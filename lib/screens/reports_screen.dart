import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedMonth = DateFormat.MMMM().format(DateTime.now());
  final List<String> _months = List.generate(
    12,
    (i) => DateFormat.MMMM().format(DateTime(0, i + 1)),
  );

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<TransactionModel>('transactions');

    // Filter transactions by selected month
    final filtered = box.values.where((tx) {
      return DateFormat.MMMM().format(tx.date) == _selectedMonth;
    }).toList();

    double totalIncome = filtered
        .where((t) => t.type == "Income")
        .fold(0, (sum, t) => sum + t.amount);
    double totalExpenses = filtered
        .where((t) => t.type == "Expense")
        .fold(0, (sum, t) => sum + t.amount);

    // Group expenses by category
    final Map<String, double> expenseByCategory = {};
    for (var tx in filtered.where((t) => t.type == "Expense")) {
      expenseByCategory[tx.category] =
          (expenseByCategory[tx.category] ?? 0) + tx.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        actions: [
          DropdownButton<String>(
            value: _selectedMonth,
            underline: const SizedBox(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedMonth = value;
                });
              }
            },
            items: _months
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
          ),
        ],
      ),
      body: filtered.isEmpty
          ? const Center(child: Text("No data for this month"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Pie Chart for Expenses by Category
                  const Text(
                    "Expenses by Category",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: expenseByCategory.entries.map((entry) {
                          final percentage =
                              (entry.value / totalExpenses) * 100;
                          return PieChartSectionData(
                            value: entry.value,
                            title: "${entry.key}\n${percentage.toStringAsFixed(1)}%",
                            radius: 80,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Bar Chart for Income vs Expenses
                  const Text(
                    "Income vs Expenses",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: totalIncome,
                                color: Colors.green,
                                width: 30,
                              ),
                            ],
                            showingTooltipIndicators: [0],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: totalExpenses,
                                color: Colors.red,
                                width: 30,
                              ),
                            ],
                            showingTooltipIndicators: [0],
                          ),
                        ],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text("Income");
                                  case 1:
                                    return const Text("Expenses");
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
