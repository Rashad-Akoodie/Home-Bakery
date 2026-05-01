import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  final _db = DatabaseHelper();

  late DateTime _from;
  late DateTime _to;

  double _sales = 0;
  double _received = 0;
  double _grocerySpend = 0;
  double _expenses = 0;
  double _wasteLoss = 0;
  int _orderCount = 0;
  double _debtorsBalance = 0;
  double _creditorsBalance = 0;
  Map<String, double> _expenseBreakdown = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = now;
    _load();
  }

  Future<void> _load() async {
    final from = _from;
    final to = DateTime(_to.year, _to.month, _to.day, 23, 59, 59);

    final results = await Future.wait([
      _db.getTotalSalesBetween(from, to),
      _db.getTotalPaidBetween(from, to),
      _db.getTotalGrocerySpendBetween(from, to),
      _db.getTotalExpensesBetween(from, to),
      _db.getTotalWasteLossBetween(from, to),
      _db.getOrderCountBetween(from, to),
      _db.getTotalDebtorsBalance(),
      _db.getTotalCreditorsBalance(),
      _db.getExpenseBreakdownBetween(from, to),
    ]);

    setState(() {
      _sales = results[0] as double;
      _received = results[1] as double;
      _grocerySpend = results[2] as double;
      _expenses = results[3] as double;
      _wasteLoss = results[4] as double;
      _orderCount = results[5] as int;
      _debtorsBalance = results[6] as double;
      _creditorsBalance = results[7] as double;
      _expenseBreakdown = results[8] as Map<String, double>;
    });
  }

  double get _totalSpend => _grocerySpend + _expenses;
  double get _grossProfit => _sales - _totalSpend;
  double get _netProfit => _grossProfit - _wasteLoss;

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (range != null) {
      setState(() {
        _from = range.start;
        _to = range.end;
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Text('Accounting & Reports', style: Theme.of(context).textTheme.headlineLarge)),
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range, size: 18),
                label: Text('${fmt.format(_from)} – ${fmt.format(_to)}'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Income ──
          const SectionHeader(title: 'Income'),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _card('Total Sales', _sales, Icons.point_of_sale, BakeryTheme.success),
              _card('Payments Received', _received, Icons.account_balance_wallet, Colors.green),
              _card(
                'Orders',
                _orderCount.toDouble(),
                Icons.receipt_long,
                Colors.blue,
                isCurrency: false,
                displayInt: true,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Expenses ──
          const SectionHeader(title: 'Expenses'),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _card('Grocery Spend', _grocerySpend, Icons.shopping_cart, Colors.orange),
              _card('Other Expenses', _expenses, Icons.receipt, Colors.deepOrange),
              _card('Total Spend', _totalSpend, Icons.money_off, Colors.red),
              _card('Waste / Loss', _wasteLoss, Icons.delete_sweep, Colors.brown),
            ],
          ),
          const SizedBox(height: 24),

          // ── Profit ──
          const SectionHeader(title: 'Profit'),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _card('Gross Profit', _grossProfit, Icons.trending_up, _grossProfit >= 0 ? Colors.green : Colors.red),
              _card(
                'Net Profit (after waste)',
                _netProfit,
                Icons.show_chart,
                _netProfit >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Debtors & Creditors ──
          const SectionHeader(title: 'Outstanding Balances'),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _card('Debtors (owed to you)', _debtorsBalance, Icons.person_outline, Colors.blue),
              _card('Creditors (you owe)', _creditorsBalance, Icons.account_balance, Colors.red),
            ],
          ),
          const SizedBox(height: 24),

          // ── Expense Breakdown ──
          if (_expenseBreakdown.isNotEmpty) ...[
            const SectionHeader(title: 'Expense Breakdown'),
            SurfaceCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _expenseBreakdown.entries.map((e) {
                    final pct = _expenses > 0 ? (e.value / _expenses * 100) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 140,
                            child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 14,
                                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                color: BakeryTheme.primary.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 90,
                            child: Text(
                              '${formatCurrency(e.value)} (${pct.toStringAsFixed(0)}%)',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card(
    String title,
    double value,
    IconData icon,
    Color color, {
    bool isCurrency = true,
    bool displayInt = false,
  }) {
    return SizedBox(
      width: 220,
      child: SurfaceCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                displayInt
                    ? value.toInt().toString()
                    : isCurrency
                    ? formatCurrency(value)
                    : value.toStringAsFixed(2),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
