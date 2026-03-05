import 'package:flutter/material.dart';
import 'package:kcare/themes/dark_theme.dart';
import 'package:kcare/themes/light_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeMode = darkTheme;

  ThemeData get themeMode => _themeMode;

  bool get isDarkTheme => _themeMode == darkTheme;

  set themeMode(ThemeData themeData) {
    _themeMode = themeData;
    notifyListeners();
  }

  void toggleThemeMode() {
    if (_themeMode == lightTheme) {
      _themeMode = darkTheme;
    } else {
      _themeMode = lightTheme;
    }
    notifyListeners();
  }
}
