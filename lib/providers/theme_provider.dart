import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  late ThemeData _lightTheme;
  late ThemeData _darkTheme;

  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;

  ThemeProvider() {
    _lightTheme = _buildLightTheme();
    _darkTheme = _buildDarkTheme();
  }

  void setInitialTheme(bool isDark) {
    _isDark = isDark;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
    notifyListeners();
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      primaryColor: Colors.teal,
      colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.amber),
      textTheme: GoogleFonts.robotoTextTheme(),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      scaffoldBackgroundColor: Colors.grey.shade50,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.teal.shade700,
      colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(secondary: Colors.amber),
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      cardTheme: CardThemeData(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.grey.shade800,
      ),
      scaffoldBackgroundColor: Colors.grey.shade900,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}