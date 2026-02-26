import 'package:flutter/material.dart';

class Transaction {
  final String? id;
  final double amount;
  final String merchant;
  final String category;
  final DateTime time;
  final String? note;
  final String source; // 'wechat', 'alipay', 'manual'

  Transaction({
    this.id,
    required this.amount,
    required this.merchant,
    required this.category,
    required this.time,
    this.note,
    required this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'category': category,
      'time': time.toIso8601String(),
      'note': note,
      'source': source,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id']?.toString(),
      amount: map['amount'] as double,
      merchant: map['merchant'] as String,
      category: map['category'] as String,
      time: DateTime.parse(map['time'] as String),
      note: map['note'] as String?,
      source: map['source'] as String,
    );
  }

  // 从 URL Scheme 参数创建（带智能分类）
  factory Transaction.fromUrlParams(Map<String, String> params) {
    return Transaction(
      amount: double.tryParse(params['amount'] ?? '0') ?? 0,
      merchant: params['merchant'] ?? '未知商家',
      category: params['category'] ?? '其他',
      time: DateTime.tryParse(params['time'] ?? '') ?? DateTime.now(),
      note: params['note'],
      source: params['source'] ?? 'shortcut',
    );
  }

  // 复制并修改
  Transaction copyWith({
    String? id,
    double? amount,
    String? merchant,
    String? category,
    DateTime? time,
    String? note,
    String? source,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      time: time ?? this.time,
      note: note ?? this.note,
      source: source ?? this.source,
    );
  }
}

// 预设分类 - 由 SmartCategoryService 管理
final List<String> defaultCategories = [
  '餐饮',
  '交通',
  '购物',
  '娱乐',
  '医疗',
  '教育',
  '住房',
  '其他',
];
