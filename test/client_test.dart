import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:story_cms_client/client.dart';
import 'package:story_cms_client/models/locale_catalog_model.dart';
import 'package:story_cms_client/services/network_service.dart';

void main() {
  group('StoryCMSClient.getStrings', () {
    test('hits /ui/v1/translation with locale as a query parameter, strips ARB '
        'metadata but keeps @@locale', () async {
      Uri? requestedUri;
      final mockClient = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            '@@locale': 'ar',
            '@welcomeMessage': {'description': 'greeting'},
            'welcomeMessage': 'Hi',
            'loginButton': 'Log in',
          }),
          200,
        );
      });

      final client = StoryCMSClient(
        NetworkService(mockClient),
        baseUrl: 'https://example.com/api/v1',
      );

      final strings = await client.getStrings(locale: 'ar');

      expect(requestedUri?.path, '/ui/v1/translation');
      expect(requestedUri?.queryParameters, {'locale': 'ar'});
      expect(strings, {
        '@@locale': 'ar',
        'welcomeMessage': 'Hi',
        'loginButton': 'Log in',
      });
    });

    test('returns an empty map when the response body is empty', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({}), 200);
      });

      final client = StoryCMSClient(
        NetworkService(mockClient),
        baseUrl: 'https://example.com/api/v1',
      );

      final strings = await client.getStrings(locale: 'fr');

      expect(strings, <String, String>{});
    });

    test('throws UnimplementedError for locale "en" without hitting the '
        'network - the CMS has no override endpoint data for the ARB '
        'baseline language', () async {
      final mockClient = MockClient((request) async {
        fail('should not make a network request for locale "en"');
      });

      final client = StoryCMSClient(
        NetworkService(mockClient),
        baseUrl: 'https://example.com/api/v1',
      );

      expect(
        () => client.getStrings(locale: 'en'),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  group('StoryCMSClient.getLocales', () {
    test(
      'parses the languages, content, app and media arrays independently',
      () async {
        Uri? requestedUri;
        final mockClient = MockClient((request) async {
          requestedUri = request.url;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'languages': [
                  {
                    'locale': 'en',
                    'name': 'English',
                    'nativeName': 'English',
                    'languageDirection': 'ltr',
                  },
                  {
                    'locale': 'ar',
                    'name': 'Arabic',
                    'nativeName': 'العربية',
                    'languageDirection': 'rtl',
                  },
                ],
                'content': [
                  {
                    'locale': 'en',
                    'stories': ['classic', 'express', 'youth'],
                  },
                  {
                    'locale': 'de',
                    'stories': ['classic'],
                  },
                ],
                'app': ['en'],
                'media': ['en'],
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final client = StoryCMSClient(
          NetworkService(mockClient),
          baseUrl: 'https://example.com/api/v1',
        );

        final catalog = await client.getLocales();

        expect(requestedUri?.path, '/api/v1/locale');
        expect(catalog.languages, [
          AppLocale(
            locale: 'en',
            name: 'English',
            nativeName: 'English',
            languageDirection: LanguageDirection.ltr,
          ),
          AppLocale(
            locale: 'ar',
            name: 'Arabic',
            nativeName: 'العربية',
            languageDirection: LanguageDirection.rtl,
          ),
        ]);
        expect(catalog.content, [
          ContentLocale(
            locale: 'en',
            stories: ['classic', 'express', 'youth'],
          ),
          ContentLocale(locale: 'de', stories: ['classic']),
        ]);
        expect(catalog.app, ['en']);
        expect(catalog.media, ['en']);
      },
    );

    test('missing languages/content/app/media arrays parse as empty lists', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({}), 200);
      });

      final client = StoryCMSClient(
        NetworkService(mockClient),
        baseUrl: 'https://example.com/api/v1',
      );

      final catalog = await client.getLocales();

      expect(catalog.languages, <AppLocale>[]);
      expect(catalog.content, <ContentLocale>[]);
      expect(catalog.app, <String>[]);
      expect(catalog.media, <String>[]);
    });
  });
}
