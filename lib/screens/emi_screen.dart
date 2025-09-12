// lib/screens/emi_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/emi.dart';
import '../models/category.dart';

class EmiScreen extends StatefulWidget {
  const EmiScreen({super.key});

  @override
  State<EmiScreen> createState() => _EmiScreenState();
}

class _EmiScreenState extends State<EmiScreen> {
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

  /// Helper: compute how many months should have been paid since startDate up to today.
  /// This is an *estimate* and doesn't rely on any 'monthsPaid' field in the model.
  int _computeMonthsPaidFromStart(Emi e) {
    final start = e.startDate;
    final today = DateTime.now();
    if (start.isAfter(today)) return 0;
    int months =
        (today.year - start.year) * 12 + (today.month - start.month);
    // if current day is before start day, the current month payment hasn't arrived yet
    if (today.day < start.day) months -= 1;
    if (months < 0) months = 0;
    if (e.tenureMonths != 0 && months > e.tenureMonths) months = e.tenureMonths;
    return months;
  }

  /// Compute months remaining
  int _computeMonthsRemaining(Emi e) {
    final paid = _computeMonthsPaidFromStart(e);
    final remain = (e.tenureMonths - paid);
    return remain < 0 ? 0 : remain;
  }

  /// Compute the next due date based on start + monthsPaid
  DateTime _computeNextDueDate(Emi e) {
    final paid = _computeMonthsPaidFromStart(e);
    // Next due is start + paid months
    final start = e.startDate;
    final totalMonths = (start.month - 1) + paid;
    final year = start.year + (totalMonths ~/ 12);
    final month = (totalMonths % 12) + 1;
    // pick same day if possible (clamp to last day of month)
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = start.day > lastDay ? lastDay : start.day;
    return DateTime(year, month, day);
  }

  Color _statusColor(Emi e) {
    if (!e.isActive) return Colors.green; // consider inactive as Done (green)
    final nowDate = DateTime.now();
    final nextDue = _computeNextDueDate(e);
    if (nextDue.isBefore(DateTime(nowDate.year, nowDate.month, nowDate.day))) {
      return Colors.red; // overdue
    }
    return Colors.orange; // pending this month
  }

  Future<void> _openAddEditEmi({Emi? item}) async {
    final nameCtrl = TextEditingController(text: item?.name ?? "");
    final amountCtrl =
        TextEditingController(text: item?.emiAmount?.toString() ?? "");
    DateTime startDate = item?.startDate ?? DateTime.now();
    final tenureCtrl =
        TextEditingController(text: item?.tenureMonths.toString() ?? "");

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
                                  item == null ? "Add EMI" : "Edit EMI",
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
                            labelText: "EMI name (e.g., Car Loan)"),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration:
                            const InputDecoration(labelText: "EMI Amount"),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setSheetState(() => startDate = picked);
                                }
                              },
                              child: AbsorbPointer(
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: "Start date",
                                    hintText:
                                        DateFormat.yMMMd().format(startDate),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: tenureCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: "Tenure (months)"),
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
                                final amount =
                                    double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                                final tenure =
                                    int.tryParse(tenureCtrl.text.trim()) ?? 0;
                                if (name.isEmpty || tenure <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Please enter valid name and tenure")));
                                  return;
                                }
                                final emiBox = Hive.box<Emi>('emis');
                                if (item == null) {
                                  final newEmi = Emi(
                                    name: name,
                                    emiAmount: amount,
                                    startDate: startDate,
                                    tenureMonths: tenure,
                                    isActive: true,
                                    monthsPaid: 0,
                                    category: selectedCategory,
                                  );
                                  await emiBox.add(newEmi);
                                } else {
                                  item.name = name;
                                  item.emiAmount = amount;
                                  item.startDate = startDate;
                                  item.tenureMonths = tenure;
                                  item.category = selectedCategory;
                                  await item.save();
                                }
                                Navigator.of(context).pop();
                                setState(() {});
                              },
                              child:
                                  Text(item == null ? "Add EMI" : "Save Changes"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (item != null)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey),
                              onPressed: () async {
                                item.isActive = !item.isActive;
                                await item.save();
                                Navigator.of(context).pop();
                                setState(() {});
                              },
                              child: Text(item.isActive
                                  ? "Mark Inactive"
                                  : "Mark Active"),
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

  Future<bool> _confirmDelete(Emi e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete EMI"),
        content: const Text("Delete this EMI? This cannot be undone."),
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
        title: const Text("EMI Tracker"),
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
        onPressed: () => _openAddEditEmi(),
        backgroundColor: Colors.orangeAccent,
        icon: const Icon(Icons.add),
        label: const Text("Add EMI"),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ValueListenableBuilder(
          valueListenable: Hive.box<Emi>('emis').listenable(),
          builder: (context, Box<Emi> emiBox, _) {
            final allEmis = emiBox.values.toList();

            final selectedMonth = _selectedMonthIndex;
            final selectedYear = _selectedYear;
            final monthStart = DateTime(selectedYear, selectedMonth, 1);

            // EMIs active in this month (due this month) OR overdue unpaid
            final visibleEmis = allEmis.where((e) {
              if (!e.isActive) return false;
              final due = _computeNextDueDate(e);
              final dueThisMonth =
                  due.month == selectedMonth && due.year == selectedYear;
              final overdue = due.isBefore(monthStart);
              return (dueThisMonth || overdue);
            }).toList();

            // Apply category filter
            final filtered = _selectedCategoryFilter == null
                ? visibleEmis
                : visibleEmis
                    .where((e) => e.category == _selectedCategoryFilter)
                    .toList();

            // Totals per category
            final Map<String, double> totals = {};
            for (final e in visibleEmis) {
              totals[e.category ?? "Uncategorized"] =
                  (totals[e.category ?? "Uncategorized"] ?? 0) +
                      (e.emiAmount ?? 0);
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
                      const Text("EMIs by Category",
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
                    const Text("Upcoming EMIs (this month + overdue)",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (filtered.isEmpty)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: Text("No EMIs for this selection")))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final e = filtered[index];
                          final cat = _findCategory(e.category) ??
                              Category(
                                  name: e.category ?? "Uncategorized",
                                  icon: '🧾',
                                  color: Colors.blueAccent.value,
                                  type: "Expense");
                          final overdue = _computeNextDueDate(e).isBefore(monthStart);
                          final status = e.isActive
                              ? (overdue ? "Overdue" : "Pending")
                              : "Done";
                          final statusColor = _statusColor(e);
                          final nextDue = _computeNextDueDate(e);
                          final monthsRemaining = _computeMonthsRemaining(e);

                          return Dismissible(
                            key: ValueKey(e.key),
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
                              final ok = await _confirmDelete(e);
                              if (ok) {
                                await e.delete();
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
                              title: Text(e.name ?? "",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                  "Next due: ${DateFormat.MMMd().format(nextDue)} • Remaining: $monthsRemaining",
                                  style: const TextStyle(fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("₹${(e.emiAmount ?? 0).toStringAsFixed(0)}",
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
                              onTap: () => _openAddEditEmi(item: e),
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
