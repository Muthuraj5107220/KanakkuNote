import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const expenseInk = Color(0xFF173D35);
const expenseMuted = Color(0xFF7C8982);
const expenseLine = Color(0xFFE8ECE6);
const expenseMint = Color(0xFFE7F1E9);

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
