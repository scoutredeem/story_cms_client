import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../exceptions/network_exception.dart';

class NetworkService {
  static const defaultTimeout = Duration(seconds: 20);

  final http.Client client;
  NetworkService(this.client);

  /// Makes a GET request to the given endpoint
  Future<Map<String, dynamic>> get(Uri uri,
      {Map<String, String>? headers}) async {
    log('GET request to $uri');
    try {
      final response =
          await client.get(uri, headers: headers).timeout(defaultTimeout);
      return _getBody(response);
    } catch (e) {
      log('Error in GET request to ${uri.toString()}: $e');
      // check if the error is network exception
      if (e.toString().contains('Failed host lookup')) {
        throw NetworkException.noNetwork();
      }
      rethrow;
    }
  }

  Map<String, dynamic> _getBody(http.Response response) {
    if (!response.isOk) {
      throw NetworkException(response.body, response.statusCode);
    }

    if (response.body.isEmpty) return {};

    final body = jsonDecode(response.body);
    if (body is List) return {'data': body};

    return body as Map<String, dynamic>;
  }
}

extension ResponseX on http.Response {
  bool get isOk {
    return (statusCode ~/ 100) == 2;
  }
}
