import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../services/download_service.dart';
import '../widgets/download_item_card.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DownloadType? _filterType;
  DownloadStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load downloads on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadProvider>().loadDownloads();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Downloads'),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  text: 'All (${downloadProvider.totalDownloads})',
                  icon: const Icon(Icons.download, size: 16),
                ),
                Tab(
                  text: 'Active (${downloadProvider.activeCount})',
                  icon: const Icon(Icons.downloading, size: 16),
                ),
                Tab(
                  text: 'Completed (${downloadProvider.completedCount})',
                  icon: const Icon(Icons.check_circle, size: 16),
                ),
                Tab(
                  text: 'Failed (${downloadProvider.failedCount})',
                  icon: const Icon(Icons.error, size: 16),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearchDialog(context),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(context, value, downloadProvider),
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'filter',
                        child: Row(
                          children: [Icon(Icons.filter_list), SizedBox(width: 8), Text('Filter')],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'stats',
                        child: Row(
                          children: [Icon(Icons.analytics), SizedBox(width: 8), Text('Statistics')],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clear_completed',
                        child: Row(
                          children: [
                            Icon(Icons.clear_all),
                            SizedBox(width: 8),
                            Text('Clear Completed'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clear_all',
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Clear All', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
          body:
              downloadProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : downloadProvider.error != null
                  ? _buildErrorState(downloadProvider.error!)
                  : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDownloadsList(downloadProvider.downloads),
                      _buildDownloadsList(downloadProvider.activeDownloads),
                      _buildDownloadsList(downloadProvider.completedDownloads),
                      _buildDownloadsList(downloadProvider.failedDownloads),
                    ],
                  ),
          floatingActionButton:
              downloadProvider.hasActiveDownloads
                  ? FloatingActionButton.extended(
                    onPressed: () => _showActiveDownloadsDialog(context, downloadProvider),
                    icon: const Icon(Icons.downloading),
                    label: Text('${downloadProvider.activeCount} Active'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  )
                  : null,
        );
      },
    );
  }

  Widget _buildDownloadsList(List<DownloadItem> downloads) {
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      downloads =
          downloads.where((download) {
            return download.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                download.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
    }

    // Apply type filter
    if (_filterType != null) {
      downloads = downloads.where((d) => d.type == _filterType).toList();
    }

    // Apply status filter
    if (_filterStatus != null) {
      downloads = downloads.where((d) => d.status == _filterStatus).toList();
    }

    if (downloads.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<DownloadProvider>().loadDownloads();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: downloads.length,
        itemBuilder: (context, index) {
          final download = downloads[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DownloadItemCard(
              download: download,
              onPause: () => context.read<DownloadProvider>().pauseDownload(download.id),
              onResume: () => context.read<DownloadProvider>().resumeDownload(download.id),
              onCancel: () => context.read<DownloadProvider>().cancelDownload(download.id),
              onDelete: () => _confirmDelete(context, download),
              onRetry: () => context.read<DownloadProvider>().retryDownload(download.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No downloads found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your downloads will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Error Loading Downloads', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(error, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<DownloadProvider>().loadDownloads(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Search Downloads'),
            content: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Enter search term...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              autofocus: true,
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value;
                });
                Navigator.pop(context);
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                  Navigator.pop(context);
                },
                child: const Text('Clear'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = _searchController.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Search'),
              ),
            ],
          ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Filter Downloads'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Download Type:'),
                      const SizedBox(height: 8),
                      DropdownButton<DownloadType?>(
                        value: _filterType,
                        hint: const Text('All Types'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Types')),
                          ...DownloadType.values.map(
                            (type) =>
                                DropdownMenuItem(value: type, child: Text(type.name.toUpperCase())),
                          ),
                        ],
                        onChanged: (value) => setDialogState(() => _filterType = value),
                      ),
                      const SizedBox(height: 16),
                      const Text('Download Status:'),
                      const SizedBox(height: 8),
                      DropdownButton<DownloadStatus?>(
                        value: _filterStatus,
                        hint: const Text('All Statuses'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Statuses')),
                          ...DownloadStatus.values.map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.name.toUpperCase()),
                            ),
                          ),
                        ],
                        onChanged: (value) => setDialogState(() => _filterStatus = value),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          _filterType = null;
                          _filterStatus = null;
                        });
                        setState(() {
                          _filterType = null;
                          _filterStatus = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Clear Filters'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showStatsDialog(BuildContext context, DownloadProvider downloadProvider) {
    final stats = downloadProvider.getFormattedStats();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Download Statistics'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    stats.entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key),
                                Text(
                                  entry.value,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
    );
  }

  void _showActiveDownloadsDialog(BuildContext context, DownloadProvider downloadProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Active Downloads'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: downloadProvider.activeDownloads.length,
                itemBuilder: (context, index) {
                  final download = downloadProvider.activeDownloads[index];
                  return ListTile(
                    leading: CircularProgressIndicator(value: download.progress),
                    title: Text(download.title),
                    subtitle: Text('${(download.progress * 100).toStringAsFixed(1)}%'),
                    trailing: IconButton(
                      icon: Icon(download.canPause ? Icons.pause : Icons.play_arrow),
                      onPressed: () {
                        if (download.canPause) {
                          downloadProvider.pauseDownload(download.id);
                        } else {
                          downloadProvider.resumeDownload(download.id);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, DownloadProvider downloadProvider) {
    switch (action) {
      case 'filter':
        _showFilterDialog(context);
        break;
      case 'stats':
        _showStatsDialog(context, downloadProvider);
        break;
      case 'clear_completed':
        _confirmClearCompleted(context, downloadProvider);
        break;
      case 'clear_all':
        _confirmClearAll(context, downloadProvider);
        break;
    }
  }

  void _confirmDelete(BuildContext context, DownloadItem download) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Download'),
            content: Text('Are you sure you want to delete "${download.title}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  context.read<DownloadProvider>().deleteDownload(download.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Download deleted')));
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _confirmClearCompleted(BuildContext context, DownloadProvider downloadProvider) {
    final completedCount = downloadProvider.completedCount;
    if (completedCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No completed downloads to clear')));
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Completed Downloads'),
            content: Text('Are you sure you want to clear $completedCount completed downloads?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Delete all completed downloads
                  for (final download in downloadProvider.completedDownloads) {
                    await downloadProvider.deleteDownload(download.id);
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Completed downloads cleared')));
                },
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  void _confirmClearAll(BuildContext context, DownloadProvider downloadProvider) {
    final totalCount = downloadProvider.totalDownloads;
    if (totalCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No downloads to clear')));
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Downloads'),
            content: Text(
              'Are you sure you want to clear ALL $totalCount downloads? This will cancel active downloads and delete all files.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await downloadProvider.clearAllDownloads();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'All downloads cleared' : 'Failed to clear downloads',
                      ),
                    ),
                  );
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }
}
