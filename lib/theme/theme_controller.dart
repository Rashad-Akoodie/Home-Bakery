import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  final DatabaseHelper _db = DatabaseHelper();

  bool _loaded = false;
  ThemeData get theme => BakeryTheme.theme;

  Color get primary => BakeryTheme.primary;
  Color get secondary => BakeryTheme.secondary;
  Color get tertiary => BakeryTheme.tertiary;
  Color get background => BakeryTheme.background;
  Color get menuGlassyStart => BakeryTheme.menuGlassyStart;
  Color get menuGlassyEnd => BakeryTheme.menuGlassyEnd;
  Color get textPrimary => BakeryTheme.textPrimary;
  Color get textSecondary => BakeryTheme.textSecondary;
  Color get selectedCardText => BakeryTheme.selectedCardText;

  Future<void> load() async {
    if (_loaded) return;
    final primaryHex = await _db.getPreference('theme.primary');
    final secondaryHex = await _db.getPreference('theme.secondary');
    final tertiaryHex = await _db.getPreference('theme.tertiary');
    final backgroundHex = await _db.getPreference('theme.background');
    final menuGlassyStartHex = await _db.getPreference('theme.menu_glassy_start');
    final menuGlassyEndHex = await _db.getPreference('theme.menu_glassy_end');
    final textPrimaryHex = await _db.getPreference('theme.text_primary');
    final textSecondaryHex = await _db.getPreference('theme.text_secondary');
    final selectedCardTextHex = await _db.getPreference('theme.selected_card_text');

    BakeryTheme.applyPalette(
      primaryColor: _parseColor(primaryHex) ?? BakeryTheme.defaultPrimary,
      secondaryColor: _parseColor(secondaryHex) ?? BakeryTheme.defaultSecondary,
      tertiaryColor: _parseColor(tertiaryHex) ?? BakeryTheme.defaultTertiary,
      backgroundColor: _parseColor(backgroundHex) ?? BakeryTheme.defaultBackground,
    );
    BakeryTheme.menuGlassyStart = _parseColor(menuGlassyStartHex) ?? BakeryTheme.defaultMenuGlassyStart;
    BakeryTheme.menuGlassyEnd = _parseColor(menuGlassyEndHex) ?? BakeryTheme.defaultMenuGlassyEnd;
    BakeryTheme.textPrimary = _parseColor(textPrimaryHex) ?? BakeryTheme.defaultTextPrimary;
    BakeryTheme.textSecondary = _parseColor(textSecondaryHex) ?? BakeryTheme.defaultTextSecondary;
    BakeryTheme.selectedCardText = _parseColor(selectedCardTextHex) ?? BakeryTheme.defaultSelectedCardText;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setPalette({
    required Color primaryColor,
    required Color secondaryColor,
    required Color tertiaryColor,
    required Color backgroundColor,
  }) async {
    BakeryTheme.applyPalette(
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      tertiaryColor: tertiaryColor,
      backgroundColor: backgroundColor,
    );
    await _db.setPreference('theme.primary', _toHex(primaryColor));
    await _db.setPreference('theme.secondary', _toHex(secondaryColor));
    await _db.setPreference('theme.tertiary', _toHex(tertiaryColor));
    await _db.setPreference('theme.background', _toHex(backgroundColor));
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    BakeryTheme.resetPalette();
    BakeryTheme.menuGlassyStart = BakeryTheme.defaultMenuGlassyStart;
    BakeryTheme.menuGlassyEnd = BakeryTheme.defaultMenuGlassyEnd;
    BakeryTheme.textPrimary = BakeryTheme.defaultTextPrimary;
    BakeryTheme.textSecondary = BakeryTheme.defaultTextSecondary;
    BakeryTheme.selectedCardText = BakeryTheme.defaultSelectedCardText;
    await _db.setPreference('theme.primary', _toHex(BakeryTheme.defaultPrimary));
    await _db.setPreference('theme.secondary', _toHex(BakeryTheme.defaultSecondary));
    await _db.setPreference('theme.tertiary', _toHex(BakeryTheme.defaultTertiary));
    await _db.setPreference('theme.background', _toHex(BakeryTheme.defaultBackground));
    await _db.setPreference('theme.menu_glassy_start', _toHex(BakeryTheme.defaultMenuGlassyStart));
    await _db.setPreference('theme.menu_glassy_end', _toHex(BakeryTheme.defaultMenuGlassyEnd));
    await _db.setPreference('theme.text_primary', _toHex(BakeryTheme.defaultTextPrimary));
    await _db.setPreference('theme.text_secondary', _toHex(BakeryTheme.defaultTextSecondary));
    await _db.setPreference('theme.selected_card_text', _toHex(BakeryTheme.defaultSelectedCardText));
    notifyListeners();
  }

  Future<void> setMenuGlassyColors({required Color startColor, required Color endColor}) async {
    BakeryTheme.menuGlassyStart = startColor;
    BakeryTheme.menuGlassyEnd = endColor;
    await _db.setPreference('theme.menu_glassy_start', _toHex(startColor));
    await _db.setPreference('theme.menu_glassy_end', _toHex(endColor));
    notifyListeners();
  }

  Future<void> setTextColors({
    required Color primaryColor,
    required Color secondaryColor,
    required Color selectedCardColor,
  }) async {
    BakeryTheme.textPrimary = primaryColor;
    BakeryTheme.textSecondary = secondaryColor;
    BakeryTheme.selectedCardText = selectedCardColor;
    await _db.setPreference('theme.text_primary', _toHex(primaryColor));
    await _db.setPreference('theme.text_secondary', _toHex(secondaryColor));
    await _db.setPreference('theme.selected_card_text', _toHex(selectedCardColor));
    notifyListeners();
  }

  String _toHex(Color color) => color.toARGB32().toRadixString(16).padLeft(8, '0');

  Color? _parseColor(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return null;
    return Color(parsed);
  }
}
