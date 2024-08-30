import 'dart:convert';
import 'dart:developer';

import 'package:hive/hive.dart';

import '../models/page_model.dart';

enum Keys {
  /// List of [PageModel]
  pages,
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
}
