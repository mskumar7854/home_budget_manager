import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_budget_manager/providers/budget_provider.dart';
import 'package:home_budget_manager/screens/dashboard_screen.dart';
import 'package:home_budget_manager/screens/expenses_screen.dart';
import 'package:home_budget_manager/screens/add_expense_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Budget Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainNavigation(),
      routes: {
        '/dashboard': (context) => DashboardScreen(),
        '/expenses': (context) => ExpensesScreen(),
        '/add-expense': (context) => AddExpenseScreen(),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  
  static final List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    ExpensesScreen(),
    Placeholder(), // EMI screen
    Placeholder(), // Todo screen
    Placeholder(), // Savings screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'EMIs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'To-Do',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings),
            label: 'Savings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Placeholder screens for EMI, Todo, and Savings (to be implemented later)
class EMIScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('EMI Tracker')),
      body: Center(child: Text('EMI Screen - Coming Soon')),
    );
  }
}

class TodoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('To-Do List')),
      body: Center(child: Text('To-Do Screen - Coming Soon')),
    );
  }
}

class SavingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Savings Goals')),
      body: Center(child: Text('Savings Screen - Coming Soon')),
    );
  }
}