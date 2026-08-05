import 'package:flutter_test/flutter_test.dart';
import 'package:story_cms_client/models/locale_catalog_model.dart';

void main() {
  group('LocaleCatalog', () {
    test('fromMap parses languages, content, app and media independently', () {
      final item = LocaleCatalog.fromMap({
        'languages': [
          {
            'locale': 'en',
            'name': 'English',
            'nativeName': 'English',
            'languageDirection': 'ltr',
          },
        ],
        'content': [
          {
            'locale': 'de',
            'stories': ['classic'],
          },
        ],
        'app': ['en'],
        'media': ['en'],
      });

      expect(item.languages, [
        AppLocale(
          locale: 'en',
          name: 'English',
          nativeName: 'English',
          languageDirection: LanguageDirection.ltr,
        ),
      ]);
      expect(item.content, [
        ContentLocale(locale: 'de', stories: ['classic']),
      ]);
      expect(item.app, ['en']);
      expect(item.media, ['en']);
    });

    test('missing keys parse as empty lists', () {
      final item = LocaleCatalog.fromMap({});

      expect(item.languages, <AppLocale>[]);
      expect(item.content, <ContentLocale>[]);
      expect(item.app, <String>[]);
      expect(item.media, <String>[]);
    });

    test('toJson/fromJson round-trips all lists, including when empty', () {
      final item = LocaleCatalog(
        languages: [
          AppLocale(
            locale: 'en',
            name: 'English',
            nativeName: 'English',
            languageDirection: LanguageDirection.ltr,
          ),
        ],
        content: [],
        app: ['en'],
        media: [],
      );

      final restored = LocaleCatalog.fromJson(item.toJson());

      expect(restored, item);
      expect(restored.content, <ContentLocale>[]);
      expect(restored.media, <String>[]);
    });
  });
}
