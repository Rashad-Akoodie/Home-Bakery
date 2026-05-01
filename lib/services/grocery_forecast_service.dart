import '../database/database_helper.dart';
import '../models/models.dart';

class GroceryForecastService {
  final DatabaseHelper _db;
  GroceryForecastService({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<GroceryPurchaseSuggestion>> buildSuggestions({int lookbackDays = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: lookbackDays));
    final orders = await _db.getOrders();
    final recentOrders = orders.where((o) => o.orderDate.isAfter(cutoff) && o.status != 'cancelled').toList();

    final recipes = await _db.getRecipes();
    final recipeByProductId = <int, Recipe>{};
    for (final recipe in recipes) {
      if (recipe.productId != null && !recipeByProductId.containsKey(recipe.productId)) {
        recipeByProductId[recipe.productId!] = recipe;
      }
    }

    final ingredientsCache = <int, List<RecipeIngredient>>{};
    final predictedUsageByItem = <String, double>{};
    final unitByItem = <String, String>{};

    for (final order in recentOrders) {
      if (order.id == null) continue;
      final items = await _db.getOrderItems(order.id!);
      for (final item in items) {
        if (item.productId == null) continue;
        final recipe = recipeByProductId[item.productId!];
        if (recipe == null || recipe.id == null) continue;

        final ingredients = ingredientsCache[recipe.id!] ?? await _db.getRecipeIngredients(recipe.id!);
        ingredientsCache[recipe.id!] = ingredients;

        for (final ing in ingredients) {
          final key = ing.ingredientName.trim().toLowerCase();
          if (key.isEmpty) continue;
          final required = ing.quantity * item.quantity;
          predictedUsageByItem[key] = (predictedUsageByItem[key] ?? 0) + required;
          unitByItem[key] = ing.unit;
        }
      }
    }

    final inventory = await _db.getInventoryItems();
    final inventoryByName = <String, InventoryItem>{for (final i in inventory) i.name.trim().toLowerCase(): i};

    final suggestions = <GroceryPurchaseSuggestion>[];
    final addedKeys = <String>{};

    for (final entry in predictedUsageByItem.entries) {
      final key = entry.key;
      final predicted = entry.value;
      final stock = inventoryByName[key];
      final current = stock?.quantity ?? 0.0;
      final reorder = stock?.reorderLevel ?? 0.0;
      final deficit = predicted - current;
      final buffer = reorder > current ? (reorder - current) : 0.0;
      final suggested = deficit > 0 ? deficit + buffer : buffer;
      if (suggested > 0) {
        suggestions.add(
          GroceryPurchaseSuggestion(
            itemName: stock?.name ?? key,
            unit: stock?.unit ?? unitByItem[key] ?? 'pcs',
            suggestedQuantity: suggested,
            currentStock: current,
            predictedUsage: predicted,
            reason: 'Forecast from last $lookbackDays days + stock buffer',
          ),
        );
        addedKeys.add(key);
      }
    }

    final lowStock = await _db.getLowStockItems();
    for (final item in lowStock) {
      final key = item.name.trim().toLowerCase();
      if (addedKeys.contains(key)) continue;
      final shortage = (item.reorderLevel - item.quantity);
      if (shortage <= 0) continue;
      suggestions.add(
        GroceryPurchaseSuggestion(
          itemName: item.name,
          unit: item.unit,
          suggestedQuantity: shortage,
          currentStock: item.quantity,
          predictedUsage: 0,
          reason: 'Currently below reorder level',
        ),
      );
    }

    suggestions.sort((a, b) => b.suggestedQuantity.compareTo(a.suggestedQuantity));
    return suggestions;
  }
}
