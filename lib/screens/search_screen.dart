import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/quran_provider.dart';
import '../providers/settings_provider.dart'; // Added import for SettingsProvider
import '../widgets/surah_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late TabController _tabController;

  List<String> _searchHistory = [];
  String _selectedLanguage = 'en.sahih';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSearchHistory();

    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadSearchHistory() {
    // In a real app, load from SharedPreferences
    setState(() {
      _searchHistory = ['Bismillah', 'Alhamdulillahi', 'Rahman', 'Rahim', 'Prayer'];
    });
  }

  void _saveToHistory(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.take(10).toList();
      }
    });

    // In a real app, save to SharedPreferences
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    _saveToHistory(query);
    setState(() {
      _isSearching = true;
    });

    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    quranProvider.searchVerses(query).then((_) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.searchQuran ?? 'Search Quran'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n?.searchResults ?? 'Search Results'),
            Tab(text: l10n?.searchHistory ?? 'Search History'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Input
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: l10n?.searchHint ?? 'Search for verses, words, or topics...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        )
                        : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() {}),
              onSubmitted: _performSearch,
            ),
          ),

          // Search Button & Language Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _searchController.text.isNotEmpty
                            ? () => _performSearch(_searchController.text)
                            : null,
                    child:
                        _isSearching
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Language Selector
          _buildLanguageSelector(l10n),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildSearchResults(), _buildSearchHistory(l10n)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(l10n?.translation ?? 'Translation: '),
          DropdownButton<String>(
            value: _selectedLanguage,
            items: [
              DropdownMenuItem(
                value: 'en.sahih',
                child: Text(l10n?.sahihInternational ?? 'Sahih International'),
              ),
              DropdownMenuItem(value: 'en.pickthall', child: Text(l10n?.pickthall ?? 'Pickthall')),
              DropdownMenuItem(value: 'en.yusufali', child: Text(l10n?.yusufAli ?? 'Yusuf Ali')),
              DropdownMenuItem(
                value: 'ur.jalandhry',
                child: Text(l10n?.urduJalandhry ?? 'Urdu - Jalandhry'),
              ),
              DropdownMenuItem(
                value: 'id.indonesian',
                child: Text(l10n?.indonesian ?? 'Indonesian'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedLanguage = value;
                });
                if (_searchController.text.isNotEmpty) {
                  _performSearch(_searchController.text);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final l10n = AppLocalizations.of(context);

    return Consumer<QuranProvider>(
      builder: (context, quranProvider, child) {
        if (quranProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (quranProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(l10n?.searchError ?? 'Search error occurred'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _performSearch(_searchController.text),
                  child: Text(l10n?.retry ?? 'Retry'),
                ),
              ],
            ),
          );
        }

        if (quranProvider.searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isEmpty
                      ? 'Enter a search term to find verses'
                      : (l10n?.noResults ?? 'No results found'),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: quranProvider.searchResults.length,
          itemBuilder: (context, index) {
            final verse = quranProvider.searchResults[index];
            return ListTile(
              title: Text(
                verse.text,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 18),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (verse.translation != null) Text(verse.translation!),
                  const SizedBox(height: 4),
                  Text(
                    'Verse ${verse.numberInSurah}',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary),
                  ),
                ],
              ),
              onTap: () {
                // Navigate to specific verse - would need surah info
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navigate to verse functionality would be added here'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchHistory(AppLocalizations? l10n) {
    if (_searchHistory.isEmpty) {
      return const Center(child: Text('No recent searches'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.recentSearches ?? 'Recent Searches',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(onPressed: _clearHistory, child: Text(l10n?.clearHistory ?? 'Clear')),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(query),
                trailing: IconButton(
                  onPressed: () => _removeFromHistory(query),
                  icon: const Icon(Icons.close, size: 20),
                ),
                onTap: () {
                  _searchController.text = query;
                  _performSearch(query);
                  _tabController.animateTo(0); // Switch to results tab
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _clearHistory() {
    setState(() {
      _searchHistory.clear();
    });
    // In a real app, clear from SharedPreferences
  }

  void _removeFromHistory(String query) {
    setState(() {
      _searchHistory.remove(query);
    });
    // In a real app, save to SharedPreferences
  }
}
