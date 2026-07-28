import 'package:flutter_test/flutter_test.dart';
import 'package:story_cms_client/models/locale_item_model.dart';

void main() {
  group('LocaleItem', () {
    test('fromMap parses app and content independently', () {
      final item = LocaleItem.fromMap({
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
      final item = LocaleItem.fromMap({});

      expect(item.app, <AppLocale>[]);
      expect(item.content, <ContentLocale>[]);
    });

    test('toJson/fromJson round-trips both lists, including when empty', () {
      final item = LocaleItem(
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

      final restored = LocaleItem.fromJson(item.toJson());

      expect(restored, item);
      expect(restored.content, <ContentLocale>[]);
    });
  });
}
