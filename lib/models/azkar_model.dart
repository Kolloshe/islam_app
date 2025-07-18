class AzkarCategory {
  final String id;
  final String name;
  final String nameArabic;
  final String description;
  final String icon;
  final int totalAzkar;
  final String time; // morning, evening, post_prayer, general, etc.
  final List<Azkar> azkarList;

  AzkarCategory({
    required this.id,
    required this.name,
    required this.nameArabic,
    required this.description,
    required this.icon,
    required this.totalAzkar,
    required this.time,
    required this.azkarList,
  });

  factory AzkarCategory.fromJson(Map<String, dynamic> json) {
    return AzkarCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameArabic: json['nameArabic'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      totalAzkar: json['totalAzkar'] ?? 0,
      time: json['time'] ?? '',
      azkarList:
          (json['azkarList'] as List<dynamic>?)?.map((item) => Azkar.fromJson(item)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameArabic': nameArabic,
      'description': description,
      'icon': icon,
      'totalAzkar': totalAzkar,
      'time': time,
      'azkarList': azkarList.map((azkar) => azkar.toJson()).toList(),
    };
  }
}

class Azkar {
  final String id;
  final String text;
  final String textArabic;
  final String transliteration;
  final String translation;
  final String benefits;
  final String source;
  final int count;
  final int currentCount;
  final bool isCompleted;
  final String categoryId;

  Azkar({
    required this.id,
    required this.text,
    required this.textArabic,
    required this.transliteration,
    required this.translation,
    required this.benefits,
    required this.source,
    required this.count,
    this.currentCount = 0,
    this.isCompleted = false,
    required this.categoryId,
  });

  factory Azkar.fromJson(Map<String, dynamic> json) {
    return Azkar(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      textArabic: json['textArabic'] ?? '',
      transliteration: json['transliteration'] ?? '',
      translation: json['translation'] ?? '',
      benefits: json['benefits'] ?? '',
      source: json['source'] ?? '',
      count: json['count'] ?? 1,
      currentCount: json['currentCount'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      categoryId: json['categoryId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'textArabic': textArabic,
      'transliteration': transliteration,
      'translation': translation,
      'benefits': benefits,
      'source': source,
      'count': count,
      'currentCount': currentCount,
      'isCompleted': isCompleted,
      'categoryId': categoryId,
    };
  }

  Azkar copyWith({
    String? id,
    String? text,
    String? textArabic,
    String? transliteration,
    String? translation,
    String? benefits,
    String? source,
    int? count,
    int? currentCount,
    bool? isCompleted,
    String? categoryId,
  }) {
    return Azkar(
      id: id ?? this.id,
      text: text ?? this.text,
      textArabic: textArabic ?? this.textArabic,
      transliteration: transliteration ?? this.transliteration,
      translation: translation ?? this.translation,
      benefits: benefits ?? this.benefits,
      source: source ?? this.source,
      count: count ?? this.count,
      currentCount: currentCount ?? this.currentCount,
      isCompleted: isCompleted ?? this.isCompleted,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  double get progress => count > 0 ? currentCount / count : 0.0;
}
