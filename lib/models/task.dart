// lib/models/task.dart
import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 2)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String note;

  @HiveField(2)
  DateTime dueDate;

  @HiveField(3)
  int priority; // 1 = high, 2 = medium, 3 = low

  @HiveField(4)
  bool isCompleted;

  Task({
    required this.title,
    this.note = "",
    required this.dueDate,
    this.priority = 2,
    this.isCompleted = false,
  });
}
