import 'dart:io';

import 'demo_db.dart';

Future<void> main(List<String> args) async {
  final confirmed = args.contains('--yes');
  final clearFiles = args.contains('--delete-invoices');

  if (!confirmed) {
    stdout.writeln('This will erase all app data from the local demo database.');
    stdout.writeln('Run again with --yes to confirm.');
    stdout.writeln('Optional: add --delete-invoices to remove generated invoice files too.');
    exitCode = 64;
    return;
  }

  final dbPath = await resolveDatabasePath();
  final db = await openAppDatabase();
  try {
    await resetAllData(db);
  } finally {
    await db.close();
  }

  if (clearFiles) {
    await clearInvoicesDirectory();
  }

  stdout.writeln('Reset complete.');
  stdout.writeln('Database: $dbPath');
  if (clearFiles) {
    stdout.writeln('Invoice files deleted.');
  }
}
