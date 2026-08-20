import 'dart:developer';

import 'package:flutter/widgets.dart';
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

  /// Resolves the [TextDirection] for [localeCode] from `catalog.languages`.
  ///
  /// This is the single source of truth apps should use for RTL, at any
  /// scope - both the app-level `Directionality` Flutter derives from
  /// `WidgetsLocalizations.textDirection` (see the "Framework delegate
  /// fallback" section of the README) and any app-specific per-content
  /// `Directionality` wrap, when an app's content locale can differ from its
  /// interface locale.
  ///
  /// Falls back to [TextDirection.ltr] when the catalog hasn't loaded yet or
  /// [localeCode] has no matching entry - the same default an unset
  /// `Directionality` ambient would have anyway, so this never regresses an
  /// app that doesn't check it.
  TextDirection directionFor(String localeCode) {
    for (final language in catalog?.languages ?? const <AppLocale>[]) {
      if (language.locale == localeCode) {
        return language.languageDirection == LanguageDirection.rtl
            ? TextDirection.rtl
            : TextDirection.ltr;
      }
    }
    return TextDirection.ltr;
  }

  void dispose() {
    _catalogSignal.value = null;
  }
}
