import 'package:flutter_test/flutter_test.dart';
import 'package:story_cms_client/models/locale_catalog_model.dart';

void main() {
  group('LocaleCatalog', () {
    test('fromMap parses app and content independently', () {
      final item = LocaleCatalog.fromMap({
        'app': [
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
      });

      expect(item.app, [
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
    });

    test('missing app/content keys parse as empty lists', () {
      final item = LocaleCatalog.fromMap({});

      expect(item.app, <AppLocale>[]);
      expect(item.content, <ContentLocale>[]);
    });

    test('toJson/fromJson round-trips both lists, including when empty', () {
      final item = LocaleCatalog(
        app: [
          AppLocale(
            locale: 'en',
            name: 'English',
            nativeName: 'English',
            languageDirection: LanguageDirection.ltr,
          ),
        ],
        content: [],
      );

      final restored = LocaleCatalog.fromJson(item.toJson());

      expect(restored, item);
      expect(restored.content, <ContentLocale>[]);
    });
  });
}
