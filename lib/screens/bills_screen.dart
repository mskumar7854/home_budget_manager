// lib/screens/bills_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/bill.dart';
import '../models/category.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  String _selectedMonth = DateFormat.MMMM().format(DateTime.now());
  late List<int> _years;
  int _selectedYear = DateTime.now().year;
  final List<String> _months =
      List.generate(12, (i) => DateFormat.MMMM().format(DateTime(0, i + 1)));

  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    final cy = DateTime.now().year;
    _years = [cy - 1, cy, cy + 1];
    _selectedYear = cy;
  }

  int get _selectedMonthIndex =>
      DateFormat.MMMM().parse(_selectedMonth).month; // 1..12

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() {});
  }

  Category? _findCategory(String? name) {
    if (name == null) return null;
    final catBox = Hive.box<Category>('categories');
    try {
      return catBox.values.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  Color _statusColor(Bill b) {
    if (b.isPaid) return Colors.green;
    final now = DateTime.now();
    if (b.dueDate.isBefore(now)) return Colors.red;
    return Colors.orange;
  }

  Future<void> _openAddEditBill({Bill? item}) async {
    final nameCtrl = TextEditingController(text: item?.name ?? "");
    final providerCtrl = TextEditingController(text: item?.provider ?? "");
    final amountCtrl =
        TextEditingController(text: item?.amount?.toString() ?? "");
    DateTime dueDate = item?.dueDate ?? DateTime.now();

    final catBox = Hive.box<Category>('categories');
    final categories = catBox.values.toList();
    String? selectedCategory =
        item?.category ?? (categories.isNotEmpty ? categories.first.name : null);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(
                                  item == null ? "Add Bill / Recharge" : "Edit Bill",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold))),
                          IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close))
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                            labelText: "Bill name (e.g., Electricity)"),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: providerCtrl,
                        decoration:
                            const InputDecoration(labelText: "Provider"),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: amountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration:
                                  const InputDecoration(labelText: "Amount"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: dueDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setSheetState(() => dueDate = picked);
                                }
                              },
                              child: AbsorbPointer(
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: "Due date",
                                    hintText: DateFormat.yMMMd().format(dueDate),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: categories
                            .map((c) =>
                                DropdownMenuItem(value: c.name, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) =>
                            setSheetState(() => selectedCategory = v),
                        decoration:
                            const InputDecoration(labelText: "Category"),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent),
                              onPressed: () async {
                                final name = nameCtrl.text.trim();
                                final provider = providerCtrl.text.trim();
                                final amount =
                                    double.tryParse(amountCtrl.text.trim()) ??
                                        0.0;
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text("Please enter bill name")));
                                  return;
                                }
                                final billsBox = Hive.box<Bill>('bills');
                                if (item == null) {
                                  final newBill = Bill(
                                    name: name,
                                    provider:
                                        provider.isEmpty ? null : provider,
                                    amount: amount,
                                    dueDate: dueDate,
                                    isPaid: false,
                                    category: selectedCategory,
                                  );
                                  await billsBox.add(newBill);
                                } else {
                                  item.name = name;
                                  item.provider =
                                      provider.isEmpty ? null : provider;
                                  item.amount = amount;
                                  item.dueDate = dueDate;
                                  item.category = selectedCategory;
                                  await item.save();
                                }
                                Navigator.of(context).pop();
                                setState(() {});
                              },
                              child: Text(item == null
                                  ? "Add Bill"
                                  : "Save Changes"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (item != null)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey),
                              onPressed: () async {
                                item.isPaid = !item.isPaid;
                                await item.save();
                                Navigator.of(context).pop();
                                setState(() {});
                              },
                              child: Text(
                                  (item.isPaid) ? "Mark Unpaid" : "Mark Paid"),
                            )
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(Bill b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete bill"),
        content: const Text("Delete this bill? This cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text("Delete",
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final md = DateFormat.MMMd();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bills & Recharges"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMonth,
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedMonth = value);
                    },
                    items: _months
                        .map((m) =>
                            DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedYear,
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedYear = v);
                  },
                  items: _years
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text(y.toString())))
                      .toList(),
                ),
                const SizedBox(width: 6),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditBill(),
        backgroundColor: Colors.orangeAccent,
        icon: const Icon(Icons.add),
        label: const Text("Add Bill"),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ValueListenableBuilder(
          valueListenable: Hive.box<Bill>('bills').listenable(),
          builder: (context, Box<Bill> billsBox, _) {
            final allBills = billsBox.values.toList();

            final selectedMonth = _selectedMonthIndex;
            final selectedYear = _selectedYear;
            final monthStart = DateTime(selectedYear, selectedMonth, 1);
            final monthEnd = DateTime(selectedYear, selectedMonth + 1, 0);

            // Bills due in this month or overdue unpaid
            final visibleBills = allBills.where((b) {
              final due = b.dueDate;
              final dueThisMonth =
                  due.month == selectedMonth && due.year == selectedYear;
              final overdue = due.isBefore(monthStart) && !b.isPaid;
              return (dueThisMonth || overdue);
            }).toList();

            // Apply category filter
            final filtered = _selectedCategoryFilter == null
                ? visibleBills
                : visibleBills
                    .where((b) => b.category == _selectedCategoryFilter)
                    .toList();

            // Totals per category
            final Map<String, double> totals = {};
            for (final b in visibleBills) {
              totals[b.category ?? "Uncategorized"] =
                  (totals[b.category ?? "Uncategorized"] ?? 0) +
                      (b.amount ?? 0);
            }
            final totalAll = totals.values.fold(0.0, (a, b) => a + b);

            final catBox = Hive.box<Category>('categories');
            final categoryEntries = totals.entries.toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (categoryEntries.isNotEmpty) ...[
                      const Text("Bills by Category",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      LayoutBuilder(builder: (context, constraints) {
                        final spacing = 12.0;
                        final available = constraints.maxWidth;
                        final singleW = (available - spacing * 2) / 3;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: 12,
                          children: [
                            _categoryCardWidget("All", "📊",
                                Colors.orangeAccent.value, 0, singleW,
                                _selectedCategoryFilter == null,
                                isAll: true, allTotal: totalAll),
                            ...categoryEntries.map((entry) {
                              final cat = catBox.values.firstWhere(
                                  (c) => c.name == entry.key,
                                  orElse: () => Category(
                                      name: entry.key,
                                      icon: '🧾',
                                      color: Colors.blueAccent.value,
                                      type: "Expense"));
                              return _categoryCardWidget(
                                  cat.name,
                                  cat.icon,
                                  cat.color,
                                  entry.value,
                                  singleW,
                                  _selectedCategoryFilter == cat.name);
                            }),
                          ],
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                    const Text("Upcoming Bills (this month + overdue)",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (filtered.isEmpty)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: Text("No bills for this selection")))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final b = filtered[index];
                          final cat = _findCategory(b.category) ??
                              Category(
                                  name: b.category ?? "Uncategorized",
                                  icon: '🧾',
                                  color: Colors.blueAccent.value,
                                  type: "Expense");
                          final overdue = b.dueDate.isBefore(monthStart);
                          final status =
                              b.isPaid ? "Paid" : (overdue ? "Overdue" : "Pending");
                          final statusColor = _statusColor(b);

                          return Dismissible(
                            key: ValueKey(b.key),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete,
                                  color: Colors.white),
                            ),
                            confirmDismiss: (dir) async {
                              final ok = await _confirmDelete(b);
                              if (ok) {
                                await b.delete();
                                setState(() {});
                              }
                              return ok;
                            },
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              leading: CircleAvatar(
                                  backgroundColor:
                                      Color(cat.color).withOpacity(0.15),
                                  child: Text(cat.icon)),
                              title: Text(b.name ?? "",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                  "${b.provider ?? ''} • Due: ${md.format(b.dueDate)}\n$status",
                                  style: const TextStyle(fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("₹${(b.amount ?? 0).toStringAsFixed(0)}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10)),
                                    child: Text(status,
                                        style: TextStyle(
                                            color: statusColor, fontSize: 11)),
                                  )
                                ],
                              ),
                              onTap: () => _openAddEditBill(item: b),
                            ),
                          );
                        },
                      ),
                  ]),
            );
          },
        ),
      ),
    );
  }

  Widget _categoryCardWidget(String? name, String icon, int color, double total,
      double width, bool isSelected,
      {bool isAll = false, double? allTotal}) {
    final bgColor = Color(color);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isAll) {
            _selectedCategoryFilter = null;
          } else {
            _selectedCategoryFilter =
                (_selectedCategoryFilter == name) ? null : name;
          }
        });
      },
      child: SizedBox(
        width: width,
        child: Card(
          color: bgColor.withOpacity(isSelected ? 0.92 : 0.85),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: isSelected ? 6 : 2,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Column(
              children: [
                CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.18),
                    child: Text(icon, style: const TextStyle(fontSize: 18))),
                const SizedBox(height: 8),
                Text(isAll ? "All" : (name ?? "Unknown"),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(
                    "₹${(isAll ? (allTotal ?? 0.0) : total).toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
