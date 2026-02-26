import 'package:flutter/material.dart';
import '../services/database_service.dart';

// 智能分类规则
class SmartCategory {
  static final Map<String, List<String>> _rules = {
    '餐饮': ['麦当劳', '肯德基', '星巴克', '火锅', '烧烤', '奶茶', '咖啡', '餐厅', '饭店', '外卖', '美团', '饿了么'],
    '交通': ['滴滴', '高德', '地铁', '公交', '加油', '停车', '高速', '铁路', '航空', '携程', '飞猪'],
    '购物': ['淘宝', '天猫', '京东', '拼多多', '苏宁', '盒马', '永辉', '超市', '便利店', '商场'],
    '娱乐': ['影院', '电影', 'KTV', '游戏', '视频', '音乐', '会员', '爱奇艺', '腾讯', '优酷', 'B站'],
    '医疗': ['医院', '诊所', '药店', '药房', '体检', '医保'],
    '住房': ['房租', '物业', '水电', '燃气', '宽带', '话费', '装修'],
    '教育': ['学费', '培训', '课程', '书籍', '书店', '知识付费'],
  };

  // 根据商家智能匹配分类
  static String categorize(String merchant) {
    final lowerMerchant = merchant.toLowerCase();
    
    for (final entry in _rules.entries) {
      for (final keyword in entry.value) {
        if (lowerMerchant.contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }
    return '其他';
  }

  // 获取所有分类
  static List<String> get categories => ['餐饮', '交通', '购物', '娱乐', '医疗', '住房', '教育', '其他'];
}

// 商家学习系统
class MerchantLearning {
  // 获取商家上次使用的分类
  static Future<String> getPreferredCategory(String merchant) async {
    final history = await DatabaseService.getByMerchant(merchant, limit: 1);
    if (history.isNotEmpty) {
      return history.first.category;
    }
    return SmartCategory.categorize(merchant);
  }

  // 保存商家偏好（在添加记录时自动调用）
  static Future<void> learn(String merchant, String category) async {
    // 实际存储在交易记录中，通过 getByMerchant 查询
    // 这里可以扩展为独立的偏好表
  }
}
