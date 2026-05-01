import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class WasteLogScreen extends StatefulWidget {
  const WasteLogScreen({super.key});

  @override
  State<WasteLogScreen> createState() => _WasteLogScreenState();
}

class _WasteLogScreenState extends State<WasteLogScreen> {
  final _db = DatabaseHelper();
  List<WasteLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getWasteLogs();
    setState(() => _logs = list);
  }

  Future<void> _showForm([WasteLog? existing]) async {
    final products = await _db.getProducts();
    final reasons = await _db.getSettingValues('waste_reason', fallback: kWasteReasons);
    if (!mounted) return;
    final result = await showDialog<WasteLog>(
      context: context,
      builder: (ctx) => _WasteLogForm(existing: existing, products: products, reasons: reasons),
    );
    if (result != null) {
      if (existing != null) {
        await _db.updateWasteLog(result);
        await _db.applyWasteToInventory(previous: existing, current: result);
      } else {
        await _db.insertWasteLog(result);
        await _db.applyWasteToInventory(current: result);
      }
      _load();
    }
  }

  Color _reasonColor(String reason) {
    switch (reason) {
      case 'Expired':
        return Colors.red;
      case 'Burnt/Spoiled':
        return Colors.orange;
      case 'Overproduction':
        return Colors.amber;
      case 'Customer Return':
        return Colors.blue;
      case 'Dropped/Damaged':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Waste & Loss Log',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Log Waste'),
            ),
          ],
        ),
        Expanded(
          child: _logs.isEmpty
              ? const EmptyState(icon: Icons.delete_sweep_outlined, message: 'No waste logged yet. Good job!')
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _logs.length,
                  itemBuilder: (ctx, i) {
                    final w = _logs[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SurfaceCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _reasonColor(w.reason).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.warning_amber, color: _reasonColor(w.reason)),
                          ),
                          title: Text(w.itemName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${w.reason} • Qty: ${w.quantity} • ${DateFormat.yMMMd().format(w.date)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '-${formatCurrency(w.estimatedLoss ?? 0)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: BakeryTheme.error),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showForm(w),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () async {
                                  if (await confirmDelete(context, w.itemName)) {
                                    await _db.deleteWasteLog(w.id!);
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

class _WasteLogForm extends StatefulWidget {
  final WasteLog? existing;
  final List<Product> products;
  final List<String> reasons;
  const _WasteLogForm({this.existing, required this.products, required this.reasons});

  @override
  State<_WasteLogForm> createState() => _WasteLogFormState();
}

class _WasteLogFormState extends State<_WasteLogForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _item;
  late final TextEditingController _qty;
  late final TextEditingController _loss;
  late final TextEditingController _notes;
  late String _reason;
  late DateTime _date;
  int? _productId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _item = TextEditingController(text: e?.itemName ?? '');
    _qty = TextEditingController(text: e != null ? e.quantity.toString() : '');
    _loss = TextEditingController(text: e != null ? (e.estimatedLoss?.toStringAsFixed(2) ?? '') : '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _reason = e?.reason ?? widget.reasons.first;
    if (!widget.reasons.contains(_reason)) _reason = widget.reasons.first;
    _date = e?.date ?? DateTime.now();
    // productId not in model; track locally for form UI
    _productId = null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Waste Log' : 'Log Waste'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int?>(
                initialValue: _productId,
                decoration: const InputDecoration(labelText: 'Product (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Custom item')),
                  ...widget.products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                ],
                onChanged: (v) {
                  setState(() {
                    _productId = v;
                    if (v != null) {
                      final prod = widget.products.firstWhere((p) => p.id == v);
                      _item.text = prod.name;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _item,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: widget.reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => _reason = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qty,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final qty = double.tryParse(v);
                        if (qty == null) return 'Enter a valid number';
                        if (qty <= 0) return 'Quantity must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _loss,
                      decoration: const InputDecoration(labelText: 'Estimated Loss (optional)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null; // Optional
                        final loss = double.tryParse(v);
                        if (loss == null) return 'Enter a valid number';
                        if (loss < 0) return 'Cannot be negative';
                        return null;
                      },
                    ),
                  ),
                ],
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
                WasteLog(
                  id: widget.existing?.id,
                  itemName: _item.text.trim(),
                  quantity: double.parse(_qty.text),
                  unit: 'pcs',
                  reason: _reason,
                  estimatedLoss: double.parse(_loss.text),
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
