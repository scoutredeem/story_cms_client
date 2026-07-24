import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:story_cms_client/client.dart';
import 'package:story_cms_client/features/locale/locale_catalog_manager.dart';
import 'package:story_cms_client/models/locale_item_model.dart';
import 'package:story_cms_client/models/page_model.dart';
import 'package:story_cms_client/services/client_store_service.dart';

class _FakeCMSClient implements CMSClient {
  List<LocaleItem> localesToReturn = [];
  Object? errorToThrow;

  @override
  Future<List<LocaleItem>> getLocales() async {
    if (errorToThrow != null) throw errorToThrow!;
    return localesToReturn;
  }

  @override
  Future<Map<String, String>> getStrings({required String locale}) async => {};

  @override
  Future<List<PageModel>> getPages(
    Map<String, String>? queryParameters,
  ) async => [];
}

final _en = LocaleItem(
  locale: 'en',
  name: 'English',
  nativeName: 'English',
  languageDirection: LanguageDirection.ltr,
);
final _ku = LocaleItem(
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
      await storeService.saveLocales([_en]);
      client.localesToReturn = [_en, _ku];

      await manager.init(
        client: client,
        storeService: storeService,
        bundledLocales: {'en'},
      );

      expect(manager.locales, [_en, _ku]);
      expect(storeService.locales, [_en, _ku]);
    },
  );

  test(
    'keeps the last cache and does not throw when the fetch fails',
    () async {
      await storeService.saveLocales([_en]);
      client.errorToThrow = Exception('network down');

      await manager.init(
        client: client,
        storeService: storeService,
        bundledLocales: {'en'},
      );

      expect(manager.locales, [_en]);
    },
  );

  test(
    'isBundled reflects the bundledLocales passed to init, not the fetched catalog',
    () async {
      client.localesToReturn = [_en, _ku];

      await manager.init(
        client: client,
        storeService: storeService,
        bundledLocales: {'en'},
      );

      expect(manager.isBundled('en'), isTrue);
      // ku is in the CMS catalog but the app has no bundled ARB for it.
      expect(manager.isBundled('ku'), isFalse);
      expect(manager.isBundled('never-heard-of-it'), isFalse);
    },
  );
}
