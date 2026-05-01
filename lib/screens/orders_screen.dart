import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _db = DatabaseHelper();
  List<Order> _orders = [];
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orders = await _db.getOrders(statusFilter: _statusFilter == 'all' ? null : _statusFilter);
    setState(() => _orders = orders);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return BakeryTheme.warning;
      case 'in_progress':
        return BakeryTheme.tertiary;
      case 'ready':
        return BakeryTheme.secondary;
      case 'delivered':
        return BakeryTheme.success;
      default:
        return BakeryTheme.textSecondary;
    }
  }

  Color _paymentColor(String ps) {
    switch (ps) {
      case 'paid':
        return BakeryTheme.success;
      case 'partial':
        return BakeryTheme.warning;
      default:
        return BakeryTheme.error;
    }
  }

  Future<void> _showForm([Order? existing]) async {
    final customers = await _db.getCustomers();
    final products = await _db.getProductsBackedByRecipes();
    if (!mounted) return;
    final result = await showDialog<_OrderFormResult>(
      context: context,
      builder: (ctx) => _OrderForm(existing: existing, customers: customers, products: products, db: _db),
    );
    if (result != null) {
      if (existing != null) {
        await _db.updateOrder(result.order);
        await _db.deleteOrderItems(existing.id!);
      }
      final orderId = existing != null ? existing.id! : await _db.insertOrder(result.order);
      for (final item in result.items) {
        await _db.insertOrderItem(
          OrderItem(
            orderId: orderId,
            productId: item.productId,
            productName: item.productName,
            variantName: item.variantName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
          ),
        );
      }
      // Update order total
      final total = result.items.fold<double>(0, (sum, i) => sum + i.quantity * i.unitPrice);
      await _db.updateOrder(result.order.copyWith(id: orderId, totalAmount: total));
      _load();
    }
  }

  Future<void> _updateStatus(Order order, String newStatus) async {
    if (order.id != null && order.status != 'delivered' && newStatus == 'delivered') {
      await _db.consumeInventoryForDeliveredOrder(order.id!);
    }
    await _db.updateOrder(order.copyWith(status: newStatus));
    _load();
  }

  Future<void> _recordPayment(Order order) async {
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: ${formatCurrency(order.totalAmount)} | Paid: ${formatCurrency(order.paidAmount)}'),
            Text('Remaining: ${formatCurrency(order.totalAmount - order.paidAmount)}'),
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
      final newPaid = order.paidAmount + result;
      final ps = newPaid >= order.totalAmount
          ? 'paid'
          : newPaid > 0
          ? 'partial'
          : 'unpaid';
      await _db.updateOrder(order.copyWith(paidAmount: newPaid, paymentStatus: ps));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = {
      'all': 'All',
      'pending': 'Pending',
      'in_progress': 'In Progress',
      'ready': 'Ready',
      'delivered': 'Delivered',
    };

    return Column(
      children: [
        ScreenHeader(
          title: 'Orders',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Order'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: filters.entries.map((e) {
                final selected = _statusFilter == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppFilterChip(
                    label: e.value,
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _statusFilter = e.key);
                      _load();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _orders.isEmpty
              ? const EmptyState(icon: Icons.receipt_long_outlined, message: 'No orders yet.')
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _orders.length,
                  itemBuilder: (ctx, i) {
                    final o = _orders[i];
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
                                  Text(
                                    'Order #${o.id}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  _statusChip(o.status, _statusColor(o.status)),
                                  const SizedBox(width: 8),
                                  _statusChip(o.paymentStatus, _paymentColor(o.paymentStatus)),
                                  const Spacer(),
                                  Text(
                                    formatCurrency(o.totalAmount),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (o.customerName != null && o.customerName!.isNotEmpty)
                                    Text('Customer: ${o.customerName}  |  '),
                                  Text('Ordered: ${DateFormat.yMMMd().format(o.orderDate)}'),
                                  if (o.dueDate != null) ...[
                                    const Text('  |  '),
                                    Text('Due: ${DateFormat.yMMMd().format(o.dueDate!)}'),
                                  ],
                                ],
                              ),
                              if (o.notes != null && o.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Notes: ${o.notes}', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                              const Divider(height: 20),
                              Row(
                                children: [
                                  if (o.status != 'delivered') ...[
                                    _actionButton('Next Status', Icons.arrow_forward, () {
                                      final next = {
                                        'pending': 'in_progress',
                                        'in_progress': 'ready',
                                        'ready': 'delivered',
                                      };
                                      if (next.containsKey(o.status)) {
                                        _updateStatus(o, next[o.status]!);
                                      }
                                    }),
                                    const SizedBox(width: 8),
                                  ],
                                  if (o.status != 'pending') ...[
                                    _actionButton('Previous Status', Icons.arrow_back, () async {
                                      final confirmed =
                                          await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Reverse Status Change'),
                                              content: const Text(
                                                'Are you sure you want to move this order back to the previous status? '
                                                'This action should only be used to correct mistakes.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.orange.shade700,
                                                  ),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Go Back', style: TextStyle(color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          ) ??
                                          false;
                                      if (confirmed) {
                                        final prev = {
                                          'in_progress': 'pending',
                                          'ready': 'in_progress',
                                          'delivered': 'ready',
                                        };
                                        if (prev.containsKey(o.status)) {
                                          _updateStatus(o, prev[o.status]!);
                                        }
                                      }
                                    }),
                                    const SizedBox(width: 8),
                                  ],
                                  if (o.paymentStatus != 'paid')
                                    _actionButton('Record Payment', Icons.payment, () => _recordPayment(o)),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () => _showForm(o),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    onPressed: () async {
                                      if (await confirmDelete(context, 'Order #${o.id}')) {
                                        await _db.deleteOrder(o.id!);
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

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
      child: Text(
        label.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color.withValues(alpha: 1.0)),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: BakeryTheme.primary.withValues(alpha: 0.5)),
      ),
    );
  }
}

// ── Order Form ──
class _OrderFormResult {
  final Order order;
  final List<OrderItem> items;
  _OrderFormResult(this.order, this.items);
}

class _OrderForm extends StatefulWidget {
  final Order? existing;
  final List<Customer> customers;
  final List<Product> products;
  final DatabaseHelper db;
  const _OrderForm({this.existing, required this.customers, required this.products, required this.db});

  @override
  State<_OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<_OrderForm> {
  int? _customerId;
  DateTime? _dueDate;
  final _notes = TextEditingController();
  final List<_LineItem> _lines = [];
  bool _manualPriceOverride = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _customerId = e.customerId;
      _dueDate = e.dueDate;
      _notes.text = e.notes ?? '';
      _loadExistingItems();
    }
  }

  Future<void> _loadExistingItems() async {
    if (widget.existing?.id == null) return;
    final items = await widget.db.getOrderItems(widget.existing!.id!);
    setState(() {
      _lines.addAll(
        items.map((i) {
          // Try to find the original product to get its price
          Product? product;
          try {
            product = widget.products.firstWhere((p) => p.id == i.productId);
          } catch (e) {
            product = null;
          }
          return _LineItem(
            productName: i.productName,
            variantName: i.variantName,
            quantity: i.quantity,
            unitPrice: i.unitPrice,
            productId: i.productId,
            originalPrice: product?.fixedPrice,
          );
        }),
      );
    });
  }

  void _addLine() {
    setState(() => _lines.add(_LineItem()));
  }

  double get _total => _lines.fold(0, (sum, l) => sum + l.quantity * l.unitPrice);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Order' : 'New Order'),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int?>(
                initialValue: _customerId,
                decoration: const InputDecoration(labelText: 'Customer'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Walk-in')),
                  ...widget.customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => setState(() => _customerId = v),
              ),
              const SizedBox(height: 12),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text('Advanced Options', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  initiallyExpanded: _dueDate != null || _notes.text.isNotEmpty,
                  children: [
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setState(() => _dueDate = d);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Due Date'),
                        child: Text(_dueDate != null ? DateFormat.yMMMd().format(_dueDate!) : 'Not set'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notes,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Line Items', style: TextStyle(fontWeight: FontWeight.bold)),
              if (_lines.isNotEmpty && _lines.any((l) => l.productId != null))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _manualPriceOverride,
                    title: const Text('Manual price override'),
                    subtitle: const Text(
                      'Enable to manually edit line price. Product selection remains recipe-backed.',
                    ),
                    onChanged: (v) {
                      final newValue = v ?? false;
                      setState(() {
                        _manualPriceOverride = newValue;
                        // When disabling override, revert all line prices to original product prices
                        if (!newValue) {
                          for (final line in _lines) {
                            if (line.originalPrice != null) {
                              line.unitPrice = line.originalPrice!;
                            }
                          }
                        }
                      });
                    },
                  ),
                ),
              const SizedBox(height: 8),
              ..._lines.asMap().entries.map((entry) {
                final idx = entry.key;
                final line = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<int?>(
                              isExpanded: true,
                              initialValue: widget.products.any((p) => p.id == line.productId) ? line.productId : null,
                              decoration: const InputDecoration(labelText: 'Recipe Product'),
                              items: widget.products
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p.id,
                                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                final p = widget.products.firstWhere((x) => x.id == v);
                                setState(() {
                                  line.productId = p.id;
                                  line.productName = p.name;
                                  line.originalPrice = p.fixedPrice ?? 0;
                                  if (!_manualPriceOverride) {
                                    line.unitPrice = line.originalPrice!;
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: line.variantName ?? '',
                              decoration: const InputDecoration(labelText: 'Size'),
                              onChanged: (v) => line.variantName = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: line.quantity.toString(),
                              decoration: const InputDecoration(labelText: 'Qty'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(() => line.quantity = int.tryParse(v) ?? 1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: line.unitPrice.toStringAsFixed(2),
                              readOnly: !_manualPriceOverride,
                              decoration: const InputDecoration(labelText: 'Price'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (v) => setState(() => line.unitPrice = double.tryParse(v) ?? 0),
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
                onPressed: _addLine,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Line'),
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
            // Validate at least one line item with a product
            final validItems = _lines.where((l) => l.productId != null && l.quantity > 0).toList();
            if (validItems.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add at least one line item with a product and quantity > 0'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final order = Order(
              id: widget.existing?.id,
              customerId: _customerId,
              orderDate: widget.existing?.orderDate ?? DateTime.now(),
              dueDate: _dueDate,
              status: widget.existing?.status ?? 'pending',
              paymentStatus: widget.existing?.paymentStatus ?? 'unpaid',
              totalAmount: _total,
              paidAmount: widget.existing?.paidAmount ?? 0,
              notes: _notes.text.trim(),
            );
            final items = _lines
                .where((l) => l.productId != null)
                .map(
                  (l) => OrderItem(
                    orderId: widget.existing?.id ?? 0,
                    productId: l.productId,
                    productName: l.productName,
                    variantName: l.variantName,
                    quantity: l.quantity,
                    unitPrice: l.unitPrice,
                  ),
                )
                .toList();
            Navigator.pop(context, _OrderFormResult(order, items));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _LineItem {
  String productName;
  String? variantName;
  int quantity;
  double unitPrice;
  int? productId;
  double? originalPrice; // Track original product price for override revert

  _LineItem({
    this.productName = '',
    this.variantName,
    this.quantity = 1,
    this.unitPrice = 0,
    this.productId,
    this.originalPrice,
  });
}
