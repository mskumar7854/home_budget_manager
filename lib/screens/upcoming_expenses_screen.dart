// lib/screens/upcoming_expenses_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../models/emi.dart' as emimodel;
import '../models/bill.dart';
import '../models/category.dart';

import 'emi_screen.dart' as emiui;
import 'bills_screen.dart' as billsui;

class UpcomingExpensesScreen extends StatelessWidget {
  final int month;
  final int year;

  const UpcomingExpensesScreen({Key? key, required this.month, required this.year}) : super(key: key);

  DateTime _addMonths(DateTime d, int months) {
    final y = d.year + ((d.month - 1 + months) ~/ 12);
    final m = ((d.month - 1 + months) % 12) + 1;
    final lastDay = DateTime(y, m + 1, 0).day;
    final day = d.day > lastDay ? lastDay : d.day;
    return DateTime(y, m, day);
  }

  bool _isSameMonthYear(DateTime d, int m, int y) => d.month == m && d.year == y;

  Category? _findCategory(String? name) {
    if (name == null) return null;
    final box = Hive.box<Category>('categories');
    try {
      return box.values.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final md = DateFormat.MMMd();
    final Box<emimodel.Emi> emisBox = Hive.box<emimodel.Emi>('emis');
    final Box<Bill> billsBox = Hive.box<Bill>('bills');
    final firstDayOfSelected = DateTime(year, month, 1);

    // EMIs due this month (active) OR overdue (unpaid and due before this month)
    final upcomingEmis = emisBox.values.where((e) {
      if (e.monthsPaid >= e.tenureMonths) return false; // finished
      final next = _addMonths(e.startDate, e.monthsPaid);
      final dueThisMonth = e.isActive && _isSameMonthYear(next, month, year) && (e.monthsPaid < e.tenureMonths);
      final overdue = e.isActive && next.isBefore(firstDayOfSelected) && (e.monthsPaid < e.tenureMonths);
      return dueThisMonth || overdue;
    }).toList()
      ..sort((a, b) => _addMonths(a.startDate, a.monthsPaid).compareTo(_addMonths(b.startDate, b.monthsPaid)));

    // Bills due this month (unpaid) OR overdue (unpaid and due before this month)
    final upcomingBills = billsBox.values.where((b) {
      if (b.isPaid) return false;
      final due = b.dueDate;
      final dueThisMonth = _isSameMonthYear(due, month, year);
      final overdue = due.isBefore(firstDayOfSelected);
      return dueThisMonth || overdue;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      appBar: AppBar(
        title: Text("Upcoming Expenses - ${DateFormat.MMMM().format(DateTime(0, month))} $year"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // EMIs Section
            const Text("EMIs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (upcomingEmis.isEmpty)
              const Text("No EMIs this month", style: TextStyle(color: Colors.black54))
            else
              Column(
                children: upcomingEmis.map((e) {
                  final next = _addMonths(e.startDate, e.monthsPaid);
                  final isOverdue = next.isBefore(firstDayOfSelected);
                  final cat = _findCategory(e.category ?? e.name);
                  final bg = isOverdue ? Colors.red.shade400 : Colors.orangeAccent;
                  final subtitleStyle = TextStyle(
                    fontSize: 12,
                    color: isOverdue ? Colors.red : Colors.black54,
                  );
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: bg,
                        child: cat?.icon != null
                            ? Text(cat!.icon, style: const TextStyle(fontSize: 18))
                            : const Icon(Icons.credit_card, color: Colors.white),
                      ),
                      title: Text(
                        e.name ?? "EMI",
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        "${isOverdue ? 'Overdue • ' : ''}Next: ${md.format(next)} • Remaining: ${(e.tenureMonths - e.monthsPaid).clamp(0, e.tenureMonths)}\n₹${(e.emiAmount ?? 0).toStringAsFixed(0)}",
                        style: subtitleStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("₹${(e.emiAmount ?? 0).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => emiui.EmiScreen())),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),

            // Bills Section
            const Text("Bills & Recharges", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (upcomingBills.isEmpty)
              const Text("No bills this month", style: TextStyle(color: Colors.black54))
            else
              Column(
                children: upcomingBills.map((b) {
                  final isOverdue = b.dueDate.isBefore(firstDayOfSelected);
                  final cat = _findCategory(b.category ?? b.name);
                  final bg = isOverdue ? Colors.red.shade400 : Colors.orangeAccent;
                  final subtitleStyle = TextStyle(fontSize: 12, color: isOverdue ? Colors.red : Colors.black54);
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: bg,
                        child: cat?.icon != null ? Text(cat!.icon, style: const TextStyle(fontSize: 18)) : const Icon(Icons.receipt_long, color: Colors.white),
                      ),
                      title: Text(
                        b.name ?? "Bill",
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        "${isOverdue ? 'Overdue • ' : ''}${b.provider ?? ''} • Due: ${md.format(b.dueDate)}",
                        style: subtitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text("₹${(b.amount ?? 0).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => billsui.BillsScreen())),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),

            // Note / footer
            const Divider(),
            const SizedBox(height: 8),
            Text(
              "Tip: Tap a row to open full list. Overdue items are highlighted in red.",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
