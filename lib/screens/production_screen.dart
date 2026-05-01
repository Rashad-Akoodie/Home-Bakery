import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  final _db = DatabaseHelper();
  List<ProductionTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getProductionTasks();
    setState(() => _tasks = list);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return BakeryTheme.success;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.timelapse;
      default:
        return Icons.schedule;
    }
  }

  Future<void> _updateStatus(ProductionTask task, String newStatus) async {
    await _db.updateProductionTask(task.copyWith(status: newStatus));
    _load();
  }

  Future<void> _showForm([ProductionTask? existing]) async {
    final recipes = await _db.getRecipes();
    final orders = await _db.getOrders();
    if (!mounted) return;
    final result = await showDialog<ProductionTask>(
      context: context,
      builder: (ctx) => _ProductionForm(existing: existing, recipes: recipes, orders: orders),
    );
    if (result != null) {
      if (existing != null) {
        await _db.updateProductionTask(result);
      } else {
        await _db.insertProductionTask(result);
      }
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayTasks = _tasks.where(
      (t) =>
          t.scheduledDate.year == today.year &&
          t.scheduledDate.month == today.month &&
          t.scheduledDate.day == today.day,
    );
    final upcoming = _tasks.where(
      (t) =>
          t.scheduledDate.isAfter(today) &&
          !(t.scheduledDate.year == today.year &&
              t.scheduledDate.month == today.month &&
              t.scheduledDate.day == today.day),
    );
    final past = _tasks.where((t) => t.scheduledDate.isBefore(DateTime(today.year, today.month, today.day)));

    return Column(
      children: [
        ScreenHeader(
          title: 'Production Scheduler',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Task'),
            ),
          ],
        ),
        Expanded(
          child: _tasks.isEmpty
              ? const EmptyState(icon: Icons.event_note_outlined, message: 'No production tasks scheduled yet.')
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (todayTasks.isNotEmpty) ...[
                      const SectionHeader(title: 'Today'),
                      ...todayTasks.map((t) => _taskCard(t)),
                    ],
                    if (upcoming.isNotEmpty) ...[
                      const SectionHeader(title: 'Upcoming'),
                      ...upcoming.map((t) => _taskCard(t)),
                    ],
                    if (past.isNotEmpty) ...[const SectionHeader(title: 'Past'), ...past.map((t) => _taskCard(t))],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _taskCard(ProductionTask t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(_statusIcon(t.status), color: _statusColor(t.status), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      'Qty: ${t.quantity} • ${DateFormat.yMMMd().format(t.scheduledDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (t.notes != null && t.notes!.isNotEmpty)
                      Text(t.notes!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              if (t.status == 'scheduled')
                OutlinedButton(
                  onPressed: () => _updateStatus(t, 'in_progress'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                  child: const Text('Start', style: TextStyle(fontSize: 12)),
                ),
              if (t.status == 'in_progress')
                ElevatedButton(
                  onPressed: () => _updateStatus(t, 'completed'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                  child: const Text('Done', style: TextStyle(fontSize: 12)),
                ),
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showForm(t)),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () async {
                  if (await confirmDelete(context, t.productName)) {
                    await _db.deleteProductionTask(t.id!);
                    _load();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductionForm extends StatefulWidget {
  final ProductionTask? existing;
  final List<Recipe> recipes;
  final List<Order> orders;
  const _ProductionForm({this.existing, required this.recipes, required this.orders});

  @override
  State<_ProductionForm> createState() => _ProductionFormState();
}

class _ProductionFormState extends State<_ProductionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _product;
  late final TextEditingController _qty;
  late final TextEditingController _notes;
  late DateTime _date;
  int? _recipeId;
  int? _orderId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _product = TextEditingController(text: e?.productName ?? '');
    _qty = TextEditingController(text: e != null ? e.quantity.toString() : '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _date = e?.scheduledDate ?? DateTime.now();
    _recipeId = e?.recipeId;
    _orderId = e?.orderId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Task' : 'New Production Task'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _product,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qty,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null ? 'Enter qty' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _date = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Scheduled Date'),
                  child: Text(DateFormat.yMMMd().format(_date)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _recipeId,
                decoration: const InputDecoration(labelText: 'Link Recipe (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...widget.recipes.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))),
                ],
                onChanged: (v) => setState(() => _recipeId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _orderId,
                decoration: const InputDecoration(labelText: 'Link Order (optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...widget.orders.map(
                    (o) => DropdownMenuItem(value: o.id, child: Text('#${o.id} - ${o.customerName ?? 'Walk-in'}')),
                  ),
                ],
                onChanged: (v) => setState(() => _orderId = v),
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
                ProductionTask(
                  id: widget.existing?.id,
                  productName: _product.text.trim(),
                  quantity: int.parse(_qty.text),
                  scheduledDate: _date,
                  status: widget.existing?.status ?? 'scheduled',
                  recipeId: _recipeId,
                  orderId: _orderId,
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
