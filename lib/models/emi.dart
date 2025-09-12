// lib/models/emi.dart
import 'package:hive/hive.dart';

part 'emi.g.dart';

@HiveType(typeId: 5)
class Emi extends HiveObject {
  @HiveField(0)
  String? name;

  @HiveField(1)
  double? loanAmount;

  @HiveField(2)
  double? emiAmount;

  @HiveField(3)
  DateTime startDate;

  @HiveField(4)
  int tenureMonths;

  @HiveField(5)
  double? interestRate;

  @HiveField(6)
  String? lender;

  @HiveField(7)
  int monthsPaid;

  @HiveField(8)
  bool isActive;

  // NEW: category assigned by user
  @HiveField(9)
  String? category;

  Emi({
    this.name,
    this.loanAmount,
    this.emiAmount,
    required this.startDate,
    required this.tenureMonths,
    this.interestRate,
    this.lender,
    this.monthsPaid = 0,
    this.isActive = true,
    this.category,
  });
}
