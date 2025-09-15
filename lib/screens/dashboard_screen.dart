import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/emi.dart' as emimodel;
import '../models/bill.dart';
import '../models/task.dart';

// Screens (alias where collisions possible)
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

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  final List<Widget> _pages = const [
    _DashboardContent(),
    TodoScreen(),
    ExpensesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Colors.orangeAccent;
    
    return Scaffold(
      body: _pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? AnimatedBuilder(
              animation: _fabAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fabAnimation.value,
                  child: Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.shade700,
                          accent.shade700,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.shade700.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(35),
                        onTapDown: (_) => _fabAnimationController.forward(),
                        onTapUp: (_) => _fabAnimationController.reverse(),
                        onTapCancel: () => _fabAnimationController.reverse(),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddTransactionScreen(),
                            ),
                          );
                          setState(() {}); // refresh dashboard after adding
                        },
                        child: const Center(
                          child: Icon(
                            Icons.add_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: accent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomAppBar(
            color: Colors.transparent,
            elevation: 0,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            child: SizedBox(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navButton(Icons.dashboard_rounded, 0, 'Dashboard'),
                  _navButton(Icons.check_circle_outline_rounded, 1, 'To-Do'),
                  const SizedBox(width: 40), // for FAB
                  _navButton(Icons.payments_rounded, 2, 'Expenses'),
                  _navButton(Icons.settings_rounded, 3, 'Settings'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, int index, String tooltip) {
    final isSelected = _selectedIndex == index;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
          size: 24,
        ),
        onPressed: () => setState(() => _selectedIndex = index),
        tooltip: tooltip,
      ),
    );
  }
}

/// Dashboard Content Only
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
  final List<String> _months = List.generate(12, (i) => DateFormat.MMMM().format(DateTime(0, i + 1)));
  
  int get _selectedMonthIndex => DateFormat.MMMM().parse(_selectedMonth).month;

  @override
  void initState() {
    super.initState();
    final cy = DateTime.now().year;
    _years = [cy - 1, cy, cy + 1];
    _selectedYear = cy;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _addMonths(DateTime d, int months) {
    final y = d.year + ((d.month - 1 + months) ~/ 12);
    final m0 = (d.month - 1 + months) % 12;
    final m = m0 + 1;
    final lastDay = DateTime(y, m + 1, 0).day;
    final day = d.day > lastDay ? lastDay : d.day;
    return DateTime(y, m, day);
  }

  DateTime _nextDueEmi(emimodel.Emi e) => _addMonths(e.startDate, e.monthsPaid);

  bool _isSameMonthYear(DateTime d, int month, int year) =>
      d.month == month && d.year == year;

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
      DateTime candidate = tx.date;
      if (candidate.isBefore(firstDay)) {
        final diff = firstDay.difference(candidate).inDays;
        final weeksToAdd = (diff / 7).ceil();
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
      debugPrint("Failed to create transaction for EMI: $ex");
    }
    if (mounted) setState(() {});
  }

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
      debugPrint("Failed to create transaction for bill: $ex");
    }
    if (mounted) setState(() {});
  }

  Category? _findCategory(String? name) {
    if (name == null) return null;
    final box = Hive.box<Category>('categories');
    try {
      return box.values.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

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

  Widget _modernCategoryCard(Category? cat, double amount, double width) {
  final bgColor = Colors.white; // White background
  final iconBgColor = Color(cat?.color ?? Colors.deepOrange.value); // Category accent color
  final iconText = cat?.icon ?? '🧾';
  const textColor = Colors.black87; // Always black text

  return Container(
    width: width,
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconBgColor,
            boxShadow: [
              BoxShadow(
                color: iconBgColor.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            iconText,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          cat?.name ?? "Other",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        Text(
          "₹${amount.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: iconBgColor,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    ),
  );
}




  @override
  Widget build(BuildContext context) {
    final md = DateFormat.MMMd();
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orangeAccent.shade200,
                Colors.orangeAccent.shade400,
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orangeAccent.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
        title: const Text(
          "My Budget",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: "EMI Tracker",
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const emiui.EmiScreen()),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: "Bills & Recharges",
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const billsui.BillsScreen()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () => _showMonthYearPicker(context),
                icon: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
                label: Text(
                  "${DateFormat.MMM().format(DateTime(0, _selectedMonthIndex))} $_selectedYear",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: Colors.orangeAccent,
        child: ValueListenableBuilder(
          valueListenable: Hive.box<TransactionModel>('transactions').listenable(),
          builder: (context, Box<TransactionModel> txBox, _) {
            final monthTx = txBox.values.where((tx) {
              return tx.date.month == _selectedMonthIndex && tx.date.year == _selectedYear;
            }).toList();

            // Fix: Use double for all financial calculations
            final totalIncome = monthTx.where((t) => t.type == "Income").fold<double>(0.0, (s, t) => s + t.amount);
            final totalExpense = monthTx.where((t) => t.type == "Expense").fold<double>(0.0, (s, t) => s + t.amount);
            final balance = totalIncome - totalExpense;

            // EMIs: due OR overdue
            final emisBox = Hive.box<emimodel.Emi>('emis');
            final emisAll = emisBox.values.toList();
            final upcomingEmis = <emimodel.Emi>[];
            final selectedMonth = _selectedMonthIndex;
            final selectedYear = _selectedYear;

            for (final e in emisAll) {
              if (!e.isActive && e.monthsPaid >= e.tenureMonths) continue;
              final next = _nextDueEmi(e);
              final dueThisMonth = _isSameMonthYear(next, selectedMonth, selectedYear) && (e.monthsPaid < e.tenureMonths);
              final overdue = next.isBefore(DateTime(selectedYear, selectedMonth, 1)) && (e.monthsPaid < e.tenureMonths);
              if (dueThisMonth || overdue) upcomingEmis.add(e);
            }
            upcomingEmis.sort((a, b) => _nextDueEmi(a).compareTo(_nextDueEmi(b)));

            // Bills: due OR overdue
            final billsBox = Hive.box<Bill>('bills');
            final billsAll = billsBox.values.toList();
            final upcomingBills = <Bill>[];

            for (final b in billsAll) {
              if (b.isPaid && !b.isRecurring) continue;
              final due = b.dueDate;
              final dueThisMonth = _isSameMonthYear(due, selectedMonth, selectedYear) && !b.isPaid;
              final overdue = due.isBefore(DateTime(selectedYear, selectedMonth, 1)) && !b.isPaid;
              if (dueThisMonth || overdue) upcomingBills.add(b);
            }
            upcomingBills.sort((a, b) => a.dueDate.compareTo(b.dueDate));

            // Recurring templates (unpaid)
            final allRecurringTemplates = txBox.values
                .where((t) => t.isRecurring == true && t.recurrenceType != null && _isRecurringInMonth(t, selectedMonth, selectedYear))
                .toList();

            final recurringUnpaid = allRecurringTemplates.where((tpl) {
              final hasPaidInstance = txBox.values.any((existing) {
                return existing.type == "Expense" &&
                    existing.category == tpl.category &&
                    existing.date.month == selectedMonth &&
                    existing.date.year == selectedYear;
              });
              return !hasPaidInstance;
            }).toList();

            // Fix: Use double for all calculations
            final recurringTxTotal = recurringUnpaid.fold<double>(0.0, (s, t) => s + t.amount);
            final upcomingEmiTotal = upcomingEmis.fold<double>(0.0, (s, e) => s + (e.emiAmount ?? 0));
            final upcomingBillsTotal = upcomingBills.fold<double>(0.0, (s, b) => s + (b.amount ?? 0));
            final upcomingExpensesTotal = upcomingEmiTotal + upcomingBillsTotal + recurringTxTotal;

            final tasksBox = Hive.box<Task>('tasks');
            final today = _dateOnly(DateTime.now());
            bool sameDay(DateTime a, DateTime b) => _dateOnly(a) == _dateOnly(b);

            final previewTasks = tasksBox.values.where((t) {
              return sameDay(t.dueDate, today) || sameDay(t.dueDate, today.add(const Duration(days: 1)));
            }).toList()
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

            final Map<String, double> totals = {};
            for (final t in monthTx.where((e) => e.type == "Expense")) {
              totals[t.category] = (totals[t.category] ?? 0) + t.amount;
            }
            final categoryEntries = totals.entries.toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Only Summary Cards Row (removed hero balance card)
                  _buildSummaryCardsSection(totalIncome, totalExpense, balance),
                  const SizedBox(height: 20),
                  
                  // Upcoming Expenses Card
                  _modernUpcomingExpensesCard(upcomingEmis.length, upcomingBills.length, recurringUnpaid.isEmpty, upcomingExpensesTotal),
                  const SizedBox(height: 24),

                  if (categoryEntries.isNotEmpty)
                    ..._modernSpendingByCategory(categoryEntries),

                  if (upcomingEmis.isNotEmpty)
                    ..._modernEmiSection(upcomingEmis, md),

                  if (upcomingBills.isNotEmpty)
                    ..._modernBillsSection(upcomingBills, md),

                  if (recurringUnpaid.isNotEmpty)
                    ..._modernRecurringSection(recurringUnpaid),

                  if (previewTasks.isNotEmpty)
                    ..._modernTodoSection(previewTasks),

                  _modernTransactionsSection(monthTx),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Summary Cards Section with Teal Gradient Background
Widget _buildSummaryCardsSection(double totalIncome, double totalExpense, double balance) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.teal.shade100.withOpacity(0.5),
          Colors.teal.shade200.withOpacity(0.5),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.teal.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        _buildModernSummaryCard(
          "Income",
          totalIncome,
          Colors.green,
          Icons.arrow_upward_rounded,
        ),
        const SizedBox(width: 12),
        _buildModernSummaryCard(
          "Expenses",
          totalExpense,
          Colors.red,
          Icons.arrow_downward_rounded,
        ),
        const SizedBox(width: 12),
        _buildModernSummaryCard(
          "Net",
          balance,
          Colors.deepPurple,
          Icons.account_balance_wallet_rounded,
        ),
      ],
    ),
  );
}

/// Individual Summary Card
Widget _buildModernSummaryCard(
  String title,
  double value,
  Color color,
  IconData icon,
) {
  return Expanded(
    child: SizedBox(
      height: 115,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "₹${value.toStringAsFixed(0)}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  /// Modern Upcoming Expenses Card
  Widget _modernUpcomingExpensesCard(int emiCount, int billCount, bool noRecurring, double total) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UpcomingExpensesScreen(month: _selectedMonthIndex, year: _selectedYear),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orangeAccent.shade100,
              Colors.orangeAccent.shade200,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: Colors.orangeAccent.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Upcoming Expenses",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.orangeAccent.shade700,
                    ),
                  ),
                  Text(
                    "${_selectedMonth} $_selectedYear",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orangeAccent.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$emiCount EMIs • $billCount Bills • ${noRecurring ? 'No unpaid recurring' : 'Unpaid recurring present'}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "₹${total.toStringAsFixed(0)}",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.orangeAccent.shade700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modern Spending by Category section (3 cards per row)
List<Widget> _modernSpendingByCategory(List<MapEntry<String, double>> categories) {
  return [
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade100.withOpacity(0.5),
            Colors.red.shade200.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade700.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Spending by Category ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    children: [
                      TextSpan(
                        text: '(this month)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final spacing = 6.0;
            final cardsPerRow = 3;
            final totalSpacing = spacing * (cardsPerRow - 1);
            final width = (constraints.maxWidth - totalSpacing) / cardsPerRow;
            return Wrap(
              spacing: spacing,
              runSpacing: 8,
              children: categories.map((e) {
                final cat = _findCategory(e.key);
                return SizedBox(
                  width: width,
                  child: _modernCategoryCard(cat, e.value, width),
                );
              }).toList(),
            );
          }),
        ],
      ),
    ),
    const SizedBox(height: 24),
  ];
}

  /// Modern EMI Section with separate card style
  List<Widget> _modernEmiSection(List<emimodel.Emi> emis, DateFormat md) {
    return [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade100,
              Colors.blue.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.credit_card_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text.rich(
    TextSpan(
      text: 'EMIs ',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
      children: [
        TextSpan(text: '(this month + overdue)', style: TextStyle(fontSize: 12)),
      ],
    ),
    overflow: TextOverflow.ellipsis,
  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...emis.map((e) {
              final next = _nextDueEmi(e);
              final remaining = (e.tenureMonths - e.monthsPaid).clamp(0, e.tenureMonths);
              final statusColor = _statusColorForEmi(e);
              final overdue = next.isBefore(DateTime.now()) && (e.monthsPaid < e.tenureMonths);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.credit_card_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.name ?? "EMI",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${overdue ? 'Overdue • ' : ''}Next: ${md.format(next)}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: overdue ? Colors.red : Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "Remaining: $remaining months",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₹${(e.emiAmount ?? 0).toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: (e.isActive && e.monthsPaid < e.tenureMonths)
                                    ? () => _markEmiThisMonthPaid(e)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (e.isActive && e.monthsPaid < e.tenureMonths)
                                        ? Colors.orangeAccent.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 20,
                                    color: (e.isActive && e.monthsPaid < e.tenureMonths)
                                        ? Colors.orangeAccent
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  /// Modern Bills Section with separate card style
  List<Widget> _modernBillsSection(List<Bill> bills, DateFormat md) {
    return [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade100,
              Colors.purple.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  
  child: Text.rich(
    TextSpan(
      text: 'Bills & Recharges ',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
      children: [
        TextSpan(text: '(this month + overdue)', style: TextStyle(fontSize: 12)),
      ],
    ),
    overflow: TextOverflow.ellipsis,
  ),


                ),
              ],
            ),
            const SizedBox(height: 16),
            ...bills.map((b) {
              final statusColor = _statusColorForBill(b);
              final overdue = b.dueDate.isBefore(DateTime.now()) && !b.isPaid;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onLongPress: () {
                      b.isPaid = !b.isPaid;
                      b.save();
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.name ?? "",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${b.provider ?? ''} • Due: ${md.format(b.dueDate)}${overdue ? ' • Overdue' : ''}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: overdue ? Colors.red : Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₹${(b.amount ?? 0).toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: b.isPaid ? null : () => _markBillPaid(b),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: b.isPaid
                                        ? Colors.grey.withOpacity(0.1)
                                        : Colors.orangeAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 20,
                                    color: b.isPaid ? Colors.grey : Colors.orangeAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  /// Modern Recurring Section with separate card style
  List<Widget> _modernRecurringSection(List<TransactionModel> recurs) {
    return [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade100,
              Colors.indigo.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.repeat_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Recurring (unpaid this month)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recurs.map((t) {
              final cat = _findCategory(t.category);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(cat?.color ?? Colors.indigo.value).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          cat?.icon ?? '🔄',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat?.name ?? t.category ?? "Recurring",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${t.recurrenceType} • ${DateFormat.yMMMd().format(t.date)}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "₹${t.amount.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  /// Modern Todo Section with separate card style
  List<Widget> _modernTodoSection(List<Task> tasks) {
    return [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade100,
              Colors.teal.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "To-Do (today & tomorrow)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tasks.map((t) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: t.isCompleted 
                              ? Colors.green.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          t.isCompleted 
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: t.isCompleted ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Due: ${DateFormat.MMMd().format(t.dueDate)} • Priority: ${t.priority}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  /// Modern Transactions Section with separate card style
  Widget _modernTransactionsSection(List<TransactionModel> txs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orangeAccent.shade100,
            Colors.orangeAccent.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.shade700,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  "Recent Transactions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...txs.reversed.take(6).map((tx) {
            final cat = _findCategory(tx.category);
            final isIncome = tx.type == "Income";
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isIncome ? Colors.green : Color(cat?.color ?? Colors.red.value)).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: isIncome
                          ? const Icon(Icons.arrow_upward_rounded, color: Colors.green, size: 20)
                          : Text(cat?.icon ?? '💰', style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (cat?.name ?? tx.category) + (tx.subCategory != null ? " • ${tx.subCategory}" : ""),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.yMMMd().format(tx.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "₹${tx.amount.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Enhanced Month-Year Picker
  Future<void> _showMonthYearPicker(BuildContext context) async {
    final List<String> monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    int tempYear = _selectedYear;
    int tempMonthIndex = _selectedMonthIndex;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Column(
                children: [
                  const Text(
                    "Select Month & Year",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orangeAccent.shade200, Colors.orangeAccent.shade400],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => setModalState(() => tempYear--),
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                        ),
                        Text(
                          '$tempYear',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setModalState(() => tempYear++),
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 320,
                height: 240,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.0,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final isSelected = (index + 1) == tempMonthIndex;
                    
                    return GestureDetector(
                      onTap: () => setModalState(() => tempMonthIndex = index + 1),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isSelected 
                            ? LinearGradient(colors: [Colors.orangeAccent, Colors.orangeAccent.shade400])
                            : null,
                          color: isSelected ? null : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.orangeAccent : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            monthNames[index],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedYear = tempYear;
                      final fullMonthNames = [
                        'January', 'February', 'March', 'April', 'May', 'June',
                        'July', 'August', 'September', 'October', 'November', 'December'
                      ];
                      _selectedMonth = fullMonthNames[tempMonthIndex - 1];
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: const Text("Apply", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}