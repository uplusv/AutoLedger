import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BudgetService {
  static const String _budgetKey = 'monthly_budgets';
  static const String _alertsKey = 'budget_alerts';

  // 获取某月预算
  static Future<double> getBudget(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final budgets = prefs.getString(_budgetKey);
    if (budgets == null) return 0;
    
    final map = jsonDecode(budgets) as Map<String, dynamic>;
    final key = '$year-$month';
    return (map[key] as num?)?.toDouble() ?? 0;
  }

  // 设置某月预算
  static Future<void> setBudget(int year, int month, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final budgets = prefs.getString(_budgetKey);
    final map = budgets != null 
        ? jsonDecode(budgets) as Map<String, dynamic> 
        : <String, dynamic>{};
    
    final key = '$year-$month';
    map[key] = amount;
    
    await prefs.setString(_budgetKey, jsonEncode(map));
  }

  // 检查是否超支
  static Future<BudgetStatus> checkBudget(int year, int month, double spent) async {
    final budget = await getBudget(year, month);
    if (budget <= 0) return BudgetStatus.noBudget;
    
    final percent = spent / budget;
    
    if (percent >= 1.0) {
      return BudgetStatus.overBudget;
    } else if (percent >= 0.9) {
      return BudgetStatus.warning;
    } else if (percent >= 0.8) {
      return BudgetStatus.caution;
    }
    return BudgetStatus.safe;
  }

  // 获取预算提示信息
  static String getBudgetMessage(BudgetStatus status, double budget, double spent) {
    final remaining = budget - spent;
    switch (status) {
      case BudgetStatus.overBudget:
        return '已超支 ¥${remaining.abs().toStringAsFixed(2)}';
      case BudgetStatus.warning:
        return '预算紧张，剩余 ¥${remaining.toStringAsFixed(2)}';
      case BudgetStatus.caution:
        return '已用 80%，剩余 ¥${remaining.toStringAsFixed(2)}';
      case BudgetStatus.safe:
        return '剩余 ¥${remaining.toStringAsFixed(2)}';
      case BudgetStatus.noBudget:
        return '未设置预算';
    }
  }

  // 获取预算颜色
  static int getBudgetColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.overBudget:
        return 0xFFE53935; // 红色
      case BudgetStatus.warning:
        return 0xFFFF9800; // 橙色
      case BudgetStatus.caution:
        return 0xFFFFC107; // 黄色
      case BudgetStatus.safe:
        return 0xFF4CAF50; // 绿色
      case BudgetStatus.noBudget:
        return 0xFF9E9E9E; // 灰色
    }
  }
}

enum BudgetStatus {
  noBudget,   // 未设置预算
  safe,       // 安全（<80%）
  caution,    // 注意（80-90%）
  warning,    // 警告（90-100%）
  overBudget, // 超支（>100%）
}
