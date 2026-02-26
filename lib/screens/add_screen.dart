import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/smart_category_service.dart';
import '../services/category_system.dart';

class AddScreen extends StatefulWidget {
  final Map<String, String>? initialData;

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
  
  String _primaryCategory = '其他支出';
  String? _subCategory;
  DateTime _time = DateTime.now();
  bool _isLoadingCategory = false;

  @override
  void initState() {
    super.initState();
    _initCategory();
  }

  // 初始化分类
  Future<void> _initCategory() async {
    final merchant = widget.initialData?['merchant'] ?? '';
    
    if (merchant.isNotEmpty) {
      setState(() => _isLoadingCategory = true);
      final preferred = await MerchantLearning.getPreferredCategory(merchant);
      setState(() {
        _primaryCategory = preferred['一级']!;
        _subCategory = preferred['二级'];
        _isLoadingCategory = false;
      });
    }
  }

  // 商家改变时重新分类
  Future<void> _onMerchantChanged(String value) async {
    if (value.isEmpty) return;
    
    final preferred = await MerchantLearning.getPreferredCategory(value);
    setState(() {
      _primaryCategory = preferred['一级']!;
      _subCategory = preferred['二级'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记一笔')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
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
              
              // 一级分类
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _primaryCategory,
                      decoration: InputDecoration(
                        labelText: '分类',
                        suffixIcon: _isLoadingCategory 
                            ? const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(SmartCategoryService.getIcon(_primaryCategory)),
                      ),
                      items: SmartCategoryService.primaryCategories.map((c) => 
                        DropdownMenuItem(
                          value: c, 
                          child: Row(
                            children: [
                              Icon(SmartCategoryService.getIcon(c), size: 20),
                              const SizedBox(width: 8),
                              Text(c),
                            ],
                          ),
                        )
                      ).toList(),
                      onChanged: (v) => setState(() {
                        _primaryCategory = v!;
                        _subCategory = null; // 重置二级分类
                      }),
                    ),
                  ),
                ],
              ),
              
              // 二级分类
              if (SmartCategoryService.getSubCategories(_primaryCategory).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: DropdownButtonFormField<String>(
                    value: _subCategory,
                    decoration: const InputDecoration(
                      labelText: '子分类',
                    ),
                    hint: const Text('选择子分类（可选）'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('无'),
                      ),
                      ...SmartCategoryService.getSubCategories(_primaryCategory).map((c) => 
                        DropdownMenuItem(value: c, child: Text(c))
                      ),
                    ],
                    onChanged: (v) => setState(() => _subCategory = v),
                  ),
                ),
              
              // 智能分类提示
              if (!_isLoadingCategory && _merchantController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    '智能识别: ${CategorySystem.smartMatch(_merchantController.text)['一级']} - '
                    '${CategorySystem.smartMatch(_merchantController.text)['二级']}',
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
              
              const SizedBox(height: 32),
              
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
      category: _primaryCategory,
      subCategory: _subCategory,
      time: _time,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      source: widget.initialData != null ? 'shortcut' : 'manual',
    );
    
    await DatabaseService.insert(transaction);
    if (mounted) Navigator.pop(context);
  }
}
