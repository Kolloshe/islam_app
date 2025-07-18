import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('ar', ''), // Arabic
  ];

  LanguageProvider() {
    _loadLanguage();
  }

  // Load saved language from SharedPreferences
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'en';

      // Validate that the language code is supported
      final supportedLanguageCodes = supportedLocales.map((locale) => locale.languageCode).toList();
      if (supportedLanguageCodes.contains(languageCode)) {
        _currentLocale = Locale(languageCode);
      } else {
        _currentLocale = const Locale('en'); // Default to English
      }

      notifyListeners();
    } catch (e) {
      print('Error loading language: $e');
      _currentLocale = const Locale('en'); // Default to English on error
    }
  }

  // Save language to SharedPreferences
  Future<void> _saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', languageCode);
    } catch (e) {
      print('Error saving language: $e');
    }
  }

  // Change language
  Future<void> setLanguage(Locale locale) async {
    if (supportedLocales.contains(locale) && _currentLocale != locale) {
      _currentLocale = locale;
      await _saveLanguage(locale.languageCode);
      notifyListeners();
    }
  }

  // Helper methods
  bool get isArabic => _currentLocale.languageCode == 'ar';
  bool get isEnglish => _currentLocale.languageCode == 'en';

  // Get language name for display
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      default:
        return 'English';
    }
  }

  // Get current language name
  String get currentLanguageName => getLanguageName(_currentLocale.languageCode);

  // Get text direction based on current language
  TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;
}
