import 'package:flutter/material.dart';

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
  final ValueChanged<List<ExpenseAccount>> onContinue;

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final _nameController = TextEditingController();
  late final List<ExpenseAccount> _accounts = [...widget.initialAccounts];
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addAccount() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _saving) return;

    setState(() => _saving = true);
    try {
      final account = await widget.storage.addAccount(name);
      if (!mounted) return;
      setState(() {
        _accounts.add(account);
        _nameController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: expenseInk,
                    size: 36,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Create your accounts',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: expenseInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add the places you spend from, like Cash, Bank, or UPI. '
                    'You can assign each expense to an account.',
                    style: TextStyle(
                      color: expenseMuted,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addAccount(),
                          decoration: const InputDecoration(
                            labelText: 'Account name',
                            hintText: 'e.g. Cash',
                            prefixIcon: Icon(Icons.account_balance_outlined),
                          ),
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
                  const SizedBox(height: 8),
                  if (_accounts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Add at least one account to continue.',
                        style: TextStyle(color: expenseMuted),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(top: 12),
                        itemCount: _accounts.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final account = _accounts[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: expenseLine),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_outlined,
                                  color: expenseInk,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    account.name,
                                    style: const TextStyle(
                                      color: expenseInk,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.check_circle,
                                  color: expenseInk,
                                  size: 20,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  if (_accounts.isEmpty) const Spacer(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _accounts.isEmpty || _saving
                          ? null
                          : () => widget.onContinue(_accounts),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
