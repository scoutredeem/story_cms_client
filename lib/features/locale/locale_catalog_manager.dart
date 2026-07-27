import 'dart:developer';

import 'package:signals/signals.dart';

import '../../client.dart';
import '../../models/locale_item_model.dart';
import '../../services/client_store_service.dart';

/// Mirrors [PagesManager]/[StringsManager]: exposes the CMS's locale catalog
/// as a signal (locale, name, nativeName, direction), sourced from
/// [CMSClient.getLocales], cache-then-refresh. Replaces the picker's old
/// dependency on `AppLocalizations.supportedLocales` and a hardcoded
/// metadata array — this is now the single source of "which locales exist
/// and what are they called," including locales never bundled in the app.
class LocaleCatalogManager {
  Future<void> init({
    required CMSClient client,
    required ClientStoreService? storeService,
  }) async {
    _loadCachedLocales(storeService);

    try {
      final remoteLocales = await client.getLocales();
      _localesSignal.value = remoteLocales;
      await storeService?.saveLocales(locales);
    } catch (e) {
      log('Error fetching locales: $e');
    }
  }

  void _loadCachedLocales(ClientStoreService? store) {
    if (store == null) return;

    try {
      final cachedLocales = store.locales;
      if (cachedLocales.isNotEmpty) {
        _localesSignal.value = cachedLocales;
      }
    } catch (e) {
      log('Error loading cached locales: $e');
    }
  }

  final _localesSignal = Signal<List<LocaleItem>>([]);
  List<LocaleItem> get locales => _localesSignal.value;

  void dispose() {
    _localesSignal.value = [];
  }
}
