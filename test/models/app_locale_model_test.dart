import 'package:flutter_test/flutter_test.dart';
import 'package:story_cms_client/models/app_locale_model.dart';

void main() {
  group('AppLocale', () {
    test('fromMap parses languageDirection', () {
      final item = AppLocale.fromMap({
        'locale': 'ar',
        'name': 'Arabic',
        'nativeName': 'العربية',
        'languageDirection': 'rtl',
      });

      expect(item.locale, 'ar');
      expect(item.name, 'Arabic');
      expect(item.nativeName, 'العربية');
      expect(item.languageDirection, LanguageDirection.rtl);
    });

    test('toJson/fromJson round-trips', () {
      final item = AppLocale(
        locale: 'en',
        name: 'English',
        nativeName: 'English',
        languageDirection: LanguageDirection.ltr,
      );

      final restored = AppLocale.fromJson(item.toJson());

      expect(restored, item);
    });

    test('unknown languageDirection falls back to ltr', () {
      final item = AppLocale.fromMap({
        'locale': 'en',
        'name': 'English',
        'nativeName': 'English',
        'languageDirection': 'sideways',
      });

      expect(item.languageDirection, LanguageDirection.ltr);
    });
  });
}
