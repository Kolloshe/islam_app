import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/surah_model.dart';
import '../providers/settings_provider.dart';
import '../providers/download_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SurahCard extends StatelessWidget {
  final Surah surah;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;
  final bool showPlayButton;
  final bool showDownloadButton;

  const SurahCard({
    super.key,
    required this.surah,
    this.onTap,
    this.onPlayTap,
    this.showPlayButton = true,
    this.showDownloadButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 2.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Surah number in a circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        surah.number.toString(),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Surah information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Arabic name with settings-based font size
                        Text(
                          surah.name,
                          style: TextStyle(
                            fontSize:
                                settings.arabicFontSize * 0.8, // Slightly smaller for card view
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Amiri', // Arabic font
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 4),

                        // English name and translation
                        Text(
                          surah.englishName,
                          style: TextStyle(
                            fontSize: settings.fontSize,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),

                        Text(
                          surah.englishTranslation,
                          style: TextStyle(
                            fontSize: settings.fontSize * 0.85,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Revelation type and verse count
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color:
                                    surah.revelationType.toLowerCase() == 'meccan'
                                        ? Colors.orange.withOpacity(0.2)
                                        : Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                surah.revelationType,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      surah.revelationType.toLowerCase() == 'meccan'
                                          ? Colors.orange[700]
                                          : Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${surah.numberOfAyahs} verses',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Download button
                      if (showDownloadButton)
                        Consumer<DownloadProvider>(
                          builder: (context, downloadProvider, child) {
                            return FutureBuilder<bool>(
                              future: downloadProvider.isSurahDownloaded(surah.number),
                              builder: (context, snapshot) {
                                final isDownloaded = snapshot.data ?? false;

                                return IconButton(
                                  onPressed: () async {
                                    if (isDownloaded) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(context)?.surahAlreadyDownloaded ??
                                                'Surah already downloaded',
                                          ),
                                        ),
                                      );
                                    } else {
                                      // Start download
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(context)?.downloadStarted ??
                                                'Download started',
                                          ),
                                        ),
                                      );
                                      downloadProvider.downloadSurah(surah).catchError((error) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppLocalizations.of(context)?.downloadFailed ??
                                                  'Failed to start download',
                                            ),
                                          ),
                                        );
                                      });
                                    }
                                  },
                                  icon: Icon(
                                    isDownloaded ? Icons.download_done : Icons.download,
                                    color:
                                        isDownloaded
                                            ? Colors.green
                                            : Theme.of(context).primaryColor,
                                    size: 28,
                                  ),
                                  tooltip: isDownloaded ? 'Downloaded' : 'Download surah',
                                );
                              },
                            );
                          },
                        ),

                      // Play button
                      if (showPlayButton && onPlayTap != null)
                        IconButton(
                          onPressed: onPlayTap,
                          icon: Icon(
                            Icons.play_circle_outline,
                            color: Theme.of(context).primaryColor,
                            size: 32,
                          ),
                          tooltip: 'Play recitation',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
