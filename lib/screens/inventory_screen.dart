import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _db = DatabaseHelper();
  List<InventoryItem> _items = [];
  List<String> _categoryOptions = kInventoryCategories;
  List<String> _unitOptions = kUnits;
  String _filterCategory = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _db.getInventoryItems();
    final categories = await _db.getSettingValues('inventory_category', fallback: kInventoryCategories);
    final units = await _db.getSettingValues('unit', fallback: kUnits);
    setState(() {
      _items = items;
      _categoryOptions = categories;
      _unitOptions = units;
      if (_filterCategory != 'All' && !_categoryOptions.contains(_filterCategory)) {
        _filterCategory = 'All';
      }
    });
  }

  List<InventoryItem> get _filteredItems {
    if (_filterCategory == 'All') return _items;
    return _items.where((i) => i.category == _filterCategory).toList();
  }

  Future<void> _showForm([InventoryItem? existing]) async {
    final result = await showDialog<InventoryItem>(
      context: context,
      builder: (ctx) => _InventoryForm(existing: existing, categories: _categoryOptions, units: _unitOptions),
    );
    if (result != null) {
      if (existing != null) {
        await _db.updateInventoryItem(result);
      } else {
        await _db.insertInventoryItem(result);
      }
      _load();
    }
  }

  Future<void> _adjustQuantity(InventoryItem item) async {
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adjust: ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: ${item.quantity} ${item.unit}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Amount (+/-)', hintText: 'e.g. 5 or -2.5'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null) Navigator.pop(ctx, v);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (result != null) {
      final newQty = (item.quantity + result).clamp(0, double.infinity);
      await _db.updateInventoryItem(item.copyWith(quantity: newQty.toDouble(), lastUpdated: DateTime.now()));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ..._categoryOptions];
    return Column(
      children: [
        ScreenHeader(
          title: 'Inventory',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Item'),
            ),
          ],
        ),
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categories.map((c) {
                final selected = _filterCategory == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppFilterChip(
                    label: c,
                    selected: selected,
                    onSelected: (_) => setState(() => _filterCategory = c),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Table
        Expanded(
          child: _filteredItems.isEmpty
              ? const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  message: 'No inventory items yet.\nAdd your first ingredient!',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(BakeryTheme.primary.withValues(alpha: 0.08)),
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Qty'), numeric: true),
                        DataColumn(label: Text('Unit')),
                        DataColumn(label: Text('Reorder Level'), numeric: true),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _filteredItems.map((item) {
                        // Calculate status based on reorder level
                        String status = 'OK';
                        Color statusColor = Colors.green.shade800;
                        Color bgColor = BakeryTheme.success.withValues(alpha: 0.3);
                        String tooltip = 'Quantity is above reorder level';

                        if (item.quantity <= 0) {
                          // Out of stock
                          status = 'Out';
                          statusColor = Colors.red.shade800;
                          bgColor = BakeryTheme.error.withValues(alpha: 0.3);
                          tooltip = 'Item is out of stock';
                        } else if (item.reorderLevel > 0) {
                          // Only apply tiered warnings if reorder level is explicitly set
                          if (item.quantity <= item.reorderLevel * 0.25) {
                            // Critical - below 25% of reorder level
                            status = 'Critical';
                            statusColor = Colors.red.shade800;
                            bgColor = BakeryTheme.error.withValues(alpha: 0.3);
                            tooltip = 'Critical stock level - below 25% of reorder level';
                          } else if (item.quantity <= item.reorderLevel * 0.5) {
                            // Very Low - below 50% of reorder level
                            status = 'Very Low';
                            statusColor = Colors.orange.shade800;
                            bgColor = const Color(0xFFFFE5CC).withValues(alpha: 0.8);
                            tooltip = 'Very low stock - below 50% of reorder level';
                          } else if (item.quantity <= item.reorderLevel) {
                            // Low - at or below reorder level
                            status = 'Low';
                            statusColor = Colors.orange.shade800;
                            bgColor = BakeryTheme.warning.withValues(alpha: 0.3);
                            tooltip = 'Low stock - at or below reorder level';
                          }
                        }

                        return DataRow(
                          cells: [
                            DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text(item.category ?? '')),
                            DataCell(Text(item.quantity.toStringAsFixed(1))),
                            DataCell(Text(item.unit)),
                            DataCell(Text(item.reorderLevel.toStringAsFixed(1))),
                            DataCell(
                              Tooltip(
                                message: tooltip,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    status,
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 20),
                                    tooltip: 'Adjust quantity',
                                    onPressed: () => _adjustQuantity(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    tooltip: 'Edit',
                                    onPressed: () => _showForm(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    tooltip: 'Delete',
                                    onPressed: () async {
                                      final usageCount = await _db.getInventoryUsageCount(item.id!);
                                      if (usageCount > 0) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Cannot delete ${item.name}. It is linked in recipes/grocery records.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      if (await confirmDelete(context, item.name)) {
                                        await _db.deleteInventoryItem(item.id!);
                                        _load();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Inventory Add/Edit Form ──
class _InventoryForm extends StatefulWidget {
  final InventoryItem? existing;
  final List<String> categories;
  final List<String> units;
  const _InventoryForm({this.existing, required this.categories, required this.units});

  @override
  State<_InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<_InventoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _qty;
  late final TextEditingController _reorder;
  late String _unit;
  late String _category;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _qty = TextEditingController(text: e != null ? e.quantity.toStringAsFixed(1) : '');
    _reorder = TextEditingController(text: (e?.reorderLevel ?? 0).toStringAsFixed(1));
    _unit = e?.unit ?? widget.units.first;
    _category = e?.category ?? widget.categories.first;
    if (!widget.units.contains(_unit)) _unit = widget.units.first;
    if (!widget.categories.contains(_category)) _category = widget.categories.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Item' : 'Add Item'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _qty,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Enter a number' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: widget.units
                          .map(
                            (u) => DropdownMenuItem(
                              value: u,
                              child: Text(u, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reorder,
                decoration: const InputDecoration(
                  labelText: 'Reorder Level',
                  helperText: 'Defaults to 0 if not changed.',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || double.tryParse(v) == null ? 'Enter a number' : null,
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
                InventoryItem(
                  id: widget.existing?.id,
                  name: _name.text.trim(),
                  unit: _unit,
                  quantity: double.parse(_qty.text),
                  reorderLevel: double.tryParse(_reorder.text) ?? 0,
                  category: _category,
                  lastUpdated: DateTime.now(),
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
