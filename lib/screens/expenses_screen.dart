// lib/screens/expenses_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../models/category.dart';
import 'add_transaction_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
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
      DateFormat.MMMM().parse(_selectedMonth).month;

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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.18),
                  child: Text(icon, style: const TextStyle(fontSize: 18)),
                ),
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
                      fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteDialog(TransactionModel tx) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text("Delete expense"),
      content: const Text("Are you sure you want to delete this expense? This cannot be undone."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  return confirmed == true;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expenses"),
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
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
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
                      .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                      .toList(),
                ),
                const SizedBox(width: 6),
              ],
            ),
          )
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
          setState(() {});
        },
        label: const Text("Add"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orangeAccent,
      ),

      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ValueListenableBuilder(
          valueListenable: Hive.box<TransactionModel>('transactions').listenable(),
          builder: (context, Box<TransactionModel> txBox, _) {
            // Filter by selected month/year
            final monthTx = txBox.values.where((tx) {
              return tx.date.month == _selectedMonthIndex && tx.date.year == _selectedYear;
            }).toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            // Totals per category
            final Map<String, double> totals = {};
            for (final t in monthTx.where((e) => e.type == "Expense")) {
              totals[t.category] = (totals[t.category] ?? 0) + t.amount;
            }
            final totalSpent = totals.values.fold(0.0, (a, b) => a + b);

            final catBox = Hive.box<Category>('categories');
            final categoryEntries = totals.entries.toList();

            // filtered transactions according to selected category (or all)
            final filteredTx = _selectedCategoryFilter == null
                ? monthTx
                : monthTx.where((t) => t.category == _selectedCategoryFilter).toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories grid (All first)
                  if (categoryEntries.isNotEmpty) ...[
                    const Text("Spending by Category", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    LayoutBuilder(builder: (context, constraints) {
                      final spacing = 12.0;
                      final available = constraints.maxWidth;
                      final singleW = (available - spacing * 2) / 3;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: 12,
                        children: [
                          // All card shows overall total and acts as reset
                          _categoryCardWidget(
                              "All",
                              "📊",
                              Colors.orangeAccent.value,
                              0,
                              singleW,
                              _selectedCategoryFilter == null,
                              isAll: true,
                              allTotal: totalSpent),
                          // individual categories
                          ...categoryEntries.map((entry) {
                            final cat = catBox.values.firstWhere(
                              (c) => c.name == entry.key,
                              orElse: () => Category(
                                name: entry.key,
                                icon: '🧾',
                                color: Colors.blueAccent.value,
                                type: "Expense",
                              ),
                            );
                            return _categoryCardWidget(
                              cat.name,
                              cat.icon,
                              cat.color,
                              entry.value,
                              singleW,
                              _selectedCategoryFilter == cat.name,
                            );
                          }),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                  ] else ...[
                    // If no categories/expenses present, still show All card with zero
                    const SizedBox(height: 6),
                    LayoutBuilder(builder: (context, constraints) {
                      final available = constraints.maxWidth;
                      final singleW = available;
                      return _categoryCardWidget("All", "📊", Colors.orangeAccent.value, 0, singleW, _selectedCategoryFilter == null, isAll: true, allTotal: 0.0);
                    }),
                    const SizedBox(height: 16),
                  ],

                  const Text("Expenses List", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  if (filteredTx.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text("No expenses")),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredTx.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final tx = filteredTx[index];
                        final category = _findCategory(tx.category) ??
                            Category(name: tx.category, icon: '🧾', color: Colors.blueAccent.value, type: "Expense");

                        final sub = (tx.subCategory?.isNotEmpty == true) ? " • ${tx.subCategory}" : "";
                        final pm = (tx.paymentMethod?.isNotEmpty == true) ? " • ${tx.paymentMethod}" : "";

                        return Dismissible(
                          key: ValueKey(tx.key),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            final confirmed = await _confirmDeleteDialog(tx);
                            if (confirmed) {
                              // perform deletion
                              await tx.delete();
                              setState(() {});
                              return true;
                            }
                            return false;
                          },
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: Color(category.color).withOpacity(0.15),
                              child: Text(category.icon),
                            ),
                            title: Text("${category.name}$sub", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text("${DateFormat.yMMMd().format(tx.date)}$pm\n${tx.note ?? ''}", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                            trailing: Text("₹${tx.amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                            onTap: () async {
                              // Edit by tapping the row
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionScreen(transaction: tx, index: index)));
                              setState(() {});
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
