import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'expense_widget_styles.dart';

class ExpenseSummaryCard extends StatelessWidget {
  const ExpenseSummaryCard({
    super.key,
    required this.date,
    required this.dayTotalPaise,
    required this.monthTotalPaise,
    required this.onPreviousDay,
    required this.onNextDay,
  });

  final DateTime date;
  final int dayTotalPaise;
  final int monthTotalPaise;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: expenseInk,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: expenseInk.withValues(alpha: .14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.wb_sunny_outlined,
                color: Color(0xFFB9D5BF),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, d MMMM').format(date),
                style: const TextStyle(
                  color: Color(0xFFB9D5BF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Previous day',
                visualDensity: VisualDensity.compact,
                onPressed: onPreviousDay,
                color: Colors.white,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Next day',
                visualDensity: VisualDensity.compact,
                onPressed: onNextDay,
                color: Colors.white,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            formatExpenseAmount(dayTotalPaise),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.1,
            ),
          ),
          const Text(
            'spent this day',
            style: TextStyle(color: Color(0xFFB9D5BF), fontSize: 13),
          ),
          const SizedBox(height: 22),
          Container(height: 1, color: Colors.white.withValues(alpha: .15)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.calendar_view_month_rounded,
                size: 17,
                color: Color(0xFFB9D5BF),
              ),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('MMMM').format(date)} total',
                style: const TextStyle(color: Color(0xFFB9D5BF), fontSize: 13),
              ),
              const Spacer(),
              Text(
                formatCompactExpenseAmount(monthTotalPaise),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
