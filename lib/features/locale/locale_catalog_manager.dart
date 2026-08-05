import 'dart:developer';

import 'package:signals/signals.dart';

import '../../client.dart';
import '../../models/locale_catalog_model.dart';
import '../../services/client_store_service.dart';

/// Mirrors [PagesManager]/[StringsManager]: exposes the CMS's locale catalog
/// ([LocaleCatalog]'s `languages`, `content`, `app` and `media` arrays) as a
/// signal, sourced from [CMSClient.getLocales], cache-then-refresh. Replaces
/// the picker's old dependency on `AppLocalizations.supportedLocales` and a
/// hardcoded metadata array — this is now the single source of "what is
/// locale X called" (`.languages`), "which story slugs are published per
/// locale" (`.content`), and "which locales are translation-ready for the
/// app UI" (`.app`), including locales never bundled in the app.
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

  final _catalogSignal = Signal<LocaleCatalog?>(null);
  LocaleCatalog? get catalog => _catalogSignal.value;

  void dispose() {
    _catalogSignal.value = null;
  }
}
