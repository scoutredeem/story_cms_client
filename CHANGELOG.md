## 0.5.0

* Add `LocaleCatalogManager.directionFor(String localeCode)`, resolving a `TextDirection` from `catalog.languages` (rtl/ltr), with a documented README recipe (README, "Framework delegate fallback" / "Content-locale direction is a second, independent scope") for wiring it into both app-wide `Directionality` (via a `WidgetsLocalizations` fallback delegate) and a per-content-locale `Directionality` wrap. Fixes a latent bug in the previously-documented fallback delegate example, which hardcoded `TextDirection.ltr` for any locale Flutter doesn't ship, silently breaking RTL for CMS-tagged-rtl locales like `ckb`/`prs`/`ps`.

## 0.4.0

* Breaking: `LocaleCatalog.app` and `.media` are now `List<String>` of locale codes (was `AppLocale[]` metadata) — `app` lists locales past the 80% UI-translation threshold, `media` is new and parallel. Metadata (name/nativeName/direction) moved to a new `languages: List<AppLocale>` lookup field. `content` is unchanged.

## 0.3.0

* Breaking: `getLocales()` now returns a single `LocaleItem` with independent `app` (picker metadata) and `content` (published story slugs per locale) arrays, replacing the old flat `List<LocaleItem>`.

## 0.2.0

* Add remote language list and language string fetching: `LocaleCatalogManager` fetches available locales, `StringsManager` fetches and caches translation strings per locale.
* Bump `flutter_pdfview` to `1.4.5-beta.3`.

## 0.0.5

* Add built-in PDF viewer for Android/iOS (`PdfViewerScreen` + `PdfCacheService`), replacing the external Google Docs gview browser workaround. Web/desktop still fall back to launching the PDF in the browser.
* PDF downloads are cached to disk by URL hash to avoid re-downloading on repeat views.

## 0.0.1

* TODO: Describe initial release.
