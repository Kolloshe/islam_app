import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  // Theme settings
  bool _isDarkMode = false;

  // Font settings
  double _fontSize = 16.0;
  double _arabicFontSize = 24.0;

  // Language and translation settings
  String _selectedLanguage = 'English';
  String _defaultTranslation = 'en.sahih';

  // Reading preferences
  bool _showTransliteration = false;
  bool _showVerseNumbers = true;
  bool _showTranslation = true;

  // Audio settings
  bool _autoPlay = true;
  bool _downloadOnWifi = true;
  String _audioQuality = 'High';
  double _playbackSpeed = 1.0;
  double _volume = 1.0;

  // Notification settings
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;

  // Getters
  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  double get arabicFontSize => _arabicFontSize;
  String get selectedLanguage => _selectedLanguage;
  String get defaultTranslation => _defaultTranslation;
  bool get showTransliteration => _showTransliteration;
  bool get showVerseNumbers => _showVerseNumbers;
  bool get showTranslation => _showTranslation;
  bool get autoPlay => _autoPlay;
  bool get downloadOnWifi => _downloadOnWifi;
  String get audioQuality => _audioQuality;
  double get playbackSpeed => _playbackSpeed;
  double get volume => _volume;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  // Initialize settings
  Future<void> initializeSettings() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    _isDarkMode = _prefs!.getBool('isDarkMode') ?? false;
    _fontSize = _prefs!.getDouble('fontSize') ?? 16.0;
    _arabicFontSize = _prefs!.getDouble('arabicFontSize') ?? 24.0;
    _selectedLanguage = _prefs!.getString('selectedLanguage') ?? 'English';
    _defaultTranslation = _prefs!.getString('defaultTranslation') ?? 'en.sahih';
    _showTransliteration = _prefs!.getBool('showTransliteration') ?? false;
    _showVerseNumbers = _prefs!.getBool('showVerseNumbers') ?? true;
    _showTranslation = _prefs!.getBool('showTranslation') ?? true;
    _autoPlay = _prefs!.getBool('autoPlay') ?? true;
    _downloadOnWifi = _prefs!.getBool('downloadOnWifi') ?? true;
    _audioQuality = _prefs!.getString('audioQuality') ?? 'High';
    _playbackSpeed = _prefs!.getDouble('playbackSpeed') ?? 1.0;
    _volume = _prefs!.getDouble('volume') ?? 1.0;
    _notificationsEnabled = _prefs!.getBool('notificationsEnabled') ?? true;
    _vibrationEnabled = _prefs!.getBool('vibrationEnabled') ?? true;

    notifyListeners();
  }

  // Theme settings
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs?.setBool('isDarkMode', value);
    notifyListeners();
  }

  // Font settings
  Future<void> setFontSize(double value) async {
    _fontSize = value;
    await _prefs?.setDouble('fontSize', value);
    notifyListeners();
  }

  Future<void> setArabicFontSize(double value) async {
    _arabicFontSize = value;
    await _prefs?.setDouble('arabicFontSize', value);
    notifyListeners();
  }

  // Language and translation settings
  Future<void> setSelectedLanguage(String value) async {
    _selectedLanguage = value;
    await _prefs?.setString('selectedLanguage', value);
    notifyListeners();
  }

  Future<void> setDefaultTranslation(String value) async {
    _defaultTranslation = value;
    await _prefs?.setString('defaultTranslation', value);
    notifyListeners();
  }

  // Reading preferences
  Future<void> setShowTransliteration(bool value) async {
    _showTransliteration = value;
    await _prefs?.setBool('showTransliteration', value);
    notifyListeners();
  }

  Future<void> setShowVerseNumbers(bool value) async {
    _showVerseNumbers = value;
    await _prefs?.setBool('showVerseNumbers', value);
    notifyListeners();
  }

  Future<void> setShowTranslation(bool value) async {
    _showTranslation = value;
    await _prefs?.setBool('showTranslation', value);
    notifyListeners();
  }

  // Audio settings
  Future<void> setAutoPlay(bool value) async {
    _autoPlay = value;
    await _prefs?.setBool('autoPlay', value);
    notifyListeners();
  }

  Future<void> setDownloadOnWifi(bool value) async {
    _downloadOnWifi = value;
    await _prefs?.setBool('downloadOnWifi', value);
    notifyListeners();
  }

  Future<void> setAudioQuality(String value) async {
    _audioQuality = value;
    await _prefs?.setString('audioQuality', value);
    notifyListeners();
  }

  Future<void> setPlaybackSpeed(double value) async {
    _playbackSpeed = value;
    await _prefs?.setDouble('playbackSpeed', value);
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    _volume = value;
    await _prefs?.setDouble('volume', value);
    notifyListeners();
  }

  // Notification settings
  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs?.setBool('notificationsEnabled', value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    await _prefs?.setBool('vibrationEnabled', value);
    notifyListeners();
  }

  // Get theme mode for app
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _prefs?.clear();
    await _loadDefaultSettings();
    notifyListeners();
  }

  Future<void> _loadDefaultSettings() async {
    _isDarkMode = false;
    _fontSize = 16.0;
    _arabicFontSize = 24.0;
    _selectedLanguage = 'English';
    _defaultTranslation = 'en.sahih';
    _showTransliteration = false;
    _showVerseNumbers = true;
    _showTranslation = true;
    _autoPlay = true;
    _downloadOnWifi = true;
    _audioQuality = 'High';
    _playbackSpeed = 1.0;
    _volume = 1.0;
    _notificationsEnabled = true;
    _vibrationEnabled = true;
  }

  // Get translation options map
  Map<String, String> get translationOptions => {
    'en.sahih': 'Sahih International',
    'en.pickthall': 'Pickthall',
    'en.yusufali': 'Yusuf Ali',
    'en.khattab': 'Dr. Mustafa Khattab',
    'en.haleem': 'Abdul Haleem',
    'en.arberry': 'Arberry',
  };

  // Get audio quality options
  List<String> get audioQualityOptions => ['Low', 'Medium', 'High', 'Very High'];

  // Get language options
  List<String> get languageOptions => [
    'English',
    'Arabic',
    'Urdu',
    'Indonesian',
    'Turkish',
    'French',
    'German',
  ];
}
