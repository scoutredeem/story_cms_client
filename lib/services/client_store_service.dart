import 'dart:convert';
import 'dart:developer';

import 'package:hive_ce/hive.dart';

import '../models/locale_item_model.dart';
import '../models/page_model.dart';

enum Keys {
  /// List of [PageModel]
  pages,

  /// Map of interface string key -> override value
  strings,

  /// The [LocaleItem] catalog (app + content arrays)
  localeCatalog,
}

class ClientStoreService {
  final Box box;
  const ClientStoreService(this.box);

  // ------------------------------------
  // Page
  // ------------------------------------
  List<PageModel> get pages {
    final pages = box.get(Keys.pages.toString());

    if (pages == null) {
      return [];
    }

    try {
      return (jsonDecode(pages) as List)
          .map<PageModel>((e) => PageModel.fromJson(e))
          .toList();
    } catch (e) {
      log('Error while parsing page: $e');
      return [];
    }
  }

  Future<void> savePages(List<PageModel> pages) async {
    try {
      await box.put(
        Keys.pages.toString(),
        jsonEncode(pages.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      log('Error while saving pages: $e');
    }
  }

  // ------------------------------------
  // Strings
  // ------------------------------------

  /// The last-cached interface-string overrides, tagged with the locale
  /// they belong to - null if nothing is cached or the cache is unreadable.
  /// Tagging the locale lets callers refuse to apply this cache when it
  /// belongs to a different locale than the one currently requested (see
  /// StringsManager), instead of leaking a stale locale's strings.
  ({String locale, Map<String, String> overrides})? get cachedStrings {
    final raw = box.get(Keys.strings.toString());
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as Map;
      return (
        locale: decoded['locale'] as String,
        overrides: (decoded['overrides'] as Map).cast<String, String>(),
      );
    } catch (e) {
      log('Error while parsing strings: $e');
      return null;
    }
  }

  Future<void> saveStrings(String locale, Map<String, String> overrides) async {
    try {
      await box.put(
        Keys.strings.toString(),
        jsonEncode({'locale': locale, 'overrides': overrides}),
      );
    } catch (e) {
      log('Error while saving strings: $e');
    }
  }

  // ------------------------------------
  // Locale catalog
  // ------------------------------------
  LocaleItem? get localeCatalog {
    final catalog = box.get(Keys.localeCatalog.toString());

    if (catalog == null) {
      return null;
    }

    try {
      return LocaleItem.fromJson(catalog);
    } catch (e) {
      log('Error while parsing locale catalog: $e');
      return null;
    }
  }

  Future<void> saveLocaleCatalog(LocaleItem catalog) async {
    try {
      await box.put(Keys.localeCatalog.toString(), catalog.toJson());
    } catch (e) {
      log('Error while saving locale catalog: $e');
    }
  }
}
