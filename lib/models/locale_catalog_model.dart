// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'app_locale_model.dart';
import 'content_locale_model.dart';

export 'app_locale_model.dart';
export 'content_locale_model.dart';

/// The full `GET /locale` response. [languages] is metadata-only (name,
/// nativeName, direction) for every locale the CMS is configured with - it's
/// a lookup table, not an iteration source. [content], [app] and [media] are
/// the actual dynamic lists: which locales currently qualify for content,
/// app-UI (>80% translated, excluding AI-prefilled), and media respectively.
/// A locale can appear in [languages] without appearing in any of the three.
class LocaleCatalog {
  final List<AppLocale> languages;
  final List<ContentLocale> content;
  final List<String> app;
  final List<String> media;

  LocaleCatalog({
    required this.languages,
    required this.content,
    required this.app,
    required this.media,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'languages': languages.map((e) => e.toMap()).toList(),
      'content': content.map((e) => e.toMap()).toList(),
      'app': app,
      'media': media,
    };
  }

  factory LocaleCatalog.fromMap(Map<String, dynamic> map) {
    return LocaleCatalog(
      languages: (map['languages'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(AppLocale.fromMap)
          .toList(),
      content: (map['content'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ContentLocale.fromMap)
          .toList(),
      app: (map['app'] as List<dynamic>? ?? []).cast<String>().toList(),
      media: (map['media'] as List<dynamic>? ?? []).cast<String>().toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory LocaleCatalog.fromJson(String source) =>
      LocaleCatalog.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'LocaleCatalog(languages: $languages, content: $content, app: $app, media: $media)';

  @override
  bool operator ==(covariant LocaleCatalog other) {
    if (identical(this, other)) return true;

    if (other.languages.length != languages.length) return false;
    if (other.content.length != content.length) return false;
    if (other.app.length != app.length) return false;
    if (other.media.length != media.length) return false;
    for (var i = 0; i < languages.length; i++) {
      if (other.languages[i] != languages[i]) return false;
    }
    for (var i = 0; i < content.length; i++) {
      if (other.content[i] != content[i]) return false;
    }
    for (var i = 0; i < app.length; i++) {
      if (other.app[i] != app[i]) return false;
    }
    for (var i = 0; i < media.length; i++) {
      if (other.media[i] != media[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll(languages) ^
      Object.hashAll(content) ^
      Object.hashAll(app) ^
      Object.hashAll(media);
}
