import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/expense.dart';
import 'empty_expenses_state.dart';
import 'expense_home_header.dart';
import 'expense_list_tile.dart';
import 'expense_summary_card.dart';
import 'expense_widget_styles.dart';
import 'weekly_spending_card.dart';

class ExpenseDashboard extends StatelessWidget {
  const ExpenseDashboard({
    super.key,
    required this.selectedDate,
    required this.dayExpenses,
    required this.dayTotalPaise,
    required this.monthTotalPaise,
    required this.totalForDay,
    required this.onChooseDate,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onSelectDate,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.accounts,
  });

  final DateTime selectedDate;
  final List<Expense> dayExpenses;
  final int dayTotalPaise;
  final int monthTotalPaise;
  final int Function(DateTime day) totalForDay;
  final VoidCallback onChooseDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<Expense> onEditExpense;
  final ValueChanged<Expense> onDeleteExpense;
  final List<ExpenseAccount> accounts;

  bool get _isToday {
    final today = DateUtils.dateOnly(DateTime.now());
    return selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.expensePalette;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
          sliver: SliverToBoxAdapter(
            child: ExpenseHomeHeader(onChooseDate: onChooseDate),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Your money, in focus',
                    style: TextStyle(color: palette.muted, fontSize: 14),
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(selectedDate),
                  style: TextStyle(
                    color: palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          sliver: SliverToBoxAdapter(
            child: ExpenseSummaryCard(
              date: selectedDate,
              dayTotalPaise: dayTotalPaise,
              monthTotalPaise: monthTotalPaise,
              onPreviousDay: onPreviousDay,
              onNextDay: onNextDay,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(
            child: WeeklySpendingCard(
              selectedDate: selectedDate,
              totalForDay: totalForDay,
              onDateSelected: onSelectDate,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 27, 24, 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Your expenses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: palette.ink,
                    ),
                  ),
                ),
                Text(
                  '${dayExpenses.length} ${dayExpenses.length == 1 ? 'entry' : 'entries'}',
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        if (dayExpenses.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 112),
            sliver: SliverToBoxAdapter(
              child: EmptyExpensesState(isToday: _isToday),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 112),
            sliver: SliverList.separated(
              itemCount: dayExpenses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final expense = dayExpenses[index];
                final accountName = accounts
                    .where((account) => account.id == expense.accountId)
                    .map((account) => account.name)
                    .firstOrNull;
                return ExpenseListTile(
                  expense: expense,
                  accountName: accountName,
                  onEdit: () => onEditExpense(expense),
                  onDelete: () => onDeleteExpense(expense),
                );
              },
            ),
          ),
      ],
    );
  }
}
