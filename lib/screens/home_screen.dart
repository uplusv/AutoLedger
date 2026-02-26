import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/smart_category_service.dart';
import '../services/budget_service.dart';
import '../services/ledger_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _transactions = [];
  double _monthTotal = 0;
  String _searchQuery = '';
  
  // 预算相关
  double _budget = 0;
  BudgetStatus _budgetStatus = BudgetStatus.noBudget;
  
  // 账本相关
  List<Ledger> _ledgers = [];
  String _currentLedgerId = 'default';
  Ledger? get _currentLedger => _ledgers.firstWhere(
    (l) => l.id == _currentLedgerId,
    orElse: () => Ledger(id: 'default', name: '日常账本'),
  );

  @override
  void initState() {
    super.initState();
    _loadLedgers();
    _loadData();
  }

  Future<void> _loadLedgers() async {
    final ledgers = await LedgerService.getLedgers();
    final currentId = await LedgerService.getCurrentLedgerId();
    setState(() {
      _ledgers = ledgers;
      _currentLedgerId = currentId;
    });
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final transactions = await DatabaseService.getByMonth(
      now.year, now.month, 
      ledgerId: _currentLedgerId,
    );
    final stats = await DatabaseService.getCategoryStats(
      now.year, now.month,
      ledgerId: _currentLedgerId,
    );
    
    final total = stats.values.fold(0.0, (a, b) => a + b);
    
    // 加载预算
    final budget = await BudgetService.getBudget(now.year, now.month);
    final status = await BudgetService.checkBudget(now.year, now.month, total);
    
    setState(() {
      _transactions = transactions;
      _monthTotal = total;
      _budget = budget;
      _budgetStatus = status;
    });
  }

  Future<void> _switchLedger(String ledgerId) async {
    await LedgerService.setCurrentLedger(ledgerId);
    setState(() => _currentLedgerId = ledgerId);
    _loadData();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      _loadData();
      return;
    }
    final results = await DatabaseService.search(query, ledgerId: _currentLedgerId);
    setState(() {
      _transactions = results;
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildLedgerSelector(),
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 本月总览（带预算）
          _buildBudgetCard(),
          
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

  Widget _buildLedgerSelector() {
    return GestureDetector(
      onTap: _showLedgerPicker,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LedgerService.getIcon(_currentLedger?.icon ?? 'book'),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(_currentLedger?.name ?? '日常账本'),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
    );
  }

  void _showLedgerPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择账本',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._ledgers.map((ledger) => ListTile(
              leading: Icon(LedgerService.getIcon(ledger.icon)),
              title: Text(ledger.name),
              trailing: _currentLedgerId == ledger.id 
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _switchLedger(ledger.id);
              },
            )),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('管理账本'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/ledgers');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard() {
    final budgetColor = Color(BudgetService.getBudgetColor(_budgetStatus));
    final budgetMessage = BudgetService.getBudgetMessage(
      _budgetStatus, _budget, _monthTotal,
    );
    
    return Container(
      padding: const EdgeInsets.all(20),
      color: budgetColor.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('本月支出', style: TextStyle(fontSize: 16)),
              GestureDetector(
                onTap: _setBudget,
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 16, color: budgetColor),
                    const SizedBox(width: 4),
                    Text(
                      budgetMessage,
                      style: TextStyle(fontSize: 12, color: budgetColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '¥${_monthTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              if (_budget > 0)
                Text(
                  '预算 ¥${_budget.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
            ],
          ),
          if (_budget > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_monthTotal / _budget).clamp(0, 1),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(budgetColor),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _setBudget() async {
    final controller = TextEditingController(text: _budget > 0 ? _budget.toString() : '');
    
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置本月预算'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '预算金额',
            prefixText: '¥ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              Navigator.pop(context, amount);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      final now = DateTime.now();
      await BudgetService.setBudget(now.year, now.month, result);
      _loadData();
    }
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
          backgroundColor: SmartCategoryService.getColor(t.category),
          child: Icon(
            SmartCategoryService.getIcon(t.category),
            color: Colors.white,
            size: 20,
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
            Text('${t.fullCategory} · ${_formatTime(t.time)}'),
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
        onTap: () => _showTransactionDetail(t),
        onLongPress: () => _deleteTransaction(t),
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
            Text('分类: ${t.fullCategory}'),
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

  Future<void> _deleteTransaction(Transaction t) async {
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
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
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
