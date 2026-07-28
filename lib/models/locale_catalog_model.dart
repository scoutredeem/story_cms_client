// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'app_locale_model.dart';
import 'content_locale_model.dart';

export 'app_locale_model.dart';
export 'content_locale_model.dart';

/// The full `GET /locale` response: [app] (picker metadata) and [content]
/// (which story slugs are published per locale) are independent arrays -
/// this wrapper mirrors that shape 1:1 rather than joining them, so callers
/// search whichever list they actually care about (see
/// `LocaleCatalogManager.catalog`).
class LocaleCatalog {
  final List<AppLocale> app;
  final List<ContentLocale> content;

  LocaleCatalog({required this.app, required this.content});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'app': app.map((e) => e.toMap()).toList(),
      'content': content.map((e) => e.toMap()).toList(),
    };
  }

  factory LocaleCatalog.fromMap(Map<String, dynamic> map) {
    return LocaleCatalog(
      app: (map['app'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(AppLocale.fromMap)
          .toList(),
      content: (map['content'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ContentLocale.fromMap)
          .toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory LocaleCatalog.fromJson(String source) =>
      LocaleCatalog.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'LocaleCatalog(app: $app, content: $content)';

  @override
  bool operator ==(covariant LocaleCatalog other) {
    if (identical(this, other)) return true;

    if (other.app.length != app.length) return false;
    if (other.content.length != content.length) return false;
    for (var i = 0; i < app.length; i++) {
      if (other.app[i] != app[i]) return false;
    }
    for (var i = 0; i < content.length; i++) {
      if (other.content[i] != content[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(app) ^ Object.hashAll(content);
}
