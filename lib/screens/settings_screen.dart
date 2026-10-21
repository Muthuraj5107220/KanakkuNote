import 'package:flutter/material.dart';

import '../widgets/expense/expense_widget_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final Future<void> Function(BuildContext context, ThemeMode mode)
  onThemeModeChanged;

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
                Text(
                  'Settings',
                  style: TextStyle(
                    color: context.expensePalette.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your app and data, at a glance.',
                  style: TextStyle(
                    color: context.expensePalette.muted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                _ThemeSelection(
                  themeMode: themeMode,
                  onChanged: onThemeModeChanged,
                ),
                const SizedBox(height: 14),
                _SettingsSection(
                  icon: Icons.shield_outlined,
                  title: 'Privacy',
                  description: 'Your expense and account data stay on this device. No online account is required, and entries are not sent to a server.',
                ),
                const SizedBox(height: 14),
                _SettingsSection(
                  icon: Icons.storage_outlined,
                  title: 'Expense storage',
                  description: 'Expenses and accounts are saved in a local SQLite database on your device.',
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

class _ThemeSelection extends StatelessWidget {
  const _ThemeSelection({required this.themeMode, required this.onChanged});

  final ThemeMode themeMode;
  final Future<void> Function(BuildContext context, ThemeMode mode) onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.expensePalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: palette.ink),
              const SizedBox(width: 12),
              Text(
                'Theme',
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) =>
                  onChanged(context, selection.single),
            ),
          ),
        ],
      ),
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
    final palette = context.expensePalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.mint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: palette.ink, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: palette.muted,
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
