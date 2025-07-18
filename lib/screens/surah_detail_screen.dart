import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/surah_model.dart';
import '../providers/quran_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/settings_provider.dart';

class SurahDetailScreen extends StatefulWidget {
  final Surah surah;
  final int? initialVerse;

  const SurahDetailScreen({super.key, required this.surah, this.initialVerse});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Load surah verses on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSurahVerses();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    // Save final reading position when leaving the screen
    _saveFinalReadingPosition();

    super.dispose();
  }

  void _saveFinalReadingPosition() {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
    final currentSurah = quranProvider.currentSurah;
    final verses = currentSurah?.verses;

    if (verses != null && verses.isNotEmpty) {
      // Get the last visible verse based on scroll position
      final scrollOffset = _scrollController.offset;
      final estimatedVerseIndex = (scrollOffset / 150).round();
      final lastVerseNumber = (estimatedVerseIndex + 1).clamp(1, verses.length);

      // Calculate progress percentage
      final progressPercentage = (lastVerseNumber / verses.length) * 100;

      // Save reading position
      bookmarkProvider.saveLastReadPosition(
        surahNumber: widget.surah.number,
        verseNumber: lastVerseNumber,
        surahName: widget.surah.name,
        totalVersesRead: lastVerseNumber,
        progressPercentage: progressPercentage,
      );
    }
  }

  void _scrollListener() {
    if (_scrollController.offset > 200 && !_showFab) {
      setState(() => _showFab = true);
    } else if (_scrollController.offset <= 200 && _showFab) {
      setState(() => _showFab = false);
    }

    // Track reading progress
    _trackReadingProgress();
  }

  void _trackReadingProgress() {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
    final currentSurah = quranProvider.currentSurah;
    final verses = currentSurah?.verses;

    if (verses != null && verses.isNotEmpty) {
      // Calculate which verse the user is currently viewing based on scroll position
      final scrollOffset = _scrollController.offset;
      final estimatedVerseIndex = (scrollOffset / 150).round(); // Approximate verse height
      final currentVerseNumber = (estimatedVerseIndex + 1).clamp(1, verses.length);

      // Calculate progress percentage
      final progressPercentage = (currentVerseNumber / verses.length) * 100;

      // Save reading position
      bookmarkProvider.saveLastReadPosition(
        surahNumber: widget.surah.number,
        verseNumber: currentVerseNumber,
        surahName: widget.surah.name,
        totalVersesRead: currentVerseNumber,
        progressPercentage: progressPercentage,
      );
    }
  }

  void _loadSurahVerses() {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    quranProvider.loadSurah(widget.surah.number).then((_) {
      // Scroll to initial verse if specified
      if (widget.initialVerse != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToVerse(widget.initialVerse!);
        });
      }
    });
  }

  void _scrollToVerse(int verseNumber) {
    // Find the verse in the loaded surah and scroll to it
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    final currentSurah = quranProvider.currentSurah;
    final verses = currentSurah?.verses;
    if (verses != null && verses.isNotEmpty) {
      final verseIndex = verses.indexWhere((verse) => verse.numberInSurah == verseNumber);
      if (verseIndex != -1) {
        // Calculate approximate position (each verse takes roughly 100-200 pixels)
        final estimatedPosition = verseIndex * 150.0;
        _scrollController.animateTo(
          estimatedPosition,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<QuranProvider, AudioProvider, BookmarkProvider, SettingsProvider>(
      builder: (context, quranProvider, audioProvider, bookmarkProvider, settings, child) {
        final currentSurah = quranProvider.currentSurah;
        final verses = currentSurah?.verses ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.surah.englishName, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (quranProvider.isCurrentSurahOffline)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_pin, size: 14, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettingsBottomSheet(settings),
              ),
              PopupMenuButton(
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'share',
                        child: const Row(
                          children: [Icon(Icons.share), SizedBox(width: 8), Text('Share Surah')],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'bookmark',
                        child: const Row(
                          children: [
                            Icon(Icons.bookmark),
                            SizedBox(width: 8),
                            Text('Bookmark Surah'),
                          ],
                        ),
                      ),
                    ],
                onSelected: (value) {
                  switch (value) {
                    case 'share':
                      _shareSurah();
                      break;
                    case 'bookmark':
                      _bookmarkSurah();
                      break;
                  }
                },
              ),
            ],
          ),
          body:
              quranProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : quranProvider.error != null
                  ? _buildErrorState(quranProvider.error!)
                  : verses.isEmpty
                  ? _buildEmptyState()
                  : _buildQuranContent(verses, settings),
          floatingActionButton:
              _showFab
                  ? FloatingActionButton(
                    onPressed: _scrollToTop,
                    mini: true,
                    child: const Icon(Icons.keyboard_arrow_up),
                  )
                  : null,
        );
      },
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          // Traditional Bismillah decoration (if not Al-Fatiha or At-Tawbah)

          // Compact surah name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.surah.name,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_convertToArabicNumbers(widget.surah.numberOfAyahs)} آية',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontFamily: 'Amiri'),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),

          if (widget.surah.number != 1 && widget.surah.number != 9) ...[
            const SizedBox(height: 16),
            _buildBismillah(),
          ],
        ],
      ),
    );
  }

  bool _hasTranslations(List<Verse> verses) {
    return verses.any((verse) => verse.translation != null && verse.translation!.isNotEmpty);
  }

  Widget _buildBismillah() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: const Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        style: TextStyle(fontFamily: 'Amiri', fontSize: 24, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildQuranContent(List<Verse> verses, SettingsProvider settings) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          // Compact header that scrolls with content
          _buildCompactHeader(),

          // Mushaf-style Arabic text
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildMushafText(verses, settings),
          ),

          // Translation section (if enabled and has translations)
          if (settings.showTranslation && _hasTranslations(verses)) ...[
            const SizedBox(height: 8),
            _buildTranslationSection(verses, settings),
          ],

          // Verse actions
          const SizedBox(height: 24),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildQuickActions()),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMushafText(List<Verse> verses, SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title

        // Continuous Quran text like in mushaf
        RichText(
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: settings.arabicFontSize,
              height: 2.0,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            children: _buildVerseSpans(verses, settings),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _buildVerseSpans(List<Verse> verses, SettingsProvider settings) {
    List<TextSpan> spans = [];

    for (int i = 0; i < verses.length; i++) {
      final verse = verses[i];

      // Get verse text, removing Bismillah from first verse if header already shows it
      String verseText = _getCleanVerseText(verse, i == 0);

      // Add verse text
      spans.add(
        TextSpan(
          text: verseText,
          recognizer: null, // Can add tap recognizer for verse actions
        ),
      );

      // Add verse number if enabled
      if (settings.showVerseNumbers) {
        spans.add(
          TextSpan(
            text: ' ${_getVerseNumberSymbol(verse.numberInSurah)} ',
            style: TextStyle(
              fontSize: settings.arabicFontSize * 0.8,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }

      // Add space between verses (except last one)
      if (i < verses.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return spans;
  }

  String _getCleanVerseText(Verse verse, bool isFirstVerse) {
    String verseText = verse.text;

    // Remove Bismillah from first verse if header already shows it
    // Only for surahs that have Bismillah in header (not Al-Fatiha and At-Tawbah)
    if (isFirstVerse && widget.surah.number != 1 && widget.surah.number != 9) {
      // Common Bismillah variations in Arabic text
      const bismillahPatterns = [
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        'بسم الله الرحمن الرحيم',
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      ];

      for (String pattern in bismillahPatterns) {
        if (verseText.startsWith(pattern)) {
          verseText = verseText.substring(pattern.length).trim();
          break;
        }
      }
    }

    return verseText;
  }

  String _getVerseNumberSymbol(int verseNumber) {
    // Using Unicode circle numbers or custom formatting
    return '﴿${_convertToArabicNumbers(verseNumber)}﴾';
  }

  String _convertToArabicNumbers(int number) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) {
          return arabicNumbers[int.parse(digit)];
        })
        .join('');
  }

  Widget _buildTranslationSection(List<Verse> verses, SettingsProvider settings) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Translation title
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Translation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Translation verses (only show verses with translations)
          ...verses
              .where((verse) => verse.translation != null && verse.translation!.isNotEmpty)
              .map(
                (verse) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Verse number
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${verse.numberInSurah}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Translation text
                      Expanded(
                        child: Text(
                          verse.translation!,
                          style: TextStyle(
                            fontSize: settings.fontSize * 0.8,
                            height: 1.6,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(icon: Icons.copy, label: 'Copy', onPressed: _copySurah),
          _buildActionButton(icon: Icons.share, label: 'Share', onPressed: _shareSurah),
          _buildActionButton(
            icon: Icons.bookmark_border,
            label: 'Bookmark',
            onPressed: _bookmarkSurah,
          ),
          _buildActionButton(
            icon: Icons.play_arrow,
            label: 'Listen',
            onPressed: () {
              final audioProvider = Provider.of<AudioProvider>(context, listen: false);
              audioProvider.togglePlayPause();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    print(error);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Error Loading Surah', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadSurahVerses, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('No Verses Found', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Unable to load verses for this surah',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showSettingsBottomSheet(SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.outline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Reading Settings', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 20),

                      // Arabic Font Size
                      Text('Arabic Font Size', style: Theme.of(context).textTheme.titleMedium),
                      Slider(
                        value: settings.arabicFontSize,
                        min: 18.0,
                        max: 36.0,
                        divisions: 18,
                        label: settings.arabicFontSize.round().toString(),
                        onChanged: (value) {
                          settings.setArabicFontSize(value);
                          setModalState(() {});
                        },
                      ),

                      const SizedBox(height: 16),

                      // Show Translation
                      SwitchListTile(
                        title: const Text('Show Translation'),
                        subtitle: const Text('Display English translation below Arabic text'),
                        value: settings.showTranslation,
                        onChanged: (value) {
                          settings.setShowTranslation(value);
                          setModalState(() {});
                        },
                      ),

                      // Show Verse Numbers
                      SwitchListTile(
                        title: const Text('Show Verse Numbers'),
                        subtitle: const Text('Display verse numbers in Arabic text'),
                        value: settings.showVerseNumbers,
                        onChanged: (value) {
                          settings.setShowVerseNumbers(value);
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _copySurah() {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    final verses = quranProvider.currentSurah?.verses ?? [];

    String arabicText = verses
        .map((verse) => '${verse.text} ${_getVerseNumberSymbol(verse.numberInSurah)}')
        .join(' ');

    String fullText = 'سورة ${widget.surah.name}\n\n$arabicText';

    final settings = Provider.of<SettingsProvider>(context, listen: false);

    if (settings.showTranslation) {
      String translationText = verses
          .map((verse) => '${verse.numberInSurah}. ${verse.translation ?? ""}')
          .join('\n');
      fullText += '\n\n--- Translation ---\n$translationText';
    }

    Clipboard.setData(ClipboardData(text: fullText));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Surah copied to clipboard')));
  }

  void _shareSurah() {
    _copySurah(); // For now, just copy to clipboard
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Surah copied for sharing')));
  }

  void _bookmarkSurah() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Surah bookmark feature coming soon')));
  }
}
