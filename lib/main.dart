import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/expense.dart';
import 'services/expense_storage.dart';
import 'screens/account_setup_screen.dart';
import 'screens/expense_home_screen.dart';
import 'screens/welcome_screen.dart';

const _welcomeCompletedKey = 'kanakku_note.welcome_completed.v1';

enum _AppPage { welcome, accountSetup, expenses }

class _AppStart {
  const _AppStart(this.page, [this.accounts = const []]);

  final _AppPage page;
  final List<ExpenseAccount> accounts;
}

void main() {
  runApp(const KanakkuNoteApp());
}

class KanakkuNoteApp extends StatefulWidget {
  const KanakkuNoteApp({super.key, this.storage});

  final ExpenseStorage? storage;

  @override
  State<KanakkuNoteApp> createState() => _KanakkuNoteAppState();
}

class _KanakkuNoteAppState extends State<KanakkuNoteApp> {
  late final ExpenseStorage _storage = widget.storage ?? ExpenseStorage();
  late final Future<_AppStart> _appStart = _loadAppStart();
  _AppPage? _pageOverride;
  List<ExpenseAccount> _accountsOverride = const [];

  Future<_AppStart> _loadAppStart() async {
    await _storage.initialize();
    final preferences = await SharedPreferences.getInstance();
    final welcomeCompleted = preferences.getBool(_welcomeCompletedKey) ?? false;
    if (!welcomeCompleted) return const _AppStart(_AppPage.welcome);

    final accounts = await _storage.loadAccounts();
    return _AppStart(
      accounts.isEmpty ? _AppPage.accountSetup : _AppPage.expenses,
      accounts,
    );
  }

  Future<void> _completeWelcome(BuildContext context) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setBool(_welcomeCompletedKey, true);
      if (!saved) {
        throw StateError('The welcome status could not be saved.');
      }
      if (mounted) {
        setState(() => _pageOverride = _AppPage.accountSetup);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save welcome status: $error')),
        );
      }
    }
  }

  void _completeAccountSetup(List<ExpenseAccount> accounts) {
    if (accounts.isEmpty) return;
    setState(() {
      _accountsOverride = accounts;
      _pageOverride = _AppPage.expenses;
    });
  }

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
      home: FutureBuilder<_AppStart>(
        future: _appStart,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Could not start app: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final start = snapshot.data!;
          final page = _pageOverride ?? start.page;
          final accounts = _pageOverride == null
              ? start.accounts
              : _accountsOverride;
          return switch (page) {
            _AppPage.welcome => WelcomeScreen(onContinue: _completeWelcome),
            _AppPage.accountSetup => AccountSetupScreen(
              storage: _storage,
              initialAccounts: accounts,
              onContinue: _completeAccountSetup,
            ),
            _AppPage.expenses => ExpenseHomeScreen(
              storage: _storage,
              accounts: accounts,
            ),
          };
        },
      ),
    );
  }
}
