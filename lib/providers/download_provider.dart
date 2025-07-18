import 'package:flutter/foundation.dart';
import '../services/download_service.dart';
import '../models/surah_model.dart';
import '../models/reciter_model.dart';

class DownloadProvider extends ChangeNotifier {
  final DownloadService _downloadService = DownloadService();

  // State variables
  List<DownloadItem> _downloads = [];
  Map<String, dynamic> _downloadStats = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<DownloadItem> get downloads => _downloads;
  Map<String, dynamic> get downloadStats => _downloadStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed getters
  List<DownloadItem> get activeDownloads =>
      _downloads.where((d) => d.isDownloading || d.isPaused).toList();

  List<DownloadItem> get completedDownloads => _downloads.where((d) => d.isCompleted).toList();

  List<DownloadItem> get failedDownloads => _downloads.where((d) => d.isFailed).toList();

  List<DownloadItem> get audioDownloads =>
      _downloads.where((d) => d.type == DownloadType.audio).toList();

  List<DownloadItem> get surahDownloads =>
      _downloads.where((d) => d.type == DownloadType.surah).toList();

  int get totalDownloads => _downloads.length;
  int get completedCount => completedDownloads.length;
  int get activeCount => activeDownloads.length;
  int get failedCount => failedDownloads.length;

  bool get hasActiveDownloads => activeDownloads.isNotEmpty;
  bool get hasCompletedDownloads => completedDownloads.isNotEmpty;
  bool get hasFailedDownloads => failedDownloads.isNotEmpty;

  /// Initialize download provider
  Future<void> initialize() async {
    await loadDownloads();
    await loadDownloadStats();
  }

  /// Load all downloads
  Future<void> loadDownloads() async {
    _setLoading(true);
    _clearError();

    try {
      _downloads = await _downloadService.getAllDownloads();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load downloads: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load download statistics
  Future<void> loadDownloadStats() async {
    try {
      _downloadStats = await _downloadService.getDownloadStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load download stats: $e');
    }
  }

  /// Check if surah is downloaded
  Future<bool> isSurahDownloaded(int surahNumber) async {
    try {
      return await _downloadService.isSurahTextDownloaded(surahNumber);
    } catch (e) {
      return false;
    }
  }

  /// Get downloaded surah data
  Future<Surah?> getDownloadedSurah(int surahNumber) async {
    try {
      return await _downloadService.getDownloadedSurah(surahNumber);
    } catch (e) {
      debugPrint('Failed to get downloaded surah $surahNumber: $e');
      return null;
    }
  }

  /// Check if surah audio is downloaded
  Future<bool> isSurahAudioDownloaded(int surahNumber, Reciter reciter) async {
    try {
      return await _downloadService.isSurahAudioDownloaded(surahNumber, reciter);
    } catch (e) {
      return false;
    }
  }

  /// Download surah text
  Future<bool> downloadSurah(Surah surah) async {
    _clearError();

    try {
      final downloadItem = await _downloadService.downloadSurah(
        surah,
        onProgress: (item) {
          _updateDownloadItem(item);
        },
      );

      if (downloadItem != null) {
        await loadDownloads();
        await loadDownloadStats();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to download surah: $e');
      return false;
    }
  }

  /// Download surah audio
  Future<bool> downloadSurahAudio(int surahNumber, String surahName, Reciter reciter) async {
    _clearError();

    try {
      final downloadItem = await _downloadService.downloadSurahAudio(
        surahNumber,
        surahName,
        reciter,
        onProgress: (item) {
          _updateDownloadItem(item);
        },
      );

      if (downloadItem != null) {
        await loadDownloads();
        await loadDownloadStats();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to download audio: $e');
      return false;
    }
  }

  /// Pause download
  Future<bool> pauseDownload(String id) async {
    _clearError();

    try {
      await _downloadService.pauseDownload(id);
      await loadDownloads();
      return true;
    } catch (e) {
      _setError('Failed to pause download: $e');
      return false;
    }
  }

  /// Resume download
  Future<bool> resumeDownload(String id) async {
    _clearError();

    try {
      await _downloadService.resumeDownload(id);
      await loadDownloads();
      return true;
    } catch (e) {
      _setError('Failed to resume download: $e');
      return false;
    }
  }

  /// Cancel download
  Future<bool> cancelDownload(String id) async {
    _clearError();

    try {
      await _downloadService.cancelDownload(id);
      await loadDownloads();
      await loadDownloadStats();
      return true;
    } catch (e) {
      _setError('Failed to cancel download: $e');
      return false;
    }
  }

  /// Delete download
  Future<bool> deleteDownload(String id) async {
    _clearError();

    try {
      await _downloadService.deleteDownload(id);
      await loadDownloads();
      await loadDownloadStats();
      return true;
    } catch (e) {
      _setError('Failed to delete download: $e');
      return false;
    }
  }

  /// Retry failed download
  Future<bool> retryDownload(String id) async {
    final download = _downloads.firstWhere((d) => d.id == id);

    if (download.type == DownloadType.audio &&
        download.reciter != null &&
        download.surahNumber != null) {
      return await downloadSurahAudio(download.surahNumber!, download.title, download.reciter!);
    } else if (download.type == DownloadType.surah && download.surahNumber != null) {
      // Create a temporary Surah object for retry
      final surah = Surah(
        number: download.surahNumber!,
        name: download.title,
        englishName: download.title,
        englishTranslation: download.subtitle,
        revelationType: '',
        numberOfAyahs: 0,
      );
      return await downloadSurah(surah);
    }

    return false;
  }

  /// Clear all downloads
  Future<bool> clearAllDownloads() async {
    _clearError();

    try {
      await _downloadService.clearAllDownloads();
      await loadDownloads();
      await loadDownloadStats();
      return true;
    } catch (e) {
      _setError('Failed to clear downloads: $e');
      return false;
    }
  }

  /// Get download by ID
  DownloadItem? getDownloadById(String id) {
    try {
      return _downloads.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get downloads by surah number
  List<DownloadItem> getDownloadsBySurah(int surahNumber) {
    return _downloads.where((d) => d.surahNumber == surahNumber).toList();
  }

  /// Get downloads by reciter
  List<DownloadItem> getDownloadsByReciter(Reciter reciter) {
    return _downloads.where((d) => d.reciter?.id == reciter.id).toList();
  }

  /// Get downloads by status
  List<DownloadItem> getDownloadsByStatus(DownloadStatus status) {
    return _downloads.where((d) => d.status == status).toList();
  }

  /// Get downloads by type
  List<DownloadItem> getDownloadsByType(DownloadType type) {
    return _downloads.where((d) => d.type == type).toList();
  }

  /// Get total download size
  String getTotalDownloadSize() {
    int totalBytes = 0;
    for (final download in completedDownloads) {
      totalBytes += download.totalBytes;
    }
    final mb = totalBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Get download progress for a specific surah
  double? getSurahDownloadProgress(int surahNumber) {
    final downloads = getDownloadsBySurah(surahNumber);
    if (downloads.isEmpty) return null;

    double totalProgress = 0;
    for (final download in downloads) {
      totalProgress += download.progress;
    }
    return totalProgress / downloads.length;
  }

  /// Check if any downloads are active for a surah
  bool isSurahDownloadActive(int surahNumber) {
    final downloads = getDownloadsBySurah(surahNumber);
    return downloads.any((d) => d.isDownloading);
  }

  /// Get formatted download statistics
  Map<String, String> getFormattedStats() {
    return {
      'Total Downloads': totalDownloads.toString(),
      'Completed': completedCount.toString(),
      'Active': activeCount.toString(),
      'Failed': failedCount.toString(),
      'Audio Files': audioDownloads.length.toString(),
      'Surah Files': surahDownloads.length.toString(),
      'Total Size': getTotalDownloadSize(),
    };
  }

  /// Export downloads list
  Map<String, dynamic> exportDownloads() {
    return {
      'downloads': _downloads.map((d) => d.toJson()).toList(),
      'stats': _downloadStats,
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  /// Search downloads
  List<DownloadItem> searchDownloads(String query) {
    if (query.isEmpty) return _downloads;

    final lowerQuery = query.toLowerCase();
    return _downloads.where((download) {
      return download.title.toLowerCase().contains(lowerQuery) ||
          download.subtitle.toLowerCase().contains(lowerQuery) ||
          (download.reciter?.name.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Filter downloads
  List<DownloadItem> filterDownloads({
    DownloadType? type,
    DownloadStatus? status,
    Reciter? reciter,
  }) {
    return _downloads.where((download) {
      if (type != null && download.type != type) return false;
      if (status != null && download.status != status) return false;
      if (reciter != null && download.reciter?.id != reciter.id) return false;
      return true;
    }).toList();
  }

  /// Update download item in the list
  void _updateDownloadItem(DownloadItem item) {
    final index = _downloads.indexWhere((d) => d.id == item.id);
    if (index != -1) {
      _downloads[index] = item;
      notifyListeners();
    } else {
      // Item not in list yet, add it
      _downloads.add(item);
      notifyListeners();
    }
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _downloadService.dispose();
    super.dispose();
  }
}
