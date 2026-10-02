import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalCredential {
  const LocalCredential({
    required this.id,
    required this.type,
    required this.issuer,
    required this.reference,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String issuer;
  final String reference;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'issuer': issuer,
        'reference': reference,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory LocalCredential.fromJson(Map<String, dynamic> json) {
    return LocalCredential(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Credencial',
      issuer: json['issuer']?.toString() ?? 'Emissor não indicado',
      reference: json['reference']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class CredentialStore {
  static const _credentialsKey = 'karta.local_credentials.v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<LocalCredential>> list() async {
    final raw = await _storage.read(key: _credentialsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.any((entry) => entry is! Map)) {
        throw const FormatException('Invalid credential index.');
      }
      final credentials = decoded
          .map(
            (item) => LocalCredential.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
      if (credentials.any((item) => item.id.isEmpty)) {
        throw const FormatException('Invalid credential entry.');
      }
      credentials.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return credentials;
    } on FormatException {
      throw StateError(
        'O índice seguro de credenciais está inválido. Nenhum registo foi alterado; restaure um backup válido antes de adicionar ou remover credenciais.',
      );
    }
  }

  Future<LocalCredential> add({
    required String type,
    required String issuer,
    required String reference,
  }) async {
    final now = DateTime.now().toUtc();
    final credential = LocalCredential(
      id: '${now.microsecondsSinceEpoch}',
      type: type.trim(),
      issuer: issuer.trim(),
      reference: reference.trim(),
      createdAt: now,
    );

    final credentials = await list();
    credentials.insert(0, credential);
    await _write(credentials);
    return credential;
  }

  Future<void> remove(String id) async {
    final credentials = await list();
    credentials.removeWhere((credential) => credential.id == id);
    await _write(credentials);
  }

  Future<void> clear() => _storage.delete(key: _credentialsKey);

  Future<void> _write(List<LocalCredential> credentials) {
    return _storage.write(
      key: _credentialsKey,
      value: jsonEncode(credentials.map((item) => item.toJson()).toList()),
    );
  }
}
