import 'package:flutter/material.dart';

import 'expense_widget_styles.dart';

class EmptyExpensesState extends StatelessWidget {
  const EmptyExpensesState({super.key, required this.isToday});

  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: expenseLine),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: expenseMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings_outlined,
              color: expenseInk,
              size: 25,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            isToday ? 'A fresh start' : 'Nothing logged here',
            style: const TextStyle(
              color: expenseInk,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isToday
                ? 'Add your first expense and keep your day in view.'
                : 'There are no expenses for this day.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: expenseMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
