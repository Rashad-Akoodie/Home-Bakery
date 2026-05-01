import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class DocumentationScreen extends StatefulWidget {
  const DocumentationScreen({super.key});

  @override
  State<DocumentationScreen> createState() => _DocumentationScreenState();
}

class _DocSection {
  final String title;
  final IconData icon;
  final List<TextSpan> content;

  _DocSection({required this.title, required this.icon, required this.content});
}

class _DocumentationScreenState extends State<DocumentationScreen> {
  late final List<_DocSection> _sections = [
    _DocSection(
      title: 'Getting Started',
      icon: Icons.rocket_launch,
      content: [
        const TextSpan(
          text: 'Welcome to Home Bakery Assistant!\n\n',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const TextSpan(
          text:
              'This guide will help you navigate and use the system effectively. Start with the sections below based on your role:\n\n',
        ),
        const TextSpan(
          text: 'Bakery Owner/Manager: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'Focus on Dashboard, Recipes, and Accounting\n'),
        const TextSpan(
          text: 'Production Staff: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'Use Production Scheduler and Inventory\n'),
        const TextSpan(
          text: 'Sales/Customer Service: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'Use Orders and Customers sections\n'),
        const TextSpan(
          text: 'Finance: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'Use Accounting Reports and Debtors/Creditors\n\n'),
        const TextSpan(text: 'Each section is designed to help you manage a specific aspect of your bakery business.'),
      ],
    ),
    _DocSection(
      title: 'Dashboard',
      icon: Icons.dashboard,
      content: [
        const TextSpan(
          text: 'Dashboard ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const TextSpan(text: 'is your command center. It shows:\n\n'),
        const TextSpan(
          text: 'Key Metrics: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'Total orders, inventory status, outstanding debts\n'),
        const TextSpan(
          text: 'Quick Stats: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'Revenue, expenses, and profit summaries\n'),
        const TextSpan(
          text: 'Recent Activity: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'Latest orders and activities\n\n'),
        const TextSpan(text: 'Use the dashboard to get a quick overview of your business health at a glance.'),
      ],
    ),
    _DocSection(
      title: 'Recipes & Price List',
      icon: Icons.menu_book,
      content: [
        const TextSpan(
          text: 'Recipes ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const TextSpan(text: 'are the foundation of your business:\n\n'),
        const TextSpan(
          text: '1. Create Recipes: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'Define ingredients with quantities and costs\n'),
        const TextSpan(
          text: '2. Link to Products: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'Each recipe creates an entry in your Price List\n'),
        const TextSpan(
          text: '3. Track Costs: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'See estimated ingredient costs per recipe\n\n'),
        const TextSpan(
          text: 'Price List ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'lets you:\n'),
        const TextSpan(
          text: '• Define product prices ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '(fixed or size-based variants)\n'),
        const TextSpan(
          text: '• Manage pricing changes ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'with automatic safeguards\n'),
        const TextSpan(text: '• Track which products are active\n\n'),
        const TextSpan(
          text: 'Key Principle: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(
          text: 'New recipes automatically create price list entries at \$0 cost. Update pricing as needed.',
        ),
      ],
    ),
    _DocSection(
      title: 'Orders Management',
      icon: Icons.receipt_long,
      content: [
        const TextSpan(
          text: 'Creating Orders:\n',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const TextSpan(text: '1. Click "New Order" and select a customer (or "Walk-in")\n'),
        const TextSpan(text: '2. Add line items by selecting from recipe-backed products\n'),
        const TextSpan(text: '3. Set due date and notes (both optional)\n'),
        const TextSpan(text: '4. Enable "Manual Price Override" if you need custom pricing\n\n'),
        const TextSpan(
          text: 'Status Flow:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'Pending → In Progress → Ready → Delivered\n'),
        const TextSpan(text: 'Use "Previous Status" button to correct mistakes (with warning)\n\n'),
        const TextSpan(
          text: 'Tracking:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '• Record payments as you receive them\n'),
        const TextSpan(text: '• Track payment status: Unpaid, Partial, or Paid\n'),
        const TextSpan(text: '• View and manage order history'),
      ],
    ),
    _DocSection(
      title: 'Inventory Management',
      icon: Icons.inventory_2,
      content: [
        const TextSpan(
          text: 'Inventory ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const TextSpan(text: 'is your source of truth for ingredients:\n\n'),
        const TextSpan(
          text: '1. Add Items: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'Name, unit (kg, pcs, L, etc.), quantity, reorder level\n'),
        const TextSpan(
          text: '2. Status Indicators:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '   • OK = Above reorder level\n'),
        const TextSpan(text: '   • Low = At or below reorder level\n'),
        const TextSpan(text: '   • Very Low = Below 50% of reorder level\n'),
        const TextSpan(text: '   • Critical = Below 25% of reorder level\n'),
        const TextSpan(text: '   • Out = Zero quantity\n\n'),
        const TextSpan(
          text: '3. Adjust Stock: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'Use the +/- button to quickly adjust quantities\n'),
        const TextSpan(
          text: '4. Set Reorder Levels: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'Get alerts when stock is running low\n\n'),
        const TextSpan(
          text: 'Principle: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'All recipe ingredients must be created in inventory first.'),
      ],
    ),
    _DocSection(
      title: 'Grocery Runs & Purchasing',
      icon: Icons.shopping_cart,
      content: [
        const TextSpan(
          text: 'Planning Grocery Runs:\n',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const TextSpan(text: '1. Create a grocery run with date and supplier\n'),
        const TextSpan(text: '2. Add items from inventory (or new items)\n'),
        const TextSpan(text: '3. Enter quantity and unit price for each item\n\n'),
        const TextSpan(
          text: 'Processing:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '• Set quantity, unit, and price for each line item\n'),
        const TextSpan(text: '• All fields are required for valid items\n'),
        const TextSpan(text: '• Prices must be ≥ 0\n\n'),
        const TextSpan(
          text: 'Completion:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '• Mark as "Completed" when purchasing is done\n'),
        const TextSpan(text: '• Inventory quantities auto-update when run is completed\n'),
        const TextSpan(text: '• Track supplier information for future reference'),
      ],
    ),
    _DocSection(
      title: 'Production Scheduler',
      icon: Icons.event_note,
      content: [
        const TextSpan(
          text: 'Scheduling Production Tasks:\n',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const TextSpan(text: '1. Create a production task with product name and quantity\n'),
        const TextSpan(text: '2. Set a scheduled date\n'),
        const TextSpan(text: '3. (Optional) Link to a recipe or order for context\n\n'),
        const TextSpan(
          text: 'Status Management:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'Scheduled → In Progress → Completed\n'),
        const TextSpan(text: 'Mark tasks as started and completed through the interface\n\n'),
        const TextSpan(
          text: 'Use For:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '• Planning daily/weekly production\n'),
        const TextSpan(text: '• Tracking which products need to be made\n'),
        const TextSpan(text: '• Linking production to specific orders'),
      ],
    ),
    _DocSection(
      title: 'Debtors & Invoices',
      icon: Icons.person_outline,
      content: [
        const TextSpan(
          text: 'Creating Invoices:\n',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const TextSpan(text: '1. Click "New Invoice" and select an order\n'),
        const TextSpan(text: '2. Review invoice details (auto-calculated from order)\n'),
        const TextSpan(text: '3. PDF is automatically generated and saved\n\n'),
        const TextSpan(
          text: 'Managing Invoices:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '• View PDF: Opens the invoice in your default viewer\n'),
        const TextSpan(text: '• Record Payment: Track partial or full payments\n'),
        const TextSpan(text: '• Email: Opens email client to send invoice\n'),
        const TextSpan(text: '• Regenerate: Create a new PDF if needed\n'),
        const TextSpan(text: '• History: View all versions with clickable download links\n\n'),
        const TextSpan(
          text: 'Invoice Storage:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(
          text:
              'Invoices are saved to your application data folder. Click "Open Invoices Folder" to access them directly.\n\n',
        ),
        const TextSpan(
          text: 'Location:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(
          text:
              'macOS: ~/Library/Application Support/home_bakery/invoices/\nWindows: %APPDATA%/Local/home_bakery/invoices/\nLinux: ~/.local/share/home_bakery/invoices/',
        ),
      ],
    ),
    _DocSection(
      title: 'Expenses & Waste Tracking',
      icon: Icons.account_balance_wallet,
      content: [
        const TextSpan(
          text: 'Expenses:\n',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const TextSpan(text: '1. Record daily expenses by category\n'),
        const TextSpan(text: '2. Include description, amount, and date\n'),
        const TextSpan(text: '3. View expense reports in Accounting section\n\n'),
        const TextSpan(
          text: 'Waste/Loss Tracking:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '1. Log waste items with quantity and reason\n'),
        const TextSpan(text: '2. Estimate financial loss\n'),
        const TextSpan(text: '3. Track reasons for waste (spoilage, mistake, etc.)\n\n'),
        const TextSpan(
          text: 'Benefits:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '• Identify cost-saving opportunities\n'),
        const TextSpan(text: '• Understand loss patterns\n'),
        const TextSpan(text: '• Improve quality control'),
      ],
    ),
    _DocSection(
      title: 'Accounting & Reports',
      icon: Icons.bar_chart,
      content: [
        const TextSpan(
          text: 'Financial Reports:\n',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const TextSpan(text: '• View total revenue from delivered orders\n'),
        const TextSpan(text: '• Track total paid vs unpaid amounts\n'),
        const TextSpan(text: '• Monitor expenses and waste\n'),
        const TextSpan(text: '• See profit/loss calculations\n\n'),
        const TextSpan(
          text: 'Debtors Report:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '• See customers who owe you money\n'),
        const TextSpan(text: '• Track outstanding amounts\n'),
        const TextSpan(text: '• Monitor payment history\n\n'),
        const TextSpan(
          text: 'Key Metrics:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '• Use accounting data to identify trends\n'),
        const TextSpan(text: '• Plan inventory based on sales patterns\n'),
        const TextSpan(text: '• Optimize pricing based on costs'),
      ],
    ),
    _DocSection(
      title: 'Settings & Customization',
      icon: Icons.settings,
      content: [
        const TextSpan(
          text: 'Appearance Settings:\n',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const TextSpan(text: '• Customize colors and theme\n'),
        const TextSpan(text: '• Control glass effect intensity\n'),
        const TextSpan(text: '• Adjust text colors for readability\n\n'),
        const TextSpan(
          text: 'Data Management:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '• Add/manage custom categories for expenses, products, etc.\n'),
        const TextSpan(text: '• Define available units (kg, g, pcs, L, ml, etc.)\n'),
        const TextSpan(text: '• Set business information for invoices\n\n'),
        const TextSpan(
          text: 'Backup & Export:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '• Settings are automatically saved\n'),
        const TextSpan(text: '• Ensure your app data folder is backed up regularly\n\n'),
        const TextSpan(
          text: 'Important: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: 'Never delete the application data folder manually.'),
      ],
    ),
    _DocSection(
      title: 'Tips & Best Practices',
      icon: Icons.lightbulb,
      content: [
        const TextSpan(
          text: 'Data Entry:\n',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const TextSpan(text: '✓ Always set reorder levels for inventory items\n'),
        const TextSpan(text: '✓ Use consistent unit names (kg not kilogram, pcs not pieces)\n'),
        const TextSpan(text: '✓ Add detailed notes to recipes for production clarity\n\n'),
        const TextSpan(
          text: 'Financial Accuracy:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '✓ Record all expenses immediately\n'),
        const TextSpan(text: '✓ Update inventory when grocery runs complete\n'),
        const TextSpan(text: '✓ Track waste to identify patterns\n\n'),
        const TextSpan(
          text: 'Quality Control:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '✓ Set realistic reorder levels based on usage\n'),
        const TextSpan(text: '✓ Review production scheduled regularly\n'),
        const TextSpan(text: '✓ Monitor waste logs for quality issues\n\n'),
        const TextSpan(
          text: 'Customer Relations:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '✓ Set due dates on invoices when appropriate\n'),
        const TextSpan(text: '✓ Record payments promptly\n'),
        const TextSpan(text: '✓ Keep detailed customer notes\n\n'),
        const TextSpan(
          text: 'Troubleshooting:\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: '✓ If stock doesn\'t update, ensure grocery run is marked completed\n'),
        const TextSpan(text: '✓ If price changes aren\'t reflected, only new orders use new prices\n'),
        const TextSpan(text: '✓ Use "Regenerate PDF" if an invoice needs updating'),
      ],
    ),
  ];

  late PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Documentation & Guide',
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: BakeryTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BakeryTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${_currentPage + 1} / ${_sections.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _sections.length,
            itemBuilder: (context, index) {
              final section = _sections[index];
              return _buildSectionPage(section);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: _currentPage > 0
                    ? () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                    : null,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Previous'),
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                children: List.generate(
                  _sections.length,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _currentPage ? BakeryTheme.primary : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _currentPage < _sections.length - 1
                    ? () =>
                          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                    : null,
                label: const Text('Next'),
                icon: const Icon(Icons.arrow_forward, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionPage(_DocSection section) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: SizedBox(
          width: 800,
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: BakeryTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(section.icon, size: 40, color: BakeryTheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(section.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              RichText(
                text: TextSpan(
                  children: section.content,
                  style: TextStyle(height: 1.8, fontSize: 14, color: Colors.grey.shade900),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
