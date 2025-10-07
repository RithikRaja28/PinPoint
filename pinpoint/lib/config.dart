import 'package:flutter_dotenv/flutter_dotenv.dart';

// Declare a top-level constant (read once, available globally)
final String apiUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:5000';

String buildApiUrl(String path) {
  // ensure no double slashes
  final base = apiUrl.endsWith('/')
      ? apiUrl.substring(0, apiUrl.length - 1)
      : apiUrl;
  final p = path.startsWith('/') ? path.substring(1) : path;
  return '$base/$p';
}
