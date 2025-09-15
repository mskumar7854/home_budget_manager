// lib/screens/todo_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  String _selectedMonth = DateFormat.MMMM().format(DateTime.now());
  late List<int> _years;
  int _selectedYear = DateTime.now().year;
  final List<String> _months =
      List.generate(12, (i) => DateFormat.MMMM().format(DateTime(0, i + 1)));
  String? _priorityFilter; // "High", "Medium", "Low", or null for all
  bool _showCompleted = false;
  bool _calendarMode = false; // toggles daily calendar-like view

  @override
  void initState() {
    super.initState();
    final cy = DateTime.now().year;
    _years = [cy - 1, cy, cy + 1];
    _selectedYear = cy;
  }

  int get _selectedMonthIndex =>
      DateFormat.MMMM().parse(_selectedMonth).month; // 1..12

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() {});
  }

  // Month-Year Picker - Same as dashboard
  Future<void> _showMonthYearPicker(BuildContext context) async {
    final List<String> monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    int tempYear = _selectedYear;
    int tempMonthIndex = _selectedMonthIndex;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Column(
                children: [
                  Text(
                    "Select Month & Year",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => setModalState(() => tempYear--),
                          icon: Icon(Icons.chevron_left, color: Colors.black87),
                        ),
                        Text(
                          '$tempYear',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setModalState(() => tempYear++),
                          icon: Icon(Icons.chevron_right, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: Container(
                width: 300,
                height: 200,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.0,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final isSelected = (index + 1) == tempMonthIndex;
                    
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          tempMonthIndex = index + 1;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.orangeAccent : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.orangeAccent.shade700 : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            monthNames[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedYear = tempYear;
                      final fullMonthNames = [
                        'January', 'February', 'March', 'April', 'May', 'June',
                        'July', 'August', 'September', 'October', 'November', 'December'
                      ];
                      _selectedMonth = fullMonthNames[tempMonthIndex - 1];
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    "Apply",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Convert stored priority (int?) to UI string ("High"/"Medium"/"Low")
  String _priorityToString(int? storedPriority) {
    if (storedPriority == null) return "Medium";
    if (storedPriority >= 2) return "High";
    if (storedPriority == 1) return "Medium";
    return "Low";
  }

  // Convert UI string to stored int (2 High, 1 Medium, 0 Low)
  int _uiPriorityToStored(String ui) {
    if (ui == "High") return 2;
    if (ui == "Medium") return 1;
    return 0;
  }

  // Priority color helper
  Color _priorityColor(String? priority) {
    switch (priority) {
      case "High":
        return Colors.red;
      case "Medium":
        return Colors.orange;
      case "Low":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Show add/edit sheet
  Future<void> _openAddEditTask({Task? item}) async {
    final titleCtrl = TextEditingController(text: item?.title ?? "");
    DateTime dueDate = item?.dueDate ?? DateTime.now();
    // initial UI priority string based on stored int priority
    String priorityUI = _priorityToString(item?.priority as int?);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(builder: (context, setSheetState) {
            void setDueTo(DateTime d) => setSheetState(() => dueDate = d);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item == null ? "Add Task" : "Edit Task",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold))),
                      IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close))
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleCtrl,
                    decoration:
                        const InputDecoration(labelText: "Task description"),
                  ),
                  const SizedBox(height: 10),
                  // Date + quick picks
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dueDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) setDueTo(picked);
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              decoration: InputDecoration(
                                  labelText: "Due date",
                                  hintText: DateFormat.yMMMd().format(dueDate)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        tooltip: "Quick date",
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: const [
                              Icon(Icons.calendar_today, size: 18),
                              SizedBox(width: 6),
                              Text("Quick"),
                            ],
                          ),
                        ),
                        onSelected: (v) {
                          if (v == "Today") setDueTo(DateTime.now());
                          if (v == "Tomorrow") setDueTo(DateTime.now().add(const Duration(days: 1)));
                          if (v == "NextWeek") setDueTo(DateTime.now().add(const Duration(days: 7)));
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: "Today", child: Text("Today")),
                          PopupMenuItem(value: "Tomorrow", child: Text("Tomorrow")),
                          PopupMenuItem(value: "NextWeek", child: Text("Next Week")),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Priority
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: priorityUI,
                        items: const [
                          DropdownMenuItem(value: "High", child: Text("High")),
                          DropdownMenuItem(value: "Medium", child: Text("Medium")),
                          DropdownMenuItem(value: "Low", child: Text("Low")),
                        ],
                        onChanged: (v) => setSheetState(() => priorityUI = v ?? "Medium"),
                        decoration: const InputDecoration(labelText: "Priority"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(), // reserved (we removed recurrence)
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                        onPressed: () async {
                          final title = titleCtrl.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a task")));
                            return;
                          }

                          final box = Hive.box<Task>('tasks');
                          final storedPriorityValue = _uiPriorityToStored(priorityUI);
                          if (item == null) {
                            final t = Task(
                              title: title,
                              dueDate: DateTime(dueDate.year, dueDate.month, dueDate.day),
                              priority: storedPriorityValue,
                              isCompleted: false,
                            );
                            await box.add(t);
                          } else {
                            item.title = title;
                            item.dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
                            item.priority = storedPriorityValue;
                            await item.save();
                          }

                          Navigator.of(context).pop();
                          setState(() {});
                        },
                        child: Text(item == null ? "Add Task" : "Save"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (item != null)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        onPressed: () async {
                          // toggle completion quickly
                          item.isCompleted = !item.isCompleted;
                          await item.save();
                          Navigator.of(context).pop();
                          setState(() {});
                        },
                        child: Text(item.isCompleted ? "Mark Uncomplete" : "Mark Done"),
                      ),
                  ]),
                  const SizedBox(height: 12),
                ]),
              ),
            );
          }),
        );
      },
    );
  }

  Future<bool> _confirmDelete(Task t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete task"),
        content: const Text("Delete this task? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    return confirmed == true;
  }

  // Group tasks by date for calendar/daily view
  Map<DateTime, List<Task>> _groupByDate(List<Task> tasks) {
    final Map<DateTime, List<Task>> map = {};
    DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    for (var t in tasks) {
      final d = dateOnly(t.dueDate);
      map.putIfAbsent(d, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.orangeAccent.shade200,
        title: const Text(
          "To-Do List",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: _calendarMode ? "List view" : "Calendar view",
            icon: Icon(_calendarMode ? Icons.list : Icons.calendar_today, color: Colors.white),
            onPressed: () => setState(() => _calendarMode = !_calendarMode),
          ),
          // Month-Year picker button styled
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () => _showMonthYearPicker(context),
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              label: Text(
                "${DateFormat.MMM().format(DateTime(0, _selectedMonthIndex))} $_selectedYear",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditTask(),
        icon: const Icon(Icons.add),
        label: const Text("Add"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ValueListenableBuilder(
          valueListenable: Hive.box<Task>('tasks').listenable(),
          builder: (context, Box<Task> box, _) {
            final all = box.values.toList();
            // Filter tasks by selected month/year
            final monthFiltered = all.where((t) {
              return t.dueDate.month == _selectedMonthIndex && t.dueDate.year == _selectedYear;
            }).toList()
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

            // Apply priority filter and showCompleted flag
            final filtered = monthFiltered.where((t) {
              if (!_showCompleted && t.isCompleted == true) return false;
              final prStr = _priorityToString(t.priority as int?);
              if (_priorityFilter != null && prStr != _priorityFilter) return false;
              return true;
            }).toList();

            // If calendar mode, group by date
            final grouped = _groupByDate(filtered);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // TOP CONTROLS: make priority chips horizontally scrollable to avoid overflow
                Row(
                  children: [
                    // scrollable chips
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const SizedBox(width: 0),
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: const Text("All"),
                                selected: _priorityFilter == null,
                                onSelected: (_) => setState(() => _priorityFilter = null),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: const Text("High"),
                                selected: _priorityFilter == "High",
                                onSelected: (_) => setState(() => _priorityFilter = _priorityFilter == "High" ? null : "High"),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: const Text("Medium"),
                                selected: _priorityFilter == "Medium",
                                onSelected: (_) => setState(() => _priorityFilter = _priorityFilter == "Medium" ? null : "Medium"),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: const Text("Low"),
                                selected: _priorityFilter == "Low",
                                onSelected: (_) => setState(() => _priorityFilter = _priorityFilter == "Low" ? null : "Low"),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                    // Show done switch on the right
                    Row(children: [
                      const Text("Show done"),
                      Switch(value: _showCompleted, onChanged: (v) => setState(() => _showCompleted = v)),
                    ])
                  ],
                ),
                const SizedBox(height: 12),
                if (_calendarMode)
                  // Simple calendar-like daily list
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: grouped.entries.map((e) {
                      final date = e.key;
                      final tasksForDate = e.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat.yMMMMd().format(date), style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          ...tasksForDate.map((t) => _buildTaskListTile(t)).toList(),
                          const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                  )
                else
                  // Compact list
                  filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: Text("No tasks for selected month")))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 12, endIndent: 12),
                          itemBuilder: (context, index) {
                            final t = filtered[index];
                            return Dismissible(
                              key: ValueKey(t.key),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (_) async {
                                final ok = await _confirmDelete(t);
                                if (ok) {
                                  await t.delete();
                                  setState(() {});
                                }
                                return ok;
                              },
                              child: _buildTaskListTile(t),
                            );
                          },
                        ),
              ]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskListTile(Task t) {
    final prStr = _priorityToString(t.priority as int?);
    final prColor = _priorityColor(prStr);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: GestureDetector(
        onTap: () async {
          t.isCompleted = !t.isCompleted;
          await t.save();
          setState(() {});
        },
        child: Icon(t.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: t.isCompleted ? Colors.green : Colors.grey[500]),
      ),
      title: Text(t.title ?? "", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, decoration: t.isCompleted ? TextDecoration.lineThrough : TextDecoration.none)),
      subtitle: Text("${DateFormat.yMMMd().format(t.dueDate)}", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: prColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(prStr, style: TextStyle(color: prColor, fontSize: 11)),
          ),
        ],
      ),
      onTap: () async {
        // edit
        await _openAddEditTask(item: t);
        setState(() {});
      },
      onLongPress: () async {
        // quick actions: mark done/pending, edit, delete
        final actions = await showModalBottomSheet<String>(
          context: context,
          builder: (ctx) {
            return SafeArea(
              child: Wrap(children: [
                ListTile(leading: const Icon(Icons.check), title: const Text("Toggle Done"), onTap: () => Navigator.pop(ctx, "toggle")),
                ListTile(leading: const Icon(Icons.edit), title: const Text("Edit"), onTap: () => Navigator.pop(ctx, "edit")),
                ListTile(leading: const Icon(Icons.delete), title: const Text("Delete"), onTap: () => Navigator.pop(ctx, "delete")),
                ListTile(leading: const Icon(Icons.close), title: const Text("Cancel"), onTap: () => Navigator.pop(ctx, null)),
              ]),
            );
          },
        );
        if (actions == "toggle") {
          t.isCompleted = !t.isCompleted;
          await t.save();
          setState(() {});
        } else if (actions == "edit") {
          await _openAddEditTask(item: t);
          setState(() {});
        } else if (actions == "delete") {
          final ok = await _confirmDelete(t);
          if (ok) {
            await t.delete();
            setState(() {});
          }
        }
      },
    );
  }
}
