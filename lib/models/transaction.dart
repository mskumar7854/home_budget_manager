import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class TransactionModel extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  String type; // "Income" or "Expense"

  @HiveField(2)
  String category; // parent category name

  @HiveField(3)
  DateTime date; // auto-date by default

  @HiveField(4)
  String note;

  @HiveField(5)
  bool isRecurring;

  @HiveField(6)
  String? recurrenceType; // daily, weekly, monthly, yearly

  @HiveField(7)
  DateTime? endDate;

  // NEW
  @HiveField(8)
  int? tenureMonths; // EMI

  @HiveField(9)
  DateTime? validTill; // Recharge

  // NEW breakdown fields
  @HiveField(10)
  String? subCategory; // e.g., "Groceries"

  @HiveField(11)
  String? paymentMethod; // Cash/Card/UPI/etc.

  TransactionModel({
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note = "",
    this.isRecurring = false,
    this.recurrenceType,
    this.endDate,
    this.tenureMonths,
    this.validTill,
    this.subCategory,
    this.paymentMethod,
  });
}
