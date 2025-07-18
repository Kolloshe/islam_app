import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/azkar_model.dart';

class AzkarApiService {
  static const String baseUrl = 'https://dua-dhikr.vercel.app';
  static const Duration timeoutDuration = Duration(seconds: 15);
  static const Duration cacheDuration = Duration(hours: 24); // Cache for 24 hours
  static const int maxRetries = 3;
  static const Duration baseRetryDelay = Duration(seconds: 2);

  // Rate limiting variables
  static DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(
    milliseconds: 1500,
  ); // 1.5 seconds between requests

  // Cache management
  static Future<void> _cacheData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'azkar_cache_$key',
        json.encode({'data': data, 'timestamp': DateTime.now().millisecondsSinceEpoch}),
      );
    } catch (e) {
      print('Error caching data: $e');
    }
  }

  static Future<Map<String, dynamic>?> _getCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('azkar_cache_$key');
      if (cachedString != null) {
        final cached = json.decode(cachedString);
        final timestamp = cached['timestamp'] as int;
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

        if (DateTime.now().difference(cacheTime) < cacheDuration) {
          return cached['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('Error reading cache: $e');
    }
    return null;
  }

  // Rate limiting helper
  static Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        final waitTime = _minRequestInterval - timeSinceLastRequest;
        print('Rate limiting: waiting ${waitTime.inMilliseconds}ms before next request');
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  // Enhanced HTTP request with retry logic
  static Future<http.Response> _makeRequest(String url) async {
    await _enforceRateLimit();

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept-Language': 'en',
                'User-Agent': 'QuranApp/1.0',
              },
            )
            .timeout(timeoutDuration);

        if (response.statusCode == 200) {
          return response;
        } else if (response.statusCode == 429) {
          // Rate limited - wait longer
          final retryDelay = Duration(seconds: baseRetryDelay.inSeconds * (attempt + 1) * 2);
          print(
            'Rate limited (429). Attempt ${attempt + 1}/$maxRetries. Waiting ${retryDelay.inSeconds}s...',
          );
          if (attempt < maxRetries - 1) {
            await Future.delayed(retryDelay);
            continue;
          }
        } else if (response.statusCode >= 500) {
          // Server error - retry with exponential backoff
          final retryDelay = Duration(seconds: baseRetryDelay.inSeconds * (attempt + 1));
          print(
            'Server error (${response.statusCode}). Attempt ${attempt + 1}/$maxRetries. Waiting ${retryDelay.inSeconds}s...',
          );
          if (attempt < maxRetries - 1) {
            await Future.delayed(retryDelay);
            continue;
          }
        }

        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      } catch (e) {
        if (attempt == maxRetries - 1) {
          throw e;
        }

        final retryDelay = Duration(seconds: baseRetryDelay.inSeconds * (attempt + 1));
        print(
          'Request failed. Attempt ${attempt + 1}/$maxRetries. Error: $e. Retrying in ${retryDelay.inSeconds}s...',
        );
        await Future.delayed(retryDelay);
      }
    }

    throw Exception('Max retries exceeded');
  }

  // Get all available categories with caching
  static Future<List<String>> getCategories() async {
    const cacheKey = 'categories';

    try {
      // Try cache first
      final cachedData = await _getCachedData(cacheKey);
      if (cachedData != null) {
        print('Using cached categories data');
        final List<dynamic> categories = cachedData['data'];
        return categories.map((cat) => cat['slug'].toString()).toList();
      }

      // Make API request
      final response = await _makeRequest('$baseUrl/categories?language=ar');
      final data = json.decode(response.body);

      if (data['statusCode'] == 200 && data['data'] != null) {
        // Cache the response
        await _cacheData(cacheKey, data);

        final List<dynamic> categories = data['data'];
        return categories.map((cat) => cat['slug'].toString()).toList();
      }

      throw Exception('Invalid API response format');
    } catch (e) {
      print('Error fetching categories: $e');
      throw Exception('Failed to load categories: $e');
    }
  }

  // Get azkar for a specific category with caching and better rate limiting
  static Future<List<Azkar>> getAzkarByCategory(String categorySlug) async {
    final cacheKey = 'category_$categorySlug';

    try {
      // Try cache first
      final cachedData = await _getCachedData(cacheKey);
      if (cachedData != null) {
        print('Using cached data for $categorySlug');
        return _parseAzkarList(cachedData, categorySlug);
      }

      // Make API request
      final response = await _makeRequest('$baseUrl/categories/$categorySlug?language=ar');
      final data = json.decode(response.body);

      if (data['statusCode'] == 200 && data['data'] != null) {
        // Cache the response
        await _cacheData(cacheKey, data);

        return _parseAzkarList(data, categorySlug);
      }

      throw Exception('Invalid API response format');
    } catch (e) {
      print('Error fetching azkar for $categorySlug: $e');
      throw Exception('Failed to load azkar: $e');
    }
  }

  // Parse azkar list from API data (simplified to avoid too many detail requests)
  static List<Azkar> _parseAzkarList(Map<String, dynamic> data, String categorySlug) {
    List<Azkar> azkarList = [];
    final List<dynamic> items = data['data'];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is Map<String, dynamic>) {
        // Create azkar from list data without making additional detail requests
        // This reduces API calls and prevents rate limiting
        azkarList.add(
          Azkar(
            id: '${categorySlug}_${item['id']}',
            text: item['title'] ?? '',
            textArabic: item['arabic'] ?? item['title'] ?? '',
            transliteration: item['latin'] ?? '',
            translation: item['translation'] ?? item['title'] ?? '',
            benefits: item['fawaid'] ?? '',
            source: item['source'] ?? 'Dua & Dhikr API',
            count: _extractCount(item['notes']?.toString() ?? ''),
            categoryId: categorySlug,
          ),
        );
      }
    }
    return azkarList;
  }

  // Get detailed azkar (only when specifically needed)
  static Future<Azkar?> getAzkarDetail(String categorySlug, String azkarId) async {
    final cacheKey = 'detail_${categorySlug}_$azkarId';

    try {
      // Try cache first
      final cachedData = await _getCachedData(cacheKey);
      if (cachedData != null) {
        print('Using cached detail for $azkarId');
        return _parseAzkarDetail(cachedData, categorySlug);
      }

      // Make API request
      final response = await _makeRequest('$baseUrl/categories/$categorySlug/$azkarId?language=ar');
      final data = json.decode(response.body);

      if (data['statusCode'] == 200 && data['data'] != null) {
        // Cache the response
        await _cacheData(cacheKey, data);

        return _parseAzkarDetail(data['data'], categorySlug);
      }

      return null;
    } catch (e) {
      print('Error fetching detail for $azkarId: $e');
      return null;
    }
  }

  // Parse detailed azkar data
  static Azkar _parseAzkarDetail(Map<String, dynamic> detail, String categoryId) {
    return Azkar(
      id: '${categoryId}_${detail['id']}',
      text: detail['arabic'] ?? detail['title'] ?? '',
      textArabic: detail['arabic'] ?? detail['title'] ?? '',
      transliteration: detail['latin'] ?? '',
      translation: detail['translation'] ?? '',
      benefits: detail['fawaid'] ?? '',
      source: detail['source'] ?? 'Dua & Dhikr API',
      count: _extractCount(detail['notes']?.toString() ?? ''),
      categoryId: categoryId,
    );
  }

  // Extract count from notes helper
  static int _extractCount(String notes) {
    final countMatch = RegExp(r'(\d+)x').firstMatch(notes);
    if (countMatch != null) {
      return int.tryParse(countMatch.group(1) ?? '1') ?? 1;
    }
    return 1;
  }

  // Fetch morning dhikr
  static Future<List<Azkar>> getMorningAzkar() async {
    return getAzkarByCategory('morning-dhikr');
  }

  // Fetch evening dhikr
  static Future<List<Azkar>> getEveningAzkar() async {
    return getAzkarByCategory('evening-dhikr');
  }

  // Fetch dhikr after salah (post-prayer)
  static Future<List<Azkar>> getPostPrayerAzkar() async {
    return getAzkarByCategory('dhikr-after-salah');
  }

  // Fetch daily dua
  static Future<List<Azkar>> getDailyDua() async {
    return getAzkarByCategory('daily-dua');
  }

  // Fetch selected dua
  static Future<List<Azkar>> getSelectedDua() async {
    return getAzkarByCategory('selected-dua');
  }

  // Fetch all azkar categories
  static Future<List<AzkarCategory>> getAllAzkarCategories() async {
    try {
      // Get all categories from API (including empty ones)
      final categoryResults = await Future.wait([
        getMorningAzkar(),
        getEveningAzkar(),
        getPostPrayerAzkar(),
        getDailyDua(),
        getSelectedDua(),
      ]);

      List<AzkarCategory> categories = [];

      // Morning dhikr
      if (categoryResults[0].isNotEmpty) {
        categories.add(
          AzkarCategory(
            id: 'morning_api',
            name: 'Morning Dhikr',
            nameArabic: 'أذكار الصباح',
            description: 'Authentic morning remembrance from Hisnul Muslim',
            icon: '🌅',
            totalAzkar: categoryResults[0].length,
            time: 'morning',
            azkarList: categoryResults[0],
          ),
        );
      }

      // Evening dhikr - provide fallback if API is empty
      if (categoryResults[1].isNotEmpty) {
        categories.add(
          AzkarCategory(
            id: 'evening_api',
            name: 'Evening Dhikr',
            nameArabic: 'أذكار المساء',
            description: 'Evening remembrance and supplications',
            icon: '🌙',
            totalAzkar: categoryResults[1].length,
            time: 'evening',
            azkarList: categoryResults[1],
          ),
        );
      } else {
        // Add local evening dhikr if API is empty
        categories.add(_getLocalEveningDhikr());
      }

      // Post-prayer dhikr - provide fallback if API is empty
      if (categoryResults[2].isNotEmpty) {
        categories.add(
          AzkarCategory(
            id: 'post_prayer_api',
            name: 'Post-Prayer Dhikr',
            nameArabic: 'أذكار ما بعد الصلاة',
            description: 'Dhikr to be recited after prayers',
            icon: '🤲',
            totalAzkar: categoryResults[2].length,
            time: 'post_prayer',
            azkarList: categoryResults[2],
          ),
        );
      } else {
        // Add local post-prayer dhikr if API is empty
        categories.add(_getLocalPostPrayerDhikr());
      }

      // Daily dua - provide fallback if API is empty
      if (categoryResults[3].isNotEmpty) {
        categories.add(
          AzkarCategory(
            id: 'daily_dua_api',
            name: 'Daily Dua',
            nameArabic: 'أدعية يومية',
            description: 'Daily supplications for various occasions',
            icon: '🤲',
            totalAzkar: categoryResults[3].length,
            time: 'general',
            azkarList: categoryResults[3],
          ),
        );
      } else {
        // Add local daily dua if API is empty
        categories.add(_getLocalDailyDua());
      }

      // Selected dua (general)
      if (categoryResults[4].isNotEmpty) {
        categories.add(
          AzkarCategory(
            id: 'general_api',
            name: 'Selected Dua',
            nameArabic: 'أدعية مختارة',
            description: 'Selected supplications for daily use',
            icon: '📿',
            totalAzkar: categoryResults[4].length,
            time: 'general',
            azkarList: categoryResults[4],
          ),
        );
      }

      return categories;
    } catch (e) {
      print('Error fetching all azkar categories: $e');
      throw Exception('Failed to load azkar: $e');
    }
  }

  // Local fallback for evening dhikr
  static AzkarCategory _getLocalEveningDhikr() {
    return AzkarCategory(
      id: 'evening_local',
      name: 'Evening Dhikr',
      nameArabic: 'أذكار المساء',
      description: 'Evening remembrance and supplications',
      icon: '🌙',
      totalAzkar: 8,
      time: 'evening',
      azkarList: [
        Azkar(
          id: 'evening_1',
          text: 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
          textArabic: 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
          transliteration: 'A\'ūdhu billāhi min ash-shayṭāni ar-rajīm',
          translation: 'I seek refuge in Allah from Satan, the accursed one.',
          benefits: 'Protection from Satan and evil influences',
          source: 'Quran',
          count: 1,
          categoryId: 'evening_local',
        ),
        Azkar(
          id: 'evening_2',
          text:
              'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ',
          textArabic:
              'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ',
          transliteration:
              'Allāhumma anta rabbī lā ilāha illā anta, khalaqtanī wa anā \'abduka, wa anā \'alā \'ahdika wa wa\'dika mā istaṭa\'tu',
          translation:
              'O Allah, You are my Lord, none has the right to be worshipped except You, You created me and I am Your servant and I abide to Your covenant and promise as best I can.',
          benefits: 'Whoever says this during the day with conviction and dies will enter Paradise',
          source: 'Bukhari',
          count: 1,
          categoryId: 'evening_local',
        ),
        Azkar(
          id: 'evening_3',
          text: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ',
          textArabic: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ',
          transliteration: 'Amsaynā wa amsal-mulku lillāh, wal-ḥamdu lillāh',
          translation:
              'We have reached the evening and at this very time unto Allah belongs all sovereignty, and all praise is for Allah.',
          benefits: 'Recognition of Allah\'s sovereignty at evening time',
          source: 'Muslim',
          count: 1,
          categoryId: 'evening_local',
        ),
        Azkar(
          id: 'evening_4',
          text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
          textArabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
          transliteration: 'Subḥān Allāhi wa biḥamdih',
          translation: 'Glory is to Allah and praise is to Him.',
          benefits:
              'Whoever says this 100 times, his sins are forgiven even if they are like the foam of the sea',
          source: 'Bukhari & Muslim',
          count: 100,
          categoryId: 'evening_local',
        ),
        Azkar(
          id: 'evening_5',
          text: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
          textArabic: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
          transliteration: 'Lā ilāha illā Allāhu waḥdahu lā sharīka lah',
          translation: 'None has the right to be worshipped except Allah, alone, without partner.',
          benefits: 'Great reward and protection',
          source: 'Bukhari & Muslim',
          count: 10,
          categoryId: 'evening_local',
        ),
        Azkar(
          id: 'evening_6',
          text:
              'أَسْتَغْفِرُ اللَّهَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ',
          textArabic:
              'أَسْتَغْفِرُ اللَّهَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ',
          transliteration:
              'Astaghfir Allāh alladhī lā ilāha illā huwa al-ḥayyu al-qayyūmu wa atūbu ilayh',
          translation:
              'I seek forgiveness of Allah, besides whom none has the right to be worshipped except He, the Ever Living, the Self-Subsisting and Supporter of all, and I turn to Him in repentance.',
          benefits: 'Forgiveness of sins even if one has fled from battle',
          source: 'Abu Dawud, Tirmidhi',
          count: 3,
          categoryId: 'evening_local',
        ),
        Azkar(
          id: 'evening_7',
          text:
              'اللَّهُمَّ بِكَ أَمْسَيْنَا وَبِكَ أَصْبَحْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ',
          textArabic:
              'اللَّهُمَّ بِكَ أَمْسَيْنَا وَبِكَ أَصْبَحْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ',
          transliteration:
              'Allāhumma bika amsaynā wa bika aṣbaḥnā wa bika naḥyā wa bika namūtu wa ilayka al-maṣīr',
          translation:
              'O Allah, by Your leave we have reached the evening and by Your leave we have reached the morning, by Your leave we live and die and unto You is our return.',
          benefits: 'Acknowledgment of Allah\'s control over life and death',
          source: 'Abu Dawud, Tirmidhi',
          count: 1,
          categoryId: 'evening_local',
        ),
        Azkar(
          id: 'evening_8',
          text: 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
          textArabic: 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
          transliteration: 'Allāhumma a\'innī \'alā dhikrika wa shukrika wa ḥusni \'ibādatik',
          translation:
              'O Allah, help me remember You, to be grateful to You, and to worship You in an excellent manner.',
          benefits: 'Help in remembering Allah and worshipping properly',
          source: 'Abu Dawud, Nasa\'i',
          count: 1,
          categoryId: 'evening_local',
        ),
      ],
    );
  }

  // Local fallback for post-prayer dhikr
  static AzkarCategory _getLocalPostPrayerDhikr() {
    return AzkarCategory(
      id: 'post_prayer_local',
      name: 'Post-Prayer Dhikr',
      nameArabic: 'أذكار ما بعد الصلاة',
      description: 'Dhikr to be recited after prayers',
      icon: '🤲',
      totalAzkar: 5,
      time: 'post_prayer',
      azkarList: [
        Azkar(
          id: 'post_prayer_1',
          text: 'أَسْتَغْفِرُ اللَّهَ',
          textArabic: 'أَسْتَغْفِرُ اللَّهَ',
          transliteration: 'Astaghfir Allāh',
          translation: 'I seek forgiveness of Allah.',
          benefits: 'Seeking forgiveness after prayer',
          source: 'Muslim',
          count: 3,
          categoryId: 'post_prayer_local',
        ),
        Azkar(
          id: 'post_prayer_2',
          text:
              'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
          textArabic:
              'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
          transliteration:
              'Allāhumma anta as-salāmu wa minka as-salāmu tabārakta yā dhā al-jalāli wa al-ikrām',
          translation:
              'O Allah, You are Peace and from You is Peace, blessed are You, O Possessor of majesty and honor.',
          benefits: 'Recognition of Allah\'s names and attributes',
          source: 'Muslim',
          count: 1,
          categoryId: 'post_prayer_local',
        ),
        Azkar(
          id: 'post_prayer_3',
          text: 'سُبْحَانَ اللَّهِ',
          textArabic: 'سُبْحَانَ اللَّهِ',
          transliteration: 'Subḥān Allāh',
          translation: 'Glory is to Allah.',
          benefits: 'Glorification of Allah',
          source: 'Bukhari & Muslim',
          count: 33,
          categoryId: 'post_prayer_local',
        ),
        Azkar(
          id: 'post_prayer_4',
          text: 'الْحَمْدُ لِلَّهِ',
          textArabic: 'الْحَمْدُ لِلَّهِ',
          transliteration: 'Al-ḥamdu lillāh',
          translation: 'Praise is to Allah.',
          benefits: 'Praising Allah',
          source: 'Bukhari & Muslim',
          count: 33,
          categoryId: 'post_prayer_local',
        ),
        Azkar(
          id: 'post_prayer_5',
          text: 'اللَّهُ أَكْبَرُ',
          textArabic: 'اللَّهُ أَكْبَرُ',
          transliteration: 'Allāhu akbar',
          translation: 'Allah is the greatest.',
          benefits: 'Declaring Allah\'s greatness',
          source: 'Bukhari & Muslim',
          count: 34,
          categoryId: 'post_prayer_local',
        ),
      ],
    );
  }

  // Local fallback for daily dua
  static AzkarCategory _getLocalDailyDua() {
    return AzkarCategory(
      id: 'daily_dua_local',
      name: 'Daily Dua',
      nameArabic: 'أدعية يومية',
      description: 'Daily supplications for various occasions',
      icon: '🤲',
      totalAzkar: 6,
      time: 'general',
      azkarList: [
        Azkar(
          id: 'daily_1',
          text:
              'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
          textArabic:
              'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
          transliteration:
              'Rabbanā ātinā fī ad-dunyā ḥasanatan wa fī al-ākhirati ḥasanatan wa qinā \'adhāb an-nār',
          translation:
              'Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire.',
          benefits: 'Comprehensive dua for this world and the next',
          source: 'Quran 2:201',
          count: 1,
          categoryId: 'daily_dua_local',
        ),
        Azkar(
          id: 'daily_2',
          text:
              'اللَّهُمَّ اغْفِرْ لِي ذَنْبِي وَوَسِّعْ لِي فِي دَارِي وَبَارِكْ لِي فِيمَا رَزَقْتَنِي',
          textArabic:
              'اللَّهُمَّ اغْفِرْ لِي ذَنْبِي وَوَسِّعْ لِي فِي دَارِي وَبَارِكْ لِي فِيمَا رَزَقْتَنِي',
          transliteration:
              'Allāhumma ighfir lī dhanbī wa wassi\' lī fī dārī wa bārik lī fīmā razaqtanī',
          translation:
              'O Allah, forgive my sin, make my home spacious for me, and bless me in what You have provided for me.',
          benefits: 'Seeking forgiveness, space in home, and blessings in sustenance',
          source: 'Tirmidhi',
          count: 1,
          categoryId: 'daily_dua_local',
        ),
        Azkar(
          id: 'daily_3',
          text:
              'اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي',
          textArabic:
              'اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي',
          transliteration:
              'Allāhumma aṣliḥ lī dīnī alladhī huwa \'iṣmatu amrī, wa aṣliḥ lī dunyāya allatī fīhā ma\'āshī',
          translation:
              'O Allah, make my religion good for me, whereby my affair is protected, and make my world good for me, wherein is my livelihood.',
          benefits: 'Seeking goodness in religion and worldly matters',
          source: 'Muslim',
          count: 1,
          categoryId: 'daily_dua_local',
        ),
        Azkar(
          id: 'daily_4',
          text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنَ الْخَيْرِ كُلِّهِ عَاجِلِهِ وَآجِلِهِ',
          textArabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنَ الْخَيْرِ كُلِّهِ عَاجِلِهِ وَآجِلِهِ',
          transliteration: 'Allāhumma innī as\'aluka min al-khayri kullihi \'ājilihi wa ājilihi',
          translation:
              'O Allah, I ask You for all that is good, in this world and in the Hereafter.',
          benefits: 'Comprehensive asking for all good',
          source: 'Bukhari & Muslim',
          count: 1,
          categoryId: 'daily_dua_local',
        ),
        Azkar(
          id: 'daily_5',
          text:
              'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي',
          textArabic:
              'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي',
          transliteration:
              'Allāhumma \'āfinī fī badanī, Allāhumma \'āfinī fī sam\'ī, Allāhumma \'āfinī fī baṣarī',
          translation:
              'O Allah, grant me health in my body. O Allah, grant me health in my hearing. O Allah, grant me health in my sight.',
          benefits: 'Seeking health and protection for the body and senses',
          source: 'Abu Dawud',
          count: 1,
          categoryId: 'daily_dua_local',
        ),
        Azkar(
          id: 'daily_6',
          text:
              'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
          textArabic:
              'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
          transliteration:
              'Ḥasbiya Allāhu lā ilāha illā huwa \'alayhi tawakkaltu wa huwa rabbu al-\'arshi al-\'aẓīm',
          translation:
              'Allah is sufficient for me; none has the right to be worshipped except Him, in Him I trust, and He is Lord of the Great Throne.',
          benefits: 'Whoever says this 7 times, Allah will take care of whatever worries him',
          source: 'Abu Dawud',
          count: 7,
          categoryId: 'daily_dua_local',
        ),
      ],
    );
  }

  // Test API connection
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/categories'), headers: {'Accept-Language': 'en'})
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('API connection test failed: $e');
      return false;
    }
  }

  // Clear all cached data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('azkar_cache_')).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
      print('Azkar cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Clear expired cache entries
  static Future<void> clearExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('azkar_cache_')).toList();

      for (final key in keys) {
        final cachedString = prefs.getString(key);
        if (cachedString != null) {
          try {
            final cached = json.decode(cachedString);
            final timestamp = cached['timestamp'] as int;
            final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

            if (DateTime.now().difference(cacheTime) >= cacheDuration) {
              await prefs.remove(key);
              print('Removed expired cache: $key');
            }
          } catch (e) {
            // Invalid cache entry, remove it
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      print('Error clearing expired cache: $e');
    }
  }

  // Get cache info
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('azkar_cache_')).toList();

      int totalEntries = keys.length;
      int expiredEntries = 0;
      List<String> cacheTypes = [];

      for (final key in keys) {
        final cachedString = prefs.getString(key);
        if (cachedString != null) {
          try {
            final cached = json.decode(cachedString);
            final timestamp = cached['timestamp'] as int;
            final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

            if (DateTime.now().difference(cacheTime) >= cacheDuration) {
              expiredEntries++;
            }

            final cacheType = key.replaceFirst('azkar_cache_', '');
            if (!cacheTypes.contains(cacheType)) {
              cacheTypes.add(cacheType);
            }
          } catch (e) {
            expiredEntries++;
          }
        }
      }

      return {
        'totalEntries': totalEntries,
        'expiredEntries': expiredEntries,
        'validEntries': totalEntries - expiredEntries,
        'cacheTypes': cacheTypes,
      };
    } catch (e) {
      return {
        'totalEntries': 0,
        'expiredEntries': 0,
        'validEntries': 0,
        'cacheTypes': [],
        'error': e.toString(),
      };
    }
  }
}
