class Reciter {
  final int id;
  final String name;
  final String letter;
  final List<Moshaf> moshaf;

  Reciter({required this.id, required this.name, required this.letter, required this.moshaf});

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      letter: json['letter'] ?? '',
      moshaf:
          json['moshaf'] != null
              ? (json['moshaf'] as List).map((m) => Moshaf.fromJson(m)).toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'letter': letter,
      'moshaf': moshaf.map((m) => m.toJson()).toList(),
    };
  }
}

class Moshaf {
  final int id;
  final String name;
  final String server;
  final int surahTotal;
  final int moshafType;
  final String surahList;

  Moshaf({
    required this.id,
    required this.name,
    required this.server,
    required this.surahTotal,
    required this.moshafType,
    required this.surahList,
  });

  factory Moshaf.fromJson(Map<String, dynamic> json) {
    return Moshaf(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      server: json['server'] ?? '',
      surahTotal: json['surah_total'] ?? 0,
      moshafType: json['moshaf_type'] ?? 0,
      surahList: json['surah_list'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'server': server,
      'surah_total': surahTotal,
      'moshaf_type': moshafType,
      'surah_list': surahList,
    };
  }

  List<int> get availableSurahs {
    return surahList.split(',').map((s) => int.tryParse(s.trim()) ?? 0).toList();
  }

  String getAudioUrl(int surahNumber) {
    String formattedNumber = surahNumber.toString().padLeft(3, '0');
    return '$server$formattedNumber.mp3';
  }
}
