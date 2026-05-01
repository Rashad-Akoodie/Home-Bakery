import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../services/invoice_pdf_generator.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class DebtorsScreen extends StatefulWidget {
  const DebtorsScreen({super.key});

  @override
  State<DebtorsScreen> createState() => _DebtorsScreenState();
}

class _DebtorsScreenState extends State<DebtorsScreen> {
  final _db = DatabaseHelper();
  List<Invoice> _invoices = [];
  List<Invoice> _debtors = [];
  double _totalOwed = 0;
  String _view = 'debtors'; // 'debtors' or 'all'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _db.getInvoices();
    final debtors = await _db.getDebtors();
    final totalOwed = await _db.getTotalDebtorsBalance();
    setState(() {
      _invoices = all;
      _debtors = debtors;
      _totalOwed = totalOwed;
    });
  }

  List<Invoice> get _displayList => _view == 'debtors' ? _debtors : _invoices;

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return BakeryTheme.success;
      case 'sent':
        return BakeryTheme.tertiary;
      case 'overdue':
        return BakeryTheme.error;
      case 'draft':
        return BakeryTheme.textSecondary;
      default:
        return BakeryTheme.textSecondary;
    }
  }

  Future<void> _createInvoiceFromOrder() async {
    final orders = await _db.getOrders();
    final customers = await _db.getCustomers();
    if (!mounted) return;

    final result = await showDialog<Invoice>(
      context: context,
      builder: (ctx) => _InvoiceForm(orders: orders, customers: customers, db: _db),
    );
    if (result != null) {
      final id = await _db.insertInvoice(result);
      // Generate PDF
      final invoice = result.copyWith(id: id);
      List<OrderItem> items = [];
      if (invoice.orderId != null) {
        items = await _db.getOrderItems(invoice.orderId!);
      }
      Customer? customer;
      if (invoice.customerId != null) {
        final custs = await _db.getCustomers();
        customer = custs.where((c) => c.id == invoice.customerId).firstOrNull;
      }
      final pdfPath = await InvoicePdfGenerator.generate(invoice: invoice, items: items, customer: customer);
      await _db.updateInvoice(invoice.copyWith(pdfPath: pdfPath));
      await _db.insertInvoiceHistory(
        InvoiceHistoryEntry(
          invoiceId: id,
          invoiceNumber: invoice.invoiceNumber,
          action: 'generated',
          filePath: pdfPath,
          totalAmount: invoice.total,
        ),
      );
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice created & PDF saved to: $pdfPath')));
      }
    }
  }

  Future<void> _recordPayment(Invoice inv) async {
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total: ${formatCurrency(inv.total)}'),
            Text('Paid: ${formatCurrency(inv.paidAmount)}'),
            Text('Remaining: ${formatCurrency(inv.balanceDue)}'),
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
      final newPaid = inv.paidAmount + result;
      final newStatus = newPaid >= inv.total ? 'paid' : 'sent';
      await _db.updateInvoice(inv.copyWith(paidAmount: newPaid, status: newStatus));
      // Also update linked order payment
      if (inv.orderId != null) {
        final orders = await _db.getOrders();
        final order = orders.where((o) => o.id == inv.orderId).firstOrNull;
        if (order != null) {
          final ps = newPaid >= order.totalAmount
              ? 'paid'
              : newPaid > 0
              ? 'partial'
              : 'unpaid';
          await _db.updateOrder(order.copyWith(paidAmount: newPaid, paymentStatus: ps));
        }
      }
      _load();
    }
  }

  Future<void> _openPdf(Invoice inv) async {
    if (inv.pdfPath == null || inv.pdfPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No PDF generated for this invoice')));
      return;
    }
    final file = File(inv.pdfPath!);
    if (await file.exists()) {
      // Open with system default viewer
      final uri = Uri.file(inv.pdfPath!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF file not found')));
      }
    }
  }

  Future<void> _emailInvoice(Invoice inv) async {
    if (inv.pdfPath == null || inv.pdfPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generate a PDF first before emailing')));
      return;
    }

    String? email;
    if (inv.customerId != null) {
      final custs = await _db.getCustomers();
      final cust = custs.where((c) => c.id == inv.customerId).firstOrNull;
      email = cust?.email;
    }

    final subject = Uri.encodeComponent('Invoice ${inv.invoiceNumber} - Home Bakery');
    final body = Uri.encodeComponent(
      'Dear ${inv.customerName ?? "Customer"},\n\n'
      'Please find attached invoice ${inv.invoiceNumber} '
      'for ${formatCurrency(inv.total)}.\n\n'
      'Due date: ${inv.dueDate != null ? DateFormat.yMMMd().format(inv.dueDate!) : "Upon receipt"}\n\n'
      'The invoice PDF is saved at:\n${inv.pdfPath}\n\n'
      'Please attach it to this email.\n\n'
      'Thank you for your business!\n'
      'Home Bakery',
    );

    final mailto = 'mailto:${email ?? ""}?subject=$subject&body=$body';
    final uri = Uri.parse(mailto);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      final archived = await InvoicePdfGenerator.archiveSentCopy(
        sourcePath: inv.pdfPath!,
        invoiceNumber: inv.invoiceNumber,
      );
      await _db.insertInvoiceHistory(
        InvoiceHistoryEntry(
          invoiceId: inv.id,
          invoiceNumber: inv.invoiceNumber,
          action: 'sent',
          filePath: archived,
          recipientEmail: email,
          totalAmount: inv.total,
        ),
      );
    }

    if (!mounted) return;

    // Mark as sent
    if (inv.status == 'draft') {
      await _db.updateInvoice(inv.copyWith(status: 'sent'));
      if (!mounted) return;
      _load();
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Email client opened. Attach the PDF from:\n${inv.pdfPath}')));
  }

  Future<void> _regeneratePdf(Invoice inv) async {
    List<OrderItem> items = [];
    if (inv.orderId != null) {
      items = await _db.getOrderItems(inv.orderId!);
    }
    Customer? customer;
    if (inv.customerId != null) {
      final custs = await _db.getCustomers();
      customer = custs.where((c) => c.id == inv.customerId).firstOrNull;
    }
    final pdfPath = await InvoicePdfGenerator.generate(invoice: inv, items: items, customer: customer);
    await _db.updateInvoice(inv.copyWith(pdfPath: pdfPath));
    await _db.insertInvoiceHistory(
      InvoiceHistoryEntry(
        invoiceId: inv.id,
        invoiceNumber: inv.invoiceNumber,
        action: 'regenerated',
        filePath: pdfPath,
        totalAmount: inv.total,
      ),
    );
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF regenerated: $pdfPath')));
    }
  }

  Future<void> _showHistory(Invoice inv) async {
    final history = await _db.getInvoiceHistory(invoiceId: inv.id);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('History: ${inv.invoiceNumber}'),
        content: SizedBox(
          width: 650,
          child: history.isEmpty
              ? const Text('No history yet.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length,
                  itemBuilder: (c, i) {
                    final h = history[i];
                    final fileExists = File(h.filePath).existsSync();
                    return Card(
                      child: ListTile(
                        dense: false,
                        leading: Icon(Icons.history, color: fileExists ? BakeryTheme.primary : Colors.grey),
                        title: Text('${h.action.toUpperCase()} • ${DateFormat.yMMMd().add_Hm().format(h.createdAt)}'),
                        subtitle: Text(
                          h.filePath,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fileExists ? Colors.grey[700] : Colors.red,
                            fontSize: 11,
                            fontFamily: 'Courier',
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (fileExists)
                              IconButton(
                                icon: const Icon(Icons.picture_as_pdf, size: 20),
                                tooltip: 'Open PDF',
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _openPdfFromPath(h.filePath);
                                },
                              ),
                            if (!fileExists)
                              Tooltip(
                                message: 'File not found',
                                child: Icon(Icons.warning_outlined, size: 20, color: Colors.red.shade700),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _openPdfFromPath(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open PDF. Path: $filePath')));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF file not found')));
      }
    }
  }

  Future<void> _openInvoicesFolder() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final invoicesDir = Directory(p.join(dir.path, 'invoices'));

      // Create directory if it doesn't exist
      if (!await invoicesDir.exists()) {
        await invoicesDir.create(recursive: true);
      }

      // Open with system file manager
      final uri = Uri.file(invoicesDir.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location: ${invoicesDir.path}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open folder: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Debtors & Invoices',
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _totalOwed > 0
                    ? BakeryTheme.warning.withValues(alpha: 0.3)
                    : BakeryTheme.success.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _totalOwed > 0
                      ? BakeryTheme.warning.withValues(alpha: 0.5)
                      : BakeryTheme.success.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'Owed to you: ${formatCurrency(_totalOwed)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _totalOwed > 0 ? Colors.orange.shade800 : Colors.green.shade800,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _createInvoiceFromOrder,
              icon: const Icon(Icons.receipt, size: 18),
              label: const Text('New Invoice'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _openInvoicesFolder,
              icon: const Icon(Icons.folder_open_outlined, size: 18),
              label: const Text('Open Invoices Folder'),
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
                    label: 'Outstanding Debtors',
                    selected: _view == 'debtors',
                    onSelected: (_) => setState(() => _view = 'debtors'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppFilterChip(
                    label: 'All Invoices',
                    selected: _view == 'all',
                    onSelected: (_) => setState(() => _view = 'all'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BakeryTheme.primary.withValues(alpha: 0.08),
              border: Border.all(color: BakeryTheme.primary.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: BakeryTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Invoices are saved to your application data folder. Click "View PDF" or the PDF icon in history to open them.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _displayList.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: _view == 'debtors' ? 'No outstanding debts. All clear!' : 'No invoices yet.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _displayList.length,
                  itemBuilder: (ctx, i) {
                    final inv = _displayList[i];
                    final isOverdue =
                        inv.dueDate != null && inv.dueDate!.isBefore(DateTime.now()) && inv.status != 'paid';
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
                                    inv.invoiceNumber,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  _chip(
                                    isOverdue ? 'overdue' : inv.status,
                                    _statusColor(isOverdue ? 'overdue' : inv.status),
                                  ),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        formatCurrency(inv.total),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      if (inv.balanceDue > 0)
                                        Text(
                                          'Due: ${formatCurrency(inv.balanceDue)}',
                                          style: TextStyle(
                                            color: BakeryTheme.error,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (inv.customerName != null && inv.customerName!.isNotEmpty)
                                    Text('${inv.customerName}  |  '),
                                  Text('Issued: ${DateFormat.yMMMd().format(inv.issueDate)}'),
                                  if (inv.dueDate != null) ...[
                                    const Text('  |  '),
                                    Text(
                                      'Due: ${DateFormat.yMMMd().format(inv.dueDate!)}',
                                      style: TextStyle(
                                        color: isOverdue ? Colors.red.shade700 : null,
                                        fontWeight: isOverdue ? FontWeight.bold : null,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const Divider(height: 20),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (inv.status != 'paid')
                                    _actionBtn('Record Payment', Icons.payment, () => _recordPayment(inv)),
                                  _actionBtn('View PDF', Icons.picture_as_pdf, () => _openPdf(inv)),
                                  _actionBtn('Email', Icons.email, () => _emailInvoice(inv)),
                                  _actionBtn('Regenerate PDF', Icons.refresh, () => _regeneratePdf(inv)),
                                  _actionBtn('History', Icons.history, () => _showHistory(inv)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    onPressed: () async {
                                      if (await confirmDelete(context, inv.invoiceNumber)) {
                                        await _db.deleteInvoice(inv.id!);
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

  Widget _actionBtn(String label, IconData icon, VoidCallback onPressed) {
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

// ── Invoice Form ──
class _InvoiceForm extends StatefulWidget {
  final List<Order> orders;
  final List<Customer> customers;
  final DatabaseHelper db;
  const _InvoiceForm({required this.orders, required this.customers, required this.db});

  @override
  State<_InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<_InvoiceForm> {
  int? _orderId;
  int? _customerId;
  DateTime? _dueDate;
  final _tax = TextEditingController(text: '0');
  final _notes = TextEditingController();
  String _invoiceNumber = '';
  double _subtotal = 0;

  @override
  void initState() {
    super.initState();
    _generateNumber();
  }

  Future<void> _generateNumber() async {
    final num = await widget.db.generateInvoiceNumber();
    setState(() => _invoiceNumber = num);
  }

  void _onOrderSelected(int? orderId) {
    setState(() {
      _orderId = orderId;
      if (orderId != null) {
        final order = widget.orders.where((o) => o.id == orderId).firstOrNull;
        if (order != null) {
          _customerId = order.customerId;
          _subtotal = order.totalAmount;
        }
      }
    });
  }

  double get _total => _subtotal + (double.tryParse(_tax.text) ?? 0);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Invoice'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoice #: $_invoiceNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: _orderId,
                decoration: const InputDecoration(labelText: 'Link to Order'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No linked order')),
                  ...widget.orders.map(
                    (o) => DropdownMenuItem(
                      value: o.id,
                      child: Text('Order #${o.id} - ${o.customerName ?? "Walk-in"} (${formatCurrency(o.totalAmount)})'),
                    ),
                  ),
                ],
                onChanged: _onOrderSelected,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _customerId,
                decoration: const InputDecoration(labelText: 'Customer'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No customer')),
                  ...widget.customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => setState(() => _customerId = v),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 14)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _dueDate = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Due Date'),
                  child: Text(_dueDate != null ? DateFormat.yMMMd().format(_dueDate!) : 'Select a due date'),
                ),
              ),
              const SizedBox(height: 12),
              if (_orderId == null)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Subtotal (manual entry)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => setState(() => _subtotal = double.tryParse(v) ?? 0),
                ),
              if (_orderId != null)
                Text(
                  'Subtotal (from order): ${formatCurrency(_subtotal)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tax,
                decoration: const InputDecoration(labelText: 'Tax Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: ${formatCurrency(_total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final invoice = Invoice(
              orderId: _orderId,
              customerId: _customerId,
              invoiceNumber: _invoiceNumber,
              dueDate: _dueDate,
              subtotal: _subtotal,
              tax: double.tryParse(_tax.text) ?? 0,
              total: _total,
              status: 'draft',
              notes: _notes.text.trim(),
            );
            Navigator.pop(context, invoice);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
