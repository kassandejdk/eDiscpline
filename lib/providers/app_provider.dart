// lib/providers/app_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/notification_service.dart';

const _uuid = Uuid();

class AppProvider extends ChangeNotifier {
  List<MonthlyBudget> _budgets = [];
  List<DailyTask> _tasks = [];
  List<LearningEntry> _learnings = [];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _hideAmounts = false;

  List<MonthlyBudget> get budgets => _budgets;
  List<DailyTask> get tasks => _tasks;
  List<LearningEntry> get learnings => _learnings;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  bool get hideAmounts => _hideAmounts;

  MonthlyBudget? get currentBudget {
    try {
      return _budgets.firstWhere(
          (b) => b.month == _selectedMonth && b.year == _selectedYear);
    } catch (_) {
      return null;
    }
  }

  List<DailyTask> tasksForDate(DateTime date) => _tasks
      .where((t) =>
          t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day)
      .toList();

  List<LearningEntry> get recentLearnings {
    final sorted = List<LearningEntry>.from(_learnings)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final bj = prefs.getString('budgets');
    if (bj != null) {
      _budgets = (jsonDecode(bj) as List)
          .map((e) => MonthlyBudget.fromJson(e))
          .toList();
    }
    final tj = prefs.getString('tasks');
    if (tj != null) {
      _tasks = (jsonDecode(tj) as List)
          .map((e) => DailyTask.fromJson(e))
          .toList();
    }
    final lj = prefs.getString('learnings');
    if (lj != null) {
      _learnings = (jsonDecode(lj) as List)
          .map((e) => LearningEntry.fromJson(e))
          .toList();
    }
    _hideAmounts = prefs.getBool('hide_amounts') ?? false;
    notifyListeners();
    unawaited(NotificationService.instance.syncAll(_tasks));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'budgets', jsonEncode(_budgets.map((b) => b.toJson()).toList()));
    await prefs.setString(
        'tasks', jsonEncode(_tasks.map((t) => t.toJson()).toList()));
    await prefs.setString(
        'learnings', jsonEncode(_learnings.map((l) => l.toJson()).toList()));
  }

  void setSelectedPeriod(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    notifyListeners();
  }

  Future<void> toggleHideAmounts() async {
    _hideAmounts = !_hideAmounts;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_amounts', _hideAmounts);
    notifyListeners();
  }

  // ─── BUDGET ────────────────────────────────────────────────────────────────

  /// Crée un budget pour le mois sélectionné.
  /// Si [copyCategories] est true et qu'un budget antérieur existe,
  /// les catégories sont reprises (sans les dépenses).
  void createBudget(double totalBudget, {bool copyCategories = true}) {
    if (currentBudget != null) return;

    List<BudgetCategory> templateCategories = [];
    if (copyCategories && _budgets.isNotEmpty) {
      // On prend le budget le plus récent (peu importe le sens)
      final sorted = List<MonthlyBudget>.from(_budgets)
        ..sort((a, b) {
          if (a.year != b.year) return b.year.compareTo(a.year);
          return b.month.compareTo(a.month);
        });
      final last = sorted.first;
      templateCategories = last.categories
          .map((c) => BudgetCategory(
                id: _uuid.v4(),
                name: c.name,
                icon: c.icon,
                budgeted: c.budgeted,
                expenses: [],
                month: _selectedMonth,
                year: _selectedYear,
              ))
          .toList();
    }

    _budgets.add(MonthlyBudget(
      month: _selectedMonth,
      year: _selectedYear,
      totalBudget: totalBudget,
      categories: templateCategories,
    ));
    notifyListeners();
    _save();
  }

  void updateTotalBudget(double value) {
    final b = currentBudget;
    if (b == null) return;
    b.totalBudget = value;
    notifyListeners();
    _save();
  }

  void addCategory(String name, String icon, double budgeted) {
    final b = currentBudget;
    if (b == null) return;
    b.categories.add(BudgetCategory(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      budgeted: budgeted,
      expenses: [],
      month: _selectedMonth,
      year: _selectedYear,
    ));
    notifyListeners();
    _save();
  }

  void updateCategory(
      String categoryId, String name, String icon, double budgeted) {
    final b = currentBudget;
    if (b == null) return;
    final cat = b.categories.firstWhere((c) => c.id == categoryId);
    cat.name = name;
    cat.icon = icon;
    cat.budgeted = budgeted;
    notifyListeners();
    _save();
  }

  void deleteCategory(String categoryId) {
    currentBudget?.categories.removeWhere((c) => c.id == categoryId);
    notifyListeners();
    _save();
  }

  // ─── EXPENSES ──────────────────────────────────────────────────────────────

  void addExpense(String categoryId, double amount, String note) {
    final b = currentBudget;
    if (b == null) return;
    final cat = b.categories.firstWhere((c) => c.id == categoryId);
    cat.expenses.add(Expense(
      id: _uuid.v4(),
      note: note,
      amount: amount,
      date: DateTime.now(),
    ));
    notifyListeners();
    _save();
  }

  void deleteExpense(String categoryId, String expenseId) {
    final b = currentBudget;
    if (b == null) return;
    final cat = b.categories.firstWhere((c) => c.id == categoryId);
    cat.expenses.removeWhere((e) => e.id == expenseId);
    notifyListeners();
    _save();
  }

  // ─── TASKS ─────────────────────────────────────────────────────────────────

  void addTask(String title, DateTime date, String? time) {
    final task = DailyTask(
      id: _uuid.v4(),
      title: title,
      isDone: false,
      date: date,
      time: time,
    );
    _tasks.add(task);
    notifyListeners();
    _save();
    unawaited(NotificationService.instance.scheduleTask(task));
  }

  void updateTask(String taskId, String title, String? time) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.title = title;
    task.time = time;
    notifyListeners();
    _save();
    unawaited(NotificationService.instance.scheduleTask(task));
  }

  void toggleTask(String taskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.isDone = !task.isDone;
    notifyListeners();
    _save();
    unawaited(NotificationService.instance.scheduleTask(task));
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    _save();
    unawaited(NotificationService.instance.cancelTask(taskId));
  }

  // ─── LEARNINGS ─────────────────────────────────────────────────────────────

  void addLearning(String content, String tag) {
    _learnings.add(LearningEntry(
      id: _uuid.v4(),
      content: content,
      tag: tag,
      date: DateTime.now(),
    ));
    notifyListeners();
    _save();
  }

  void updateLearning(String id, String content, String tag) {
    final entry = _learnings.firstWhere((l) => l.id == id);
    entry.content = content;
    entry.tag = tag;
    notifyListeners();
    _save();
  }

  void deleteLearning(String id) {
    _learnings.removeWhere((l) => l.id == id);
    notifyListeners();
    _save();
  }

    // ─── RAPPORT ANNUEL ────────────────────────────────────────────────────────

  YearlyReport? buildYearlyReport(int year) {
    final yearBudgets = _budgets.where((b) => b.year == year).toList();
    if (yearBudgets.isEmpty) return null;

    final monthlySpent = <int, double>{};
    final monthlyBudget = <int, double>{};
    final byCategory = <String, double>{};
    final icons = <String, String>{};

    double totalBudget = 0;
    double totalSpent = 0;

    for (final b in yearBudgets) {
      monthlyBudget[b.month] = b.totalBudget;
      monthlySpent[b.month] = b.totalSpent;
      totalBudget += b.totalBudget;
      totalSpent += b.totalSpent;

      for (final c in b.categories) {
        byCategory[c.name] = (byCategory[c.name] ?? 0) + c.actual;
        icons[c.name] = c.icon;
      }
    }

    return YearlyReport(
      year: year,
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      monthlySpent: monthlySpent,
      monthlyBudget: monthlyBudget,
      byCategory: byCategory,
      categoryIcons: icons,
    );
  }

  /// Liste des années pour lesquelles on a au moins un budget.
  List<int> get availableYears {
    final years = _budgets.map((b) => b.year).toSet().toList()..sort();
    return years;
  }
}