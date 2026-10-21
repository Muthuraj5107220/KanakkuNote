import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';

class ExpenseStorage {
  static const _legacyStorageKey = 'kanakku_note.expenses.v1';
  static const _migrationKey = 'kanakku_note.sqlite_migration_completed.v1';

  ExpenseStorage({DatabaseFactory? factory, this.databasePath})
    : _databaseFactory = factory ?? databaseFactory;

  final DatabaseFactory _databaseFactory;
  final String? databasePath;
  Database? _database;

  Future<Database> _openDatabase() async {
    final existing = _database;
    if (existing != null) return existing;

    final resolvedPath =
        databasePath ??
        path.join(await _databaseFactory.getDatabasesPath(), 'kanakku_note.db');
    final database = await _databaseFactory.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(
        version: 3,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE accounts (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL COLLATE NOCASE UNIQUE,
              opening_balance_paise INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await database.execute('''
            CREATE TABLE expenses (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              amount_paise INTEGER NOT NULL,
              category TEXT NOT NULL,
              date TEXT NOT NULL,
              note TEXT NOT NULL,
              account_id TEXT,
              FOREIGN KEY (account_id) REFERENCES accounts(id)
            )
          ''');
          await database.execute(
            'CREATE INDEX expenses_date_idx ON expenses(date)',
          );
          await _createCategoriesTable(database);
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await database.execute(
              'ALTER TABLE accounts ADD COLUMN '
              'opening_balance_paise INTEGER NOT NULL DEFAULT 0',
            );
          }
          if (oldVersion < 3) {
            await _createCategoriesTable(database);
          }
        },
      ),
    );
    _database = database;
    return database;
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    await database?.close();
  }

  Future<void> _createCategoriesTable(DatabaseExecutor executor) async {
    await executor.execute('''
      CREATE TABLE categories (
        name TEXT NOT NULL COLLATE NOCASE PRIMARY KEY
      )
    ''');
    for (final category in ExpenseCategory.all) {
      await executor.insert('categories', {'name': category.name});
    }
  }

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_migrationKey) == true) return;

    final stored = preferences.getString(_legacyStorageKey);
    final expenses = <Expense>[];
    if (stored != null && stored.isNotEmpty) {
      final decoded = jsonDecode(stored);
      if (decoded is! List) {
        throw const FormatException('Saved expenses are not a list.');
      }
      for (final entry in decoded) {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('A saved expense is not an object.');
        }
        expenses.add(Expense.fromJson(entry));
      }
    }

    final database = await _openDatabase();
    await database.transaction((transaction) async {
      if (expenses.isNotEmpty) {
        const legacyAccountId = 'legacy-cash-account';
        await transaction.insert('accounts', {
          'id': legacyAccountId,
          'name': 'Cash',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        for (final expense in expenses) {
          await transaction.insert('expenses', {
            ..._expenseValues(expense),
            'account_id': legacyAccountId,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    });

    final migrated = await preferences.setBool(_migrationKey, true);
    if (!migrated) {
      throw StateError('Could not save expense migration status.');
    }
  }

  Future<List<Expense>> loadExpenses() async {
    final database = await _openDatabase();
    final rows = await database.query('expenses', orderBy: 'date DESC');
    return rows.map(_expenseFromRow).toList(growable: false);
  }

  Future<List<ExpenseAccount>> loadAccounts() async {
    final database = await _openDatabase();
    final rows = await database.query(
      'accounts',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows
        .map(
          (row) => ExpenseAccount(
            id: row['id'] as String,
            name: row['name'] as String,
            openingBalancePaise: row['opening_balance_paise'] as int,
          ),
        )
        .toList(growable: false);
  }

  Future<ExpenseAccount> addAccount(
    String name, {
    int openingBalancePaise = 0,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Account name cannot be empty.');
    }
    if (openingBalancePaise < 0) {
      throw ArgumentError.value(
        openingBalancePaise,
        'openingBalancePaise',
        'Opening balance cannot be negative.',
      );
    }
    final account = ExpenseAccount(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: normalizedName,
      openingBalancePaise: openingBalancePaise,
    );
    final database = await _openDatabase();
    await database.insert('accounts', {
      'id': account.id,
      'name': account.name,
      'opening_balance_paise': account.openingBalancePaise,
    });
    return account;
  }

  Future<List<ExpenseCategory>> loadCategories() async {
    final database = await _openDatabase();
    final rows = await database.query(
      'categories',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows
        .map((row) => ExpenseCategory.fromName(row['name'] as String))
        .toList(growable: false);
  }

  Future<ExpenseCategory> addCategory(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Category name cannot be empty.');
    }
    final category = ExpenseCategory.fromName(normalizedName);
    final database = await _openDatabase();
    await database.insert('categories', {'name': category.name});
    return category;
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final database = await _openDatabase();
    await database.transaction((transaction) async {
      await transaction.delete('expenses');
      for (final expense in expenses) {
        await transaction.insert('expenses', _expenseValues(expense));
      }
    });
  }

  Map<String, Object?> _expenseValues(Expense expense) => {
    'id': expense.id,
    'title': expense.title,
    'amount_paise': expense.amountPaise,
    'category': expense.category,
    'date': expense.date.toIso8601String(),
    'note': expense.note,
    'account_id': expense.accountId,
  };

  Expense _expenseFromRow(Map<String, Object?> row) => Expense(
    id: row['id'] as String,
    title: row['title'] as String,
    amountPaise: row['amount_paise'] as int,
    category: row['category'] as String,
    date: DateTime.parse(row['date'] as String),
    note: row['note'] as String,
    accountId: row['account_id'] as String?,
  );
}
