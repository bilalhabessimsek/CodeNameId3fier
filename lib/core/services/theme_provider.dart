import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  String? _backgroundImagePath;
  String? get backgroundImagePath => _backgroundImagePath;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _backgroundImagePath = prefs.getString('background_image_path');
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setBackgroundImage(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove('background_image_path');
    } else {
      await prefs.setString('background_image_path', path);
    }
    _backgroundImagePath = path;
    notifyListeners();
  }
}
