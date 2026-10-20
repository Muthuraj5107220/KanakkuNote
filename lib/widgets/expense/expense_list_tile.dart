import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/expense.dart';
import 'expense_widget_styles.dart';

class ExpenseListTile extends StatelessWidget {
  const ExpenseListTile({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final category = ExpenseCategory.fromName(expense.category);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: expenseLine),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(category.icon, color: category.color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: expenseInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${expense.category}  ·  ${DateFormat('h:mm a').format(expense.date)}',
                      style: const TextStyle(color: expenseMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                formatExpenseAmount(expense.amountPaise),
                style: const TextStyle(
                  color: expenseInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Expense options',
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: expenseMuted,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
