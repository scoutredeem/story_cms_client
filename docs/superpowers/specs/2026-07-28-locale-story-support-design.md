# Locale story support (SCO-2691)

## Problem

[SCO-2691](https://linear.app/scoutredeem/issue/SCO-2691/unpublished-editions-can-still-be-selected-in-bnap):
BNAP lets users select any content language regardless of whether the CMS
has actually published that language for the currently-selected edition
(classic/express/youth). Switching to an unpublished language+edition combo
produces an empty devotion screen.

Root cause: `content_language_settings.dart`'s language picker gates
selectability using a hardcoded, hand-maintained map
(`Languages().variantLanguageMap`) that has drifted out of sync with what's
actually published in the CMS - it never consults live CMS data. (The
edition picker, `edition_settings.dart`, is *not* part of this bug - it
already checks `StoriesManager.stories`, fetched per-locale from the real
content API.)

The CMS's `GET /locale` endpoint (`content-staging.bioy.app/api/v1/locale`)
already returns a `content` array - `[{ "locale": "de", "stories": ["classic",
"express"] }, ...]` - naming published stories by slug, not the app's
internal int `storyId`. `story_cms_client` currently parses only the sibling
`app` array (picker metadata); this feature adds parsing for `content` and
wires it into BNAP's language picker.

## Scope

Two repos:

1. **`story_cms_client`** (this repo) - parse the `content` array, expose it
   alongside the existing `app` array data.
2. **`bioy-client`** (BNAP) - consume it to fix the language-picker gate
   (closes SCO-2691), and switch its `story_cms_client` pubspec dependency
   to a local path dependency for this development cycle.

## Part 1 - `story_cms_client`

### Models

- **`AppLocale`** (`lib/models/app_locale_model.dart`) - the current
  `LocaleItem` fields, renamed: `locale`, `name`, `nativeName`,
  `languageDirection` (`LanguageDirection` enum moves here too).
- **`ContentLocale`** (`lib/models/content_locale_model.dart`) - new:
  `locale: String`, `stories: List<String>` (raw CMS story slugs, e.g.
  `"classic"`, `"express"`, `"youth"` - package stays CMS-generic and does
  not restrict/validate against a known set; callers filter/interpret as
  needed).
- **`LocaleItem`** (`lib/models/locale_item_model.dart`, rewritten) - the
  catalog wrapper, mirroring the raw `/locale` response 1:1: `app:
  List<AppLocale>`, `content: List<ContentLocale>`. Not per-locale - one
  `LocaleItem` represents the *entire* catalog response, holding the two
  arrays independently. No merging/joining happens in this model or in
  `getLocales()` - each array is parsed and stored as-is, and consumers that
  need a specific locale's entry search the relevant list themselves (see
  Part 2). This keeps the package a thin pass-through (no synthetic
  cross-referencing to maintain) and avoids forcing nullable `app`/`content`
  fields onto every item the way a per-locale merge would.

Serialization: `toMap`/`fromMap`/`toJson`/`fromJson`/`==`/`hashCode` on all
three. `LocaleItem.toMap` is `{'app': [...AppLocale.toMap()], 'content':
[...ContentLocale.toMap()]}` - the same shape the API returns, so
`LocaleItem.fromMap` can parse the raw `/locale` response directly (no
separate merge step needed for cache round-tripping vs. live parsing - it's
the same code path either way).

### `CMSClient.getLocales()`

Signature changes: `Future<List<LocaleItem>>` -> `Future<LocaleItem>`
(singular - one catalog object per call, not a list of locales):

```dart
@override
Future<LocaleItem> getLocales() async {
  final uri = Uri.parse('$baseUrl/locale');
  final data = await _networkService.get(uri);
  return LocaleItem.fromMap(data);
}
```

with `LocaleItem.fromMap` doing:

```dart
factory LocaleItem.fromMap(Map<String, dynamic> map) => LocaleItem(
      app: (map['app'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(AppLocale.fromMap)
          .toList(),
      content: (map['content'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ContentLocale.fromMap)
          .toList(),
    );
```

### `ClientStoreService` / `LocaleCatalogManager`

Both move from list-of-locales to a single cached/signaled `LocaleItem`:

- `ClientStoreService`: `Keys.locales` -> `Keys.localeCatalog`; getter
  `locales`/`saveLocales(List<LocaleItem>)` -> `localeCatalog` (`LocaleItem?`,
  `null` until first successful fetch-or-cache-load) /
  `saveLocaleCatalog(LocaleItem catalog)`.
- `LocaleCatalogManager`: `Signal<List<LocaleItem>>` -> `Signal<LocaleItem?>`;
  getter `locales` -> `catalog` (`LocaleItem?`).

### Tests / docs to update

- `test/client_test.dart` - `getLocales` parses both arrays into one
  `LocaleItem`.
- `test/models/locale_item_model_test.dart` - split into
  `app_locale_model_test.dart`, `content_locale_model_test.dart`, and a
  rewritten `locale_item_model_test.dart` for the wrapper (round-tripping
  both lists, including empty-list cases, through `toJson`/`fromJson`).
- `test/features/locale/locale_catalog_manager_test.dart`,
  `test/services/client_store_service_test.dart`,
  `test/features/strings/strings_manager_test.dart` (fake client stub) -
  update constructors/fixtures and the fake `getLocales()` return type.
- `README.md` - update the `/locale` section for `AppLocale`/`ContentLocale`/
  the `LocaleItem` catalog wrapper, and `LocaleCatalogManager.catalog`.

## Part 2 - `bioy-client` (BNAP)

### `content_language_settings.dart` - the actual bug fix

Replace the hardcoded gate with a live CMS check, **fail-closed** (no
catalog entry yet -> treated as unavailable, matching "unpublished editions
should be disabled" from the issue):

```dart
bool _isLanguageAvailable(Variant variant, String candidateLocale) {
  final normalized = candidateLocale.split('_').first; // matches ContentService's existing normalization
  final contentLocale = locator<LocaleCatalogManager>().catalog?.content
      .firstWhereOrNull((c) => c.locale == normalized);
  return contentLocale?.stories.contains(variant.enumString) ?? false;
}
```

Replaces the `Languages().variantHasLanguage(...)` calls in `_languageField`
(disabled state) and the `showEdition`/`showExpress` helpers.

### `languages.dart`

Delete `variantLanguageMap` and `variantHasLanguage` - dead code once the
fail-closed live check replaces them (no fallback path needs them; leaving
them risks someone reaching for the stale map again).

### `settings_manager.dart`

`refreshInterfaceStrings()` - remove the `if
(FeatureFlag.dynamicAppLanguageList.isEnabled)` wrapper around
`LocaleCatalogManager.init(...)`. The catalog (app + content) always
fetches now; that flag no longer gates fetching at all, only the
app-language *UI* (below).

### `app_language_settings.dart`

Move the flag check here, scoped to the app-language list only - content
language gating is never flag-gated:

```dart
final appLocales = FeatureFlag.dynamicAppLanguageList.isEnabled
    ? locator<LocaleCatalogManager>().catalog?.app ?? <AppLocale>[]
    : <AppLocale>[];
final locales = appLocales.isEmpty
    ? Languages().languages.keys.toList()
    : appLocales.map((item) => item.locale).toList();
final names = appLocales.isEmpty
    ? Languages().languages
    : {for (final item in appLocales) item.locale: item.nativeName};
```

### `edition_settings.dart`

No change - already correct (per-locale live check via `StoriesManager`).

## Part 3 - Dev setup

`bioy-client/pubspec.yaml` - swap the `story_cms_client` git dependency for
a local path dependency during this development cycle:

```yaml
story_cms_client:
  path: /Users/paurakh/projects/scoutredeem/al-massira/story_cms_client
```

Reverting to a tagged git dependency once the package is released is out of
scope for this work - left to a later, separate step.

## Out of scope

- Restricting `ContentLocale.stories` to a known enum of story slugs -
  package stays generic; BNAP's own `Variant.enumString` values happen to
  match the slugs `classic`/`express`/`youth` today.
- Any change to `edition_settings.dart` - it isn't part of the bug.
- Reverting the pubspec path dependency back to a git tag.
