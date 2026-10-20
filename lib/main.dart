import 'package:flutter/material.dart';

import 'screens/expense_home_screen.dart';

void main() {
  runApp(const KanakkuNoteApp());
}

class KanakkuNoteApp extends StatelessWidget {
  const KanakkuNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF173D35);
    const canvas = Color(0xFFF7F8F4);

    return MaterialApp(
      title: 'Kanakku Note',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ink,
          surface: canvas,
          primary: ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: ink,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF4F6F2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      home: const ExpenseHomeScreen(),
    );
  }
}
