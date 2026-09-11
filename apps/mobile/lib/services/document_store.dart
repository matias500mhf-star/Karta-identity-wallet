import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class VaultDocument {
  const VaultDocument({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.frontFile,
    this.backFile,
    this.attachmentFile,
    this.attachmentName,
    this.attachmentMime,
  });

  final String id;
  final String type;
  final String title;
  final DateTime createdAt;
  final String? frontFile;
  final String? backFile;
  final String? attachmentFile;
  final String? attachmentName;
  final String? attachmentMime;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'frontFile': frontFile,
        'backFile': backFile,
        'attachmentFile': attachmentFile,
        'attachmentName': attachmentName,
        'attachmentMime': attachmentMime,
      };

  factory VaultDocument.fromJson(Map<String, dynamic> json) => VaultDocument(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'Documento',
        title: json['title']?.toString() ?? 'Documento',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        frontFile: json['frontFile']?.toString(),
        backFile: json['backFile']?.toString(),
        attachmentFile: json['attachmentFile']?.toString(),
        attachmentName: json['attachmentName']?.toString(),
        attachmentMime: json['attachmentMime']?.toString(),
      );
}

class DocumentStore {
  static const _indexKey = 'karta.document_vault.index.v1';
  static const _keyKey = 'karta.document_vault.key.v1';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  final AesGcm _cipher = AesGcm.with256bits();

  Future<List<VaultDocument>> list() async {
    final raw = await _secure.read(key: _indexKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final items = decoded
          .whereType<Map>()
          .map((e) => VaultDocument.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (_) {
      return [];
    }
  }

  Future<VaultDocument> add({
    required String type,
    required String title,
    Uint8List? frontBytes,
    Uint8List? backBytes,
    Uint8List? attachmentBytes,
    String? attachmentName,
    String? attachmentMime,
  }) async {
    if (frontBytes == null && backBytes == null && attachmentBytes == null) {
      throw ArgumentError('At least one document file is required.');
    }
    final now = DateTime.now().toUtc();
    final id = now.microsecondsSinceEpoch.toString();
    final front = frontBytes == null ? null : await _writeEncrypted('$id-front.karta', frontBytes);
    final back = backBytes == null ? null : await _writeEncrypted('$id-back.karta', backBytes);
    final attachment = attachmentBytes == null
        ? null
        : await _writeEncrypted('$id-attachment.karta', attachmentBytes);

    final item = VaultDocument(
      id: id,
      type: type.trim(),
      title: title.trim().isEmpty ? type.trim() : title.trim(),
      createdAt: now,
      frontFile: front,
      backFile: back,
      attachmentFile: attachment,
      attachmentName: attachmentName,
      attachmentMime: attachmentMime,
    );
    final items = await list();
    items.insert(0, item);
    await _writeIndex(items);
    return item;
  }

  Future<Uint8List> readEncrypted(String fileName) async {
    final dir = await _vaultDir();
    final packed = await File('${dir.path}/$fileName').readAsBytes();
    final decoded = jsonDecode(utf8.decode(packed)) as Map<String, dynamic>;
    final key = await _key();
    final box = SecretBox(
      base64Decode(decoded['cipherText'] as String),
      nonce: base64Decode(decoded['nonce'] as String),
      mac: Mac(base64Decode(decoded['mac'] as String)),
    );
    final clear = await _cipher.decrypt(box, secretKey: key);
    return Uint8List.fromList(clear);
  }

  Future<void> remove(VaultDocument item) async {
    final dir = await _vaultDir();
    for (final name in [item.frontFile, item.backFile, item.attachmentFile]) {
      if (name == null) continue;
      final file = File('${dir.path}/$name');
      if (await file.exists()) await file.delete();
    }
    final items = await list()..removeWhere((e) => e.id == item.id);
    await _writeIndex(items);
  }

  Future<void> clear() async {
    final dir = await _vaultDir();
    if (await dir.exists()) await dir.delete(recursive: true);
    await _secure.delete(key: _indexKey);
    await _secure.delete(key: _keyKey);
  }

  Future<String> _writeEncrypted(String fileName, Uint8List bytes) async {
    final dir = await _vaultDir();
    final key = await _key();
    final nonce = List<int>.generate(12, (_) => Random.secure().nextInt(256));
    final box = await _cipher.encrypt(bytes, secretKey: key, nonce: nonce);
    final packed = utf8.encode(jsonEncode({
      'cipherText': base64Encode(box.cipherText),
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
    }));
    await File('${dir.path}/$fileName').writeAsBytes(packed, flush: true);
    return fileName;
  }

  Future<SecretKey> _key() async {
    final existing = await _secure.read(key: _keyKey);
    if (existing != null && existing.isNotEmpty) {
      return SecretKey(base64Decode(existing));
    }
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    await _secure.write(key: _keyKey, value: base64Encode(bytes));
    return SecretKey(bytes);
  }

  Future<Directory> _vaultDir() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/karta_vault');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _writeIndex(List<VaultDocument> items) => _secure.write(
        key: _indexKey,
        value: jsonEncode(items.map((e) => e.toJson()).toList()),
      );
}
