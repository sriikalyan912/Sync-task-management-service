import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../models/category.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Expense> _expenses = [];
  List<ExpenseCategory> _categories = [];
  bool _loaded = false;

  /// Expenses sorted newest first.
  List<Expense> get expenses => List.unmodifiable(_expenses);

  List<ExpenseCategory> get categories => List.unmodifiable(_categories);

  bool get loaded => _loaded;

  Future<void> init() async {
    _categories = await _db.getCategories();
    _expenses = await _db.getExpenses();
    _loaded = true;
    notifyListeners();
  }

  ExpenseCategory categoryById(int id) {
    return _categories.firstWhere(
      (c) => c.id == id,
      orElse: () => const ExpenseCategory(
        name: 'Other',
        iconKey: 'other',
        colorValue: 0xFF546E7A,
      ),
    );
  }

  Future<void> addExpense(Expense expense) async {
    final id = await _db.insertExpense(expense);
    _expenses.add(expense.copyWith(id: id));
    _sort();
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await _db.updateExpense(expense);
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      _sort();
      notifyListeners();
    }
  }

  Future<void> deleteExpense(int id) async {
    await _db.deleteExpense(id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void _sort() {
    _expenses.sort((a, b) => b.date.compareTo(a.date));
  }

  // ----------------------------------------------------------- aggregations

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  double get totalToday {
    final today = _dayOf(DateTime.now());
    return _expenses
        .where((e) => _dayOf(e.date) == today)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalThisMonth {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  int get countThisMonth {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .length;
  }

  /// Total spent per day for the trailing [days] days (today included).
  /// Every day in the range is present in the result, including zero days,
  /// so the graph has a continuous x-axis.
  Map<DateTime, double> dailyTotals(int days) {
    final today = _dayOf(DateTime.now());
    final start = today.subtract(Duration(days: days - 1));
    final totals = <DateTime, double>{
      for (var i = 0; i < days; i++) start.add(Duration(days: i)): 0.0,
    };
    for (final e in _expenses) {
      final day = _dayOf(e.date);
      if (totals.containsKey(day)) {
        totals[day] = totals[day]! + e.amount;
      }
    }
    return totals;
  }

  /// Total spent per category for the trailing [days] days, sorted
  /// highest first. Categories with no spend are omitted.
  Map<ExpenseCategory, double> categoryTotals(int days) {
    final today = _dayOf(DateTime.now());
    final start = today.subtract(Duration(days: days - 1));
    final totals = <int, double>{};
    for (final e in _expenses) {
      final day = _dayOf(e.date);
      if (!day.isBefore(start) && !day.isAfter(today)) {
        totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amount;
      }
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) categoryById(e.key): e.value};
  }
}
