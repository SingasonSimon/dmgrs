import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  AppThemeMode _currentTheme = AppThemeMode.light;
  bool _isLoading = false;

  AppThemeMode get currentTheme => _currentTheme;
  bool get isLoading => _isLoading;
  ThemeData get currentThemeData => AppTheme.currentThemeData;

  static const String _themeKey = 'app_theme';

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      _currentTheme = AppThemeMode.values[themeIndex];
      AppTheme.setTheme(_currentTheme);
    } catch (e) {
      // Use default theme if loading fails
      _currentTheme = AppThemeMode.light;
      AppTheme.setTheme(_currentTheme);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setTheme(AppThemeMode theme) async {
    if (_currentTheme == theme) return;

    _setLoading(true);
    try {
      _currentTheme = theme;
      AppTheme.setTheme(theme);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, theme.index);

      notifyListeners();
    } catch (e) {
      // Handle error silently or show a snackbar
      debugPrint('Error saving theme: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get all available themes
  List<AppThemeMode> get availableThemes => AppThemeMode.values;

  // Get theme name
  String getThemeName(AppThemeMode theme) => AppTheme.getThemeName(theme);

  // Get theme icon
  IconData getThemeIcon(AppThemeMode theme) => AppTheme.getThemeIcon(theme);
}
