import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:story_cms_client/services/pdf_cache_service.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String path;
  _FakePathProviderPlatform(this.path);

  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final pdfUri = Uri.parse('https://example.com/doc.pdf');

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pdf_cache_test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('downloads and writes the file on a cache miss', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      return http.Response.bytes(utf8.encode('pdf-bytes'), 200);
    });

    final service = PdfCacheService(client: client);
    final file = await service.getFile(pdfUri);

    expect(requestCount, 1);
    expect(await file.exists(), isTrue);
    expect(await file.readAsString(), 'pdf-bytes');
  });

  test('skips the network call on a cache hit', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      return http.Response.bytes(utf8.encode('pdf-bytes'), 200);
    });

    final service = PdfCacheService(client: client);
    await service.getFile(pdfUri);
    final file = await service.getFile(pdfUri);

    expect(requestCount, 1);
    expect(await file.readAsString(), 'pdf-bytes');
  });

  test('throws on a non-200 response', () async {
    final client = MockClient((request) async {
      return http.Response('not found', 404);
    });

    final service = PdfCacheService(client: client);

    expect(() => service.getFile(pdfUri), throwsA(isA<HttpException>()));
  });

  test('caches by URL hash under pdf_cache/', () async {
    final client = MockClient((request) async {
      return http.Response.bytes(utf8.encode('pdf-bytes'), 200);
    });

    final service = PdfCacheService(client: client);
    final file = await service.getFile(pdfUri);

    final expectedHash = md5.convert(utf8.encode(pdfUri.toString())).toString();
    expect(file.path, '${tempDir.path}/pdf_cache/$expectedHash.pdf');
  });
}
