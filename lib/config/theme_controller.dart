import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static const _themeKey = 'app_theme_mode_dark';
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);

  static bool get isDark => themeMode.value == ThemeMode.dark;

  static Future<void> loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dark = prefs.getBool(_themeKey) ?? false;
      themeMode.value = dark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {}
  }

  static Future<void> toggleTheme() async {
    final nextDark = !isDark;
    themeMode.value = nextDark ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, nextDark);
    } catch (_) {}
  }
}
