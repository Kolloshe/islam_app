import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/surah_model.dart';
import '../models/edition_model.dart';
import '../models/reciter_model.dart';

class QuranApiService {
  static const String _alQuranBaseUrl = 'https://api.alquran.cloud/v1';
  static const String _quranApiBaseUrl = 'https://quranapi.pages.dev/api';
  static const String _mp3QuranBaseUrl = 'https://mp3quran.net/api/v3';

  // Headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Get list of all surahs with basic information
  Future<List<Surah>> getAllSurahs() async {
    try {
      final response = await http.get(Uri.parse('$_alQuranBaseUrl/surah'), headers: _headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> surahsData = jsonData['data'];

        return surahsData.map((surahJson) => Surah.fromJson(surahJson)).toList();
      } else {
        throw Exception('Failed to load surahs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching surahs: $e');
    }
  }

  /// Get detailed surah with verses
  Future<Surah> getSurahWithVerses(int surahNumber, {String edition = 'quran-uthmani'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_alQuranBaseUrl/surah/$surahNumber/$edition'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Surah.fromJson(jsonData['data']);
      } else {
        throw Exception('Failed to load surah: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching surah: $e');
    }
  }

  /// Get surah with multiple editions (Arabic + Translation)
  Future<Map<String, Surah>> getSurahWithMultipleEditions(
    int surahNumber,
    List<String> editions,
  ) async {
    try {
      String editionsParam = editions.join(',');
      final response = await http.get(
        Uri.parse('$_alQuranBaseUrl/surah/$surahNumber/editions/$editionsParam'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(jsonData['data']);
        final List<dynamic> surahsData = jsonData['data'];

        Map<String, Surah> result = {};
        for (var surahData in surahsData) {
          final surah = Surah.fromJson(surahData);
          // Use edition identifier as key
          final edition = surahData['edition']?['identifier'] ?? '';
          result[edition] = surah;
        }
        return result;
      } else {
        throw Exception('Failed to load surahs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching surahs: $e');
    }
  }

  /// Get available editions (translations)
  Future<List<Edition>> getAvailableEditions({String? format, String? language}) async {
    try {
      String url = '$_alQuranBaseUrl/edition';
      List<String> queryParams = [];

      if (format != null) queryParams.add('format=$format');
      if (language != null) queryParams.add('language=$language');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> editionsData = jsonData['data'];

        return editionsData.map((editionJson) => Edition.fromJson(editionJson)).toList();
      } else {
        throw Exception('Failed to load editions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching editions: $e');
    }
  }

  /// Search verses by keyword
  Future<List<Verse>> searchVerses(String keyword, {String edition = 'en'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_alQuranBaseUrl/search/$keyword/all/$edition'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> versesData = jsonData['data']['matches'];

        return versesData.map((verseJson) => Verse.fromJson(verseJson)).toList();
      } else {
        throw Exception('Failed to search verses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching verses: $e');
    }
  }

  /// Get available reciters from MP3Quran
  Future<List<Reciter>> getReciters({String language = 'eng'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_mp3QuranBaseUrl/reciters?language=$language'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        log(jsonData.toString());
        final List<dynamic> recitersData = jsonData['reciters'];

        return recitersData.map((reciterJson) => Reciter.fromJson(reciterJson)).toList();
      } else {
        throw Exception('Failed to load reciters: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching reciters: $e');
    }
  }

  /// Get specific verse by reference
  Future<Verse> getVerse(String reference, {String edition = 'quran-uthmani'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_alQuranBaseUrl/ayah/$reference/$edition'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Verse.fromJson(jsonData['data']);
      } else {
        throw Exception('Failed to load verse: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching verse: $e');
    }
  }

  /// Get Juz (Para) information
  Future<List<Verse>> getJuz(int juzNumber, {String edition = 'quran-uthmani'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_alQuranBaseUrl/juz/$juzNumber/$edition'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> versesData = jsonData['data']['ayahs'];

        return versesData.map((verseJson) => Verse.fromJson(verseJson)).toList();
      } else {
        throw Exception('Failed to load juz: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching juz: $e');
    }
  }
}
