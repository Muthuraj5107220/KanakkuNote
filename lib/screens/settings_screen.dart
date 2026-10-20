import 'package:flutter/material.dart';

import '../widgets/expense/expense_widget_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 112),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: expenseInk,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your app and data, at a glance.',
                  style: TextStyle(color: expenseMuted, fontSize: 14),
                ),
                const SizedBox(height: 24),
                _SettingsSection(
                  icon: Icons.shield_outlined,
                  title: 'Privacy',
                  description: 'Your expenses stay on this device. Kanakku Note does not require an account or send your entries to a server.',
                ),
                const SizedBox(height: 14),
                _SettingsSection(
                  icon: Icons.storage_outlined,
                  title: 'Expense storage',
                  description: 'Expense data is saved locally on your device so it is available when you reopen the app.',
                ),
                const SizedBox(height: 14),
                _SettingsSection(
                  icon: Icons.info_outline_rounded,
                  title: 'About Kanakku Note',
                  description: 'A simple, local-first daily expense manager to help you keep spending in focus.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: expenseLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: expenseMint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: expenseInk, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: expenseInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: expenseMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
