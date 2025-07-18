import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel('quran_app/notifications');

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  /// Show audio playback notification
  Future<void> showAudioNotification({
    required String title,
    required String subtitle,
    required bool isPlaying,
    String? artwork,
  }) async {
    try {
      await _channel.invokeMethod('showAudioNotification', {
        'title': title,
        'subtitle': subtitle,
        'isPlaying': isPlaying,
        'artwork': artwork,
      });
    } catch (e) {
      debugPrint('Failed to show audio notification: $e');
    }
  }

  /// Hide audio notification
  Future<void> hideAudioNotification() async {
    try {
      await _channel.invokeMethod('hideAudioNotification');
    } catch (e) {
      debugPrint('Failed to hide audio notification: $e');
    }
  }

  /// Update notification playback state
  Future<void> updatePlaybackState(bool isPlaying) async {
    try {
      await _channel.invokeMethod('updatePlaybackState', {'isPlaying': isPlaying});
    } catch (e) {
      debugPrint('Failed to update playback state: $e');
    }
  }

  /// Set up notification callbacks
  void setNotificationCallbacks({
    VoidCallback? onPlay,
    VoidCallback? onPause,
    VoidCallback? onStop,
    VoidCallback? onNext,
    VoidCallback? onPrevious,
    VoidCallback? onSeekForward,
    VoidCallback? onSeekBackward,
  }) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPlay':
          onPlay?.call();
          break;
        case 'onPause':
          onPause?.call();
          break;
        case 'onStop':
          onStop?.call();
          break;
        case 'onNext':
          onNext?.call();
          break;
        case 'onPrevious':
          onPrevious?.call();
          break;
        case 'onSeekForward':
          onSeekForward?.call();
          break;
        case 'onSeekBackward':
          onSeekBackward?.call();
          break;
        default:
          debugPrint('Unknown notification method: ${call.method}');
      }
    });
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } catch (e) {
      debugPrint('Failed to request notification permissions: $e');
      return false;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('areNotificationsEnabled');
      return result ?? false;
    } catch (e) {
      debugPrint('Failed to check notification status: $e');
      return false;
    }
  }

  /// Show daily verse notification
  Future<void> showDailyVerseNotification({
    required String title,
    required String body,
    String? verseReference,
  }) async {
    try {
      await _channel.invokeMethod('showDailyVerseNotification', {
        'title': title,
        'body': body,
        'verseReference': verseReference,
      });
    } catch (e) {
      debugPrint('Failed to show daily verse notification: $e');
    }
  }

  /// Schedule daily verse notifications
  Future<void> scheduleDailyVerseNotifications({
    required int hour,
    required int minute,
    required bool enabled,
  }) async {
    try {
      await _channel.invokeMethod('scheduleDailyVerseNotifications', {
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
      });
    } catch (e) {
      debugPrint('Failed to schedule daily verse notifications: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _channel.invokeMethod('cancelAllNotifications');
    } catch (e) {
      debugPrint('Failed to cancel notifications: $e');
    }
  }

  /// Show reading reminder notification
  Future<void> showReadingReminder({required String title, required String body}) async {
    try {
      await _channel.invokeMethod('showReadingReminder', {'title': title, 'body': body});
    } catch (e) {
      debugPrint('Failed to show reading reminder: $e');
    }
  }
}
