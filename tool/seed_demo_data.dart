import 'dart:io';

import 'demo_db.dart';

Future<void> main(List<String> args) async {
  final resetFirst = !args.contains('--append');
  final dbPath = await resolveDatabasePath();
  final db = await openAppDatabase();

  try {
    if (resetFirst) {
      await resetAllData(db);
    }
    await seedDemoData(db);

    final inventoryCount = await _count(db, 'inventory');
    final customerCount = await _count(db, 'customers');
    final productCount = await _count(db, 'products');
    final orderCount = await _count(db, 'orders');
    final invoiceCount = await _count(db, 'invoices');

    stdout.writeln('Demo data seeded successfully.');
    stdout.writeln('Database: $dbPath');
    stdout.writeln('Inventory items: $inventoryCount');
    stdout.writeln('Customers: $customerCount');
    stdout.writeln('Products: $productCount');
    stdout.writeln('Orders: $orderCount');
    stdout.writeln('Invoices: $invoiceCount');
  } finally {
    await db.close();
  }
}

Future<int> _count(dynamic db, String table) async {
  final rows = await db.rawQuery('SELECT COUNT(*) AS cnt FROM $table');
  return (rows.first['cnt'] as int?) ?? 0;
}
