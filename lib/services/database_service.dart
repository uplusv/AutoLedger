import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as model;

class DatabaseService {
  static Database? _database;
  static const String tableName = 'transactions';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'accounting.db');

    return await openDatabase(
      path,
      version: 2, // 升级数据库版本
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            merchant TEXT NOT NULL,
            category TEXT NOT NULL,
            subCategory TEXT,
            time TEXT NOT NULL,
            note TEXT,
            source TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $tableName ADD COLUMN subCategory TEXT');
        }
      },
    );
  }

  // 插入交易
  static Future<int> insert(model.Transaction transaction) async {
    final db = await database;
    return await db.insert(tableName, transaction.toMap());
  }

  // 获取所有交易
  static Future<List<model.Transaction>> getAll() async {
    final db = await database;
    final maps = await db.query(tableName, orderBy: 'time DESC');
    return maps.map((m) => model.Transaction.fromMap(m)).toList();
  }

  // 按月份获取
  static Future<List<model.Transaction>> getByMonth(int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    
    final maps = await db.query(
      tableName,
      where: 'time >= ? AND time < ?',
      whereArgs: [start, end],
      orderBy: 'time DESC',
    );
    return maps.map((m) => model.Transaction.fromMap(m)).toList();
  }

  // 获取分类统计
  static Future<Map<String, double>> getCategoryStats(int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM $tableName
      WHERE time >= ? AND time < ?
      GROUP BY category
    ''', [start, end]);
    
    return {
      for (var row in result) 
        row['category'] as String: (row['total'] as num).toDouble()
    };
  }

  // 删除
  static Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // 按商家查询历史记录（用于商家学习）
  static Future<List<model.Transaction>> getByMerchant(String merchant, {int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'merchant LIKE ?',
      whereArgs: ['%$merchant%'],
      orderBy: 'time DESC',
      limit: limit,
    );
    return maps.map((m) => model.Transaction.fromMap(m)).toList();
  }

  // 搜索交易
  static Future<List<model.Transaction>> search(String keyword) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'merchant LIKE ? OR note LIKE ? OR category LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
      orderBy: 'time DESC',
    );
    return maps.map((m) => model.Transaction.fromMap(m)).toList();
  }

  // 获取每日支出（用于趋势图）
  static Future<List<Map<String, dynamic>>> getDailyExpenses(int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    
    final result = await db.rawQuery('''
      SELECT 
        CAST(strftime('%d', time) AS INTEGER) as day,
        SUM(amount) as total
      FROM $tableName
      WHERE time >= ? AND time < ?
      GROUP BY day
      ORDER BY day
    ''', [start, end]);
    
    return result;
  }
}
