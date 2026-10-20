import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../services/expense_storage.dart';

const _ink = Color(0xFF173D35);
const _muted = Color(0xFF7C8982);
const _line = Color(0xFFE8ECE6);
const _mint = Color(0xFFE7F1E9);
final _money = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);
final _compactMoney = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

class ExpenseHomeScreen extends StatefulWidget {
  const ExpenseHomeScreen({super.key});

  @override
  State<ExpenseHomeScreen> createState() => _ExpenseHomeScreenState();
}

class _ExpenseHomeScreenState extends State<ExpenseHomeScreen> {
  final _storage = ExpenseStorage();
  List<Expense> _expenses = [];
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  bool _loading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final expenses = await _storage.loadExpenses();
      if (!mounted) return;
      setState(() {
        _expenses = expenses;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Expense> get _dayExpenses {
    final items = _expenses
        .where((expense) => _isSameDay(expense.date, _selectedDate))
        .toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  int get _dayTotal =>
      _dayExpenses.fold(0, (sum, expense) => sum + expense.amountPaise);

  int get _monthTotal => _expenses
      .where(
        (expense) =>
            expense.date.year == _selectedDate.year &&
            expense.date.month == _selectedDate.month,
      )
      .fold(0, (sum, expense) => sum + expense.amountPaise);

  int _totalForDay(DateTime day) => _expenses
      .where((expense) => _isSameDay(expense.date, day))
      .fold(0, (sum, expense) => sum + expense.amountPaise);

  Future<void> _openExpenseForm({Expense? expense}) async {
    final result = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) =>
          _ExpenseForm(initial: expense, defaultDate: _selectedDate),
    );
    if (result == null || !mounted) return;

    final updated = [..._expenses];
    final index = updated.indexWhere((item) => item.id == result.id);
    if (index == -1) {
      updated.add(result);
    } else {
      updated[index] = result;
    }
    await _persist(updated);
    if (mounted) {
      setState(() => _selectedDate = DateUtils.dateOnly(result.date));
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Remove "${expense.title}" from your entries?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB84F48),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final updated = _expenses.where((item) => item.id != expense.id).toList();
    await _persist(updated);
  }

  Future<void> _persist(List<Expense> updated) async {
    try {
      await _storage.saveExpenses(updated);
      if (mounted) setState(() => _expenses = updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save your expense: $error')),
        );
      }
    }
  }

  void _changeDay(int offset) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: offset)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: _ink),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = DateUtils.dateOnly(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading || _loadError != null
            ? null
            : () => _openExpenseForm(),
        backgroundColor: _ink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add expense'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _ink))
                : _loadError != null
                ? _ErrorState(error: _loadError!, onRetry: _loadExpenses)
                : _buildDashboard(),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final today = DateUtils.dateOnly(DateTime.now());
    final isToday = _isSameDay(_selectedDate, today);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.spa_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'kanakku note',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4,
                      ),
                    ),
                    Text(
                      'A little clarity, every day',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Choose date',
                  onPressed: _pickDate,
                  style: IconButton.styleFrom(backgroundColor: Colors.white),
                  icon: const Icon(Icons.calendar_month_rounded, color: _ink),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Your money, in focus',
                    style: TextStyle(color: _muted, fontSize: 14),
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          sliver: SliverToBoxAdapter(child: _summaryCard()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(child: _weekCard()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 27, 24, 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Your expenses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                ),
                Text(
                  '${_dayExpenses.length} ${_dayExpenses.length == 1 ? 'entry' : 'entries'}',
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        if (_dayExpenses.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 112),
            sliver: SliverToBoxAdapter(child: _EmptyState(isToday: isToday)),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 112),
            sliver: SliverList.separated(
              itemCount: _dayExpenses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final expense = _dayExpenses[index];
                return _ExpenseTile(
                  expense: expense,
                  onEdit: () => _openExpenseForm(expense: expense),
                  onDelete: () => _deleteExpense(expense),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: .14),
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
                DateFormat('EEEE, d MMMM').format(_selectedDate),
                style: const TextStyle(
                  color: Color(0xFFB9D5BF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _changeDay(-1),
                color: Colors.white,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _changeDay(1),
                color: Colors.white,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            _money.format(_dayTotal / 100),
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
                '${DateFormat('MMMM').format(_selectedDate)} total',
                style: const TextStyle(color: Color(0xFFB9D5BF), fontSize: 13),
              ),
              const Spacer(),
              Text(
                _compactMoney.format(_monthTotal / 100),
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

  Widget _weekCard() {
    final monday = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    final days = List.generate(
      7,
      (index) => DateUtils.dateOnly(monday.add(Duration(days: index))),
    );
    final maxSpend = days
        .map(_totalForDay)
        .fold<int>(0, (max, value) => value > max ? value : max);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'This week',
                  style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '${DateFormat('d MMM').format(days.first)} — ${DateFormat('d MMM').format(days.last)}',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(days.length, (index) {
              final day = days[index];
              final amount = _totalForDay(day);
              final selected = _isSameDay(day, _selectedDate);
              final normalized = maxSpend == 0 ? 0.0 : amount / maxSpend;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedDate = day),
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
                                    ? _ink
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
                            color: selected ? _ink : _muted,
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
                            color: selected ? _ink : _muted,
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

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
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
            border: Border.all(color: _line),
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
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${expense.category}  ·  ${DateFormat('h:mm a').format(expense.date)}',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                _money.format(expense.amountPaise / 100),
                style: const TextStyle(
                  color: _ink,
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
                  color: _muted,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isToday});

  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: _mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings_outlined, color: _ink, size: 25),
          ),
          const SizedBox(height: 13),
          Text(
            isToday ? 'A fresh start' : 'Nothing logged here',
            style: const TextStyle(
              color: _ink,
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
            style: const TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFB84F48),
              size: 38,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load your expenses',
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  const _ExpenseForm({this.initial, required this.defaultDate});

  final Expense? initial;
  final DateTime defaultDate;

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _category;
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
                    color: _line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                editing ? 'Edit expense' : 'Add an expense',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Keep the little things in sight.',
                style: TextStyle(color: _muted, fontSize: 13),
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
              const Text(
                'Category',
                style: TextStyle(
                  color: _ink,
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
                    selectedColor: _ink,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : _ink,
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
                  style: FilledButton.styleFrom(backgroundColor: _ink),
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
