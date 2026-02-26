import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Ledger {
  final String id;
  String name;
  String icon;
  String color;
  bool isDefault;

  Ledger({
    required this.id,
    required this.name,
    this.icon = 'book',
    this.color = 'blue',
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'isDefault': isDefault,
  };

  factory Ledger.fromMap(Map<String, dynamic> map) => Ledger(
    id: map['id'],
    name: map['name'],
    icon: map['icon'] ?? 'book',
    color: map['color'] ?? 'blue',
    isDefault: map['isDefault'] ?? false,
  );
}

class LedgerService {
  static const String _ledgersKey = 'ledgers';
  static const String _currentLedgerKey = 'current_ledger';

  // 获取默认账本
  static List<Ledger> getDefaultLedgers() => [
    Ledger(id: 'default', name: '日常账本', icon: 'book', color: 'green', isDefault: true),
    Ledger(id: 'travel', name: '旅行账本', icon: 'flight', color: 'blue'),
    Ledger(id: '装修', name: '装修账本', icon: 'home', color: 'orange'),
    Ledger(id: 'business', name: '生意账本', icon: 'business', color: 'purple'),
  ];

  // 获取所有账本
  static Future<List<Ledger>> getLedgers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_ledgersKey);
    
    if (data == null) {
      // 首次使用，创建默认账本
      final defaults = getDefaultLedgers();
      await saveLedgers(defaults);
      return defaults;
    }
    
    final list = jsonDecode(data) as List;
    return list.map((e) => Ledger.fromMap(e as Map<String, dynamic>)).toList();
  }

  // 保存账本列表
  static Future<void> saveLedgers(List<Ledger> ledgers) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(ledgers.map((e) => e.toMap()).toList());
    await prefs.setString(_ledgersKey, data);
  }

  // 添加账本
  static Future<void> addLedger(Ledger ledger) async {
    final ledgers = await getLedgers();
    ledgers.add(ledger);
    await saveLedgers(ledgers);
  }

  // 删除账本
  static Future<void> deleteLedger(String id) async {
    final ledgers = await getLedgers();
    ledgers.removeWhere((l) => l.id == id);
    await saveLedgers(ledgers);
  }

  // 获取当前账本
  static Future<String> getCurrentLedgerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentLedgerKey) ?? 'default';
  }

  // 设置当前账本
  static Future<void> setCurrentLedger(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentLedgerKey, id);
  }

  // 获取账本图标
  static IconData getIcon(String iconName) {
    final icons = {
      'book': Icons.book,
      'flight': Icons.flight,
      'home': Icons.home,
      'business': Icons.business,
      'shopping': Icons.shopping_bag,
      'car': Icons.directions_car,
      'pets': Icons.pets,
      'child': Icons.child_care,
      'school': Icons.school,
      'work': Icons.work,
    };
    return icons[iconName] ?? Icons.book;
  }

  // 获取账本颜色
  static Color getColor(String colorName) {
    final colors = {
      'green': Colors.green,
      'blue': Colors.blue,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'red': Colors.red,
      'pink': Colors.pink,
      'teal': Colors.teal,
      'brown': Colors.brown,
    };
    return colors[colorName] ?? Colors.blue;
  }
}
