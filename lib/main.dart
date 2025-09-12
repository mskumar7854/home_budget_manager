// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';

// screens
import 'screens/dashboard_screen.dart';
import 'screens/todo_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_transaction_screen.dart';

// models
import 'models/category.dart';
import 'models/transaction.dart';
import 'models/emi.dart';
import 'models/bill.dart';
import 'models/task.dart';

// notifications
import 'services/notifications_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Hive.initFlutter();

  // register adapters (safe-guarded)
  try {
    Hive.registerAdapter(CategoryAdapter());
  } catch (_) {}
  try {
    Hive.registerAdapter(TransactionModelAdapter());
  } catch (_) {}
  try {
    Hive.registerAdapter(EmiAdapter());
  } catch (_) {}
  try {
    Hive.registerAdapter(BillAdapter());
  } catch (_) {}
  try {
    Hive.registerAdapter(TaskAdapter());
  } catch (_) {}

  // open boxes
  await Hive.openBox<Category>('categories');
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<Emi>('emis');
  await Hive.openBox<Bill>('bills');
  await Hive.openBox<Task>('tasks');

  // init notifications (if you use them)
  await NotificationsService.instance.init();
  await NotificationsService.instance.requestPermissions();

  runApp(const BudgetApp());
}

class BudgetApp extends StatefulWidget {
  const BudgetApp({super.key});

  @override
  State<BudgetApp> createState() => _BudgetAppState();
}

class _BudgetAppState extends State<BudgetApp> {
  // keep these in case you want to control navigation globally
  int _selectedIndex = 0;

  // If you previously used an indexed stack / bottom nav in main
  // but want child screens to manage their own scaffold/appBar,
  // you can either navigate to them (push) or use a top-level
  // Navigator + routes. Here we keep the simple approach of
  // starting at DashboardScreen; it will manage its own scaffold.
  final List<Widget> _screens = const [
    DashboardScreen(),
    TodoScreen(),
    ExpensesScreen(),
    SettingsScreen(),
  ];

  // color scheme (orange accent)
  final ColorScheme _scheme = ColorScheme.fromSeed(seedColor: Colors.deepOrange);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Budget App',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: _scheme,
        appBarTheme: const AppBarTheme(centerTitle: false),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.orangeAccent,
        ),
      ),

      // NOTE: no outer Scaffold here. We start at DashboardScreen (which should
      // provide its own Scaffold/AppBar). Use routes or pushes to open other screens.
      home: const DashboardScreen(),

      // If you still want named routes, uncomment / adapt:
      // routes: {
      //   '/': (_) => const DashboardScreen(),
      //   '/todo': (_) => const TodoScreen(),
      //   '/expenses': (_) => const ExpensesScreen(),
      //   '/settings': (_) => const SettingsScreen(),
      //   '/add': (_) => const AddTransactionScreen(),
      // },
    );
  }
}
