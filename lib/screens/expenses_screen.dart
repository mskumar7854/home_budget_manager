import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_budget_manager/providers/budget_provider.dart';
import 'package:home_budget_manager/screens/add_expense_screen.dart';

class ExpensesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AddExpenseScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, child) {
          if (budgetProvider.expenses.isEmpty) {
            return Center(
              child: Text('No expenses yet. Add your first expense!'),
            );
          }

          return ListView.builder(
            itemCount: budgetProvider.expenses.length,
            itemBuilder: (context, index) {
              final expense = budgetProvider.expenses[index];
              return ListTile(
                leading: Icon(Icons.money_off, color: Colors.red),
                title: Text(expense.category),
                subtitle: Text(expense.description),
                trailing: Text('\$${expense.amount.toStringAsFixed(2)}'),
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete Expense?'),
                      content: Text('Are you sure you want to delete this expense?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            budgetProvider.removeExpense(expense.id);
                            Navigator.of(context).pop();
                          },
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
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