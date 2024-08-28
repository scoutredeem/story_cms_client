import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../exceptions/network_exception.dart';

extension ResponseX on http.Response {
  bool get isOk {
    return (statusCode ~/ 100) == 2;
  }
}

class NetworkService {
  static const defaultTimeout = Duration(seconds: 20);
  static const noInternetStatusCode = 0;
  static const noInternetMessage = 'Please check your internet connection';

  final http.Client client;
  NetworkService(this.client);

  /// Makes a GET request to the given endpoint
  Future<Map<String, dynamic>> get(Uri uri,
      {Map<String, String>? headers}) async {
    log('GET request to $uri');
    try {
      final response =
          await client.get(uri, headers: headers).timeout(defaultTimeout);
      if (response.isOk) {
        return jsonDecode(response.body);
      } else {
        throw NetworkException(response.body, response.statusCode);
      }
    } catch (e) {
      log('Error in GET request to ${uri.toString()}: $e');
      // check if the error is network exception
      if (e.toString().contains('Failed host lookup')) {
        throw NetworkException(noInternetMessage, noInternetStatusCode);
      }
      rethrow;
    }
  }

  /// Makes a POST request to the given endpoint
  Future<Map<String, dynamic>> post(Uri uri,
      {Map<String, String>? headers, String? body}) async {
    log('POST request to $uri');
    try {
      final response = await client
          .post(uri, headers: headers, body: body)
          .timeout(defaultTimeout);
      if (response.isOk) {
        return jsonDecode(response.body);
      } else {
        throw NetworkException(response.body, response.statusCode);
      }
    } catch (e) {
      log('Error in POST request to ${uri.toString()}: $e');
      // check if the error is network exception
      if (e.toString().contains('Failed host lookup')) {
        throw NetworkException(noInternetMessage, noInternetStatusCode);
      }
      rethrow;
    }
  }
}
