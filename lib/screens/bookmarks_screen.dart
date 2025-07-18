import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../models/bookmark_model.dart';
import '../widgets/bookmark_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  bool _isSelectionMode = false;
  final Set<String> _selectedBookmarks = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize bookmarks on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookmarkProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _isSelectionMode
                ? Text('${_selectedBookmarks.length} selected')
                : const Text('Bookmarks'),
        actions: _buildAppBarActions(),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.bookmark)),
            Tab(text: 'Verses', icon: Icon(Icons.menu_book)),
            Tab(text: 'Favorites', icon: Icon(Icons.favorite)),
          ],
        ),
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildSearchBar(provider),
              _buildFiltersRow(provider),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookmarksList(provider, null),
                    _buildBookmarksList(provider, BookmarkType.verse),
                    _buildBookmarksList(provider, BookmarkType.favorite),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _isSelectionMode ? null : _buildFloatingActionButton(),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isSelectionMode) {
      return [
        IconButton(
          onPressed: _selectedBookmarks.isNotEmpty ? _deleteSelectedBookmarks : null,
          icon: const Icon(Icons.delete),
        ),
        IconButton(
          onPressed: _selectedBookmarks.isNotEmpty ? _shareSelectedBookmarks : null,
          icon: const Icon(Icons.share),
        ),
        IconButton(onPressed: _exitSelectionMode, icon: const Icon(Icons.close)),
      ];
    }

    return [
      IconButton(onPressed: _showSortOptions, icon: const Icon(Icons.sort)),
      IconButton(onPressed: _showMoreOptions, icon: const Icon(Icons.more_vert)),
    ];
  }

  Widget _buildSearchBar(BookmarkProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search bookmarks...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      provider.searchBookmarks('');
                    },
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: provider.searchBookmarks,
      ),
    );
  }

  Widget _buildFiltersRow(BookmarkProvider provider) {
    if (!provider.hasFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('Filters: '),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                if (provider.filterType != null)
                  Chip(
                    label: Text(provider.filterType!.displayName),
                    onDeleted: () => provider.filterByType(null),
                  ),
                if (provider.selectedTags.isNotEmpty)
                  ...provider.selectedTags.map(
                    (tag) => Chip(
                      label: Text(tag),
                      onDeleted: () {
                        final tags = List<String>.from(provider.selectedTags);
                        tags.remove(tag);
                        provider.filterByTags(tags);
                      },
                    ),
                  ),
              ],
            ),
          ),
          TextButton(onPressed: provider.clearFilters, child: const Text('Clear All')),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(BookmarkProvider provider, BookmarkType? filterType) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return _buildErrorWidget(provider);
    }

    // Filter bookmarks based on tab
    var bookmarks = provider.bookmarks;
    if (filterType != null) {
      bookmarks = bookmarks.where((b) => b.type == filterType).toList();
    }

    if (bookmarks.isEmpty) {
      return _buildEmptyWidget(filterType);
    }

    return RefreshIndicator(
      onRefresh: provider.loadBookmarks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookmarks.length,
        itemBuilder: (context, index) {
          final bookmark = bookmarks[index];
          return BookmarkCard(
            bookmark: bookmark,
            isSelected: _selectedBookmarks.contains(bookmark.id),
            isSelectionMode: _isSelectionMode,
            onTap: () => _handleBookmarkTap(bookmark),
            onLongPress: () => _handleBookmarkLongPress(bookmark),
            onToggleSelection: () => _toggleBookmarkSelection(bookmark.id),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(BookmarkProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to Load Bookmarks', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            provider.error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: provider.loadBookmarks, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(BookmarkType? filterType) {
    String message;
    String subtitle;
    IconData icon;

    switch (filterType) {
      case BookmarkType.verse:
        message = 'No Verse Bookmarks';
        subtitle = 'Start bookmarking verses while reading';
        icon = Icons.menu_book;
        break;
      case BookmarkType.favorite:
        message = 'No Favorites';
        subtitle = 'Mark your favorite verses';
        icon = Icons.favorite_border;
        break;
      default:
        message = 'No Bookmarks Yet';
        subtitle = 'Start bookmarking verses to see them here';
        icon = Icons.bookmark_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            child: const Text('Start Reading'),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    return Consumer<BookmarkProvider>(
      builder: (context, provider, child) {
        if (!provider.hasBookmarks) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: _enterSelectionMode,
          icon: const Icon(Icons.checklist),
          label: const Text('Select'),
        );
      },
    );
  }

  void _handleBookmarkTap(Bookmark bookmark) {
    if (_isSelectionMode) {
      _toggleBookmarkSelection(bookmark.id);
    } else {
      // Navigate to the specific verse
      Navigator.pushNamed(
        context,
        '/surah-detail',
        arguments: {'surahNumber': bookmark.surahNumber, 'verseNumber': bookmark.verseNumber},
      );
    }
  }

  void _handleBookmarkLongPress(Bookmark bookmark) {
    if (!_isSelectionMode) {
      _enterSelectionMode();
      _toggleBookmarkSelection(bookmark.id);
    }
  }

  void _toggleBookmarkSelection(String bookmarkId) {
    setState(() {
      if (_selectedBookmarks.contains(bookmarkId)) {
        _selectedBookmarks.remove(bookmarkId);
      } else {
        _selectedBookmarks.add(bookmarkId);
      }
    });
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedBookmarks.clear();
    });
  }

  void _deleteSelectedBookmarks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Bookmarks'),
            content: Text('Delete ${_selectedBookmarks.length} bookmark(s)?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final provider = context.read<BookmarkProvider>();
      for (final bookmarkId in _selectedBookmarks) {
        await provider.deleteBookmark(bookmarkId);
      }
      _exitSelectionMode();
    }
  }

  void _shareSelectedBookmarks() {
    // Implement bookmark sharing
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Sharing ${_selectedBookmarks.length} bookmark(s)')));
  }

  void _showSortOptions() {
    final provider = context.read<BookmarkProvider>();

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sort By', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ...SortOption.values.map(
                  (option) => ListTile(
                    title: Text(option.displayName),
                    trailing:
                        provider.sortOption == option
                            ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                            : null,
                    onTap: () {
                      provider.setSortOption(option);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Export Bookmarks'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportBookmarks();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Import Bookmarks'),
                  onTap: () {
                    Navigator.pop(context);
                    _importBookmarks();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Bookmark Statistics'),
                  onTap: () {
                    Navigator.pop(context);
                    _showBookmarkStats();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.clear_all),
                  title: const Text('Clear All Bookmarks'),
                  textColor: Theme.of(context).colorScheme.error,
                  iconColor: Theme.of(context).colorScheme.error,
                  onTap: () {
                    Navigator.pop(context);
                    _clearAllBookmarks();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _exportBookmarks() async {
    final provider = context.read<BookmarkProvider>();
    final exported = await provider.exportBookmarks();

    if (exported != null) {
      // In a real app, save to file or share
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bookmarks exported successfully')));
    }
  }

  void _importBookmarks() async {
    // In a real app, pick file and read content
    const sampleData = '{"bookmarks":[],"exportedAt":"2024-01-01T00:00:00.000Z","version":"1.0"}';

    final provider = context.read<BookmarkProvider>();
    final imported = await provider.importBookmarks(sampleData);

    if (imported != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$imported bookmark(s) imported')));
    }
  }

  void _showBookmarkStats() async {
    final provider = context.read<BookmarkProvider>();
    final stats = await provider.getBookmarkStats();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bookmark Statistics'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Total Bookmarks', '${stats['totalBookmarks'] ?? 0}'),
                _buildStatRow('Verse Bookmarks', '${stats['verseBookmarks'] ?? 0}'),
                _buildStatRow('Favorite Bookmarks', '${stats['favoriteBookmarks'] ?? 0}'),
                _buildStatRow('With Notes', '${stats['bookmarksWithNotes'] ?? 0}'),
                _buildStatRow('Total Tags', '${stats['totalTags'] ?? 0}'),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
      ),
    );
  }

  void _clearAllBookmarks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Bookmarks'),
            content: const Text(
              'This will permanently delete all your bookmarks. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clear All'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final provider = context.read<BookmarkProvider>();
      final success = await provider.clearAllBookmarks();

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All bookmarks cleared')));
      }
    }
  }
}
