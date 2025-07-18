import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/reciter_model.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioSession? _audioSession;

  // Getters
  AudioPlayer get player => _audioPlayer;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<double> get speedStream => _audioPlayer.speedStream;

  bool get isPlaying => _audioPlayer.playing;
  bool get isPaused => !_audioPlayer.playing && _audioPlayer.position.inSeconds > 0;
  Duration? get duration => _audioPlayer.duration;
  Duration get position => _audioPlayer.position;

  /// Initialize audio session
  Future<void> initialize() async {
    try {
      _audioSession = await AudioSession.instance;
      await _audioSession!.configure(const AudioSessionConfiguration.speech());
    } catch (e) {
      print('Error initializing audio session: $e');
    }
  }

  /// Play audio from URL
  Future<void> playFromUrl(String url) async {
    try {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      throw Exception('Error playing audio: $e');
    }
  }

  /// Play surah recitation
  Future<void> playSurah(Reciter reciter, int surahNumber) async {
    try {
      if (reciter.moshaf.isNotEmpty) {
        final moshaf = reciter.moshaf.first;
        if (moshaf.availableSurahs.contains(surahNumber)) {
          final audioUrl = moshaf.getAudioUrl(surahNumber);
          await playFromUrl(audioUrl);
        } else {
          throw Exception('Surah $surahNumber not available for this reciter');
        }
      } else {
        throw Exception('No moshaf available for this reciter');
      }
    } catch (e) {
      throw Exception('Error playing surah: $e');
    }
  }

  /// Play/Pause toggle
  Future<void> togglePlayPause() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      throw Exception('Error toggling play/pause: $e');
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      throw Exception('Error stopping audio: $e');
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      throw Exception('Error seeking: $e');
    }
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
    } catch (e) {
      throw Exception('Error setting speed: $e');
    }
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
    } catch (e) {
      throw Exception('Error setting volume: $e');
    }
  }

  /// Skip forward by duration
  Future<void> skipForward([Duration duration = const Duration(seconds: 10)]) async {
    try {
      final newPosition = _audioPlayer.position + duration;
      await seek(newPosition);
    } catch (e) {
      throw Exception('Error skipping forward: $e');
    }
  }

  /// Skip backward by duration
  Future<void> skipBackward([Duration duration = const Duration(seconds: 10)]) async {
    try {
      final newPosition = _audioPlayer.position - duration;
      await seek(newPosition < Duration.zero ? Duration.zero : newPosition);
    } catch (e) {
      throw Exception('Error skipping backward: $e');
    }
  }

  /// Format duration to string
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
    } catch (e) {
      print('Error disposing audio player: $e');
    }
  }
}
