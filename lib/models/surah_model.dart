class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishTranslation;
  final String revelationType;
  final int numberOfAyahs;
  final List<Verse>? verses;

  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
    this.verses,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] ?? 0,
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      englishTranslation: json['englishTranslation'] ?? '',
      revelationType: json['revelationType'] ?? '',
      numberOfAyahs: json['numberOfAyahs'] ?? 0,
      verses:
          json['ayahs'] != null
              ? (json['ayahs'] as List).map((v) => Verse.fromJson(v)).toList()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
      'englishName': englishName,
      'englishTranslation': englishTranslation,
      'revelationType': revelationType,
      'numberOfAyahs': numberOfAyahs,
      'ayahs': verses?.map((v) => v.toJson()).toList(),
    };
  }
}

class Verse {
  final int number;
  final String text;
  final String? translation;
  final int numberInSurah;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;
  final bool sajda;

  Verse({
    required this.number,
    required this.text,
    this.translation,
    required this.numberInSurah,
    required this.juz,
    required this.manzil,
    required this.page,
    required this.ruku,
    required this.hizbQuarter,
    required this.sajda,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    // Handle sajda field which can be either bool or Map
    bool sajdaValue = false;
    final sajdaField = json['sajda'];
    if (sajdaField is bool) {
      sajdaValue = sajdaField;
    } else if (sajdaField is Map<String, dynamic>) {
      // If it's a Map, check for common keys that indicate prostration
      sajdaValue =
          sajdaField['obligatory'] == true ||
          sajdaField['recommended'] == true ||
          sajdaField.isNotEmpty; // If the map has any content, it likely indicates sajda
    }

    return Verse(
      number: json['number'] ?? 0,
      text: json['text'] ?? '',
      translation: json['translation'],
      numberInSurah: json['numberInSurah'] ?? 0,
      juz: json['juz'] ?? 0,
      manzil: json['manzil'] ?? 0,
      page: json['page'] ?? 0,
      ruku: json['ruku'] ?? 0,
      hizbQuarter: json['hizbQuarter'] ?? 0,
      sajda: sajdaValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'text': text,
      'translation': translation,
      'numberInSurah': numberInSurah,
      'juz': juz,
      'manzil': manzil,
      'page': page,
      'ruku': ruku,
      'hizbQuarter': hizbQuarter,
      'sajda': sajda,
    };
  }
}
