import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:story_cms_client/client.dart';
import 'package:story_cms_client/features/locale/locale_catalog_manager.dart';
import 'package:story_cms_client/models/locale_catalog_model.dart';
import 'package:story_cms_client/models/page_model.dart';
import 'package:story_cms_client/services/client_store_service.dart';

class _FakeCMSClient implements CMSClient {
  LocaleCatalog catalogToReturn = LocaleCatalog(app: [], content: []);
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
        LocaleCatalog(app: [_en], content: []),
      );
      client.catalogToReturn = LocaleCatalog(app: [_en, _ku], content: []);

      await manager.init(client: client, storeService: storeService);

      expect(manager.catalog, LocaleCatalog(app: [_en, _ku], content: []));
      expect(
        storeService.localeCatalog,
        LocaleCatalog(app: [_en, _ku], content: []),
      );
    },
  );

  test(
    'keeps the last cache and does not throw when the fetch fails',
    () async {
      await storeService.saveLocaleCatalog(
        LocaleCatalog(app: [_en], content: []),
      );
      client.errorToThrow = Exception('network down');

      await manager.init(client: client, storeService: storeService);

      expect(manager.catalog, LocaleCatalog(app: [_en], content: []));
    },
  );
}
