import 'models/locale_item_model.dart';
import 'models/page_model.dart';
import 'services/network_service.dart';

abstract class CMSClient {
  /// Fetches all the pages from the CMS
  ///
  /// [queryParameters] are the optional query parameters to be sent with the request
  Future<List<PageModel>> getPages(Map<String, String>? queryParameters);

  /// Fetches the interface string overrides for [locale] from the existing
  /// `/ui/v1/translation` ARB-serving endpoint (same one `Makefile`'s
  /// `update-translations` target curls at build time).
  ///
  /// The response may omit any subset of keys the app knows about — that's
  /// expected, not an error. Callers fall back to their compiled-in value
  /// for any key not present in the returned map.
  Future<Map<String, String>> getStrings({required String locale});

  /// Fetches the CMS's locale catalog: `app` (picker metadata - name,
  /// nativeName, direction - for locales never bundled in the app's own ARB
  /// files) and `content` (which story slugs are published per locale).
  Future<LocaleItem> getLocales();
}

class StoryCMSClient implements CMSClient {
  final NetworkService _networkService;

  final String baseUrl;
  StoryCMSClient(this._networkService, {required this.baseUrl});

  @override
  Future<List<PageModel>> getPages(Map<String, String>? queryParameters) async {
    final uri = Uri.parse(
      '$baseUrl/page',
    ).replace(queryParameters: queryParameters);

    final data = await _networkService.get(uri);
    return data['pages']
        .cast<Map<String, dynamic>>()
        .map<PageModel>(PageModel.fromMap)
        .toList();
  }

  @override
  Future<Map<String, String>> getStrings({required String locale}) async {
    if (locale == 'en') {
      throw UnimplementedError('English strings are not supported yet');
    }
    // `/ui/v1/translation` lives outside the `/api/v1` prefix baked into
    // [baseUrl], so keep the origin but replace the path entirely.
    final uri = Uri.parse(
      baseUrl,
    ).replace(path: '/ui/v1/translation', queryParameters: {'locale': locale});

    final data = await _networkService.get(uri);
    // The endpoint returns a full ARB file (flat key/value, plus ARB
    // metadata keys like `@@locale` prefixed with `@`) rather than a
    // `{"strings": {...}}` override map, so filter those out - except
    // `@@locale`, which StringsManager keeps to confirm the response
    // actually matches the requested locale before applying it.
    return Map.fromEntries(
      data.entries
          .where(
            (entry) => entry.key == '@@locale' || !entry.key.startsWith('@'),
          )
          .map((entry) => MapEntry(entry.key, entry.value.toString())),
    );
  }

  @override
  Future<LocaleItem> getLocales() async {
    final uri = Uri.parse('$baseUrl/locale');

    final data = await _networkService.get(uri);
    return LocaleItem.fromMap(data);
  }
}
