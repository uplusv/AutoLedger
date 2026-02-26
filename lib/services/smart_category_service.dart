import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/category_system.dart';

// 智能分类服务（新版 - 支持一级+二级分类）
class SmartCategoryService {
  // 根据商家智能匹配分类（返回一级+二级）
  static Map<String, String> categorize(String merchant) {
    return CategorySystem.smartMatch(merchant);
  }

  // 获取所有一级分类
  static List<String> get primaryCategories => CategorySystem.primaryCategories;

  // 获取二级分类
  static List<String> getSubCategories(String primary) {
    return CategorySystem.getSubCategories(primary);
  }

  // 获取分类图标
  static IconData getIcon(String primary) => CategorySystem.getIcon(primary);

  // 获取分类颜色  
  static Color getColor(String primary) => CategorySystem.getColor(primary);
}

// 商家学习系统（新版）
class MerchantLearning {
  // 获取商家上次使用的分类（一级+二级）
  static Future<Map<String, String>> getPreferredCategory(String merchant) async {
    final history = await DatabaseService.getByMerchant(merchant, limit: 1);
    if (history.isNotEmpty) {
      return {
        '一级': history.first.category,
        '二级': history.first.subCategory ?? '其他',
      };
    }
    // 没有历史记录，使用智能分类
    return SmartCategoryService.categorize(merchant);
  }
}
