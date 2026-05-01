import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseHelper();
  int _pendingOrders = 0;
  int _todayProduction = 0;
  int _lowStockCount = 0;
  double _monthSales = 0;
  double _monthExpenses = 0;
  double _monthGroceries = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final results = await Future.wait([
      _db.getPendingOrderCount(),
      _db.getTodayProductionCount(),
      _db.getLowStockItems(),
      _db.getTotalSalesBetween(monthStart, monthEnd),
      _db.getTotalExpensesBetween(monthStart, monthEnd),
      _db.getTotalGrocerySpendBetween(monthStart, monthEnd),
    ]);

    setState(() {
      _pendingOrders = results[0] as int;
      _todayProduction = results[1] as int;
      _lowStockCount = (results[2] as List).length;
      _monthSales = results[3] as double;
      _monthExpenses = results[4] as double;
      _monthGroceries = results[5] as double;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final monthName = DateFormat.MMMM().format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeader(title: 'Dashboard', subtitle: "Welcome back! Here's your bakery at a glance."),
          const SizedBox(height: 8),

          // Quick stats row
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 220,
                child: StatCard(
                  title: 'Pending Orders',
                  value: '$_pendingOrders',
                  icon: Icons.receipt_long,
                  color: BakeryTheme.primary,
                ),
              ),
              SizedBox(
                width: 220,
                child: StatCard(
                  title: 'Today\'s Production',
                  value: '$_todayProduction',
                  icon: Icons.bakery_dining,
                  color: BakeryTheme.secondary,
                ),
              ),
              SizedBox(
                width: 220,
                child: StatCard(
                  title: 'Low Stock Items',
                  value: '$_lowStockCount',
                  icon: Icons.warning_amber_rounded,
                  color: _lowStockCount > 0 ? BakeryTheme.warning : BakeryTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Monthly overview
          SectionHeader(title: '$monthName Overview'),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 220,
                child: StatCard(
                  title: 'Sales',
                  value: formatCurrency(_monthSales),
                  icon: Icons.trending_up,
                  color: BakeryTheme.success,
                ),
              ),
              SizedBox(
                width: 220,
                child: StatCard(
                  title: 'Grocery Spend',
                  value: formatCurrency(_monthGroceries),
                  icon: Icons.shopping_cart,
                  color: BakeryTheme.warning,
                ),
              ),
              SizedBox(
                width: 220,
                child: StatCard(
                  title: 'Other Expenses',
                  value: formatCurrency(_monthExpenses),
                  icon: Icons.account_balance_wallet,
                  color: BakeryTheme.error,
                ),
              ),
              SizedBox(
                width: 220,
                child: StatCard(
                  title: 'Gross Profit',
                  value: formatCurrency(_monthSales - _monthGroceries - _monthExpenses),
                  icon: Icons.savings,
                  color: (_monthSales - _monthGroceries - _monthExpenses) >= 0
                      ? BakeryTheme.success
                      : BakeryTheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
