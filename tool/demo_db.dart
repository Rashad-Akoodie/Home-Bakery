import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const String _dbFileName = 'home_bakery.db';
const String _macBundleId = 'com.example.homeBakeryAssistant';

Future<Database> openAppDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbPath = await resolveDatabasePath();
  await Directory(p.dirname(dbPath)).create(recursive: true);

  return databaseFactoryFfi.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(version: 4, onCreate: _onCreate, onUpgrade: _onUpgrade),
  );
}

Future<String> resolveDatabasePath() async {
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    throw StateError('HOME is not set.');
  }

  final candidates = <String>[
    p.join(
      home,
      'Library',
      'Containers',
      _macBundleId,
      'Data',
      'Library',
      'Application Support',
      _macBundleId,
      _dbFileName,
    ),
    p.join(home, 'Library', 'Application Support', _dbFileName),
    p.join(home, 'Library', 'Application Support', 'home_bakery_assistant', _dbFileName),
    p.join(home, 'Library', 'Application Support', 'home_bakery', _dbFileName),
  ];

  for (final candidate in candidates) {
    if (await File(candidate).exists()) {
      return candidate;
    }
  }

  final containersDir = Directory(p.join(home, 'Library', 'Containers'));
  if (await containersDir.exists()) {
    await for (final entity in containersDir.list(recursive: true, followLinks: false)) {
      if (entity is File && p.basename(entity.path) == _dbFileName) {
        return entity.path;
      }
    }
  }

  return candidates.first;
}

Future<String> resolveInvoicesDirectory() async {
  final dbPath = await resolveDatabasePath();
  final supportDir = Directory(p.dirname(dbPath));
  return p.join(supportDir.path, 'invoices');
}

Future<void> clearInvoicesDirectory() async {
  final invoicesDir = Directory(await resolveInvoicesDirectory());
  if (await invoicesDir.exists()) {
    await invoicesDir.delete(recursive: true);
  }
}

Future<void> resetAllData(Database db) async {
  final tables = <String>[
    'invoice_history',
    'invoices',
    'order_items',
    'orders',
    'recipe_ingredients',
    'recipes',
    'product_variants',
    'products',
    'grocery_run_items',
    'grocery_runs',
    'production_tasks',
    'expenses',
    'waste_log',
    'creditors',
    'customers',
    'suppliers',
    'inventory',
    'setting_options',
    'app_preferences',
  ];

  await db.transaction((txn) async {
    await txn.execute('PRAGMA foreign_keys = OFF');
    for (final table in tables) {
      await txn.delete(table);
    }
    await txn.delete('sqlite_sequence');
    await txn.execute('PRAGMA foreign_keys = ON');
    await _seedDefaultSettingOptions(txn);
  });
}

Future<void> seedDemoData(Database db) async {
  final random = Random(42);
  final now = DateTime.now();

  await db.transaction((txn) async {
    final inventoryIds = <String, int>{};
    final inventoryItems = [
      ('Cake Flour', 'kg', 18.0, 8.0, 'Flour'),
      ('Bread Flour', 'kg', 12.0, 6.0, 'Flour'),
      ('Self Raising Flour', 'kg', 0.0, 5.0, 'Flour'),
      ('Granulated Sugar', 'kg', 14.5, 7.0, 'Sugar'),
      ('Brown Sugar', 'kg', 6.0, 4.0, 'Sugar'),
      ('Icing Sugar', 'kg', 2.0, 4.0, 'Sugar'),
      ('Butter', 'kg', 4.0, 5.0, 'Dairy'),
      ('Cream Cheese', 'kg', 1.0, 3.0, 'Dairy'),
      ('Eggs', 'pcs', 72.0, 30.0, 'Dairy'),
      ('Milk', 'L', 10.0, 5.0, 'Dairy'),
      ('Heavy Cream', 'L', 2.0, 3.0, 'Dairy'),
      ('Vanilla Extract', 'ml', 500.0, 150.0, 'Flavoring'),
      ('Cocoa Powder', 'kg', 3.5, 2.0, 'Baking'),
      ('Baking Powder', 'g', 800.0, 300.0, 'Baking'),
      ('Baking Soda', 'g', 650.0, 250.0, 'Baking'),
      ('Strawberries', 'kg', 1.5, 3.0, 'Fruit'),
      ('Blueberries', 'kg', 0.5, 2.0, 'Fruit'),
      ('Lemons', 'pcs', 10.0, 12.0, 'Fruit'),
      ('Cake Boxes', 'pcs', 45.0, 20.0, 'Packaging'),
      ('Cupcake Liners', 'pcs', 0.0, 200.0, 'Packaging'),
    ];

    for (final item in inventoryItems) {
      final id = await txn.insert('inventory', {
        'name': item.$1,
        'unit': item.$2,
        'quantity': item.$3,
        'reorder_level': item.$4,
        'category': item.$5,
        'last_updated': now.toIso8601String(),
      });
      inventoryIds[item.$1] = id;
    }

    final supplierIds = <int>[];
    final suppliers = [
      ('Metro Cash & Carry', '555-1001', 'orders@metro.example', '23 Bulk Road', 'Primary grocery supplier'),
      ('Sweet Source', '555-1002', 'sales@sweetsource.example', '44 Sugar Ave', 'Sugar and chocolate'),
      ('Dairy Fresh', '555-1003', 'dispatch@dairyfresh.example', '12 Cream Lane', 'Dairy and eggs'),
      ('BakePro Supplies', '555-1004', 'hello@bakepro.example', '88 Baker Street', 'Packaging and tools'),
      ('Berry Market', '555-1005', 'fruit@berrymarket.example', '9 Orchard Park', 'Seasonal fruit'),
    ];

    for (final supplier in suppliers) {
      supplierIds.add(
        await txn.insert('suppliers', {
          'name': supplier.$1,
          'phone': supplier.$2,
          'email': supplier.$3,
          'address': supplier.$4,
          'notes': supplier.$5,
        }),
      );
    }

    final customerIds = <int>[];
    final customers = [
      ('Ava Johnson', '555-2001', 'ava@example.com', '12 Rose Street', 'Birthday cake regular'),
      ('Noah Smith', '555-2002', 'noah@example.com', '8 River Close', 'Prefers vanilla frosting'),
      ('Mia Brown', '555-2003', 'mia@example.com', '43 Grand Ave', 'Corporate cupcakes'),
      ('Liam Davis', '555-2004', 'liam@example.com', '77 Green Way', 'Wedding tasting client'),
      ('Emma Wilson', '555-2005', 'emma@example.com', '16 Elm Road', 'Weekend pickups'),
      ('Olivia Taylor', '555-2006', 'olivia@example.com', '5 Hillcrest', 'Gluten conscious'),
      ('Elijah Thomas', '555-2007', 'elijah@example.com', '31 Sunset Blvd', 'Large event orders'),
      ('Sophia Moore', '555-2008', 'sophia@example.com', '90 Willow Drive', 'Chocolate lover'),
      ('Lucas Martin', '555-2009', 'lucas@example.com', '14 Lake View', 'School functions'),
      ('Charlotte Lee', '555-2010', 'charlotte@example.com', '28 Cedar Court', 'Celebration cakes'),
      ('Amelia King', '555-2011', 'amelia@example.com', '4 Oak Terrace', 'Cupcake sampler buyer'),
      ('Benjamin Scott', '555-2012', 'ben@example.com', '52 Meadow Lane', 'Office treats'),
    ];

    for (final customer in customers) {
      customerIds.add(
        await txn.insert('customers', {
          'name': customer.$1,
          'phone': customer.$2,
          'email': customer.$3,
          'address': customer.$4,
          'notes': customer.$5,
          'created_at': now.subtract(Duration(days: random.nextInt(120))).toIso8601String(),
        }),
      );
    }

    final productIds = <String, int>{};
    final productVariants = <String, Map<String, double>>{};
    final fixedProducts = [
      ('Vanilla Cupcake Box', 18.0, 'Cupcakes'),
      ('Chocolate Cupcake Box', 20.0, 'Cupcakes'),
      ('Red Velvet Slice', 6.5, 'Slices'),
      ('Lemon Drizzle Loaf', 14.0, 'Loaves'),
      ('Brownie Tray', 22.0, 'Brownies'),
      ('Blueberry Muffin Box', 16.0, 'Muffins'),
    ];

    for (final product in fixedProducts) {
      final id = await txn.insert('products', {
        'name': product.$1,
        'description': '${product.$1} demo product',
        'pricing_type': 'fixed',
        'fixed_price': product.$2,
        'category': product.$3,
        'is_active': 1,
      });
      productIds[product.$1] = id;
    }

    final sizedProducts = {
      'Classic Vanilla Cake': {'6-inch': 45.0, '8-inch': 70.0, '10-inch': 95.0},
      'Chocolate Celebration Cake': {'6-inch': 50.0, '8-inch': 78.0, '10-inch': 105.0},
      'Red Velvet Cake': {'6-inch': 52.0, '8-inch': 82.0, '10-inch': 110.0},
      'Strawberry Shortcake': {'6-inch': 55.0, '8-inch': 88.0, '10-inch': 118.0},
      'Carrot Cake': {'6-inch': 48.0, '8-inch': 76.0, '10-inch': 102.0},
      'Wedding Tasting Sampler': {'Standard': 65.0, 'Premium': 95.0},
    };

    for (final entry in sizedProducts.entries) {
      final productId = await txn.insert('products', {
        'name': entry.key,
        'description': '${entry.key} demo product',
        'pricing_type': 'sized',
        'fixed_price': null,
        'category': 'Cakes',
        'is_active': 1,
      });
      productIds[entry.key] = productId;
      productVariants[entry.key] = entry.value;
      for (final variant in entry.value.entries) {
        await txn.insert('product_variants', {
          'product_id': productId,
          'size_name': variant.key,
          'price': variant.value,
        });
      }
    }

    final recipeDefs = [
      (
        'Classic Vanilla Cake',
        'Soft vanilla sponge with buttercream',
        'Mix, bake, cool, ice.',
        12,
        '2h 30m',
        [
          ('Cake Flour', 1.2, 'kg', 3.5),
          ('Granulated Sugar', 0.8, 'kg', 2.4),
          ('Butter', 0.6, 'kg', 5.8),
          ('Eggs', 8.0, 'pcs', 0.25),
          ('Vanilla Extract', 25.0, 'ml', 0.04),
        ],
      ),
      (
        'Chocolate Celebration Cake',
        'Rich chocolate cake with ganache',
        'Mix, bake, fill and frost.',
        12,
        '3h 00m',
        [
          ('Cake Flour', 1.0, 'kg', 3.5),
          ('Granulated Sugar', 0.9, 'kg', 2.4),
          ('Cocoa Powder', 0.25, 'kg', 10.0),
          ('Butter', 0.5, 'kg', 5.8),
          ('Eggs', 8.0, 'pcs', 0.25),
        ],
      ),
      (
        'Red Velvet Cake',
        'Velvety crumb with cream cheese frosting',
        'Mix, bake, cool and stack.',
        12,
        '3h 15m',
        [
          ('Self Raising Flour', 1.0, 'kg', 3.2),
          ('Granulated Sugar', 0.8, 'kg', 2.4),
          ('Butter', 0.45, 'kg', 5.8),
          ('Cream Cheese', 0.5, 'kg', 8.0),
          ('Eggs', 8.0, 'pcs', 0.25),
        ],
      ),
      (
        'Lemon Drizzle Loaf',
        'Bright lemon loaf with drizzle',
        'Mix and bake.',
        8,
        '1h 40m',
        [
          ('Cake Flour', 0.8, 'kg', 3.5),
          ('Granulated Sugar', 0.5, 'kg', 2.4),
          ('Butter', 0.35, 'kg', 5.8),
          ('Lemons', 4.0, 'pcs', 0.7),
          ('Eggs', 5.0, 'pcs', 0.25),
        ],
      ),
      (
        'Blueberry Muffin Box',
        'Bakery-style blueberry muffins',
        'Mix, portion, bake.',
        12,
        '1h 20m',
        [
          ('Cake Flour', 0.9, 'kg', 3.5),
          ('Granulated Sugar', 0.45, 'kg', 2.4),
          ('Blueberries', 0.35, 'kg', 9.0),
          ('Milk', 0.4, 'L', 1.7),
          ('Eggs', 4.0, 'pcs', 0.25),
        ],
      ),
    ];

    for (final recipe in recipeDefs) {
      final productId = productIds[recipe.$1]!;
      final estimatedCost = (recipe.$6 as List<(String, double, String, double)>).fold<double>(
        0,
        (sum, ingredient) => sum + ingredient.$2 * ingredient.$4,
      );
      final recipeId = await txn.insert('recipes', {
        'name': recipe.$1,
        'description': recipe.$2,
        'instructions': recipe.$3,
        'servings': recipe.$4,
        'prep_time': recipe.$5,
        'product_id': productId,
        'estimated_cost': estimatedCost,
      });
      for (final ingredient in recipe.$6 as List<(String, double, String, double)>) {
        await txn.insert('recipe_ingredients', {
          'recipe_id': recipeId,
          'inventory_item_id': inventoryIds[ingredient.$1],
          'ingredient_name': ingredient.$1,
          'quantity': ingredient.$2,
          'unit': ingredient.$3,
          'cost_per_unit': ingredient.$4,
        });
      }
    }

    for (var i = 0; i < 9; i++) {
      final runDate = now.subtract(Duration(days: 35 - (i * 3)));
      final supplierId = supplierIds[i % supplierIds.length];
      final groceryRunId = await txn.insert('grocery_runs', {
        'date': runDate.toIso8601String(),
        'store_name': suppliers[i % suppliers.length].$1,
        'supplier_id': supplierId,
        'total_cost': 0.0,
        'status': i < 7 ? 'completed' : 'draft',
        'inventory_applied': i < 7 ? 1 : 0,
        'notes': i.isEven ? 'Weekly replenishment' : 'Special top-up for weekend orders',
      });

      var totalCost = 0.0;
      final selectedNames = inventoryItems.skip(i % 4).take(4).map((e) => e.$1).toList();
      for (final name in selectedNames) {
        final qty = 1 + random.nextInt(6) + random.nextDouble();
        final price = 2 + random.nextInt(14) + random.nextDouble();
        final lineTotal = qty * price;
        totalCost += lineTotal;
        await txn.insert('grocery_run_items', {
          'grocery_run_id': groceryRunId,
          'item_name': name,
          'quantity': qty,
          'unit': inventoryItems.firstWhere((e) => e.$1 == name).$2,
          'unit_price': price,
          'line_total': lineTotal,
          'inventory_item_id': inventoryIds[name],
        });
      }
      await txn.update('grocery_runs', {'total_cost': totalCost}, where: 'id = ?', whereArgs: [groceryRunId]);
    }

    for (var i = 0; i < 18; i++) {
      final expenseDate = now.subtract(Duration(days: random.nextInt(50)));
      final category = ['Packaging', 'Utilities', 'Marketing', 'Transport', 'Equipment'][i % 5];
      final amount = 15 + random.nextInt(180) + random.nextDouble();
      await txn.insert('expenses', {
        'category': category,
        'description': '$category expense #${i + 1}',
        'amount': amount,
        'date': expenseDate.toIso8601String(),
        'notes': i.isEven ? 'Seeded demo expense' : '',
      });
    }

    for (var i = 0; i < 8; i++) {
      final wasteDate = now.subtract(Duration(days: random.nextInt(40)));
      final item = inventoryItems[(i * 2) % inventoryItems.length];
      final quantity = (random.nextInt(3) + 1).toDouble();
      final estimatedLoss = quantity * (2.5 + random.nextDouble() * 6);
      await txn.insert('waste_log', {
        'item_name': item.$1,
        'quantity': quantity,
        'unit': item.$2,
        'reason': ['Spoilage', 'Production mistake', 'Damaged packaging'][i % 3],
        'estimated_loss': estimatedLoss,
        'date': wasteDate.toIso8601String(),
        'notes': 'Seeded demo waste record',
      });
    }

    final productNames = productIds.keys.toList();
    for (var i = 0; i < 22; i++) {
      final orderDate = now.subtract(Duration(days: 28 - i));
      final dueDate = orderDate.add(Duration(days: 2 + (i % 5)));
      final status = i < 6
          ? 'delivered'
          : i < 12
          ? 'ready'
          : i < 18
          ? 'in_progress'
          : 'pending';
      final paymentStatus = i < 7
          ? 'paid'
          : i < 16
          ? 'partial'
          : 'unpaid';
      final customerId = customerIds[i % customerIds.length];

      final lineItems = <Map<String, Object?>>[];
      final lineCount = 1 + random.nextInt(3);
      var total = 0.0;
      for (var j = 0; j < lineCount; j++) {
        final productName = productNames[(i + j) % productNames.length];
        final productId = productIds[productName]!;
        final quantity = 1 + random.nextInt(3);
        String variantName = '';
        double unitPrice;
        if (productVariants.containsKey(productName)) {
          final variants = productVariants[productName]!;
          final variantEntries = variants.entries.toList();
          final picked = variantEntries[(i + j) % variantEntries.length];
          variantName = picked.key;
          unitPrice = picked.value;
        } else {
          unitPrice = fixedProducts.firstWhere((p) => p.$1 == productName).$2;
        }
        final lineTotal = unitPrice * quantity;
        total += lineTotal;
        lineItems.add({
          'product_id': productId,
          'product_name': productName,
          'variant_name': variantName,
          'quantity': quantity,
          'unit_price': unitPrice,
          'line_total': lineTotal,
        });
      }

      final paidAmount = paymentStatus == 'paid'
          ? total
          : paymentStatus == 'partial'
          ? double.parse((total * 0.45).toStringAsFixed(2))
          : 0.0;
      final orderId = await txn.insert('orders', {
        'customer_id': customerId,
        'order_date': orderDate.toIso8601String(),
        'due_date': dueDate.toIso8601String(),
        'status': status,
        'payment_status': paymentStatus,
        'total_amount': total,
        'paid_amount': paidAmount,
        'notes': i.isEven ? 'Seeded demo order' : 'Customer requested pastel colors',
      });

      for (final line in lineItems) {
        await txn.insert('order_items', {'order_id': orderId, ...line});
      }

      if (status != 'pending' || paymentStatus != 'unpaid') {
        final issueDate = orderDate.add(const Duration(hours: 6));
        final dueInvoiceDate = dueDate.add(const Duration(days: 3));
        final invoiceNumber = 'INV-${now.year}-${(1000 + i).toString()}';
        final invoiceStatus = paidAmount >= total
            ? 'paid'
            : paidAmount > 0
            ? 'partial'
            : 'sent';
        await txn.insert('invoices', {
          'order_id': orderId,
          'customer_id': customerId,
          'invoice_number': invoiceNumber,
          'issue_date': issueDate.toIso8601String(),
          'due_date': dueInvoiceDate.toIso8601String(),
          'subtotal': total,
          'tax': 0.0,
          'total': total,
          'paid_amount': paidAmount,
          'status': invoiceStatus,
          'pdf_path': '',
          'notes': 'Seeded demo invoice',
        });
      }
    }

    for (var i = 0; i < 12; i++) {
      final scheduledDate = now.add(Duration(days: i - 3));
      final productName = productNames[i % productNames.length];
      await txn.insert('production_tasks', {
        'product_name': productName,
        'order_id': null,
        'recipe_id': null,
        'scheduled_date': scheduledDate.toIso8601String(),
        'quantity': 1 + random.nextInt(5),
        'status': i < 4
            ? 'completed'
            : i < 8
            ? 'in_progress'
            : 'scheduled',
        'notes': i.isEven ? 'Prep for weekend orders' : '',
      });
    }

    for (var i = 0; i < 6; i++) {
      final supplierId = supplierIds[i % supplierIds.length];
      final amountOwed = 45 + random.nextInt(240) + random.nextDouble();
      final amountPaid = i.isEven ? amountOwed * 0.6 : 0.0;
      await txn.insert('creditors', {
        'supplier_id': supplierId,
        'description': 'Supplier invoice #${3000 + i}',
        'amount_owed': amountOwed,
        'amount_paid': amountPaid,
        'due_date': now.add(Duration(days: 4 + i)).toIso8601String(),
        'status': amountPaid >= amountOwed
            ? 'paid'
            : amountPaid > 0
            ? 'partial'
            : 'unpaid',
        'notes': 'Seeded demo payable',
        'created_at': now.subtract(Duration(days: 10 + i)).toIso8601String(),
      });
    }

    await txn.insert('app_preferences', {'key': 'sidebar.favorites', 'value': 'orders,inventory,debtors'});
  });
}

Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE inventory (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      unit TEXT NOT NULL,
      quantity REAL NOT NULL DEFAULT 0,
      reorder_level REAL NOT NULL DEFAULT 0,
      category TEXT DEFAULT '',
      last_updated TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT DEFAULT '',
      email TEXT DEFAULT '',
      address TEXT DEFAULT '',
      notes TEXT DEFAULT '',
      created_at TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT DEFAULT '',
      pricing_type TEXT NOT NULL DEFAULT 'fixed',
      fixed_price REAL,
      category TEXT DEFAULT '',
      is_active INTEGER DEFAULT 1
    )
  ''');

  await db.execute('''
    CREATE TABLE product_variants (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      size_name TEXT NOT NULL,
      price REAL NOT NULL,
      FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_id INTEGER,
      order_date TEXT NOT NULL,
      due_date TEXT,
      status TEXT NOT NULL DEFAULT 'pending',
      payment_status TEXT NOT NULL DEFAULT 'unpaid',
      total_amount REAL DEFAULT 0,
      paid_amount REAL DEFAULT 0,
      notes TEXT DEFAULT '',
      FOREIGN KEY (customer_id) REFERENCES customers(id)
    )
  ''');

  await db.execute('''
    CREATE TABLE order_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER NOT NULL,
      product_id INTEGER,
      product_name TEXT NOT NULL,
      variant_name TEXT DEFAULT '',
      quantity INTEGER NOT NULL,
      unit_price REAL NOT NULL,
      line_total REAL NOT NULL,
      FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES products(id)
    )
  ''');

  await db.execute('''
    CREATE TABLE recipes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT DEFAULT '',
      instructions TEXT DEFAULT '',
      servings INTEGER,
      prep_time TEXT DEFAULT '',
      product_id INTEGER,
      estimated_cost REAL,
      FOREIGN KEY (product_id) REFERENCES products(id)
    )
  ''');

  await db.execute('''
    CREATE TABLE recipe_ingredients (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recipe_id INTEGER NOT NULL,
      inventory_item_id INTEGER,
      ingredient_name TEXT NOT NULL,
      quantity REAL NOT NULL,
      unit TEXT NOT NULL,
      cost_per_unit REAL,
      FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
      FOREIGN KEY (inventory_item_id) REFERENCES inventory(id)
    )
  ''');

  await db.execute('''
    CREATE TABLE suppliers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT DEFAULT '',
      email TEXT DEFAULT '',
      address TEXT DEFAULT '',
      notes TEXT DEFAULT ''
    )
  ''');

  await db.execute('''
    CREATE TABLE grocery_runs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      store_name TEXT DEFAULT '',
      supplier_id INTEGER,
      total_cost REAL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'draft',
      inventory_applied INTEGER NOT NULL DEFAULT 0,
      notes TEXT DEFAULT '',
      FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
    )
  ''');

  await db.execute('''
    CREATE TABLE grocery_run_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      grocery_run_id INTEGER NOT NULL,
      item_name TEXT NOT NULL,
      quantity REAL NOT NULL,
      unit TEXT NOT NULL,
      unit_price REAL NOT NULL,
      line_total REAL NOT NULL,
      inventory_item_id INTEGER,
      FOREIGN KEY (grocery_run_id) REFERENCES grocery_runs(id) ON DELETE CASCADE,
      FOREIGN KEY (inventory_item_id) REFERENCES inventory(id)
    )
  ''');

  await db.execute('''
    CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category TEXT NOT NULL,
      description TEXT NOT NULL,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      notes TEXT DEFAULT ''
    )
  ''');

  await db.execute('''
    CREATE TABLE waste_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item_name TEXT NOT NULL,
      quantity REAL NOT NULL,
      unit TEXT NOT NULL,
      reason TEXT NOT NULL,
      estimated_loss REAL,
      date TEXT NOT NULL,
      notes TEXT DEFAULT ''
    )
  ''');

  await db.execute('''
    CREATE TABLE production_tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_name TEXT NOT NULL,
      order_id INTEGER,
      recipe_id INTEGER,
      scheduled_date TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'scheduled',
      notes TEXT DEFAULT '',
      FOREIGN KEY (order_id) REFERENCES orders(id),
      FOREIGN KEY (recipe_id) REFERENCES recipes(id)
    )
  ''');

  await db.execute('''
    CREATE TABLE invoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER,
      customer_id INTEGER,
      invoice_number TEXT NOT NULL UNIQUE,
      issue_date TEXT NOT NULL,
      due_date TEXT,
      subtotal REAL DEFAULT 0,
      tax REAL DEFAULT 0,
      total REAL DEFAULT 0,
      paid_amount REAL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'draft',
      pdf_path TEXT DEFAULT '',
      notes TEXT DEFAULT '',
      FOREIGN KEY (order_id) REFERENCES orders(id),
      FOREIGN KEY (customer_id) REFERENCES customers(id)
    )
  ''');

  await db.execute('''
    CREATE TABLE creditors (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      supplier_id INTEGER,
      description TEXT NOT NULL,
      amount_owed REAL NOT NULL,
      amount_paid REAL DEFAULT 0,
      due_date TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'unpaid',
      notes TEXT DEFAULT '',
      created_at TEXT,
      FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS invoice_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_id INTEGER,
      invoice_number TEXT NOT NULL,
      action TEXT NOT NULL,
      file_path TEXT NOT NULL,
      recipient_email TEXT DEFAULT '',
      created_at TEXT NOT NULL,
      total_amount REAL,
      notes TEXT DEFAULT '',
      FOREIGN KEY (invoice_id) REFERENCES invoices(id)
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS setting_options (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      value TEXT NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 1,
      UNIQUE(type, value)
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS app_preferences (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');

  await _seedDefaultSettingOptions(db);
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoice_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        invoice_number TEXT NOT NULL,
        action TEXT NOT NULL,
        file_path TEXT NOT NULL,
        recipient_email TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        total_amount REAL,
        notes TEXT DEFAULT '',
        FOREIGN KEY (invoice_id) REFERENCES invoices(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS setting_options (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        value TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        UNIQUE(type, value)
      )
    ''');
    await _seedDefaultSettingOptions(db);
  }
  if (oldVersion < 3) {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }
  if (oldVersion < 4) {
    await db.execute("ALTER TABLE grocery_runs ADD COLUMN status TEXT NOT NULL DEFAULT 'draft'");
    await db.execute("ALTER TABLE grocery_runs ADD COLUMN inventory_applied INTEGER NOT NULL DEFAULT 0");
  }
}

Future<void> _seedDefaultSettingOptions(DatabaseExecutor db) async {
  Future<void> seed(String type, List<String> values) async {
    final existing = await db.rawQuery('SELECT COUNT(*) as cnt FROM setting_options WHERE type = ?', [type]);
    final count = (existing.first['cnt'] as int?) ?? 0;
    if (count > 0) return;
    for (var i = 0; i < values.length; i++) {
      await db.insert('setting_options', {'type': type, 'value': values[i], 'sort_order': i, 'is_active': 1});
    }
  }

  await seed('unit', const [
    'kg',
    'g',
    'lbs',
    'oz',
    'L',
    'ml',
    'cups',
    'tbsp',
    'tsp',
    'pcs',
    'dozen',
    'boxes',
    'bags',
    'bottles',
  ]);

  await seed('expense_category', const [
    'Packaging',
    'Equipment',
    'Utilities',
    'Marketing',
    'Transport',
    'Rent',
    'Insurance',
    'Maintenance',
    'Subscriptions',
    'Miscellaneous',
  ]);

  await seed('inventory_category', const [
    'Flour',
    'Sugar',
    'Dairy',
    'Baking',
    'Fruit',
    'Packaging',
    'Flavoring',
    'Other',
  ]);
}
