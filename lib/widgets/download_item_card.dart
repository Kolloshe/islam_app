import 'package:flutter/material.dart';
import '../services/download_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DownloadItemCard extends StatelessWidget {
  final DownloadItem download;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final VoidCallback? onRetry;

  const DownloadItemCard({
    super.key,
    required this.download,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onDelete,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and actions
            Row(
              children: [
                // Download type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor(download.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(download.type),
                    color: _getTypeColor(download.type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        download.title,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        download.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Status indicator
                _buildStatusIndicator(context),
              ],
            ),

            const SizedBox(height: 16),

            // Progress section
            if (download.isDownloading || download.isPaused) ...[
              _buildProgressSection(context),
              const SizedBox(height: 12),
            ],

            // Download info
            _buildDownloadInfo(context),

            const SizedBox(height: 12),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (download.status) {
      case DownloadStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case DownloadStatus.downloading:
        statusColor = Colors.blue;
        statusIcon = Icons.downloading;
        break;
      case DownloadStatus.paused:
        statusColor = Colors.amber;
        statusIcon = Icons.pause_circle;
        break;
      case DownloadStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case DownloadStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case DownloadStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 4),
          Text(
            download.status.name.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: download.totalBytes > 0 ? download.progress : null, // null for indeterminate
                backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  download.isDownloading ? Colors.blue : Colors.amber,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              download.totalBytes > 0
                  ? '${(download.progress * 100).toStringAsFixed(1)}%'
                  : 'Downloading...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Progress details
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              download.totalBytes > 0
                  ? '${download.formattedDownloadedSize} / ${download.formattedSize}'
                  : '${download.formattedDownloadedSize} downloaded',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (download.isDownloading)
              Text(
                'Downloading...',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.blue, fontWeight: FontWeight.w500),
              )
            else if (download.isPaused)
              Text(
                'Paused',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.amber, fontWeight: FontWeight.w500),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloadInfo(BuildContext context) {
    return Row(
      children: [
        // File size
        if (download.formattedSize.isNotEmpty) ...[
          Icon(
            Icons.storage,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            download.formattedSize,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 16),
        ],

        // Download date
        Icon(
          Icons.access_time,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 4),
        Text(
          _formatDate(download.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),

        if (download.isCompleted && download.completedAt != null) ...[
          const Spacer(),
          Icon(Icons.check, size: 16, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            'Completed',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Error message for failed downloads
        if (download.isFailed && download.error != null) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      download.error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],

        // Action buttons based on status
        if (download.isDownloading) ...[
          // Pause button
          IconButton.filled(
            onPressed: () => onPause?.call(),
            icon: const Icon(Icons.pause),
            tooltip: AppLocalizations.of(context)?.pause ?? 'Pause',
          ),
          const SizedBox(width: 8),
          // Cancel button
          TextButton.icon(
            onPressed: () => onCancel?.call(),
            icon: const Icon(Icons.close),
            label: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
        ] else if (download.isPaused) ...[
          // Resume button
          ElevatedButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Resume'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          // Cancel button
          TextButton.icon(
            onPressed: () => onCancel?.call(),
            icon: const Icon(Icons.close),
            label: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
        ] else if (download.isFailed) ...[
          // Retry button
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, size: 16),
            label: Text(AppLocalizations.of(context)?.delete ?? 'Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ] else if (download.isCompleted) ...[
          // Delete button
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, size: 16),
            label: Text(AppLocalizations.of(context)?.delete ?? 'Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ],
    );
  }

  Color _getTypeColor(DownloadType type) {
    switch (type) {
      case DownloadType.audio:
        return Colors.green;
      case DownloadType.surah:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(DownloadType type) {
    switch (type) {
      case DownloadType.audio:
        return Icons.audiotrack;
      case DownloadType.surah:
        return Icons.book;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
