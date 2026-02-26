import 'package:flutter/material.dart';
import '../services/ledger_service.dart';

class LedgerManageScreen extends StatefulWidget {
  const LedgerManageScreen({super.key});

  @override
  State<LedgerManageScreen> createState() => _LedgerManageScreenState();
}

class _LedgerManageScreenState extends State<LedgerManageScreen> {
  List<Ledger> _ledgers = [];

  @override
  void initState() {
    super.initState();
    _loadLedgers();
  }

  Future<void> _loadLedgers() async {
    final ledgers = await LedgerService.getLedgers();
    setState(() => _ledgers = ledgers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账本管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addLedger,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _ledgers.length,
        itemBuilder: (context, index) {
          final ledger = _ledgers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: LedgerService.getColor(ledger.color),
              child: Icon(
                LedgerService.getIcon(ledger.icon),
                color: Colors.white,
              ),
            ),
            title: Text(ledger.name),
            subtitle: ledger.isDefault ? const Text('默认账本') : null,
            trailing: ledger.isDefault
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteLedger(ledger),
                  ),
            onTap: () => _editLedger(ledger),
          );
        },
      ),
    );
  }

  Future<void> _addLedger() async {
    final result = await showDialog<Ledger>(
      context: context,
      builder: (context) => const LedgerEditDialog(),
    );
    
    if (result != null) {
      await LedgerService.addLedger(result);
      _loadLedgers();
    }
  }

  Future<void> _editLedger(Ledger ledger) async {
    final result = await showDialog<Ledger>(
      context: context,
      builder: (context) => LedgerEditDialog(ledger: ledger),
    );
    
    if (result != null) {
      // 更新账本
      final index = _ledgers.indexWhere((l) => l.id == result.id);
      if (index != -1) {
        _ledgers[index] = result;
        await LedgerService.saveLedgers(_ledgers);
        _loadLedgers();
      }
    }
  }

  Future<void> _deleteLedger(Ledger ledger) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除账本'),
        content: Text('确定删除 "${ledger.name}" 吗？该账本下的记录将被保留但无法查看。'),
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
    
    if (confirm == true) {
      await LedgerService.deleteLedger(ledger.id);
      _loadLedgers();
    }
  }
}

class LedgerEditDialog extends StatefulWidget {
  final Ledger? ledger;

  const LedgerEditDialog({super.key, this.ledger});

  @override
  State<LedgerEditDialog> createState() => _LedgerEditDialogState();
}

class _LedgerEditDialogState extends State<LedgerEditDialog> {
  late final _nameController = TextEditingController(
    text: widget.ledger?.name ?? '',
  );
  String _selectedIcon = 'book';
  String _selectedColor = 'blue';

  final List<Map<String, String>> _icons = [
    {'name': 'book', 'label': '日常'},
    {'name': 'flight', 'label': '旅行'},
    {'name': 'home', 'label': '装修'},
    {'name': 'business', 'label': '生意'},
    {'name': 'shopping', 'label': '购物'},
    {'name': 'car', 'label': '汽车'},
    {'name': 'pets', 'label': '宠物'},
    {'name': 'child', 'label': '育儿'},
    {'name': 'school', 'label': '教育'},
    {'name': 'work', 'label': '工作'},
  ];

  final List<Map<String, String>> _colors = [
    {'name': 'green', 'label': '绿色'},
    {'name': 'blue', 'label': '蓝色'},
    {'name': 'orange', 'label': '橙色'},
    {'name': 'purple', 'label': '紫色'},
    {'name': 'red', 'label': '红色'},
    {'name': 'pink', 'label': '粉色'},
    {'name': 'teal', 'label': '青色'},
    {'name': 'brown', 'label': '棕色'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.ledger != null) {
      _selectedIcon = widget.ledger!.icon;
      _selectedColor = widget.ledger!.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ledger == null ? '新建账本' : '编辑账本'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '账本名称',
                hintText: '如：旅行账本',
              ),
            ),
            const SizedBox(height: 16),
            const Text('选择图标', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((icon) {
                final isSelected = _selectedIcon == icon['name'];
                return ChoiceChip(
                  label: Icon(LedgerService.getIcon(icon['name']!)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedIcon = icon['name']!),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('选择颜色', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                final isSelected = _selectedColor == color['name'];
                return ChoiceChip(
                  label: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: LedgerService.getColor(color['name']!),
                      shape: BoxShape.circle,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedColor = color['name']!),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.isEmpty) return;
            
            final ledger = Ledger(
              id: widget.ledger?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameController.text,
              icon: _selectedIcon,
              color: _selectedColor,
            );
            Navigator.pop(context, ledger);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
