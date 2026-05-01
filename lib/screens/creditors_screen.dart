import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class CreditorsScreen extends StatefulWidget {
  const CreditorsScreen({super.key});

  @override
  State<CreditorsScreen> createState() => _CreditorsScreenState();
}

class _CreditorsScreenState extends State<CreditorsScreen> {
  final _db = DatabaseHelper();
  List<Creditor> _creditors = [];
  double _totalOwed = 0;
  String _filter = 'outstanding'; // 'outstanding' or 'all'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _db.getCreditors();
    final totalOwed = await _db.getTotalCreditorsBalance();
    setState(() {
      _creditors = all;
      _totalOwed = totalOwed;
    });
  }

  List<Creditor> get _displayed {
    if (_filter == 'outstanding') {
      return _creditors.where((c) => c.status != 'paid').toList();
    }
    return _creditors;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return BakeryTheme.success;
      case 'partial':
        return BakeryTheme.warning;
      default:
        return BakeryTheme.error;
    }
  }

  Future<void> _showForm([Creditor? existing]) async {
    final suppliers = await _db.getSuppliers();
    if (!mounted) return;
    final result = await showDialog<Creditor>(
      context: context,
      builder: (ctx) => _CreditorForm(existing: existing, suppliers: suppliers),
    );
    if (result != null) {
      if (existing != null) {
        await _db.updateCreditor(result);
      } else {
        await _db.insertCreditor(result);
      }
      _load();
    }
  }

  Future<void> _recordPayment(Creditor cred) async {
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Owed: ${formatCurrency(cred.amountOwed)} | Paid: ${formatCurrency(cred.amountPaid)}'),
            Text('Remaining: ${formatCurrency(cred.balanceDue)}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Payment Amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
    if (result != null) {
      final newPaid = cred.amountPaid + result;
      final newStatus = newPaid >= cred.amountOwed
          ? 'paid'
          : newPaid > 0
          ? 'partial'
          : 'unpaid';
      await _db.updateCreditor(cred.copyWith(amountPaid: newPaid, status: newStatus));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Creditors',
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _totalOwed > 0
                    ? BakeryTheme.error.withValues(alpha: 0.3)
                    : BakeryTheme.success.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _totalOwed > 0
                      ? BakeryTheme.error.withValues(alpha: 0.5)
                      : BakeryTheme.success.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'You owe: ${formatCurrency(_totalOwed)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _totalOwed > 0 ? Colors.red.shade700 : Colors.green.shade800,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Creditor'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppFilterChip(
                    label: 'Outstanding',
                    selected: _filter == 'outstanding',
                    onSelected: (_) => setState(() => _filter = 'outstanding'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppFilterChip(
                    label: 'All',
                    selected: _filter == 'all',
                    onSelected: (_) => setState(() => _filter = 'all'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _displayed.isEmpty
              ? EmptyState(
                  icon: Icons.account_balance_outlined,
                  message: _filter == 'outstanding'
                      ? 'No outstanding creditors. You\'re all clear!'
                      : 'No creditor records yet.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _displayed.length,
                  itemBuilder: (ctx, i) {
                    final c = _displayed[i];
                    final isOverdue = c.dueDate.isBefore(DateTime.now()) && c.status != 'paid';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SurfaceCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              c.description,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(width: 10),
                                            _chip(
                                              isOverdue ? 'overdue' : c.status,
                                              _statusColor(isOverdue ? 'unpaid' : c.status),
                                            ),
                                          ],
                                        ),
                                        if (c.supplierName != null && c.supplierName!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Supplier: ${c.supplierName}',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        formatCurrency(c.amountOwed),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      if (c.balanceDue > 0 && c.balanceDue != c.amountOwed)
                                        Text(
                                          'Due: ${formatCurrency(c.balanceDue)}',
                                          style: TextStyle(color: BakeryTheme.error, fontSize: 13),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Due: ${DateFormat.yMMMd().format(c.dueDate)}',
                                style: TextStyle(
                                  color: isOverdue ? Colors.red.shade700 : null,
                                  fontWeight: isOverdue ? FontWeight.bold : null,
                                ),
                              ),
                              if (c.notes != null && c.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Notes: ${c.notes}', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                              const Divider(height: 16),
                              Row(
                                children: [
                                  if (c.status != 'paid')
                                    OutlinedButton.icon(
                                      onPressed: () => _recordPayment(c),
                                      icon: const Icon(Icons.payment, size: 16),
                                      label: const Text('Record Payment', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        side: BorderSide(color: BakeryTheme.primary.withValues(alpha: 0.5)),
                                      ),
                                    ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () => _showForm(c),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    onPressed: () async {
                                      if (await confirmDelete(context, c.description)) {
                                        await _db.deleteCreditor(c.id!);
                                        _load();
                                      }
                                    },
                                  ),
                                ],
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

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ── Creditor Form ──
class _CreditorForm extends StatefulWidget {
  final Creditor? existing;
  final List<Supplier> suppliers;
  const _CreditorForm({this.existing, required this.suppliers});

  @override
  State<_CreditorForm> createState() => _CreditorFormState();
}

class _CreditorFormState extends State<_CreditorForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _desc;
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  int? _supplierId;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _desc = TextEditingController(text: e?.description ?? '');
    _amount = TextEditingController(text: e != null ? e.amountOwed.toStringAsFixed(2) : '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _supplierId = e?.supplierId;
    _dueDate = e?.dueDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Creditor' : 'Add Creditor'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'e.g. Flour delivery invoice'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _supplierId,
                decoration: const InputDecoration(labelText: 'Supplier'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No supplier')),
                  ...widget.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                ],
                onChanged: (v) => setState(() => _supplierId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                decoration: const InputDecoration(labelText: 'Amount Owed'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || double.tryParse(v) == null ? 'Enter a valid amount' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (d != null) setState(() => _dueDate = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Due Date'),
                  child: Text(_dueDate != null ? DateFormat.yMMMd().format(_dueDate!) : 'Select due date'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _dueDate != null) {
              Navigator.pop(
                context,
                Creditor(
                  id: widget.existing?.id,
                  supplierId: _supplierId,
                  description: _desc.text.trim(),
                  amountOwed: double.parse(_amount.text),
                  amountPaid: widget.existing?.amountPaid ?? 0,
                  dueDate: _dueDate!,
                  status: widget.existing?.status ?? 'unpaid',
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
