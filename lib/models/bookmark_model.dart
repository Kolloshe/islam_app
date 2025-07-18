class Bookmark {
  final String id;
  final int surahNumber;
  final int verseNumber;
  final String surahName;
  final String verseText;
  final String? translation;
  final String? note;
  final DateTime createdAt;
  final List<String> tags;
  final BookmarkType type;

  const Bookmark({
    required this.id,
    required this.surahNumber,
    required this.verseNumber,
    required this.surahName,
    required this.verseText,
    this.translation,
    this.note,
    required this.createdAt,
    this.tags = const [],
    this.type = BookmarkType.verse,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      surahNumber: json['surahNumber'] as int,
      verseNumber: json['verseNumber'] as int,
      surahName: json['surahName'] as String,
      verseText: json['verseText'] as String,
      translation: json['translation'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      tags: List<String>.from(json['tags'] as List? ?? []),
      type: BookmarkType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BookmarkType.verse,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surahNumber': surahNumber,
      'verseNumber': verseNumber,
      'surahName': surahName,
      'verseText': verseText,
      'translation': translation,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'type': type.name,
    };
  }

  Bookmark copyWith({
    String? id,
    int? surahNumber,
    int? verseNumber,
    String? surahName,
    String? verseText,
    String? translation,
    String? note,
    DateTime? createdAt,
    List<String>? tags,
    BookmarkType? type,
  }) {
    return Bookmark(
      id: id ?? this.id,
      surahNumber: surahNumber ?? this.surahNumber,
      verseNumber: verseNumber ?? this.verseNumber,
      surahName: surahName ?? this.surahName,
      verseText: verseText ?? this.verseText,
      translation: translation ?? this.translation,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      type: type ?? this.type,
    );
  }

  String get reference => '$surahName $surahNumber:$verseNumber';

  bool get hasNote => note != null && note!.isNotEmpty;
  bool get hasTags => tags.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bookmark &&
        other.id == id &&
        other.surahNumber == surahNumber &&
        other.verseNumber == verseNumber;
  }

  @override
  int get hashCode => Object.hash(id, surahNumber, verseNumber);

  @override
  String toString() => 'Bookmark(id: $id, reference: $reference)';
}

enum BookmarkType {
  verse('Verse'),
  lastRead('Last Read Position'),
  favorite('Favorite');

  const BookmarkType(this.displayName);
  final String displayName;
}

class ReadingPosition {
  final int surahNumber;
  final int verseNumber;
  final String surahName;
  final DateTime lastReadAt;
  final int totalVersesRead;
  final double progressPercentage;

  const ReadingPosition({
    required this.surahNumber,
    required this.verseNumber,
    required this.surahName,
    required this.lastReadAt,
    required this.totalVersesRead,
    required this.progressPercentage,
  });

  factory ReadingPosition.fromJson(Map<String, dynamic> json) {
    return ReadingPosition(
      surahNumber: json['surahNumber'] as int,
      verseNumber: json['verseNumber'] as int,
      surahName: json['surahName'] as String,
      lastReadAt: DateTime.parse(json['lastReadAt'] as String),
      totalVersesRead: json['totalVersesRead'] as int,
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'verseNumber': verseNumber,
      'surahName': surahName,
      'lastReadAt': lastReadAt.toIso8601String(),
      'totalVersesRead': totalVersesRead,
      'progressPercentage': progressPercentage,
    };
  }

  String get reference => '$surahName $surahNumber:$verseNumber';
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(lastReadAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String getLocalizedTimeAgo(dynamic l10n) {
    final now = DateTime.now();
    final difference = now.difference(lastReadAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays > 1 ? l10n.daysAgo : l10n.dayAgo}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours > 1 ? l10n.hoursAgo : l10n.hourAgo}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes > 1 ? l10n.minutesAgo : l10n.minuteAgo}';
    } else {
      return l10n.justNow;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingPosition &&
        other.surahNumber == surahNumber &&
        other.verseNumber == verseNumber;
  }

  @override
  int get hashCode => Object.hash(surahNumber, verseNumber);
}
