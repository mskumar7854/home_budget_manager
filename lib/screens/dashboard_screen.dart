// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Models
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/emi.dart' as emimodel;
import '../models/bill.dart';
import '../models/task.dart';

// Screens (alias imports to avoid name collisions)
import 'add_transaction_screen.dart';
import 'todo_screen.dart';
import 'expenses_screen.dart';
import 'settings_screen.dart';
import 'emi_screen.dart' as emiui;
import 'bills_screen.dart' as billsui;
import 'upcoming_expenses_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _DashboardContent(),
    TodoScreen(),
    ExpensesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Use orange accent theme for BottomAppBar + FAB
    final accent = Colors.orangeAccent;
    return Scaffold(
      body: _pages[_selectedIndex],

      floatingActionButton: _selectedIndex == 0
          ? SizedBox(
              height: 70,
              width: 70,
              child: FloatingActionButton(
                shape: const CircleBorder(),
                backgroundColor: accent.shade700,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(),
                    ),
                  );
                  setState(() {}); // refresh dashboard after adding
                },
                child: const Icon(Icons.add, size: 36),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: accent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  Icons.dashboard,
                  color: _selectedIndex == 0 ? Colors.white : Colors.white70,
                ),
                onPressed: () => setState(() => _selectedIndex = 0),
                tooltip: 'Dashboard',
              ),
              IconButton(
                icon: Icon(
                  Icons.check_circle_outline,
                  color: _selectedIndex == 1 ? Colors.white : Colors.white70,
                ),
                onPressed: () => setState(() => _selectedIndex = 1),
                tooltip: 'To-Do',
              ),
              const SizedBox(width: 40), // space for FAB
              IconButton(
                icon: Icon(
                  Icons.payments,
                  color: _selectedIndex == 2 ? Colors.white : Colors.white70,
                ),
                onPressed: () => setState(() => _selectedIndex = 2),
                tooltip: 'Expenses',
              ),
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: _selectedIndex == 3 ? Colors.white : Colors.white70,
                ),
                onPressed: () => setState(() => _selectedIndex = 3),
                tooltip: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashboard content only (kept separate so nav stays clean)
class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  DateTime now = DateTime.now();
  String _selectedMonth = DateFormat.MMMM().format(DateTime.now());
  late List<int> _years;
  int _selectedYear = DateTime.now().year;
  final List<String> _months =
      List.generate(12, (i) => DateFormat.MMMM().format(DateTime(0, i + 1)));

  int get _selectedMonthIndex =>
      DateFormat.MMMM().parse(_selectedMonth).month; // 1..12

  @override
  void initState() {
    super.initState();
    final cy = DateTime.now().year;
    _years = [cy - 1, cy, cy + 1];
    _selectedYear = cy;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // add months helper (safe)
  DateTime _addMonths(DateTime d, int months) {
    final y = d.year + ((d.month - 1 + months) ~/ 12);
    final m0 = (d.month - 1 + months) % 12;
    final m = m0 + 1;
    final lastDay = DateTime(y, m + 1, 0).day;
    final day = d.day > lastDay ? lastDay : d.day;
    return DateTime(y, m, day);
  }

  // next due for EMI given monthsPaid
  DateTime _nextDueEmi(emimodel.Emi e) {
    return _addMonths(e.startDate, e.monthsPaid);
  }

  bool _isSameMonthYear(DateTime d, int month, int year) {
    return d.month == month && d.year == year;
  }

  // recurring detection (daily/weekly/monthly/yearly)
  bool _isRecurringInMonth(TransactionModel tx, int month, int year) {
    if (tx.isRecurring != true || tx.recurrenceType == null) return false;
    final recurrence = tx.recurrenceType!.toLowerCase();
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    if (tx.date.isAfter(lastDay)) return false;
    if (tx.endDate != null && tx.endDate!.isBefore(firstDay)) return false;

    if (recurrence == 'monthly') return true;
    if (recurrence == 'yearly') return tx.date.month == month;
    if (recurrence == 'daily') {
      final start = tx.date.isAfter(firstDay) ? tx.date : firstDay;
      return !start.isAfter(lastDay);
    }
    if (recurrence == 'weekly') {
      final start = tx.date;
      DateTime candidate = start;
      if (candidate.isBefore(firstDay)) {
        final diffDays = firstDay.difference(candidate).inDays;
        final weeksToAdd = (diffDays / 7).ceil();
        candidate = candidate.add(Duration(days: weeksToAdd * 7));
      }
      return !candidate.isAfter(lastDay);
    }
    return false;
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() {});
  }

  /// Create transaction and update EMI as paid for this month
  Future<void> _markEmiThisMonthPaid(emimodel.Emi e) async {
    e.monthsPaid = (e.monthsPaid + 1).clamp(0, e.tenureMonths);
    if (e.monthsPaid >= e.tenureMonths) e.isActive = false;
    await e.save();
    try {
      final txBox = Hive.box<TransactionModel>('transactions');
      final tx = TransactionModel(
        amount: e.emiAmount ?? 0,
        type: "Expense",
        category: e.category ?? e.name ?? "EMI",
        date: DateTime.now(),
        note: "EMI payment ${e.name ?? ''}",
        isRecurring: true,
      );
      await txBox.add(tx);
    } catch (ex) {
      debugPrint("Failed to create transaction for EMI from dashboard: $ex");
    }
    if (mounted) setState(() {});
  }

  /// Mark bill paid and advance (calls model helper)
  Future<void> _markBillPaid(Bill b) async {
    await b.markPaidAndAdvance();
    try {
      final txBox = Hive.box<TransactionModel>('transactions');
      final tx = TransactionModel(
        amount: b.amount ?? 0,
        type: "Expense",
        category: b.category ?? b.name ?? "Bills",
        date: DateTime.now(),
        note: "Paid ${b.name ?? ''}",
        isRecurring: b.isRecurring,
      );
      await txBox.add(tx);
    } catch (ex) {
      debugPrint("Failed to create transaction for bill from dashboard: $ex");
    }
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

  // status color coding
  Color _statusColorForEmi(emimodel.Emi e) {
    final next = _nextDueEmi(e);
    final remaining = (e.tenureMonths - e.monthsPaid).clamp(0, e.tenureMonths);
    if (remaining <= 0 || !e.isActive) return Colors.green;
    if (next.isBefore(DateTime.now())) return Colors.red;
    return Colors.orange;
  }

  Color _statusColorForBill(Bill b) {
    if (b.isPaid) return Colors.green;
    if (b.dueDate.isBefore(DateTime.now())) return Colors.red;
    return Colors.orange;
  }

  Widget _categoryCardWidget(Category? cat, double amount, double width) {
    final bgColor = Color(cat?.color ?? Colors.deepOrange.value);
    final iconText = cat?.icon ?? '🧾';
    final textColor = ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: bgColor.withOpacity(0.08),
          border: Border.all(color: bgColor.withOpacity(0.12)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
              ),
              child: Text(iconText, style: TextStyle(fontSize: 20, color: textColor)),
            ),
            const SizedBox(height: 10),
            Text(
              cat?.name ?? "Other",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              "₹${amount.toStringAsFixed(0)}",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: bgColor),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final md = DateFormat.MMMd();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Budget"),
        actions: [
          IconButton(
            tooltip: "EMI Tracker",
            icon: const Icon(Icons.credit_card),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const emiui.EmiScreen()),
              );
            },
          ),
          IconButton(
            tooltip: "Bills & Recharges",
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const billsui.BillsScreen()),
              );
            },
          ),
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
                    items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedYear,
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedYear = v);
                  },
                  items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ValueListenableBuilder(
          valueListenable: Hive.box<TransactionModel>('transactions').listenable(),
          builder: (context, Box<TransactionModel> txBox, _) {
            // filtered transactions for selected month/year
            final monthTx = txBox.values.where((tx) {
              return tx.date.month == _selectedMonthIndex && tx.date.year == _selectedYear;
            }).toList();

            final totalIncome = monthTx.where((t) => t.type == "Income").fold<double>(0, (s, t) => s + t.amount);
            final totalExpense = monthTx.where((t) => t.type == "Expense").fold<double>(0, (s, t) => s + t.amount);
            final balance = totalIncome - totalExpense;

            // EMIs: include items due this month OR overdue (carry forward)
            final emisBox = Hive.box<emimodel.Emi>('emis');
            final List<emimodel.Emi> emisAll = emisBox.values.toList();
            final selectedMonth = _selectedMonthIndex;
            final selectedYear = _selectedYear;

            final upcomingEmis = <emimodel.Emi>[];
            for (final e in emisAll) {
              if (!e.isActive && e.monthsPaid >= e.tenureMonths) continue;
              final next = _nextDueEmi(e);
              // due this selected month
              final dueThisMonth = _isSameMonthYear(next, selectedMonth, selectedYear) && (e.monthsPaid < e.tenureMonths);
              // overdue (next before selected month/year and unpaid)
              final overdue = next.isBefore(DateTime(selectedYear, selectedMonth, 1)) && (e.monthsPaid < e.tenureMonths);
              if (dueThisMonth || overdue) upcomingEmis.add(e);
            }
            upcomingEmis.sort((a, b) => _nextDueEmi(a).compareTo(_nextDueEmi(b)));

            // Bills: include those due this month OR overdue (carry forward)
            final billsBox = Hive.box<Bill>('bills');
            final billsAll = billsBox.values.toList();
            final upcomingBills = <Bill>[];
            for (final b in billsAll) {
              if (b.isPaid) {
                // skip paid; but if recurrence, mark if next due in month
                if (!b.isRecurring) continue;
              }
              final due = b.dueDate;
              final dueThisMonth = _isSameMonthYear(due, selectedMonth, selectedYear) && !b.isPaid;
              final overdue = due.isBefore(DateTime(selectedYear, selectedMonth, 1)) && !b.isPaid;
              if (dueThisMonth || overdue) upcomingBills.add(b);
            }
            upcomingBills.sort((a, b) => a.dueDate.compareTo(b.dueDate));

            // ------------------------
            // Recurring templates for this month -> filter out ones already paid
            // ------------------------
            // Find "recurring templates" from transactions (these are entries with isRecurring == true and a recurrenceType)
            final allRecurringTemplates = txBox.values
                .where((t) => t.isRecurring == true && t.recurrenceType != null && _isRecurringInMonth(t, selectedMonth, selectedYear))
                .toList();

            // Filter out templates for which there exists a paid/recorded expense in the same month.
            // We consider a recurring template "paid" for the month if there exists any transaction (type Expense)
            // with same category (or same title), same month/year. This is a heuristic — adjust if you store templates differently.
            final recurringUnpaid = allRecurringTemplates.where((tpl) {
              final hasPaidInstance = txBox.values.any((existing) {
                // paid instance criteria:
                //  - same month/year
                //  - same category (or same note) and type is Expense
                //  - amount similar (optional, omitted for flexibility)
                return existing.type == "Expense" &&
                    existing.category == tpl.category &&
                    existing.date.month == selectedMonth &&
                    existing.date.year == selectedYear;
              });
              return !hasPaidInstance;
            }).toList();

            // Sum unpaid recurring amounts to include in upcoming totals
            final recurringTxTotal = recurringUnpaid.fold<double>(0, (s, t) => s + t.amount);

            // upcoming totals (EMI + Bills + unpaid recurring templates)
            final upcomingEmiTotal = upcomingEmis.fold<double>(0, (s, e) => s + (e.emiAmount ?? 0));
            final upcomingBillsTotal = upcomingBills.fold<double>(0, (s, b) => s + (b.amount ?? 0));
            final upcomingExpensesTotal = upcomingEmiTotal + upcomingBillsTotal + recurringTxTotal;

            // To-Do preview
            final tasksBox = Hive.box<Task>('tasks');
            final today = _dateOnly(DateTime.now());
            bool sameDay(DateTime a, DateTime b) => _dateOnly(a) == _dateOnly(b);
            final previewTasks = tasksBox.values.where((t) {
              return sameDay(t.dueDate, today) || sameDay(t.dueDate, today.add(const Duration(days: 1)));
            }).toList()
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

            // build category totals for selected month
            final Map<String, double> totals = {};
            for (final t in monthTx.where((e) => e.type == "Expense")) {
              totals[t.category] = (totals[t.category] ?? 0) + t.amount;
            }
            final categoryEntries = totals.entries.toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top summary
                  Row(
                    children: [
                      _buildSummaryCard("Income", totalIncome, Colors.green),
                      _buildSummaryCard("Expenses", totalExpense, Colors.red),
                      _buildSummaryCard("Balance", balance, Colors.deepPurple),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Upcoming Expenses card (clickable)
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpcomingExpensesScreen(month: selectedMonth, year: selectedYear),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.calendar_today, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Upcoming Expenses (${_selectedMonth} $_selectedYear)",
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text("${upcomingEmis.length} EMIs • ${upcomingBills.length} Bills • ${recurringUnpaid.isEmpty ? 'No unpaid recurring' : 'Unpaid recurring present'}",
                                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text("₹${upcomingExpensesTotal.toStringAsFixed(0)}",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Spending by category - modern 3-per-row cards
                  if (categoryEntries.isNotEmpty) ...[
                    const Text("Spending by Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    LayoutBuilder(builder: (context, constraints) {
                      final spacing = 12.0;
                      final available = constraints.maxWidth;
                      final singleW = (available - spacing * 2) / 3;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: 12,
                        children: categoryEntries.map((e) {
                          final cat = _findCategory(e.key);
                          return _categoryCardWidget(cat, e.value, singleW);
                        }).toList(),
                      );
                    }),
                    const SizedBox(height: 14),
                  ],

                  // EMIs - compact, color-coded, no delete icon
                  if (upcomingEmis.isNotEmpty) ...[
                    const Text("EMIs (this month + overdue)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Column(
                      children: upcomingEmis.map((e) {
                        final next = _nextDueEmi(e);
                        final remaining = (e.tenureMonths - e.monthsPaid).clamp(0, e.tenureMonths);
                        final statusColor = _statusColorForEmi(e);
                        final overdue = next.isBefore(DateTime.now()) && (e.monthsPaid < e.tenureMonths);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const emiui.EmiScreen()));
                            },
                            onLongPress: () async {
                              e.isActive = !e.isActive;
                              if (!e.isActive && e.monthsPaid < e.tenureMonths) {
                                e.monthsPaid = (e.monthsPaid + 1).clamp(0, e.tenureMonths);
                              }
                              if (e.monthsPaid >= e.tenureMonths) e.isActive = false;
                              await e.save();
                              setState(() {});
                            },
                            leading: CircleAvatar(radius: 16, backgroundColor: statusColor, child: const Icon(Icons.credit_card, color: Colors.white, size: 16)),
                            title: Text(e.name ?? "EMI", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              "${overdue ? 'Overdue • ' : ''}Next: ${md.format(next)} • Remaining: $remaining\n₹${(e.emiAmount ?? 0).toStringAsFixed(0)}",
                              style: const TextStyle(fontSize: 11, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.check_circle, size: 20, color: Colors.orangeAccent),
                              tooltip: e.isActive ? "Mark Paid" : "Already done",
                              onPressed: (e.isActive && e.monthsPaid < e.tenureMonths) ? () => _markEmiThisMonthPaid(e) : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Bills - compact, color-coded
                  if (upcomingBills.isNotEmpty) ...[
                    const Text("Bills & Recharges (this month + overdue)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Column(
                      children: upcomingBills.map((b) {
                        final statusColor = _statusColorForBill(b);
                        final overdue = b.dueDate.isBefore(DateTime.now()) && !b.isPaid;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            onLongPress: () {
                              b.isPaid = !b.isPaid;
                              b.save();
                              setState(() {});
                            },
                            leading: CircleAvatar(radius: 16, backgroundColor: statusColor, child: const Icon(Icons.receipt_long, color: Colors.white, size: 16)),
                            title: Text(b.name ?? "", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
                            subtitle: Text("${b.provider ?? ''} • Due: ${md.format(b.dueDate)}${overdue ? ' • Overdue' : ''}",
                                style: const TextStyle(fontSize: 11)),
                            trailing: IconButton(
                              icon: Icon(Icons.check_circle, size: 20, color: b.isPaid ? Colors.grey : Colors.orangeAccent),
                              tooltip: b.isPaid ? "Already paid" : "Mark paid",
                              onPressed: b.isPaid ? null : () => _markBillPaid(b),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Unpaid recurring templates (show only unpaid templates)
                  if (recurringUnpaid.isNotEmpty) ...[
                    const Text("Recurring (unpaid this month)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Column(
                      children: recurringUnpaid.map((t) {
                        final cat = _findCategory(t.category);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: _categoryLeadingIcon(cat, false),
                            title: Text(cat?.name ?? t.category ?? "Recurring", style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text("${t.recurrenceType} • ${DateFormat.yMMMd().format(t.date)}", style: const TextStyle(fontSize: 11)),
                            trailing: Text("₹${t.amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // To-Do preview
                  if (previewTasks.isNotEmpty) ...[
                    const Text("To-Do (today & tomorrow)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Column(
                      children: previewTasks.map((t) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: Icon(t.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: t.isCompleted ? Colors.green : Colors.grey, size: 20),
                            title: Text(t.title, style: const TextStyle(fontSize: 13)),
                            subtitle: Text("Due: ${DateFormat.MMMd().format(t.dueDate)} • Priority: ${t.priority}", style: const TextStyle(fontSize: 11)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Recent Transactions
                  const Text("Recent Transactions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Column(
                    children: monthTx.reversed.take(6).map((tx) {
                      final cat = _findCategory(tx.category);
                      final isIncome = tx.type == "Income";
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: _categoryLeadingIcon(cat, isIncome),
                          title: Text((cat?.name ?? tx.category) + (tx.subCategory != null ? " • ${tx.subCategory}" : ""), style: const TextStyle(fontSize: 13)),
                          subtitle: Text(DateFormat.yMMMd().format(tx.date), style: const TextStyle(fontSize: 11)),
                          trailing: Text("₹${tx.amount.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build the three top summary cards (kept compact)
  Widget _buildSummaryCard(String title, double value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text("₹${value.toStringAsFixed(0)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryLeadingIcon(Category? cat, bool isIncome) {
    if (isIncome) {
      return const Icon(Icons.arrow_downward, color: Colors.green, size: 18);
    }
    final color = Color(cat?.color ?? Colors.red.value);
    final emoji = cat?.icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: color, size: 10),
        const SizedBox(width: 6),
        Text(emoji ?? '🧾'),
      ],
    );
  }
}
