import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/expense.dart';
import 'services/expense_storage.dart';
import 'screens/account_setup_screen.dart';
import 'screens/category_setup_screen.dart';
import 'screens/expense_home_screen.dart';
import 'screens/welcome_screen.dart';
import 'widgets/expense/expense_widget_styles.dart';

const _welcomeCompletedKey = 'kanakku_note.welcome_completed.v1';
const _themeModeKey = 'kanakku_note.theme_mode.v1';

enum _AppPage { welcome, accountSetup, categorySetup, expenses }

class _AppStart {
  const _AppStart(
    this.page, {
    this.accounts = const [],
    this.themeMode = ThemeMode.system,
  });

  final _AppPage page;
  final List<ExpenseAccount> accounts;
  final ThemeMode themeMode;
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
  ThemeMode? _themeModeOverride;
  List<ExpenseAccount> _accountsOverride = const [];

  Future<_AppStart> _loadAppStart() async {
    await _storage.initialize();
    final preferences = await SharedPreferences.getInstance();
    final themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == preferences.getString(_themeModeKey),
      orElse: () => ThemeMode.system,
    );
    final welcomeCompleted = preferences.getBool(_welcomeCompletedKey) ?? false;
    if (!welcomeCompleted) {
      return _AppStart(_AppPage.welcome, themeMode: themeMode);
    }

    final accounts = await _storage.loadAccounts();
    return _AppStart(
      accounts.isEmpty ? _AppPage.accountSetup : _AppPage.expenses,
      accounts: accounts,
      themeMode: themeMode,
    );
  }

  Future<void> _changeThemeMode(BuildContext context, ThemeMode mode) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(_themeModeKey, mode.name);
      if (!saved) throw StateError('The theme preference could not be saved.');
      if (mounted) setState(() => _themeModeOverride = mode);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save theme preference: $error')),
        );
      }
    }
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

  Future<void> _completeAccountSetup(List<ExpenseAccount> accounts) async {
    if (accounts.isEmpty) return;
    final savedAccounts = await _storage.loadAccounts();
    if (savedAccounts.isEmpty) return;
    final categories = await _storage.loadCategories();
    if (!mounted) return;
    setState(() {
      _accountsOverride = savedAccounts;
      _categoriesOverride = categories;
      _pageOverride = _AppPage.categorySetup;
    });
  }

  List<ExpenseCategory> _categoriesOverride = const [];

  Future<void> _completeCategorySetup(List<ExpenseCategory> categories) async {
    if (categories.isEmpty) return;
    final savedCategories = await _storage.loadCategories();
    if (savedCategories.isEmpty || !mounted) return;
    setState(() {
      _categoriesOverride = savedCategories;
      _pageOverride = _AppPage.expenses;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppStart>(
      future: _appStart,
      builder: (context, snapshot) {
        final start = snapshot.data;
        final lightTheme = ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7F8F4),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF173D35),
            surface: const Color(0xFFF7F8F4),
            primary: const Color(0xFF173D35),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF7F8F4),
            foregroundColor: Color(0xFF173D35),
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
          extensions: [ExpensePalette.light],
        );
        final darkTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF151B17),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8DB99A),
            brightness: Brightness.dark,
            surface: const Color(0xFF151B17),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF202923),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          extensions: [ExpensePalette.dark],
        );
        return MaterialApp(
          title: 'Kanakku Note',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: _themeModeOverride ?? start?.themeMode ?? ThemeMode.system,
          home: Builder(
            builder: (context) {
              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text('Could not start app: ${snapshot.error}'),
                  ),
                );
              }
              if (start == null) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
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
                _AppPage.categorySetup => CategorySetupScreen(
                  storage: _storage,
                  initialCategories: _categoriesOverride,
                  onContinue: _completeCategorySetup,
                ),
                _AppPage.expenses => ExpenseHomeScreen(
                  storage: _storage,
                  accounts: accounts,
                  onThemeModeChanged: _changeThemeMode,
                  themeMode: _themeModeOverride ?? start.themeMode,
                ),
              };
            },
          ),
        );
      },
    );
  }
}
