import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'theme/theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/common.dart';
import 'screens/dashboard_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/price_list_screen.dart';
import 'screens/grocery_runs_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/suppliers_screen.dart';
import 'screens/waste_log_screen.dart';
import 'screens/production_screen.dart';
import 'screens/debtors_screen.dart';
import 'screens/creditors_screen.dart';
import 'screens/accounting_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/documentation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeController.instance.load();
  runApp(const BakeryApp());
}

class BakeryApp extends StatelessWidget {
  const BakeryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) => MaterialApp(
        title: 'Home Bakery Assistant',
        debugShowCheckedModeBanner: false,
        theme: ThemeController.instance.theme,
        home: const AppShell(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String key;
  final String label;
  const _NavItem({required this.key, required this.icon, required this.label});
}

class _NavGroup {
  final String label;
  final IconData icon;
  final List<_NavItem> items;
  const _NavGroup({required this.label, required this.icon, required this.items});
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _db = DatabaseHelper();
  String _selectedKey = 'dashboard';
  final Set<String> _expandedGroups = {'Operations', 'Stock & Purchasing', 'Finance', 'People'};
  final Set<String> _favorites = {};
  String? _hoveredKey;

  final _dashboard = const _NavItem(key: 'dashboard', icon: Icons.dashboard, label: 'Dashboard');
  final _documentation = const _NavItem(key: 'documentation', icon: Icons.help_outline, label: 'Documentation');
  final _settings = const _NavItem(key: 'settings', icon: Icons.settings, label: 'Settings / Admin');

  static const _groups = <_NavGroup>[
    _NavGroup(
      label: 'Operations',
      icon: Icons.bakery_dining_outlined,
      items: [
        _NavItem(key: 'orders', icon: Icons.receipt_long, label: 'Orders'),
        _NavItem(key: 'production', icon: Icons.event_note, label: 'Production Scheduler'),
        _NavItem(key: 'recipes', icon: Icons.menu_book, label: 'Recipes'),
        _NavItem(key: 'pricelist', icon: Icons.sell, label: 'Price List'),
      ],
    ),
    _NavGroup(
      label: 'Stock & Purchasing',
      icon: Icons.inventory_2_outlined,
      items: [
        _NavItem(key: 'inventory', icon: Icons.inventory_2, label: 'Inventory'),
        _NavItem(key: 'grocery', icon: Icons.shopping_cart, label: 'Grocery Runs'),
        _NavItem(key: 'suppliers', icon: Icons.local_shipping, label: 'Suppliers'),
        _NavItem(key: 'waste', icon: Icons.delete_sweep, label: 'Waste / Loss'),
      ],
    ),
    _NavGroup(
      label: 'Finance',
      icon: Icons.account_balance_wallet_outlined,
      items: [
        _NavItem(key: 'expenses', icon: Icons.account_balance_wallet, label: 'Expenses'),
        _NavItem(key: 'debtors', icon: Icons.person_outline, label: 'Debtors / Invoices'),
        _NavItem(key: 'creditors', icon: Icons.account_balance, label: 'Creditors'),
        _NavItem(key: 'accounting', icon: Icons.bar_chart, label: 'Accounting Reports'),
      ],
    ),
    _NavGroup(
      label: 'People',
      icon: Icons.people_outline,
      items: [_NavItem(key: 'customers', icon: Icons.people, label: 'Customers')],
    ),
  ];

  static final _screens = <String, Widget>{
    'dashboard': const DashboardScreen(),
    'orders': const OrdersScreen(),
    'production': const ProductionScreen(),
    'recipes': const RecipesScreen(),
    'pricelist': const PriceListScreen(),
    'inventory': const InventoryScreen(),
    'grocery': const GroceryRunsScreen(),
    'suppliers': const SuppliersScreen(),
    'waste': const WasteLogScreen(),
    'expenses': const ExpensesScreen(),
    'debtors': const DebtorsScreen(),
    'creditors': const CreditorsScreen(),
    'accounting': const AccountingScreen(),
    'customers': const CustomersScreen(),
    'documentation': const DocumentationScreen(),
    'settings': const SettingsScreen(),
  };

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final raw = await _db.getPreference('sidebar.favorites');
    if (!mounted) return;
    final allKeys = _groups.expand((g) => g.items).map((e) => e.key).toSet();
    setState(() {
      _favorites
        ..clear()
        ..addAll((raw ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty && allKeys.contains(e)));
    });
  }

  Future<void> _toggleFavorite(String key) async {
    setState(() {
      if (_favorites.contains(key)) {
        _favorites.remove(key);
      } else {
        _favorites.add(key);
      }
    });
    await _db.setPreference('sidebar.favorites', _favorites.join(','));
  }

  _NavItem? _itemByKey(String key) {
    for (final g in _groups) {
      for (final item in g.items) {
        if (item.key == key) return item;
      }
    }
    return null;
  }

  Widget _buildNavTile(_NavItem item) {
    final selected = item.key == _selectedKey;
    final hovered = _hoveredKey == item.key;
    final active = selected || hovered;
    final canFavorite = item.key != 'dashboard' && item.key != 'documentation' && item.key != 'settings';
    final glassyStart = ThemeController.instance.menuGlassyStart;
    final glassyEnd = ThemeController.instance.menuGlassyEnd;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredKey = item.key),
        onExit: (_) => setState(() => _hoveredKey = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Colors.white,
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      glassyStart.withValues(alpha: selected ? 0.36 : 0.26),
                      Colors.white.withValues(alpha: 0.74),
                      glassyEnd.withValues(alpha: selected ? 0.28 : 0.2),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? Color.alphaBlend(glassyEnd.withValues(alpha: 0.5), BakeryTheme.primary.withValues(alpha: 0.26))
                  : BakeryTheme.primary.withValues(alpha: 0.16),
            ),
            boxShadow: active
                ? [BoxShadow(color: glassyEnd.withValues(alpha: 0.15), blurRadius: 14, offset: const Offset(0, 5))]
                : [],
          ),
          child: Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _selectedKey = item.key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 19,
                          color: selected ? BakeryTheme.selectedCardText : BakeryTheme.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: 0.1,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? BakeryTheme.selectedCardText : BakeryTheme.textPrimary,
                              fontFamilyFallback: const ['SF Pro Text', 'Avenir Next', 'Segoe UI', 'Roboto'],
                            ),
                          ),
                        ),
                        if (canFavorite)
                          GestureDetector(
                            onTap: () => _toggleFavorite(item.key),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                _favorites.contains(item.key) ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 18,
                                color: _favorites.contains(item.key)
                                    ? Colors.amber.shade700
                                    : BakeryTheme.textSecondary.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (active)
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: createGlassyGradient(startColor: glassyStart, endColor: glassyEnd),
                    ),
                  ),
                ),
              if (active)
                IgnorePointer(
                  child: Container(
                    height: 14,
                    margin: const EdgeInsets.fromLTRB(2, 2, 2, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ),
              if (active)
                Positioned(
                  right: 14,
                  top: 6,
                  child: IgnorePointer(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            glassyStart.withValues(alpha: 0.35),
                            glassyEnd.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) => Scaffold(
        body: Row(
          children: [
            // Sidebar
            Container(
              width: 270,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [BakeryTheme.surface, BakeryTheme.background],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.cake, color: BakeryTheme.primary, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Bakery',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 21,
                            letterSpacing: 0.2,
                            color: BakeryTheme.primary,
                            fontFamilyFallback: const ['SF Pro Display', 'Avenir Next', 'Segoe UI', 'Roboto'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildNavTile(_dashboard),
                        const SizedBox(height: 6),
                        if (_favorites.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Favorites',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber.shade800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ..._favorites.map(_itemByKey).whereType<_NavItem>().map(_buildNavTile),
                          const SizedBox(height: 4),
                        ],
                        ..._groups.map(
                          (group) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (_expandedGroups.contains(group.label)) {
                                      _expandedGroups.remove(group.label);
                                    } else {
                                      _expandedGroups.add(group.label);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: BakeryTheme.primary.withValues(alpha: 0.09),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(group.icon, size: 15, color: BakeryTheme.textSecondary),
                                        const SizedBox(width: 6),
                                        Text(
                                          group.label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.25,
                                            color: BakeryTheme.textSecondary,
                                            fontFamilyFallback: const [
                                              'SF Pro Text',
                                              'Avenir Next',
                                              'Segoe UI',
                                              'Roboto',
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          _expandedGroups.contains(group.label) ? Icons.expand_less : Icons.expand_more,
                                          size: 16,
                                          color: BakeryTheme.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (_expandedGroups.contains(group.label))
                                ...group.items.map((item) => _buildNavTile(item)),
                              const SizedBox(height: 2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: BakeryTheme.tertiary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BakeryTheme.tertiary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                          child: _buildNavTile(_documentation),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                          child: _buildNavTile(_settings),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            // Content
            Expanded(child: _screens[_selectedKey] ?? const DashboardScreen()),
          ],
        ),
      ),
    );
  }
}
