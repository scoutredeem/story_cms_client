import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:story_cms_client/models/locale_item_model.dart';
import 'package:story_cms_client/services/client_store_service.dart';

void main() {
  late Box box;
  late ClientStoreService service;

  setUp(() async {
    box = await Hive.openBox('client_store_service_test', path: './test');
    await box.clear();
    service = ClientStoreService(box);
  });

  tearDown(() async {
    await box.close();
  });

  group('strings cache', () {
    test('returns empty map when nothing cached', () {
      expect(service.strings, <String, String>{});
    });

    test('saves and reloads the override map', () async {
      await service.saveStrings({'welcomeMessage': 'Hi there'});

      expect(service.strings, {'welcomeMessage': 'Hi there'});
    });
  });

  group('locales cache', () {
    test('returns empty list when nothing cached', () {
      expect(service.locales, <LocaleItem>[]);
    });

    test('saves and reloads the locale catalog', () async {
      final locales = [
        LocaleItem(
          locale: 'en',
          name: 'English',
          nativeName: 'English',
          languageDirection: LanguageDirection.ltr,
        ),
      ];

      await service.saveLocales(locales);

      expect(service.locales, locales);
    });
  });
}
