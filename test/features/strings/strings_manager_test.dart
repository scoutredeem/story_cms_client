import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:story_cms_client/client.dart';
import 'package:story_cms_client/features/strings/strings_manager.dart';
import 'package:story_cms_client/models/locale_item_model.dart';
import 'package:story_cms_client/models/page_model.dart';
import 'package:story_cms_client/services/client_store_service.dart';

class _FakeCMSClient implements CMSClient {
  Map<String, String> stringsToReturn = {};

  /// The `@@locale` tag the fake response carries. Defaults to echoing back
  /// whatever locale was requested (the normal case); set explicitly to
  /// simulate a server returning data for the wrong locale.
  String? localeToReturn;

  Object? errorToThrow;

  @override
  Future<Map<String, String>> getStrings({required String locale}) async {
    if (errorToThrow != null) throw errorToThrow!;
    return {'@@locale': localeToReturn ?? locale, ...stringsToReturn};
  }

  @override
  Future<List<PageModel>> getPages(
    Map<String, String>? queryParameters,
  ) async => [];

  @override
  Future<LocaleItem> getLocales() async => LocaleItem(app: [], content: []);
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
      await storeService.saveStrings('en', {'welcomeMessage': 'cached'});
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
      expect(storeService.cachedStrings?.locale, 'en');
      expect(storeService.cachedStrings?.overrides, {
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
      await storeService.saveStrings('en', {'welcomeMessage': 'cached'});
      client.errorToThrow = Exception('network down');

      await manager.init(
        client: client,
        storeService: storeService,
        locale: 'en',
      );

      expect(manager.overrides, {'welcomeMessage': 'cached'});
    },
  );

  test('a cache tagged for a different locale is not applied - a subsequent '
      'fetch failure leaves overrides empty rather than leaking it', () async {
    // Simulates: the app was previously in Hindi, which cached Hindi's
    // overrides. The user now switches to French while offline.
    await storeService.saveStrings('hi', {'welcomeMessage': 'Hindi welcome'});
    client.errorToThrow = Exception('offline');

    await manager.init(
      client: client,
      storeService: storeService,
      locale: 'fr',
    );

    expect(manager.overrides, isEmpty);
  });

  test('a fetch response tagged with a different locale than requested is '
      'ignored and not persisted', () async {
    // Simulates a server/CDN bug: asked for French, got English back.
    client.localeToReturn = 'en';
    client.stringsToReturn = {'welcomeMessage': 'Hello'};

    await manager.init(
      client: client,
      storeService: storeService,
      locale: 'fr',
    );

    expect(manager.overrides, isEmpty);
    expect(storeService.cachedStrings, isNull);
  });

  test('in-memory overrides from a previous locale do not leak into a later '
      'init() call for a different locale within the same session', () async {
    client.stringsToReturn = {'welcomeMessage': 'Hindi welcome'};
    await manager.init(
      client: client,
      storeService: storeService,
      locale: 'hi',
    );
    expect(manager.overrides, {'welcomeMessage': 'Hindi welcome'});

    client.stringsToReturn = {};
    client.errorToThrow = Exception('offline');
    await manager.init(
      client: client,
      storeService: storeService,
      locale: 'fr',
    );

    expect(manager.overrides, isEmpty);
  });
}
