// ── Inventory Item ──
class InventoryItem {
  final int? id;
  final String name;
  final String unit; // kg, g, lbs, pcs, ml, L, etc.
  final double quantity;
  final double reorderLevel;
  final String? category; // e.g. Flour, Sugar, Dairy, etc.
  final DateTime? lastUpdated;

  InventoryItem({
    this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    this.reorderLevel = 0,
    this.category,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'unit': unit,
    'quantity': quantity,
    'reorder_level': reorderLevel,
    'category': category ?? '',
    'last_updated': (lastUpdated ?? DateTime.now()).toIso8601String(),
  };

  factory InventoryItem.fromMap(Map<String, dynamic> m) => InventoryItem(
    id: m['id'] as int?,
    name: m['name'] as String,
    unit: m['unit'] as String,
    quantity: (m['quantity'] as num).toDouble(),
    reorderLevel: (m['reorder_level'] as num?)?.toDouble() ?? 0,
    category: m['category'] as String?,
    lastUpdated: m['last_updated'] != null ? DateTime.tryParse(m['last_updated'] as String) : null,
  );

  InventoryItem copyWith({
    int? id,
    String? name,
    String? unit,
    double? quantity,
    double? reorderLevel,
    String? category,
    DateTime? lastUpdated,
  }) => InventoryItem(
    id: id ?? this.id,
    name: name ?? this.name,
    unit: unit ?? this.unit,
    quantity: quantity ?? this.quantity,
    reorderLevel: reorderLevel ?? this.reorderLevel,
    category: category ?? this.category,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
}

// ── Customer ──
class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final DateTime createdAt;

  Customer({this.id, required this.name, this.phone, this.email, this.address, this.notes, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'phone': phone ?? '',
    'email': email ?? '',
    'address': address ?? '',
    'notes': notes ?? '',
    'created_at': createdAt.toIso8601String(),
  };

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
    id: m['id'] as int?,
    name: m['name'] as String,
    phone: m['phone'] as String?,
    email: m['email'] as String?,
    address: m['address'] as String?,
    notes: m['notes'] as String?,
    createdAt: DateTime.tryParse(m['created_at'] as String? ?? ''),
  );

  Customer copyWith({int? id, String? name, String? phone, String? email, String? address, String? notes}) => Customer(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    notes: notes ?? this.notes,
    createdAt: createdAt,
  );
}

// ── Product / Price List ──
class Product {
  final int? id;
  final String name;
  final String? description;
  final String pricingType; // 'fixed' or 'sized'
  final double? fixedPrice;
  final String? category;
  final bool isActive;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.pricingType,
    this.fixedPrice,
    this.category,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'description': description ?? '',
    'pricing_type': pricingType,
    'fixed_price': fixedPrice,
    'category': category ?? '',
    'is_active': isActive ? 1 : 0,
  };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
    id: m['id'] as int?,
    name: m['name'] as String,
    description: m['description'] as String?,
    pricingType: m['pricing_type'] as String,
    fixedPrice: (m['fixed_price'] as num?)?.toDouble(),
    category: m['category'] as String?,
    isActive: (m['is_active'] as int?) == 1,
  );

  Product copyWith({
    int? id,
    String? name,
    String? description,
    String? pricingType,
    double? fixedPrice,
    String? category,
    bool? isActive,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    pricingType: pricingType ?? this.pricingType,
    fixedPrice: fixedPrice ?? this.fixedPrice,
    category: category ?? this.category,
    isActive: isActive ?? this.isActive,
  );
}

// ── Product Size Variant (for size-based pricing) ──
class ProductVariant {
  final int? id;
  final int productId;
  final String sizeName; // e.g. "6-inch", "8-inch", "12-inch"
  final double price;

  ProductVariant({this.id, required this.productId, required this.sizeName, required this.price});

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'product_id': productId,
    'size_name': sizeName,
    'price': price,
  };

  factory ProductVariant.fromMap(Map<String, dynamic> m) => ProductVariant(
    id: m['id'] as int?,
    productId: m['product_id'] as int,
    sizeName: m['size_name'] as String,
    price: (m['price'] as num).toDouble(),
  );
}

// ── Order ──
class Order {
  final int? id;
  final int? customerId;
  final String? customerName; // convenience, populated from join
  final DateTime orderDate;
  final DateTime? dueDate;
  final String status; // pending, in_progress, ready, delivered
  final String paymentStatus; // unpaid, partial, paid
  final double totalAmount;
  final double paidAmount;
  final String? notes;

  Order({
    this.id,
    this.customerId,
    this.customerName,
    DateTime? orderDate,
    this.dueDate,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.notes,
  }) : orderDate = orderDate ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'customer_id': customerId,
    'order_date': orderDate.toIso8601String(),
    'due_date': dueDate?.toIso8601String(),
    'status': status,
    'payment_status': paymentStatus,
    'total_amount': totalAmount,
    'paid_amount': paidAmount,
    'notes': notes ?? '',
  };

  factory Order.fromMap(Map<String, dynamic> m) => Order(
    id: m['id'] as int?,
    customerId: m['customer_id'] as int?,
    customerName: m['customer_name'] as String?,
    orderDate: DateTime.tryParse(m['order_date'] as String? ?? '') ?? DateTime.now(),
    dueDate: m['due_date'] != null ? DateTime.tryParse(m['due_date'] as String) : null,
    status: m['status'] as String? ?? 'pending',
    paymentStatus: m['payment_status'] as String? ?? 'unpaid',
    totalAmount: (m['total_amount'] as num?)?.toDouble() ?? 0,
    paidAmount: (m['paid_amount'] as num?)?.toDouble() ?? 0,
    notes: m['notes'] as String?,
  );

  Order copyWith({
    int? id,
    int? customerId,
    String? customerName,
    DateTime? orderDate,
    DateTime? dueDate,
    String? status,
    String? paymentStatus,
    double? totalAmount,
    double? paidAmount,
    String? notes,
  }) => Order(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    orderDate: orderDate ?? this.orderDate,
    dueDate: dueDate ?? this.dueDate,
    status: status ?? this.status,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    totalAmount: totalAmount ?? this.totalAmount,
    paidAmount: paidAmount ?? this.paidAmount,
    notes: notes ?? this.notes,
  );
}

// ── Order Line Item ──
class OrderItem {
  final int? id;
  final int orderId;
  final int? productId;
  final String productName;
  final String? variantName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  OrderItem({
    this.id,
    required this.orderId,
    this.productId,
    required this.productName,
    this.variantName,
    required this.quantity,
    required this.unitPrice,
    double? lineTotal,
  }) : lineTotal = lineTotal ?? (quantity * unitPrice);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'order_id': orderId,
    'product_id': productId,
    'product_name': productName,
    'variant_name': variantName ?? '',
    'quantity': quantity,
    'unit_price': unitPrice,
    'line_total': lineTotal,
  };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    id: m['id'] as int?,
    orderId: m['order_id'] as int,
    productId: m['product_id'] as int?,
    productName: m['product_name'] as String,
    variantName: m['variant_name'] as String?,
    quantity: m['quantity'] as int,
    unitPrice: (m['unit_price'] as num).toDouble(),
    lineTotal: (m['line_total'] as num?)?.toDouble(),
  );
}

// ── Recipe ──
class Recipe {
  final int? id;
  final String name;
  final String? description;
  final String? instructions;
  final int? servings;
  final String? prepTime;
  final int? productId; // link to a product
  final double? estimatedCost; // calculated from ingredients

  Recipe({
    this.id,
    required this.name,
    this.description,
    this.instructions,
    this.servings,
    this.prepTime,
    this.productId,
    this.estimatedCost,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'description': description ?? '',
    'instructions': instructions ?? '',
    'servings': servings,
    'prep_time': prepTime ?? '',
    'product_id': productId,
    'estimated_cost': estimatedCost,
  };

  factory Recipe.fromMap(Map<String, dynamic> m) => Recipe(
    id: m['id'] as int?,
    name: m['name'] as String,
    description: m['description'] as String?,
    instructions: m['instructions'] as String?,
    servings: m['servings'] as int?,
    prepTime: m['prep_time'] as String?,
    productId: m['product_id'] as int?,
    estimatedCost: (m['estimated_cost'] as num?)?.toDouble(),
  );

  Recipe copyWith({
    int? id,
    String? name,
    String? description,
    String? instructions,
    int? servings,
    String? prepTime,
    int? productId,
    double? estimatedCost,
  }) => Recipe(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    instructions: instructions ?? this.instructions,
    servings: servings ?? this.servings,
    prepTime: prepTime ?? this.prepTime,
    productId: productId ?? this.productId,
    estimatedCost: estimatedCost ?? this.estimatedCost,
  );
}

// ── Recipe Ingredient ──
class RecipeIngredient {
  final int? id;
  final int recipeId;
  final int? inventoryItemId;
  final String ingredientName;
  final double quantity;
  final String unit;
  final double? costPerUnit; // from inventory pricing

  RecipeIngredient({
    this.id,
    required this.recipeId,
    this.inventoryItemId,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    this.costPerUnit,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'recipe_id': recipeId,
    'inventory_item_id': inventoryItemId,
    'ingredient_name': ingredientName,
    'quantity': quantity,
    'unit': unit,
    'cost_per_unit': costPerUnit,
  };

  factory RecipeIngredient.fromMap(Map<String, dynamic> m) => RecipeIngredient(
    id: m['id'] as int?,
    recipeId: m['recipe_id'] as int,
    inventoryItemId: m['inventory_item_id'] as int?,
    ingredientName: m['ingredient_name'] as String,
    quantity: (m['quantity'] as num).toDouble(),
    unit: m['unit'] as String,
    costPerUnit: (m['cost_per_unit'] as num?)?.toDouble(),
  );

  RecipeIngredient copyWith({
    int? id,
    int? recipeId,
    int? inventoryItemId,
    String? ingredientName,
    double? quantity,
    String? unit,
    double? costPerUnit,
  }) => RecipeIngredient(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    inventoryItemId: inventoryItemId ?? this.inventoryItemId,
    ingredientName: ingredientName ?? this.ingredientName,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    costPerUnit: costPerUnit ?? this.costPerUnit,
  );
}

// ── Supplier ──
class Supplier {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;

  Supplier({this.id, required this.name, this.phone, this.email, this.address, this.notes});

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'phone': phone ?? '',
    'email': email ?? '',
    'address': address ?? '',
    'notes': notes ?? '',
  };

  factory Supplier.fromMap(Map<String, dynamic> m) => Supplier(
    id: m['id'] as int?,
    name: m['name'] as String,
    phone: m['phone'] as String?,
    email: m['email'] as String?,
    address: m['address'] as String?,
    notes: m['notes'] as String?,
  );

  Supplier copyWith({int? id, String? name, String? phone, String? email, String? address, String? notes}) => Supplier(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    notes: notes ?? this.notes,
  );
}

// ── Grocery Run ──
class GroceryRun {
  final int? id;
  final DateTime date;
  final String? storeName;
  final int? supplierId;
  final double totalCost;
  final String status; // draft, completed
  final bool inventoryApplied;
  final String? notes;

  GroceryRun({
    this.id,
    DateTime? date,
    this.storeName,
    this.supplierId,
    this.totalCost = 0,
    this.status = 'draft',
    this.inventoryApplied = false,
    this.notes,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'date': date.toIso8601String(),
    'store_name': storeName ?? '',
    'supplier_id': supplierId,
    'total_cost': totalCost,
    'status': status,
    'inventory_applied': inventoryApplied ? 1 : 0,
    'notes': notes ?? '',
  };

  factory GroceryRun.fromMap(Map<String, dynamic> m) => GroceryRun(
    id: m['id'] as int?,
    date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
    storeName: m['store_name'] as String?,
    supplierId: m['supplier_id'] as int?,
    totalCost: (m['total_cost'] as num?)?.toDouble() ?? 0,
    status: m['status'] as String? ?? 'draft',
    inventoryApplied: (m['inventory_applied'] as int?) == 1,
    notes: m['notes'] as String?,
  );

  GroceryRun copyWith({
    int? id,
    DateTime? date,
    String? storeName,
    int? supplierId,
    double? totalCost,
    String? status,
    bool? inventoryApplied,
    String? notes,
  }) => GroceryRun(
    id: id ?? this.id,
    date: date ?? this.date,
    storeName: storeName ?? this.storeName,
    supplierId: supplierId ?? this.supplierId,
    totalCost: totalCost ?? this.totalCost,
    status: status ?? this.status,
    inventoryApplied: inventoryApplied ?? this.inventoryApplied,
    notes: notes ?? this.notes,
  );
}

// ── Grocery Run Item ──
class GroceryRunItem {
  final int? id;
  final int groceryRunId;
  final String itemName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double lineTotal;
  final int? inventoryItemId;

  GroceryRunItem({
    this.id,
    required this.groceryRunId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    double? lineTotal,
    this.inventoryItemId,
  }) : lineTotal = lineTotal ?? (quantity * unitPrice);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'grocery_run_id': groceryRunId,
    'item_name': itemName,
    'quantity': quantity,
    'unit': unit,
    'unit_price': unitPrice,
    'line_total': lineTotal,
    'inventory_item_id': inventoryItemId,
  };

  factory GroceryRunItem.fromMap(Map<String, dynamic> m) => GroceryRunItem(
    id: m['id'] as int?,
    groceryRunId: m['grocery_run_id'] as int,
    itemName: m['item_name'] as String,
    quantity: (m['quantity'] as num).toDouble(),
    unit: m['unit'] as String,
    unitPrice: (m['unit_price'] as num).toDouble(),
    lineTotal: (m['line_total'] as num?)?.toDouble(),
    inventoryItemId: m['inventory_item_id'] as int?,
  );

  GroceryRunItem copyWith({
    int? id,
    int? groceryRunId,
    String? itemName,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? lineTotal,
    int? inventoryItemId,
  }) => GroceryRunItem(
    id: id ?? this.id,
    groceryRunId: groceryRunId ?? this.groceryRunId,
    itemName: itemName ?? this.itemName,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    unitPrice: unitPrice ?? this.unitPrice,
    lineTotal: lineTotal ?? this.lineTotal,
    inventoryItemId: inventoryItemId ?? this.inventoryItemId,
  );
}

// ── Expense ──
class Expense {
  final int? id;
  final String category; // packaging, equipment, utilities, marketing, other
  final String description;
  final double amount;
  final DateTime date;
  final String? notes;

  Expense({
    this.id,
    required this.category,
    required this.description,
    required this.amount,
    DateTime? date,
    this.notes,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'category': category,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    'notes': notes ?? '',
  };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id: m['id'] as int?,
    category: m['category'] as String,
    description: m['description'] as String,
    amount: (m['amount'] as num).toDouble(),
    date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
    notes: m['notes'] as String?,
  );

  Expense copyWith({int? id, String? category, String? description, double? amount, DateTime? date, String? notes}) =>
      Expense(
        id: id ?? this.id,
        category: category ?? this.category,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        notes: notes ?? this.notes,
      );
}

// ── Waste / Loss ──
class WasteLog {
  final int? id;
  final String itemName;
  final double quantity;
  final String unit;
  final String reason; // expired, damaged, unsold, other
  final double? estimatedLoss;
  final DateTime date;
  final String? notes;

  WasteLog({
    this.id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.reason,
    this.estimatedLoss,
    DateTime? date,
    this.notes,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'item_name': itemName,
    'quantity': quantity,
    'unit': unit,
    'reason': reason,
    'estimated_loss': estimatedLoss,
    'date': date.toIso8601String(),
    'notes': notes ?? '',
  };

  factory WasteLog.fromMap(Map<String, dynamic> m) => WasteLog(
    id: m['id'] as int?,
    itemName: m['item_name'] as String,
    quantity: (m['quantity'] as num).toDouble(),
    unit: m['unit'] as String,
    reason: m['reason'] as String,
    estimatedLoss: (m['estimated_loss'] as num?)?.toDouble(),
    date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
    notes: m['notes'] as String?,
  );

  WasteLog copyWith({
    int? id,
    String? itemName,
    double? quantity,
    String? unit,
    String? reason,
    double? estimatedLoss,
    DateTime? date,
    String? notes,
  }) => WasteLog(
    id: id ?? this.id,
    itemName: itemName ?? this.itemName,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    reason: reason ?? this.reason,
    estimatedLoss: estimatedLoss ?? this.estimatedLoss,
    date: date ?? this.date,
    notes: notes ?? this.notes,
  );
}

// ── Production Schedule ──
class ProductionTask {
  final int? id;
  final String productName;
  final int? orderId;
  final int? recipeId;
  final DateTime scheduledDate;
  final int quantity;
  final String status; // scheduled, in_progress, completed, cancelled
  final String? notes;

  ProductionTask({
    this.id,
    required this.productName,
    this.orderId,
    this.recipeId,
    required this.scheduledDate,
    required this.quantity,
    this.status = 'scheduled',
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'product_name': productName,
    'order_id': orderId,
    'recipe_id': recipeId,
    'scheduled_date': scheduledDate.toIso8601String(),
    'quantity': quantity,
    'status': status,
    'notes': notes ?? '',
  };

  factory ProductionTask.fromMap(Map<String, dynamic> m) => ProductionTask(
    id: m['id'] as int?,
    productName: m['product_name'] as String,
    orderId: m['order_id'] as int?,
    recipeId: m['recipe_id'] as int?,
    scheduledDate: DateTime.tryParse(m['scheduled_date'] as String? ?? '') ?? DateTime.now(),
    quantity: m['quantity'] as int,
    status: m['status'] as String? ?? 'scheduled',
    notes: m['notes'] as String?,
  );

  ProductionTask copyWith({
    int? id,
    String? productName,
    int? orderId,
    int? recipeId,
    DateTime? scheduledDate,
    int? quantity,
    String? status,
    String? notes,
  }) => ProductionTask(
    id: id ?? this.id,
    productName: productName ?? this.productName,
    orderId: orderId ?? this.orderId,
    recipeId: recipeId ?? this.recipeId,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    quantity: quantity ?? this.quantity,
    status: status ?? this.status,
    notes: notes ?? this.notes,
  );
}

// ── Invoice ──
class Invoice {
  final int? id;
  final int? orderId;
  final int? customerId;
  final String? customerName;
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime? dueDate;
  final double subtotal;
  final double tax;
  final double total;
  final double paidAmount;
  final String status; // draft, sent, paid, overdue, cancelled
  final String? pdfPath;
  final String? notes;

  Invoice({
    this.id,
    this.orderId,
    this.customerId,
    this.customerName,
    required this.invoiceNumber,
    DateTime? issueDate,
    this.dueDate,
    this.subtotal = 0,
    this.tax = 0,
    this.total = 0,
    this.paidAmount = 0,
    this.status = 'draft',
    this.pdfPath,
    this.notes,
  }) : issueDate = issueDate ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'order_id': orderId,
    'customer_id': customerId,
    'invoice_number': invoiceNumber,
    'issue_date': issueDate.toIso8601String(),
    'due_date': dueDate?.toIso8601String(),
    'subtotal': subtotal,
    'tax': tax,
    'total': total,
    'paid_amount': paidAmount,
    'status': status,
    'pdf_path': pdfPath ?? '',
    'notes': notes ?? '',
  };

  factory Invoice.fromMap(Map<String, dynamic> m) => Invoice(
    id: m['id'] as int?,
    orderId: m['order_id'] as int?,
    customerId: m['customer_id'] as int?,
    customerName: m['customer_name'] as String?,
    invoiceNumber: m['invoice_number'] as String,
    issueDate: DateTime.tryParse(m['issue_date'] as String? ?? '') ?? DateTime.now(),
    dueDate: m['due_date'] != null ? DateTime.tryParse(m['due_date'] as String) : null,
    subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0,
    tax: (m['tax'] as num?)?.toDouble() ?? 0,
    total: (m['total'] as num?)?.toDouble() ?? 0,
    paidAmount: (m['paid_amount'] as num?)?.toDouble() ?? 0,
    status: m['status'] as String? ?? 'draft',
    pdfPath: m['pdf_path'] as String?,
    notes: m['notes'] as String?,
  );

  Invoice copyWith({
    int? id,
    int? orderId,
    int? customerId,
    String? customerName,
    String? invoiceNumber,
    DateTime? issueDate,
    DateTime? dueDate,
    double? subtotal,
    double? tax,
    double? total,
    double? paidAmount,
    String? status,
    String? pdfPath,
    String? notes,
  }) => Invoice(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    issueDate: issueDate ?? this.issueDate,
    dueDate: dueDate ?? this.dueDate,
    subtotal: subtotal ?? this.subtotal,
    tax: tax ?? this.tax,
    total: total ?? this.total,
    paidAmount: paidAmount ?? this.paidAmount,
    status: status ?? this.status,
    pdfPath: pdfPath ?? this.pdfPath,
    notes: notes ?? this.notes,
  );

  double get balanceDue => total - paidAmount;
}

// ── Invoice History (local archive log) ──
class InvoiceHistoryEntry {
  final int? id;
  final int? invoiceId;
  final String invoiceNumber;
  final String action; // generated, regenerated, sent
  final String filePath;
  final String? recipientEmail;
  final DateTime createdAt;
  final double? totalAmount;
  final String? notes;

  InvoiceHistoryEntry({
    this.id,
    this.invoiceId,
    required this.invoiceNumber,
    required this.action,
    required this.filePath,
    this.recipientEmail,
    DateTime? createdAt,
    this.totalAmount,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'invoice_id': invoiceId,
    'invoice_number': invoiceNumber,
    'action': action,
    'file_path': filePath,
    'recipient_email': recipientEmail ?? '',
    'created_at': createdAt.toIso8601String(),
    'total_amount': totalAmount,
    'notes': notes ?? '',
  };

  factory InvoiceHistoryEntry.fromMap(Map<String, dynamic> m) => InvoiceHistoryEntry(
    id: m['id'] as int?,
    invoiceId: m['invoice_id'] as int?,
    invoiceNumber: m['invoice_number'] as String,
    action: m['action'] as String,
    filePath: m['file_path'] as String,
    recipientEmail: m['recipient_email'] as String?,
    createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
    totalAmount: (m['total_amount'] as num?)?.toDouble(),
    notes: m['notes'] as String?,
  );
}

// ── Admin Setting Option (for dropdowns/lists) ──
class SettingOption {
  final int? id;
  final String type; // unit, expense_category, waste_reason, inventory_category, product_category
  final String value;
  final int sortOrder;
  final bool isActive;

  SettingOption({this.id, required this.type, required this.value, this.sortOrder = 0, this.isActive = true});

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'type': type,
    'value': value,
    'sort_order': sortOrder,
    'is_active': isActive ? 1 : 0,
  };

  factory SettingOption.fromMap(Map<String, dynamic> m) => SettingOption(
    id: m['id'] as int?,
    type: m['type'] as String,
    value: m['value'] as String,
    sortOrder: (m['sort_order'] as int?) ?? 0,
    isActive: (m['is_active'] as int?) != 0,
  );
}

// ── Grocery Purchase Suggestion ──
class GroceryPurchaseSuggestion {
  final String itemName;
  final String unit;
  final double suggestedQuantity;
  final double currentStock;
  final double predictedUsage;
  final String reason;

  GroceryPurchaseSuggestion({
    required this.itemName,
    required this.unit,
    required this.suggestedQuantity,
    required this.currentStock,
    required this.predictedUsage,
    required this.reason,
  });
}

// ── Creditor (money bakery owes to suppliers) ──
class Creditor {
  final int? id;
  final int? supplierId;
  final String? supplierName; // from join
  final String description;
  final double amountOwed;
  final double amountPaid;
  final DateTime dueDate;
  final String status; // unpaid, partial, paid
  final String? notes;
  final DateTime createdAt;

  Creditor({
    this.id,
    this.supplierId,
    this.supplierName,
    required this.description,
    required this.amountOwed,
    this.amountPaid = 0,
    required this.dueDate,
    this.status = 'unpaid',
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'supplier_id': supplierId,
    'description': description,
    'amount_owed': amountOwed,
    'amount_paid': amountPaid,
    'due_date': dueDate.toIso8601String(),
    'status': status,
    'notes': notes ?? '',
    'created_at': createdAt.toIso8601String(),
  };

  factory Creditor.fromMap(Map<String, dynamic> m) => Creditor(
    id: m['id'] as int?,
    supplierId: m['supplier_id'] as int?,
    supplierName: m['supplier_name'] as String?,
    description: m['description'] as String,
    amountOwed: (m['amount_owed'] as num).toDouble(),
    amountPaid: (m['amount_paid'] as num?)?.toDouble() ?? 0,
    dueDate: DateTime.tryParse(m['due_date'] as String? ?? '') ?? DateTime.now(),
    status: m['status'] as String? ?? 'unpaid',
    notes: m['notes'] as String?,
    createdAt: DateTime.tryParse(m['created_at'] as String? ?? ''),
  );

  Creditor copyWith({
    int? id,
    int? supplierId,
    String? supplierName,
    String? description,
    double? amountOwed,
    double? amountPaid,
    DateTime? dueDate,
    String? status,
    String? notes,
  }) => Creditor(
    id: id ?? this.id,
    supplierId: supplierId ?? this.supplierId,
    supplierName: supplierName ?? this.supplierName,
    description: description ?? this.description,
    amountOwed: amountOwed ?? this.amountOwed,
    amountPaid: amountPaid ?? this.amountPaid,
    dueDate: dueDate ?? this.dueDate,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    createdAt: createdAt,
  );

  double get balanceDue => amountOwed - amountPaid;
}
