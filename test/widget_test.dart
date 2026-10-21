import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanakku_note/main.dart';
import 'package:kanakku_note/models/expense.dart';
import 'package:kanakku_note/screens/account_setup_screen.dart';
import 'package:kanakku_note/services/expense_storage.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late ExpenseStorage storage;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = ExpenseStorage(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await storage.close();
  });

  Future<void> pumpUntilReady(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('A clearer view of your spending').evaluate().isNotEmpty ||
          find.text('Create your accounts').evaluate().isNotEmpty ||
          find.text('Your money, in focus').evaluate().isNotEmpty ||
          find.textContaining('Could not start app').evaluate().isNotEmpty) {
        return;
      }
    }
  }

  Future<void> openDashboard(WidgetTester tester) async {
    await tester.runAsync(() async {
      await storage.initialize();
      await storage.addAccount('Cash');
      SharedPreferences.setMockInitialValues({
        'kanakku_note.welcome_completed.v1': true,
        'kanakku_note.sqlite_migration_completed.v1': true,
      });
    });
    await tester.pumpWidget(KanakkuNoteApp(storage: storage));
    await pumpUntilReady(tester);
  }

  testWidgets('shows account setup after the welcome screen', (tester) async {
    await tester.runAsync(storage.initialize);
    await tester.pumpWidget(KanakkuNoteApp(storage: storage));
    await pumpUntilReady(tester);

    expect(find.text('A clearer view of your spending'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Create your accounts'), findsOneWidget);
    expect(find.text('Add at least one account to continue.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(KanakkuNoteApp(storage: storage));
    await pumpUntilReady(tester);

    expect(find.text('A clearer view of your spending'), findsNothing);
    expect(find.text('Create your accounts'), findsOneWidget);
  });

  testWidgets(
    'creates an account with an opening balance and enables continue',
    (tester) async {
      await tester.runAsync(storage.initialize);
      var continuedAccounts = <ExpenseAccount>[];
      await tester.pumpWidget(
        MaterialApp(
          home: AccountSetupScreen(
            storage: storage,
            initialAccounts: const [],
            onContinue: (accounts) async {
              continuedAccounts = accounts;
            },
          ),
        ),
      );

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Cash');
      await tester.enterText(find.byType(TextFormField).at(1), '-1');
      await tester.tap(find.byTooltip('Add account'));
      await tester.pump();
      expect(find.text('Enter a valid non-negative amount'), findsOneWidget);
      expect(await tester.runAsync(storage.loadAccounts), isEmpty);

      await tester.enterText(find.byType(TextFormField).at(1), '1234.56');
      await tester.tap(find.byTooltip('Add account'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Opening balance: ₹1,234.56'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Continue'));

      expect(continuedAccounts, hasLength(1));
      expect(continuedAccounts.single.name, 'Cash');
      expect(continuedAccounts.single.openingBalancePaise, 123456);
      final savedAccounts = await tester.runAsync(storage.loadAccounts);
      expect(savedAccounts!.single.openingBalancePaise, 123456);
    },
  );

  testWidgets('shows the daily expense dashboard', (tester) async {
    await openDashboard(tester);

    expect(find.text('Your money, in focus'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('A fresh start'), findsOneWidget);
    expect(find.text('Add expense'), findsOneWidget);
  });

  testWidgets('bottom bar opens settings and returns to dashboard', (
    tester,
  ) async {
    await openDashboard(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Expense storage'), findsOneWidget);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Your money, in focus'), findsOneWidget);
  });

  testWidgets('adds an expense to the selected day', (tester) async {
    await openDashboard(tester);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Coffee');
    await tester.enterText(find.byType(TextFormField).at(1), '125.50');
    await tester.ensureVisible(find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('₹125.50'), findsWidgets);
    expect(find.text('1 entry'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(KanakkuNoteApp(storage: storage));
    await pumpUntilReady(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.textContaining('Food & drink  ·  Cash'), findsOneWidget);
  });

  test('imports legacy JSON expenses into SQLite', () async {
    final date = DateTime(2026, 10, 21, 9);
    SharedPreferences.setMockInitialValues({
      'kanakku_note.expenses.v1': jsonEncode([
        {
          'id': 'legacy-expense',
          'title': 'Legacy lunch',
          'amountPaise': 45000,
          'category': 'Food & drink',
          'date': date.toIso8601String(),
          'note': 'Imported entry',
        },
      ]),
    });

    await storage.initialize();
    final expenses = await storage.loadExpenses();
    final accounts = await storage.loadAccounts();

    expect(expenses, hasLength(1));
    expect(expenses.single.title, 'Legacy lunch');
    expect(expenses.single.accountId, 'legacy-cash-account');
    expect(accounts, hasLength(1));
    expect(accounts.single.name, 'Cash');
  });

  test('persists an account opening balance in SQLite', () async {
    await storage.initialize();
    await storage.addAccount('Savings', openingBalancePaise: 287550);

    final accounts = await storage.loadAccounts();
    expect(accounts.single.name, 'Savings');
    expect(accounts.single.openingBalancePaise, 287550);
  });

  test(
    'upgrades existing SQLite accounts with a zero opening balance',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'kanakku-note-db-upgrade-',
      );
      final databasePath = path.join(directory.path, 'legacy.db');
      final legacyDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (database, version) async {
            await database.execute('''
            CREATE TABLE accounts (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL COLLATE NOCASE UNIQUE
            )
          ''');
            await database.insert('accounts', {
              'id': 'existing-account',
              'name': 'Existing',
            });
            await database.execute('''
            CREATE TABLE expenses (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              amount_paise INTEGER NOT NULL,
              category TEXT NOT NULL,
              date TEXT NOT NULL,
              note TEXT NOT NULL,
              account_id TEXT
            )
          ''');
          },
        ),
      );
      await legacyDatabase.close();

      final upgradedStorage = ExpenseStorage(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      try {
        await upgradedStorage.initialize();
        final accounts = await upgradedStorage.loadAccounts();
        expect(accounts.single.name, 'Existing');
        expect(accounts.single.openingBalancePaise, 0);
      } finally {
        await upgradedStorage.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
