import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark_model.dart';

class BookmarkService {
  static const String _bookmarksKey = 'bookmarks';
  static const String _lastReadKey = 'last_read_position';
  static const String _readingStatsKey = 'reading_stats';

  /// Get all bookmarks
  Future<List<Bookmark>> getBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList(_bookmarksKey) ?? [];

      return bookmarksJson.map((json) {
        final Map<String, dynamic> data = jsonDecode(json);
        return Bookmark.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load bookmarks: $e');
    }
  }

  /// Get bookmarks by type
  Future<List<Bookmark>> getBookmarksByType(BookmarkType type) async {
    final bookmarks = await getBookmarks();
    return bookmarks.where((bookmark) => bookmark.type == type).toList();
  }

  /// Get bookmarks by tags
  Future<List<Bookmark>> getBookmarksByTags(List<String> tags) async {
    final bookmarks = await getBookmarks();
    return bookmarks.where((bookmark) {
      return tags.any((tag) => bookmark.tags.contains(tag));
    }).toList();
  }

  /// Save a bookmark
  Future<void> saveBookmark(Bookmark bookmark) async {
    try {
      final bookmarks = await getBookmarks();

      // Remove existing bookmark with same id if it exists
      bookmarks.removeWhere((b) => b.id == bookmark.id);

      // Add new bookmark at the beginning
      bookmarks.insert(0, bookmark);

      await _saveBookmarks(bookmarks);
    } catch (e) {
      throw Exception('Failed to save bookmark: $e');
    }
  }

  /// Delete a bookmark
  Future<void> deleteBookmark(String bookmarkId) async {
    try {
      final bookmarks = await getBookmarks();
      bookmarks.removeWhere((bookmark) => bookmark.id == bookmarkId);
      await _saveBookmarks(bookmarks);
    } catch (e) {
      throw Exception('Failed to delete bookmark: $e');
    }
  }

  /// Update a bookmark
  Future<void> updateBookmark(Bookmark bookmark) async {
    try {
      final bookmarks = await getBookmarks();
      final index = bookmarks.indexWhere((b) => b.id == bookmark.id);

      if (index != -1) {
        bookmarks[index] = bookmark;
        await _saveBookmarks(bookmarks);
      } else {
        throw Exception('Bookmark not found');
      }
    } catch (e) {
      throw Exception('Failed to update bookmark: $e');
    }
  }

  /// Check if a verse is bookmarked
  Future<bool> isBookmarked(int surahNumber, int verseNumber) async {
    try {
      final bookmarks = await getBookmarks();
      return bookmarks.any(
        (bookmark) => bookmark.surahNumber == surahNumber && bookmark.verseNumber == verseNumber,
      );
    } catch (e) {
      return false;
    }
  }

  /// Get bookmark for a specific verse
  Future<Bookmark?> getBookmarkForVerse(int surahNumber, int verseNumber) async {
    try {
      final bookmarks = await getBookmarks();
      return bookmarks.firstWhere(
        (bookmark) => bookmark.surahNumber == surahNumber && bookmark.verseNumber == verseNumber,
        orElse: () => throw StateError('Not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Toggle bookmark for a verse
  Future<bool> toggleBookmark({
    required int surahNumber,
    required int verseNumber,
    required String surahName,
    required String verseText,
    String? translation,
    String? note,
    List<String>? tags,
    BookmarkType type = BookmarkType.verse,
  }) async {
    try {
      final existingBookmark = await getBookmarkForVerse(surahNumber, verseNumber);

      if (existingBookmark != null) {
        await deleteBookmark(existingBookmark.id);
        return false; // Removed
      } else {
        final bookmark = Bookmark(
          id: '${surahNumber}_${verseNumber}_${DateTime.now().millisecondsSinceEpoch}',
          surahNumber: surahNumber,
          verseNumber: verseNumber,
          surahName: surahName,
          verseText: verseText,
          translation: translation,
          note: note,
          createdAt: DateTime.now(),
          tags: tags ?? [],
          type: type,
        );

        await saveBookmark(bookmark);
        return true; // Added
      }
    } catch (e) {
      throw Exception('Failed to toggle bookmark: $e');
    }
  }

  /// Get all unique tags from bookmarks
  Future<List<String>> getAllTags() async {
    try {
      final bookmarks = await getBookmarks();
      final allTags = <String>{};

      for (final bookmark in bookmarks) {
        allTags.addAll(bookmark.tags);
      }

      return allTags.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  /// Search bookmarks
  Future<List<Bookmark>> searchBookmarks(String query) async {
    try {
      final bookmarks = await getBookmarks();
      final lowerQuery = query.toLowerCase();

      return bookmarks.where((bookmark) {
        return bookmark.verseText.toLowerCase().contains(lowerQuery) ||
            (bookmark.translation?.toLowerCase().contains(lowerQuery) ?? false) ||
            bookmark.surahName.toLowerCase().contains(lowerQuery) ||
            (bookmark.note?.toLowerCase().contains(lowerQuery) ?? false) ||
            bookmark.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save last read position
  Future<void> saveLastReadPosition(ReadingPosition position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(position.toJson());
      await prefs.setString(_lastReadKey, json);
    } catch (e) {
      throw Exception('Failed to save reading position: $e');
    }
  }

  /// Get last read position
  Future<ReadingPosition?> getLastReadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_lastReadKey);

      if (json != null) {
        final Map<String, dynamic> data = jsonDecode(json);
        return ReadingPosition.fromJson(data);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear all bookmarks
  Future<void> clearAllBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bookmarksKey);
    } catch (e) {
      throw Exception('Failed to clear bookmarks: $e');
    }
  }

  /// Export bookmarks as JSON
  Future<String> exportBookmarks() async {
    try {
      final bookmarks = await getBookmarks();
      final data = {
        'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      return jsonEncode(data);
    } catch (e) {
      throw Exception('Failed to export bookmarks: $e');
    }
  }

  /// Import bookmarks from JSON
  Future<int> importBookmarks(String jsonData) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonData);
      final List<dynamic> bookmarksData = data['bookmarks'] ?? [];

      final importedBookmarks =
          bookmarksData.map((json) {
            return Bookmark.fromJson(json as Map<String, dynamic>);
          }).toList();

      final existingBookmarks = await getBookmarks();
      final allBookmarks = [...existingBookmarks];

      int importedCount = 0;
      for (final bookmark in importedBookmarks) {
        // Check if bookmark already exists
        final exists = allBookmarks.any(
          (b) => b.surahNumber == bookmark.surahNumber && b.verseNumber == bookmark.verseNumber,
        );

        if (!exists) {
          allBookmarks.add(bookmark);
          importedCount++;
        }
      }

      await _saveBookmarks(allBookmarks);
      return importedCount;
    } catch (e) {
      throw Exception('Failed to import bookmarks: $e');
    }
  }

  /// Get bookmark statistics
  Future<Map<String, dynamic>> getBookmarkStats() async {
    try {
      final bookmarks = await getBookmarks();
      final tags = await getAllTags();

      final stats = <String, dynamic>{
        'totalBookmarks': bookmarks.length,
        'verseBookmarks': bookmarks.where((b) => b.type == BookmarkType.verse).length,
        'favoriteBookmarks': bookmarks.where((b) => b.type == BookmarkType.favorite).length,
        'bookmarksWithNotes': bookmarks.where((b) => b.hasNote).length,
        'totalTags': tags.length,
        'oldestBookmark':
            bookmarks.isNotEmpty
                ? bookmarks.map((b) => b.createdAt).reduce((a, b) => a.isBefore(b) ? a : b)
                : null,
        'newestBookmark':
            bookmarks.isNotEmpty
                ? bookmarks.map((b) => b.createdAt).reduce((a, b) => a.isAfter(b) ? a : b)
                : null,
      };

      return stats;
    } catch (e) {
      return {};
    }
  }

  /// Private method to save bookmarks list
  Future<void> _saveBookmarks(List<Bookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson =
        bookmarks.map((bookmark) {
          return jsonEncode(bookmark.toJson());
        }).toList();

    await prefs.setStringList(_bookmarksKey, bookmarksJson);
  }
}
