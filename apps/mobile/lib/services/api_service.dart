import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  ApiService({this.baseUrl = const String.fromEnvironment('KARTA_API_URL', defaultValue: 'http://10.0.2.2:3000')});
  final String baseUrl;
  String? accessToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Future<dynamic> _request(String method, String path, {Map<String, dynamic>? body}) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'))..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Client().send(request);
    final text = await response.stream.bytesToString();
    dynamic decoded;
    if (text.isNotEmpty) {
      try { decoded = jsonDecode(text); } catch (_) { decoded = null; }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map && decoded['message'] != null ? decoded['message'].toString() : 'Request failed (${response.statusCode})';
      throw ApiException(message);
    }
    return decoded;
  }

  Future<Map<String, dynamic>> login(String email, String password) async => Map<String, dynamic>.from(await _request('POST', '/auth/login', body: {'email': email, 'password': password}));
  Future<Map<String, dynamic>> register(String email, String password) async => Map<String, dynamic>.from(await _request('POST', '/auth/register', body: {'email': email, 'password': password}));
  Future<Map<String, dynamic>> me() async => Map<String, dynamic>.from(await _request('GET', '/me'));
  Future<List<Map<String, dynamic>>> documents() async {
    final raw = await _request('GET', '/documents');
    if (raw is List) return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (raw is Map && raw['data'] is List) return (raw['data'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    return [];
  }
}
