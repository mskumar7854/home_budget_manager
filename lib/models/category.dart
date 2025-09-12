import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 0)
class Category extends HiveObject {
  @HiveField(0)
  String name; // e.g., Food

  @HiveField(1)
  String type; // "Income" or "Expense"

  @HiveField(2)
  int color; // Color value

  @HiveField(3)
  String icon; // e.g., "🍎" or "food"

  @HiveField(4)
  String group; // "Daily", "Monthly", "Other"

  @HiveField(5)
  List<String> subCategories; // e.g., ["Groceries", "Dining out"]

  Category({
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
    this.group = "Daily",
    this.subCategories = const [],
  });
}
