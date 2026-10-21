import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'expense_widget_styles.dart';

class WeeklySpendingCard extends StatelessWidget {
  const WeeklySpendingCard({
    super.key,
    required this.selectedDate,
    required this.totalForDay,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final int Function(DateTime day) totalForDay;
  final ValueChanged<DateTime> onDateSelected;

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  @override
  Widget build(BuildContext context) {
    final palette = context.expensePalette;
    final monday = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    final days = List.generate(
      7,
      (index) => DateUtils.dateOnly(monday.add(Duration(days: index))),
    );
    final maxSpend = days
        .map(totalForDay)
        .fold<int>(0, (max, value) => value > max ? value : max);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'This week',
                  style: TextStyle(
                    color: palette.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '${DateFormat('d MMM').format(days.first)} — ${DateFormat('d MMM').format(days.last)}',
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(days.length, (index) {
              final day = days[index];
              final amount = totalForDay(day);
              final selected = _isSameDay(day, selectedDate);
              final normalized = maxSpend == 0 ? 0.0 : amount / maxSpend;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onDateSelected(day),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 58,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 18,
                              height: amount == 0 ? 5 : 9 + normalized * 39,
                              decoration: BoxDecoration(
                                color: selected
                                    ? palette.ink
                                    : const Color(0xFFB6D5BE),
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('E').format(day).substring(0, 1),
                          style: TextStyle(
                            color: selected ? palette.ink : palette.muted,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            color: selected ? palette.ink : palette.muted,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
