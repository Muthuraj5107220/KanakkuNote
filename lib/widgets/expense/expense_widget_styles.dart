import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const expenseInk = Color(0xFF173D35);
const expenseMuted = Color(0xFF7C8982);
const expenseLine = Color(0xFFE8ECE6);
const expenseMint = Color(0xFFE7F1E9);

@immutable
class ExpensePalette extends ThemeExtension<ExpensePalette> {
  const ExpensePalette({
    required this.ink,
    required this.muted,
    required this.line,
    required this.mint,
    required this.surface,
    required this.accent,
  });

  final Color ink;
  final Color muted;
  final Color line;
  final Color mint;
  final Color surface;
  final Color accent;

  static const light = ExpensePalette(
    ink: expenseInk,
    muted: expenseMuted,
    line: expenseLine,
    mint: expenseMint,
    surface: Colors.white,
    accent: expenseInk,
  );

  static const dark = ExpensePalette(
    ink: Color(0xFFB9D5BF),
    muted: Color(0xFFADB9B0),
    line: Color(0xFF39443D),
    mint: Color(0xFF293A30),
    surface: Color(0xFF202923),
    accent: Color(0xFF355E45),
  );

  @override
  ExpensePalette copyWith({
    Color? ink,
    Color? muted,
    Color? line,
    Color? mint,
    Color? surface,
    Color? accent,
  }) => ExpensePalette(
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    line: line ?? this.line,
    mint: mint ?? this.mint,
    surface: surface ?? this.surface,
    accent: accent ?? this.accent,
  );

  @override
  ExpensePalette lerp(ThemeExtension<ExpensePalette>? other, double t) {
    if (other is! ExpensePalette) return this;
    return ExpensePalette(
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

extension ExpensePaletteContext on BuildContext {
  ExpensePalette get expensePalette {
    final theme = Theme.of(this);
    return theme.extension<ExpensePalette>() ??
        (theme.brightness == Brightness.dark
            ? ExpensePalette.dark
            : ExpensePalette.light);
  }
}

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

String formatExpenseAmount(int amountPaise) => _money.format(amountPaise / 100);

String formatCompactExpenseAmount(int amountPaise) =>
    _compactMoney.format(amountPaise / 100);
