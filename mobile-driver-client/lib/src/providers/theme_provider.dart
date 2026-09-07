import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's theme preference (dark / light).
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  /// Convenience constructor that restores the saved preference.
  ThemeProvider() {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('vamo_driver_dark_theme') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vamo_driver_dark_theme', _themeMode == ThemeMode.dark);
  }
}