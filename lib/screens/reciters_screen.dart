import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:quran_app/providers/settings_provider.dart';
import '../providers/quran_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/download_provider.dart';
import '../models/reciter_model.dart';
import '../widgets/audio_player_widget.dart';

class RecitersScreen extends StatefulWidget {
  const RecitersScreen({super.key});

  @override
  State<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends State<RecitersScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReciters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReciters() async {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    if (quranProvider.reciters.isEmpty) {
      await quranProvider.loadReciters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.audioReciters),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: l10n.aboutAudio,
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
                hintText: l10n.searchReciters,
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

          // Reciters list
          Expanded(
            child: Consumer2<QuranProvider, AudioProvider>(
              builder: (context, quranProvider, audioProvider, child) {
                if (quranProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (quranProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.errorLoadingReciters,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quranProvider.error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => quranProvider.loadReciters(),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  );
                }

                final filteredReciters =
                    quranProvider.reciters.where((reciter) {
                      return _searchQuery.isEmpty ||
                          reciter.name.toLowerCase().contains(_searchQuery);
                    }).toList();

                if (filteredReciters.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noRecitersFound,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tryDifferentKeywords,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh:
                      () => quranProvider.loadReciters(
                        language:
                            context.read<SettingsProvider>().selectedLanguage == 'English'
                                ? 'eng'
                                : 'ar',
                      ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredReciters.length,
                    itemBuilder: (context, index) {
                      final reciter = filteredReciters[index];
                      final isCurrentReciter = audioProvider.currentReciter?.id == reciter.id;

                      return ReciterCard(
                        reciter: reciter,
                        isPlaying: isCurrentReciter && audioProvider.isPlaying,
                        isSelected: isCurrentReciter,
                        onTap: () => _showSurahSelection(reciter),
                        onPlayTap: () => _showSurahSelection(reciter),
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
    );
  }

  void _showSurahSelection(Reciter reciter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SurahSelectionSheet(reciter: reciter),
    );
  }

  void _showInfoDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.aboutAudioRecitations),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.listenToBeautifulQuran, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.features,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.highQualityAudio),
                  Text(l10n.multipleReciters),
                  Text(l10n.backgroundPlayback),
                  Text(l10n.speedControl),
                  Text(l10n.offlineListening),
                  const SizedBox(height: 16),
                  Text(
                    l10n.audioNote,
                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.gotIt))],
          ),
    );
  }
}

class ReciterCard extends StatelessWidget {
  final Reciter reciter;
  final bool isPlaying;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPlayTap;

  const ReciterCard({
    super.key,
    required this.reciter,
    required this.isPlaying,
    required this.isSelected,
    required this.onTap,
    required this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Reciter avatar/icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).primaryColor.withOpacity(0.3),
                    width: isSelected ? 3 : 2,
                  ),
                ),
                child: Icon(Icons.person, size: 28, color: Theme.of(context).primaryColor),
              ),

              const SizedBox(width: 16),

              // Reciter info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reciter.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reciter.moshaf.length} ${l10n.collectionsAvailable}',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isSelected
                                ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reciter.letter,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(
                            isPlaying ? Icons.volume_up : Icons.pause,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPlaying ? l10n.currentlyPlaying : l10n.currentlySelected,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Play button
              IconButton(
                onPressed: onPlayTap,
                icon: Icon(
                  isPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 40,
                  color: Theme.of(context).primaryColor,
                ),
                tooltip: isPlaying ? 'Pause' : 'Play',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SurahSelectionSheet extends StatefulWidget {
  final Reciter reciter;

  const SurahSelectionSheet({super.key, required this.reciter});

  @override
  State<SurahSelectionSheet> createState() => _SurahSelectionSheetState();
}

class _SurahSelectionSheetState extends State<SurahSelectionSheet> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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

              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      widget.reciter.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.chooseSurahToListen, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchSurahs,
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

              const SizedBox(height: 16),

              // Surahs list
              Expanded(
                child: Consumer3<QuranProvider, AudioProvider, DownloadProvider>(
                  builder: (context, quranProvider, audioProvider, downloadProvider, child) {
                    final availableSurahs =
                        widget.reciter.moshaf.isNotEmpty
                            ? widget.reciter.moshaf.first.availableSurahs
                            : <int>[];

                    final filteredSurahs =
                        quranProvider.surahs.where((surah) {
                          final matchesSearch =
                              _searchQuery.isEmpty ||
                              surah.englishName.toLowerCase().contains(_searchQuery) ||
                              surah.name.contains(_searchQuery);
                          final isAvailable = availableSurahs.contains(surah.number);
                          return matchesSearch && isAvailable;
                        }).toList();

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredSurahs.length,
                      itemBuilder: (context, index) {
                        final surah = filteredSurahs[index];
                        final isCurrentSurah =
                            audioProvider.currentSurahNumber == surah.number &&
                            audioProvider.currentReciter?.id == widget.reciter.id;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    isCurrentSurah
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context).primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  surah.number.toString(),
                                  style: TextStyle(
                                    color:
                                        isCurrentSurah
                                            ? Colors.white
                                            : Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              surah.name,
                              style: const TextStyle(fontFamily: 'Amiri', fontSize: 16),
                            ),
                            subtitle: Text(surah.englishName),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Download button
                                FutureBuilder<bool>(
                                  future: downloadProvider.isSurahAudioDownloaded(
                                    surah.number,
                                    widget.reciter,
                                  ),
                                  builder: (context, snapshot) {
                                    final isDownloaded = snapshot.data ?? false;

                                    return IconButton(
                                      icon: Icon(
                                        isDownloaded ? Icons.download_done : Icons.download,
                                        color: isDownloaded ? Colors.green : Colors.grey[600],
                                        size: 20,
                                      ),
                                      onPressed:
                                          isDownloaded
                                              ? null
                                              : () async {
                                                final success = await downloadProvider
                                                    .downloadSurahAudio(
                                                      surah.number,
                                                      surah.englishName,
                                                      widget.reciter,
                                                    );

                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        success
                                                            ? l10n.downloadStartedFor(
                                                              surah.englishName,
                                                            )
                                                            : l10n.failedToStartDownload,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                      tooltip: isDownloaded ? l10n.downloaded : l10n.downloadAudio,
                                    );
                                  },
                                ),
                                // Play button
                                IconButton(
                                  icon: Icon(
                                    isCurrentSurah && audioProvider.isPlaying
                                        ? Icons.volume_up
                                        : Icons.play_arrow,
                                    color:
                                        isCurrentSurah && audioProvider.isPlaying
                                            ? Colors.green
                                            : null,
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await audioProvider.playSurah(widget.reciter, surah.number);
                                    audioProvider.setSurahName(surah.englishName);
                                  },
                                  tooltip: l10n.playAudio,
                                ),
                              ],
                            ),
                            onTap: () async {
                              Navigator.pop(context);
                              await audioProvider.playSurah(widget.reciter, surah.number);
                              audioProvider.setSurahName(surah.englishName);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
