import 'package:flutter/material.dart';
import '../theme/theme.dart';

// Reusable stat card for dashboard
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const StatCard({super.key, required this.title, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? BakeryTheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: c, size: 24),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: c)),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// Section header
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          if (trailing case final Widget trailingWidget) trailingWidget,
        ],
      ),
    );
  }
}

/// Standard screen page header: title + optional subtitle + action widgets.
/// Encodes consistent padding (24 top/sides, 16 bottom) and typography.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const ScreenHeader({super.key, required this.title, this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineLarge)),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 12),
                ...actions.map((a) => Padding(padding: const EdgeInsets.only(left: 8), child: a)),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const AppFilterChip({super.key, required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: BakeryTheme.primary.withValues(alpha: 0.2),
      backgroundColor: BakeryTheme.primary.withValues(alpha: 0.06),
      side: BorderSide(color: BakeryTheme.primary.withValues(alpha: selected ? 0.45 : 0.22)),
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? BakeryTheme.primaryDark : BakeryTheme.textPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const SurfaceCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BakeryTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BakeryTheme.primary.withValues(alpha: 0.16)),
      ),
      child: Padding(padding: padding ?? const EdgeInsets.all(14), child: child),
    );
  }
}

// Empty state placeholder
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({super.key, required this.icon, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: BakeryTheme.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: BakeryTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel case final String label) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onAction, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}

// Delete confirmation dialog
Future<bool> confirmDelete(BuildContext context, String itemName) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete'),
          content: Text('Are you sure you want to delete "$itemName"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: BakeryTheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}

// Format currency
String formatCurrency(double amount) {
  return 'R ${amount.toStringAsFixed(2)}';
}

// Create a glassy/shiny gradient overlay for menu items
Gradient createGlassyGradient({required Color startColor, required Color endColor}) {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      startColor.withValues(alpha: 0.34),
      endColor.withValues(alpha: 0.16),
      endColor.withValues(alpha: 0.06),
      Colors.transparent,
    ],
    stops: const [0.0, 0.38, 0.72, 1.0],
  );
}
