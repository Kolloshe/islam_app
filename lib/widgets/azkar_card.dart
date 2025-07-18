import 'package:flutter/material.dart';
import '../models/azkar_model.dart';

class AzkarCard extends StatelessWidget {
  final AzkarCategory category;
  final double progress;
  final VoidCallback onTap;

  const AzkarCard({super.key, required this.category, required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(category.icon, style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 16),

                  // Title and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.nameArabic,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress indicator
                  Column(
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        backgroundColor: colorScheme.outline.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 1.0 ? Colors.green : colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: progress >= 1.0 ? Colors.green : colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bottom info
              Row(
                children: [
                  Icon(Icons.menu_book, size: 16, color: colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    '${category.azkarList.length} Adhkar',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),

                  // Time indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTimeColor(category.time).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getTimeLabel(category.time),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getTimeColor(category.time),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTimeColor(String time) {
    switch (time) {
      case 'morning':
        return Colors.orange;
      case 'evening':
        return Colors.purple;
      case 'post_prayer':
        return Colors.blue;
      case 'general':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getTimeLabel(String time) {
    switch (time) {
      case 'morning':
        return 'Morning';
      case 'evening':
        return 'Evening';
      case 'post_prayer':
        return 'Post-Prayer';
      case 'general':
        return 'General';
      default:
        return 'Unknown';
    }
  }
}
