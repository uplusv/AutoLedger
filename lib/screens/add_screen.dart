import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class AddScreen extends StatefulWidget {
  final Map<String, String>? initialData; // 从快捷指令传入的数据

  const AddScreen({super.key, this.initialData});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _amountController = TextEditingController(
    text: widget.initialData?['amount'] ?? '',
  );
  late final _merchantController = TextEditingController(
    text: widget.initialData?['merchant'] ?? '',
  );
  late final _noteController = TextEditingController();
  
  String _category = '餐饮';
  DateTime _time = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记一笔')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 金额
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '金额',
                  prefixText: '¥ ',
                ),
                validator: (v) => v?.isEmpty ?? true ? '请输入金额' : null,
              ),
              const SizedBox(height: 16),
              
              // 商家
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(labelText: '商家/用途'),
                validator: (v) => v?.isEmpty ?? true ? '请输入商家' : null,
              ),
              const SizedBox(height: 16),
              
              // 分类
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: '分类'),
                items: defaultCategories.map((c) => 
                  DropdownMenuItem(value: c, child: Text(c))
                ).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              
              // 时间
              ListTile(
                title: const Text('时间'),
                subtitle: Text(_time.toString().substring(0, 16)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _time,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _time = date);
                  }
                },
              ),
              
              // 备注
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: '备注（可选）'),
              ),
              
              const Spacer(),
              
              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('保存', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final transaction = Transaction(
      amount: double.parse(_amountController.text),
      merchant: _merchantController.text,
      category: _category,
      time: _time,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      source: widget.initialData != null ? 'shortcut' : 'manual',
    );
    
    await DatabaseService.insert(transaction);
    if (mounted) Navigator.pop(context);
  }
}
