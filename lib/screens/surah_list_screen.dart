import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quran_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/download_provider.dart';
import '../widgets/surah_card.dart';
import '../widgets/audio_player_widget.dart';
import 'surah_detail_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    if (quranProvider.surahs.isEmpty) {
      await quranProvider.loadSurahs();
    }
    if (quranProvider.reciters.isEmpty) {
      await quranProvider.loadReciters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'السور',
          style: TextStyle(fontFamily: 'Amiri', fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter surahs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search surahs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Filter chip
          if (_selectedFilter != 'All')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Chip(
                    label: Text(_selectedFilter),
                    onDeleted: () {
                      setState(() {
                        _selectedFilter = 'All';
                      });
                    },
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    deleteIconColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),

          // Surahs list
          Expanded(
            child: Consumer<QuranProvider>(
              builder: (context, quranProvider, child) {
                if (quranProvider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading surahs...'),
                      ],
                    ),
                  );
                }

                if (quranProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${quranProvider.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => quranProvider.loadSurahs(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (quranProvider.surahs.isEmpty) {
                  return const Center(child: Text('No surahs found'));
                }

                // Filter surahs based on search and filter
                final filteredSurahs =
                    quranProvider.surahs.where((surah) {
                      // Search filter
                      final matchesSearch =
                          _searchQuery.isEmpty ||
                          surah.name.toLowerCase().contains(_searchQuery) ||
                          surah.englishName.toLowerCase().contains(_searchQuery) ||
                          surah.englishTranslation.toLowerCase().contains(_searchQuery) ||
                          surah.number.toString().contains(_searchQuery);

                      // Type filter
                      final matchesFilter =
                          _selectedFilter == 'All' ||
                          (_selectedFilter == 'Meccan' &&
                              surah.revelationType.toLowerCase() == 'meccan') ||
                          (_selectedFilter == 'Medinan' &&
                              surah.revelationType.toLowerCase() == 'medinan');

                      return matchesSearch && matchesFilter;
                    }).toList();

                if (filteredSurahs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No surahs match your search'
                              : 'No surahs match the selected filter',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => quranProvider.loadSurahs(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100), // Space for audio player
                    itemCount: filteredSurahs.length,
                    itemBuilder: (context, index) {
                      final surah = filteredSurahs[index];
                      return SurahCard(
                        surah: surah,
                        onTap: () => _navigateToSurahDetail(surah),
                        onPlayTap: () => _playSurahRecitation(surah),
                        showPlayButton: quranProvider.reciters.isNotEmpty,
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Audio player at bottom
          Consumer<AudioProvider>(
            builder: (context, audioProvider, child) {
              if (audioProvider.hasAudio) {
                return const AudioPlayerWidget();
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      floatingActionButton: Consumer<DownloadProvider>(
        builder: (context, downloadProvider, child) {
          if (downloadProvider.hasActiveDownloads) {
            return FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/downloads'),
              icon: const Icon(Icons.download),
              label: Text('${downloadProvider.activeCount} Downloads'),
              backgroundColor: Colors.blue,
            );
          }
          return FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/downloads'),
            child: const Icon(Icons.download),
            tooltip: 'Downloads',
          );
        },
      ),
    );
  }

  void _navigateToSurahDetail(surah) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SurahDetailScreen(surah: surah)),
    );
  }

  void _playSurahRecitation(surah) async {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    if (quranProvider.reciters.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No reciters available')));
      return;
    }

    // Show reciter selection if multiple reciters available
    if (quranProvider.reciters.length > 1) {
      _showReciterSelection(surah);
    } else {
      // Play with the first available reciter
      final reciter = quranProvider.reciters.first;
      try {
        await audioProvider.playSurah(reciter, surah.number);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playing ${surah.englishName} by ${reciter.name}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error playing recitation: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showReciterSelection(surah) {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.3,
            expand: false,
            builder:
                (context, scrollController) => Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Choose Reciter for ${surah.englishName}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),

                    // Reciters list
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: quranProvider.reciters.length,
                        itemBuilder: (context, index) {
                          final reciter = quranProvider.reciters[index];
                          final hasThisSurah = reciter.moshaf.any(
                            (moshaf) => moshaf.availableSurahs.contains(surah.number),
                          );

                          return ListTile(
                            leading: CircleAvatar(child: Text(reciter.letter)),
                            title: Text(reciter.name),
                            subtitle:
                                hasThisSurah
                                    ? const Text('Available')
                                    : const Text(
                                      'Not available',
                                      style: TextStyle(color: Colors.red),
                                    ),
                            enabled: hasThisSurah,
                            onTap:
                                hasThisSurah
                                    ? () async {
                                      Navigator.pop(context);
                                      final audioProvider = Provider.of<AudioProvider>(
                                        context,
                                        listen: false,
                                      );
                                      try {
                                        await audioProvider.playSurah(reciter, surah.number);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Playing ${surah.englishName} by ${reciter.name}',
                                              ),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error playing recitation: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                    : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Surahs'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('All'),
                  value: 'All',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Meccan'),
                  value: 'Meccan',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Medinan'),
                  value: 'Medinan',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ],
          ),
    );
  }
}
