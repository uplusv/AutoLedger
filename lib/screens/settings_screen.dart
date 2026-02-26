import 'package:flutter/material.dart';
import '../services/export_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // 数据导出
          _buildSectionHeader('数据管理'),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('导出本月数据'),
            subtitle: const Text('CSV 格式，可用于 Excel'),
            onTap: () => _exportCurrentMonth(context),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('导出全部数据'),
            subtitle: const Text('包含所有历史记录'),
            onTap: () => _exportAll(context),
          ),
          
          const Divider(),
          
          // 备份恢复
          _buildSectionHeader('备份'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('备份到 JSON'),
            subtitle: const Text('完整数据备份'),
            onTap: () => _backupJSON(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('从 JSON 恢复'),
            subtitle: const Text('导入备份文件'),
            onTap: () => _restoreJSON(context),
          ),
          
          const Divider(),
          
          // 关于
          _buildSectionHeader('关于'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('版本'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('使用帮助'),
            subtitle: const Text('查看快捷指令配置指南'),
            onTap: () {
              // 打开帮助文档
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Future<void> _exportCurrentMonth(BuildContext context) async {
    final now = DateTime.now();
    try {
      await ExportService.shareCSV(year: now.year, month: now.month);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _exportAll(BuildContext context) async {
    try {
      await ExportService.shareCSV();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _backupJSON(BuildContext context) async {
    try {
      final json = await ExportService.exportToJSON();
      // TODO: 保存到文件并分享
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份功能开发中')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份失败: $e')),
        );
      }
    }
  }

  Future<void> _restoreJSON(BuildContext context) async {
    // TODO: 文件选择器导入
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('恢复功能开发中')),
      );
    }
  }
}
