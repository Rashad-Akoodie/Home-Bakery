import 'package:flutter/material.dart';

class BakeryTheme {
  // Default pastel palette
  static const Color defaultPrimary = Color(0xFFE8A0BF);
  static const Color defaultSecondary = Color(0xFFBA90C6);
  static const Color defaultTertiary = Color(0xFFC0DBEA);
  static const Color defaultAccent = Color(0xFFEFD595);
  static const Color defaultSurface = Color(0xFFFFF8F0);
  static const Color defaultBackground = Color(0xFFFDF6F0);
  static const Color defaultMenuGlassyStart = Color(0xFFFFFFFF);
  static const Color defaultMenuGlassyEnd = Color(0xFFE8A0BF);
  static const Color defaultTextPrimary = Color(0xFF4A4A4A);
  static const Color defaultTextSecondary = Color(0xFF8A8A8A);
  static const Color defaultSelectedCardText = Color(0xFF5B4B55);

  // Runtime palette (configurable from settings)
  static Color primary = defaultPrimary;
  static Color primaryDark = _darken(defaultPrimary, 0.12);
  static Color secondary = defaultSecondary;
  static Color tertiary = defaultTertiary;
  static Color accent = defaultAccent;
  static Color surface = defaultSurface;
  static Color background = defaultBackground;
  static Color menuGlassyStart = defaultMenuGlassyStart;
  static Color menuGlassyEnd = defaultMenuGlassyEnd;
  static Color textPrimary = defaultTextPrimary;
  static Color textSecondary = defaultTextSecondary;
  static Color selectedCardText = defaultSelectedCardText;
  static const Color cardColor = Colors.white;
  static const Color success = Color(0xFF98D8AA);
  static const Color warning = Color(0xFFFFD89C);
  static const Color error = Color(0xFFE8A0A0);
  static const BorderRadius kRadiusSm = BorderRadius.all(Radius.circular(10));
  static const BorderRadius kRadiusMd = BorderRadius.all(Radius.circular(14));
  static const BorderRadius kRadiusLg = BorderRadius.all(Radius.circular(18));

  static void applyPalette({
    required Color primaryColor,
    required Color secondaryColor,
    required Color tertiaryColor,
    required Color backgroundColor,
  }) {
    primary = primaryColor;
    primaryDark = _darken(primaryColor, 0.12);
    secondary = secondaryColor;
    tertiary = tertiaryColor;
    background = backgroundColor;
    surface = Color.alphaBlend(primaryColor.withValues(alpha: 0.08), backgroundColor);
  }

  static void resetPalette() {
    applyPalette(
      primaryColor: defaultPrimary,
      secondaryColor: defaultSecondary,
      tertiaryColor: defaultTertiary,
      backgroundColor: defaultBackground,
    );
    surface = defaultSurface;
  }

  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final darker = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darker.toColor();
  }

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      tertiary: tertiary,
      surface: surface,
      error: error,
    ),
    scaffoldBackgroundColor: background,
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: kRadiusMd,
        side: BorderSide(color: primary.withValues(alpha: 0.16)),
      ),
    ),
    appBarTheme: AppBarTheme(backgroundColor: primary, foregroundColor: Colors.white, elevation: 0),
    floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: primary, foregroundColor: Colors.white),
    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: kRadiusLg),
    ),
    listTileTheme: ListTileThemeData(
      dense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: kRadiusMd),
      iconColor: textSecondary,
      textColor: textPrimary,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primary.withValues(alpha: 0.06),
      selectedColor: primary.withValues(alpha: 0.2),
      side: BorderSide(color: primary.withValues(alpha: 0.22)),
      shape: RoundedRectangleBorder(borderRadius: kRadiusMd),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
      secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      checkmarkColor: primaryDark,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: kRadiusSm,
        borderSide: BorderSide(color: primary.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: kRadiusSm,
        borderSide: BorderSide(color: primary.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: kRadiusSm,
        borderSide: BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: kRadiusSm),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.1),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryDark,
        side: BorderSide(color: primary.withValues(alpha: 0.35)),
        backgroundColor: primary.withValues(alpha: 0.07),
        shape: RoundedRectangleBorder(borderRadius: kRadiusSm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primaryDark)),
    dividerTheme: DividerThemeData(color: primary.withValues(alpha: 0.15)),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(primary.withValues(alpha: 0.08)),
      headingTextStyle: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
      dataTextStyle: TextStyle(fontSize: 13.5, color: textPrimary),
      horizontalMargin: 14,
      columnSpacing: 24,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 28,
        letterSpacing: 0.15,
        fontFamilyFallback: ['SF Pro Display', 'Avenir Next', 'Segoe UI', 'Roboto'],
      ),
      headlineMedium: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 22,
        letterSpacing: 0.1,
        fontFamilyFallback: ['SF Pro Display', 'Avenir Next', 'Segoe UI', 'Roboto'],
      ),
      titleLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 18,
        letterSpacing: 0.12,
        fontFamilyFallback: ['SF Pro Text', 'Avenir Next', 'Segoe UI', 'Roboto'],
      ),
      titleMedium: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        letterSpacing: 0.1,
        fontFamilyFallback: ['SF Pro Text', 'Avenir Next', 'Segoe UI', 'Roboto'],
      ),
      bodyLarge: TextStyle(
        color: textPrimary,
        fontSize: 15,
        fontFamilyFallback: ['SF Pro Text', 'Avenir Next', 'Segoe UI', 'Roboto'],
      ),
      bodyMedium: TextStyle(
        color: textSecondary,
        fontSize: 14,
        fontFamilyFallback: ['SF Pro Text', 'Avenir Next', 'Segoe UI', 'Roboto'],
      ),
    ),
  );
}

// Common units
const List<String> kUnits = [
  'kg',
  'g',
  'lbs',
  'oz',
  'L',
  'ml',
  'cups',
  'tbsp',
  'tsp',
  'pcs',
  'dozen',
  'boxes',
  'bags',
  'bottles',
];

const List<String> kExpenseCategories = [
  'Packaging',
  'Equipment',
  'Utilities',
  'Marketing',
  'Transport',
  'Rent',
  'Insurance',
  'Subscriptions',
  'Other',
];

const List<String> kWasteReasons = ['Expired', 'Damaged', 'Unsold', 'Over-produced', 'Quality Issue', 'Other'];

const List<String> kInventoryCategories = [
  'Flour & Grains',
  'Sugar & Sweeteners',
  'Dairy',
  'Eggs',
  'Fats & Oils',
  'Leavening',
  'Flavoring & Spices',
  'Chocolate & Cocoa',
  'Fruits & Nuts',
  'Decorations',
  'Packaging',
  'Other',
];

const List<String> kProductCategories = [
  'Cakes',
  'Cupcakes',
  'Cookies',
  'Bread',
  'Pastries',
  'Pies & Tarts',
  'Brownies & Bars',
  'Special Orders',
  'Other',
];
