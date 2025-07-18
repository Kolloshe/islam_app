import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/azkar_model.dart';
import '../providers/azkar_provider.dart';
import '../widgets/azkar_counter_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AzkarCategoryScreen extends StatefulWidget {
  final AzkarCategory category;

  const AzkarCategoryScreen({super.key, required this.category});

  @override
  State<AzkarCategoryScreen> createState() => _AzkarCategoryScreenState();
}

class _AzkarCategoryScreenState extends State<AzkarCategoryScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.category.name),
            Text(
              widget.category.nameArabic,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          Consumer<AzkarProvider>(
            builder: (context, azkarProvider, child) {
              final progress = azkarProvider.getCategoryProgress(widget.category.id);
              return CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                backgroundColor: colorScheme.onPrimary.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? Colors.greenAccent : colorScheme.onPrimary,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            onSelected: (value) {
              final azkarProvider = Provider.of<AzkarProvider>(context, listen: false);
              switch (value) {
                case 'reset_category':
                  _showResetCategoryDialog(context, azkarProvider);
                  break;
                case 'toggle_translation':
                  azkarProvider.toggleTranslation();
                  break;
                case 'toggle_transliteration':
                  azkarProvider.toggleTransliteration();
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
                      Text(AppLocalizations.of(context)?.showTranslation ?? 'Show Translation'),
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
                      Text(
                        AppLocalizations.of(context)?.showTransliteration ?? 'Show Transliteration',
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'reset_category',
                  child: Row(
                    children: [
                      const Icon(Icons.restore, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)?.resetCategory ?? 'Reset Category'),
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
          if (widget.category.azkarList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No azkar in this category',
                    style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.outline),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Category info header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.05),
                  border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(widget.category.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.category.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.menu_book, size: 16, color: colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.category.azkarList.length} Adhkar',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                        ),
                        const Spacer(),
                        Text(
                          '${_currentIndex + 1} of ${widget.category.azkarList.length}',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Azkar list
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: widget.category.azkarList.length,
                  itemBuilder: (context, index) {
                    final azkar = widget.category.azkarList[index];
                    final currentCount = azkarProvider.getCurrentCount(azkar.id);

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: AzkarCounterWidget(
                          azkar: azkar,
                          currentCount: currentCount,
                          showTranslation: azkarProvider.showTranslation,
                          showTransliteration: azkarProvider.showTransliteration,
                          onCountChanged: (newCount) {
                            azkarProvider.updateAzkarCount(azkar.id, newCount);
                          },
                          onReset: () {
                            azkarProvider.resetAzkarCount(azkar.id);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar:
          widget.category.azkarList.length > 1
              ? Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Previous button
                    IconButton.filled(
                      onPressed:
                          _currentIndex > 0
                              ? () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                              : null,
                      icon: const Icon(Icons.arrow_back),
                    ),

                    const SizedBox(width: 16),

                    // Page indicator
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.category.azkarList.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  index == _currentIndex
                                      ? colorScheme.primary
                                      : colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Next button
                    IconButton.filled(
                      onPressed:
                          _currentIndex < widget.category.azkarList.length - 1
                              ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                              : null,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              )
              : null,
    );
  }

  void _showResetCategoryDialog(BuildContext context, AzkarProvider azkarProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reset ${widget.category.name}'),
            content: Text(
              'Are you sure you want to reset all progress for ${widget.category.name}? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () {
                  azkarProvider.resetCategoryProgress(widget.category.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.category.name} progress has been reset'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(AppLocalizations.of(context)?.reset ?? 'Reset'),
              ),
            ],
          ),
    );
  }
}
