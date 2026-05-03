import 'package:http/http.dart' as http;

/// Check network connectivity
class NetworkInfo {
  final http.Client httpClient;

  NetworkInfo({http.Client? client}) : httpClient = client ?? http.Client();

  Future<bool> get isConnected async {
    try {
      final response = await httpClient.get(
        Uri.parse('https://www.google.com/generate_204'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
