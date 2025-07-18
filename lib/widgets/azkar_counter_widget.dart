import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/azkar_model.dart';

class AzkarCounterWidget extends StatefulWidget {
  final Azkar azkar;
  final int currentCount;
  final bool showTranslation;
  final bool showTransliteration;
  final Function(int) onCountChanged;
  final VoidCallback onReset;

  const AzkarCounterWidget({
    super.key,
    required this.azkar,
    required this.currentCount,
    required this.showTranslation,
    required this.showTransliteration,
    required this.onCountChanged,
    required this.onReset,
  });

  @override
  State<AzkarCounterWidget> createState() => _AzkarCounterWidgetState();
}

class _AzkarCounterWidgetState extends State<AzkarCounterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _incrementCount() {
    if (widget.currentCount < widget.azkar.count) {
      HapticFeedback.lightImpact();
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
      widget.onCountChanged(widget.currentCount + 1);
    }
  }

  void _decrementCount() {
    if (widget.currentCount > 0) {
      HapticFeedback.lightImpact();
      widget.onCountChanged(widget.currentCount - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompleted = widget.currentCount >= widget.azkar.count;
    final progress = widget.azkar.count > 0 ? widget.currentCount / widget.azkar.count : 0.0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with source and benefits
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.azkar.source.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.azkar.source,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (widget.azkar.benefits.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.azkar.benefits,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Completion status
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Arabic text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: Text(
                widget.azkar.textArabic,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Amiri',
                  height: 2.0,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),

            // Transliteration
            if (widget.showTransliteration && widget.azkar.transliteration.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.azkar.transliteration,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Translation
            if (widget.showTranslation && widget.azkar.translation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.azkar.translation,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Progress bar
            if (widget.azkar.count > 1) ...[
              Row(
                children: [
                  Text(
                    'Progress',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.currentCount}/${widget.azkar.count}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? Colors.green : colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.outline.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green : colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
            ],

            // Counter controls
            Row(
              children: [
                // Decrement button
                IconButton(
                  onPressed: widget.currentCount > 0 ? _decrementCount : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.error.withOpacity(0.1),
                    foregroundColor: colorScheme.error,
                  ),
                ),

                const SizedBox(width: 16),

                // Main counter button
                Expanded(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: ElevatedButton(
                      onPressed: widget.currentCount < widget.azkar.count ? _incrementCount : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted ? Colors.green : colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isCompleted
                            ? 'Completed! 🎉'
                            : widget.azkar.count == 1
                            ? 'Mark as Done'
                            : 'Tap to Count (${widget.currentCount}/${widget.azkar.count})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Reset button
                IconButton(
                  onPressed: widget.currentCount > 0 ? widget.onReset : null,
                  icon: const Icon(Icons.refresh),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.outline.withOpacity(0.1),
                    foregroundColor: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
