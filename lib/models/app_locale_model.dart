// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

enum LanguageDirection {
  ltr,
  rtl;

  static LanguageDirection fromString(String value) {
    return LanguageDirection.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LanguageDirection.ltr,
    );
  }
}

/// A locale from `GET /locale`'s `app` array - the picker metadata (code,
/// display names, direction), independent of which locales have published
/// story content (see [ContentLocale] for that).
class AppLocale {
  final String locale;
  final String name;
  final String nativeName;
  final LanguageDirection languageDirection;

  AppLocale({
    required this.locale,
    required this.name,
    required this.nativeName,
    required this.languageDirection,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'locale': locale,
      'name': name,
      'nativeName': nativeName,
      'languageDirection': languageDirection.name,
    };
  }

  factory AppLocale.fromMap(Map<String, dynamic> map) {
    return AppLocale(
      locale: map['locale'] as String,
      name: (map['name'] ?? '') as String,
      nativeName: (map['nativeName'] ?? '') as String,
      languageDirection: LanguageDirection.fromString(
        (map['languageDirection'] ?? '') as String,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory AppLocale.fromJson(String source) =>
      AppLocale.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AppLocale(locale: $locale, name: $name, nativeName: $nativeName, '
        'languageDirection: $languageDirection)';
  }

  @override
  bool operator ==(covariant AppLocale other) {
    if (identical(this, other)) return true;

    return other.locale == locale &&
        other.name == name &&
        other.nativeName == nativeName &&
        other.languageDirection == languageDirection;
  }

  @override
  int get hashCode {
    return locale.hashCode ^
        name.hashCode ^
        nativeName.hashCode ^
        languageDirection.hashCode;
  }
}
