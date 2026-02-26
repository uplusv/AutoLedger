import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _transactions = [];
  double _monthTotal = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final transactions = await DatabaseService.getByMonth(now.year, now.month);
    final stats = await DatabaseService.getCategoryStats(now.year, now.month);
    
    setState(() {
      _transactions = transactions;
      _monthTotal = stats.values.fold(0, (a, b) => a + b);
    });
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      _loadData();
      return;
    }
    final results = await DatabaseService.search(query);
    setState(() {
      _transactions = results;
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记账本'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: TransactionSearchDelegate(onSearch: _search),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () => Navigator.pushNamed(context, '/stats'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 本月总览
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('本月支出', style: TextStyle(fontSize: 16)),
                Text(
                  '¥${_monthTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          // 交易列表
          Expanded(
            child: _transactions.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty 
                          ? '暂无记录，点击右下角添加'
                          : '未找到 "$_searchQuery" 相关记录',
                    ),
                  )
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final t = _transactions[index];
                      return _buildTransactionCard(t);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add').then((_) => _loadData()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction t) {
    // 来源图标
    IconData sourceIcon;
    switch (t.source) {
      case 'wechat':
        sourceIcon = Icons.chat;
        break;
      case 'alipay':
        sourceIcon = Icons.account_balance_wallet;
        break;
      case 'shortcut':
        sourceIcon = Icons.bolt;
        break;
      default:
        sourceIcon = Icons.edit;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(t.category),
          child: Text(
            t.category[0],
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(t.merchant)),
            Icon(sourceIcon, size: 14, color: Colors.grey),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t.category} · ${_formatTime(t.time)}'),
            if (t.note != null && t.note!.isNotEmpty)
              Text(
                t.note!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Text(
          '¥${t.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () {
          // 查看详情或编辑
          _showTransactionDetail(t);
        },
        onLongPress: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('删除记录'),
              content: Text('确定删除 "${t.merchant}" ¥${t.amount} 的记录吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('删除'),
                ),
              ],
            ),
          );
          if (confirm == true && t.id != null) {
            await DatabaseService.delete(int.parse(t.id!));
            _loadData();
          }
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return '今天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getCategoryColor(String category) {
    final colors = {
      '餐饮': Colors.orange,
      '交通': Colors.blue,
      '购物': Colors.pink,
      '娱乐': Colors.purple,
      '医疗': Colors.red,
      '教育': Colors.green,
      '住房': Colors.brown,
      '其他': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  void _showTransactionDetail(Transaction t) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.merchant, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('金额: ¥${t.amount.toStringAsFixed(2)}'),
            Text('分类: ${t.category}'),
            Text('时间: ${t.time.toString().substring(0, 19)}'),
            Text('来源: ${t.source}'),
            if (t.note != null && t.note!.isNotEmpty) Text('备注: ${t.note}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 搜索委托
class TransactionSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;

  TransactionSearchDelegate({required this.onSearch});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('输入商家、分类或备注搜索'));
  }
}
