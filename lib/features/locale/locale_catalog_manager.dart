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
  /// The set of locale codes the host app ships an `AppLocalizations`
  /// delegate for (i.e. has an ARB file for), passed in by the app at init
  /// since the package itself has no knowledge of the app's bundled locales.
  Set<String> _bundledLocales = {};

  Future<void> init({
    required CMSClient client,
    required ClientStoreService? storeService,
    required Set<String> bundledLocales,
  }) async {
    _bundledLocales = bundledLocales;

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

  /// Whether [locale] is one the host app ships a generated
  /// `AppLocalizations` delegate for. `false` means the locale was
  /// introduced purely via the CMS and has no compiled-in resources.
  bool isBundled(String locale) => _bundledLocales.contains(locale);

  void dispose() {
    _localesSignal.value = [];
    _bundledLocales = {};
  }
}
