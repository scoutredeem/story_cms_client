import 'dart:developer';

import 'package:signals/signals.dart';

import '../../client.dart';
import '../../models/locale_item_model.dart';
import '../../services/client_store_service.dart';

/// Mirrors [PagesManager]/[StringsManager]: exposes the CMS's locale catalog
/// ([LocaleItem]'s `app` and `content` arrays) as a signal, sourced from
/// [CMSClient.getLocales], cache-then-refresh. Replaces the picker's old
/// dependency on `AppLocalizations.supportedLocales` and a hardcoded
/// metadata array — this is now the single source of "which locales exist
/// and what are they called" (`.app`) and "which story slugs are published
/// per locale" (`.content`), including locales never bundled in the app.
class LocaleCatalogManager {
  Future<void> init({
    required CMSClient client,
    required ClientStoreService? storeService,
  }) async {
    _loadCachedCatalog(storeService);

    try {
      final remoteCatalog = await client.getLocales();
      _catalogSignal.value = remoteCatalog;
      await storeService?.saveLocaleCatalog(remoteCatalog);
    } catch (e) {
      log('Error fetching locale catalog: $e');
    }
  }

  void _loadCachedCatalog(ClientStoreService? store) {
    if (store == null) return;

    try {
      final cachedCatalog = store.localeCatalog;
      if (cachedCatalog != null) {
        _catalogSignal.value = cachedCatalog;
      }
    } catch (e) {
      log('Error loading cached locale catalog: $e');
    }
  }

  final _catalogSignal = Signal<LocaleItem?>(null);
  LocaleItem? get catalog => _catalogSignal.value;

  void dispose() {
    _catalogSignal.value = null;
  }
}
