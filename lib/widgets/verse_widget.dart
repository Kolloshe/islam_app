import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/surah_model.dart';
import '../providers/settings_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VerseWidget extends StatelessWidget {
  final Verse verse;
  final String? translation;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;
  final bool isBookmarked;

  const VerseWidget({
    super.key,
    required this.verse,
    this.translation,
    this.onTap,
    this.onBookmark,
    this.onShare,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 1.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Verse header (only show if verse numbers are enabled)
                  if (settings.showVerseNumbers) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Verse number
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            verse.numberInSurah.toString(),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        // Action buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onBookmark != null)
                              IconButton(
                                onPressed: onBookmark,
                                icon: Icon(
                                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                  color:
                                      isBookmarked ? Theme.of(context).primaryColor : Colors.grey,
                                ),
                                tooltip: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
                              ),
                            if (onShare != null)
                              IconButton(
                                onPressed: () => _shareVerse(context, settings),
                                icon: const Icon(Icons.share, color: Colors.grey),
                                tooltip: 'Share verse',
                              ),
                            IconButton(
                              onPressed: () => _copyVerse(context, settings),
                              icon: const Icon(Icons.copy, color: Colors.grey),
                              tooltip: 'Copy verse',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Arabic text with settings-based font size
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      verse.text,
                      style: TextStyle(
                        fontSize: settings.arabicFontSize,
                        height: 2.0,
                        fontFamily: 'Amiri', // Arabic font
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),

                  // Translation (only show if enabled in settings)
                  if (settings.showTranslation && translation != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        translation!,
                        style: TextStyle(
                          fontSize: settings.fontSize,
                          height: 1.6,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],

                  // Verse metadata
                  if (settings.showVerseNumbers) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMetadataChip(context, 'Juz ${verse.juz}'),
                        const SizedBox(width: 8),
                        _buildMetadataChip(context, 'Page ${verse.page}'),
                        if (verse.sajda) ...[
                          const SizedBox(width: 8),
                          _buildMetadataChip(context, 'Sajda', Colors.orange),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetadataChip(BuildContext context, String label, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color ?? Theme.of(context).primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _copyVerse(BuildContext context, SettingsProvider settings) {
    String textToCopy = verse.text;
    if (translation != null && settings.showTranslation) {
      textToCopy += '\n\n$translation';
    }
    textToCopy += '\n\n— Quran ${verse.numberInSurah}';

    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)?.verseCopied ?? 'Verse copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareVerse(BuildContext context, SettingsProvider settings) {
    if (onShare != null) {
      onShare!();
    }
  }
}
