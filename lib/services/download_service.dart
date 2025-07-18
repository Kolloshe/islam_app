import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah_model.dart';
import '../models/reciter_model.dart';

enum DownloadType { surah, audio }

enum DownloadStatus { pending, downloading, paused, completed, failed, cancelled }

class DownloadItem {
  final String id;
  final String title;
  final String subtitle;
  final DownloadType type;
  final String url;
  final String filePath;
  final int? surahNumber;
  final Reciter? reciter;
  DownloadStatus status;
  double progress;
  int totalBytes;
  int downloadedBytes;
  String? error;
  DateTime createdAt;
  DateTime? completedAt;

  DownloadItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.url,
    required this.filePath,
    this.surahNumber,
    this.reciter,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.error,
    required this.createdAt,
    this.completedAt,
  });

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      type: DownloadType.values[json['type']],
      url: json['url'],
      filePath: json['filePath'],
      surahNumber: json['surahNumber'],
      reciter: json['reciter'] != null ? Reciter.fromJson(json['reciter']) : null,
      status: DownloadStatus.values[json['status']],
      progress: json['progress'],
      totalBytes: json['totalBytes'],
      downloadedBytes: json['downloadedBytes'],
      error: json['error'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'type': type.index,
      'url': url,
      'filePath': filePath,
      'surahNumber': surahNumber,
      'reciter': reciter?.toJson(),
      'status': status.index,
      'progress': progress,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'error': error,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  String get formattedSize {
    if (totalBytes == 0) {
      // If size is unknown, show downloaded size instead
      if (downloadedBytes > 0) {
        final mb = downloadedBytes / (1024 * 1024);
        return '${mb.toStringAsFixed(1)} MB';
      }
      return 'Unknown size';
    }
    final mb = totalBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get formattedDownloadedSize {
    final mb = downloadedBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isPaused => status == DownloadStatus.paused;
  bool get isFailed => status == DownloadStatus.failed;
  bool get canResume => isPaused || isFailed;
  bool get canPause => isDownloading;
}

class DownloadService {
  static const String _downloadsKey = 'downloads';
  static const String _downloadStatsKey = 'download_stats';

  final Map<String, http.Client> _activeDownloads = {};
  final Map<String, Function(DownloadItem)> _progressCallbacks = {};

  // Get downloads directory
  Future<Directory> _getDownloadsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${appDir.path}/downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }

  // Get audio downloads directory
  Future<Directory> _getAudioDownloadsDirectory() async {
    final downloadsDir = await _getDownloadsDirectory();
    final audioDir = Directory('${downloadsDir.path}/audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  // Get surah downloads directory
  Future<Directory> _getSurahDownloadsDirectory() async {
    final downloadsDir = await _getDownloadsDirectory();
    final surahDir = Directory('${downloadsDir.path}/surahs');
    if (!await surahDir.exists()) {
      await surahDir.create(recursive: true);
    }
    return surahDir;
  }

  // Save downloads list
  Future<void> _saveDownloads(List<DownloadItem> downloads) async {
    final prefs = await SharedPreferences.getInstance();
    final downloadsJson = downloads.map((d) => d.toJson()).toList();
    await prefs.setString(_downloadsKey, jsonEncode(downloadsJson));
  }

  // Load downloads list
  Future<List<DownloadItem>> getAllDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = prefs.getString(_downloadsKey);

      if (downloadsJson != null) {
        final List<dynamic> downloadsList = jsonDecode(downloadsJson);
        return downloadsList.map((json) => DownloadItem.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load downloads: $e');
    }
    return [];
  }

  // Get downloads by status
  Future<List<DownloadItem>> getDownloadsByStatus(DownloadStatus status) async {
    final downloads = await getAllDownloads();
    return downloads.where((d) => d.status == status).toList();
  }

  // Get downloads by type
  Future<List<DownloadItem>> getDownloadsByType(DownloadType type) async {
    final downloads = await getAllDownloads();
    return downloads.where((d) => d.type == type).toList();
  }

  // Check if item is downloaded
  Future<bool> isDownloaded(String id) async {
    final downloads = await getAllDownloads();
    final download = downloads.firstWhere(
      (d) => d.id == id,
      orElse:
          () => DownloadItem(
            id: '',
            title: '',
            subtitle: '',
            type: DownloadType.surah,
            url: '',
            filePath: '',
            createdAt: DateTime.now(),
          ),
    );
    return download.id.isNotEmpty && download.isCompleted;
  }

  // Check if surah audio is downloaded
  Future<bool> isSurahAudioDownloaded(int surahNumber, Reciter reciter) async {
    final id = 'audio_${surahNumber}_${reciter.id}';
    return await isDownloaded(id);
  }

  // Check if surah text is downloaded
  Future<bool> isSurahTextDownloaded(int surahNumber) async {
    final id = 'surah_$surahNumber';
    return await isDownloaded(id);
  }

  // Get downloaded surah data
  Future<Surah?> getDownloadedSurah(int surahNumber) async {
    try {
      final isDownloaded = await isSurahTextDownloaded(surahNumber);
      if (!isDownloaded) return null;

      final surahDir = await _getSurahDownloadsDirectory();
      final file = File('${surahDir.path}/surah_$surahNumber.json');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString);

        // The API response has a 'data' field containing the surah
        if (jsonData['code'] == 200 && jsonData['data'] != null) {
          return Surah.fromJson(jsonData['data']);
        }
      }
    } catch (e) {
      debugPrint('Failed to load downloaded surah $surahNumber: $e');
    }
    return null;
  }

  // Download surah text
  Future<DownloadItem?> downloadSurah(Surah surah, {Function(DownloadItem)? onProgress}) async {
    try {
      final id = 'surah_${surah.number}';
      final surahDir = await _getSurahDownloadsDirectory();
      final filePath = '${surahDir.path}/surah_${surah.number}.json';

      final downloadItem = DownloadItem(
        id: id,
        title: surah.englishName,
        subtitle: 'Surah ${surah.number} - ${surah.numberOfAyahs} verses',
        type: DownloadType.surah,
        url: 'https://api.alquran.cloud/v1/surah/${surah.number}/quran-uthmani',
        filePath: filePath,
        surahNumber: surah.number,
        createdAt: DateTime.now(),
      );

      if (onProgress != null) {
        _progressCallbacks[id] = onProgress;
      }

      await _addDownload(downloadItem);
      await _startDownload(downloadItem);

      return downloadItem;
    } catch (e) {
      debugPrint('Failed to start surah download: $e');
      return null;
    }
  }

  // Download surah audio
  Future<DownloadItem?> downloadSurahAudio(
    int surahNumber,
    String surahName,
    Reciter reciter, {
    Function(DownloadItem)? onProgress,
  }) async {
    try {
      final id = 'audio_${surahNumber}_${reciter.id}';
      final audioDir = await _getAudioDownloadsDirectory();
      final filePath = '${audioDir.path}/${reciter.id}_$surahNumber.mp3';

      // Get audio URL from reciter
      String? audioUrl;
      for (final moshaf in reciter.moshaf) {
        if (moshaf.availableSurahs.contains(surahNumber)) {
          audioUrl = moshaf.getAudioUrl(surahNumber);
          debugPrint('Audio URL for surah $surahNumber: $audioUrl');
          break;
        }
      }

      if (audioUrl == null) {
        debugPrint('No moshaf found for surah $surahNumber in reciter ${reciter.name}');
        throw Exception('Audio not available for this surah');
      }

      final downloadItem = DownloadItem(
        id: id,
        title: surahName,
        subtitle: '${reciter.name} - Surah $surahNumber',
        type: DownloadType.audio,
        url: audioUrl,
        filePath: filePath,
        surahNumber: surahNumber,
        reciter: reciter,
        createdAt: DateTime.now(),
      );

      if (onProgress != null) {
        _progressCallbacks[id] = onProgress;
      }

      await _addDownload(downloadItem);
      await _startDownload(downloadItem);

      return downloadItem;
    } catch (e) {
      debugPrint('Failed to start audio download: $e');
      return null;
    }
  }

  // Start download
  Future<void> _startDownload(DownloadItem item) async {
    try {
      debugPrint('Starting download for ${item.id}: ${item.url}');
      final client = http.Client();
      _activeDownloads[item.id] = client;

      item.status = DownloadStatus.downloading;
      await _updateDownload(item);

      final request = http.Request('GET', Uri.parse(item.url));
      final response = await client
          .send(request)
          .timeout(
            const Duration(minutes: 5),
            onTimeout: () {
              throw Exception('Download timeout after 5 minutes');
            },
          );

      debugPrint(
        'Download response for ${item.id}: ${response.statusCode}, Content-Length: ${response.contentLength}',
      );

      if (response.statusCode == 200) {
        item.totalBytes = response.contentLength ?? 0;
        debugPrint('Total bytes for ${item.id}: ${item.totalBytes}');
        await _updateDownload(item);

        final file = File(item.filePath);
        await file.parent.create(recursive: true);
        final sink = file.openWrite();

        int chunkCount = 0;
        try {
          await for (final chunk in response.stream) {
            chunkCount++;
            sink.add(chunk);
            item.downloadedBytes += chunk.length;

            // Handle unknown content length
            if (item.totalBytes == 0) {
              // For unknown size, show indeterminate progress
              item.progress = 0.5; // Show as 50% for visual feedback
            } else {
              item.progress = item.downloadedBytes / item.totalBytes;
            }

            // Debug logging
            if (chunkCount <= 5) {
              debugPrint(
                'Chunk $chunkCount for ${item.id}: ${chunk.length} bytes, total: ${item.downloadedBytes}',
              );
            }

            // Update progress every chunk for small files, less frequently for large files
            bool shouldUpdate = false;
            if (item.totalBytes < 1024 * 1024) {
              // Files smaller than 1MB - update every chunk
              shouldUpdate = true;
            } else if (item.downloadedBytes % (1024 * 50) < chunk.length) {
              // Every 50KB for larger files
              shouldUpdate = true;
            }

            if (shouldUpdate) {
              await _updateDownload(item);
              _progressCallbacks[item.id]?.call(item);
            }
          }

          // Download completed successfully
          debugPrint(
            'Download completed for ${item.id}, final size: ${item.downloadedBytes} bytes',
          );
          await sink.close();

          // Update total bytes if it was unknown
          if (item.totalBytes == 0) {
            item.totalBytes = item.downloadedBytes;
          }

          item.status = DownloadStatus.completed;
          item.progress = 1.0;
          item.completedAt = DateTime.now();

          // Final update to mark as completed
          await _updateDownload(item);
          _progressCallbacks[item.id]?.call(item);

          // Clean up active download tracking
          _activeDownloads.remove(item.id);
          _progressCallbacks.remove(item.id);

          debugPrint('Download ${item.id} marked as completed and cleaned up');
        } catch (error) {
          debugPrint('Download stream error for ${item.id}: $error');
          await sink.close();
          item.status = DownloadStatus.failed;
          item.error = error.toString();

          await _updateDownload(item);
          _progressCallbacks[item.id]?.call(item);
          _activeDownloads.remove(item.id);
          _progressCallbacks.remove(item.id);
        }
      } else {
        throw Exception('Failed to download: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Download error for ${item.id}: $e');
      item.status = DownloadStatus.failed;
      item.error = e.toString();
      await _updateDownload(item);
      _activeDownloads.remove(item.id);
      _progressCallbacks.remove(item.id);
    }
  }

  // Pause download
  Future<void> pauseDownload(String id) async {
    final client = _activeDownloads[id];
    if (client != null) {
      client.close();
      _activeDownloads.remove(id);

      final downloads = await getAllDownloads();
      final downloadIndex = downloads.indexWhere((d) => d.id == id);
      if (downloadIndex != -1) {
        downloads[downloadIndex].status = DownloadStatus.paused;
        await _saveDownloads(downloads);
      }
    }
  }

  // Resume download
  Future<void> resumeDownload(String id) async {
    final downloads = await getAllDownloads();
    final download = downloads.firstWhere((d) => d.id == id);
    await _startDownload(download);
  }

  // Cancel download
  Future<void> cancelDownload(String id) async {
    final client = _activeDownloads[id];
    if (client != null) {
      client.close();
      _activeDownloads.remove(id);
    }

    final downloads = await getAllDownloads();
    final downloadIndex = downloads.indexWhere((d) => d.id == id);
    if (downloadIndex != -1) {
      final download = downloads[downloadIndex];

      // Delete partial file
      final file = File(download.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      downloads.removeAt(downloadIndex);
      await _saveDownloads(downloads);
    }

    _progressCallbacks.remove(id);
  }

  // Delete downloaded file
  Future<void> deleteDownload(String id) async {
    final downloads = await getAllDownloads();
    final downloadIndex = downloads.indexWhere((d) => d.id == id);
    if (downloadIndex != -1) {
      final download = downloads[downloadIndex];

      // Delete file
      final file = File(download.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      downloads.removeAt(downloadIndex);
      await _saveDownloads(downloads);
    }
  }

  // Get downloaded file
  Future<File?> getDownloadedFile(String id) async {
    final downloads = await getAllDownloads();
    final download = downloads.firstWhere(
      (d) => d.id == id && d.isCompleted,
      orElse:
          () => DownloadItem(
            id: '',
            title: '',
            subtitle: '',
            type: DownloadType.surah,
            url: '',
            filePath: '',
            createdAt: DateTime.now(),
          ),
    );

    if (download.id.isNotEmpty) {
      final file = File(download.filePath);
      if (await file.exists()) {
        return file;
      }
    }
    return null;
  }

  // Get download statistics
  Future<Map<String, dynamic>> getDownloadStats() async {
    final downloads = await getAllDownloads();
    final completedDownloads = downloads.where((d) => d.isCompleted).toList();

    int totalSize = 0;
    int audioCount = 0;
    int surahCount = 0;

    for (final download in completedDownloads) {
      totalSize += download.totalBytes;
      if (download.type == DownloadType.audio) {
        audioCount++;
      } else {
        surahCount++;
      }
    }

    return {
      'totalDownloads': completedDownloads.length,
      'audioDownloads': audioCount,
      'surahDownloads': surahCount,
      'totalSize': totalSize,
      'formattedSize': '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB',
    };
  }

  // Clear all downloads
  Future<void> clearAllDownloads() async {
    final downloads = await getAllDownloads();

    // Cancel active downloads
    for (final client in _activeDownloads.values) {
      client.close();
    }
    _activeDownloads.clear();
    _progressCallbacks.clear();

    // Delete all files
    for (final download in downloads) {
      final file = File(download.filePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('Failed to delete file: ${download.filePath}');
        }
      }
    }

    // Clear downloads list
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_downloadsKey);
  }

  // Helper methods
  Future<void> _addDownload(DownloadItem item) async {
    final downloads = await getAllDownloads();
    downloads.add(item);
    await _saveDownloads(downloads);
  }

  Future<void> _updateDownload(DownloadItem item) async {
    try {
      final downloads = await getAllDownloads();
      final index = downloads.indexWhere((d) => d.id == item.id);
      if (index != -1) {
        downloads[index] = item;
        await _saveDownloads(downloads);
        debugPrint(
          'Updated download ${item.id}: ${item.status.name}, progress: ${(item.progress * 100).toStringAsFixed(1)}%',
        );
      } else {
        debugPrint('Warning: Download ${item.id} not found in list for update');
      }
    } catch (e) {
      debugPrint('Error updating download ${item.id}: $e');
    }
  }

  // Cleanup
  void dispose() {
    for (final client in _activeDownloads.values) {
      client.close();
    }
    _activeDownloads.clear();
    _progressCallbacks.clear();
  }
}
