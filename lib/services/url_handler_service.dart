import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/smart_category_service.dart';
import '../services/category_system.dart';

class UrlHandlerService {
  static const platform = MethodChannel('com.example.accounting/url');
  
  // 处理 URL Scheme 传入的数据（支持一级+二级分类）
  static Future<void> handleUrl(String url, BuildContext context) async {
    if (!url.startsWith('accounting://')) return;
    
    final uri = Uri.parse(url);
    if (uri.host == 'add') {
      final params = uri.queryParameters;
      
      // 1. 解析基础数据
      var transaction = Transaction.fromUrlParams(params);
      
      // 2. 智能分类 + 商家学习
      String primaryCategory;
      String? subCategory;
      
      if (params['category'] != null && params['category']!.isNotEmpty) {
        // 快捷指令传了一级分类
        primaryCategory = params['category']!;
        subCategory = params['subCategory'];
      } else {
        // 使用智能分类
        final smartMatch = CategorySystem.smartMatch(transaction.merchant);
        primaryCategory = smartMatch['一级']!;
        subCategory = smartMatch['二级'];
      }
      
      // 3. 更新分类
      transaction = transaction.copyWith(
        category: primaryCategory,
        subCategory: subCategory,
      );
      
      // 4. 保存到数据库
      await DatabaseService.insert(transaction);
      
      // 5. 显示确认（带完整分类）
      if (context.mounted) {
        _showSuccessSnackBar(context, transaction);
      }
    }
  }

  // 显示成功提示
  static void _showSuccessSnackBar(BuildContext context, Transaction transaction) {
    final noteText = transaction.note?.isNotEmpty == true 
        ? '\n备注: ${transaction.note}' 
        : '';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '已记账: ${transaction.merchant}\n'
          '¥${transaction.amount.toStringAsFixed(2)} · ${transaction.fullCategory}'
          '$noteText',
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '查看',
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/');
          },
        ),
      ),
    );
  }

  // 注册 URL Scheme 监听（iOS）
  static void initUrlListener(BuildContext context) {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'handleUrl') {
        final url = call.arguments as String;
        await handleUrl(url, context);
      }
    });
  }
}
