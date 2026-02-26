import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/smart_category_service.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  Map<String, double> _categoryStats = {};
  double _total = 0;
  List<DailyExpense> _dailyExpenses = [];
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await DatabaseService.getCategoryStats(_selectedYear, _selectedMonth);
    final daily = await DatabaseService.getDailyExpenses(_selectedYear, _selectedMonth);
    
    setState(() {
      _categoryStats = stats;
      _total = stats.values.fold(0, (a, b) => a + b);
      _dailyExpenses = daily.map((d) => DailyExpense(
        d['day'] as int,
        (d['total'] as num).toDouble(),
      )).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectMonth,
          ),
        ],
      ),
      body: _categoryStats.isEmpty
          ? const Center(child: Text('暂无数据'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 月份选择器
                  _buildMonthSelector(),
                  
                  const SizedBox(height: 20),
                  
                  // 总支出卡片
                  _buildTotalCard(),
                  
                  const SizedBox(height: 20),
                  
                  // 饼图
                  _buildPieChart(),
                  
                  const SizedBox(height: 20),
                  
                  // 分类列表
                  _buildCategoryList(),
                  
                  const SizedBox(height: 20),
                  
                  // 每日趋势图
                  if (_dailyExpenses.length > 1)
                    _buildTrendChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              if (_selectedMonth > 1) {
                _selectedMonth--;
              } else {
                _selectedMonth = 12;
                _selectedYear--;
              }
            });
            _loadStats();
          },
        ),
        Text(
          '$_selectedYear年$_selectedMonth月',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            final now = DateTime.now();
            if (_selectedYear < now.year || 
                (_selectedYear == now.year && _selectedMonth < now.month)) {
              setState(() {
                if (_selectedMonth < 12) {
                  _selectedMonth++;
                } else {
                  _selectedMonth = 1;
                  _selectedYear++;
                }
              });
              _loadStats();
            }
          },
        ),
      ],
    );
  }

  Widget _buildTotalCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('本月支出', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              '¥${_total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '共 ${_categoryStats.length} 个分类',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final sorted = _categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('支出构成', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _showingSections(sorted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _showingSections(List<MapEntry<String, double>> sorted) {
    return sorted.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      final percent = _total > 0 ? (data.value / _total * 100).toStringAsFixed(1) : '0';
      
      return PieChartSectionData(
        color: SmartCategoryService.getColor(data.key),
        value: data.value,
        title: isTouched ? '$percent%' : '',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildCategoryList() {
    final sorted = _categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('分类明细', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...sorted.map((entry) => _buildCategoryItem(entry)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(MapEntry<String, double> entry) {
    final percent = _total > 0 ? entry.value / _total : 0;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: SmartCategoryService.getColor(entry.key),
        child: Icon(
          SmartCategoryService.getIcon(entry.key),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(entry.key),
      subtitle: LinearProgressIndicator(
        value: percent,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation(SmartCategoryService.getColor(entry.key)),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '¥${entry.value.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${(percent * 100).toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('每日趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 5 == 0) {
                            return Text('${value.toInt()}日');
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _dailyExpenses.map((e) => 
                        FlSpot(e.day.toDouble(), e.amount)
                      ).toList(),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectMonth() async {
    // 简单的月份选择
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择月份'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            selectedDate: DateTime(_selectedYear, _selectedMonth),
            onChanged: (date) {
              Navigator.pop(context);
              _selectMonthInYear(date.year);
            },
          ),
        ),
      ),
    );
  }

  void _selectMonthInYear(int year) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$year年'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(12, (index) {
            final month = index + 1;
            return ActionChip(
              label: Text('$month月'),
              onPressed: () {
                setState(() {
                  _selectedYear = year;
                  _selectedMonth = month;
                });
                _loadStats();
                Navigator.pop(context);
              },
            );
          }),
        ),
      ),
    );
  }
}

// 每日支出数据
class DailyExpense {
  final int day;
  final double amount;

  DailyExpense(this.day, this.amount);
}
