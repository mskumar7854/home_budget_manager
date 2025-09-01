import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/budget_models.dart';

class EMIScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EMI Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navigate to add EMI screen
            },
          ),
        ],
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, child) {
          if (budgetProvider.emiList.isEmpty) {
            return Center(
              child: Text('No EMIs added yet.'),
            );
          }

          return ListView.builder(
            itemCount: budgetProvider.emiList.length,
            itemBuilder: (context, index) {
              final emi = budgetProvider.emiList[index];
              return ListTile(
                leading: Icon(Icons.account_balance, color: Colors.blue),
                title: Text(emi.title),
                subtitle: Text('Due: ${emi.dueDate.day}/${emi.dueDate.month}/${emi.dueDate.year}'),
                trailing: Text('\$${emi.amount.toStringAsFixed(2)}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add EMI screen
        },
        child: Icon(Icons.add),
      ),
    );
  }
}