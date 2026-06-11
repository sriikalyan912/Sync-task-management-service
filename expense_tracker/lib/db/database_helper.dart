import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/expense.dart';

/// All app data lives in a local SQLite database (expense_tracker.db) inside
/// the app's private storage. Nothing leaves the device.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'expense_tracker.db';
  static const int _dbVersion = 1;

  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<String> get databasePath async =>
      join(await getDatabasesPath(), _dbName);

  Future<Database> _open() async {
    return openDatabase(
      await databasePath,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        payee_vpa TEXT,
        payee_name TEXT,
        txn_ref TEXT,
        note TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses (date)');
    await _seedCategories(db);
  }

  Future<void> _seedCategories(Database db) async {
    const defaults = [
      ExpenseCategory(name: 'Food & Dining', iconKey: 'food', colorValue: 0xFFE53935),
      ExpenseCategory(name: 'Groceries', iconKey: 'groceries', colorValue: 0xFF43A047),
      ExpenseCategory(name: 'Transport', iconKey: 'transport', colorValue: 0xFF1E88E5),
      ExpenseCategory(name: 'Shopping', iconKey: 'shopping', colorValue: 0xFF8E24AA),
      ExpenseCategory(name: 'Bills & Utilities', iconKey: 'bills', colorValue: 0xFFF4511E),
      ExpenseCategory(name: 'Entertainment', iconKey: 'entertainment', colorValue: 0xFF3949AB),
      ExpenseCategory(name: 'Health', iconKey: 'health', colorValue: 0xFF00897B),
      ExpenseCategory(name: 'Education', iconKey: 'education', colorValue: 0xFF6D4C41),
      ExpenseCategory(name: 'Travel', iconKey: 'travel', colorValue: 0xFF039BE5),
      ExpenseCategory(name: 'Other', iconKey: 'other', colorValue: 0xFF546E7A),
    ];
    final batch = db.batch();
    for (final category in defaults) {
      batch.insert('categories', category.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------------- queries

  Future<List<ExpenseCategory>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'id ASC');
    return rows.map(ExpenseCategory.fromMap).toList();
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final rows = await db.query('expenses', orderBy: 'date DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.insert('expenses', expense.toMap()..remove('id'));
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
