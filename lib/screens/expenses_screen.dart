// lib/screens/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'add_transaction_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedMonth = DateFormat.MMMM().format(DateTime.now());
  late List<int> _years;
  int _selectedYear = DateTime.now().year;
  final List<String> _months =
      List.generate(12, (i) => DateFormat.MMMM().format(DateTime(0, i + 1)));
  String? _selectedExpenseCategoryFilter;
  String? _selectedIncomeCategoryFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final cy = DateTime.now().year;
    _years = [cy - 1, cy, cy + 1];
    _selectedYear = cy;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _selectedMonthIndex => DateFormat.MMMM().parse(_selectedMonth).month;

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() {});
  }

  Category? _findCategory(String? name) {
    if (name == null) return null;
    final catBox = Hive.box<Category>('categories');
    try {
      return catBox.values.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  // Enhanced Month-Year Picker
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Column(
                children: [
                  const Text(
                    "Select Month & Year",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple.shade100, Colors.deepPurple.shade200],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => setModalState(() => tempYear--),
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                        ),
                        Text(
                          '$tempYear',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setModalState(() => tempYear++),
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 320,
                height: 240,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.0,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final isSelected = (index + 1) == tempMonthIndex;
                    
                    return GestureDetector(
                      onTap: () => setModalState(() => tempMonthIndex = index + 1),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isSelected 
                            ? LinearGradient(colors: [Colors.deepPurple, Colors.deepPurple.shade300])
                            : null,
                          color: isSelected ? null : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            monthNames[index],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                  child: const Text("Apply", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _categoryCardWidget(
    String? name, 
    String icon, 
    int color, 
    double total,
    double width, 
    bool isSelected,
    String type, {
    bool isAll = false, 
    double? allTotal
  }) {
    final bgColor = Color(color);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (type == "Expense") {
            if (isAll) {
              _selectedExpenseCategoryFilter = null;
            } else {
              _selectedExpenseCategoryFilter =
                  (_selectedExpenseCategoryFilter == name) ? null : name;
            }
          } else {
            if (isAll) {
              _selectedIncomeCategoryFilter = null;
            } else {
              _selectedIncomeCategoryFilter =
                  (_selectedIncomeCategoryFilter == name) ? null : name;
            }
          }
        });
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected 
              ? [bgColor, bgColor.withOpacity(0.8)]
              : [bgColor.withOpacity(0.1), bgColor.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? bgColor : bgColor.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(isSelected ? 0.3 : 0.1),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : bgColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                icon, 
                style: TextStyle(
                  fontSize: 18,
                  color: isSelected ? Colors.white : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAll ? "All" : (name ?? "Unknown"),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              "₹${(isAll ? (allTotal ?? 0.0) : total).toStringAsFixed(0)}",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : bgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteDialog(TransactionModel tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Transaction"),
        content: const Text("Are you sure you want to delete this transaction? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Widget _buildTransactionTab(String type) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ValueListenableBuilder(
        valueListenable: Hive.box<TransactionModel>('transactions').listenable(),
        builder: (context, Box<TransactionModel> txBox, _) {
          // Filter by selected month/year and type
          final monthTx = txBox.values.where((tx) {
            return tx.date.month == _selectedMonthIndex && 
                   tx.date.year == _selectedYear &&
                   tx.type == type;
          }).toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          // Totals per category
          final Map<String, double> totals = {};
          for (final t in monthTx) {
            totals[t.category] = (totals[t.category] ?? 0) + t.amount;
          }

          final totalAmount = totals.values.fold<double>(0.0, (a, b) => a + b);
          final catBox = Hive.box<Category>('categories');
          final categoryEntries = totals.entries.toList();

          // Filtered transactions according to selected category
          final selectedFilter = type == "Expense" 
            ? _selectedExpenseCategoryFilter 
            : _selectedIncomeCategoryFilter;
          final filteredTx = selectedFilter == null
              ? monthTx
              : monthTx.where((t) => t.category == selectedFilter).toList();

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categories Section with gradient container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: type == "Expense" 
                        ? [Colors.red.shade100.withOpacity(0.3), Colors.red.shade200.withOpacity(0.3)]
                        : [Colors.green.shade100.withOpacity(0.3), Colors.green.shade200.withOpacity(0.3)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (type == "Expense" ? Colors.red : Colors.green).withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: type == "Expense" ? Colors.red.shade600 : Colors.green.shade600,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (type == "Expense" ? Colors.red : Colors.green).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              type == "Expense" ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: '$type by Category ',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                                children: const [
                                  TextSpan(
                                    text: '(this month)',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (categoryEntries.isNotEmpty) 
                        LayoutBuilder(builder: (context, constraints) {
                          final spacing = 8.0;
                          final cardsPerRow = 3;
                          final totalSpacing = spacing * (cardsPerRow - 1);
                          final width = (constraints.maxWidth - totalSpacing) / cardsPerRow;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: 12,
                            children: [
                              // All card
                              _categoryCardWidget(
                                "All",
                                type == "Expense" ? "📊" : "💰",
                                (type == "Expense" ? Colors.deepOrange : Colors.teal).value,
                                0,
                                width,
                                selectedFilter == null,
                                type,
                                isAll: true,
                                allTotal: totalAmount,
                              ),
                              // Individual categories
                              ...categoryEntries.map((entry) {
                                final cat = catBox.values.firstWhere(
                                  (c) => c.name == entry.key,
                                  orElse: () => Category(
                                    name: entry.key,
                                    icon: type == "Expense" ? '🧾' : '💵',
                                    color: (type == "Expense" ? Colors.blueAccent : Colors.green).value,
                                    type: type,
                                  ),
                                );
                                return _categoryCardWidget(
                                  cat.name,
                                  cat.icon,
                                  cat.color,
                                  entry.value,
                                  width,
                                  selectedFilter == cat.name,
                                  type,
                                );
                              }),
                            ],
                          );
                        })
                      else 
                        LayoutBuilder(builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          return _categoryCardWidget(
                            "All", 
                            type == "Expense" ? "📊" : "💰", 
                            (type == "Expense" ? Colors.deepOrange : Colors.teal).value, 
                            0, 
                            width, 
                            selectedFilter == null, 
                            type,
                            isAll: true, 
                            allTotal: 0.0,
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Transactions List Section with gradient container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueGrey.shade50, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade600,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueGrey.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.list_alt_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            "$type List",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (filteredTx.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  type == "Expense" ? Icons.receipt_long : Icons.account_balance_wallet,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No ${type.toLowerCase()}s yet",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredTx.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final tx = filteredTx[index];
                            final category = _findCategory(tx.category) ??
                                Category(
                                  name: tx.category,
                                  icon: type == "Expense" ? '🧾' : '💵',
                                  color: (type == "Expense" ? Colors.blueAccent : Colors.green).value,
                                  type: type,
                                );
                            final sub = (tx.subCategory?.isNotEmpty == true) 
                                ? " • ${tx.subCategory}" : "";
                            final pm = (tx.paymentMethod?.isNotEmpty == true) 
                                ? " • ${tx.paymentMethod}" : "";

                            return Dismissible(
                              key: ValueKey(tx.key),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.red.shade400, Colors.red.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                              ),
                              confirmDismiss: (direction) async {
                                final confirmed = await _confirmDeleteDialog(tx);
                                if (confirmed) {
                                  await tx.delete();
                                  setState(() {});
                                  return true;
                                }
                                return false;
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Color(category.color).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Color(category.color).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      category.icon,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  title: Text(
                                    "${category.name}$sub",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        "${DateFormat.yMMMd().format(tx.date)}$pm",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (tx.note?.isNotEmpty == true) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          tx.note!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: Text(
                                    "₹${tx.amount.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: type == "Expense" ? Colors.red.shade600 : Colors.green.shade600,
                                    ),
                                  ),
                                  onTap: () async {
                                    await showDialog(
                                      context: context,
                                      builder: (_) => AddTransactionScreen(transaction: tx, index: index),
                                    );
                                    setState(() {});
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text(
          "Transactions",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          tabs: const [
            Tab(text: "Expenses", icon: Icon(Icons.trending_down_rounded)),
            Tab(text: "Income", icon: Icon(Icons.trending_up_rounded)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () => _showMonthYearPicker(context),
              icon: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
              label: Text(
                "${DateFormat.MMM().format(DateTime(0, _selectedMonthIndex))} $_selectedYear",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => const AddTransactionScreen(),
          );
          setState(() {});
        },
        label: const Text("Add", style: TextStyle(fontWeight: FontWeight.w600)),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionTab("Expense"),
          _buildTransactionTab("Income"),
        ],
      ),
    );
  }
}
