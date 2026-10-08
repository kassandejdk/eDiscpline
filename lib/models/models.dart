// lib/models/models.dart

class Expense {
  String id;
  String note;
  double amount;
  DateTime date;

  Expense({
    required this.id,
    required this.note,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'note': note,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        note: json['note'] ?? '',
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
      );
}

class BudgetCategory {
  String id;
  String name;
  String icon;
  double budgeted;
  List<Expense> expenses;
  int month;
  int year;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.budgeted,
    required this.expenses,
    required this.month,
    required this.year,
  });

  double get actual => expenses.fold(0, (sum, e) => sum + e.amount);
  double get difference => budgeted - actual;
  double get percentage => budgeted > 0 ? (actual / budgeted).clamp(0.0, 1.5) : 0;
  bool get isOverBudget => actual > budgeted;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'budgeted': budgeted,
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'month': month,
        'year': year,
      };

  factory BudgetCategory.fromJson(Map<String, dynamic> json) => BudgetCategory(
        id: json['id'],
        name: json['name'],
        icon: json['icon'],
        budgeted: (json['budgeted'] as num).toDouble(),
        expenses: json['expenses'] != null
            ? (json['expenses'] as List).map((e) => Expense.fromJson(e)).toList()
            : [],
        month: json['month'],
        year: json['year'],
      );
}

class MonthlyBudget {
  int month;
  int year;
  double totalBudget;
  List<BudgetCategory> categories;

  MonthlyBudget({
    required this.month,
    required this.year,
    required this.totalBudget,
    required this.categories,
  });

  double get totalSpent => categories.fold(0, (sum, c) => sum + c.actual);
  double get balance => totalBudget - totalSpent;
  bool get isPositive => balance >= 0;

  Map<String, dynamic> toJson() => {
        'month': month,
        'year': year,
        'totalBudget': totalBudget,
        'categories': categories.map((c) => c.toJson()).toList(),
      };

  factory MonthlyBudget.fromJson(Map<String, dynamic> json) => MonthlyBudget(
        month: json['month'],
        year: json['year'],
        totalBudget: (json['totalBudget'] as num).toDouble(),
        categories: (json['categories'] as List)
            .map((c) => BudgetCategory.fromJson(c))
            .toList(),
      );
}
class YearlyReport {
  final int year;
  final double totalBudget;
  final double totalSpent;
  final Map<int, double> monthlySpent;   // mois (1-12) → dépensé
  final Map<int, double> monthlyBudget;  // mois (1-12) → prévu
  final Map<String, double> byCategory;  // nom → dépensé annuel
  final Map<String, String> categoryIcons;

  YearlyReport({
    required this.year,
    required this.totalBudget,
    required this.totalSpent,
    required this.monthlySpent,
    required this.monthlyBudget,
    required this.byCategory,
    required this.categoryIcons,
  });

  double get balance => totalBudget - totalSpent;
  bool get isPositive => balance >= 0;

  double get averageMonthly {
    if (monthlySpent.isEmpty) return 0;
    return monthlySpent.values.fold(0.0, (a, b) => a + b) /
        monthlySpent.length;
  }

  int? get bestMonth {
    if (monthlySpent.isEmpty) return null;
    return monthlySpent.entries
        .reduce((a, b) => a.value <= b.value ? a : b)
        .key;
  }

  int? get worstMonth {
    if (monthlySpent.isEmpty) return null;
    return monthlySpent.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  /// Catégories triées par dépense décroissante.
  List<MapEntry<String, double>> get sortedCategories {
    final list = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }
}
class DailyTask {
  String id;
  String title;
  bool isDone;
  DateTime date;
  String? time;

  DailyTask({
    required this.id,
    required this.title,
    required this.isDone,
    required this.date,
    this.time,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
        'date': date.toIso8601String(),
        'time': time,
      };

  factory DailyTask.fromJson(Map<String, dynamic> json) => DailyTask(
        id: json['id'],
        title: json['title'],
        isDone: json['isDone'],
        date: DateTime.parse(json['date']),
        time: json['time'],
      );
}

class LearningEntry {
  String id;
  String content;
  String tag;
  DateTime date;

  LearningEntry({
    required this.id,
    required this.content,
    required this.tag,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'tag': tag,
        'date': date.toIso8601String(),
      };

  factory LearningEntry.fromJson(Map<String, dynamic> json) => LearningEntry(
        id: json['id'],
        content: json['content'],
        tag: json['tag'],
        date: DateTime.parse(json['date']),
      );
}