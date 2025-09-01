import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';

class MonthlySummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        return Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                // Placeholder content
                Text('Income: \$0.00', style: TextStyle(color: Colors.green)),
                SizedBox(height: 8),
                Text('Expenses: \$0.00', style: TextStyle(color: Colors.red)),
                SizedBox(height: 8),
                Text('Remaining: \$0.00', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}