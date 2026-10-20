import 'package:flutter/material.dart';

import '../expense/expense_widget_styles.dart';

class FloatingBottomBar extends StatelessWidget {
  const FloatingBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAddExpense,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onAddExpense;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: expenseLine),
          boxShadow: [
            BoxShadow(
              color: expenseInk.withValues(alpha: .10),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavigationDestination(
                label: 'Dashboard',
                icon: Icons.space_dashboard_outlined,
                selectedIcon: Icons.space_dashboard_rounded,
                selected: selectedIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
            ),
            Expanded(child: _AddExpenseDestination(onTap: onAddExpense)),
            Expanded(
              child: _NavigationDestination(
                label: 'Settings',
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings_rounded,
                selected: selectedIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationDestination extends StatelessWidget {
  const _NavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? expenseInk : expenseMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddExpenseDestination extends StatelessWidget {
  const _AddExpenseDestination({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: 'Add expense',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: onTap == null
                      ? expenseMuted.withValues(alpha: .5)
                      : expenseInk,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Add expense',
                style: TextStyle(
                  color: expenseInk,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
