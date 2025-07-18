import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/language_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, LanguageProvider>(
      builder: (context, settings, languageProvider, child) {
        final l10n = AppLocalizations.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.settings),
            actions: [
              IconButton(
                onPressed: () => _showResetDialog(context, settings),
                icon: const Icon(Icons.restore),
                tooltip: 'Reset to Defaults',
              ),
            ],
          ),
          body: ListView(
            children: [
              _buildSection(context, 'Appearance', Icons.palette, [
                _buildThemeToggle(context, settings),
                _buildFontSizeSlider(
                  context,
                  l10n.fontSize,
                  settings.fontSize,
                  (value) => settings.setFontSize(value),
                  12.0,
                  24.0,
                ),
                _buildFontSizeSlider(
                  context,
                  l10n.arabicFontSize,
                  settings.arabicFontSize,
                  (value) => settings.setArabicFontSize(value),
                  18.0,
                  36.0,
                ),
                _buildLanguageSelector(context, languageProvider),
              ]),
              const Divider(),
              _buildSection(context, l10n.readingPreferences, Icons.menu_book, [
                _buildDropdownTile(
                  context,
                  l10n.defaultTranslation,
                  settings.translationOptions[settings.defaultTranslation] ??
                      settings.defaultTranslation,
                  settings.translationOptions.values.toList(),
                  (value) {
                    final key =
                        settings.translationOptions.entries
                            .firstWhere((entry) => entry.value == value)
                            .key;
                    settings.setDefaultTranslation(key);
                  },
                  Icons.translate,
                ),
                _buildSwitchTile(
                  context,
                  l10n.showTransliteration,
                  l10n.showTransliterationDesc,
                  settings.showTransliteration,
                  (value) => settings.setShowTransliteration(value),
                  Icons.abc,
                ),
                _buildSwitchTile(
                  context,
                  l10n.showVerseNumbers,
                  l10n.displayVerseNumbers,
                  settings.showVerseNumbers,
                  (value) => settings.setShowVerseNumbers(value),
                  Icons.numbers,
                ),
                _buildSwitchTile(
                  context,
                  l10n.showTranslation,
                  l10n.displayTranslation,
                  settings.showTranslation,
                  (value) => settings.setShowTranslation(value),
                  Icons.translate,
                ),
              ]),
              const Divider(),
              _buildSection(context, 'Audio Settings', Icons.volume_up, [
                _buildDropdownTile(
                  context,
                  'Audio Quality',
                  settings.audioQuality,
                  settings.audioQualityOptions,
                  (value) => settings.setAudioQuality(value),
                  Icons.high_quality,
                ),
                _buildSwitchTile(
                  context,
                  'Auto-play Next',
                  'Automatically play next surah',
                  settings.autoPlay,
                  (value) => settings.setAutoPlay(value),
                  Icons.skip_next,
                ),
                _buildSwitchTile(
                  context,
                  'Download on WiFi Only',
                  'Prevent mobile data usage for downloads',
                  settings.downloadOnWifi,
                  (value) => settings.setDownloadOnWifi(value),
                  Icons.wifi,
                ),
                _buildSliderTile(
                  context,
                  'Playback Speed',
                  settings.playbackSpeed,
                  (value) => settings.setPlaybackSpeed(value),
                  0.5,
                  2.0,
                  'x',
                  Icons.speed,
                ),
                _buildSliderTile(
                  context,
                  'Volume',
                  settings.volume,
                  (value) => settings.setVolume(value),
                  0.0,
                  1.0,
                  '%',
                  Icons.volume_up,
                ),
              ]),
              const Divider(),
              _buildSection(context, l10n.notifications, Icons.notifications, [
                _buildSwitchTile(
                  context,
                  l10n.enableNotifications,
                  'Receive prayer reminders and updates',
                  settings.notificationsEnabled,
                  (value) => settings.setNotificationsEnabled(value),
                  Icons.notifications,
                ),
                _buildSwitchTile(
                  context,
                  l10n.vibrationEnabled,
                  'Vibrate for notifications',
                  settings.vibrationEnabled,
                  (value) => settings.setVibrationEnabled(value),
                  Icons.vibration,
                ),
              ]),
              const Divider(),
              _buildSection(context, l10n.storageAndData, Icons.storage, [
                _buildStorageInfoTile(context),
                _buildActionTile(
                  context,
                  l10n.manageDownloads,
                  'View and manage offline audio content',
                  Icons.download,
                  () => _manageDownloads(context),
                ),
                _buildActionTile(
                  context,
                  l10n.clearCache,
                  'Free up storage space (${_getCacheSize()})',
                  Icons.cleaning_services,
                  () => _clearCache(context),
                ),
                _buildActionTile(
                  context,
                  l10n.clearAllDownloads,
                  'Remove all offline audio files',
                  Icons.delete_forever,
                  () => _clearAllDownloads(context),
                ),
                _buildSwitchTile(
                  context,
                  l10n.autoCacheSurahs,
                  'Automatically cache recently viewed surahs',
                  settings.downloadOnWifi, // Using existing setting as placeholder
                  (value) => settings.setDownloadOnWifi(value),
                  Icons.auto_awesome,
                ),
                _buildDropdownTile(
                  context,
                  l10n.cacheLimit,
                  '100 MB', // Placeholder
                  ['50 MB', '100 MB', '200 MB', '500 MB', '1 GB'],
                  (value) => _setCacheLimit(value),
                  Icons.storage,
                ),
              ]),
              const Divider(),
              _buildSection(context, l10n.dataManagement, Icons.backup, [
                _buildActionTile(
                  context,
                  l10n.exportBookmarks,
                  'Save bookmarks to file',
                  Icons.file_download,
                  () => _exportBookmarks(context),
                ),
                _buildActionTile(
                  context,
                  l10n.importBookmarks,
                  'Load bookmarks from file',
                  Icons.file_upload,
                  () => _importBookmarks(context),
                ),
                _buildActionTile(
                  context,
                  l10n.exportReadingProgress,
                  'Save reading history and progress',
                  Icons.analytics,
                  () => _exportProgress(context),
                ),
                _buildActionTile(
                  context,
                  l10n.clearReadingHistory,
                  'Remove all reading progress data',
                  Icons.history_toggle_off,
                  () => _clearReadingHistory(context),
                ),
                _buildActionTile(
                  context,
                  l10n.resetAllData,
                  'Clear all app data and settings',
                  Icons.restore,
                  () => _resetAllData(context),
                ),
              ]),
              const Divider(),
              _buildSection(context, l10n.aboutApp, Icons.info, [
                _buildActionTile(
                  context,
                  l10n.rateApp,
                  'Share your feedback',
                  Icons.star,
                  () => _rateApp(),
                ),
                _buildActionTile(
                  context,
                  l10n.shareApp,
                  'Tell others about this app',
                  Icons.share,
                  () => _shareApp(),
                ),
                _buildActionTile(
                  context,
                  l10n.privacyPolicy,
                  'Read our privacy policy',
                  Icons.privacy_tip,
                  () => _openPrivacyPolicy(),
                ),
                _buildActionTile(
                  context,
                  l10n.termsOfService,
                  'Read our terms',
                  Icons.description,
                  () => _openTermsOfService(),
                ),
                _buildActionTile(
                  context,
                  l10n.contactSupport,
                  'Get help and support',
                  Icons.support,
                  () => _contactSupport(),
                ),
              ]),
              _buildDeveloperInfo(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildThemeToggle(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: Icon(settings.isDarkMode ? Icons.dark_mode : Icons.light_mode),
      title: Text(l10n.darkMode),
      subtitle: Text(settings.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled'),
      trailing: Switch(
        value: settings.isDarkMode,
        onChanged: (value) => settings.setDarkMode(value),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildFontSizeSlider(
    BuildContext context,
    String title,
    double value,
    Function(double) onChanged,
    double min,
    double max,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Size: ${value.round()}'),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 2).round(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    BuildContext context,
    String title,
    double value,
    Function(double) onChanged,
    double min,
    double max,
    String unit,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${unit == '%' ? (value * 100).round() : value.toStringAsFixed(1)}$unit'),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: unit == '%' ? 10 : 15,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    BuildContext context,
    String title,
    String value,
    List<String> options,
    Function(String) onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: Container(),
        items:
            options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
        onChanged: (newValue) {
          if (newValue != null) onChanged(newValue);
        },
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildLanguageSelector(BuildContext context, LanguageProvider languageProvider) {
    final l10n = AppLocalizations.of(context);

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.language),
      subtitle: DropdownButton<Locale>(
        value: languageProvider.currentLocale,
        isExpanded: true,
        underline: Container(),
        items:
            LanguageProvider.supportedLocales.map((locale) {
              return DropdownMenuItem<Locale>(
                value: locale,
                child: Text(languageProvider.getLanguageName(locale.languageCode)),
              );
            }).toList(),
        onChanged: (newLocale) {
          if (newLocale != null) {
            languageProvider.setLanguage(newLocale);
          }
        },
      ),
    );
  }

  Widget _buildDeveloperInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.favorite, color: Theme.of(context).colorScheme.error, size: 24),
          const SizedBox(height: 8),
          Text(
            l10n.madeWithLove,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(l10n.version, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.resetSettings),
            content: Text('Are you sure you want to reset all settings to their default values?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
              TextButton(
                onPressed: () {
                  settings.resetToDefaults();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.settingsResetToDefaults)));
                },
                child: Text(l10n.reset),
              ),
            ],
          ),
    );
  }

  void _manageDownloads(BuildContext context) {
    Navigator.pushNamed(context, '/downloads');
  }

  void _clearCache(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.clearCache),
            content: Text(l10n.clearCacheDesc),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.cacheClaredSuccessfully)));
                },
                child: Text(l10n.clear),
              ),
            ],
          ),
    );
  }

  void _rateApp() {
    const url = 'https://apps.apple.com/app/your-app-id';
    canLaunchUrl(Uri.parse(url)).then((canLaunch) {
      if (canLaunch) {
        launchUrl(Uri.parse(url));
      }
    });
  }

  void _shareApp() {
    Share.share(
      'Check out this amazing Quran app! Download it from the App Store: https://apps.apple.com/app/your-app-id',
      subject: 'Quran App - Read & Listen to the Holy Quran',
    );
  }

  void _openPrivacyPolicy() {
    const url = 'https://yourwebsite.com/privacy';
    canLaunchUrl(Uri.parse(url)).then((canLaunch) {
      if (canLaunch) {
        launchUrl(Uri.parse(url));
      }
    });
  }

  void _openTermsOfService() {
    const url = 'https://yourwebsite.com/terms';
    canLaunchUrl(Uri.parse(url)).then((canLaunch) {
      if (canLaunch) {
        launchUrl(Uri.parse(url));
      }
    });
  }

  void _contactSupport() {
    const email = 'mailto:support@yourapp.com';
    canLaunchUrl(Uri.parse(email)).then((canLaunch) {
      if (canLaunch) {
        launchUrl(Uri.parse(email));
      }
    });
  }

  // Storage Info Widget
  Widget _buildStorageInfoTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Storage Usage',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStorageRow(context, 'App Data', '15.2 MB', Colors.blue),
          _buildStorageRow(context, 'Audio Cache', '125.8 MB', Colors.green),
          _buildStorageRow(context, 'Bookmarks', '2.1 MB', Colors.orange),
          _buildStorageRow(context, 'Reading History', '5.7 MB', Colors.purple),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Used',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '148.8 MB',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageRow(BuildContext context, String label, String size, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            size,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Storage and Data Methods
  String _getCacheSize() {
    // In a real app, this would calculate actual cache size
    return '125.8 MB';
  }

  void _setCacheLimit(String limit) {
    // Implementation for setting cache limit
    // This would typically update a settings value
    // For now, we'll show a placeholder message
    debugPrint('Cache limit set to $limit');
  }

  void _clearAllDownloads(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.clearAllDownloads),
            content: Text(l10n.clearAllDownloadsDesc),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) => Dialog(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(width: 16),
                                Text(l10n.clearingDownloads),
                              ],
                            ),
                          ),
                        ),
                  );

                  // Simulate clearing downloads
                  Future.delayed(const Duration(seconds: 2), () {
                    Navigator.pop(context); // Close loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.downloadsCleared), backgroundColor: Colors.green),
                    );
                  });
                },
                child: Text(l10n.clearAllDownloads),
              ),
            ],
          ),
    );
  }

  void _exportBookmarks(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    try {
      final bookmarkProvider = Provider.of<BookmarkProvider>(context, listen: false);
      bookmarkProvider
          .exportBookmarks()
          .then((result) async {
            if (result != null) {
              await Share.shareXFiles([
                XFile.fromData(
                  Uint8List.fromList(utf8.encode(result)),
                  name: 'quran_bookmarks_${DateTime.now().millisecondsSinceEpoch}.json',
                  mimeType: 'application/json',
                ),
              ]);

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.bookmarksExported)));
            }
          })
          .catchError((e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to export bookmarks: $e')));
          });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export bookmarks: $e')));
    }
  }



  void _importBookmarks(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.importBookmarks),
            content: Text(l10n.importBookmarksComingSoon),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok))],
          ),
    );
  }

  void _exportProgress(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.exportReadingProgress),
            content: Text(l10n.exportProgressComingSoon),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok))],
          ),
    );
  }

  void _clearReadingHistory(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.clearReadingHistory),
            content: Text(l10n.clearReadingHistoryDesc),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.readingHistoryCleared),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                child: Text(l10n.clearAllDownloads),
              ),
            ],
          ),
    );
  }

  void _resetAllData(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.resetAllData),
            content: Text(l10n.resetAllDataDescription),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(l10n.finalConfirmation),
                          content: Text(l10n.typeDeleteToConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.allAppDataReset),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                              child: Text(l10n.confirm),
                            ),
                          ],
                        ),
                  );
                },
                child: Text(l10n.resetEverything),
              ),
            ],
          ),
    );
  }

  String _getQualityDisplayName(String quality, AppLocalizations? l10n) {
    switch (quality) {
      case 'high':
        return l10n?.audioQualityHigh ?? 'High (128 kbps)';
      case 'medium':
        return l10n?.audioQualityMedium ?? 'Medium (64 kbps)';
      case 'low':
        return l10n?.audioQualityLow ?? 'Low (32 kbps)';
      default:
        return l10n?.audioQualityMedium ?? 'Medium (64 kbps)';
    }
  }
}
