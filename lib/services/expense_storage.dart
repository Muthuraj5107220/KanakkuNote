import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';

class ExpenseStorage {
  static const _storageKey = 'kanakku_note.expenses.v1';

  Future<List<Expense>> loadExpenses() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_storageKey);
    if (stored == null || stored.isEmpty) return [];

    final decoded = jsonDecode(stored);
    if (decoded is! List) {
      throw const FormatException('Saved expenses are not a list.');
    }
    return decoded
        .map((entry) {
          if (entry is! Map<String, dynamic>) {
            throw const FormatException('A saved expense is not an object.');
          }
          return Expense.fromJson(entry);
        })
        .toList(growable: false);
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final encoded = jsonEncode(
      expenses.map((expense) => expense.toJson()).toList(),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, encoded);
  }
}
