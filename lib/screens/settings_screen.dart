import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = DatabaseHelper();

  static const Map<String, String> _types = {
    'appearance': 'Appearance',
    'unit': 'Units',
    'expense_category': 'Expense Categories',
    'waste_reason': 'Waste Reasons',
    'inventory_category': 'Inventory Categories',
    'product_category': 'Product Categories',
  };

  static const Map<String, String> _developerTypes = {'developer_tools': 'Developer Tools'};

  String _selectedType = 'appearance';
  String? _hoveredType;
  int? _hoveredOptionId;
  List<SettingOption> _options = [];
  bool _useWhiteCards = false;
  Color _glassyStart = ThemeController.instance.menuGlassyStart;
  Color _glassyEnd = ThemeController.instance.menuGlassyEnd;

  Color _primary = ThemeController.instance.primary;
  Color _secondary = ThemeController.instance.secondary;
  Color _tertiary = ThemeController.instance.tertiary;
  Color _background = ThemeController.instance.background;
  Color _textPrimary = ThemeController.instance.textPrimary;
  Color _textSecondary = ThemeController.instance.textSecondary;
  Color _selectedCardText = ThemeController.instance.selectedCardText;

  bool get _showDeveloperTools => !kReleaseMode;
  Map<String, String> get _visibleTypes => {..._types, if (_showDeveloperTools) ..._developerTypes};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_selectedType == 'developer_tools') {
      if (mounted) {
        setState(() => _options = []);
      }
      return;
    }

    if (_selectedType == 'appearance') {
      final whiteCardsPref = await _db.getPreference('use_white_cards');
      setState(() {
        _options = [];
        _primary = ThemeController.instance.primary;
        _secondary = ThemeController.instance.secondary;
        _tertiary = ThemeController.instance.tertiary;
        _background = ThemeController.instance.background;
        _textPrimary = ThemeController.instance.textPrimary;
        _textSecondary = ThemeController.instance.textSecondary;
        _selectedCardText = ThemeController.instance.selectedCardText;
        _glassyStart = ThemeController.instance.menuGlassyStart;
        _glassyEnd = ThemeController.instance.menuGlassyEnd;
        _useWhiteCards = whiteCardsPref == 'true';
      });
      return;
    }
    final options = await _db.getSettingOptions(_selectedType);
    setState(() => _options = options);
  }

  Future<void> _pickColor({
    required String title,
    required Color initial,
    required ValueChanged<Color> onChanged,
  }) async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => _RgbColorPickerDialog(title: title, initial: initial),
    );
    if (picked == null) return;
    onChanged(picked);
    await ThemeController.instance.setPalette(
      primaryColor: _primary,
      secondaryColor: _secondary,
      tertiaryColor: _tertiary,
      backgroundColor: _background,
    );
    await ThemeController.instance.setTextColors(
      primaryColor: _textPrimary,
      secondaryColor: _textSecondary,
      selectedCardColor: _selectedCardText,
    );
    if (mounted) setState(() {});
  }

  Future<void> _pickGlassyStartColor() async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => _RgbColorPickerDialog(title: 'Pick Glass Start Color', initial: _glassyStart),
    );
    if (picked == null) return;
    await ThemeController.instance.setMenuGlassyColors(startColor: picked, endColor: _glassyEnd);
    if (mounted) {
      setState(() => _glassyStart = picked);
    }
  }

  Future<void> _pickGlassyEndColor() async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => _RgbColorPickerDialog(title: 'Pick Glass End Color', initial: _glassyEnd),
    );
    if (picked == null) return;
    await ThemeController.instance.setMenuGlassyColors(startColor: _glassyStart, endColor: picked);
    if (mounted) {
      setState(() => _glassyEnd = picked);
    }
  }

  Future<void> _toggleWhiteCards(bool value) async {
    await _db.setPreference('use_white_cards', value.toString());
    setState(() => _useWhiteCards = value);
  }

  Future<void> _addOption() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add ${_types[_selectedType]} Option'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Value'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty) Navigator.pop(ctx, v);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (value != null) {
      await _db.insertSettingOption(SettingOption(type: _selectedType, value: value, sortOrder: _options.length));
      _load();
    }
  }

  Future<void> _editOption(SettingOption option) async {
    final controller = TextEditingController(text: option.value);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Option'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Value'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null && value != option.value) {
      await _db.updateSettingOption(option.copyWith(value: value));
      _load();
    }
  }

  Future<void> _copyText(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Settings / Admin',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.2),
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                  children: _visibleTypes.entries.map((entry) => _buildTypeTile(entry)).toList(),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: BakeryTheme.surface.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: BakeryTheme.primary.withValues(alpha: 0.16)),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 120, maxWidth: 420),
                        child: Text(
                          _visibleTypes[_selectedType]!,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
                        ),
                      ),
                      if (_selectedType == 'appearance')
                        OutlinedButton.icon(
                          style: _tokenButtonStyle(),
                          onPressed: () async {
                            await ThemeController.instance.resetToDefault();
                            _load();
                          },
                          icon: const Icon(Icons.restart_alt, size: 18),
                          label: const Text('Reset Colors'),
                        )
                      else
                        OutlinedButton.icon(
                          style: _tokenButtonStyle(),
                          onPressed: _addOption,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Option'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: BakeryTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Currency format is fixed to ZAR (R) for all totals and invoices.'),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedType == 'appearance')
                    Expanded(
                      child: ListView(
                        children: [
                          _colorRow(
                            title: 'Primary',
                            color: _primary,
                            onPick: () => _pickColor(
                              title: 'Pick Primary Color',
                              initial: _primary,
                              onChanged: (c) => _primary = c,
                            ),
                          ),
                          _colorRow(
                            title: 'Secondary',
                            color: _secondary,
                            onPick: () => _pickColor(
                              title: 'Pick Secondary Color',
                              initial: _secondary,
                              onChanged: (c) => _secondary = c,
                            ),
                          ),
                          _colorRow(
                            title: 'Tertiary',
                            color: _tertiary,
                            onPick: () => _pickColor(
                              title: 'Pick Tertiary Color',
                              initial: _tertiary,
                              onChanged: (c) => _tertiary = c,
                            ),
                          ),
                          _colorRow(
                            title: 'Background',
                            color: _background,
                            onPick: () => _pickColor(
                              title: 'Pick Background Color',
                              initial: _background,
                              onChanged: (c) => _background = c,
                            ),
                          ),
                          _colorRow(
                            title: 'Text Primary',
                            color: _textPrimary,
                            onPick: () => _pickColor(
                              title: 'Pick Primary Text Color',
                              initial: _textPrimary,
                              onChanged: (c) => _textPrimary = c,
                            ),
                          ),
                          _colorRow(
                            title: 'Text Secondary',
                            color: _textSecondary,
                            onPick: () => _pickColor(
                              title: 'Pick Secondary Text Color',
                              initial: _textSecondary,
                              onChanged: (c) => _textSecondary = c,
                            ),
                          ),
                          _colorRow(
                            title: 'Selected Card Text',
                            color: _selectedCardText,
                            onPick: () => _pickColor(
                              title: 'Pick Selected Card Text Color',
                              initial: _selectedCardText,
                              onChanged: (c) => _selectedCardText = c,
                            ),
                          ),
                          _colorRow(title: 'Glass Blend Start', color: _glassyStart, onPick: _pickGlassyStartColor),
                          _colorRow(title: 'Glass Blend End', color: _glassyEnd, onPick: _pickGlassyEndColor),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: BakeryTheme.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'White Card Style',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Use white cards throughout the app',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(color: BakeryTheme.textSecondary),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: _useWhiteCards,
                                  onChanged: _toggleWhiteCards,
                                  activeThumbColor: BakeryTheme.primary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Changes are saved locally and applied immediately.'),
                        ],
                      ),
                    )
                  else if (_selectedType == 'developer_tools')
                    Expanded(
                      child: ListView(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: BakeryTheme.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: BakeryTheme.warning.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'These tools are only shown outside release builds. The actual reset and demo seed logic lives in the project tool scripts and is not bundled into your shipped app.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _developerCommandCard(
                            title: 'Reset All Data',
                            description:
                                'Erases all app data in the local SQLite database. Add invoice deletion if you want a fully clean demo environment.',
                            command: 'dart run tool/reset_all_data.dart --yes',
                          ),
                          _developerCommandCard(
                            title: 'Reset Data And Invoice Files',
                            description: 'Erases all app data and removes generated invoice PDFs too.',
                            command: 'dart run tool/reset_all_data.dart --yes --delete-invoices',
                          ),
                          _developerCommandCard(
                            title: 'Seed Demo Data',
                            description: 'Resets the database and seeds a full demo bakery dataset.',
                            command: 'dart run tool/seed_demo_data.dart',
                          ),
                          _developerCommandCard(
                            title: 'Append More Demo Data',
                            description: 'Adds another batch of demo records without clearing what already exists.',
                            command: 'dart run tool/seed_demo_data.dart --append',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Run these from the project root in your terminal while developing.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: BakeryTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: _options.isEmpty
                          ? const EmptyState(icon: Icons.tune, message: 'No options defined yet.')
                          : ListView.builder(
                              itemCount: _options.length,
                              itemBuilder: (ctx, i) {
                                final option = _options[i];
                                return _buildOptionRow(option);
                              },
                            ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeTile(MapEntry<String, String> entry) {
    final selected = _selectedType == entry.key;
    final hovered = _hoveredType == entry.key;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredType = entry.key),
        onExit: (_) => setState(() => _hoveredType = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: BakeryTheme.primary.withValues(
              alpha: selected
                  ? 0.2
                  : hovered
                  ? 0.12
                  : 0.06,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BakeryTheme.primary.withValues(alpha: selected ? 0.5 : 0.18)),
            boxShadow: hovered || selected
                ? [
                    BoxShadow(
                      color: BakeryTheme.primary.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    setState(() => _selectedType = entry.key);
                    _load();
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 13,
                            letterSpacing: 0.1,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? BakeryTheme.selectedCardText : BakeryTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: createGlassyGradient(startColor: _glassyStart, endColor: _glassyEnd),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionRow(SettingOption option) {
    final hovered = _hoveredOptionId == option.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredOptionId = option.id),
        onExit: (_) => setState(() => _hoveredOptionId = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _useWhiteCards
                ? (hovered ? BakeryTheme.primary.withValues(alpha: 0.05) : Colors.white)
                : BakeryTheme.primary.withValues(alpha: hovered ? 0.12 : 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BakeryTheme.primary.withValues(alpha: 0.2)),
          ),
          child: ListTile(
            title: Text(option.value),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _editOption(option)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () async {
                    if (await confirmDelete(context, option.value)) {
                      await _db.deleteSettingOption(option.id!);
                      _load();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorRow({required String title, required Color color, required VoidCallback onPick}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _useWhiteCards ? Colors.white : BakeryTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BakeryTheme.primary.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}'),
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6), border: Border.all()),
        ),
        trailing: OutlinedButton(style: _tokenButtonStyle(), onPressed: onPick, child: const Text('Pick')),
      ),
    );
  }

  Widget _developerCommandCard({required String title, required String description, required String command}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _useWhiteCards ? Colors.white : BakeryTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BakeryTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(description, style: TextStyle(color: BakeryTheme.textSecondary)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              command,
              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              style: _tokenButtonStyle(),
              onPressed: () => _copyText(command, title),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy Command'),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _tokenButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: BakeryTheme.primaryDark,
      side: BorderSide(color: BakeryTheme.primary.withValues(alpha: 0.35)),
      backgroundColor: BakeryTheme.primary.withValues(alpha: 0.07),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.1),
    );
  }
}

extension on SettingOption {
  SettingOption copyWith({int? id, String? type, String? value, int? sortOrder, bool? isActive}) {
    return SettingOption(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}

class _RgbColorPickerDialog extends StatefulWidget {
  final String title;
  final Color initial;
  const _RgbColorPickerDialog({required this.title, required this.initial});

  @override
  State<_RgbColorPickerDialog> createState() => _RgbColorPickerDialogState();
}

class _RgbColorPickerDialogState extends State<_RgbColorPickerDialog> {
  late double r;
  late double g;
  late double b;

  @override
  void initState() {
    super.initState();
    r = widget.initial.r * 255;
    g = widget.initial.g * 255;
    b = widget.initial.b * 255;
  }

  Color get current => Color.fromARGB(255, r.round(), g.round(), b.round());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(color: current, borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 12),
            _slider('R', r, Colors.red, (v) => setState(() => r = v)),
            _slider('G', g, Colors.green, (v) => setState(() => g = v)),
            _slider('B', b, Colors.blue, (v) => setState(() => b = v)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, current), child: const Text('Apply')),
      ],
    );
  }

  Widget _slider(String label, double value, Color color, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 22, child: Text(label)),
        Expanded(
          child: Slider(value: value, min: 0, max: 255, activeColor: color, onChanged: onChanged),
        ),
        SizedBox(width: 36, child: Text(value.round().toString())),
      ],
    );
  }
}
