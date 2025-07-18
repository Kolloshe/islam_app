import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/surah_model.dart';
import '../models/edition_model.dart';
import '../models/reciter_model.dart';
import '../services/quran_api_service.dart';
import 'settings_provider.dart';

class QuranProvider extends ChangeNotifier {
  final QuranApiService _apiService = QuranApiService();
  SettingsProvider? _settingsProvider;

  // State variables
  List<Surah> _surahs = [];
  List<Edition> _editions = [];
  List<Reciter> _reciters = [];
  Surah? _currentSurah;
  Map<String, Surah> _currentSurahEditions = {};
  List<Verse> _searchResults = [];

  bool _isLoading = false;
  String? _error;
  String _selectedEdition = 'quran-uthmani';
  bool _suppressNotifications = false;
  bool _isCurrentSurahOffline = false;

  // Getters
  List<Surah> get surahs => _surahs;
  List<Edition> get editions => _editions;
  List<Reciter> get reciters => _reciters;
  Surah? get currentSurah => _currentSurah;
  Map<String, Surah> get currentSurahEditions => _currentSurahEditions;
  List<Verse> get searchResults => _searchResults;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedEdition => _selectedEdition;
  String get selectedTranslation => _settingsProvider?.defaultTranslation ?? 'en.sahih';
  bool get isCurrentSurahOffline => _isCurrentSurahOffline;

  // Get Arabic text for current surah
  Surah? get arabicSurah => _currentSurahEditions[_selectedEdition];

  // Get translation for current surah
  Surah? get translationSurah => _currentSurahEditions[selectedTranslation];

  // Set settings provider for translation integration
  void setSettingsProvider(SettingsProvider settingsProvider) {
    _settingsProvider = settingsProvider;
  }

  /// Load all surahs
  Future<void> loadSurahs() async {
    try {
      _setLoading(true);
      _clearError();

      _surahs = await _apiService.getAllSurahs();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load surahs: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load available editions
  Future<void> loadEditions({String? format, String? language}) async {
    try {
      _setLoading(true);
      _clearError();

      _editions = await _apiService.getAvailableEditions(format: format, language: language);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load editions: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load available reciters
  Future<void> loadReciters({String language = 'eng'}) async {
    try {
      _setLoading(true);
      _clearError();

      _reciters = await _apiService.getReciters(language: language);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load reciters: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load specific surah with verses
  Future<void> loadSurah(int surahNumber) async {
    try {
      _setLoading(true);
      _clearError();

      // First, try to load from offline storage
      _currentSurah = await _tryLoadOfflineSurah(surahNumber);

      if (_currentSurah != null) {
        _isCurrentSurahOffline = true;
        debugPrint('✅ Loaded surah $surahNumber from offline storage');
        notifyListeners();
        return;
      }

      // If not available offline, load from API
      _isCurrentSurahOffline = false;
      debugPrint('🌐 Loading surah $surahNumber from API');
      // Load both Arabic and translation using settings
      _currentSurahEditions = await _apiService.getSurahWithMultipleEditions(surahNumber, [
        _selectedEdition,
        selectedTranslation,
      ]);

      // Set current surah to Arabic version
      _currentSurah = _currentSurahEditions[_selectedEdition];

      // Merge translation into current surah verses if available
      final translationSurah = _currentSurahEditions[selectedTranslation];
      if (_currentSurah != null && translationSurah != null && _currentSurah!.verses != null) {
        List<Verse> versesWithTranslation = [];
        for (int i = 0; i < _currentSurah!.verses!.length; i++) {
          final arabicVerse = _currentSurah!.verses![i];
          String? translation;
          if (i < translationSurah.verses!.length) {
            translation = translationSurah.verses![i].text;
          }

          versesWithTranslation.add(
            Verse(
              number: arabicVerse.number,
              text: arabicVerse.text,
              translation: translation,
              numberInSurah: arabicVerse.numberInSurah,
              juz: arabicVerse.juz,
              manzil: arabicVerse.manzil,
              page: arabicVerse.page,
              ruku: arabicVerse.ruku,
              hizbQuarter: arabicVerse.hizbQuarter,
              sajda: arabicVerse.sajda,
            ),
          );
        }

        _currentSurah = Surah(
          number: _currentSurah!.number,
          name: _currentSurah!.name,
          englishName: _currentSurah!.englishName,
          englishTranslation: _currentSurah!.englishTranslation,
          revelationType: _currentSurah!.revelationType,
          numberOfAyahs: _currentSurah!.numberOfAyahs,
          verses: versesWithTranslation,
        );
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load surah: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Search verses by keyword
  Future<void> searchVerses(String keyword) async {
    if (keyword.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _searchResults = await _apiService.searchVerses(keyword, edition: selectedTranslation);
      notifyListeners();
    } catch (e) {
      _setError('Failed to search verses: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  /// Set selected edition (Arabic)
  void setSelectedEdition(String edition) {
    _selectedEdition = edition;
    notifyListeners();
  }

  /// Set selected translation (now handled by SettingsProvider)
  void setSelectedTranslation(String translation) {
    _settingsProvider?.setDefaultTranslation(translation);
    notifyListeners();
  }

  /// Get surah by number
  Surah? getSurahByNumber(int number) {
    try {
      return _surahs.firstWhere((surah) => surah.number == number);
    } catch (e) {
      return null;
    }
  }

  /// Get verse by surah and verse number
  Verse? getVerse(int surahNumber, int verseNumber) {
    final surah = getSurahByNumber(surahNumber);
    if (surah?.verses != null) {
      try {
        return surah!.verses!.firstWhere((verse) => verse.numberInSurah == verseNumber);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Try to load surah from offline storage
  Future<Surah?> _tryLoadOfflineSurah(int surahNumber) async {
    try {
      // We need to access DownloadProvider to check for offline data
      // Since providers can't directly access each other, we'll add a callback
      // For now, let's check if file exists directly
      final appDir = await getApplicationDocumentsDirectory();
      final surahDir = Directory('${appDir.path}/downloads/surahs');
      final file = File('${surahDir.path}/surah_$surahNumber.json');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString);

        // The API response has a 'data' field containing the surah
        if (jsonData['code'] == 200 && jsonData['data'] != null) {
          final surah = Surah.fromJson(jsonData['data']);

          // For offline data, we need to add translation if available from settings
          // For now, return the Arabic text - we can enhance this later
          return surah;
        }
      }
    } catch (e) {
      debugPrint('Failed to load offline surah $surahNumber: $e');
    }
    return null;
  }

  /// Suppress notifications (for initial loading)
  void suppressNotifications(bool suppress) {
    _suppressNotifications = suppress;
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!_suppressNotifications) {
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    if (!_suppressNotifications) {
      notifyListeners();
    }
  }

  void _clearError() {
    _error = null;
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([loadSurahs(), loadEditions(format: 'text'), loadReciters()]);
  }
}
