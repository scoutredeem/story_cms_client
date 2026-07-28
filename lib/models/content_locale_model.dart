// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

/// A locale from `GET /locale`'s `content` array - which story slugs (e.g.
/// `"classic"`, `"express"`, `"youth"`) the CMS has actually published for
/// [locale]. Slugs are passed through as-is; this package doesn't know or
/// validate against the host app's own set of stories.
class ContentLocale {
  final String locale;
  final List<String> stories;

  ContentLocale({required this.locale, required this.stories});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'locale': locale, 'stories': stories};
  }

  factory ContentLocale.fromMap(Map<String, dynamic> map) {
    return ContentLocale(
      locale: map['locale'] as String,
      stories: (map['stories'] as List<dynamic>? ?? []).cast<String>().toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ContentLocale.fromJson(String source) =>
      ContentLocale.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'ContentLocale(locale: $locale, stories: $stories)';

  @override
  bool operator ==(covariant ContentLocale other) {
    if (identical(this, other)) return true;

    if (other.locale != locale) return false;
    if (other.stories.length != stories.length) return false;
    for (var i = 0; i < stories.length; i++) {
      if (other.stories[i] != stories[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => locale.hashCode ^ Object.hashAll(stories);
}
