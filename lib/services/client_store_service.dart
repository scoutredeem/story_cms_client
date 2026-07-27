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

  /// List of [LocaleItem]
  locales,
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
  Map<String, String> get strings {
    final strings = box.get(Keys.strings.toString());

    if (strings == null) {
      return {};
    }

    try {
      return (jsonDecode(strings) as Map).cast<String, String>();
    } catch (e) {
      log('Error while parsing strings: $e');
      return {};
    }
  }

  Future<void> saveStrings(Map<String, String> strings) async {
    try {
      await box.put(Keys.strings.toString(), jsonEncode(strings));
    } catch (e) {
      log('Error while saving strings: $e');
    }
  }

  // ------------------------------------
  // Locales
  // ------------------------------------
  List<LocaleItem> get locales {
    final locales = box.get(Keys.locales.toString());

    if (locales == null) {
      return [];
    }

    try {
      return (jsonDecode(locales) as List)
          .map<LocaleItem>((e) => LocaleItem.fromJson(e))
          .toList();
    } catch (e) {
      log('Error while parsing locales: $e');
      return [];
    }
  }

  Future<void> saveLocales(List<LocaleItem> locales) async {
    try {
      await box.put(
        Keys.locales.toString(),
        jsonEncode(locales.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      log('Error while saving locales: $e');
    }
  }
}
