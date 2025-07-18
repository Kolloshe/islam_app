import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingTrackerService {
  static const String _progressKey = 'reading_progress';
  static const String _sessionsKey = 'reading_sessions';
  static const String _goalsKey = 'reading_goals';
  static const String _streakKey = 'reading_streak';
  static const String _statsKey = 'reading_stats';

  /// Save reading progress for a specific verse
  Future<void> saveReadingProgress({
    required int surahNumber,
    required int verseNumber,
    required String surahName,
    required DateTime timestamp,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current progress
      final progressData = await getReadingProgress();

      // Update progress for this surah
      progressData[surahNumber.toString()] = {
        'surahNumber': surahNumber,
        'surahName': surahName,
        'lastVerseRead': verseNumber,
        'lastReadAt': timestamp.toIso8601String(),
        'totalVersesRead': _calculateTotalVersesRead(
          progressData[surahNumber.toString()],
          verseNumber,
        ),
        'completionPercentage': _calculateCompletionPercentage(surahNumber, verseNumber),
      };

      // Save updated progress
      await prefs.setString(_progressKey, jsonEncode(progressData));

      // Update reading streak
      await _updateReadingStreak(timestamp);

      // Update daily stats
      await _updateDailyStats(timestamp);
    } catch (e) {
      debugPrint('Failed to save reading progress: $e');
    }
  }

  /// Get reading progress for all surahs
  Future<Map<String, dynamic>> getReadingProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressKey);

      if (progressJson != null) {
        return Map<String, dynamic>.from(jsonDecode(progressJson));
      }
    } catch (e) {
      debugPrint('Failed to get reading progress: $e');
    }

    return {};
  }

  /// Get reading progress for a specific surah
  Future<Map<String, dynamic>?> getSurahProgress(int surahNumber) async {
    try {
      final allProgress = await getReadingProgress();
      return allProgress[surahNumber.toString()];
    } catch (e) {
      debugPrint('Failed to get surah progress: $e');
      return null;
    }
  }

  /// Start a new reading session
  Future<String> startReadingSession({required int surahNumber, required String surahName}) async {
    try {
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final session = ReadingSession(
        id: sessionId,
        surahNumber: surahNumber,
        surahName: surahName,
        startTime: DateTime.now(),
        isActive: true,
      );

      await _saveReadingSession(session);
      return sessionId;
    } catch (e) {
      debugPrint('Failed to start reading session: $e');
      return '';
    }
  }

  /// End a reading session
  Future<void> endReadingSession(
    String sessionId, {
    int? lastVerseRead,
    int? totalVersesRead,
  }) async {
    try {
      final session = await _getReadingSession(sessionId);
      if (session != null) {
        final updatedSession = session.copyWith(
          endTime: DateTime.now(),
          isActive: false,
          lastVerseRead: lastVerseRead,
          totalVersesRead: totalVersesRead,
        );

        await _saveReadingSession(updatedSession);

        // Update reading stats
        await _updateSessionStats(updatedSession);
      }
    } catch (e) {
      debugPrint('Failed to end reading session: $e');
    }
  }

  /// Update reading session progress
  Future<void> updateSessionProgress(
    String sessionId, {
    required int currentVerse,
    int? totalVersesRead,
  }) async {
    try {
      final session = await _getReadingSession(sessionId);
      if (session != null && session.isActive) {
        final updatedSession = session.copyWith(
          lastVerseRead: currentVerse,
          totalVersesRead: totalVersesRead,
          lastActivity: DateTime.now(),
        );

        await _saveReadingSession(updatedSession);
      }
    } catch (e) {
      debugPrint('Failed to update session progress: $e');
    }
  }

  /// Get current active reading session
  Future<ReadingSession?> getActiveReadingSession() async {
    try {
      final sessions = await _getAllReadingSessions();
      return sessions.firstWhere(
        (session) => session.isActive,
        orElse: () => throw StateError('No active session'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get reading sessions for a date range
  Future<List<ReadingSession>> getReadingSessions({DateTime? startDate, DateTime? endDate}) async {
    try {
      final allSessions = await _getAllReadingSessions();

      if (startDate == null && endDate == null) {
        return allSessions;
      }

      return allSessions.where((session) {
        final sessionDate = session.startTime;

        if (startDate != null && sessionDate.isBefore(startDate)) {
          return false;
        }

        if (endDate != null && sessionDate.isAfter(endDate)) {
          return false;
        }

        return true;
      }).toList();
    } catch (e) {
      debugPrint('Failed to get reading sessions: $e');
      return [];
    }
  }

  /// Get reading statistics
  Future<ReadingStats> getReadingStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_statsKey);

      if (statsJson != null) {
        final statsData = jsonDecode(statsJson);
        return ReadingStats.fromJson(statsData);
      }

      // Calculate stats if not cached
      return await _calculateReadingStats();
    } catch (e) {
      debugPrint('Failed to get reading stats: $e');
      return ReadingStats.empty();
    }
  }

  /// Set reading goal
  Future<void> setReadingGoal(ReadingGoal goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_goalsKey, jsonEncode(goal.toJson()));
    } catch (e) {
      debugPrint('Failed to set reading goal: $e');
    }
  }

  /// Get current reading goal
  Future<ReadingGoal?> getReadingGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalJson = prefs.getString(_goalsKey);

      if (goalJson != null) {
        return ReadingGoal.fromJson(jsonDecode(goalJson));
      }
    } catch (e) {
      debugPrint('Failed to get reading goal: $e');
    }

    return null;
  }

  /// Get reading streak information
  Future<ReadingStreak> getReadingStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streakJson = prefs.getString(_streakKey);

      if (streakJson != null) {
        return ReadingStreak.fromJson(jsonDecode(streakJson));
      }
    } catch (e) {
      debugPrint('Failed to get reading streak: $e');
    }

    return ReadingStreak.empty();
  }

  /// Get overall completion percentage
  Future<double> getOverallCompletionPercentage() async {
    try {
      final progress = await getReadingProgress();
      if (progress.isEmpty) return 0.0;

      double totalCompletion = 0.0;
      int surahCount = 0;

      for (final entry in progress.values) {
        if (entry is Map<String, dynamic>) {
          totalCompletion += (entry['completionPercentage'] as num?)?.toDouble() ?? 0.0;
          surahCount++;
        }
      }

      return surahCount > 0 ? totalCompletion / surahCount : 0.0;
    } catch (e) {
      debugPrint('Failed to calculate overall completion: $e');
      return 0.0;
    }
  }

  /// Get reading insights and recommendations
  Future<ReadingInsights> getReadingInsights() async {
    try {
      final stats = await getReadingStats();
      final streak = await getReadingStreak();
      final goal = await getReadingGoal();
      final sessions = await getReadingSessions(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
      );

      return ReadingInsights(
        stats: stats,
        streak: streak,
        goal: goal,
        recentSessions: sessions,
        recommendations: _generateRecommendations(stats, streak, sessions),
      );
    } catch (e) {
      debugPrint('Failed to get reading insights: $e');
      return ReadingInsights.empty();
    }
  }

  /// Private helper methods

  int _calculateTotalVersesRead(Map<String, dynamic>? currentProgress, int latestVerse) {
    if (currentProgress == null) return latestVerse;

    final previousTotal = currentProgress['totalVersesRead'] as int? ?? 0;
    final lastVerse = currentProgress['lastVerseRead'] as int? ?? 0;

    if (latestVerse > lastVerse) {
      return previousTotal + (latestVerse - lastVerse);
    }

    return previousTotal;
  }

  double _calculateCompletionPercentage(int surahNumber, int currentVerse) {
    // Simplified calculation - in real app, use actual surah verse counts
    final surahVerseCounts = {
      1: 7, 2: 286, 3: 200, 4: 176, 5: 120, // Add all 114 surahs
      // ... complete mapping
    };

    final totalVerses = surahVerseCounts[surahNumber] ?? 100;
    return (currentVerse / totalVerses * 100).clamp(0.0, 100.0);
  }

  Future<void> _updateReadingStreak(DateTime readingDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streakJson = prefs.getString(_streakKey);

      ReadingStreak streak;
      if (streakJson != null) {
        streak = ReadingStreak.fromJson(jsonDecode(streakJson));
      } else {
        streak = ReadingStreak.empty();
      }

      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final readingDateOnly = DateTime(readingDate.year, readingDate.month, readingDate.day);
      final todayOnly = DateTime(today.year, today.month, today.day);
      final yesterdayOnly = DateTime(yesterday.year, yesterday.month, yesterday.day);

      if (readingDateOnly == todayOnly) {
        // Reading today
        if (streak.lastReadDate == null ||
            DateTime.parse(streak.lastReadDate!).isBefore(todayOnly)) {
          // First read of the day
          if (streak.lastReadDate != null &&
              DateTime.parse(streak.lastReadDate!) == yesterdayOnly) {
            // Continue streak
            streak = streak.copyWith(
              currentStreak: streak.currentStreak + 1,
              lastReadDate: todayOnly.toIso8601String(),
            );
          } else {
            // Start new streak
            streak = streak.copyWith(currentStreak: 1, lastReadDate: todayOnly.toIso8601String());
          }

          // Update longest streak
          if (streak.currentStreak > streak.longestStreak) {
            streak = streak.copyWith(longestStreak: streak.currentStreak);
          }
        }
      }

      await prefs.setString(_streakKey, jsonEncode(streak.toJson()));
    } catch (e) {
      debugPrint('Failed to update reading streak: $e');
    }
  }

  Future<void> _updateDailyStats(DateTime readingDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_statsKey);

      ReadingStats stats;
      if (statsJson != null) {
        stats = ReadingStats.fromJson(jsonDecode(statsJson));
      } else {
        stats = ReadingStats.empty();
      }

      final today = DateTime(readingDate.year, readingDate.month, readingDate.day);
      final todayKey = today.toIso8601String().split('T')[0];

      // Update daily reading count
      final dailyReading = Map<String, int>.from(stats.dailyReadingCount);
      dailyReading[todayKey] = (dailyReading[todayKey] ?? 0) + 1;

      // Update total verses read
      final updatedStats = stats.copyWith(
        totalVersesRead: stats.totalVersesRead + 1,
        dailyReadingCount: dailyReading,
      );

      await prefs.setString(_statsKey, jsonEncode(updatedStats.toJson()));
    } catch (e) {
      debugPrint('Failed to update daily stats: $e');
    }
  }

  Future<void> _saveReadingSession(ReadingSession session) async {
    try {
      final sessions = await _getAllReadingSessions();
      final index = sessions.indexWhere((s) => s.id == session.id);

      if (index >= 0) {
        sessions[index] = session;
      } else {
        sessions.add(session);
      }

      // Keep only last 100 sessions
      if (sessions.length > 100) {
        sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
        sessions.removeRange(100, sessions.length);
      }

      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = sessions.map((s) => s.toJson()).toList();
      await prefs.setString(_sessionsKey, jsonEncode(sessionsJson));
    } catch (e) {
      debugPrint('Failed to save reading session: $e');
    }
  }

  Future<ReadingSession?> _getReadingSession(String sessionId) async {
    try {
      final sessions = await _getAllReadingSessions();
      return sessions.firstWhere(
        (session) => session.id == sessionId,
        orElse: () => throw StateError('Session not found'),
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<ReadingSession>> _getAllReadingSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_sessionsKey);

      if (sessionsJson != null) {
        final sessionsList = jsonDecode(sessionsJson) as List;
        return sessionsList.map((json) => ReadingSession.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Failed to get reading sessions: $e');
    }

    return [];
  }

  Future<void> _updateSessionStats(ReadingSession session) async {
    if (session.endTime == null) return;

    try {
      final duration = session.endTime!.difference(session.startTime);
      final minutesRead = duration.inMinutes;

      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_statsKey);

      ReadingStats stats;
      if (statsJson != null) {
        stats = ReadingStats.fromJson(jsonDecode(statsJson));
      } else {
        stats = ReadingStats.empty();
      }

      final updatedStats = stats.copyWith(
        totalReadingTime: stats.totalReadingTime + minutesRead,
        totalSessions: stats.totalSessions + 1,
        averageSessionTime: _calculateAverageSessionTime(
          stats.totalReadingTime + minutesRead,
          stats.totalSessions + 1,
        ),
      );

      await prefs.setString(_statsKey, jsonEncode(updatedStats.toJson()));
    } catch (e) {
      debugPrint('Failed to update session stats: $e');
    }
  }

  double _calculateAverageSessionTime(int totalMinutes, int totalSessions) {
    return totalSessions > 0 ? totalMinutes / totalSessions : 0.0;
  }

  Future<ReadingStats> _calculateReadingStats() async {
    try {
      final progress = await getReadingProgress();
      final sessions = await _getAllReadingSessions();

      int totalVersesRead = 0;
      int totalReadingTime = 0;
      final Map<String, int> dailyReadingCount = {};

      // Calculate from progress
      for (final entry in progress.values) {
        if (entry is Map<String, dynamic>) {
          totalVersesRead += (entry['totalVersesRead'] as int?) ?? 0;
        }
      }

      // Calculate from sessions
      for (final session in sessions) {
        if (session.endTime != null) {
          final duration = session.endTime!.difference(session.startTime);
          totalReadingTime += duration.inMinutes;

          final dateKey = session.startTime.toIso8601String().split('T')[0];
          dailyReadingCount[dateKey] = (dailyReadingCount[dateKey] ?? 0) + 1;
        }
      }

      final stats = ReadingStats(
        totalVersesRead: totalVersesRead,
        totalReadingTime: totalReadingTime,
        totalSessions: sessions.length,
        averageSessionTime: _calculateAverageSessionTime(totalReadingTime, sessions.length),
        dailyReadingCount: dailyReadingCount,
      );

      // Cache the calculated stats
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statsKey, jsonEncode(stats.toJson()));

      return stats;
    } catch (e) {
      debugPrint('Failed to calculate reading stats: $e');
      return ReadingStats.empty();
    }
  }

  List<String> _generateRecommendations(
    ReadingStats stats,
    ReadingStreak streak,
    List<ReadingSession> recentSessions,
  ) {
    final recommendations = <String>[];

    // Streak recommendations
    if (streak.currentStreak == 0) {
      recommendations.add('Start your reading streak today! Even 5 minutes counts.');
    } else if (streak.currentStreak < 7) {
      recommendations.add('Keep building your streak! Aim for 7 days in a row.');
    } else {
      recommendations.add('Amazing ${streak.currentStreak}-day streak! Keep it up!');
    }

    // Session length recommendations
    if (stats.averageSessionTime < 10) {
      recommendations.add('Try reading for at least 10 minutes per session for better focus.');
    } else if (stats.averageSessionTime > 60) {
      recommendations.add('Great dedication! Consider taking breaks during long sessions.');
    }

    // Reading frequency recommendations
    final recentDays = recentSessions.length;
    if (recentDays < 7) {
      recommendations.add('Try to read daily to build a consistent habit.');
    }

    // Progress recommendations
    if (stats.totalVersesRead < 100) {
      recommendations.add('You\'re just getting started! Set small daily goals.');
    } else if (stats.totalVersesRead < 1000) {
      recommendations.add('Good progress! Consider exploring different surahs.');
    }

    return recommendations;
  }

  /// Clear all reading data
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
      await prefs.remove(_sessionsKey);
      await prefs.remove(_goalsKey);
      await prefs.remove(_streakKey);
      await prefs.remove(_statsKey);
    } catch (e) {
      debugPrint('Failed to clear reading data: $e');
    }
  }
}

// Data classes for reading tracking

class ReadingSession {
  final String id;
  final int surahNumber;
  final String surahName;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? lastActivity;
  final bool isActive;
  final int? lastVerseRead;
  final int? totalVersesRead;

  const ReadingSession({
    required this.id,
    required this.surahNumber,
    required this.surahName,
    required this.startTime,
    this.endTime,
    this.lastActivity,
    required this.isActive,
    this.lastVerseRead,
    this.totalVersesRead,
  });

  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      id: json['id'] as String,
      surahNumber: json['surahNumber'] as int,
      surahName: json['surahName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      lastActivity:
          json['lastActivity'] != null ? DateTime.parse(json['lastActivity'] as String) : null,
      isActive: json['isActive'] as bool,
      lastVerseRead: json['lastVerseRead'] as int?,
      totalVersesRead: json['totalVersesRead'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surahNumber': surahNumber,
      'surahName': surahName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'lastActivity': lastActivity?.toIso8601String(),
      'isActive': isActive,
      'lastVerseRead': lastVerseRead,
      'totalVersesRead': totalVersesRead,
    };
  }

  ReadingSession copyWith({
    String? id,
    int? surahNumber,
    String? surahName,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? lastActivity,
    bool? isActive,
    int? lastVerseRead,
    int? totalVersesRead,
  }) {
    return ReadingSession(
      id: id ?? this.id,
      surahNumber: surahNumber ?? this.surahNumber,
      surahName: surahName ?? this.surahName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      lastActivity: lastActivity ?? this.lastActivity,
      isActive: isActive ?? this.isActive,
      lastVerseRead: lastVerseRead ?? this.lastVerseRead,
      totalVersesRead: totalVersesRead ?? this.totalVersesRead,
    );
  }

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);
  String get formattedDuration {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class ReadingStats {
  final int totalVersesRead;
  final int totalReadingTime; // in minutes
  final int totalSessions;
  final double averageSessionTime;
  final Map<String, int> dailyReadingCount;

  const ReadingStats({
    required this.totalVersesRead,
    required this.totalReadingTime,
    required this.totalSessions,
    required this.averageSessionTime,
    required this.dailyReadingCount,
  });

  factory ReadingStats.empty() {
    return const ReadingStats(
      totalVersesRead: 0,
      totalReadingTime: 0,
      totalSessions: 0,
      averageSessionTime: 0.0,
      dailyReadingCount: {},
    );
  }

  factory ReadingStats.fromJson(Map<String, dynamic> json) {
    return ReadingStats(
      totalVersesRead: json['totalVersesRead'] as int,
      totalReadingTime: json['totalReadingTime'] as int,
      totalSessions: json['totalSessions'] as int,
      averageSessionTime: (json['averageSessionTime'] as num).toDouble(),
      dailyReadingCount: Map<String, int>.from(json['dailyReadingCount'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalVersesRead': totalVersesRead,
      'totalReadingTime': totalReadingTime,
      'totalSessions': totalSessions,
      'averageSessionTime': averageSessionTime,
      'dailyReadingCount': dailyReadingCount,
    };
  }

  ReadingStats copyWith({
    int? totalVersesRead,
    int? totalReadingTime,
    int? totalSessions,
    double? averageSessionTime,
    Map<String, int>? dailyReadingCount,
  }) {
    return ReadingStats(
      totalVersesRead: totalVersesRead ?? this.totalVersesRead,
      totalReadingTime: totalReadingTime ?? this.totalReadingTime,
      totalSessions: totalSessions ?? this.totalSessions,
      averageSessionTime: averageSessionTime ?? this.averageSessionTime,
      dailyReadingCount: dailyReadingCount ?? this.dailyReadingCount,
    );
  }

  String get formattedReadingTime {
    final hours = totalReadingTime ~/ 60;
    final minutes = totalReadingTime % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class ReadingGoal {
  final GoalType type;
  final int targetValue;
  final int currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;

  const ReadingGoal({
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.startDate,
    required this.endDate,
    required this.isCompleted,
  });

  factory ReadingGoal.fromJson(Map<String, dynamic> json) {
    return ReadingGoal(
      type: GoalType.values.firstWhere((e) => e.name == json['type']),
      targetValue: json['targetValue'] as int,
      currentValue: json['currentValue'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isCompleted: json['isCompleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  double get progressPercentage =>
      targetValue > 0 ? (currentValue / targetValue * 100).clamp(0.0, 100.0) : 0.0;
  bool get isActive => DateTime.now().isBefore(endDate) && !isCompleted;
}

enum GoalType {
  dailyVerses('Daily Verses'),
  weeklyMinutes('Weekly Minutes'),
  monthlyCompletion('Monthly Completion'),
  yearlyGoal('Yearly Goal');

  const GoalType(this.displayName);
  final String displayName;
}

class ReadingStreak {
  final int currentStreak;
  final int longestStreak;
  final String? lastReadDate;

  const ReadingStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastReadDate,
  });

  factory ReadingStreak.empty() {
    return const ReadingStreak(currentStreak: 0, longestStreak: 0, lastReadDate: null);
  }

  factory ReadingStreak.fromJson(Map<String, dynamic> json) {
    return ReadingStreak(
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      lastReadDate: json['lastReadDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastReadDate': lastReadDate,
    };
  }

  ReadingStreak copyWith({int? currentStreak, int? longestStreak, String? lastReadDate}) {
    return ReadingStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastReadDate: lastReadDate ?? this.lastReadDate,
    );
  }
}

class ReadingInsights {
  final ReadingStats stats;
  final ReadingStreak streak;
  final ReadingGoal? goal;
  final List<ReadingSession> recentSessions;
  final List<String> recommendations;

  const ReadingInsights({
    required this.stats,
    required this.streak,
    this.goal,
    required this.recentSessions,
    required this.recommendations,
  });

  factory ReadingInsights.empty() {
    return ReadingInsights(
      stats: ReadingStats.empty(),
      streak: ReadingStreak.empty(),
      goal: null,
      recentSessions: const [],
      recommendations: const [],
    );
  }
}
