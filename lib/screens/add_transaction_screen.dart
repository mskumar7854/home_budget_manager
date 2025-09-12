import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction; // for editing
  final int? index; // Hive index for editing

  const AddTransactionScreen({super.key, this.transaction, this.index});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _type = "Expense";
  Category? _selectedCategory;
  String? _selectedSubCategory;
  DateTime _selectedDate = DateTime.now();

  bool _isRecurring = false;
  String _recurrenceType = "monthly";

  int? _tenureMonths; // For EMI
  DateTime? _validTill; // For Recharge
  String? _paymentMethod; // Cash/Card/UPI

  final List<String> _recurrenceOptions = ["daily","weekly","monthly","yearly"];
  final List<String> _paymentOptions = ["Cash","Card","UPI","NetBanking","Wallet"];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note;
      _type = tx.type;
      _selectedDate = tx.date;
      _isRecurring = tx.isRecurring;
      _recurrenceType = tx.recurrenceType ?? "monthly";
      _tenureMonths = tx.tenureMonths;
      _validTill = tx.validTill;
      _selectedSubCategory = tx.subCategory;
      _paymentMethod = tx.paymentMethod;
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final box = Hive.box<TransactionModel>('transactions');

      final newTx = TransactionModel(
        amount: double.parse(_amountController.text),
        type: _type,
        category: _selectedCategory!.name,
        date: _selectedDate,
        note: _noteController.text.trim(),
        isRecurring: _isRecurring,
        recurrenceType: _isRecurring ? _recurrenceType : null,
        tenureMonths: _tenureMonths,
        validTill: _validTill,
        subCategory: _selectedSubCategory,
        paymentMethod: _paymentMethod,
      );

      if (widget.index == null) {
        await box.add(newTx);
      } else {
        await box.putAt(widget.index!, newTx);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.index == null ? "Transaction Added ✅" : "Transaction Updated ✏️")),
      );

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryBox = Hive.box<Category>('categories');
    final categories = categoryBox.values.where((c) => c.type == _type).toList();

    // match category when editing
    if (_selectedCategory == null && widget.transaction != null) {
      final found = categories.where((c) => c.name == widget.transaction!.category);
      if (found.isNotEmpty) {
        _selectedCategory = found.first;
      } else {
        _selectedCategory = Category(
          name: widget.transaction!.category,
          type: widget.transaction!.type,
          color: Colors.grey.value,
          icon: "🏷️",
          group: "Daily",
          subCategories: const [],
        );
      }
    }

    final subcats = _selectedCategory?.subCategories ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.index == null ? "Add Transaction" : "Edit Transaction"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Type
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: const Text("Expense"),
                      value: "Expense",
                      groupValue: _type,
                      onChanged: (val) {
                        setState(() {
                          _type = val.toString();
                          _selectedCategory = null;
                          _selectedSubCategory = null;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: const Text("Income"),
                      value: "Income",
                      groupValue: _type,
                      onChanged: (val) {
                        setState(() {
                          _type = val.toString();
                          _selectedCategory = null;
                          _selectedSubCategory = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Category
              DropdownButtonFormField<Category>(
                value: _selectedCategory,
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text("${c.icon}  ${c.name}")))
                    .toList(),
                onChanged: (val) => setState(() {
                  _selectedCategory = val;
                  _selectedSubCategory = null;
                }),
                decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                validator: (v) => v == null ? "Select a category" : null,
              ),
              const SizedBox(height: 10),

              // Sub-category (if available)
              if (subcats.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedSubCategory,
                  items: subcats.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _selectedSubCategory = val),
                  decoration: const InputDecoration(labelText: "Sub-category", border: OutlineInputBorder()),
                ),
              if (subcats.isNotEmpty) const SizedBox(height: 10),

              // EMI field
              if (_selectedCategory != null && _selectedCategory!.name.toLowerCase().contains("emi"))
                TextFormField(
                  initialValue: _tenureMonths != null ? _tenureMonths.toString() : "",
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Tenure (months)", border: OutlineInputBorder()),
                  onChanged: (val) => _tenureMonths = int.tryParse(val),
                ),
              if (_selectedCategory != null && _selectedCategory!.name.toLowerCase().contains("emi"))
                const SizedBox(height: 10),

              // Recharge field
              if (_selectedCategory != null && _selectedCategory!.name.toLowerCase().contains("recharge"))
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: _validTill != null ? DateFormat("dd MMM yyyy").format(_validTill!) : "",
                  ),
                  decoration: const InputDecoration(
                    labelText: "Valid Till",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _validTill ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (picked != null) setState(() => _validTill = picked);
                  },
                ),
              if (_selectedCategory != null && _selectedCategory!.name.toLowerCase().contains("recharge"))
                const SizedBox(height: 10),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount (₹)", border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? "Enter amount" : null,
              ),
              const SizedBox(height: 10),

              // Payment method
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                items: _paymentOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => setState(() => _paymentMethod = val),
                decoration: const InputDecoration(labelText: "Payment Method", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),

              // Date
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: DateFormat("dd MMM yyyy").format(_selectedDate)),
                decoration: const InputDecoration(labelText: "Date", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 10),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: "Description (optional)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              // Recurring
              SwitchListTile(
                title: const Text("Recurring Transaction"),
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
              if (_isRecurring)
                DropdownButtonFormField<String>(
                  value: _recurrenceType,
                  items: _recurrenceOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setState(() => _recurrenceType = val!),
                  decoration: const InputDecoration(labelText: "Repeat every", border: OutlineInputBorder()),
                ),

              const Spacer(),
              ElevatedButton.icon(
                onPressed: _saveTransaction,
                icon: const Icon(Icons.save),
                label: Text(widget.index == null ? "Save Transaction" : "Update Transaction"),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.teal, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
