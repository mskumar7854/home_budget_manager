// lib/models/bill.dart
import 'package:hive/hive.dart';

part 'bill.g.dart';

@HiveType(typeId: 4)
class Bill extends HiveObject {
  @HiveField(0)
  String? name;

  @HiveField(1)
  String? provider;

  @HiveField(2)
  double? amount;

  @HiveField(3)
  DateTime dueDate;

  // recurrenceType: "None", "Monthly", "Quarterly", "Yearly"
  @HiveField(4)
  String? recurrence; // e.g. "Monthly", "Quarterly", "None"

  @HiveField(5)
  bool isPaid; // current occurrence paid

  @HiveField(6)
  String? accountNumber;

  // last time this bill was paid
  @HiveField(7)
  DateTime? lastPaidDate;

  // number of months between recurring occurrences
  @HiveField(8)
  int recurrenceIntervalMonths;

  // NEW: category assigned by user (persisted)
  @HiveField(9)
  String? category; // category name from Category box

  Bill({
    required this.name,
    this.provider,
    this.amount,
    required this.dueDate,
    this.recurrence = "None",
    this.isPaid = false,
    this.accountNumber,
    this.lastPaidDate,
    int? recurrenceIntervalMonths,
    this.category,
  }) : recurrenceIntervalMonths = recurrenceIntervalMonths ?? _intervalFromRecurrence(recurrence);

  // Compute months interval from recurrence string
  static int _intervalFromRecurrence(String? r) {
    switch ((r ?? "None").toLowerCase()) {
      case "monthly":
        return 1;
      case "quarterly":
        return 3;
      case "yearly":
        return 12;
      case "none":
      default:
        return 0;
    }
  }

  /// Returns true if this bill is recurring (interval > 0)
  bool get isRecurring => recurrenceIntervalMonths > 0;

  /// Mark current occurrence paid and advance dueDate to next occurrence if recurring.
  Future<void> markPaidAndAdvance() async {
    final now = DateTime.now();
    isPaid = true;
    lastPaidDate = now;
    await save();

    if (isRecurring && recurrenceIntervalMonths > 0) {
      // advance dueDate by recurrenceIntervalMonths
      dueDate = _addMonths(dueDate, recurrenceIntervalMonths);
      // new occurrence unpaid
      isPaid = false;
      await save();
    }
  }

  /// Toggle paid/pending without changing due date
  Future<void> togglePaidStatus() async {
    isPaid = !isPaid;
    if (isPaid) lastPaidDate = DateTime.now();
    await save();
  }

  /// Utility to add months while handling month-ends
  static DateTime _addMonths(DateTime d, int months) {
    if (months == 0) return d;
    final y = d.year + ((d.month - 1 + months) ~/ 12);
    final m0 = (d.month - 1 + months) % 12;
    final m = m0 + 1;
    final lastDay = DateTime(y, m + 1, 0).day;
    final day = d.day > lastDay ? lastDay : d.day;
    return DateTime(y, m, day);
  }

  /// days until due (negative if overdue)
  int daysUntilDue() {
    final now = DateTime.now();
    return dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }
}
