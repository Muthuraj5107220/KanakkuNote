import 'package:flutter/material.dart';

import 'expense_widget_styles.dart';

class ExpenseHomeHeader extends StatelessWidget {
  const ExpenseHomeHeader({super.key, required this.onChooseDate});

  final VoidCallback onChooseDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: expenseInk,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.spa_rounded, color: Colors.white, size: 23),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'kanakku note',
              style: TextStyle(
                color: expenseInk,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -.4,
              ),
            ),
            Text(
              'A little clarity, every day',
              style: TextStyle(color: expenseMuted, fontSize: 12),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Choose date',
          onPressed: onChooseDate,
          style: IconButton.styleFrom(backgroundColor: Colors.white),
          icon: const Icon(Icons.calendar_month_rounded, color: expenseInk),
        ),
      ],
    );
  }
}
