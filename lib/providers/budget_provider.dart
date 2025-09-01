import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/budget_models.dart';
import '../utils/database_helper.dart';

class BudgetProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  List<EMI> _emiList = [];
  List<TodoItem> _todoList = [];
  List<SavingsGoal> _savingsGoals = [];
  double _monthlyIncome = 0;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<Expense> get expenses => _expenses;
  List<EMI> get emiList => _emiList;
  List<TodoItem> get todoList => _todoList;
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  double get monthlyIncome => _monthlyIncome;

List<EMI> getUpcomingEMIs() {
  final now = DateTime.now();
  return _emiList.where((emi) => 
    emi.dueDate.isAfter(now) && 
    emi.dueDate.isBefore(now.add(Duration(days: 30)))
  ).toList();
}
  BudgetProvider() {
    loadData();
  }

  Future<void> loadData() async {
    await loadExpenses();
    await loadEMIs();
    await loadTodos();
    await loadSavingsGoals();
    notifyListeners();
  }

  Future<void> loadExpenses() async {
    _expenses = await _databaseHelper.getExpenses();
  }

  Future<void> loadEMIs() async {
    _emiList = await _databaseHelper.getEMIs();
  }

  Future<void> loadTodos() async {
    _todoList = await _databaseHelper.getTodos();
  }

  Future<void> loadSavingsGoals() async {
    _savingsGoals = await _databaseHelper.getSavingsGoals();
  }

  void setMonthlyIncome(double income) {
    _monthlyIncome = income;
    notifyListeners();
  }

  void addExpense(Expense expense) async {
    _expenses.add(expense);
    await _databaseHelper.insertExpense(expense);
    notifyListeners();
  }

  void addEMI(EMI emi) async {
    _emiList.add(emi);
    await _databaseHelper.insertEMI(emi);
    notifyListeners();
  }

  void addTodo(TodoItem todo) async {
    _todoList.add(todo);
    await _databaseHelper.insertTodo(todo);
    notifyListeners();
  }

  void addSavingsGoal(SavingsGoal goal) async {
    _savingsGoals.add(goal);
    await _databaseHelper.insertSavingsGoal(goal);
    notifyListeners();
  }

  void removeExpense(String id) async {
    _expenses.removeWhere((expense) => expense.id == id);
    await _databaseHelper.deleteExpense(id);
    notifyListeners();
  }

  // Other methods remain the same...
}