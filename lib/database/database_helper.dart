import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, 'home_bakery.db');
    // Ensure directory exists
    await Directory(dir.path).create(recursive: true);

    return await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: 4, onCreate: _onCreate, onUpgrade: _onUpgrade),
    );
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

    await _createInvoiceHistoryTable(db);
    await _createSettingOptionsTable(db);
    await _createAppPreferencesTable(db);
    await _seedDefaultSettingOptions(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createInvoiceHistoryTable(db);
      await _createSettingOptionsTable(db);
      await _seedDefaultSettingOptions(db);
    }
    if (oldVersion < 3) {
      await _createAppPreferencesTable(db);
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE grocery_runs ADD COLUMN status TEXT NOT NULL DEFAULT 'draft'");
      await db.execute("ALTER TABLE grocery_runs ADD COLUMN inventory_applied INTEGER NOT NULL DEFAULT 0");
    }
  }

  String _normalizeName(String value) => value.trim().toLowerCase();

  Future<InventoryItem?> findInventoryItemByName(String name) async {
    final db = await database;
    final maps = await db.query(
      'inventory',
      where: 'LOWER(TRIM(name)) = ?',
      whereArgs: [_normalizeName(name)],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return InventoryItem.fromMap(maps.first);
  }

  Future<InventoryItem> ensureInventoryItem({required String name, required String unit, String? category}) async {
    final existing = await findInventoryItemByName(name);
    if (existing != null) {
      return existing;
    }
    final id = await insertInventoryItem(
      InventoryItem(name: name.trim(), unit: unit, quantity: 0, reorderLevel: 0, category: category ?? ''),
    );
    final created = await getInventoryItemById(id);
    return created!;
  }

  Future<InventoryItem?> getInventoryItemById(int id) async {
    final db = await database;
    final maps = await db.query('inventory', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return InventoryItem.fromMap(maps.first);
  }

  Future<int> getInventoryUsageCount(int inventoryId) async {
    final db = await database;
    final recipeRefs = await db.rawQuery('SELECT COUNT(*) as cnt FROM recipe_ingredients WHERE inventory_item_id = ?', [
      inventoryId,
    ]);
    final groceryRefs = await db.rawQuery('SELECT COUNT(*) as cnt FROM grocery_run_items WHERE inventory_item_id = ?', [
      inventoryId,
    ]);
    final a = (recipeRefs.first['cnt'] as int?) ?? 0;
    final b = (groceryRefs.first['cnt'] as int?) ?? 0;
    return a + b;
  }

  Future<Product?> findProductByName(String name) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'LOWER(TRIM(name)) = ?',
      whereArgs: [_normalizeName(name)],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<Product> ensureRecipeProduct(String recipeName) async {
    final existing = await findProductByName(recipeName);
    if (existing != null) return existing;
    final id = await insertProduct(
      Product(name: recipeName.trim(), pricingType: 'fixed', fixedPrice: 0, category: 'Other', isActive: true),
    );
    final list = await getProducts();
    return list.firstWhere((p) => p.id == id);
  }

  Future<List<Product>> getProductsBackedByRecipes() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT p.*
      FROM products p
      INNER JOIN recipes r ON r.product_id = p.id
      WHERE p.is_active = 1
      GROUP BY p.id
      ORDER BY p.name ASC
    ''');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<int> saveRecipeWithRelations({
    required Recipe recipe,
    required List<RecipeIngredient> ingredients,
    int? existingRecipeId,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      Product product;
      if (recipe.productId != null) {
        final p = await txn.query('products', where: 'id = ?', whereArgs: [recipe.productId], limit: 1);
        if (p.isNotEmpty) {
          product = Product.fromMap(p.first);
        } else {
          final id = await txn.insert(
            'products',
            Product(name: recipe.name.trim(), pricingType: 'fixed', fixedPrice: 0, category: 'Other').toMap(),
          );
          final created = await txn.query('products', where: 'id = ?', whereArgs: [id], limit: 1);
          product = Product.fromMap(created.first);
        }
      } else {
        final existingProduct = await txn.query(
          'products',
          where: 'LOWER(TRIM(name)) = ?',
          whereArgs: [_normalizeName(recipe.name)],
          limit: 1,
        );
        if (existingProduct.isNotEmpty) {
          product = Product.fromMap(existingProduct.first);
        } else {
          final id = await txn.insert(
            'products',
            Product(name: recipe.name.trim(), pricingType: 'fixed', fixedPrice: 0, category: 'Other').toMap(),
          );
          final created = await txn.query('products', where: 'id = ?', whereArgs: [id], limit: 1);
          product = Product.fromMap(created.first);
        }
      }

      final recipeForSave = recipe.copyWith(productId: product.id);
      final recipeId = existingRecipeId ?? await txn.insert('recipes', recipeForSave.toMap());
      if (existingRecipeId != null) {
        await txn.update(
          'recipes',
          recipeForSave.copyWith(id: recipeId).toMap(),
          where: 'id = ?',
          whereArgs: [recipeId],
        );
      }

      await txn.delete('recipe_ingredients', where: 'recipe_id = ?', whereArgs: [recipeId]);

      double estimated = 0;
      for (final ing in ingredients) {
        InventoryItem inventory;
        if (ing.inventoryItemId != null) {
          final map = await txn.query('inventory', where: 'id = ?', whereArgs: [ing.inventoryItemId], limit: 1);
          if (map.isEmpty) {
            throw Exception('Inventory item not found for ingredient ${ing.ingredientName}');
          }
          inventory = InventoryItem.fromMap(map.first);
        } else {
          final existingInv = await txn.query(
            'inventory',
            where: 'LOWER(TRIM(name)) = ?',
            whereArgs: [_normalizeName(ing.ingredientName)],
            limit: 1,
          );
          if (existingInv.isNotEmpty) {
            inventory = InventoryItem.fromMap(existingInv.first);
          } else {
            final invId = await txn.insert(
              'inventory',
              InventoryItem(name: ing.ingredientName.trim(), unit: ing.unit, quantity: 0, reorderLevel: 0).toMap(),
            );
            final invMap = await txn.query('inventory', where: 'id = ?', whereArgs: [invId], limit: 1);
            inventory = InventoryItem.fromMap(invMap.first);
          }
        }

        if (inventory.unit != ing.unit) {
          throw Exception('Unit mismatch for ingredient ${ing.ingredientName}: inventory uses ${inventory.unit}.');
        }

        await txn.insert(
          'recipe_ingredients',
          ing.copyWith(recipeId: recipeId, inventoryItemId: inventory.id, ingredientName: inventory.name).toMap(),
        );
        estimated += (ing.costPerUnit ?? 0) * ing.quantity;
      }

      await txn.update('recipes', {'estimated_cost': estimated}, where: 'id = ?', whereArgs: [recipeId]);
      return recipeId;
    });
  }

  Future<int> saveGroceryRunWithItems({
    required GroceryRun run,
    required List<GroceryRunItem> items,
    bool complete = false,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      final runId =
          run.id ?? await txn.insert('grocery_runs', run.copyWith(status: 'draft', inventoryApplied: false).toMap());
      if (run.id != null) {
        await txn.update(
          'grocery_runs',
          run.copyWith(status: run.status.isEmpty ? 'draft' : run.status).toMap(),
          where: 'id = ?',
          whereArgs: [runId],
        );
        await txn.delete('grocery_run_items', where: 'grocery_run_id = ?', whereArgs: [runId]);
      }

      double total = 0;
      for (final item in items) {
        InventoryItem inventory;
        if (item.inventoryItemId != null) {
          final map = await txn.query('inventory', where: 'id = ?', whereArgs: [item.inventoryItemId], limit: 1);
          if (map.isEmpty) {
            throw Exception('Inventory item not found for ${item.itemName}');
          }
          inventory = InventoryItem.fromMap(map.first);
        } else {
          final existingInv = await txn.query(
            'inventory',
            where: 'LOWER(TRIM(name)) = ?',
            whereArgs: [_normalizeName(item.itemName)],
            limit: 1,
          );
          if (existingInv.isNotEmpty) {
            inventory = InventoryItem.fromMap(existingInv.first);
          } else {
            final invId = await txn.insert(
              'inventory',
              InventoryItem(name: item.itemName.trim(), unit: item.unit, quantity: 0, reorderLevel: 0).toMap(),
            );
            final invMap = await txn.query('inventory', where: 'id = ?', whereArgs: [invId], limit: 1);
            inventory = InventoryItem.fromMap(invMap.first);
          }
        }

        if (inventory.unit != item.unit) {
          throw Exception('Unit mismatch for ${item.itemName}: inventory uses ${inventory.unit}.');
        }

        await txn.insert(
          'grocery_run_items',
          item.copyWith(groceryRunId: runId, inventoryItemId: inventory.id, itemName: inventory.name).toMap(),
        );
        total += item.lineTotal;
      }

      await txn.update(
        'grocery_runs',
        run.copyWith(id: runId, totalCost: total, status: 'draft', inventoryApplied: false).toMap(),
        where: 'id = ?',
        whereArgs: [runId],
      );

      if (complete) {
        await _completeGroceryRunTxn(txn, runId);
      }
      return runId;
    });
  }

  Future<void> completeGroceryRun(int runId) async {
    final db = await database;
    await db.transaction((txn) async {
      await _completeGroceryRunTxn(txn, runId);
    });
  }

  Future<void> _completeGroceryRunTxn(Transaction txn, int runId) async {
    final runMap = await txn.query('grocery_runs', where: 'id = ?', whereArgs: [runId], limit: 1);
    if (runMap.isEmpty) return;
    final alreadyApplied = (runMap.first['inventory_applied'] as int?) == 1;
    if (alreadyApplied) return;

    final items = await txn.query('grocery_run_items', where: 'grocery_run_id = ?', whereArgs: [runId]);
    for (final m in items) {
      final item = GroceryRunItem.fromMap(m);
      if (item.inventoryItemId == null) continue;
      final invMap = await txn.query('inventory', where: 'id = ?', whereArgs: [item.inventoryItemId], limit: 1);
      if (invMap.isEmpty) continue;
      final inv = InventoryItem.fromMap(invMap.first);
      await txn.update(
        'inventory',
        inv.copyWith(quantity: inv.quantity + item.quantity, lastUpdated: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [inv.id],
      );
    }
    await txn.update(
      'grocery_runs',
      {'status': 'completed', 'inventory_applied': 1},
      where: 'id = ?',
      whereArgs: [runId],
    );
  }

  Future<void> consumeInventoryForDeliveredOrder(int orderId) async {
    final db = await database;
    await db.transaction((txn) async {
      final items = await txn.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
      for (final row in items) {
        final orderItem = OrderItem.fromMap(row);
        if (orderItem.productId == null) continue;
        final recipes = await txn.query('recipes', where: 'product_id = ?', whereArgs: [orderItem.productId], limit: 1);
        if (recipes.isEmpty) continue;
        final recipeId = recipes.first['id'] as int;
        final ingredients = await txn.query('recipe_ingredients', where: 'recipe_id = ?', whereArgs: [recipeId]);
        for (final ingRow in ingredients) {
          final ing = RecipeIngredient.fromMap(ingRow);
          if (ing.inventoryItemId == null) continue;
          final invMap = await txn.query('inventory', where: 'id = ?', whereArgs: [ing.inventoryItemId], limit: 1);
          if (invMap.isEmpty) continue;
          final inv = InventoryItem.fromMap(invMap.first);
          final consume = ing.quantity * orderItem.quantity;
          final nextQty = (inv.quantity - consume).clamp(0, double.infinity).toDouble();
          await txn.update(
            'inventory',
            inv.copyWith(quantity: nextQty, lastUpdated: DateTime.now()).toMap(),
            where: 'id = ?',
            whereArgs: [inv.id],
          );
        }
      }
    });
  }

  Future<void> applyWasteToInventory({WasteLog? previous, required WasteLog current}) async {
    final db = await database;
    await db.transaction((txn) async {
      Future<void> revert(WasteLog w) async {
        final map = await txn.query(
          'inventory',
          where: 'LOWER(TRIM(name)) = ?',
          whereArgs: [_normalizeName(w.itemName)],
          limit: 1,
        );
        if (map.isEmpty) return;
        final inv = InventoryItem.fromMap(map.first);
        await txn.update(
          'inventory',
          inv.copyWith(quantity: inv.quantity + w.quantity, lastUpdated: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [inv.id],
        );
      }

      Future<void> apply(WasteLog w) async {
        final map = await txn.query(
          'inventory',
          where: 'LOWER(TRIM(name)) = ?',
          whereArgs: [_normalizeName(w.itemName)],
          limit: 1,
        );
        if (map.isEmpty) return;
        final inv = InventoryItem.fromMap(map.first);
        final nextQty = (inv.quantity - w.quantity).clamp(0, double.infinity).toDouble();
        await txn.update(
          'inventory',
          inv.copyWith(quantity: nextQty, lastUpdated: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [inv.id],
        );
      }

      if (previous != null) await revert(previous);
      await apply(current);
    });
  }

  Future<void> _createInvoiceHistoryTable(Database db) async {
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
  }

  Future<void> _createSettingOptionsTable(Database db) async {
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
  }

  Future<void> _createAppPreferencesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedDefaultSettingOptions(Database db) async {
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
      'Subscriptions',
      'Other',
    ]);

    await seed('waste_reason', const ['Expired', 'Damaged', 'Unsold', 'Over-produced', 'Quality Issue', 'Other']);

    await seed('inventory_category', const [
      'Flour & Grains',
      'Sugar & Sweeteners',
      'Dairy',
      'Eggs',
      'Fats & Oils',
      'Leavening',
      'Flavoring & Spices',
      'Chocolate & Cocoa',
      'Fruits & Nuts',
      'Decorations',
      'Packaging',
      'Other',
    ]);

    await seed('product_category', const [
      'Cakes',
      'Cupcakes',
      'Cookies',
      'Bread',
      'Pastries',
      'Pies & Tarts',
      'Brownies & Bars',
      'Special Orders',
      'Other',
    ]);
  }

  // ═══════════════════════════════════════════════
  //  INVENTORY
  // ═══════════════════════════════════════════════

  Future<int> insertInventoryItem(InventoryItem item) async {
    final db = await database;
    return await db.insert('inventory', item.toMap());
  }

  Future<List<InventoryItem>> getInventoryItems() async {
    final db = await database;
    final maps = await db.query('inventory', orderBy: 'name ASC');
    return maps.map((m) => InventoryItem.fromMap(m)).toList();
  }

  Future<int> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    return await db.update('inventory', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteInventoryItem(int id) async {
    final db = await database;
    return await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<InventoryItem>> getLowStockItems() async {
    final db = await database;
    final maps = await db.query(
      'inventory',
      where: 'quantity <= 0 OR (reorder_level > 0 AND quantity <= reorder_level)',
    );
    return maps.map((m) => InventoryItem.fromMap(m)).toList();
  }

  // ═══════════════════════════════════════════════
  //  CUSTOMERS
  // ═══════════════════════════════════════════════

  Future<int> insertCustomer(Customer c) async {
    final db = await database;
    return await db.insert('customers', c.toMap());
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'name ASC');
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<int> updateCustomer(Customer c) async {
    final db = await database;
    return await db.update('customers', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════
  //  PRODUCTS / PRICE LIST
  // ═══════════════════════════════════════════════

  Future<int> insertProduct(Product p) async {
    final db = await database;
    return await db.insert('products', p.toMap());
  }

  Future<List<Product>> getProducts({bool activeOnly = false}) async {
    final db = await database;
    final maps = await db.query('products', where: activeOnly ? 'is_active = 1' : null, orderBy: 'name ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<int> updateProduct(Product p) async {
    final db = await database;
    return await db.update('products', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Variants
  Future<int> insertVariant(ProductVariant v) async {
    final db = await database;
    return await db.insert('product_variants', v.toMap());
  }

  Future<List<ProductVariant>> getVariantsForProduct(int productId) async {
    final db = await database;
    final maps = await db.query('product_variants', where: 'product_id = ?', whereArgs: [productId]);
    return maps.map((m) => ProductVariant.fromMap(m)).toList();
  }

  Future<int> deleteVariant(int id) async {
    final db = await database;
    return await db.delete('product_variants', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteVariantsForProduct(int productId) async {
    final db = await database;
    await db.delete('product_variants', where: 'product_id = ?', whereArgs: [productId]);
  }

  // ═══════════════════════════════════════════════
  //  ORDERS
  // ═══════════════════════════════════════════════

  Future<int> insertOrder(Order o) async {
    final db = await database;
    return await db.insert('orders', o.toMap());
  }

  Future<List<Order>> getOrders({String? statusFilter}) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT o.*, c.name as customer_name
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      ${statusFilter != null ? "WHERE o.status = ?" : ""}
      ORDER BY o.order_date DESC
    ''', statusFilter != null ? [statusFilter] : []);
    return maps.map((m) => Order.fromMap(m)).toList();
  }

  Future<int> updateOrder(Order o) async {
    final db = await database;
    return await db.update('orders', o.toMap(), where: 'id = ?', whereArgs: [o.id]);
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;
    await db.delete('order_items', where: 'order_id = ?', whereArgs: [id]);
    return await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  // Order Items
  Future<int> insertOrderItem(OrderItem item) async {
    final db = await database;
    return await db.insert('order_items', item.toMap());
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await database;
    final maps = await db.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
    return maps.map((m) => OrderItem.fromMap(m)).toList();
  }

  Future<void> deleteOrderItems(int orderId) async {
    final db = await database;
    await db.delete('order_items', where: 'order_id = ?', whereArgs: [orderId]);
  }

  // ═══════════════════════════════════════════════
  //  RECIPES
  // ═══════════════════════════════════════════════

  Future<int> insertRecipe(Recipe r) async {
    final db = await database;
    return await db.insert('recipes', r.toMap());
  }

  Future<List<Recipe>> getRecipes() async {
    final db = await database;
    final maps = await db.query('recipes', orderBy: 'name ASC');
    return maps.map((m) => Recipe.fromMap(m)).toList();
  }

  Future<int> updateRecipe(Recipe r) async {
    final db = await database;
    return await db.update('recipes', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  }

  Future<int> deleteRecipe(int id) async {
    final db = await database;
    await db.delete('recipe_ingredients', where: 'recipe_id = ?', whereArgs: [id]);
    return await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  // Recipe Ingredients
  Future<int> insertRecipeIngredient(RecipeIngredient ri) async {
    final db = await database;
    return await db.insert('recipe_ingredients', ri.toMap());
  }

  Future<List<RecipeIngredient>> getRecipeIngredients(int recipeId) async {
    final db = await database;
    final maps = await db.query('recipe_ingredients', where: 'recipe_id = ?', whereArgs: [recipeId]);
    return maps.map((m) => RecipeIngredient.fromMap(m)).toList();
  }

  Future<void> deleteRecipeIngredients(int recipeId) async {
    final db = await database;
    await db.delete('recipe_ingredients', where: 'recipe_id = ?', whereArgs: [recipeId]);
  }

  // ═══════════════════════════════════════════════
  //  SUPPLIERS
  // ═══════════════════════════════════════════════

  Future<int> insertSupplier(Supplier s) async {
    final db = await database;
    return await db.insert('suppliers', s.toMap());
  }

  Future<List<Supplier>> getSuppliers() async {
    final db = await database;
    final maps = await db.query('suppliers', orderBy: 'name ASC');
    return maps.map((m) => Supplier.fromMap(m)).toList();
  }

  Future<int> updateSupplier(Supplier s) async {
    final db = await database;
    return await db.update('suppliers', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════
  //  GROCERY RUNS
  // ═══════════════════════════════════════════════

  Future<int> insertGroceryRun(GroceryRun gr) async {
    final db = await database;
    return await db.insert('grocery_runs', gr.toMap());
  }

  Future<List<GroceryRun>> getGroceryRuns() async {
    final db = await database;
    final maps = await db.query('grocery_runs', orderBy: 'date DESC');
    return maps.map((m) => GroceryRun.fromMap(m)).toList();
  }

  Future<int> updateGroceryRun(GroceryRun gr) async {
    final db = await database;
    return await db.update('grocery_runs', gr.toMap(), where: 'id = ?', whereArgs: [gr.id]);
  }

  Future<int> deleteGroceryRun(int id) async {
    final db = await database;
    await db.delete('grocery_run_items', where: 'grocery_run_id = ?', whereArgs: [id]);
    return await db.delete('grocery_runs', where: 'id = ?', whereArgs: [id]);
  }

  // Grocery Run Items
  Future<int> insertGroceryRunItem(GroceryRunItem item) async {
    final db = await database;
    return await db.insert('grocery_run_items', item.toMap());
  }

  Future<List<GroceryRunItem>> getGroceryRunItems(int groceryRunId) async {
    final db = await database;
    final maps = await db.query('grocery_run_items', where: 'grocery_run_id = ?', whereArgs: [groceryRunId]);
    return maps.map((m) => GroceryRunItem.fromMap(m)).toList();
  }

  Future<void> deleteGroceryRunItems(int groceryRunId) async {
    final db = await database;
    await db.delete('grocery_run_items', where: 'grocery_run_id = ?', whereArgs: [groceryRunId]);
  }

  // ═══════════════════════════════════════════════
  //  EXPENSES
  // ═══════════════════════════════════════════════

  Future<int> insertExpense(Expense e) async {
    final db = await database;
    return await db.insert('expenses', e.toMap());
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final maps = await db.query('expenses', orderBy: 'date DESC');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<int> updateExpense(Expense e) async {
    final db = await database;
    return await db.update('expenses', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getExpensesBetween(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  // ═══════════════════════════════════════════════
  //  WASTE LOG
  // ═══════════════════════════════════════════════

  Future<int> insertWasteLog(WasteLog w) async {
    final db = await database;
    return await db.insert('waste_log', w.toMap());
  }

  Future<List<WasteLog>> getWasteLogs() async {
    final db = await database;
    final maps = await db.query('waste_log', orderBy: 'date DESC');
    return maps.map((m) => WasteLog.fromMap(m)).toList();
  }

  Future<int> updateWasteLog(WasteLog w) async {
    final db = await database;
    return await db.update('waste_log', w.toMap(), where: 'id = ?', whereArgs: [w.id]);
  }

  Future<int> deleteWasteLog(int id) async {
    final db = await database;
    return await db.delete('waste_log', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════
  //  PRODUCTION TASKS
  // ═══════════════════════════════════════════════

  Future<int> insertProductionTask(ProductionTask t) async {
    final db = await database;
    return await db.insert('production_tasks', t.toMap());
  }

  Future<List<ProductionTask>> getProductionTasks({DateTime? date, String? status}) async {
    final db = await database;
    String where = '';
    List<dynamic> args = [];
    if (date != null) {
      final dayStr = date.toIso8601String().substring(0, 10);
      where = "scheduled_date LIKE '$dayStr%'";
    }
    if (status != null) {
      where += where.isNotEmpty ? ' AND ' : '';
      where += 'status = ?';
      args.add(status);
    }
    final maps = await db.query(
      'production_tasks',
      where: where.isNotEmpty ? where : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'scheduled_date ASC',
    );
    return maps.map((m) => ProductionTask.fromMap(m)).toList();
  }

  Future<int> updateProductionTask(ProductionTask t) async {
    final db = await database;
    return await db.update('production_tasks', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<int> deleteProductionTask(int id) async {
    final db = await database;
    return await db.delete('production_tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════
  //  ACCOUNTING / REPORTS
  // ═══════════════════════════════════════════════

  Future<double> getTotalSalesBetween(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) as total
      FROM orders
      WHERE order_date >= ? AND order_date <= ?
        AND status != 'cancelled'
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalPaidBetween(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(paid_amount), 0) as total
      FROM orders
      WHERE order_date >= ? AND order_date <= ?
        AND status != 'cancelled'
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalGrocerySpendBetween(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_cost), 0) as total
      FROM grocery_runs
      WHERE date >= ? AND date <= ?
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalExpensesBetween(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM expenses
      WHERE date >= ? AND date <= ?
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalWasteLossBetween(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(estimated_loss), 0) as total
      FROM waste_log
      WHERE date >= ? AND date <= ?
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<Map<String, double>> getExpenseBreakdownBetween(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT category, COALESCE(SUM(amount), 0) as total
      FROM expenses
      WHERE date >= ? AND date <= ?
      GROUP BY category
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return {for (var r in result) r['category'] as String: (r['total'] as num).toDouble()};
  }

  Future<int> getOrderCountBetween(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as cnt
      FROM orders
      WHERE order_date >= ? AND order_date <= ?
        AND status != 'cancelled'
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // Dashboard quick stats
  Future<int> getPendingOrderCount() async {
    final db = await database;
    final result = await db.rawQuery("SELECT COUNT(*) as cnt FROM orders WHERE status IN ('pending','in_progress')");
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<int> getTodayProductionCount() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM production_tasks WHERE scheduled_date LIKE '$today%' AND status != 'completed'",
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ═══════════════════════════════════════════════
  //  INVOICES
  // ═══════════════════════════════════════════════

  Future<int> insertInvoice(Invoice inv) async {
    final db = await database;
    return await db.insert('invoices', inv.toMap());
  }

  Future<List<Invoice>> getInvoices({String? statusFilter}) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT i.*, c.name as customer_name
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      ${statusFilter != null ? "WHERE i.status = ?" : ""}
      ORDER BY i.issue_date DESC
    ''', statusFilter != null ? [statusFilter] : []);
    return maps.map((m) => Invoice.fromMap(m)).toList();
  }

  Future<int> updateInvoice(Invoice inv) async {
    final db = await database;
    return await db.update('invoices', inv.toMap(), where: 'id = ?', whereArgs: [inv.id]);
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;
    return await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> generateInvoiceNumber() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM invoices');
    final count = ((result.first['cnt'] as int?) ?? 0) + 1;
    final year = DateTime.now().year;
    return 'INV-$year-${count.toString().padLeft(4, '0')}';
  }

  // ═══════════════════════════════════════════════
  //  DEBTORS (customers who owe money — derived from invoices)
  // ═══════════════════════════════════════════════

  Future<List<Invoice>> getDebtors() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT i.*, c.name as customer_name
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      WHERE i.status IN ('sent', 'overdue')
        AND i.paid_amount < i.total
      ORDER BY i.due_date ASC
    ''');
    return maps.map((m) => Invoice.fromMap(m)).toList();
  }

  Future<double> getTotalDebtorsBalance() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total - paid_amount), 0) as total
      FROM invoices
      WHERE status IN ('sent', 'overdue')
        AND paid_amount < total
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // ═══════════════════════════════════════════════
  //  CREDITORS (money bakery owes to suppliers)
  // ═══════════════════════════════════════════════

  Future<int> insertCreditor(Creditor c) async {
    final db = await database;
    return await db.insert('creditors', c.toMap());
  }

  Future<List<Creditor>> getCreditors({String? statusFilter}) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT cr.*, s.name as supplier_name
      FROM creditors cr
      LEFT JOIN suppliers s ON cr.supplier_id = s.id
      ${statusFilter != null ? "WHERE cr.status = ?" : ""}
      ORDER BY cr.due_date ASC
    ''', statusFilter != null ? [statusFilter] : []);
    return maps.map((m) => Creditor.fromMap(m)).toList();
  }

  Future<int> updateCreditor(Creditor c) async {
    final db = await database;
    return await db.update('creditors', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> deleteCreditor(int id) async {
    final db = await database;
    return await db.delete('creditors', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalCreditorsBalance() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_owed - amount_paid), 0) as total
      FROM creditors
      WHERE status IN ('unpaid', 'partial')
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // ═══════════════════════════════════════════════
  //  INVOICE HISTORY
  // ═══════════════════════════════════════════════

  Future<int> insertInvoiceHistory(InvoiceHistoryEntry entry) async {
    final db = await database;
    return await db.insert('invoice_history', entry.toMap());
  }

  Future<List<InvoiceHistoryEntry>> getInvoiceHistory({int? invoiceId}) async {
    final db = await database;
    final maps = await db.query(
      'invoice_history',
      where: invoiceId != null ? 'invoice_id = ?' : null,
      whereArgs: invoiceId != null ? [invoiceId] : null,
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => InvoiceHistoryEntry.fromMap(m)).toList();
  }

  // ═══════════════════════════════════════════════
  //  ADMIN SETTINGS (dropdown options)
  // ═══════════════════════════════════════════════

  Future<List<SettingOption>> getSettingOptions(String type) async {
    final db = await database;
    final maps = await db.query(
      'setting_options',
      where: 'type = ? AND is_active = 1',
      whereArgs: [type],
      orderBy: 'sort_order ASC, value ASC',
    );
    return maps.map((m) => SettingOption.fromMap(m)).toList();
  }

  Future<List<String>> getSettingValues(String type, {List<String> fallback = const []}) async {
    final options = await getSettingOptions(type);
    if (options.isEmpty) return fallback;
    return options.map((e) => e.value).toList();
  }

  Future<int> insertSettingOption(SettingOption option) async {
    final db = await database;
    return await db.insert('setting_options', option.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateSettingOption(SettingOption option) async {
    final db = await database;
    return await db.update('setting_options', option.toMap(), where: 'id = ?', whereArgs: [option.id]);
  }

  Future<int> deleteSettingOption(int id) async {
    final db = await database;
    return await db.delete('setting_options', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════
  //  APP PREFERENCES (theme, favorites, ui state)
  // ═══════════════════════════════════════════════

  Future<String?> getPreference(String key) async {
    final db = await database;
    final maps = await db.query('app_preferences', where: 'key = ?', whereArgs: [key], limit: 1);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  Future<void> setPreference(String key, String value) async {
    final db = await database;
    await db.insert('app_preferences', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
