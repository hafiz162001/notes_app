import 'package:flutter/material.dart';

class AppTheme {
  static const Color primarySeed = Color(0xFF3F51B5); // Indigo Accent

  // Predefined note card colors (Pastel palette)
  static const List<ColorOption> noteColors = [
    ColorOption(
      name: 'Default',
      color: Color(0xFFFFFFFF),
      darkColor: Color(0xFF2C2C2C),
    ),
    ColorOption(
      name: 'Kuning',
      color: Color(0xFFFFF9C4), // Amber pastel
      darkColor: Color(0xFF423B22),
    ),
    ColorOption(
      name: 'Hijau',
      color: Color(0xFFC8E6C9), // Green pastel
      darkColor: Color(0xFF1B3E25),
    ),
    ColorOption(
      name: 'Biru',
      color: Color(0xFFBBDEFB), // Blue pastel
      darkColor: Color(0xFF1B3248),
    ),
    ColorOption(
      name: 'Ungu',
      color: Color(0xFFE1BEE7), // Purple pastel
      darkColor: Color(0xFF3B1E45),
    ),
    ColorOption(
      name: 'Oranye / Peach',
      color: Color(0xFFFFCCBC), // Deep Orange / Peach
      darkColor: Color(0xFF452B20),
    ),
    ColorOption(
      name: 'Merah Muda',
      color: Color(0xFFF8BBD0), // Pink pastel
      darkColor: Color(0xFF441D2B),
    ),
    ColorOption(
      name: 'Teal',
      color: Color(0xFFB2DFDB), // Teal pastel
      darkColor: Color(0xFF183835),
    ),
  ];

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.light,
      surface: const Color(0xFFFBFBFF),
      primary: const Color(0xFF3F51B5),
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F5F9),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF1E1E24),
        fontSize: 21,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Color(0xFF2B2B36)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withAlpha(15), width: 1),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primarySeed,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E24),
      primary: const Color(0xFF7986CB),
    ),
    scaffoldBackgroundColor: const Color(0xFF121215),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 21,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withAlpha(20), width: 1),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF5C6BC0),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF24242C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1F1F26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

class ColorOption {
  final String name;
  final Color color;
  final Color darkColor;

  const ColorOption({
    required this.name,
    required this.color,
    required this.darkColor,
  });

  Color resolve(bool isDark) => isDark ? darkColor : color;
}
