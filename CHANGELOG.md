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
