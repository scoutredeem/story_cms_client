import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Downloads and caches remote PDFs on disk so [PdfViewerScreen] can
/// render them locally instead of streaming from the network each time.
class PdfCacheService {
  final http.Client client;

  const PdfCacheService({required this.client});

  /// Returns a local [File] for [url], downloading and caching it on disk
  /// first if it isn't already cached.
  Future<File> getFile(Uri url) async {
    final file = await _cacheFileFor(url);

    if (await file.exists() && await file.length() > 0) {
      return file;
    }

    final response = await client.get(url);

    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to download PDF: ${response.statusCode}',
        uri: url,
      );
    }

    await file.create(recursive: true);
    await file.writeAsBytes(response.bodyBytes);

    return file;
  }

  Future<File> _cacheFileFor(Uri url) async {
    final tempDir = await getTemporaryDirectory();
    final hash = md5.convert(utf8.encode(url.toString())).toString();

    return File('${tempDir.path}/pdf_cache/$hash.pdf');
  }
}
