import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode { light, dark, blue, green, purple }

class AppTheme {
  static AppThemeMode _currentTheme = AppThemeMode.light;
  static bool _darkModeEnabled = false; // Disable dark mode by default

  static AppThemeMode get currentTheme => _currentTheme;
  static bool get isDarkModeEnabled => _darkModeEnabled;

  static void setTheme(AppThemeMode theme) {
    _currentTheme = theme;
  }

  static void setDarkModeEnabled(bool enabled) {
    _darkModeEnabled = enabled;
    if (!enabled && _currentTheme == AppThemeMode.dark) {
      _currentTheme = AppThemeMode.light;
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
            brightness: Brightness.light,
          ).copyWith(
            surface: const Color(0xFFFAFAFA),
            surfaceContainer: const Color(0xFFF5F5F5),
            onSurface: const Color(0xFF1A1A1A),
            onSurfaceVariant: const Color(0xFF424242),
          ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF64748B), // Slate color
            brightness: Brightness.dark,
          ).copyWith(
            // Dark gray/slate background
            surface: const Color(0xFF0F172A), // Slate 900
            surfaceContainer: const Color(0xFF1E293B), // Slate 800
            surfaceContainerHighest: const Color(0xFF334155), // Slate 700
            surfaceContainerHigh: const Color(0xFF475569), // Slate 600
            // High contrast text colors - all white for maximum visibility
            onSurface: const Color(0xFFFFFFFF), // Pure white
            onSurfaceVariant: const Color(0xFFFFFFFF), // Pure white
            onBackground: const Color(0xFFFFFFFF), // Pure white
            // Accent colors
            primary: const Color(0xFF3B82F6), // Blue 500
            onPrimary: const Color(0xFFFFFFFF),
            primaryContainer: const Color(0xFF1E40AF), // Blue 800
            onPrimaryContainer: const Color(0xFFDBEAFE), // Blue 100

            secondary: const Color(0xFF10B981), // Emerald 500
            onSecondary: const Color(0xFFFFFFFF),
            secondaryContainer: const Color(0xFF047857), // Emerald 700
            onSecondaryContainer: const Color(0xFFD1FAE5), // Emerald 100
            // Error and warning colors
            error: const Color(0xFFEF4444), // Red 500
            onError: const Color(0xFFFFFFFF),
            errorContainer: const Color(0xFFDC2626), // Red 600
            onErrorContainer: const Color(0xFFFEE2E2), // Red 100
            // Outline and borders
            outline: const Color(0xFF475569), // Slate 600
            outlineVariant: const Color(0xFF334155), // Slate 700
            // Background
            background: const Color(0xFF0F172A), // Slate 900
          ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E293B), // Slate 800
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  static ThemeData get blueTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ).copyWith(
            surface: const Color(0xFFF8FAFF),
            surfaceContainer: const Color(0xFFE3F2FD),
            onSurface: const Color(0xFF0D47A1),
            onSurfaceVariant: const Color(0xFF1976D2),
          ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  static ThemeData get greenTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            brightness: Brightness.light,
          ).copyWith(
            surface: const Color(0xFFF8FFF8),
            surfaceContainer: const Color(0xFFE8F5E8),
            onSurface: const Color(0xFF1B5E20),
            onSurfaceVariant: const Color(0xFF2E7D32),
          ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
      ),
    );
  }

  static ThemeData get purpleTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF6A1B9A),
            brightness: Brightness.light,
          ).copyWith(
            surface: const Color(0xFFFDF8FF),
            surfaceContainer: const Color(0xFFF3E5F5),
            onSurface: const Color(0xFF4A148C),
            onSurfaceVariant: const Color(0xFF6A1B9A),
          ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 19,
        ),
      ),
    );
  }

  static ThemeData get currentThemeData {
    switch (_currentTheme) {
      case AppThemeMode.light:
        return lightTheme;
      case AppThemeMode.dark:
        return darkTheme;
      case AppThemeMode.blue:
        return blueTheme;
      case AppThemeMode.green:
        return greenTheme;
      case AppThemeMode.purple:
        return purpleTheme;
    }
  }

  static String getThemeName(AppThemeMode theme) {
    switch (theme) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.blue:
        return 'Ocean Blue';
      case AppThemeMode.green:
        return 'Forest Green';
      case AppThemeMode.purple:
        return 'Royal Purple';
    }
  }

  static IconData getThemeIcon(AppThemeMode theme) {
    switch (theme) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.blue:
        return Icons.water_drop;
      case AppThemeMode.green:
        return Icons.eco;
      case AppThemeMode.purple:
        return Icons.palette;
    }
  }
}
