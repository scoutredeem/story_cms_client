import 'dart:developer';

import 'package:signals/signals.dart';
import 'package:story_cms_client/services/client_store_service.dart';

import '../../client.dart';
import '../../models/page_models.dart';

final $pageManager = PagesManager();

class PagesManager {
  Future<void> init({
    required CMSClient client,
    required ClientStoreService? storeService,
    Map<String, String>? queryParameters,
  }) async {
    storeService != null ? _loadCachedPages(storeService) : null;

    final remotePages = await client.getPages(null);
    _pagesSignal.value = remotePages;

    await storeService?.savePages(pages);
  }

  void _loadCachedPages(ClientStoreService store) {
    try {
      final cachedPages = store.pages;
      if (cachedPages.isNotEmpty) {
        _pagesSignal.value = cachedPages;
      }
    } catch (e) {
      log('Error loading cached pages: $e');
    }
  }

  final _pagesSignal = Signal<List<PageModel>>([]);
  List<PageModel> get pages => _pagesSignal.value;

  final _selectedPageSignal = Signal<PageModel?>(null);
  PageModel? get selectedPage => _selectedPageSignal.value;
  void onPageSelected(PageModel page) {
    _selectedPageSignal.value = page;
  }

  void dispose() {
    _pagesSignal.value = [];
    _selectedPageSignal.value = null;
  }
}
