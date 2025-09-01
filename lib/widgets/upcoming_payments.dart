import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/budget_models.dart';

class UpcomingPayments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        final upcomingEMIs = budgetProvider.getUpcomingEMIs();
        
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
                      'Upcoming Payments',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        // Navigate to add EMI screen
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (upcomingEMIs.isEmpty)
                  Text('No upcoming payments', style: TextStyle(color: Colors.grey)),
                if (upcomingEMIs.isNotEmpty)
                  Column(
                    children: upcomingEMIs.map((emi) => _buildEMIItem(context, emi)).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEMIItem(BuildContext context, EMI emi) {
    return ListTile(
      leading: Icon(Icons.account_balance, color: Colors.blue),
      title: Text(emi.title),
      subtitle: Text('Due: ${emi.dueDate.day}/${emi.dueDate.month}/${emi.dueDate.year}'),
      trailing: Text('\$${emi.amount.toStringAsFixed(2)}', 
                   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
      onTap: () {
        // Show EMI details
      },
    );
  }
}