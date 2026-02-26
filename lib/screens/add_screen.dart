import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/smart_category_service.dart';

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
  late final _noteController = TextEditingController(
    text: widget.initialData?['note'] ?? '',
  );
  
  String _category = '其他';
  DateTime _time = DateTime.now();
  bool _isLoadingCategory = false;

  @override
  void initState() {
    super.initState();
    _initCategory();
  }

  // 初始化分类（智能分类 + 商家学习）
  Future<void> _initCategory() async {
    final merchant = widget.initialData?['merchant'] ?? '';
    
    if (widget.initialData?['category'] != null && 
        widget.initialData!['category']!.isNotEmpty) {
      // 快捷指令传了分类
      setState(() => _category = widget.initialData!['category']!);
    } else if (merchant.isNotEmpty) {
      // 商家学习 + 智能分类
      setState(() => _isLoadingCategory = true);
      final preferredCategory = await MerchantLearning.getPreferredCategory(merchant);
      setState(() {
        _category = preferredCategory;
        _isLoadingCategory = false;
      });
    }
  }

  // 商家改变时重新分类
  Future<void> _onMerchantChanged(String value) async {
    if (value.isEmpty) return;
    
    // 先查历史
    final preferred = await MerchantLearning.getPreferredCategory(value);
    if (preferred != '其他') {
      // 有历史记录，使用历史分类
      setState(() => _category = preferred);
    } else {
      // 没有历史，用智能分类
      final smart = SmartCategory.categorize(value);
      setState(() => _category = smart);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记一笔')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                decoration: const InputDecoration(
                  labelText: '商家/交易对象',
                  hintText: '如：星巴克、滴滴出行',
                ),
                validator: (v) => v?.isEmpty ?? true ? '请输入商家' : null,
                onChanged: _onMerchantChanged,
              ),
              const SizedBox(height: 16),
              
              // 分类（带智能提示）
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: InputDecoration(
                        labelText: '分类',
                        suffixIcon: _isLoadingCategory 
                            ? const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                      ),
                      items: SmartCategory.categories.map((c) => 
                        DropdownMenuItem(value: c, child: Text(c))
                      ).toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ),
                ],
              ),
              
              // 智能分类提示
              if (!_isLoadingCategory && _merchantController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    '智能分类: ${SmartCategory.categorize(_merchantController.text)}',
                    style: TextStyle(
                      fontSize: 12, 
                      color: Colors.grey[600],
                    ),
                  ),
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
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_time),
                    );
                    if (time != null) {
                      setState(() => _time = DateTime(
                        date.year, date.month, date.day,
                        time.hour, time.minute,
                      ));
                    }
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // 备注
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  hintText: '如：午餐、打车回家',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
