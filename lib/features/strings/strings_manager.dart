import 'dart:developer';

import 'package:signals/signals.dart';

import '../../client.dart';
import '../../services/client_store_service.dart';

/// Mirrors [PagesManager]: exposes the CMS's interface-string override map
/// as a signal, loading the last cached value on init and overwriting cache
/// + signal on a successful fetch. A failed fetch silently keeps whatever is
/// already cached.
///
/// Both the cache and the fetch response are locale-tagged (the cache via
/// [ClientStoreService.cachedStrings], the fetch via the `@@locale` key
/// [CMSClient.getStrings] preserves) and only trusted when that tag matches
/// the requested [locale] - otherwise a stale or mismatched locale's strings
/// would silently render under the wrong language.
class StringsManager {
  Future<void> init({
    required CMSClient client,
    required ClientStoreService? storeService,
    required String locale,
  }) async {
    _loadCachedStrings(storeService, locale);

    try {
      final remoteStrings = await client.getStrings(locale: locale);
      final remoteLocale = remoteStrings['@@locale'] ?? locale;
      if (remoteLocale != locale) {
        log(
          'Strings locale mismatch: requested $locale, got $remoteLocale - '
          'ignoring response',
        );
        return;
      }

      final overridesOnly = Map<String, String>.from(remoteStrings)
        ..remove('@@locale');
      _overridesSignal.value = overridesOnly;
      await storeService?.saveStrings(locale, overridesOnly);
    } catch (e) {
      log('Error fetching strings: $e');
    }
  }

  void _loadCachedStrings(ClientStoreService? store, String locale) {
    final cached = store == null ? null : _readCache(store);

    if (cached != null && cached.locale == locale) {
      _overridesSignal.value = cached.overrides;
      return;
    }

    // No cache, an unreadable cache, or a cache tagged for a locale other
    // than [locale] - reset rather than leaving a previous locale's map
    // (held in memory from an earlier init() call this session, or just
    // loaded above) applied to this one. If the upcoming fetch then fails,
    // this is what's shown: no overrides, not a stale wrong-language set.
    _overridesSignal.value = {};
  }

  ({String locale, Map<String, String> overrides})? _readCache(
    ClientStoreService store,
  ) {
    try {
      return store.cachedStrings;
    } catch (e) {
      log('Error loading cached strings: $e');
      return null;
    }
  }

  final _overridesSignal = Signal<Map<String, String>>({});
  Map<String, String> get overrides => _overridesSignal.value;

  void dispose() {
    _overridesSignal.value = {};
  }
}
