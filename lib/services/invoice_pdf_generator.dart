import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../models/models.dart';

class InvoicePdfGenerator {
  static Future<String> generate({
    required Invoice invoice,
    required List<OrderItem> items,
    Customer? customer,
    String? bakeryName,
    String? bakeryAddress,
    String? bakeryPhone,
    String? bakeryEmail,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat.yMMMd();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final bName = bakeryName ?? 'Home Bakery';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    bName,
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#D4789C'),
                    ),
                  ),
                  if (bakeryAddress != null && bakeryAddress.isNotEmpty)
                    pw.Text(bakeryAddress, style: const pw.TextStyle(fontSize: 10)),
                  if (bakeryPhone != null && bakeryPhone.isNotEmpty)
                    pw.Text('Phone: $bakeryPhone', style: const pw.TextStyle(fontSize: 10)),
                  if (bakeryEmail != null && bakeryEmail.isNotEmpty)
                    pw.Text('Email: $bakeryEmail', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#E8A0BF'),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Invoice #: ${invoice.invoiceNumber}',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Date: ${dateFormat.format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 10)),
                  if (invoice.dueDate != null)
                    pw.Text('Due: ${dateFormat.format(invoice.dueDate!)}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // Bill To
          if (customer != null)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFF8F0'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Bill To:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#8A8A8A'),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(customer.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  if (customer.address != null && customer.address!.isNotEmpty)
                    pw.Text(customer.address!, style: const pw.TextStyle(fontSize: 10)),
                  if (customer.phone != null && customer.phone!.isNotEmpty)
                    pw.Text(customer.phone!, style: const pw.TextStyle(fontSize: 10)),
                  if (customer.email != null && customer.email!.isNotEmpty)
                    pw.Text(customer.email!, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
          pw.SizedBox(height: 20),

          // Items table
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#E8A0BF'),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            headerAlignment: pw.Alignment.centerLeft,
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            headers: ['Item', 'Variant', 'Qty', 'Unit Price', 'Total'],
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
            },
            data: items
                .map(
                  (item) => [
                    item.productName,
                    item.variantName ?? '',
                    item.quantity.toString(),
                    'R ${item.unitPrice.toStringAsFixed(2)}',
                    'R ${item.lineTotal.toStringAsFixed(2)}',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 16),

          // Totals
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 220,
              child: pw.Column(
                children: [
                  _totalRow('Subtotal', invoice.subtotal),
                  if (invoice.tax > 0) _totalRow('Tax', invoice.tax),
                  pw.Divider(color: PdfColor.fromHex('#E8A0BF')),
                  _totalRow('Total', invoice.total, bold: true, large: true),
                  if (invoice.paidAmount > 0) _totalRow('Paid', invoice.paidAmount, color: PdfColor.fromHex('#98D8AA')),
                  if (invoice.balanceDue > 0)
                    _totalRow('Balance Due', invoice.balanceDue, bold: true, color: PdfColor.fromHex('#D4789C')),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 30),

          // Notes
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            pw.Text('Notes:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(invoice.notes!, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 20),
          ],

          // Footer
          pw.Divider(color: PdfColor.fromHex('#E8A0BF')),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#D4789C')),
            ),
          ),
        ],
      ),
    );

    // Save to app's documents directory
    final dir = await getApplicationSupportDirectory();
    final invoicesDir = Directory(p.join(dir.path, 'invoices'));
    await invoicesDir.create(recursive: true);
    final filePath = p.join(invoicesDir.path, '${invoice.invoiceNumber}_$stamp.pdf');
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  static pw.Widget _totalRow(String label, double amount, {bool bold = false, bool large = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: large ? 13 : 10, fontWeight: bold ? pw.FontWeight.bold : null, color: color),
          ),
          pw.Text(
            'R ${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: large ? 13 : 10, fontWeight: bold ? pw.FontWeight.bold : null, color: color),
          ),
        ],
      ),
    );
  }

  static Future<String> archiveSentCopy({required String sourcePath, required String invoiceNumber}) async {
    final source = File(sourcePath);
    if (!await source.exists()) return sourcePath;
    final dir = await getApplicationSupportDirectory();
    final sentDir = Directory(p.join(dir.path, 'invoices', 'sent_archive'));
    await sentDir.create(recursive: true);
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final archivedPath = p.join(sentDir.path, '${invoiceNumber}_sent_$stamp.pdf');
    await source.copy(archivedPath);
    return archivedPath;
  }
}
