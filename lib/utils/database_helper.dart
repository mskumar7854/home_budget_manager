import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/budget_models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'budget_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create expenses table
    await db.execute('''
      CREATE TABLE expenses(
        id TEXT PRIMARY KEY,
        category TEXT,
        amount REAL,
        date INTEGER,
        description TEXT,
        isRecurring INTEGER,
        recurrenceDays INTEGER
      )
    ''');

    // Create EMI table
    await db.execute('''
      CREATE TABLE emis(
        id TEXT PRIMARY KEY,
        title TEXT,
        amount REAL,
        dueDate INTEGER,
        tenure INTEGER,
        remainingPayments INTEGER,
        lender TEXT,
        description TEXT
      )
    ''');

    // Create todos table
    await db.execute('''
      CREATE TABLE todos(
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        dueDate INTEGER,
        isCompleted INTEGER,
        priority INTEGER
      )
    ''');

    // Create savings goals table
    await db.execute('''
      CREATE TABLE savings_goals(
        id TEXT PRIMARY KEY,
        name TEXT,
        targetAmount REAL,
        currentAmount REAL,
        targetDate INTEGER,
        description TEXT
      )
    ''');
  }

  // Expense methods
  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('expenses');
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // EMI methods
  Future<void> insertEMI(EMI emi) async {
    final db = await database;
    await db.insert('emis', emi.toMap());
  }

  Future<List<EMI>> getEMIs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('emis');
    return List.generate(maps.length, (i) => EMI.fromMap(maps[i]));
  }

  // Todo methods
  Future<void> insertTodo(TodoItem todo) async {
    final db = await database;
    await db.insert('todos', todo.toMap());
  }

  Future<List<TodoItem>> getTodos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('todos');
    return List.generate(maps.length, (i) => TodoItem.fromMap(maps[i]));
  }

  // Savings goals methods
  Future<void> insertSavingsGoal(SavingsGoal goal) async {
    final db = await database;
    await db.insert('savings_goals', goal.toMap());
  }

  Future<List<SavingsGoal>> getSavingsGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('savings_goals');
    return List.generate(maps.length, (i) => SavingsGoal.fromMap(maps[i]));
  }
}