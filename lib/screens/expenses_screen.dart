import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _db = DatabaseHelper();
  List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getExpenses();
    setState(() => _expenses = list);
  }

  Future<void> _showForm([Expense? existing]) async {
    final categories = await _db.getSettingValues('expense_category', fallback: kExpenseCategories);
    if (!mounted) return;
    final result = await showDialog<Expense>(
      context: context,
      builder: (ctx) => _ExpenseForm(existing: existing, categories: categories),
    );
    if (result != null) {
      if (existing != null) {
        await _db.updateExpense(result);
      } else {
        await _db.insertExpense(result);
      }
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Expenses',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Expense'),
            ),
          ],
        ),
        Expanded(
          child: _expenses.isEmpty
              ? const EmptyState(icon: Icons.account_balance_wallet_outlined, message: 'No expenses recorded yet.')
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _expenses.length,
                  itemBuilder: (ctx, i) {
                    final e = _expenses[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SurfaceCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: BakeryTheme.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.receipt, color: BakeryTheme.primaryDark),
                          ),
                          title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${e.category} • ${DateFormat.yMMMd().format(e.date)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatCurrency(e.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showForm(e),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () async {
                                  if (await confirmDelete(context, e.description)) {
                                    await _db.deleteExpense(e.id!);
                                    _load();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  final Expense? existing;
  final List<String> categories;
  const _ExpenseForm({this.existing, required this.categories});

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _desc;
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  late String _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _desc = TextEditingController(text: e?.description ?? '');
    _amount = TextEditingController(text: e != null ? e.amount.toStringAsFixed(2) : '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _category = e?.category ?? widget.categories.first;
    if (!widget.categories.contains(_category)) _category = widget.categories.first;
    _date = e?.date ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Expense' : 'Add Expense'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || double.tryParse(v) == null ? 'Enter amount' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (d != null) setState(() => _date = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text(DateFormat.yMMMd().format(_date)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                Expense(
                  id: widget.existing?.id,
                  category: _category,
                  description: _desc.text.trim(),
                  amount: double.parse(_amount.text),
                  date: _date,
                  notes: _notes.text.trim(),
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
