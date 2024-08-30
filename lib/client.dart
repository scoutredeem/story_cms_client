import 'models/page_model.dart';
import 'services/network_service.dart';

abstract class CMSClient {
  /// Fetches all the pages from the CMS
  ///
  /// [queryParameters] are the optional query parameters to be sent with the request
  Future<List<PageModel>> getPages(Map<String, String>? queryParameters);
}

class StoryCMSClient implements CMSClient {
  final NetworkService _networkService;

  final String baseUrl;
  StoryCMSClient(
    this._networkService, {
    required this.baseUrl,
  });

  @override
  Future<List<PageModel>> getPages(Map<String, String>? queryParameters) async {
    final uri = Uri.parse('$baseUrl/page')
      ..replace(queryParameters: queryParameters);

    final data = await _networkService.get(uri);
    return data['pages']
        .cast<Map<String, dynamic>>()
        .map<PageModel>(PageModel.fromMap)
        .toList();
  }
}
