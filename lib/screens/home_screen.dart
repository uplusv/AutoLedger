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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记账本'),
        actions: [
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
                ? const Center(child: Text('暂无记录，点击右下角添加'))
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final t = _transactions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(t.category[0]),
                        ),
                        title: Text(t.merchant),
                        subtitle: Text('${t.category} · ${t.time.toString().substring(0, 16)}'),
                        trailing: Text(
                          '¥${t.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onLongPress: () async {
                          if (t.id != null) {
                            await DatabaseService.delete(int.parse(t.id!));
                            _loadData();
                          }
                        },
                      );
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
}
