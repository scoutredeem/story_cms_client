import 'dart:developer';

import 'package:signals/signals.dart';

import '../../client.dart';
import '../../services/client_store_service.dart';

/// Mirrors [PagesManager]: exposes the CMS's interface-string override map
/// as a signal, loading the last cached value on init and overwriting cache
/// + signal on a successful fetch. A failed fetch silently keeps whatever is
/// already cached.
class StringsManager {
  Future<void> init({
    required CMSClient client,
    required ClientStoreService? storeService,
    required String locale,
  }) async {
    _loadCachedStrings(storeService);

    try {
      final remoteStrings = await client.getStrings(locale: locale);
      _overridesSignal.value = remoteStrings;
      await storeService?.saveStrings(overrides);
    } catch (e) {
      log('Error fetching strings: $e');
    }
  }

  void _loadCachedStrings(ClientStoreService? store) {
    if (store == null) return;

    try {
      final cachedStrings = store.strings;
      if (cachedStrings.isNotEmpty) {
        _overridesSignal.value = cachedStrings;
      }
    } catch (e) {
      log('Error loading cached strings: $e');
    }
  }

  final _overridesSignal = Signal<Map<String, String>>({});
  Map<String, String> get overrides => _overridesSignal.value;

  void dispose() {
    _overridesSignal.value = {};
  }
}
