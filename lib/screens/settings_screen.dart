import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<Category> categoryBox;

  @override
  void initState() {
    super.initState();
    categoryBox = Hive.box<Category>('categories');
  }

  void _addOrEditCategory({Category? category, int? index}) {
    final nameCtrl = TextEditingController(text: category?.name ?? "");
    String type = category?.type ?? "Expense";
    String group = category?.group ?? "Daily";
    final subCtrl = TextEditingController(text: category?.subCategories.join(', ') ?? "");
    int color = category?.color ?? Colors.teal.value;
    final iconCtrl = TextEditingController(text: category?.icon ?? "category");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(category == null ? "Add Category" : "Edit Category"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: const InputDecoration(labelText: "Name"), controller: nameCtrl),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: type,
                items: ["Expense", "Income"].map((t)=>DropdownMenuItem(value:t, child: Text(t))).toList(),
                onChanged: (v)=> type = v!,
                decoration: const InputDecoration(labelText: "Type"),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: group,
                items: ["Daily","Monthly","Other"].map((g)=>DropdownMenuItem(value:g, child: Text(g))).toList(),
                onChanged: (v)=> group = v!,
                decoration: const InputDecoration(labelText: "Group"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: subCtrl,
                decoration: const InputDecoration(
                  labelText: "Sub-categories (comma separated)",
                  helperText: "Example: Groceries, Dining out",
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: iconCtrl,
                decoration: const InputDecoration(
                  labelText: "Icon (text/emoji)",
                  helperText: "Example: 🍎  or  category",
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text("Color: "),
                  GestureDetector(
                    onTap: () async {
                      // simple color picker shortcuts
                      final colors = [Colors.teal, Colors.blue, Colors.red, Colors.orange, Colors.purple, Colors.green];
                      final picked = await showDialog<int>(
                        context: context,
                        builder: (_) => SimpleDialog(
                          title: const Text("Pick a color"),
                          children: colors.map((c)=>SimpleDialogOption(
                            onPressed: ()=> Navigator.pop(context, c.value),
                            child: Row(children: [Icon(Icons.circle, color: c), const SizedBox(width:8), Text(c.toString())]),
                          )).toList(),
                        ),
                      );
                      if (picked != null) setState(() => color = picked);
                    },
                    child: Container(width:24, height:24, decoration: BoxDecoration(color: Color(color), shape: BoxShape.circle)),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final newCat = Category(
                name: nameCtrl.text.trim(),
                type: type,
                color: color,
                icon: iconCtrl.text.trim().isEmpty ? "category" : iconCtrl.text.trim(),
                group: group,
                subCategories: subCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
              );
              if (index == null) {
                categoryBox.add(newCat);
              } else {
                categoryBox.putAt(index, newCat);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Category Management")),
      body: ValueListenableBuilder(
        valueListenable: categoryBox.listenable(),
        builder: (_, Box<Category> box, __) {
          if (box.isEmpty) return const Center(child: Text("No categories yet"));
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (_, i) {
              final c = box.getAt(i)!;
              return Card(
                child: ListTile(
                  leading: Text(c.icon, style: const TextStyle(fontSize: 20)),
                  title: Text(c.name),
                  subtitle: Text("${c.type} • ${c.group} • ${c.subCategories.join(', ')}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Color(c.color), size: 16),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: ()=> _addOrEditCategory(category: c, index: i)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: ()=> box.deleteAt(i)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ()=> _addOrEditCategory(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
