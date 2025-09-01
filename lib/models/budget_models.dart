import 'package:flutter/material.dart';

// Your existing model classes go here
// (Expense, EMI, TodoItem, SavingsGoal)
class Expense {
  final String id;
  final String category;
  final double amount;
  final DateTime date;
  final String description;
  final bool isRecurring;
  final int recurrenceDays; // 0 for one-time, 30 for monthly, etc.
  
  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
    this.isRecurring = false,
    this.recurrenceDays = 0,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'description': description,
      'isRecurring': isRecurring,
      'recurrenceDays': recurrenceDays,
    };
  }
  
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      category: map['category'],
      amount: map['amount'].toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      description: map['description'],
      isRecurring: map['isRecurring'],
      recurrenceDays: map['recurrenceDays'],
    );
  }
}

class EMI {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final int tenure;
  int remainingPayments;
  final String lender;
  final String description;
  
  EMI({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.tenure,
    required this.remainingPayments,
    required this.lender,
    required this.description,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'tenure': tenure,
      'remainingPayments': remainingPayments,
      'lender': lender,
      'description': description,
    };
  }
  
  factory EMI.fromMap(Map<String, dynamic> map) {
    return EMI(
      id: map['id'],
      title: map['title'],
      amount: map['amount'].toDouble(),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      tenure: map['tenure'],
      remainingPayments: map['remainingPayments'],
      lender: map['lender'],
      description: map['description'],
    );
  }
}

class TodoItem {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  bool isCompleted;
  final int priority; // 1-3 where 3 is highest
  
  TodoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.priority = 2,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'priority': priority,
    };
  }
  
  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      isCompleted: map['isCompleted'],
      priority: map['priority'],
    );
  }
}

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  double currentAmount;
  final DateTime targetDate;
  final String description;
  
  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.description,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.millisecondsSinceEpoch,
      'description': description,
    };
  }
  
  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'],
      name: map['name'],
      targetAmount: map['targetAmount'].toDouble(),
      currentAmount: map['currentAmount'].toDouble(),
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['targetDate']),
      description: map['description'],
    );
  }
}