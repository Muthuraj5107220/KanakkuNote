import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../services/expense_storage.dart';
import '../widgets/expense/expense_widget_styles.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({
    super.key,
    required this.storage,
    required this.initialAccounts,
    required this.onContinue,
  });

  final ExpenseStorage storage;
  final List<ExpenseAccount> initialAccounts;
  final Future<void> Function(List<ExpenseAccount> accounts) onContinue;

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  late final List<ExpenseAccount> _accounts = [...widget.initialAccounts];
  bool _saving = false;
  bool _continuing = false;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  int? _parseOpeningBalance(String value) {
    final normalized = value.trim().replaceAll(',', '');
    if (normalized.isEmpty) return 0;
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized)) return null;

    final parts = normalized.split('.');
    final rupees = int.tryParse(parts.first);
    if (rupees == null) return null;
    final paise = parts.length == 1
        ? 0
        : int.parse(parts.last.padRight(2, '0'));
    return rupees * 100 + paise;
  }

  Future<void> _addAccount() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final openingBalancePaise = _parseOpeningBalance(
      _openingBalanceController.text,
    )!;

    setState(() => _saving = true);
    try {
      final account = await widget.storage.addAccount(
        _nameController.text.trim(),
        openingBalancePaise: openingBalancePaise,
      );
      if (!mounted) return;
      setState(() {
        _accounts.add(account);
        _nameController.clear();
        _openingBalanceController.clear();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add account: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _continue() async {
    if (_accounts.isEmpty || _saving || _continuing) return;
    _continuing = true;
    try {
      await widget.onContinue(_accounts);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not continue: $error')));
      }
    } finally {
      _continuing = false;
    }
  }

  Widget _accountCard(ExpenseAccount account) {
    final palette = context.expensePalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_outlined, color: palette.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: TextStyle(
                    color: palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Opening balance: ${_currencyFormat.format(account.openingBalancePaise / 100)}',
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: palette.ink, size: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.expensePalette;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: palette.ink,
                        size: 36,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create your accounts',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: palette.ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add the places you spend from, like Cash, Bank, or '
                        'UPI. You can assign each expense to an account.',
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _nameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Account name',
                                      hintText: 'e.g. Cash',
                                      prefixIcon: Icon(
                                        Icons.account_balance_outlined,
                                      ),
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Enter an account name'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton.filled(
                                  onPressed: _saving ? null : _addAccount,
                                  tooltip: 'Add account',
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _openingBalanceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _addAccount(),
                              decoration: const InputDecoration(
                                labelText: 'Opening balance',
                                hintText: '0.00',
                                prefixText: '₹ ',
                                prefixIcon: Icon(Icons.account_balance_wallet),
                              ),
                              validator: (value) =>
                                  _parseOpeningBalance(value ?? '') == null
                                  ? 'Enter a valid non-negative amount'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_accounts.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(
                            'Add at least one account to continue.',
                            style: TextStyle(color: palette.muted),
                          ),
                        )
                      else ...[
                        const SizedBox(height: 12),
                        for (var index = 0; index < _accounts.length; index++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == _accounts.length - 1 ? 0 : 8,
                            ),
                            child: _accountCard(_accounts[index]),
                          ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: _accounts.isEmpty || _saving
                              ? null
                              : _continue,
                          child: const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
