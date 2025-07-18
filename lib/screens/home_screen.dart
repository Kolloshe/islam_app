import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/quran_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/azkar_provider.dart';
import '../providers/language_provider.dart';
import '../models/bookmark_model.dart';
import '../widgets/continue_reading_widget.dart';
import 'surah_list_screen.dart';
import 'surah_detail_screen.dart';
import 'search_screen.dart';
import 'reciters_screen.dart';
import 'azkar_screen.dart';
import 'bookmarks_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize providers on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookmarkProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quranApp),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ),
          ),
        ],
      ),
      body: Consumer6<
        QuranProvider,
        AudioProvider,
        BookmarkProvider,
        SettingsProvider,
        AzkarProvider,
        LanguageProvider
      >(
        builder: (
          context,
          quranProvider,
          audioProvider,
          bookmarkProvider,
          settings,
          azkarProvider,
          languageProvider,
          child,
        ) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.assalamuAlaikum,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.welcomeToYourQuranJourney,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).primaryColor.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.menu_book,
                        title: l10n.browseSurahs,
                        subtitle: '${quranProvider.surahs.length} ${l10n.chapters}',
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SurahListScreen()),
                            ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.search,
                        title: l10n.searchVerses,
                        subtitle: l10n.findSpecificVerses,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SearchScreen()),
                            ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.play_circle,
                        title: l10n.audioRecitations,
                        subtitle: '${quranProvider.reciters.length} ${l10n.reciters}',
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RecitersScreen()),
                            ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.auto_awesome,
                        title: l10n.azkarAndDhikr,
                        subtitle: l10n.dailyRemembrance,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AzkarScreen()),
                            ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.bookmark,
                        title: l10n.bookmarks,
                        subtitle: l10n.savedVerses,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const BookmarksScreen()),
                            ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.download,
                        title: l10n.downloads,
                        subtitle: l10n.offlineContent,
                        onTap: () => Navigator.pushNamed(context, '/downloads'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Continue Reading Section
                Text(
                  l10n.continueReading,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Continue Reading Widget
                ContinueReadingWidget(
                  lastReadPosition: bookmarkProvider.lastReadPosition,
                  surahs: quranProvider.surahs,
                  onContinueReading: (position) => _continueReading(position, quranProvider),
                  onSurahTap:
                      (surah) => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SurahDetailScreen(surah: surah)),
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _continueReading(ReadingPosition position, QuranProvider quranProvider) {
    // Find the surah by number
    final surah = quranProvider.surahs.firstWhere(
      (s) => s.number == position.surahNumber,
      orElse: () => quranProvider.surahs.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurahDetailScreen(surah: surah, initialVerse: position.verseNumber),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
