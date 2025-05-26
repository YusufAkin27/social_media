import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  ThemeType _themeType = ThemeType.light;

  static const String THEME_KEY = 'dark_mode_enabled';
  static const String THEME_TYPE_KEY = 'theme_type';

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  bool get isDarkMode =>
      _themeType == ThemeType.dark ||
      _themeType == ThemeType.midnight ||
      _themeType == ThemeType.vaporwave ||
      _themeType == ThemeType.nature ||
      _themeType == ThemeType.sunset ||
      _themeType == ThemeType.ocean;

  ThemeType get themeType => _themeType;

  ThemeData get currentTheme => AppTheme.getThemeByType(_themeType);

  // Mevcut tema tipinin adını döndürme
  String get currentThemeName {
    switch (_themeType) {
      case ThemeType.dark:
        return 'Koyu Tema';
      case ThemeType.light:
        return 'Açık Tema';
      case ThemeType.vaporwave:
        return 'Vaporwave';
      case ThemeType.midnight:
        return 'Gece Mavisi';
      case ThemeType.nature:
        return 'Doğa';
      case ThemeType.cream:
        return 'Krem';
      case ThemeType.sunset:
        return 'Gün Batımı';
      case ThemeType.ocean:
        return 'Okyanus';
      case ThemeType.minimal:
        return 'Minimal';
      case ThemeType.rose:
        return 'Gül';
      default:
        return 'Bilinmeyen';
    }
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Eski anahtar için geriye dönük uyumluluk
    final isDarkMode = prefs.getBool(THEME_KEY);

    // Yeni tema tipi anahtarını kontrol et
    final themeTypeIndex = prefs.getInt(THEME_TYPE_KEY);

    if (themeTypeIndex != null) {
      // Yeni ayar varsa, onu kullan
      _themeType = ThemeType.values[themeTypeIndex];
    } else if (isDarkMode != null) {
      // Sadece eski dark/light ayarı varsa
      _themeType = isDarkMode ? ThemeType.dark : ThemeType.light;
    }

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    // Basit koyu/açık tema geçişi
    _themeType = isDarkMode ? ThemeType.light : ThemeType.dark;
    await _saveThemePrefs();
  }

  Future<void> setDarkMode(bool value) async {
    _themeType = value ? ThemeType.dark : ThemeType.light;
    await _saveThemePrefs();
  }

  Future<void> setThemeType(ThemeType themeType) async {
    _themeType = themeType;
    await _saveThemePrefs();
  }

  // Tema ayarlarını kaydetme
  Future<void> _saveThemePrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Her iki ayarı da kaydet
    await prefs.setBool(THEME_KEY, isDarkMode);
    await prefs.setInt(THEME_TYPE_KEY, _themeType.index);

    notifyListeners();
  }

  // Tüm temaları liste olarak döndür
  List<Map<String, dynamic>> getAllThemes() {
    return [
      {'type': ThemeType.light, 'name': 'Açık Tema', 'icon': Icons.light_mode},
      {'type': ThemeType.dark, 'name': 'Koyu Tema', 'icon': Icons.dark_mode},
      {'type': ThemeType.vaporwave, 'name': 'Vaporwave', 'icon': Icons.blur_on},
      {
        'type': ThemeType.midnight,
        'name': 'Gece Mavisi',
        'icon': Icons.nights_stay
      },
      {'type': ThemeType.nature, 'name': 'Doğa', 'icon': Icons.nature},
      {
        'type': ThemeType.cream,
        'name': 'Krem',
        'icon': Icons.wb_sunny_outlined
      },
      {
        'type': ThemeType.sunset,
        'name': 'Gün Batımı',
        'icon': Icons.wb_twilight
      },
      {'type': ThemeType.ocean, 'name': 'Okyanus', 'icon': Icons.water},
      {
        'type': ThemeType.minimal,
        'name': 'Minimal',
        'icon': Icons.crop_square_outlined
      },
      {'type': ThemeType.rose, 'name': 'Gül', 'icon': Icons.spa},
    ];
  }
}
