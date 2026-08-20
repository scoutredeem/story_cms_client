import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:story_cms_client/client.dart';
import 'package:story_cms_client/features/locale/locale_catalog_manager.dart';
import 'package:story_cms_client/models/locale_catalog_model.dart';
import 'package:story_cms_client/models/page_model.dart';
import 'package:story_cms_client/services/client_store_service.dart';

class _FakeCMSClient implements CMSClient {
  LocaleCatalog catalogToReturn = LocaleCatalog(
    languages: [],
    content: [],
    app: [],
    media: [],
  );
  Object? errorToThrow;

  @override
  Future<LocaleCatalog> getLocales() async {
    if (errorToThrow != null) throw errorToThrow!;
    return catalogToReturn;
  }

  @override
  Future<Map<String, String>> getStrings({required String locale}) async => {};

  @override
  Future<List<PageModel>> getPages(
    Map<String, String>? queryParameters,
  ) async => [];
}

final _en = AppLocale(
  locale: 'en',
  name: 'English',
  nativeName: 'English',
  languageDirection: LanguageDirection.ltr,
);
final _ku = AppLocale(
  locale: 'ku',
  name: 'Kurdish',
  nativeName: 'Kurdî',
  languageDirection: LanguageDirection.ltr,
);
final _ar = AppLocale(
  locale: 'ar',
  name: 'Arabic',
  nativeName: 'العربية',
  languageDirection: LanguageDirection.rtl,
);

void main() {
  late Box box;
  late ClientStoreService storeService;
  late _FakeCMSClient client;
  late LocaleCatalogManager manager;

  setUp(() async {
    box = await Hive.openBox('locale_catalog_manager_test', path: './test');
    await box.clear();
    storeService = ClientStoreService(box);
    client = _FakeCMSClient();
    manager = LocaleCatalogManager();
  });

  tearDown(() async {
    await box.close();
  });

  test(
    'loads cached catalog immediately, then overwrites on fetch success',
    () async {
      await storeService.saveLocaleCatalog(
        LocaleCatalog(languages: [_en], content: [], app: ['en'], media: []),
      );
      client.catalogToReturn = LocaleCatalog(
        languages: [_en, _ku],
        content: [],
        app: ['en', 'ku'],
        media: [],
      );

      await manager.init(client: client, storeService: storeService);

      expect(
        manager.catalog,
        LocaleCatalog(
          languages: [_en, _ku],
          content: [],
          app: ['en', 'ku'],
          media: [],
        ),
      );
      expect(
        storeService.localeCatalog,
        LocaleCatalog(
          languages: [_en, _ku],
          content: [],
          app: ['en', 'ku'],
          media: [],
        ),
      );
    },
  );

  test(
    'keeps the last cache and does not throw when the fetch fails',
    () async {
      await storeService.saveLocaleCatalog(
        LocaleCatalog(languages: [_en], content: [], app: ['en'], media: []),
      );
      client.errorToThrow = Exception('network down');

      await manager.init(client: client, storeService: storeService);

      expect(
        manager.catalog,
        LocaleCatalog(languages: [_en], content: [], app: ['en'], media: []),
      );
    },
  );

  group('directionFor', () {
    test('returns ltr before the catalog has loaded', () {
      expect(manager.directionFor('ar'), TextDirection.ltr);
    });

    test('returns rtl for a locale tagged rtl in the catalog', () async {
      client.catalogToReturn = LocaleCatalog(
        languages: [_en, _ar],
        content: [],
        app: ['en', 'ar'],
        media: [],
      );
      await manager.init(client: client, storeService: null);

      expect(manager.directionFor('ar'), TextDirection.rtl);
    });

    test('returns ltr for a locale tagged ltr in the catalog', () async {
      client.catalogToReturn = LocaleCatalog(
        languages: [_en, _ar],
        content: [],
        app: ['en', 'ar'],
        media: [],
      );
      await manager.init(client: client, storeService: null);

      expect(manager.directionFor('en'), TextDirection.ltr);
    });

    test('returns ltr for a locale absent from the catalog', () async {
      client.catalogToReturn = LocaleCatalog(
        languages: [_en, _ar],
        content: [],
        app: ['en', 'ar'],
        media: [],
      );
      await manager.init(client: client, storeService: null);

      expect(manager.directionFor('xx'), TextDirection.ltr);
    });
  });
}
