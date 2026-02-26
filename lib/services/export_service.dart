import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class ExportService {
  // 导出为 CSV
  static Future<String> exportToCSV({int? year, int? month}) async {
    List<Transaction> transactions;
    
    if (year != null && month != null) {
      transactions = await DatabaseService.getByMonth(year, month);
    } else {
      transactions = await DatabaseService.getAll();
    }
    
    // CSV 头部
    final header = '日期,时间,商家,一级分类,二级分类,金额,备注,来源\n';
    
    // 数据行
    final rows = transactions.map((t) {
      final date = '${t.time.year}-${t.time.month.toString().padLeft(2, '0')}-${t.time.day.toString().padLeft(2, '0')}';
      final time = '${t.time.hour.toString().padLeft(2, '0')}:${t.time.minute.toString().padLeft(2, '0')}';
      final subCategory = t.subCategory ?? '';
      final note = t.note ?? '';
      
      return '$date,$time,${t.merchant},${t.category},$subCategory,${t.amount},$note,${t.source}';
    }).join('\n');
    
    return header + rows;
  }

  // 导出并分享
  static Future<void> shareCSV({int? year, int? month}) async {
    final csv = await exportToCSV(year: year, month: month);
    
    final directory = await getTemporaryDirectory();
    final fileName = _generateFileName(year: year, month: month);
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(csv);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '记账数据导出',
    );
  }

  // 生成文件名
  static String _generateFileName({int? year, int? month}) {
    final now = DateTime.now();
    if (year != null && month != null) {
      return '记账_${year}年${month}月.csv';
    }
    return '记账_全部数据_${now.year}${now.month}${now.day}.csv';
  }

  // 导出为 JSON（用于备份）
  static Future<String> exportToJSON() async {
    final transactions = await DatabaseService.getAll();
    final data = {
      'exportTime': DateTime.now().toIso8601String(),
      'count': transactions.length,
      'transactions': transactions.map((t) => t.toMap()).toList(),
    };
    return jsonEncode(data);
  }

  // 从 JSON 导入（恢复备份）
  static Future<int> importFromJSON(String json) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final transactions = (data['transactions'] as List)
        .map((t) => Transaction.fromMap(t as Map<String, dynamic>))
        .toList();
    
    int count = 0;
    for (final t in transactions) {
      await DatabaseService.insert(t);
      count++;
    }
    return count;
  }
}
