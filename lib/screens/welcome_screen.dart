import 'package:flutter/material.dart';

import '../widgets/expense/expense_widget_styles.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onContinue});

  final Future<void> Function(BuildContext context) onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 480,
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_long, color: expenseInk),
                          const SizedBox(width: 10),
                          Text(
                            'Kanakku Note',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: expenseInk,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            width: 168,
                            height: 168,
                            decoration: const BoxDecoration(
                              color: expenseMint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: expenseInk,
                              size: 80,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'A clearer view of your spending',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: expenseInk,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Keep track of everyday expenses, see your daily '
                            'and monthly totals, and feel more in control of '
                            'your money.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: expenseMuted, height: 1.6),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: () => onContinue(context),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Next'),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward),
                            ],
                          ),
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
