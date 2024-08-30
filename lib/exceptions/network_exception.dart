class NetworkException implements Exception {
  static const noInternetStatusCode = 0;
  static const noInternetMessage = 'Please check your internet connection';

  final String message;
  final int? statusCode;

  NetworkException(this.message, this.statusCode);
  factory NetworkException.noNetwork() {
    return NetworkException(noInternetMessage, noInternetStatusCode);
  }

  bool get hasNoInternet => statusCode == noInternetStatusCode;

  @override
  String toString() {
    return 'NetworkException: $message: $statusCode';
  }
}
