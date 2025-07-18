import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/bookmark_model.dart';
import '../providers/settings_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleSelection;

  const BookmarkCard({
    super.key,
    required this.bookmark,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onTap,
    this.onLongPress,
    this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 8 : 2,
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, settings),
                  const SizedBox(height: 12),
                  _buildArabicText(context, settings),
                  if (settings.showTranslation && bookmark.translation != null) ...[
                    const SizedBox(height: 8),
                    _buildTranslation(context, settings),
                  ],
                  if (bookmark.hasNote) ...[const SizedBox(height: 8), _buildNote(context)],
                  if (bookmark.hasTags) ...[const SizedBox(height: 8), _buildTags(context)],
                  const SizedBox(height: 12),
                  _buildFooter(context, settings),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, SettingsProvider settings) {
    return Row(
      children: [
        if (isSelectionMode)
          Checkbox(value: isSelected, onChanged: (_) => onToggleSelection?.call()),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            bookmark.reference,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getTypeColor(context, bookmark.type),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            bookmark.type.displayName,
            style: TextStyle(
              color: _getTypeTextColor(context, bookmark.type),
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ),
        const Spacer(),
        Text(
          _formatDate(bookmark.createdAt),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
      ],
    );
  }

  Widget _buildArabicText(BuildContext context, SettingsProvider settings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        bookmark.verseText,
        style: TextStyle(fontFamily: 'Amiri', fontSize: settings.arabicFontSize, height: 2.0),
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildTranslation(BuildContext context, SettingsProvider settings) {
    return Text(
      bookmark.translation!,
      style: TextStyle(fontSize: settings.fontSize, fontStyle: FontStyle.italic, height: 1.6),
    );
  }

  Widget _buildNote(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, size: 16, color: Theme.of(context).colorScheme.onTertiaryContainer),
              const SizedBox(width: 4),
              Text(
                'Note:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            bookmark.note!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onTertiaryContainer,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children:
          bookmark.tags
              .map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildFooter(BuildContext context, SettingsProvider settings) {
    return Row(
      children: [
        IconButton(
          onPressed: () => _copyVerse(context, settings),
          icon: const Icon(Icons.copy, size: 18),
          tooltip: 'Copy verse',
        ),
        IconButton(
          onPressed: () => _shareVerse(context, settings),
          icon: const Icon(Icons.share, size: 18),
          tooltip: 'Share verse',
        ),
        IconButton(
          onPressed: () => _editBookmark(context),
          icon: const Icon(Icons.edit, size: 18),
          tooltip: 'Edit bookmark',
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _navigateToVerse(context),
          icon: const Icon(Icons.open_in_new, size: 18),
          tooltip: 'Go to verse',
        ),
      ],
    );
  }

  Color _getTypeColor(BuildContext context, BookmarkType type) {
    switch (type) {
      case BookmarkType.verse:
        return Theme.of(context).colorScheme.primaryContainer;
      case BookmarkType.favorite:
        return Theme.of(context).colorScheme.errorContainer;
      case BookmarkType.lastRead:
        return Theme.of(context).colorScheme.tertiaryContainer;
    }
  }

  Color _getTypeTextColor(BuildContext context, BookmarkType type) {
    switch (type) {
      case BookmarkType.verse:
        return Theme.of(context).colorScheme.onPrimaryContainer;
      case BookmarkType.favorite:
        return Theme.of(context).colorScheme.onErrorContainer;
      case BookmarkType.lastRead:
        return Theme.of(context).colorScheme.onTertiaryContainer;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _copyVerse(BuildContext context, SettingsProvider settings) {
    String text = bookmark.verseText;
    if (settings.showTranslation && bookmark.translation != null) {
      text += '\n\n${bookmark.translation}';
    }
    text += '\n\n- ${bookmark.reference}';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)?.verseCopied ?? 'Verse copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareVerse(BuildContext context, SettingsProvider settings) {
    String text = bookmark.verseText;
    if (settings.showTranslation && bookmark.translation != null) {
      text += '\n\n${bookmark.translation}';
    }
    text += '\n\n- ${bookmark.reference}';

    // In a real app, use share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.shareFeature ??
              'Share functionality would be implemented here',
        ),
      ),
    );
  }

  void _editBookmark(BuildContext context) {
    showDialog(context: context, builder: (context) => _EditBookmarkDialog(bookmark: bookmark));
  }

  void _navigateToVerse(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/surah-detail',
      arguments: {'surahNumber': bookmark.surahNumber, 'verseNumber': bookmark.verseNumber},
    );
  }
}

class _EditBookmarkDialog extends StatefulWidget {
  final Bookmark bookmark;

  const _EditBookmarkDialog({required this.bookmark});

  @override
  State<_EditBookmarkDialog> createState() => _EditBookmarkDialogState();
}

class _EditBookmarkDialogState extends State<_EditBookmarkDialog> {
  late TextEditingController _noteController;
  late TextEditingController _tagsController;
  late BookmarkType _selectedType;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.bookmark.note ?? '');
    _tagsController = TextEditingController(text: widget.bookmark.tags.join(', '));
    _selectedType = widget.bookmark.type;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)?.editBookmark ?? 'Edit Bookmark'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reference: ${widget.bookmark.reference}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BookmarkType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items:
                  BookmarkType.values.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type.displayName));
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
                hintText: 'Add a personal note...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags',
                border: OutlineInputBorder(),
                hintText: 'prayer, guidance, patience (comma separated)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
        ),
      ],
    );
  }

  void _saveChanges() {
    final tags =
        _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

    final updatedBookmark = widget.bookmark.copyWith(
      note: _noteController.text.isEmpty ? null : _noteController.text,
      tags: tags,
      type: _selectedType,
    );

    // In a real app, update via BookmarkProvider
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.bookmarkUpdated ?? 'Bookmark updated successfully',
        ),
      ),
    );
  }
}
