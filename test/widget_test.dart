import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanakku_note/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the daily expense dashboard', (tester) async {
    await tester.pumpWidget(const KanakkuNoteApp());
    await tester.pumpAndSettle();

    expect(find.text('Your money, in focus'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('A fresh start'), findsOneWidget);
    expect(find.text('Add expense'), findsOneWidget);
  });

  testWidgets('adds an expense to the selected day', (tester) async {
    await tester.pumpWidget(const KanakkuNoteApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Coffee');
    await tester.enterText(find.byType(TextFormField).at(1), '125.50');
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('₹125.50'), findsWidgets);
    expect(find.text('1 entry'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const KanakkuNoteApp());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
  });
}
