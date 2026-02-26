import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class UrlHandlerService {
  static const platform = MethodChannel('com.example.accounting/url');
  
  // 处理 URL Scheme 传入的数据
  static Future<void> handleUrl(String url, BuildContext context) async {
    if (!url.startsWith('accounting://')) return;
    
    final uri = Uri.parse(url);
    if (uri.host == 'add') {
      final params = uri.queryParameters;
      final transaction = Transaction.fromUrlParams(params);
      
      // 保存到数据库
      await DatabaseService.insert(transaction);
      
      // 显示确认
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已记账: ${transaction.merchant} ¥${transaction.amount}'),
            action: SnackBarAction(
              label: '查看',
              onPressed: () {
                // 导航到首页
              },
            ),
          ),
        );
      }
    }
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
