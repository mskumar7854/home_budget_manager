import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/budget_models.dart';

class SavingsProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        final savingsGoals = budgetProvider.savingsGoals;
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Savings Progress',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        // Navigate to add savings goal screen
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (savingsGoals.isEmpty)
                  Text('No savings goals set', style: TextStyle(color: Colors.grey)),
                if (savingsGoals.isNotEmpty)
                  Column(
                    children: savingsGoals.map((goal) => _buildSavingsGoalItem(context, goal)).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavingsGoalItem(BuildContext context, SavingsGoal goal) {
    final progress = goal.currentAmount / goal.targetAmount;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(goal.name, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
        SizedBox(height: 4),
        Text(
          '\$${goal.currentAmount.toStringAsFixed(2)} / \$${goal.targetAmount.toStringAsFixed(2)} '
          '(${(progress * 100).toStringAsFixed(1)}%)',
          style: TextStyle(fontSize: 12),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}