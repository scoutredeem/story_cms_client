import 'package:flutter_test/flutter_test.dart';
import 'package:story_cms_client/models/content_locale_model.dart';

void main() {
  group('ContentLocale', () {
    test('fromMap parses stories', () {
      final item = ContentLocale.fromMap({
        'locale': 'de',
        'stories': ['classic', 'express'],
      });

      expect(item.locale, 'de');
      expect(item.stories, ['classic', 'express']);
    });

    test('missing stories parses as empty list', () {
      final item = ContentLocale.fromMap({'locale': 'de'});

      expect(item.stories, <String>[]);
    });

    test('toJson/fromJson round-trips', () {
      final item = ContentLocale(locale: 'en', stories: ['classic', 'youth']);

      final restored = ContentLocale.fromJson(item.toJson());

      expect(restored, item);
    });
  });
}
