import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class PriceListScreen extends StatefulWidget {
  const PriceListScreen({super.key});

  @override
  State<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  final _db = DatabaseHelper();
  List<Product> _products = [];
  Map<int, List<ProductVariant>> _variants = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final products = await _db.getProducts();
    final variants = <int, List<ProductVariant>>{};
    for (final p in products) {
      if (p.pricingType == 'sized' && p.id != null) {
        variants[p.id!] = await _db.getVariantsForProduct(p.id!);
      }
    }
    setState(() {
      _products = products;
      _variants = variants;
    });
  }

  Future<void> _showForm([Product? existing]) async {
    final categories = await _db.getSettingValues('product_category', fallback: kProductCategories);
    if (!mounted) return;
    final result = await showDialog<_ProductFormResult>(
      context: context,
      builder: (ctx) => _ProductForm(
        existing: existing,
        existingVariants: existing != null ? _variants[existing.id] ?? [] : [],
        categories: categories,
      ),
    );
    if (result != null) {
      if (existing != null) {
        await _db.updateProduct(result.product);
        await _db.deleteVariantsForProduct(existing.id!);
        for (final v in result.variants) {
          await _db.insertVariant(ProductVariant(productId: existing.id!, sizeName: v.sizeName, price: v.price));
        }
      } else {
        final id = await _db.insertProduct(result.product);
        for (final v in result.variants) {
          await _db.insertVariant(ProductVariant(productId: id, sizeName: v.sizeName, price: v.price));
        }
      }
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Price List',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Product'),
            ),
          ],
        ),
        Expanded(
          child: _products.isEmpty
              ? const EmptyState(icon: Icons.sell_outlined, message: 'No products yet.\nAdd your baked goods!')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _products.length,
                  itemBuilder: (ctx, i) {
                    final p = _products[i];
                    final vars = _variants[p.id] ?? [];
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              p.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(width: 8),
                                            if (!p.isActive)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: BakeryTheme.textSecondary.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('Inactive', style: TextStyle(fontSize: 11)),
                                              ),
                                          ],
                                        ),
                                        if (p.category != null && p.category!.isNotEmpty)
                                          Text(p.category!, style: Theme.of(context).textTheme.bodyMedium),
                                      ],
                                    ),
                                  ),
                                  if (p.pricingType == 'fixed' && p.fixedPrice != null)
                                    Text(
                                      formatCurrency(p.fixedPrice!),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: BakeryTheme.primaryDark,
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () => _showForm(p),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    onPressed: () async {
                                      if (await confirmDelete(context, p.name)) {
                                        await _db.deleteProduct(p.id!);
                                        _load();
                                      }
                                    },
                                  ),
                                ],
                              ),
                              if (p.description != null && p.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(p.description!, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                              if (vars.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: vars
                                      .map(
                                        (v) => Chip(
                                          label: Text('${v.sizeName}: ${formatCurrency(v.price)}'),
                                          backgroundColor: BakeryTheme.accent.withValues(alpha: 0.3),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
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
}

class _ProductFormResult {
  final Product product;
  final List<ProductVariant> variants;
  _ProductFormResult(this.product, this.variants);
}

class _ProductForm extends StatefulWidget {
  final Product? existing;
  final List<ProductVariant> existingVariants;
  final List<String> categories;
  const _ProductForm({this.existing, required this.existingVariants, required this.categories});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late String _pricingType;
  late String _category;
  late bool _isActive;
  final List<_VarLine> _variants = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _price = TextEditingController(text: e?.fixedPrice != null ? e!.fixedPrice!.toStringAsFixed(2) : '');
    _pricingType = e?.pricingType ?? 'fixed';
    _category = e?.category ?? widget.categories.first;
    if (!widget.categories.contains(_category)) _category = widget.categories.first;
    _isActive = e?.isActive ?? true;
    _variants.addAll(widget.existingVariants.map((v) => _VarLine(size: v.sizeName, price: v.price.toStringAsFixed(2))));
  }

  @override
  Widget build(BuildContext context) {
    final oldPrice = widget.existing?.fixedPrice;
    final newPrice = _pricingType == 'fixed' ? double.tryParse(_price.text) : null;
    final priceChanged = oldPrice != null && newPrice != null && (oldPrice - newPrice).abs() > 0.001;

    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Product' : 'Add Product'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (priceChanged)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    border: Border.all(color: const Color(0xFFFFEBCD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 20, color: Color(0xFF856404)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Price Change',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF856404),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Only new orders will use the new price. Existing orders will keep their original prices.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF856404)),
                      ),
                    ],
                  ),
                ),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _desc,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _pricingType,
                      decoration: const InputDecoration(labelText: 'Pricing Type'),
                      items: const [
                        DropdownMenuItem(value: 'fixed', child: Text('Fixed Price')),
                        DropdownMenuItem(value: 'sized', child: Text('Size-Based')),
                      ],
                      onChanged: (v) => setState(() => _pricingType = v!),
                    ),
                    const SizedBox(height: 12),
                    if (_pricingType == 'fixed')
                      TextFormField(
                        controller: _price,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => _pricingType == 'fixed' && (v == null || double.tryParse(v) == null)
                            ? 'Enter a price'
                            : null,
                      ),
                    if (_pricingType == 'sized') ...[
                      const Text('Size Variants', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._variants.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final v = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: v.size,
                                  decoration: const InputDecoration(labelText: 'Size', hintText: 'e.g. 6-inch'),
                                  onChanged: (val) => v.size = val,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: v.price,
                                  decoration: const InputDecoration(labelText: 'Price'),
                                  onChanged: (val) => v.price = val,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _variants.removeAt(idx)),
                              ),
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: () => setState(() => _variants.add(_VarLine())),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Size'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
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
            if (_formKey.currentState!.validate()) {
              final product = Product(
                id: widget.existing?.id,
                name: _name.text.trim(),
                description: _desc.text.trim(),
                pricingType: _pricingType,
                fixedPrice: _pricingType == 'fixed' ? double.tryParse(_price.text) : null,
                category: _category,
                isActive: _isActive,
              );
              final vars = _variants
                  .where((v) => v.size.isNotEmpty)
                  .map(
                    (v) => ProductVariant(
                      productId: widget.existing?.id ?? 0,
                      sizeName: v.size,
                      price: double.tryParse(v.price) ?? 0,
                    ),
                  )
                  .toList();
              Navigator.pop(context, _ProductFormResult(product, vars));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _VarLine {
  String size;
  String price;
  _VarLine({this.size = '', this.price = ''});
}
