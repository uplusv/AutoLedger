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
      version: 3, // 升级数据库版本
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
            source TEXT NOT NULL,
            ledgerId TEXT DEFAULT 'default'
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $tableName ADD COLUMN subCategory TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE $tableName ADD COLUMN ledgerId TEXT DEFAULT "default"');
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

  // 按月份获取（支持账本过滤）
  static Future<List<model.Transaction>> getByMonth(
    int year,
    int month, {
    String? ledgerId,
  }) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    
    String whereClause = 'time >= ? AND time < ?';
    List<dynamic> whereArgs = [start, end];
    
    if (ledgerId != null) {
      whereClause += ' AND ledgerId = ?';
      whereArgs.add(ledgerId);
    }
    
    final maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'time DESC',
    );
    return maps.map((m) => model.Transaction.fromMap(m)).toList();
  }

  // 获取分类统计（支持账本过滤）
  static Future<Map<String, double>> getCategoryStats(
    int year,
    int month, {
    String? ledgerId,
  }) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    
    String whereClause = 'time >= ? AND time < ?';
    List<dynamic> whereArgs = [start, end];
    
    if (ledgerId != null) {
      whereClause += ' AND ledgerId = ?';
      whereArgs.add(ledgerId);
    }
    
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM $tableName
      WHERE $whereClause
      GROUP BY category
    ''', whereArgs);
    
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

  // 搜索交易（支持账本过滤）
  static Future<List<model.Transaction>> search(
    String keyword, {
    String? ledgerId,
  }) async {
    final db = await database;
    
    String whereClause = 'merchant LIKE ? OR note LIKE ? OR category LIKE ?';
    List<dynamic> whereArgs = ['%$keyword%', '%$keyword%', '%$keyword%'];
    
    if (ledgerId != null) {
      whereClause = '($whereClause) AND ledgerId = ?';
      whereArgs.add(ledgerId);
    }
    
    final maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'time DESC',
    );
    return maps.map((m) => model.Transaction.fromMap(m)).toList();
  }

  // 获取每日支出（用于趋势图，支持账本过滤）
  static Future<List<Map<String, dynamic>>> getDailyExpenses(
    int year,
    int month, {
    String? ledgerId,
  }) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    
    String whereClause = 'time >= ? AND time < ?';
    List<dynamic> whereArgs = [start, end];
    
    if (ledgerId != null) {
      whereClause += ' AND ledgerId = ?';
      whereArgs.add(ledgerId);
    }
    
    final result = await db.rawQuery('''
      SELECT 
        CAST(strftime('%d', time) AS INTEGER) as day,
        SUM(amount) as total
      FROM $tableName
      WHERE $whereClause
      GROUP BY day
      ORDER BY day
    ''', whereArgs);
    
    return result;
  }
}
