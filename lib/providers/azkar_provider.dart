import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/azkar_model.dart';
import '../services/azkar_api_service.dart';

class AzkarProvider extends ChangeNotifier {
  List<AzkarCategory> _categories = [];
  Map<String, int> _azkarProgress = {};
  Map<String, bool> _azkarCompleted = {};
  bool _isLoading = false;
  String? _error;
  bool _showTranslation = true;
  bool _showTransliteration = true;
  bool _isUsingCachedData = false;
  DateTime? _lastApiCall;
  int _apiCallCount = 0;

  List<AzkarCategory> get categories => _categories;
  Map<String, int> get azkarProgress => _azkarProgress;
  Map<String, bool> get azkarCompleted => _azkarCompleted;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showTranslation => _showTranslation;
  bool get showTransliteration => _showTransliteration;
  bool get isUsingCachedData => _isUsingCachedData;

  List<AzkarCategory> get morningAzkar =>
      _categories.where((cat) => cat.time == 'morning').toList();

  List<AzkarCategory> get eveningAzkar =>
      _categories.where((cat) => cat.time == 'evening').toList();

  List<AzkarCategory> get postPrayerAzkar =>
      _categories.where((cat) => cat.time == 'post_prayer').toList();

  List<AzkarCategory> get generalAzkar =>
      _categories.where((cat) => cat.time == 'general').toList();

  AzkarProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadPreferences();
    await _loadAzkarData();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showTranslation = prefs.getBool('azkar_show_translation') ?? true;
      _showTransliteration = prefs.getBool('azkar_show_transliteration') ?? true;

      // Load progress data
      final progressJson = prefs.getString('azkar_progress');
      if (progressJson != null) {
        final Map<String, dynamic> progressData = json.decode(progressJson);
        _azkarProgress = progressData.map((key, value) => MapEntry(key, value as int));
      }

      // Load completion status
      final completedJson = prefs.getString('azkar_completed');
      if (completedJson != null) {
        final Map<String, dynamic> completedData = json.decode(completedJson);
        _azkarCompleted = completedData.map((key, value) => MapEntry(key, value as bool));
      }
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  Future<void> _loadAzkarData({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _setLoading(true);
    _error = null;
    _isUsingCachedData = false;

    try {
      // Clear expired cache on startup
      if (!forceRefresh) {
        await AzkarApiService.clearExpiredCache();
      }

      // If force refresh, clear all cache
      if (forceRefresh) {
        await AzkarApiService.clearCache();
        print('🔄 Force refresh: cache cleared');
      }

      // Track API call frequency
      _trackApiCall();

      // Check if we should throttle API calls (more than 5 calls in last minute)
      if (_shouldThrottleApiCalls() && !forceRefresh) {
        print('⏳ Throttling API calls, using cached data if available');
        await _loadFromLocalFallback();
        return;
      }

      final categories = await AzkarApiService.getAllAzkarCategories();

      if (categories.isNotEmpty) {
        _categories = categories;
        _error = null;
        print('✅ Successfully loaded ${categories.length} categories from API');
      } else {
        await _loadFromLocalFallback();
      }
    } catch (e) {
      print('❌ API Error: $e');

      // Handle specific error types
      if (e.toString().contains('429') || e.toString().contains('Too Many Requests')) {
        _error = 'Rate limit reached. Using cached data. Please try again in a few minutes.';
        print('🚦 Rate limit detected, using cached/local data');
      } else if (e.toString().contains('timeout') || e.toString().contains('SocketException')) {
        _error = 'Network connection issue. Using offline data.';
        print('📶 Network issue detected');
      } else {
        _error = 'API temporarily unavailable. Using offline data.';
        print('⚠️ Generic API error');
      }

      // Always fall back to local data
      await _loadFromLocalFallback();
    } finally {
      _setLoading(false);
    }
  }

  void _trackApiCall() {
    _lastApiCall = DateTime.now();
    _apiCallCount++;
  }

  bool _shouldThrottleApiCalls() {
    if (_lastApiCall == null) return false;

    final timeSinceLastCall = DateTime.now().difference(_lastApiCall!);
    if (timeSinceLastCall.inMinutes >= 1) {
      _apiCallCount = 0; // Reset counter after a minute
      return false;
    }

    return _apiCallCount > 5; // More than 5 calls in a minute
  }

  Future<void> _loadFromLocalFallback() async {
    try {
      _isUsingCachedData = true;

      // First try to get cache info
      final cacheInfo = await AzkarApiService.getCacheInfo();
      final validCacheEntries = cacheInfo['validEntries'] as int;

      if (validCacheEntries > 0) {
        print('📦 Found $validCacheEntries valid cache entries');
        // Try to load from cache by making API calls (they'll use cache)
        try {
          final categories = await AzkarApiService.getAllAzkarCategories();
          if (categories.isNotEmpty) {
            _categories = categories;
            print('✅ Loaded from cache successfully');
            return;
          }
        } catch (e) {
          print('Cache load failed, falling back to hardcoded data: $e');
        }
      }

      // Load hardcoded local data as final fallback
      _categories = _getLocalAzkarData();
      print('📚 Using local hardcoded data (${_categories.length} categories)');
    } catch (e) {
      print('Error in local fallback: $e');
      _categories = _getLocalAzkarData();
    }
  }

  // Refresh data with user feedback
  Future<void> refreshData({bool showLoading = true}) async {
    if (showLoading) {
      _setLoading(true);
    }

    try {
      await _loadAzkarData(forceRefresh: true);
    } catch (e) {
      _error = 'Failed to refresh data: $e';
    } finally {
      if (showLoading) {
        _setLoading(false);
      }
    }
  }

  // Clear cache manually
  Future<void> clearCache() async {
    try {
      await AzkarApiService.clearCache();
      await _loadAzkarData(forceRefresh: true);
    } catch (e) {
      _error = 'Failed to clear cache: $e';
      notifyListeners();
    }
  }

  // Get cache statistics
  Future<Map<String, dynamic>> getCacheInfo() async {
    return await AzkarApiService.getCacheInfo();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('azkar_show_translation', _showTranslation);
      await prefs.setBool('azkar_show_transliteration', _showTransliteration);
      await prefs.setString('azkar_progress', json.encode(_azkarProgress));
      await prefs.setString('azkar_completed', json.encode(_azkarCompleted));
    } catch (e) {
      print('Error saving azkar preferences: $e');
    }
  }

  List<AzkarCategory> _getLocalAzkarData() {
    return [
      // Morning Azkar
      AzkarCategory(
        id: 'morning',
        name: 'Morning Adhkar',
        nameArabic: 'أذكار الصباح',
        description: 'Remembrance to be recited in the morning',
        icon: '🌅',
        totalAzkar: 10,
        time: 'morning',
        azkarList: [
          Azkar(
            id: 'morning_1',
            text:
                'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ',
            textArabic:
                'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ',
            transliteration:
                'Allahumma bika asbahna wa bika amsayna wa bika nahya wa bika namutu wa ilayka an-nushur',
            translation:
                'O Allah, by You we enter the morning and by You we enter the evening, by You we live and by You we die, and unto You is the resurrection.',
            benefits: 'Protection and blessing for the day',
            source: 'Tirmidhi',
            count: 1,
            categoryId: 'morning',
          ),
          Azkar(
            id: 'morning_2',
            text:
                'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
            textArabic:
                'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
            transliteration:
                'Asbahna wa asbaha al-mulku lillah, wal-hamdu lillah, la ilaha illa Allah wahdahu la sharika lah',
            translation:
                'We have entered the morning and at this very time the whole kingdom belongs to Allah. All praise is for Allah. There is none worthy of worship except Allah, the One, having no partner.',
            benefits: 'Acknowledging Allah\'s sovereignty',
            source: 'Muslim',
            count: 1,
            categoryId: 'morning',
          ),
          Azkar(
            id: 'morning_3',
            text:
                'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ',
            textArabic:
                'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ',
            transliteration:
                'Allahumma anta rabbi la ilaha illa ant, khalaqtani wa ana abduk, wa ana ala ahdika wa wa\'dika ma istat\'at',
            translation:
                'O Allah, You are my Lord, there is no god but You. You created me and I am Your servant, and I am keeping my covenant and promise to You as much as I can.',
            benefits: 'Seeking Allah\'s forgiveness',
            source: 'Bukhari',
            count: 1,
            categoryId: 'morning',
          ),
          Azkar(
            id: 'morning_4',
            text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
            textArabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
            transliteration: 'Subhan Allah wa bihamdih',
            translation: 'Glory be to Allah and praise be to Him',
            benefits: 'Great reward and purification',
            source: 'Bukhari & Muslim',
            count: 100,
            categoryId: 'morning',
          ),
        ],
      ),

      // Evening Azkar
      AzkarCategory(
        id: 'evening',
        name: 'Evening Adhkar',
        nameArabic: 'أذكار المساء',
        description: 'Remembrance to be recited in the evening',
        icon: '🌅',
        totalAzkar: 8,
        time: 'evening',
        azkarList: [
          Azkar(
            id: 'evening_1',
            text:
                'اللَّهُمَّ بِكَ أَمْسَيْنَا وَبِكَ أَصْبَحْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ',
            textArabic:
                'اللَّهُمَّ بِكَ أَمْسَيْنَا وَبِكَ أَصْبَحْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ',
            transliteration:
                'Allahumma bika amsayna wa bika asbahna wa bika nahya wa bika namutu wa ilayka al-masir',
            translation:
                'O Allah, by You we enter the evening and by You we enter the morning, by You we live and by You we die, and unto You is the final return.',
            benefits: 'Protection and blessing for the night',
            source: 'Tirmidhi',
            count: 1,
            categoryId: 'evening',
          ),
          Azkar(
            id: 'evening_2',
            text:
                'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
            textArabic:
                'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
            transliteration:
                'Amsayna wa amsa al-mulku lillah, wal-hamdu lillah, la ilaha illa Allah wahdahu la sharika lah',
            translation:
                'We have entered the evening and at this very time the whole kingdom belongs to Allah. All praise is for Allah. There is none worthy of worship except Allah, the One, having no partner.',
            benefits: 'Acknowledging Allah\'s sovereignty',
            source: 'Muslim',
            count: 1,
            categoryId: 'evening',
          ),
        ],
      ),

      // Post-Prayer Azkar
      AzkarCategory(
        id: 'post_prayer',
        name: 'Post-Prayer Adhkar',
        nameArabic: 'أذكار ما بعد الصلاة',
        description: 'Remembrance to be recited after prayers',
        icon: '🤲',
        totalAzkar: 6,
        time: 'post_prayer',
        azkarList: [
          Azkar(
            id: 'post_prayer_1',
            text: 'أَسْتَغْفِرُ اللَّهَ',
            textArabic: 'أَسْتَغْفِرُ اللَّهَ',
            transliteration: 'Astaghfir Allah',
            translation: 'I seek Allah\'s forgiveness',
            benefits: 'Seeking forgiveness from Allah',
            source: 'Muslim',
            count: 3,
            categoryId: 'post_prayer',
          ),
          Azkar(
            id: 'post_prayer_2',
            text:
                'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
            textArabic:
                'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
            transliteration:
                'Allahumma anta as-salamu wa minka as-salam, tabarakta ya dhal-jalali wal-ikram',
            translation:
                'O Allah, You are Peace and from You comes peace. Blessed are You, O Owner of majesty and honor.',
            benefits: 'Seeking peace from Allah',
            source: 'Muslim',
            count: 1,
            categoryId: 'post_prayer',
          ),
          Azkar(
            id: 'post_prayer_3',
            text: 'سُبْحَانَ اللَّهِ',
            textArabic: 'سُبْحَانَ اللَّهِ',
            transliteration: 'Subhan Allah',
            translation: 'Glory be to Allah',
            benefits: 'Glorifying Allah',
            source: 'Bukhari & Muslim',
            count: 33,
            categoryId: 'post_prayer',
          ),
          Azkar(
            id: 'post_prayer_4',
            text: 'الْحَمْدُ لِلَّهِ',
            textArabic: 'الْحَمْدُ لِلَّهِ',
            transliteration: 'Alhamdulillah',
            translation: 'All praise is due to Allah',
            benefits: 'Praising Allah',
            source: 'Bukhari & Muslim',
            count: 33,
            categoryId: 'post_prayer',
          ),
          Azkar(
            id: 'post_prayer_5',
            text: 'اللَّهُ أَكْبَرُ',
            textArabic: 'اللَّهُ أَكْبَرُ',
            transliteration: 'Allahu Akbar',
            translation: 'Allah is the Greatest',
            benefits: 'Magnifying Allah',
            source: 'Bukhari & Muslim',
            count: 34,
            categoryId: 'post_prayer',
          ),
        ],
      ),

      // General Azkar
      AzkarCategory(
        id: 'general',
        name: 'General Dhikr',
        nameArabic: 'الأذكار العامة',
        description: 'General remembrance for daily recitation',
        icon: '📿',
        totalAzkar: 5,
        time: 'general',
        azkarList: [
          Azkar(
            id: 'general_1',
            text:
                'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
            textArabic:
                'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
            transliteration:
                'La ilaha illa Allah wahdahu la sharika lah, lahu al-mulku wa lahu al-hamd, wa huwa ala kulli shayin qadir',
            translation:
                'There is no deity except Allah, alone without partner. To Him belongs the dominion and to Him belongs all praise, and He is over all things competent.',
            benefits: 'Great reward equivalent to freeing ten slaves',
            source: 'Bukhari & Muslim',
            count: 100,
            categoryId: 'general',
          ),
          Azkar(
            id: 'general_2',
            text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ',
            textArabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ',
            transliteration: 'Subhan Allah wa bihamdih, subhan Allah al-azim',
            translation:
                'Glory be to Allah and praise be to Him, glory be to Allah the Magnificent',
            benefits: 'Beloved to the Most Merciful, light on the tongue, heavy in the scale',
            source: 'Bukhari & Muslim',
            count: 100,
            categoryId: 'general',
          ),
        ],
      ),
    ];
  }

  void updateAzkarCount(String azkarId, int newCount) {
    _azkarProgress[azkarId] = newCount;

    // Find the azkar to check if it's completed
    for (final category in _categories) {
      final azkar = category.azkarList.firstWhere(
        (a) => a.id == azkarId,
        orElse:
            () => Azkar(
              id: '',
              text: '',
              textArabic: '',
              transliteration: '',
              translation: '',
              benefits: '',
              source: '',
              count: 0,
              categoryId: '',
            ),
      );

      if (azkar.id.isNotEmpty) {
        _azkarCompleted[azkarId] = newCount >= azkar.count;
        break;
      }
    }

    _savePreferences();
    notifyListeners();
  }

  void resetAzkarCount(String azkarId) {
    _azkarProgress[azkarId] = 0;
    _azkarCompleted[azkarId] = false;
    _savePreferences();
    notifyListeners();
  }

  void resetAllProgress() {
    _azkarProgress.clear();
    _azkarCompleted.clear();
    _savePreferences();
    notifyListeners();
  }

  void resetCategoryProgress(String categoryId) {
    final category = _categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse:
          () => AzkarCategory(
            id: '',
            name: '',
            nameArabic: '',
            description: '',
            icon: '',
            totalAzkar: 0,
            time: '',
            azkarList: [],
          ),
    );

    for (final azkar in category.azkarList) {
      _azkarProgress[azkar.id] = 0;
      _azkarCompleted[azkar.id] = false;
    }

    _savePreferences();
    notifyListeners();
  }

  void toggleTranslation() {
    _showTranslation = !_showTranslation;
    _savePreferences();
    notifyListeners();
  }

  void toggleTransliteration() {
    _showTransliteration = !_showTransliteration;
    _savePreferences();
    notifyListeners();
  }

  int getCurrentCount(String azkarId) {
    return _azkarProgress[azkarId] ?? 0;
  }

  bool isCompleted(String azkarId) {
    return _azkarCompleted[azkarId] ?? false;
  }

  double getCategoryProgress(String categoryId) {
    final category = _categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse:
          () => AzkarCategory(
            id: '',
            name: '',
            nameArabic: '',
            description: '',
            icon: '',
            totalAzkar: 0,
            time: '',
            azkarList: [],
          ),
    );

    if (category.azkarList.isEmpty) return 0.0;

    int completedCount = 0;
    for (final azkar in category.azkarList) {
      if (isCompleted(azkar.id)) {
        completedCount++;
      }
    }

    return completedCount / category.azkarList.length;
  }

  // Refresh azkar data from API
  Future<void> refreshAzkarData() async {
    await _loadAzkarData();
  }

  // Test API connection
  Future<bool> testApiConnection() async {
    try {
      return await AzkarApiService.testConnection();
    } catch (e) {
      print('API connection test failed: $e');
      return false;
    }
  }
}
