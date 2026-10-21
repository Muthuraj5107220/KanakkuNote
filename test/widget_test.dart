import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanakku_note/main.dart';
import 'package:kanakku_note/services/expense_storage.dart';
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
    await tester.runAsync(storage.initialize);
    await tester.pumpWidget(KanakkuNoteApp(storage: storage));
    await pumpUntilReady(tester);

    if (find.text('Next').evaluate().isNotEmpty) {
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 500));
    }
    if (find.text('Create your accounts').evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextField).first, 'Cash');
      await tester.tap(find.byTooltip('Add account'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Continue'));
      await pumpUntilReady(tester);
    }
  }

  testWidgets('requires an account after welcome and continues to dashboard', (
    tester,
  ) async {
    await tester.runAsync(storage.initialize);
    await tester.pumpWidget(KanakkuNoteApp(storage: storage));
    await pumpUntilReady(tester);

    expect(find.text('A clearer view of your spending'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Create your accounts'), findsOneWidget);
    expect(find.text('Add at least one account to continue.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField).first, 'Cash');
    await tester.tap(find.byTooltip('Add account'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Cash'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await pumpUntilReady(tester);

    expect(find.text('Your money, in focus'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(KanakkuNoteApp(storage: storage));
    await pumpUntilReady(tester);

    expect(find.text('A clearer view of your spending'), findsNothing);
    expect(find.text('Create your accounts'), findsNothing);
    expect(find.text('Your money, in focus'), findsOneWidget);
  });

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
}
