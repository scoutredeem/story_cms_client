# story_cms_client

Shared Flutter client for the Journeys Studio CMS. Used by `almassira` and
other apps on the journeys platform (e.g. BNAP) so the CMS integration isn't
duplicated per app.

## Features

- **Pages** - fetch and cache CMS-authored pages (`CMSClient.getPages`,
  `PagesManager`, `PagesIndex` widget).
- **Runtime interface strings** - let the CMS push updated *values* for an
  app's existing interface-string keys at runtime, without an app-store
  release, including introducing a brand-new locale the app never bundled.
- **Locale catalog** - the CMS's list of known locales (for a language
  picker), sourced independently of which locales have published stories.

All three follow the same shape: a method on `CMSClient`/`StoryCMSClient`,
a `*Manager` exposing a `Signal` with cache-then-refresh semantics backed by
`ClientStoreService` (Hive), and (for pages) a ready-made widget. Strings and
locales don't ship a widget - the app owns its own UI and typed access, since
both are app-specific (see "App-side conventions" below).

## Pages

### What

CMS-authored "info" pages (Leader's Guides, User Guides, Bible App link,
etc.) - static content the CMS can add/edit/remove without an app release.
Each page is a `PageModel`:

```dart
class PageModel {
  final String title;
  final String description;
  final String icon;       // SVG url
  final String body;       // markdown, or an external url (see isExternal)
  final int group;         // pages with the same group number are grouped together
  final String category;   // app-defined - almassira uses '', 'guest', 'admin' to filter
}
```

`body` may be an external link instead of markdown -
`PageModel.isExternal`/`externalUri` detect this; `PagesIndex` already
handles the external case (in-app PDF viewer on Android/iOS if the url ends
in `.pdf`, otherwise `launchExternalUri`/browser).

### API contract

```
GET {baseUrl}/page?locale={locale}

200 OK
{ "pages": [ { "title": "...", "description": "...", "icon": "...", "body": "...", "group": 0, "category": "" } ] }
```

`queryParameters` on `getPages`/`PagesIndex` are passed straight through to
this request - `almassira` sends `{'locale': contentLocale}`.

### Setup

Register the client and cache once, at startup, alongside the other
singletons:

```dart
get.registerSingleton<ClientStoreService>(ClientStoreService(storyCMSBox));
get.registerSingleton<StoryCMSClient>(StoryCMSClient(networkService, baseUrl: baseUrl));
```

### Usage

`PagesIndex` is a ready-made widget: it owns fetching/caching via the
package-internal `PagesManager` singleton (`$pageManager` - not exposed to
the app, unlike `StringsManager`/`LocaleCatalogManager`) and hands the app a
grouped list to render however it wants. From `almassira`
(`lib/features/settings/resources.dart`):

```dart
PagesIndex(
  client: get<StoryCMSClient>(),
  storeService: get<ClientStoreService>(),
  tapOption: TapOption.navigate, // .navigate pushes PageInfoScreen; .select just calls onPageSelected
  queryParameters: {'locale': contentLocale},
  infoBodyBuilder: (context, text) => MarkdownText(content: text, ...),
  builder: (context, groupedPages, onPageSelected) {
    // groupedPages: List<List<PageModel>>, one inner list per `group` value.
    // Render however - almassira filters by `category` here (guest/admin/other)
    // before laying out each group as its own section.
  },
)
```

Re-run `PagesIndex` (i.e. rebuild it, e.g. inside a `Watch` keyed on the
content locale like `resources.dart` does) whenever `queryParameters` should
change - it refetches in `initState`, not reactively on prop change.

For `tapOption: TapOption.select` (or a custom detail screen instead of the
built-in `PageInfoScreen`), read the tapped page reactively via
`SelectedPageLoader`:

```dart
SelectedPageLoader(
  builder: (context, page) => MyCustomPageDetailView(page: page),
)
```

## Runtime interface strings

### Why

Interface strings (button labels, screen text, etc.) are normally compiled
in from the app's own ARB files. This feature lets Journeys Studio override
the *value* of an existing key at runtime, and even introduce a locale the
app never shipped an ARB file for. It does **not** let the CMS introduce new
keys - that still requires a normal app release. See
`almassira/docs/superpowers/specs/2026-07-23-journeys-studio-runtime-strings-design.md`
for the full design and rationale.

### API contract

```
GET {origin}/ui/v1/translation?locale={uiLocale}

200 OK
{
  "@@locale": "ar",
  "welcomeMessage": "...",
  "unlockSessionFor": "Unlock session {sessionName} for {groupName}"
}
```

- `{origin}` is `baseUrl` with its path replaced - this endpoint lives
  outside the `/api/v1` prefix baked into `baseUrl`, unlike every other
  request this package makes.
- This is the same ARB-serving endpoint `Makefile`'s `update-translations`
  target curls at build time - the response is a full ARB file (flat
  key/value, plus ARB metadata keys prefixed with `@`, e.g. `@@locale`).
  `getStrings` strips the `@`-prefixed keys before returning the map.
- `uiLocale` is the app's single interface locale - not a content/media
  locale split, if the host app has one.
- The response may omit any subset of keys the app knows about. That's
  expected, not an error - the app falls back to its compiled-in value for
  any missing key.
- Placeholder tokens (`{sessionName}`) use plain `{token}` substitution, not
  ICU `MessageFormat` - ARB placeholders must be simple `String`/`int`
  tokens for this to work.

```
GET {baseUrl}/locale

200 OK
{
  "content": [{ "locale": "en", "stories": ["classic"] }],
  "app": [
    { "locale": "en", "name": "English", "nativeName": "English", "languageDirection": "ltr" }
  ]
}
```

`getLocales()` returns a single `LocaleItem` mirroring this shape: `app` (a
`List<AppLocale>` - picker metadata: locale code, display name, native name,
text direction) and `content` (a `List<ContentLocale>` - which story slugs,
e.g. `"classic"`/`"express"`/`"youth"`/`"daily-devotion"`, the CMS has published per locale).
The two arrays are independent and are **not** joined/merged by this
package - a locale can appear in one without the other (e.g. a locale with
picker metadata but zero published stories yet), and callers search
whichever list they care about.

### Client API

```dart
final client = StoryCMSClient(networkService, baseUrl: baseUrl);

Map<String, String> overrides = await client.getStrings(locale: 'ar');
LocaleItem catalog = await client.getLocales();
catalog.app;     // List<AppLocale>
catalog.content; // List<ContentLocale>
```

### Managers

`StringsManager` and `LocaleCatalogManager` mirror `PagesManager`: cache
loaded on `init()`, then overwritten in place on a successful fetch. A
failed fetch (offline, server error) silently keeps whatever's cached - no
user-facing error.

```dart
final stringsManager = StringsManager();
await stringsManager.init(
  client: client,
  storeService: clientStoreService, // nullable - pass null to skip caching
  locale: 'ar',
);
stringsManager.overrides; // Map<String, String>, Signal-backed

final localeCatalogManager = LocaleCatalogManager();
await localeCatalogManager.init(
  client: client,
  storeService: clientStoreService, // nullable - pass null to skip caching
);
localeCatalogManager.catalog; // LocaleItem?, Signal-backed - null until first fetch/cache load
```

The package has no notion of "bundled" (i.e. which locales the host app ships
a generated `AppLocalizations` delegate for) - that's app-specific and the
package doesn't need to know it. If your fallback logic needs that check,
compute it app-side against `AppLocalizations.supportedLocales` instead of
threading it through the manager - see the `_fallback` getter below.

Both are meant to be registered once as singletons (GetIt or similar) by the
host app, not instantiated per-widget.

### Cache

`ClientStoreService` gained two Hive-backed keys: `Keys.strings` (the
override map, JSON-encoded) and `Keys.localeCatalog` (the `LocaleItem`
catalog, JSON-encoded). Same box as pages - no new Hive box required.

## App-side conventions

The package deliberately stops at the manager layer. Typed, compile-safe
access to string keys is app-specific (every app has its own ARB keys), so
each app implements a small, hand-maintained wrapper on top of
`StringsManager`/`LocaleCatalogManager`. `almassira`'s implementation
(`lib/l10n/strings.dart`) is the reference pattern - copy it when wiring up
a new app (e.g. BNAP):

1. **Typed wrapper class**, one getter per ARB key, `extends AppLocalizations`:

   ```dart
   class Strings extends AppLocalizations {
     Strings(this._context, this._locale) : super(_locale);
     final BuildContext _context;
     final String _locale;

     static Strings of(BuildContext context) =>
         Strings(context, get<LocaleManager>().appLocale);

     // Shared by every plain (non-parameterized) key.
     String _simpleOverride(String key, String fallback) =>
         get<StringsManager>().overrides[key] ?? fallback;

     @override
     String get welcomeMessage => _simpleOverride('welcomeMessage', _fallback.welcomeMessage);

     // Parameterized keys share a second helper: plain {token} substitution
     // on the override value, or the (lazily-computed) fallback if there's none.
     @override
     String unlockSessionFor(String sessionName, String groupName) => _parameterizedOverride(
       'unlockSessionFor',
       {'sessionName': sessionName, 'groupName': groupName},
       () => _fallback.unlockSessionFor(sessionName, groupName),
     );

     String _parameterizedOverride(String key, Map<String, String> tokens, String Function() fallback) {
       final override = get<StringsManager>().overrides[key];
       if (override == null) return fallback();
       var result = override;
       for (final entry in tokens.entries) {
         result = result.replaceAll('{${entry.key}}', entry.value);
       }
       return result;
     }

     // Bundled locale -> that locale's own generated AppLocalizations value.
     // Unbundled locale (CMS-only, no generated delegate) -> the default
     // locale's (en) value. "Bundled" is checked app-side against
     // AppLocalizations.supportedLocales - the package has no notion of it.
     // AppLocalizations.of(context) is nullable, so a stale/mismatched
     // context also degrades to the default instead of throwing.
     AppLocalizations get _fallback =>
         AppLocalizations.supportedLocales
             .map((locale) => locale.languageCode)
             .contains(_locale)
         ? AppLocalizations.of(_context) ?? _defaultFallback
         : _defaultFallback;

     AppLocalizations get _defaultFallback =>
         lookupAppLocalizations(const Locale('en'));
   }

   extension StringsContext on BuildContext {
     Strings get strings => Strings.of(this);
   }
   ```

   Extend `AppLocalizations` - don't make `Strings` a standalone duck-typed
   class. The base class is 100% abstract getters, so extending buys real,
   compiler-enforced parity for free: a key added to `app_en.arb`
   regenerates `AppLocalizations` with a new abstract getter, and a missing
   `@override` in `Strings` fails the *build*, not just a test someone has
   to remember to run. It also fails symmetrically for a removed key -
   `_fallback.<removedKey>` no longer resolves, so the stale getter itself
   won't compile. Verified both directions actually hard-error (`dart
   analyze`), not just warn. The `Intl.canonicalizedLocale` call inside
   `AppLocalizations`'s constructor (which `super(_locale)` invokes) is
   purely syntactic and doesn't throw for a made-up locale code, so this is
   safe for the unbundled-locale case too.

   `Strings` is still never obtained through `Localizations.of<AppLocalizations>`
   (no delegate ever returns one) - it's a plain object built directly by
   `Strings.of(context)`, so it doesn't participate in Flutter's actual
   localization-resolution mechanism, only in the type hierarchy.

2. **Guard the bypass, not just the migration** - extending doesn't stop
   someone from skipping the wrapper via a direct `AppLocalizations.of(context)`
   call (that compiles fine regardless of what `Strings` does). Add a test
   that scans `lib/` for that pattern (excluding the wrapper file's own
   `_fallback`) alongside a check for the old accessor extension, if one
   existed before this was introduced. `almassira`'s
   `test/no_strings_wrapper_bypass_test.dart` is the reference - it's what
   caught `app.dart`'s `onGenerateTitle` still calling
   `AppLocalizations.of(context)!.appTitle` directly, a call site the
   original `context.tr` migration missed because it never went through
   that extension to begin with.

3. **Full migration, not incremental** - once brand-new-locale support is in
   scope, every call site must go through the wrapper. A leftover direct
   `AppLocalizations.of(context)!` call crashes outright for a locale the
   generator never saw.

4. **Fetch lifecycle** - call `StringsManager.init` / `LocaleCatalogManager.init`
   on: app startup (after auth resolves), UI-locale change, guest/anonymous
   login, and any CMS-server switch (QA/staging tooling). Deliberately
   **not** on app resume - a changed string can wait for the next full
   launch; this is a lighter-weight signal than story content.

5. **Language picker** - prefer `LocaleCatalogManager.catalog?.app`, but fall
   back to the app's bundled/hardcoded language list when the catalog is empty
   (cold start with no cache yet, or before the CMS backend ships the
   `/locale` endpoint). An empty picker is a worse failure mode than a
   momentarily-stale one.

6. **Framework delegate fallback** - orthogonal to this feature, but a
   related trap: if the app forces its own locale (rather than relying on
   device negotiation) and supports a locale Flutter itself doesn't
   officially ship (`kWidgetsSupportedLanguages` /
   `kMaterialSupportedLanguages` / cupertino's equivalent), any framework
   widget that reads `WidgetsLocalizations.of(context)` (e.g.
   `ExpansionTile`) crashes with a null-check error unless every one of
   `WidgetsLocalizations`/`MaterialLocalizations`/`CupertinoLocalizations`
   has a delegate that supports it. A hand-written per-locale delegate
   subclass can't be added for a CMS-introduced locale at runtime, so use a
   generic fallback delegate per type instead - `isSupported` returns true
   for anything Flutter doesn't officially support, `load` always resolves
   to the English resource:

   ```dart
   class FallbackWidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
     const FallbackWidgetsLocalizationsDelegate();

     @override
     bool isSupported(Locale locale) =>
         !kWidgetsSupportedLanguages.contains(locale.languageCode);

     @override
     Future<WidgetsLocalizations> load(Locale locale) =>
         GlobalWidgetsLocalizations.delegate.load(const Locale('en'));

     @override
     bool shouldReload(FallbackWidgetsLocalizationsDelegate old) => false;
   }
   ```

   (and the `Material`/`Cupertino` equivalents). Place these **after** the
   app's normal `localizationsDelegates` so a real, officially-supported
   delegate still wins when one exists.
