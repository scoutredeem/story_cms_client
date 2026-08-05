import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:story_cms_client/models/locale_catalog_model.dart';
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
    test('returns null when nothing cached', () {
      expect(service.cachedStrings, isNull);
    });

    test('saves and reloads the override map tagged with its locale', () async {
      await service.saveStrings('fr', {'welcomeMessage': 'Bonjour'});

      final cached = service.cachedStrings;
      expect(cached?.locale, 'fr');
      expect(cached?.overrides, {'welcomeMessage': 'Bonjour'});
    });
  });

  group('locale catalog cache', () {
    test('returns null when nothing cached', () {
      expect(service.localeCatalog, isNull);
    });

    test('saves and reloads the locale catalog', () async {
      final catalog = LocaleCatalog(
        languages: [
          AppLocale(
            locale: 'en',
            name: 'English',
            nativeName: 'English',
            languageDirection: LanguageDirection.ltr,
          ),
        ],
        content: [
          ContentLocale(locale: 'en', stories: ['classic']),
        ],
        app: ['en'],
        media: ['en'],
      );

      await service.saveLocaleCatalog(catalog);

      expect(service.localeCatalog, catalog);
    });
  });
}
