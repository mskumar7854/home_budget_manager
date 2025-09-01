import 'package:flutter/material.dart';

class QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.add),
                  label: Text('Add Expense'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.account_balance),
                  label: Text('EMI'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.list),
                  label: Text('To-Do'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.savings),
                  label: Text('Savings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}