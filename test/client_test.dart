import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:story_cms_client/client.dart';
import 'package:story_cms_client/models/locale_item_model.dart';
import 'package:story_cms_client/services/network_service.dart';

void main() {
  group('StoryCMSClient.getStrings', () {
    test(
      'hits /ui/v1/translation with locale as a query parameter and strips ARB metadata',
      () async {
        Uri? requestedUri;
        final mockClient = MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode({
              '@@locale': 'ar',
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
        expect(strings, {'welcomeMessage': 'Hi', 'loginButton': 'Log in'});
      },
    );

    test('returns an empty map when the response body is empty', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({}), 200);
      });

      final client = StoryCMSClient(
        NetworkService(mockClient),
        baseUrl: 'https://example.com/api/v1',
      );

      final strings = await client.getStrings(locale: 'en');

      expect(strings, <String, String>{});
    });
  });

  group('StoryCMSClient.getLocales', () {
    test('parses the app array into LocaleItems', () async {
      Uri? requestedUri;
      final mockClient = MockClient((request) async {
        requestedUri = request.url;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'content': [
                {
                  'locale': 'en',
                  'stories': ['classic'],
                },
              ],
              'app': [
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

      final locales = await client.getLocales();

      expect(requestedUri?.path, '/api/v1/locale');
      expect(locales, [
        LocaleItem(
          locale: 'en',
          name: 'English',
          nativeName: 'English',
          languageDirection: LanguageDirection.ltr,
        ),
        LocaleItem(
          locale: 'ar',
          name: 'Arabic',
          nativeName: 'العربية',
          languageDirection: LanguageDirection.rtl,
        ),
      ]);
    });
  });
}
