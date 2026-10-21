import 'package:flutter/material.dart';

import 'expense_widget_styles.dart';

class ExpenseHomeHeader extends StatelessWidget {
  const ExpenseHomeHeader({super.key, required this.onChooseDate});

  final VoidCallback onChooseDate;

  @override
  Widget build(BuildContext context) {
    final palette = context.expensePalette;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: palette.accent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.spa_rounded, color: Colors.white, size: 23),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'kanakku note',
              style: TextStyle(
                color: palette.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -.4,
              ),
            ),
            Text(
              'A little clarity, every day',
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Choose date',
          onPressed: onChooseDate,
          style: IconButton.styleFrom(backgroundColor: palette.surface),
          icon: Icon(Icons.calendar_month_rounded, color: palette.ink),
        ),
      ],
    );
  }
}
