import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final _db = DatabaseHelper();
  List<Recipe> _recipes = [];
  List<String> _unitOptions = kUnits;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final recipes = await _db.getRecipes();
    final units = await _db.getSettingValues('unit', fallback: kUnits);
    setState(() {
      _recipes = recipes;
      _unitOptions = units;
    });
  }

  Future<void> _showForm([Recipe? existing]) async {
    final inventoryItems = await _db.getInventoryItems();
    final result = await showDialog<_RecipeFormResult>(
      context: context,
      builder: (ctx) =>
          _RecipeForm(existing: existing, db: _db, unitOptions: _unitOptions, inventoryItems: inventoryItems),
    );
    if (result != null) {
      await _db.saveRecipeWithRelations(
        recipe: result.recipe,
        ingredients: result.ingredients,
        existingRecipeId: existing?.id,
      );
      _load();
    }
  }

  Future<void> _viewRecipe(Recipe recipe) async {
    final ingredients = await _db.getRecipeIngredients(recipe.id!);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(recipe.name),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (recipe.description != null && recipe.description!.isNotEmpty) ...[
                  Text(recipe.description!, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    if (recipe.servings != null) _infoChip('Servings: ${recipe.servings}'),
                    if (recipe.prepTime != null && recipe.prepTime!.isNotEmpty) _infoChip('Prep: ${recipe.prepTime}'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...ingredients.map(
                  (ing) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 6, color: BakeryTheme.primary),
                        const SizedBox(width: 8),
                        Text('${ing.quantity} ${ing.unit} ${ing.ingredientName}'),
                        if (ing.costPerUnit != null) ...[
                          const Spacer(),
                          Text(
                            formatCurrency(ing.quantity * ing.costPerUnit!),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (ingredients.isNotEmpty) ...[
                  const Divider(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Est. Cost: ${formatCurrency(ingredients.fold<double>(0, (sum, i) => sum + (i.costPerUnit ?? 0) * i.quantity))}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                if (recipe.instructions != null && recipe.instructions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Instructions', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(recipe.instructions!),
                ],
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: BakeryTheme.tertiary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Recipes',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Recipe'),
            ),
          ],
        ),
        Expanded(
          child: _recipes.isEmpty
              ? const EmptyState(
                  icon: Icons.menu_book_outlined,
                  message: 'No recipes yet.\nAdd your signature recipes!',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _recipes.length,
                  itemBuilder: (ctx, i) {
                    final r = _recipes[i];
                    return SurfaceCard(
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _viewRecipe(r),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: BakeryTheme.accent.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.menu_book, color: BakeryTheme.primaryDark, size: 20),
                                  ),
                                  const Spacer(),
                                  PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == 'edit') {
                                        _showForm(r);
                                      } else if (v == 'delete') {
                                        if (await confirmDelete(context, r.name)) {
                                          await _db.deleteRecipe(r.id!);
                                          _load();
                                        }
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              if (r.description != null && r.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  r.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (r.servings != null) _infoChip('${r.servings} servings'),
                                  if (r.estimatedCost != null) _infoChip(formatCurrency(r.estimatedCost!)),
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
}

// ── Recipe Form ──
class _RecipeFormResult {
  final Recipe recipe;
  final List<RecipeIngredient> ingredients;
  _RecipeFormResult(this.recipe, this.ingredients);
}

class _RecipeForm extends StatefulWidget {
  final Recipe? existing;
  final DatabaseHelper db;
  final List<String> unitOptions;
  final List<InventoryItem> inventoryItems;
  const _RecipeForm({this.existing, required this.db, required this.unitOptions, required this.inventoryItems});

  @override
  State<_RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends State<_RecipeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _instructions;
  late final TextEditingController _servings;
  late final TextEditingController _prepTime;
  final List<_IngLine> _ingredients = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _instructions = TextEditingController(text: e?.instructions ?? '');
    _servings = TextEditingController(text: e?.servings != null ? e!.servings.toString() : '');
    _prepTime = TextEditingController(text: e?.prepTime ?? '');
    if (e != null) _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final ings = await widget.db.getRecipeIngredients(widget.existing!.id!);
    setState(() {
      _ingredients.addAll(
        ings.map(
          (i) => _IngLine(
            inventoryItemId: i.inventoryItemId,
            name: i.ingredientName,
            qty: i.quantity.toString(),
            unit: i.unit,
            cost: i.costPerUnit?.toString() ?? '',
          ),
        ),
      );
    });
  }

  double get _totalCost => _ingredients.fold(0, (sum, i) {
    final qty = double.tryParse(i.qty) ?? 0;
    final cost = double.tryParse(i.cost) ?? 0;
    return sum + qty * cost;
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Recipe' : 'Add Recipe'),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Recipe Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _servings,
                        decoration: const InputDecoration(labelText: 'Servings'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _prepTime,
                        decoration: const InputDecoration(labelText: 'Prep Time', hintText: 'e.g. 45 min'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(
                      'Est. Cost: ${formatCurrency(_totalCost)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._ingredients.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final ing = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int?>(
                                isExpanded: true,
                                initialValue: widget.inventoryItems.any((it) => it.id == ing.inventoryItemId)
                                    ? ing.inventoryItemId
                                    : null,
                                decoration: const InputDecoration(labelText: 'Inventory Item'),
                                items: widget.inventoryItems
                                    .map(
                                      (it) => DropdownMenuItem(
                                        value: it.id,
                                        child: Text(it.name, overflow: TextOverflow.ellipsis),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  final item = widget.inventoryItems.firstWhere((it) => it.id == v);
                                  setState(() {
                                    ing.inventoryItemId = item.id;
                                    ing.name = item.name;
                                    ing.unit = item.unit;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: ing.name,
                                decoration: const InputDecoration(labelText: 'Or New Ingredient'),
                                onChanged: (v) {
                                  ing.name = v;
                                  ing.inventoryItemId = null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: ing.qty,
                                decoration: const InputDecoration(labelText: 'Qty'),
                                onChanged: (v) => setState(() => ing.qty = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: widget.unitOptions.contains(ing.unit)
                                    ? ing.unit
                                    : widget.unitOptions.first,
                                decoration: const InputDecoration(labelText: 'Unit'),
                                items: widget.unitOptions
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(u, overflow: TextOverflow.ellipsis),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => ing.unit = v!,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: ing.cost,
                                decoration: const InputDecoration(labelText: 'R/unit'),
                                onChanged: (v) => setState(() => ing.cost = v),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _ingredients.removeAt(idx)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => setState(() {
                    final defaultUnit = widget.inventoryItems.isNotEmpty
                        ? widget.inventoryItems.first.unit
                        : widget.unitOptions.first;
                    _ingredients.add(_IngLine(unit: defaultUnit));
                  }),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Ingredient'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _instructions,
                  decoration: const InputDecoration(labelText: 'Instructions'),
                  maxLines: 6,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final recipe = Recipe(
                id: widget.existing?.id,
                name: _name.text.trim(),
                description: _desc.text.trim(),
                instructions: _instructions.text.trim(),
                servings: int.tryParse(_servings.text),
                prepTime: _prepTime.text.trim(),
                estimatedCost: _totalCost,
              );
              final ings = _ingredients
                  .where((i) => i.name.isNotEmpty)
                  .map(
                    (i) => RecipeIngredient(
                      recipeId: widget.existing?.id ?? 0,
                      inventoryItemId: i.inventoryItemId,
                      ingredientName: i.name,
                      quantity: double.tryParse(i.qty) ?? 0,
                      unit: i.unit,
                      costPerUnit: double.tryParse(i.cost),
                    ),
                  )
                  .toList();
              Navigator.pop(context, _RecipeFormResult(recipe, ings));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _IngLine {
  int? inventoryItemId;
  String name;
  String qty;
  String unit;
  String cost;
  _IngLine({this.inventoryItemId, this.name = '', this.qty = '', this.unit = 'g', this.cost = ''});
}
