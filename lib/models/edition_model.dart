class Edition {
  final String identifier;
  final String language;
  final String name;
  final String englishName;
  final String format;
  final String type;
  final String direction;

  Edition({
    required this.identifier,
    required this.language,
    required this.name,
    required this.englishName,
    required this.format,
    required this.type,
    required this.direction,
  });

  factory Edition.fromJson(Map<String, dynamic> json) {
    return Edition(
      identifier: json['identifier'] ?? '',
      language: json['language'] ?? '',
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      format: json['format'] ?? '',
      type: json['type'] ?? '',
      direction: json['direction'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'language': language,
      'name': name,
      'englishName': englishName,
      'format': format,
      'type': type,
      'direction': direction,
    };
  }

  bool get isAudio => format == 'audio';
  bool get isText => format == 'text';
  bool get isTranslation => type == 'translation';
  bool get isTafsir => type == 'tafsir';
}

class ApiResponse<T> {
  final int code;
  final String status;
  final T data;

  ApiResponse({required this.code, required this.status, required this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return ApiResponse(
      code: json['code'] ?? 0,
      status: json['status'] ?? '',
      data: fromJsonT(json['data']),
    );
  }

  bool get isSuccess => code == 200;
}
