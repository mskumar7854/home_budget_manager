import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/monthly_summary.dart';
import '../widgets/upcoming_payments.dart';
import '../widgets/savings_progress.dart';
import '../widgets/quick_actions_grid.dart';
import './add_expense_screen.dart';
import './add_expense_screen.dart';

// Your DashboardScreen class goes here

// Then update your DashboardScreen class:
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            MonthlySummary(),
            UpcomingPayments(),
            SavingsProgress(),
            QuickActionsGrid(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddExpenseScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}