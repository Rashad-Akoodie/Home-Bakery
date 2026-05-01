import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../services/grocery_forecast_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class GroceryRunsScreen extends StatefulWidget {
  const GroceryRunsScreen({super.key});

  @override
  State<GroceryRunsScreen> createState() => _GroceryRunsScreenState();
}

class _GroceryRunsScreenState extends State<GroceryRunsScreen> {
  final _db = DatabaseHelper();
  final _forecast = GroceryForecastService();
  List<GroceryRun> _runs = [];
  List<GroceryPurchaseSuggestion> _suggestions = [];
  List<String> _unitOptions = kUnits;
  List<InventoryItem> _inventoryItems = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final runs = await _db.getGroceryRuns();
    final suggestions = await _forecast.buildSuggestions();
    final units = await _db.getSettingValues('unit', fallback: kUnits);
    final inventoryItems = await _db.getInventoryItems();
    setState(() {
      _runs = runs;
      _suggestions = suggestions;
      _unitOptions = units;
      _inventoryItems = inventoryItems;
    });
  }

  Future<void> _showForm([GroceryRun? existing]) async {
    final suppliers = await _db.getSuppliers();
    if (!mounted) return;
    final result = await showDialog<_GroceryRunFormResult>(
      context: context,
      builder: (ctx) => _GroceryRunForm(
        existing: existing,
        suppliers: suppliers,
        db: _db,
        unitOptions: _unitOptions,
        inventoryItems: _inventoryItems,
      ),
    );
    if (result != null) {
      await _db.saveGroceryRunWithItems(run: result.run, items: result.items, complete: result.markCompleted);
      _load();
    }
  }

  Future<void> _completeRun(GroceryRun run) async {
    await _db.completeGroceryRun(run.id!);
    _load();
  }

  Future<void> _viewItems(GroceryRun run) async {
    final items = await _db.getGroceryRunItems(run.id!);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Grocery Run - ${DateFormat.yMMMd().format(run.date)}'),
        content: SizedBox(
          width: 400,
          child: items.isEmpty
              ? const Text('No items recorded')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...items.map(
                      (item) => ListTile(
                        dense: true,
                        title: Text(item.itemName),
                        subtitle: Text('${item.quantity} ${item.unit} @ ${formatCurrency(item.unitPrice)}'),
                        trailing: Text(
                          formatCurrency(item.lineTotal),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const Divider(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total: ${formatCurrency(run.totalCost)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Grocery Runs',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Run'),
            ),
          ],
        ),
        if (_suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SurfaceCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_graph, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Suggested Purchases (Forecast + Low Stock)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._suggestions
                        .take(8)
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${s.itemName} • Buy ${s.suggestedQuantity.toStringAsFixed(1)} ${s.unit}',
                                  ),
                                ),
                                Text(
                                  'Stock ${s.currentStock.toStringAsFixed(1)}',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: _runs.isEmpty
              ? const EmptyState(icon: Icons.shopping_cart_outlined, message: 'No grocery runs recorded yet.')
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _runs.length,
                  itemBuilder: (ctx, i) {
                    final r = _runs[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SurfaceCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: BakeryTheme.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.shopping_bag, color: BakeryTheme.primaryDark),
                          ),
                          title: Text(
                            r.storeName != null && r.storeName!.isNotEmpty ? r.storeName! : 'Grocery Run',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(DateFormat.yMMMd().format(r.date)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (r.status == 'draft')
                                OutlinedButton(onPressed: () => _completeRun(r), child: const Text('Complete')),
                              if (r.status == 'completed')
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: BakeryTheme.success.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Completed',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              Text(
                                formatCurrency(r.totalCost),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.visibility, size: 20),
                                tooltip: 'View items',
                                onPressed: () => _viewItems(r),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showForm(r),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () async {
                                  if (await confirmDelete(
                                    context,
                                    'Grocery run on ${DateFormat.yMMMd().format(r.date)}',
                                  )) {
                                    await _db.deleteGroceryRun(r.id!);
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

class _GroceryRunFormResult {
  final GroceryRun run;
  final List<GroceryRunItem> items;
  final bool markCompleted;
  _GroceryRunFormResult(this.run, this.items, this.markCompleted);
}

class _GroceryRunForm extends StatefulWidget {
  final GroceryRun? existing;
  final List<Supplier> suppliers;
  final DatabaseHelper db;
  final List<String> unitOptions;
  final List<InventoryItem> inventoryItems;
  const _GroceryRunForm({
    this.existing,
    required this.suppliers,
    required this.db,
    required this.unitOptions,
    required this.inventoryItems,
  });

  @override
  State<_GroceryRunForm> createState() => _GroceryRunFormState();
}

class _GroceryRunFormState extends State<_GroceryRunForm> {
  late DateTime _date;
  late final TextEditingController _store;
  late final TextEditingController _notes;
  int? _supplierId;
  final List<_GroceryLine> _lines = [];
  bool _markCompleted = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.date ?? DateTime.now();
    _store = TextEditingController(text: e?.storeName ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _supplierId = e?.supplierId;
    _markCompleted = e?.status == 'completed';
    if (e != null) _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await widget.db.getGroceryRunItems(widget.existing!.id!);
    setState(() {
      _lines.addAll(
        items.map(
          (i) => _GroceryLine(
            inventoryItemId: i.inventoryItemId,
            name: i.itemName,
            qty: i.quantity.toString(),
            unit: i.unit,
            price: i.unitPrice.toStringAsFixed(2),
          ),
        ),
      );
    });
  }

  double get _total => _lines.fold(0, (s, l) {
    final q = double.tryParse(l.qty) ?? 0;
    final p = double.tryParse(l.price) ?? 0;
    return s + q * p;
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Grocery Run' : 'New Grocery Run'),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _store,
                      decoration: const InputDecoration(labelText: 'Store Name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _supplierId,
                decoration: const InputDecoration(labelText: 'Supplier (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...widget.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                ],
                onChanged: (v) => setState(() => _supplierId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 16),
              const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._lines.asMap().entries.map((entry) {
                final idx = entry.key;
                final l = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              isExpanded: true,
                              initialValue: widget.inventoryItems.any((it) => it.id == l.inventoryItemId)
                                  ? l.inventoryItemId
                                  : null,
                              decoration: const InputDecoration(labelText: 'Inventory Item'),
                              items: widget.inventoryItems
                                  .map(
                                    (it) => DropdownMenuItem(
                                      value: it.id,
                                      child: Text(it.name, overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                final item = widget.inventoryItems.firstWhere((it) => it.id == v);
                                setState(() {
                                  l.inventoryItemId = item.id;
                                  l.name = item.name;
                                  l.unit = item.unit;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: l.name,
                              decoration: const InputDecoration(labelText: 'Or New Item'),
                              onChanged: (v) {
                                l.name = v;
                                l.inventoryItemId = null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: l.qty,
                              decoration: const InputDecoration(labelText: 'Qty'),
                              onChanged: (v) => setState(() => l.qty = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: widget.unitOptions.contains(l.unit) ? l.unit : widget.unitOptions.first,
                              decoration: const InputDecoration(labelText: 'Unit'),
                              items: widget.unitOptions
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u, overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => l.unit = v!,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: l.price,
                              decoration: const InputDecoration(labelText: 'Price'),
                              onChanged: (v) => setState(() => l.price = v),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _lines.removeAt(idx)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _lines.add(_GroceryLine(unit: widget.unitOptions.first))),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _markCompleted,
                title: const Text('Mark run as completed'),
                subtitle: const Text('Completing a run adds purchased quantities into inventory.'),
                onChanged: (v) => setState(() => _markCompleted = v ?? false),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: ${formatCurrency(_total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            // Validate at least one item exists
            final validItems = _lines.where((l) => l.name.trim().isNotEmpty).toList();
            if (validItems.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add at least one item to the grocery run'), backgroundColor: Colors.red),
              );
              return;
            }

            // Validate each item has quantity and price
            for (final line in validItems) {
              if ((double.tryParse(line.qty) ?? 0) <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All items must have a quantity > 0'), backgroundColor: Colors.red),
                );
                return;
              }
              if ((double.tryParse(line.price) ?? 0) < 0) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Price cannot be negative'), backgroundColor: Colors.red));
                return;
              }
            }

            final run = GroceryRun(
              id: widget.existing?.id,
              date: _date,
              storeName: _store.text.trim(),
              supplierId: _supplierId,
              totalCost: _total,
              notes: _notes.text.trim(),
            );
            final items = _lines
                .where((l) => l.name.isNotEmpty)
                .map(
                  (l) => GroceryRunItem(
                    groceryRunId: widget.existing?.id ?? 0,
                    inventoryItemId: l.inventoryItemId,
                    itemName: l.name,
                    quantity: double.tryParse(l.qty) ?? 0,
                    unit: l.unit,
                    unitPrice: double.tryParse(l.price) ?? 0,
                  ),
                )
                .toList();
            Navigator.pop(context, _GroceryRunFormResult(run, items, _markCompleted));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _GroceryLine {
  int? inventoryItemId;
  String name;
  String qty;
  String unit;
  String price;
  _GroceryLine({this.inventoryItemId, this.name = '', this.qty = '', this.unit = 'kg', this.price = ''});
}
