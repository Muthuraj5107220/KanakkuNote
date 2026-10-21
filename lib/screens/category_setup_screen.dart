import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/expense_storage.dart';
import '../widgets/expense/expense_widget_styles.dart';

class CategorySetupScreen extends StatefulWidget {
  const CategorySetupScreen({
    super.key,
    required this.storage,
    required this.initialCategories,
    required this.onContinue,
  });

  final ExpenseStorage storage;
  final List<ExpenseCategory> initialCategories;
  final Future<void> Function(List<ExpenseCategory> categories) onContinue;

  @override
  State<CategorySetupScreen> createState() => _CategorySetupScreenState();
}

class _CategorySetupScreenState extends State<CategorySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final List<ExpenseCategory> _categories = [...widget.initialCategories];
  bool _saving = false;
  bool _continuing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter a category name';
    if (_categories.any(
      (category) => category.name.toLowerCase() == name.toLowerCase(),
    )) {
      return 'This category already exists';
    }
    return null;
  }

  Future<void> _addCategory() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final category = await widget.storage.addCategory(
        _nameController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _categories.add(category);
        _nameController.clear();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add category: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _continue() async {
    if (_saving || _continuing) return;
    _continuing = true;
    try {
      await widget.onContinue(_categories);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not continue: $error')));
      }
    } finally {
      _continuing = false;
    }
  }

  Widget _categoryCard(ExpenseCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: expenseLine),
      ),
      child: Row(
        children: [
          Icon(category.icon, color: category.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(
                color: expenseInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.check_circle, color: expenseInk, size: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.category_outlined,
                        color: expenseInk,
                        size: 36,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create your categories',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: expenseInk,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Categories help organize your spending. We included '
                        'some to get you started; add any that fit your needs.',
                        style: TextStyle(
                          color: expenseMuted,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _addCategory(),
                                decoration: const InputDecoration(
                                  labelText: 'Category name',
                                  hintText: 'e.g. Pets',
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                validator: _validateName,
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filled(
                              onPressed: _saving ? null : _addCategory,
                              tooltip: 'Add category',
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (var index = 0; index < _categories.length; index++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: index == _categories.length - 1 ? 0 : 8,
                          ),
                          child: _categoryCard(_categories[index]),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: _saving ? null : _continue,
                          child: const Text('Continue'),
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
