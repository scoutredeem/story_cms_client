import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:story_cms_client/client.dart';
import 'package:story_cms_client/features/strings/strings_manager.dart';
import 'package:story_cms_client/models/locale_item_model.dart';
import 'package:story_cms_client/models/page_model.dart';
import 'package:story_cms_client/services/client_store_service.dart';

class _FakeCMSClient implements CMSClient {
  Map<String, String> stringsToReturn = {};
  Object? errorToThrow;

  @override
  Future<Map<String, String>> getStrings({required String locale}) async {
    if (errorToThrow != null) throw errorToThrow!;
    return stringsToReturn;
  }

  @override
  Future<List<PageModel>> getPages(
    Map<String, String>? queryParameters,
  ) async => [];

  @override
  Future<List<LocaleItem>> getLocales() async => [];
}

void main() {
  late Box box;
  late ClientStoreService storeService;
  late _FakeCMSClient client;
  late StringsManager manager;

  setUp(() async {
    box = await Hive.openBox('strings_manager_test', path: './test');
    await box.clear();
    storeService = ClientStoreService(box);
    client = _FakeCMSClient();
    manager = StringsManager();
  });

  tearDown(() async {
    await box.close();
  });

  test(
    'loads cached overrides immediately, then overwrites on fetch success',
    () async {
      await storeService.saveStrings({'welcomeMessage': 'cached'});
      client.stringsToReturn = {
        'welcomeMessage': 'fresh',
        'loginButton': 'Log in',
      };

      await manager.init(
        client: client,
        storeService: storeService,
        locale: 'en',
      );

      expect(manager.overrides, {
        'welcomeMessage': 'fresh',
        'loginButton': 'Log in',
      });
      expect(storeService.strings, {
        'welcomeMessage': 'fresh',
        'loginButton': 'Log in',
      });
    },
  );

  test(
    'partial overrides: fetch result only contains a subset of keys',
    () async {
      client.stringsToReturn = {'welcomeMessage': 'fresh'};

      await manager.init(
        client: client,
        storeService: storeService,
        locale: 'en',
      );

      expect(manager.overrides, {'welcomeMessage': 'fresh'});
      expect(manager.overrides.containsKey('loginButton'), isFalse);
    },
  );

  test(
    'keeps the last cache and does not throw when the fetch fails',
    () async {
      await storeService.saveStrings({'welcomeMessage': 'cached'});
      client.errorToThrow = Exception('network down');

      await manager.init(
        client: client,
        storeService: storeService,
        locale: 'en',
      );

      expect(manager.overrides, {'welcomeMessage': 'cached'});
    },
  );
}
