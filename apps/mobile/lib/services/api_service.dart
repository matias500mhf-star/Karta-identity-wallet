import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'backup_store.dart';
import 'qr_payload.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiService {
  ApiService({String? baseUrl, http.Client? client})
    : baseUrl = (baseUrl ?? const String.fromEnvironment('KARTA_API_URL'))
          .replaceFirst(RegExp(r'/+$'), ''),
      _client = client ?? http.Client();
  final String baseUrl;
  final http.Client _client;
  String? accessToken;
  bool get configured => baseUrl.isNotEmpty;
  Uri _url(String path) {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const ApiException('O serviço online ainda não está configurado.');
    }
    return Uri.parse('$baseUrl$path');
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? json,
    Uint8List? bytes,
    String? invite,
  }) async {
    final req = http.Request(method, _url(path))..followRedirects = false;
    req.headers['Accept'] = 'application/json';
    if (accessToken != null) {
      req.headers['Authorization'] = 'Bearer $accessToken';
    }
    if (invite != null) req.headers['X-Karta-Invite'] = invite;
    if (bytes != null) {
      req.headers['Content-Type'] = 'application/octet-stream';
      req.bodyBytes = bytes;
    } else if (json != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(json);
    }
    try {
      final streamed = await _client
          .send(req)
          .timeout(const Duration(seconds: 90));
      final max = path == '/backups/latest' && method == 'GET'
          ? BackupCodec.maxBytes
          : 65536;
      final out = BytesBuilder(copy: false);
      var size = 0;
      await (() async {
        await for (final chunk in streamed.stream) {
          size += chunk.length;
          if (size > max) {
            throw const ApiException('A resposta excede o tamanho permitido.');
          }
          out.add(chunk);
        }
      })().timeout(const Duration(seconds: 90));
      final response = http.Response.bytes(
        out.takeBytes(),
        streamed.statusCode,
        headers: streamed.headers,
      );
      if (response.statusCode == 401) {
        accessToken = null;
        throw const ApiException(
          'Sessão expirada ou dados de acesso incorretos. Entre novamente.',
        );
      }
      if (response.statusCode == 403) {
        throw const ApiException(
          'Registo limitado a convites da beta. Confirme o código.',
        );
      }
      if (response.statusCode == 409) {
        throw const ApiException(
          'Não foi possível criar a conta com estes dados.',
        );
      }
      if (response.statusCode == 404) {
        throw const ApiException('Ainda não existe backup nesta conta.');
      }
      if (response.statusCode == 429) {
        throw const ApiException('Demasiadas tentativas. Aguarde um minuto.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ApiException(
          'O servidor não concluiu a operação. Tente novamente.',
        );
      }
      return response;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Não foi possível comunicar com o servidor. A carteira local continua disponível.',
      );
    }
  }

  Future<void> register(String email, String password, String invite) async {
    await _request(
      'POST',
      '/auth/register',
      json: {'email': email.trim(), 'password': password},
      invite: invite,
    );
  }

  Future<void> login(String email, String password) async {
    final r = await _request(
      'POST',
      '/auth/login',
      json: {'email': email.trim(), 'password': password},
    );
    final token = (jsonDecode(r.body) as Map)['accessToken'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('Resposta de autenticação inválida.');
    }
    accessToken = token;
  }

  Future<Map<String, dynamic>?> metadata() async {
    final r = await _request('GET', '/backups/latest/metadata');
    if (r.body.isEmpty || r.body == 'null') return null;
    return Map<String, dynamic>.from(jsonDecode(r.body) as Map);
  }

  Future<void> upload(Uint8List bytes) async {
    if (bytes.length > BackupCodec.maxBytes) {
      throw const ApiException('Backup demasiado grande.');
    }
    final r = await _request('PUT', '/backups/latest', bytes: bytes);
    final meta = jsonDecode(r.body) as Map;
    if (meta['digest'] != await KartaQr.fingerprint(bytes) ||
        meta['size'] != bytes.length) {
      throw const ApiException(
        'Não foi possível confirmar a integridade do backup enviado.',
      );
    }
  }

  Future<Uint8List> download() async {
    final r = await _request('GET', '/backups/latest');
    if (r.headers['x-content-sha256'] !=
        await KartaQr.fingerprint(r.bodyBytes)) {
      throw const ApiException(
        'A transferência do backup está incompleta ou danificada.',
      );
    }
    return r.bodyBytes;
  }

  Future<void> deleteBackup() async {
    await _request('DELETE', '/backups/latest');
  }

  Future<void> deleteAccount(String password) async {
    await _request('DELETE', '/auth/account', json: {'password': password});
    accessToken = null;
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/auth/logout');
    } finally {
      accessToken = null;
    }
  }

  void close() {
    accessToken = null;
    _client.close();
  }
}
