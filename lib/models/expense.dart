import 'package:flutter/material.dart';

class ExpenseCategory {
  const ExpenseCategory(this.name, this.icon, this.color);

  final String name;
  final IconData icon;
  final Color color;

  static const all = [
    ExpenseCategory(
      'Food & drink',
      Icons.restaurant_rounded,
      Color(0xFFE98B65),
    ),
    ExpenseCategory(
      'Transport',
      Icons.directions_bus_rounded,
      Color(0xFF6388D9),
    ),
    ExpenseCategory('Shopping', Icons.shopping_bag_rounded, Color(0xFFAD76C6)),
    ExpenseCategory('Bills', Icons.receipt_long_rounded, Color(0xFFD7A648)),
    ExpenseCategory('Health', Icons.favorite_rounded, Color(0xFFE36F7D)),
    ExpenseCategory('Other', Icons.grid_view_rounded, Color(0xFF71877E)),
  ];

  static ExpenseCategory fromName(String name) => all.firstWhere(
    (category) => category.name == name,
    orElse: () => all.last,
  );
}

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amountPaise,
    required this.category,
    required this.date,
    this.note = '',
  });

  final String id;
  final String title;
  final int amountPaise;
  final String category;
  final DateTime date;
  final String note;

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'amountPaise': amountPaise,
    'category': category,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory Expense.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final amountPaise = json['amountPaise'];
    final category = json['category'];
    final date = json['date'];
    final note = json['note'];
    if (id is! String ||
        title is! String ||
        amountPaise is! int ||
        category is! String ||
        date is! String ||
        note is! String) {
      throw const FormatException('An expense entry has invalid fields.');
    }
    return Expense(
      id: id,
      title: title,
      amountPaise: amountPaise,
      category: category,
      date: DateTime.parse(date),
      note: note,
    );
  }
}
