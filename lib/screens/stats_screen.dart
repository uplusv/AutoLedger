import 'package:flutter/material.dart';
import '../services/database_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, double> _stats = {};
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final now = DateTime.now();
    final stats = await DatabaseService.getCategoryStats(now.year, now.month);
    setState(() {
      _stats = stats;
      _total = stats.values.fold(0, (a, b) => a + b);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('本月统计')),
      body: _stats.isEmpty
          ? const Center(child: Text('暂无数据'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final entry = sorted[index];
                final percent = _total > 0 ? entry.value / _total : 0;
                
                return Card(
                  child: ListTile(
                    leading: SizedBox(
                      width: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: percent,
                            backgroundColor: Colors.grey[200],
                          ),
                          Text('${(percent * 100).toInt()}%'),
                        ],
                      ),
                    ),
                    title: Text(entry.key),
                    trailing: Text(
                      '¥${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
