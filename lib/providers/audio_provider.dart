import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/reciter_model.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';

class AudioProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();
  final NotificationService _notificationService = NotificationService();

  // State variables
  Reciter? _currentReciter;
  int? _currentSurahNumber;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;
  String? _error;
  bool _backgroundPlaybackEnabled = true;
  String? _currentSurahName;

  // Getters
  AudioService get audioService => _audioService;
  Reciter? get currentReciter => _currentReciter;
  int? get currentSurahNumber => _currentSurahNumber;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackSpeed => _playbackSpeed;
  double get volume => _volume;
  String? get error => _error;
  bool get backgroundPlaybackEnabled => _backgroundPlaybackEnabled;
  String? get currentSurahName => _currentSurahName;

  // Computed getters
  bool get hasAudio => _currentReciter != null && _currentSurahNumber != null;
  bool get canPlay => hasAudio && !_isLoading;
  double get progress =>
      _totalDuration.inMilliseconds > 0
          ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
          : 0.0;

  /// Initialize audio provider
  Future<void> initialize() async {
    await _audioService.initialize();
    await _notificationService.initialize();
    _setupListeners();
    _setupNotificationCallbacks();
  }

  /// Setup audio stream listeners
  void _setupListeners() {
    // Listen to player state changes
    _audioService.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading =
          state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      notifyListeners();
    });

    // Listen to position changes
    _audioService.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    // Listen to duration changes
    _audioService.durationStream.listen((duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });

    // Listen to speed changes
    _audioService.speedStream.listen((speed) {
      _playbackSpeed = speed;
      notifyListeners();
    });
  }

  /// Setup notification callbacks for background playback
  void _setupNotificationCallbacks() {
    _notificationService.setNotificationCallbacks(
      onPlay: () async {
        await togglePlayPause();
      },
      onPause: () async {
        await togglePlayPause();
      },
      onStop: () async {
        await stop();
      },
      onNext: () async {
        await skipToNext();
      },
      onPrevious: () async {
        await skipToPrevious();
      },
      onSeekForward: () async {
        await skipForward();
      },
      onSeekBackward: () async {
        await skipBackward();
      },
    );
  }

  /// Play surah with specific reciter
  Future<void> playSurah(Reciter reciter, int surahNumber) async {
    try {
      _clearError();
      _setLoading(true);

      _currentReciter = reciter;
      _currentSurahNumber = surahNumber;

      await _audioService.playSurah(reciter, surahNumber);
      await _updateNotification();
      notifyListeners();
    } catch (e) {
      _setError('Failed to play surah: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Play audio from URL
  Future<void> playFromUrl(String url) async {
    try {
      _clearError();
      _setLoading(true);

      await _audioService.playFromUrl(url);
    } catch (e) {
      _setError('Failed to play audio: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    try {
      _clearError();
      await _audioService.togglePlayPause();
      await _updateNotification();
    } catch (e) {
      _setError('Failed to toggle playback: $e');
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      _clearError();
      await _audioService.stop();
      _currentReciter = null;
      _currentSurahNumber = null;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
      notifyListeners();
    } catch (e) {
      _setError('Failed to stop playback: $e');
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      _clearError();
      await _audioService.seek(position);
    } catch (e) {
      _setError('Failed to seek: $e');
    }
  }

  /// Seek to progress (0.0 to 1.0)
  Future<void> seekToProgress(double progress) async {
    if (_totalDuration.inMilliseconds > 0) {
      final position = Duration(milliseconds: (_totalDuration.inMilliseconds * progress).round());
      await seek(position);
    }
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    try {
      _clearError();
      await _audioService.setSpeed(speed);
      _playbackSpeed = speed;
      notifyListeners();
    } catch (e) {
      _setError('Failed to set speed: $e');
    }
  }

  /// Set playback speed (alternative method name for UI compatibility)
  void setPlaybackSpeed(double speed) {
    setSpeed(speed);
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    try {
      _clearError();
      await _audioService.setVolume(volume);
      _volume = volume;
      notifyListeners();
    } catch (e) {
      _setError('Failed to set volume: $e');
    }
  }

  /// Skip forward
  Future<void> skipForward([Duration duration = const Duration(seconds: 10)]) async {
    try {
      _clearError();
      await _audioService.skipForward(duration);
    } catch (e) {
      _setError('Failed to skip forward: $e');
    }
  }

  /// Skip backward
  Future<void> skipBackward([Duration duration = const Duration(seconds: 10)]) async {
    try {
      _clearError();
      await _audioService.skipBackward(duration);
    } catch (e) {
      _setError('Failed to skip backward: $e');
    }
  }

  /// Skip to next surah
  Future<void> skipToNext() async {
    if (_currentSurahNumber != null && _currentReciter != null) {
      final nextSurahNumber = _currentSurahNumber! + 1;
      if (nextSurahNumber <= 114) {
        await playSurah(_currentReciter!, nextSurahNumber);
      }
    }
  }

  /// Skip to previous surah
  Future<void> skipToPrevious() async {
    if (_currentSurahNumber != null && _currentReciter != null) {
      final previousSurahNumber = _currentSurahNumber! - 1;
      if (previousSurahNumber >= 1) {
        await playSurah(_currentReciter!, previousSurahNumber);
      }
    }
  }

  /// Toggle background playback
  void toggleBackgroundPlayback() {
    _backgroundPlaybackEnabled = !_backgroundPlaybackEnabled;
    notifyListeners();
  }

  /// Set current surah name for notifications
  void setSurahName(String surahName) {
    _currentSurahName = surahName;
    notifyListeners();
  }

  /// Update notification with current playback state
  Future<void> _updateNotification() async {
    if (_backgroundPlaybackEnabled && _currentReciter != null && _currentSurahName != null) {
      await _notificationService.showAudioNotification(
        title: _currentSurahName!,
        subtitle: _currentReciter!.name,
        isPlaying: _isPlaying,
      );
    }
  }

  /// Format duration for display
  String formatDuration(Duration duration) {
    return _audioService.formatDuration(duration);
  }

  /// Get current position as formatted string
  String get formattedPosition => formatDuration(_currentPosition);

  /// Get total duration as formatted string
  String get formattedDuration => formatDuration(_totalDuration);

  /// Check if reciter has surah available
  bool reciterHasSurah(Reciter reciter, int surahNumber) {
    return reciter.moshaf.any((moshaf) => moshaf.availableSurahs.contains(surahNumber));
  }

  /// Get audio URL for surah
  String? getAudioUrl(Reciter reciter, int surahNumber) {
    for (final moshaf in reciter.moshaf) {
      if (moshaf.availableSurahs.contains(surahNumber)) {
        return moshaf.getAudioUrl(surahNumber);
      }
    }
    return null;
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
