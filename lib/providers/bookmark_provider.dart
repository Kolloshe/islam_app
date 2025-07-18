import 'package:flutter/foundation.dart';
import '../models/bookmark_model.dart';
import '../services/bookmark_service.dart';

class BookmarkProvider extends ChangeNotifier {
  final BookmarkService _bookmarkService = BookmarkService();

  // State variables
  List<Bookmark> _bookmarks = [];
  List<Bookmark> _filteredBookmarks = [];
  ReadingPosition? _lastReadPosition;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  BookmarkType? _filterType;
  List<String> _selectedTags = [];
  SortOption _sortOption = SortOption.dateDesc;

  // Getters
  List<Bookmark> get bookmarks => _filteredBookmarks;
  List<Bookmark> get allBookmarks => _bookmarks;
  ReadingPosition? get lastReadPosition => _lastReadPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  BookmarkType? get filterType => _filterType;
  List<String> get selectedTags => _selectedTags;
  SortOption get sortOption => _sortOption;

  // Computed getters
  bool get hasBookmarks => _bookmarks.isNotEmpty;
  int get totalBookmarks => _bookmarks.length;
  int get verseBookmarks => _bookmarks.where((b) => b.type == BookmarkType.verse).length;
  int get favoriteBookmarks => _bookmarks.where((b) => b.type == BookmarkType.favorite).length;
  bool get hasFilters => _filterType != null || _selectedTags.isNotEmpty || _searchQuery.isNotEmpty;

  /// Initialize bookmark provider
  Future<void> initialize() async {
    await loadBookmarks();
    await loadLastReadPosition();
  }

  /// Load all bookmarks
  Future<void> loadBookmarks() async {
    _setLoading(true);
    _clearError();

    try {
      _bookmarks = await _bookmarkService.getBookmarks();
      _applyFilters();
    } catch (e) {
      _setError('Failed to load bookmarks: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load last read position
  Future<void> loadLastReadPosition() async {
    try {
      _lastReadPosition = await _bookmarkService.getLastReadPosition();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load last read position: $e');
    }
  }

  /// Save a bookmark
  Future<bool> saveBookmark({
    required int surahNumber,
    required int verseNumber,
    required String surahName,
    required String verseText,
    String? translation,
    String? note,
    List<String>? tags,
    BookmarkType type = BookmarkType.verse,
  }) async {
    _clearError();

    try {
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

      await _bookmarkService.saveBookmark(bookmark);
      await loadBookmarks(); // Refresh list
      return true;
    } catch (e) {
      _setError('Failed to save bookmark: $e');
      return false;
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
    _clearError();

    try {
      final isAdded = await _bookmarkService.toggleBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        surahName: surahName,
        verseText: verseText,
        translation: translation,
        note: note,
        tags: tags,
        type: type,
      );

      await loadBookmarks(); // Refresh list
      return isAdded;
    } catch (e) {
      _setError('Failed to toggle bookmark: $e');
      return false;
    }
  }

  /// Update a bookmark
  Future<bool> updateBookmark(Bookmark bookmark) async {
    _clearError();

    try {
      await _bookmarkService.updateBookmark(bookmark);
      await loadBookmarks(); // Refresh list
      return true;
    } catch (e) {
      _setError('Failed to update bookmark: $e');
      return false;
    }
  }

  /// Delete a bookmark
  Future<bool> deleteBookmark(String bookmarkId) async {
    _clearError();

    try {
      await _bookmarkService.deleteBookmark(bookmarkId);
      await loadBookmarks(); // Refresh list
      return true;
    } catch (e) {
      _setError('Failed to delete bookmark: $e');
      return false;
    }
  }

  /// Check if a verse is bookmarked
  Future<bool> isBookmarked(int surahNumber, int verseNumber) async {
    try {
      return await _bookmarkService.isBookmarked(surahNumber, verseNumber);
    } catch (e) {
      return false;
    }
  }

  /// Get bookmark for a specific verse
  Future<Bookmark?> getBookmarkForVerse(int surahNumber, int verseNumber) async {
    try {
      return await _bookmarkService.getBookmarkForVerse(surahNumber, verseNumber);
    } catch (e) {
      return null;
    }
  }

  /// Save last read position
  Future<void> saveLastReadPosition({
    required int surahNumber,
    required int verseNumber,
    required String surahName,
    required int totalVersesRead,
    required double progressPercentage,
  }) async {
    try {
      final position = ReadingPosition(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        surahName: surahName,
        lastReadAt: DateTime.now(),
        totalVersesRead: totalVersesRead,
        progressPercentage: progressPercentage,
      );

      await _bookmarkService.saveLastReadPosition(position);
      _lastReadPosition = position;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save last read position: $e');
    }
  }

  /// Search bookmarks
  void searchBookmarks(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Filter by bookmark type
  void filterByType(BookmarkType? type) {
    _filterType = type;
    _applyFilters();
  }

  /// Filter by tags
  void filterByTags(List<String> tags) {
    _selectedTags = tags;
    _applyFilters();
  }

  /// Set sort option
  void setSortOption(SortOption option) {
    _sortOption = option;
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _filterType = null;
    _selectedTags = [];
    _applyFilters();
  }

  /// Get all unique tags
  Future<List<String>> getAllTags() async {
    try {
      return await _bookmarkService.getAllTags();
    } catch (e) {
      return [];
    }
  }

  /// Export bookmarks
  Future<String?> exportBookmarks() async {
    try {
      return await _bookmarkService.exportBookmarks();
    } catch (e) {
      _setError('Failed to export bookmarks: $e');
      return null;
    }
  }

  /// Import bookmarks
  Future<int?> importBookmarks(String jsonData) async {
    _clearError();

    try {
      final importedCount = await _bookmarkService.importBookmarks(jsonData);
      await loadBookmarks(); // Refresh list
      return importedCount;
    } catch (e) {
      _setError('Failed to import bookmarks: $e');
      return null;
    }
  }

  /// Clear all bookmarks
  Future<bool> clearAllBookmarks() async {
    _clearError();

    try {
      await _bookmarkService.clearAllBookmarks();
      await loadBookmarks(); // Refresh list
      return true;
    } catch (e) {
      _setError('Failed to clear bookmarks: $e');
      return false;
    }
  }

  /// Get bookmark statistics
  Future<Map<String, dynamic>> getBookmarkStats() async {
    try {
      return await _bookmarkService.getBookmarkStats();
    } catch (e) {
      return {};
    }
  }

  /// Apply current filters and sorting
  void _applyFilters() {
    var filtered = List<Bookmark>.from(_bookmarks);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((bookmark) {
            return bookmark.verseText.toLowerCase().contains(query) ||
                (bookmark.translation?.toLowerCase().contains(query) ?? false) ||
                bookmark.surahName.toLowerCase().contains(query) ||
                (bookmark.note?.toLowerCase().contains(query) ?? false) ||
                bookmark.tags.any((tag) => tag.toLowerCase().contains(query));
          }).toList();
    }

    // Apply type filter
    if (_filterType != null) {
      filtered = filtered.where((bookmark) => bookmark.type == _filterType).toList();
    }

    // Apply tag filter
    if (_selectedTags.isNotEmpty) {
      filtered =
          filtered.where((bookmark) {
            return _selectedTags.any((tag) => bookmark.tags.contains(tag));
          }).toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case SortOption.dateDesc:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.dateAsc:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.surahAsc:
        filtered.sort((a, b) {
          final surahComparison = a.surahNumber.compareTo(b.surahNumber);
          return surahComparison != 0 ? surahComparison : a.verseNumber.compareTo(b.verseNumber);
        });
        break;
      case SortOption.surahDesc:
        filtered.sort((a, b) {
          final surahComparison = b.surahNumber.compareTo(a.surahNumber);
          return surahComparison != 0 ? surahComparison : b.verseNumber.compareTo(a.verseNumber);
        });
        break;
    }

    _filteredBookmarks = filtered;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

enum SortOption {
  dateDesc('Newest First'),
  dateAsc('Oldest First'),
  surahAsc('Surah (1-114)'),
  surahDesc('Surah (114-1)');

  const SortOption(this.displayName);
  final String displayName;
}
