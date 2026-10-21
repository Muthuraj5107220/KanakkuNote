import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/expense_storage.dart';
import '../widgets/navigation/floating_bottom_bar.dart';
import '../widgets/expense/expense_dashboard.dart';
import '../widgets/expense/expense_form_sheet.dart';
import '../widgets/expense/expense_load_error_state.dart';
import '../widgets/expense/expense_widget_styles.dart';
import 'settings_screen.dart';

class ExpenseHomeScreen extends StatefulWidget {
  const ExpenseHomeScreen({
    super.key,
    required this.storage,
    required this.accounts,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ExpenseStorage storage;
  final List<ExpenseAccount> accounts;
  final ThemeMode themeMode;
  final Future<void> Function(BuildContext context, ThemeMode mode)
  onThemeModeChanged;

  @override
  State<ExpenseHomeScreen> createState() => _ExpenseHomeScreenState();
}

class _ExpenseHomeScreenState extends State<ExpenseHomeScreen> {
  List<Expense> _expenses = [];
  List<ExpenseCategory> _categories = ExpenseCategory.all;
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  int _selectedDestination = 0;
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
      final expenses = await widget.storage.loadExpenses();
      final categories = await widget.storage.loadCategories();
      if (!mounted) return;
      setState(() {
        _expenses = expenses;
        _categories = categories;
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

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  List<Expense> get _dayExpenses {
    final items = _expenses
        .where((expense) => _isSameDay(expense.date, _selectedDate))
        .toList();
    items.sort((first, second) => second.date.compareTo(first.date));
    return items;
  }

  int get _dayTotalPaise =>
      _dayExpenses.fold(0, (sum, expense) => sum + expense.amountPaise);

  int get _monthTotalPaise => _expenses
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => ExpenseFormSheet(
        initial: expense,
        defaultDate: _selectedDate,
        accounts: widget.accounts,
        categories: _categories,
      ),
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

  Future<void> _addExpense() async {
    if (_selectedDestination != 0) {
      setState(() => _selectedDestination = 0);
    }
    await _openExpenseForm();
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
      await widget.storage.saveExpenses(updated);
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
          colorScheme: Theme.of(context).colorScheme
              .copyWith(primary: context.expensePalette.ink),
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
      extendBody: true,
      bottomNavigationBar: FloatingBottomBar(
        selectedIndex: _selectedDestination,
        onDestinationSelected: (index) =>
            setState(() => _selectedDestination = index),
        onAddExpense: _loading || _loadError != null ? null : _addExpense,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _selectedDestination == 1
                ? SettingsScreen(
                    themeMode: widget.themeMode,
                    onThemeModeChanged: widget.onThemeModeChanged,
                  )
                : _loading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? ExpenseLoadErrorState(
                    error: _loadError!,
                    onRetry: _loadExpenses,
                  )
                : ExpenseDashboard(
                    selectedDate: _selectedDate,
                    dayExpenses: _dayExpenses,
                    dayTotalPaise: _dayTotalPaise,
                    monthTotalPaise: _monthTotalPaise,
                    totalForDay: _totalForDay,
                    onChooseDate: _pickDate,
                    onPreviousDay: () => _changeDay(-1),
                    onNextDay: () => _changeDay(1),
                    onSelectDate: (date) =>
                        setState(() => _selectedDate = date),
                    onEditExpense: (expense) =>
                        _openExpenseForm(expense: expense),
                    onDeleteExpense: _deleteExpense,
                    accounts: widget.accounts,
                  ),
          ),
        ),
      ),
    );
  }
}
