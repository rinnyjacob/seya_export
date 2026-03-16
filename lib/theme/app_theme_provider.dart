import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  late SharedPreferences _prefs;
  static const String _themeKey = 'isDarkMode';

  bool get isDarkMode => _isDarkMode;

  // Initialize theme from saved preference
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  // Toggle and save theme preference
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  // Set theme and save preference
  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await _prefs.setBool(_themeKey, isDark);
    notifyListeners();
  }
}

