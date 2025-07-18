import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import '../models/surah_model.dart';
import '../models/reciter_model.dart';

class CacheService {
  static const String _databaseName = 'quran_cache.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _surahsTable = 'surahs';
  static const String _versesTable = 'verses';
  static const String _audioFilesTable = 'audio_files';

  Database? _database;
  String? _audioDirectory;
  String? _cacheDirectory;

  /// Initialize cache service
  Future<void> initialize() async {
    await _initializeDatabase();
    await _initializeDirectories();
  }

  /// Initialize database
  Future<void> _initializeDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final databasePath = '${documentsDirectory.path}/$_databaseName';

      _database = await openDatabase(
        databasePath,
        version: _databaseVersion,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );
    } catch (e) {
      debugPrint('Failed to initialize database: $e');
    }
  }

  /// Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    // Surahs table
    await db.execute('''
      CREATE TABLE $_surahsTable (
        number INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        englishName TEXT NOT NULL,
        englishTranslation TEXT NOT NULL,
        numberOfAyahs INTEGER NOT NULL,
        revelationType TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    // Verses table
    await db.execute('''
      CREATE TABLE $_versesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number INTEGER NOT NULL,
        numberInSurah INTEGER NOT NULL,
        text TEXT NOT NULL,
        translation TEXT,
        edition TEXT,
        juz INTEGER,
        manzil INTEGER,
        page INTEGER,
        ruku INTEGER,
        hizbQuarter INTEGER,
        sajda INTEGER,
        cached_at INTEGER NOT NULL,
        UNIQUE(number, edition)
      )
    ''');

    // Audio files table
    await db.execute('''
      CREATE TABLE $_audioFilesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_number INTEGER NOT NULL,
        reciter_id INTEGER NOT NULL,
        reciter_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        download_date INTEGER NOT NULL,
        last_accessed INTEGER NOT NULL,
        UNIQUE(surah_number, reciter_id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_verses_surah ON $_versesTable(numberInSurah)');
    await db.execute('CREATE INDEX idx_audio_surah ON $_audioFilesTable(surah_number)');
    await db.execute('CREATE INDEX idx_verses_edition ON $_versesTable(edition)');
  }

  /// Upgrade database
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
    }
  }

  /// Initialize directories for file storage
  Future<void> _initializeDirectories() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();

      _cacheDirectory = '${appDocDir.path}/cache';
      _audioDirectory = '${appDocDir.path}/audio';

      await Directory(_cacheDirectory!).create(recursive: true);
      await Directory(_audioDirectory!).create(recursive: true);
    } catch (e) {
      debugPrint('Failed to initialize directories: $e');
    }
  }

  /// Cache surahs data
  Future<void> cacheSurahs(List<Surah> surahs) async {
    if (_database == null) return;

    try {
      final batch = _database!.batch();
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final surah in surahs) {
        batch.insert(_surahsTable, {
          'number': surah.number,
          'name': surah.name,
          'englishName': surah.englishName,
          'englishTranslation': surah.englishTranslation,
          'numberOfAyahs': surah.numberOfAyahs,
          'revelationType': surah.revelationType,
          'cached_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Failed to cache surahs: $e');
    }
  }

  /// Get cached surahs
  Future<List<Surah>> getCachedSurahs() async {
    if (_database == null) return [];

    try {
      final maps = await _database!.query(_surahsTable);
      return maps
          .map(
            (map) => Surah(
              number: map['number'] as int,
              name: map['name'] as String,
              englishName: map['englishName'] as String,
              englishTranslation: map['englishTranslation'] as String,
              numberOfAyahs: map['numberOfAyahs'] as int,
              revelationType: map['revelationType'] as String,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Failed to get cached surahs: $e');
      return [];
    }
  }

  /// Cache verses for a surah
  Future<void> cacheVerses(List<Verse> verses, String edition) async {
    if (_database == null) return;

    try {
      final batch = _database!.batch();
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final verse in verses) {
        batch.insert(_versesTable, {
          'number': verse.number,
          'numberInSurah': verse.numberInSurah,
          'text': verse.text,
          'translation': verse.translation,
          'edition': edition,
          'juz': verse.juz,
          'manzil': verse.manzil,
          'page': verse.page,
          'ruku': verse.ruku,
          'hizbQuarter': verse.hizbQuarter,
          'sajda': verse.sajda ? 1 : 0,
          'cached_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Failed to cache verses: $e');
    }
  }

  /// Get cached verses for a surah (by numberInSurah)
  Future<List<Verse>> getCachedVerses(int surahNumber, {String? edition}) async {
    if (_database == null) return [];

    try {
      // Create a query to get verses by surah number
      // Since we don't have surahNumber field, we'll need to calculate it
      // or modify the query based on available fields
      final whereClause = edition != null ? 'edition = ?' : '1=1';
      final whereArgs = edition != null ? [edition] : <dynamic>[];

      final maps = await _database!.query(
        _versesTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'numberInSurah ASC',
      );

      return maps
          .map(
            (map) => Verse(
              number: map['number'] as int,
              numberInSurah: map['numberInSurah'] as int,
              text: map['text'] as String,
              translation: map['translation'] as String?,
              juz: map['juz'] as int,
              manzil: map['manzil'] as int,
              page: map['page'] as int,
              ruku: map['ruku'] as int,
              hizbQuarter: map['hizbQuarter'] as int,
              sajda: (map['sajda'] as int) == 1,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Failed to get cached verses: $e');
      return [];
    }
  }

  /// Download and cache audio file
  Future<String?> downloadAndCacheAudio({
    required String url,
    required int surahNumber,
    required Reciter reciter,
    Function(double)? onProgress,
  }) async {
    if (_audioDirectory == null) return null;

    try {
      final fileName = 'surah_${surahNumber}_reciter_${reciter.id}.mp3';
      final filePath = '$_audioDirectory/$fileName';
      final file = File(filePath);

      // Check if already exists
      if (await file.exists()) {
        await _updateAudioAccessTime(surahNumber, reciter.id);
        return filePath;
      }

      // Download file
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        var downloadedBytes = 0;

        final sink = file.openWrite();

        await response.stream
            .listen(
              (List<int> chunk) {
                sink.add(chunk);
                downloadedBytes += chunk.length;

                if (contentLength > 0) {
                  final progress = downloadedBytes / contentLength;
                  onProgress?.call(progress);
                }
              },
              onDone: () async {
                await sink.close();
              },
              onError: (error) async {
                await sink.close();
                if (await file.exists()) {
                  await file.delete();
                }
              },
            )
            .asFuture();

        // Cache audio file info in database
        await _cacheAudioFileInfo(
          surahNumber: surahNumber,
          reciterId: reciter.id,
          reciterName: reciter.name,
          filePath: filePath,
          fileSize: await file.length(),
        );

        return filePath;
      }
    } catch (e) {
      debugPrint('Failed to download audio: $e');
    }

    return null;
  }

  /// Cache audio file info in database
  Future<void> _cacheAudioFileInfo({
    required int surahNumber,
    required int reciterId,
    required String reciterName,
    required String filePath,
    required int fileSize,
  }) async {
    if (_database == null) return;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      await _database!.insert(_audioFilesTable, {
        'surah_number': surahNumber,
        'reciter_id': reciterId,
        'reciter_name': reciterName,
        'file_path': filePath,
        'file_size': fileSize,
        'download_date': now,
        'last_accessed': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Failed to cache audio file info: $e');
    }
  }

  /// Update audio file access time
  Future<void> _updateAudioAccessTime(int surahNumber, int reciterId) async {
    if (_database == null) return;

    try {
      await _database!.update(
        _audioFilesTable,
        {'last_accessed': DateTime.now().millisecondsSinceEpoch},
        where: 'surah_number = ? AND reciter_id = ?',
        whereArgs: [surahNumber, reciterId],
      );
    } catch (e) {
      debugPrint('Failed to update access time: $e');
    }
  }

  /// Get cached audio file path
  Future<String?> getCachedAudioFile(int surahNumber, int reciterId) async {
    if (_database == null) return null;

    try {
      final maps = await _database!.query(
        _audioFilesTable,
        where: 'surah_number = ? AND reciter_id = ?',
        whereArgs: [surahNumber, reciterId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        final filePath = maps.first['file_path'] as String;
        final file = File(filePath);

        if (await file.exists()) {
          await _updateAudioAccessTime(surahNumber, reciterId);
          return filePath;
        } else {
          // File doesn't exist, remove from database
          await _removeAudioFileRecord(surahNumber, reciterId);
        }
      }
    } catch (e) {
      debugPrint('Failed to get cached audio file: $e');
    }

    return null;
  }

  /// Remove audio file record from database
  Future<void> _removeAudioFileRecord(int surahNumber, int reciterId) async {
    if (_database == null) return;

    try {
      await _database!.delete(
        _audioFilesTable,
        where: 'surah_number = ? AND reciter_id = ?',
        whereArgs: [surahNumber, reciterId],
      );
    } catch (e) {
      debugPrint('Failed to remove audio file record: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    if (_database == null) return {};

    try {
      // Get audio files stats
      final audioStats = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as file_count,
          SUM(file_size) as total_size,
          AVG(file_size) as avg_size
        FROM $_audioFilesTable
      ''');

      // Get verses stats
      final versesStats = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as verse_count,
          COUNT(DISTINCT numberInSurah) as surah_count,
          COUNT(DISTINCT edition) as edition_count
        FROM $_versesTable
      ''');

      // Get surahs stats
      final surahsStats = await _database!.rawQuery('''
        SELECT COUNT(*) as cached_surahs
        FROM $_surahsTable
      ''');

      // Calculate directory sizes
      final audioDirectorySize = await _getDirectorySize(_audioDirectory);
      final cacheDirectorySize = await _getDirectorySize(_cacheDirectory);

      return {
        'audio_files': audioStats.first,
        'verses': versesStats.first,
        'surahs': surahsStats.first,
        'audio_directory_size': audioDirectorySize,
        'cache_directory_size': cacheDirectorySize,
        'total_size': audioDirectorySize + cacheDirectorySize,
      };
    } catch (e) {
      debugPrint('Failed to get cache stats: $e');
      return {};
    }
  }

  /// Get directory size in bytes
  Future<int> _getDirectorySize(String? directoryPath) async {
    if (directoryPath == null) return 0;

    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) return 0;

      int totalSize = 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('Failed to calculate directory size: $e');
      return 0;
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    try {
      // Clear database
      if (_database != null) {
        await _database!.delete(_surahsTable);
        await _database!.delete(_versesTable);
        await _database!.delete(_audioFilesTable);
      }

      // Clear audio files
      if (_audioDirectory != null) {
        final audioDir = Directory(_audioDirectory!);
        if (await audioDir.exists()) {
          await audioDir.delete(recursive: true);
          await audioDir.create();
        }
      }

      // Clear cache files
      if (_cacheDirectory != null) {
        final cacheDir = Directory(_cacheDirectory!);
        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
          await cacheDir.create();
        }
      }
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  /// Get list of downloaded audio files
  Future<List<Map<String, dynamic>>> getDownloadedAudioFiles() async {
    if (_database == null) return [];

    try {
      return await _database!.query(_audioFilesTable, orderBy: 'download_date DESC');
    } catch (e) {
      debugPrint('Failed to get downloaded audio files: $e');
      return [];
    }
  }

  /// Delete specific audio file
  Future<bool> deleteAudioFile(int surahNumber, int reciterId) async {
    if (_database == null) return false;

    try {
      // Get file path
      final maps = await _database!.query(
        _audioFilesTable,
        where: 'surah_number = ? AND reciter_id = ?',
        whereArgs: [surahNumber, reciterId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        final filePath = maps.first['file_path'] as String;
        final file = File(filePath);

        // Delete file if exists
        if (await file.exists()) {
          await file.delete();
        }

        // Remove from database
        await _database!.delete(
          _audioFilesTable,
          where: 'surah_number = ? AND reciter_id = ?',
          whereArgs: [surahNumber, reciterId],
        );

        return true;
      }
    } catch (e) {
      debugPrint('Failed to delete audio file: $e');
    }

    return false;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _database?.close();
  }
}
