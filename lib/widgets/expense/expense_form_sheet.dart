import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/expense.dart';
import 'expense_widget_styles.dart';

class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({
    super.key,
    this.initial,
    required this.defaultDate,
    required this.accounts,
  });

  final Expense? initial;
  final DateTime defaultDate;
  final List<ExpenseAccount> accounts;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _category;
  late String _accountId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final expense = widget.initial;
    _titleController = TextEditingController(text: expense?.title ?? '');
    _amountController = TextEditingController(
      text: expense == null
          ? ''
          : (expense.amountPaise / 100).toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: expense?.note ?? '');
    _category = expense?.category ?? ExpenseCategory.all.first.name;
    _accountId =
        expense?.accountId ??
        (widget.accounts.isEmpty ? '' : widget.accounts.first.id);
    _date =
        expense?.date ??
        DateTime(
          widget.defaultDate.year,
          widget.defaultDate.month,
          widget.defaultDate.day,
          DateTime.now().hour,
          DateTime.now().minute,
        );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? _parsePaise(String value) {
    final normalized = value.trim().replaceAll(',', '');
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized)) return null;
    final parts = normalized.split('.');
    final rupees = int.tryParse(parts.first);
    if (rupees == null) return null;
    final paise = parts.length == 1
        ? 0
        : int.parse(parts.last.padRight(2, '0'));
    return rupees * 100 + paise;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final expense = Expense(
      id:
          widget.initial?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      amountPaise: _parsePaise(_amountController.text)!,
      category: _category,
      date: _date,
      accountId: _accountId,
      note: _noteController.text.trim(),
    );
    Navigator.pop(context, expense);
  }

  Future<void> _chooseDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (chosen != null) {
      setState(
        () => _date = DateTime(
          chosen.year,
          chosen.month,
          chosen.day,
          _date.hour,
          _date.minute,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        22 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: expenseLine,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                editing ? 'Edit expense' : 'Add an expense',
                style: const TextStyle(
                  color: expenseInk,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Keep the little things in sight.',
                style: TextStyle(color: expenseMuted, fontSize: 13),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _titleController,
                autofocus: false,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What did you spend on?',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Add a short description'
                    : null,
              ),
              const SizedBox(height: 13),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                ),
                validator: (value) {
                  final amount = value == null ? null : _parsePaise(value);
                  return amount == null || amount <= 0
                      ? 'Enter an amount greater than zero'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _accountId,
                decoration: const InputDecoration(
                  labelText: 'Account',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                items: widget.accounts
                    .map(
                      (account) => DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      ),
                    )
                    .toList(),
                onChanged: (accountId) {
                  if (accountId != null) {
                    setState(() => _accountId = accountId);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Category',
                style: TextStyle(
                  color: expenseInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.all.map((category) {
                  final selected = _category == category.name;
                  return ChoiceChip(
                    label: Text(category.name),
                    avatar: Icon(
                      category.icon,
                      size: 16,
                      color: selected ? Colors.white : category.color,
                    ),
                    selected: selected,
                    selectedColor: expenseInk,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : expenseInk,
                      fontSize: 12,
                    ),
                    onSelected: (_) =>
                        setState(() => _category = category.name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 13),
              TextFormField(
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.event_rounded),
                label: Text(DateFormat('EEE, d MMM yyyy').format(_date)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(backgroundColor: expenseInk),
                  child: Text(
                    editing ? 'Save changes' : 'Save expense',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
