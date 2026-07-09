# Built-in PDF Viewer — Design

## Problem

`PagesIndex._onPageSelected` currently handles PDF external pages by rewriting the URL to a Google Docs `gview` embed and launching it in an external/in-app browser via `url_launcher` (`lib/features/pages/pages_index.dart:97-109`). This is a workaround for Android downloading rather than rendering PDFs in-browser, and it leaves the PDF experience outside the app's control (no consistent chrome, dependent on an external Google service).

## Goal

Render PDFs natively inside the app for Android/iOS. Desktop/web scope is explicitly out — those platforms keep the existing external-launch behavior unchanged.

## Non-goals

- Desktop/web in-app PDF rendering.
- Cache eviction/TTL policy (temp dir is OS-managed; redundant re-download on stale cache is acceptable).
- Annotations, search, or other advanced PDF features beyond paging/zoom that `flutter_pdfview` provides out of the box.

## Package choice

`flutter_pdfview` (native PDFKit on iOS, PdfiumCore/AndroidPdfViewer on Android), with the app handling download + local caching itself (the package renders local file paths, not remote URLs).

Considered and rejected:
- **pdfx** — comparable native pdfium wrapper, same manual download requirement, no material advantage over `flutter_pdfview`'s maturity/adoption.
- **flutter_cached_pdfview** — wraps `flutter_pdfview` with built-in URL caching, but is a thinner-maintained wrapper; caching logic is small enough to own directly and avoid the extra transitive dependency.
- **syncfusion_flutter_pdfviewer** — broadest platform support (including web), but commercial licensing; not needed since scope is mobile-only.

## Architecture

### `PdfCacheService` (new — `lib/services/pdf_cache_service.dart`)

- `Future<File> getFile(Uri url)`:
  - Compute cache key: `md5(url.toString())` hex digest (new `crypto` dependency — pure Dart, no native code).
  - Cache path: `<getTemporaryDirectory()>/pdf_cache/<md5>.pdf` (via `path_provider`).
  - If cached file exists and is non-empty, return it immediately.
  - Otherwise `http.get(url)`, validate 200 response, write bytes to the cache path (creating `pdf_cache/` if needed), return the `File`.
  - Throws on non-200 or network failure; caller handles the error.

### `PdfViewerScreen` (new — `lib/features/pages/pdf_viewer_screen.dart`)

- `StatefulWidget` taking `Uri pdfUri`, `String title`, optional `titleBuilder` (mirrors `PageInfoScreen`'s existing title-builder pattern).
- `initState` kicks off `PdfCacheService.getFile(pdfUri)`.
- States:
  - **Loading**: centered `CircularProgressIndicator`.
  - **Success**: `PDFView(filePath: file.path, ...)` from `flutter_pdfview`, with `onError`/`onPageError` callbacks logged via `dart:developer` `log` (non-fatal — don't tear down the view on a single page error).
  - **Error**: centered message + **Retry** button (re-runs the fetch) + **Open in Browser** button (calls the existing `launchExternalUri` as a fallback so the user is never stuck).
- `AppBar` follows the same `titleBuilder == null` conditional pattern used in `PageInfoScreen`.

### `pages_index.dart` changes

- In `_onPageSelected`, the PDF branch (`page.isExternal && isPdf`) now pushes `PdfViewerScreen(pdfUri: page.externalUri, title: page.title, titleBuilder: widget.titleBuilder)` via `Navigator.of(context).push(MaterialPageRoute(...))` instead of rewriting the URL to the `gview` embed and calling `launchExternalUri`.
- Non-PDF external pages keep calling `launchExternalUri` exactly as today — no change.
- Delete the now-dead `docs.google.com/gview` URL-rewrite block.
- `launchExternalUri` stays exported and unchanged (still used for non-PDF external links and as the PDF error-state fallback).

## Data flow

```
tap PDF page
  -> $pageManager.onPageSelected(page)
  -> Navigator.push(PdfViewerScreen(pdfUri: page.externalUri))
  -> initState -> PdfCacheService.getFile(uri)
       -> cache hit  -> return local File immediately
       -> cache miss -> http.get -> write bytes -> return local File
  -> setState -> PDFView(filePath: file.path)
```

## Error handling

- Network/download failure in `PdfCacheService.getFile` is caught in `PdfViewerScreen`, surfacing the error state described above (Retry / Open in Browser).
- `PDFView` render-level errors (`onError`, `onPageError`) are logged, not fatal to the whole screen.

## Dependencies added

- `flutter_pdfview`
- `path_provider`
- `crypto`

## Testing

- Unit test `PdfCacheService` against a mocked `http.Client` and a temp directory: verifies cache-miss downloads and writes the file, cache-hit skips the network call, and non-200 responses throw.
- `PDFView` is a native platform view and isn't meaningfully widget-testable; verified via manual run-through on an Android and iOS simulator (tap a PDF page in the example app, confirm it renders in-app, confirm Retry/Open-in-Browser fallback on a broken URL).
