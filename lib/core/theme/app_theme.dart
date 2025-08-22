import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static bool _isDarkMode = false;
  static double _volume = 0.5;
  static bool _caregiverMode = false;
  static String _caregiverEmail = '';
  static String _caregiverCode = '';

  // Getters
  static bool get isDarkMode => _isDarkMode;
  static double get volume => _volume;
  static bool get caregiverMode => _caregiverMode;
  static String get caregiverEmail => _caregiverEmail;
  static String get caregiverCode => _caregiverCode;

  // Setters
  static void setDarkMode(bool value) {
    _isDarkMode = value;
    _saveThemeSettings();
  }

  static void setVolume(double value) {
    _volume = value;
    _saveThemeSettings();
  }

  static void setCaregiverMode(bool value) {
    _caregiverMode = value;
    _saveThemeSettings();
  }

  static void setCaregiverEmail(String email) {
    _caregiverEmail = email;
    _saveThemeSettings();
  }

  static void setCaregiverCode(String code) {
    _caregiverCode = code;
    _saveThemeSettings();
  }

  // Load settings from SharedPreferences
  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _volume = prefs.getDouble('volume') ?? 0.5;
    _caregiverMode = prefs.getBool('caregiverMode') ?? false;
    _caregiverEmail = prefs.getString('caregiverEmail') ?? '';
    _caregiverCode = prefs.getString('caregiverCode') ?? '';
  }

  // Save settings to SharedPreferences
  static Future<void> _saveThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setDouble('volume', _volume);
    await prefs.setBool('caregiverMode', _caregiverMode);
    await prefs.setString('caregiverEmail', _caregiverEmail);
    await prefs.setString('caregiverCode', _caregiverCode);
  }

  // Theme colors
  static Color get backgroundColor => _isDarkMode 
      ? const Color(0xFF181A20) 
      : const Color(0xFF1565C0);

  static Color get cardColor => _isDarkMode 
      ? const Color(0xFF23272F) 
      : Colors.white;

  static Color get textColor => _isDarkMode 
      ? Colors.white 
      : const Color(0xFF333333);

  static Color get subtitleColor => _isDarkMode 
      ? Colors.white70 
      : Colors.white70;

  static Color get buttonPrimary => const Color(0xFF1565C0);

  static Color get buttonSecondary => _isDarkMode 
      ? const Color(0xFF23272F) 
      : Colors.white;

  static Color get buttonTextColor => _isDarkMode 
      ? Colors.white 
      : const Color(0xFF1565C0);

  static Color get iconColor => _isDarkMode 
      ? Colors.white 
      : const Color(0xFF1565C0);

  // Gradient colors
  static List<Color> get gradientColors => _isDarkMode
      ? [const Color(0xFF181A20), const Color(0xFF23272F)]
      : [const Color(0xFF1565C0), const Color(0xFF0D47A1)];
} 