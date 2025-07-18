import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/azkar_provider.dart';
import '../widgets/azkar_card.dart';
import 'azkar_category_screen.dart';

class AzkarScreen extends StatelessWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.azkar ?? 'Azkar'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              final azkarProvider = Provider.of<AzkarProvider>(context, listen: false);
              switch (value) {
                case 'toggle_translation':
                  azkarProvider.toggleTranslation();
                  break;
                case 'toggle_transliteration':
                  azkarProvider.toggleTransliteration();
                  break;
                case 'refresh_data':
                  _refreshAzkarData(context, azkarProvider);
                  break;
                case 'clear_cache':
                  _showCacheClearDialog(context, azkarProvider);
                  break;
                case 'reset_all':
                  _showResetDialog(context, azkarProvider);
                  break;
              }
            },
            itemBuilder: (context) {
              final azkarProvider = Provider.of<AzkarProvider>(context, listen: false);
              return [
                PopupMenuItem(
                  value: 'toggle_translation',
                  child: Row(
                    children: [
                      Icon(
                        azkarProvider.showTranslation
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                      ),
                      const SizedBox(width: 8),
                      const Text('Show Translation'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_transliteration',
                  child: Row(
                    children: [
                      Icon(
                        azkarProvider.showTransliteration
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                      ),
                      const SizedBox(width: 8),
                      const Text('Show Transliteration'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'refresh_data',
                  child: Row(
                    children: [
                      Icon(Icons.cloud_download, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Refresh from API'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_cache',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('Clear Cache'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'reset_all',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Reset All Progress'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Consumer<AzkarProvider>(
        builder: (context, azkarProvider, child) {
          if (azkarProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading azkar data...'),
                ],
              ),
            );
          }

          // Show status banner if using cached data or have errors
          Widget? statusBanner;
          if (azkarProvider.isUsingCachedData || azkarProvider.error != null) {
            statusBanner = Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: azkarProvider.error != null ? Colors.orange.shade100 : Colors.blue.shade50,
                border: Border(
                  bottom: BorderSide(
                    color:
                        azkarProvider.error != null ? Colors.orange.shade300 : Colors.blue.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    azkarProvider.error != null ? Icons.warning_amber : Icons.cached,
                    color:
                        azkarProvider.error != null ? Colors.orange.shade700 : Colors.blue.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      azkarProvider.error ?? 'Using cached data',
                      style: TextStyle(
                        color:
                            azkarProvider.error != null
                                ? Colors.orange.shade800
                                : Colors.blue.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (azkarProvider.error != null)
                    TextButton(
                      onPressed: () => _refreshAzkarData(context, azkarProvider),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                      ),
                    ),
                ],
              ),
            );
          }

          return DefaultTabController(
            length: 5,
            child: Column(
              children: [
                // Status banner (if needed)
                if (statusBanner != null) statusBanner,

                // Tab bar
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: l10n?.all ?? 'All', icon: Icon(Icons.all_inclusive)),
                      Tab(text: l10n?.morning ?? 'Morning', icon: Icon(Icons.wb_sunny)),
                      Tab(text: l10n?.evening ?? 'Evening', icon: Icon(Icons.nightlight)),
                      Tab(text: l10n?.postPrayer ?? 'Post-Prayer', icon: Icon(Icons.mosque)),
                      Tab(text: l10n?.general ?? 'General', icon: Icon(Icons.auto_awesome)),
                    ],
                  ),
                ),

                // Tab bar view
                Expanded(
                  child: TabBarView(
                    children: [
                      // All azkar
                      _buildAzkarList(context, azkarProvider.categories, azkarProvider),

                      // Morning azkar
                      _buildAzkarList(context, azkarProvider.morningAzkar, azkarProvider),

                      // Evening azkar
                      _buildAzkarList(context, azkarProvider.eveningAzkar, azkarProvider),

                      // Post-prayer azkar
                      _buildAzkarList(context, azkarProvider.postPrayerAzkar, azkarProvider),

                      // General azkar
                      _buildAzkarList(context, azkarProvider.generalAzkar, azkarProvider),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAzkarList(BuildContext context, List categories, AzkarProvider azkarProvider) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No azkar available',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for more content',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final progress = azkarProvider.getCategoryProgress(category.id);

        return AzkarCard(
          category: category,
          progress: progress,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AzkarCategoryScreen(category: category)),
            );
          },
        );
      },
    );
  }

  void _refreshAzkarData(BuildContext context, AzkarProvider azkarProvider) async {
    try {
      // Show different messages based on current state
      String message = 'Refreshing azkar data...';
      if (azkarProvider.error?.contains('429') == true ||
          azkarProvider.error?.contains('Rate limit') == true) {
        message = 'Retrying API connection...';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(message),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      await azkarProvider.refreshData();

      if (context.mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();

        String successMessage = '✅ Data refreshed successfully';
        if (azkarProvider.isUsingCachedData) {
          successMessage = '📦 Using latest cached data';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();

        String errorMessage = '❌ Refresh failed';
        Color backgroundColor = Colors.red.shade700;

        if (e.toString().contains('429') || e.toString().contains('Rate limit')) {
          errorMessage = '🚦 Rate limited. Try again in a few minutes.';
          backgroundColor = Colors.orange.shade700;
        } else if (e.toString().contains('timeout') || e.toString().contains('SocketException')) {
          errorMessage = '📶 Network issue. Check your connection.';
          backgroundColor = Colors.blue.shade700;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
            backgroundColor: backgroundColor,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _refreshAzkarData(context, azkarProvider),
            ),
          ),
        );
      }
    }
  }

  void _showCacheClearDialog(BuildContext context, AzkarProvider azkarProvider) async {
    // Get cache info first
    final cacheInfo = await azkarProvider.getCacheInfo();
    final totalEntries = cacheInfo['totalEntries'] as int;
    final validEntries = cacheInfo['validEntries'] as int;
    final expiredEntries = cacheInfo['expiredEntries'] as int;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Cache'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This will clear all cached azkar data and force a fresh download from the API.',
                ),
                const SizedBox(height: 16),
                if (totalEntries > 0) ...[
                  Text('Cache Statistics:', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text('• Total entries: $totalEntries'),
                  Text('• Valid entries: $validEntries'),
                  Text('• Expired entries: $expiredEntries'),
                ] else
                  const Text('No cached data found.'),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed:
                    totalEntries > 0
                        ? () async {
                          Navigator.pop(context);
                          try {
                            await azkarProvider.clearCache();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🗑️ Cache cleared successfully'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Failed to clear cache: $e'),
                                  duration: const Duration(seconds: 3),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          }
                        }
                        : null,
                style: TextButton.styleFrom(foregroundColor: Colors.purple),
                child: const Text('Clear Cache'),
              ),
            ],
          ),
    );
  }

  void _showResetDialog(BuildContext context, AzkarProvider azkarProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset All Progress'),
            content: const Text(
              'Are you sure you want to reset all azkar progress? This action cannot be undone.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  azkarProvider.resetAllProgress();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All progress has been reset'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reset All'),
              ),
            ],
          ),
    );
  }
}
