import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

enum DocumentExpiryState { unknown, valid, expiringSoon, expired }

class VaultDocument {
  const VaultDocument({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.issuedAt,
    this.expiresAt,
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
  final DateTime? issuedAt;
  final DateTime? expiresAt;
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
        'issuedAt': issuedAt?.toUtc().toIso8601String(),
        'expiresAt': expiresAt?.toUtc().toIso8601String(),
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
        issuedAt: DateTime.tryParse(json['issuedAt']?.toString() ?? '')?.toUtc(),
        expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '')?.toUtc(),
        frontFile: json['frontFile']?.toString(),
        backFile: json['backFile']?.toString(),
        attachmentFile: json['attachmentFile']?.toString(),
        attachmentName: json['attachmentName']?.toString(),
        attachmentMime: json['attachmentMime']?.toString(),
      );

  DocumentExpiryState expiryState({DateTime? now, int warningDays = 90}) {
    if (expiresAt == null) return DocumentExpiryState.unknown;
    final today = _dateOnlyUtc(now ?? DateTime.now());
    final expiry = _dateOnlyUtc(expiresAt!);
    if (expiry.isBefore(today)) return DocumentExpiryState.expired;
    final days = expiry.difference(today).inDays;
    return days <= warningDays
        ? DocumentExpiryState.expiringSoon
        : DocumentExpiryState.valid;
  }

  int? daysUntilExpiry({DateTime? now}) {
    if (expiresAt == null) return null;
    final today = _dateOnlyUtc(now ?? DateTime.now());
    final expiry = _dateOnlyUtc(expiresAt!);
    return expiry.difference(today).inDays;
  }

  static DateTime _dateOnlyUtc(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
}

class DocumentStore {
  DocumentStore({this.directory});

  static const _indexKey = 'karta.document_vault.index.v1';
  static const _keyKey = 'karta.document_vault.key.v1';
  static const _pendingDeleteKey = 'karta.document_vault.pending_delete.v1';

  final Directory? directory;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  final AesGcm _cipher = AesGcm.with256bits();
  bool _indexCorrupted = false;

  Future<List<VaultDocument>> list() async {
    await _recoverPendingDelete();
    return _readIndex();
  }

  Future<List<VaultDocument>> _readIndex() async {
    final raw = await _secure.read(key: _indexKey);
    if (raw == null || raw.isEmpty) {
      _indexCorrupted = false;
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.any((entry) => entry is! Map)) {
        _indexCorrupted = true;
        return [];
      }
      final items = decoded
          .map((e) => VaultDocument.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (items.any((item) => item.id.isEmpty)) {
        _indexCorrupted = true;
        return [];
      }
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _indexCorrupted = false;
      return items;
    } catch (_) {
      _indexCorrupted = true;
      return [];
    }
  }

  Never _throwCorruptIndex() => throw StateError(
        'O índice seguro de documentos está inválido. Não foram alterados dados; restaure um backup válido antes de adicionar ou apagar documentos.',
      );

  Future<VaultDocument> add({
    required String type,
    required String title,
    DateTime? issuedAt,
    DateTime? expiresAt,
    Uint8List? frontBytes,
    Uint8List? backBytes,
    Uint8List? attachmentBytes,
    String? attachmentName,
    String? attachmentMime,
  }) async {
    if (frontBytes == null && backBytes == null && attachmentBytes == null) {
      throw ArgumentError('At least one document file is required.');
    }
    final normalizedIssuedAt = issuedAt == null
        ? null
        : DateTime.utc(issuedAt.year, issuedAt.month, issuedAt.day);
    final normalizedExpiresAt = expiresAt == null
        ? null
        : DateTime.utc(expiresAt.year, expiresAt.month, expiresAt.day);
    if (normalizedIssuedAt != null &&
        normalizedExpiresAt != null &&
        normalizedExpiresAt.isBefore(normalizedIssuedAt)) {
      throw ArgumentError('Expiry date cannot be before issue date.');
    }

    final items = await list();
    if (_indexCorrupted) _throwCorruptIndex();

    final now = DateTime.now().toUtc();
    final id = now.microsecondsSinceEpoch.toString();
    final front = frontBytes == null
        ? null
        : await _writeEncrypted('$id-front.karta', frontBytes);
    final back = backBytes == null
        ? null
        : await _writeEncrypted('$id-back.karta', backBytes);
    final attachment = attachmentBytes == null
        ? null
        : await _writeEncrypted('$id-attachment.karta', attachmentBytes);

    final item = VaultDocument(
      id: id,
      type: type.trim(),
      title: title.trim().isEmpty ? type.trim() : title.trim(),
      createdAt: now,
      issuedAt: normalizedIssuedAt,
      expiresAt: normalizedExpiresAt,
      frontFile: front,
      backFile: back,
      attachmentFile: attachment,
      attachmentName: attachmentName,
      attachmentMime: attachmentMime,
    );
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
    await _recoverPendingDelete();
    final items = await _readIndex();
    if (_indexCorrupted) _throwCorruptIndex();
    if (!items.any((document) => document.id == item.id)) return;

    final files = [item.frontFile, item.backFile, item.attachmentFile]
        .whereType<String>()
        .where(_safeFileName)
        .toSet()
        .toList();
    await _secure.write(
      key: _pendingDeleteKey,
      value: jsonEncode({'id': item.id, 'files': files}),
    );

    items.removeWhere((document) => document.id == item.id);
    try {
      await _writeIndex(items);
    } catch (_) {
      await _secure.delete(key: _pendingDeleteKey);
      rethrow;
    }

    try {
      await _deleteFiles(files);
      await _secure.delete(key: _pendingDeleteKey);
    } catch (_) {
      // The index deletion is already committed. Keep the marker so a later
      // list/open cycle can finish deleting any encrypted orphan files.
    }
  }

  Future<void> clear() async {
    final dir = await _vaultDir();
    if (await dir.exists()) await dir.delete(recursive: true);
    await _secure.delete(key: _indexKey);
    await _secure.delete(key: _keyKey);
    await _secure.delete(key: _pendingDeleteKey);
    _indexCorrupted = false;
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
    final root = directory ?? await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/karta_vault');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _deleteFiles(Iterable<String> fileNames) async {
    final dir = await _vaultDir();
    for (final name in fileNames) {
      if (!_safeFileName(name)) continue;
      final file = File('${dir.path}/$name');
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _recoverPendingDelete() async {
    final pendingRaw = await _secure.read(key: _pendingDeleteKey);
    if (pendingRaw == null || pendingRaw.isEmpty) return;
    try {
      final pending = jsonDecode(pendingRaw);
      if (pending is! Map) {
        await _secure.delete(key: _pendingDeleteKey);
        return;
      }
      final id = pending['id']?.toString() ?? '';
      final rawFiles = pending['files'];
      if (id.isEmpty || rawFiles is! List) {
        await _secure.delete(key: _pendingDeleteKey);
        return;
      }
      final files = rawFiles
          .whereType<String>()
          .where(_safeFileName)
          .toSet()
          .toList();
      if (files.length != rawFiles.length) {
        await _secure.delete(key: _pendingDeleteKey);
        return;
      }

      final indexRaw = await _secure.read(key: _indexKey);
      if (indexRaw == null || indexRaw.isEmpty) return;
      final decoded = jsonDecode(indexRaw);
      if (decoded is! List) return;
      final stillIndexed = decoded.whereType<Map>().any(
            (document) => document['id']?.toString() == id,
          );
      if (stillIndexed) {
        // The app stopped before the index commit; no files were deleted yet.
        await _secure.delete(key: _pendingDeleteKey);
        return;
      }
      await _deleteFiles(files);
      await _secure.delete(key: _pendingDeleteKey);
    } catch (_) {
      // Keep a valid-looking pending marker for a later safe retry. Never
      // delete files when the index cannot be parsed confidently.
    }
  }

  static bool _safeFileName(String name) =>
      RegExp(r'^[a-zA-Z0-9_-]+\.karta$').hasMatch(name);

  Future<void> _writeIndex(List<VaultDocument> items) => _secure.write(
        key: _indexKey,
        value: jsonEncode(items.map((e) => e.toJson()).toList()),
      );
}
