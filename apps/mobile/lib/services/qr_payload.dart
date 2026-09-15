import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class KartaQr {
  static const labels = {
    'name': 'Nome',
    'nationality': 'Nacionalidade',
    'documentTitle': 'Título do documento',
    'documentType': 'Tipo do documento',
    'sha256': 'Impressão digital do ficheiro (SHA-256)',
    'issuer': 'Entidade declarada',
    'reference': 'Referência',
  };

  static String encode(Map<String, String> fields) {
    final raw = jsonEncode({
      'format': 'karta-share',
      'version': 1,
      'data': fields,
    });
    decode(raw);
    return raw;
  }

  static Map<String, String> decode(String raw) {
    if (utf8.encode(raw).length > 1800) {
      throw const FormatException('QR demasiado grande.');
    }
    final value = jsonDecode(raw);
    if (value is! Map ||
        value['format'] != 'karta-share' ||
        value['version'] != 1 ||
        value.keys.any((key) => !['format', 'version', 'data'].contains(key))) {
      throw const FormatException('Este não é um QR KARTA compatível.');
    }
    final data = value['data'];
    if (data is! Map || data.isEmpty || data.length > labels.length) {
      throw const FormatException('QR sem dados válidos.');
    }
    final fields = <String, String>{};
    for (final entry in data.entries) {
      if (!labels.containsKey(entry.key) || entry.value is! String) {
        throw const FormatException('Campo de QR não suportado.');
      }
      final text = entry.value as String;
      if (text.trim().isEmpty ||
          text.length > 160 ||
          RegExp(r'[\x00-\x1F\x7F]').hasMatch(text)) {
        throw const FormatException('Campo de QR inválido.');
      }
      if (entry.key == 'sha256' && !RegExp(r'^[a-f0-9]{64}$').hasMatch(text)) {
        throw const FormatException('Impressão digital inválida.');
      }
      fields[entry.key as String] = text;
    }
    return fields;
  }

  static Future<String> fingerprint(List<int> bytes) async {
    final hash = await Sha256().hash(bytes);
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

/// Classifies external QR content without treating it as a KARTA credential.
class QrReadResult {
  const QrReadResult({this.fields, this.text, this.error, this.isLink = false});
  final Map<String, String>? fields;
  final String? text;
  final String? error;
  final bool isLink;
  static QrReadResult parse(String raw) {
    final text = raw.trim().replaceFirst(RegExp(r'^\uFEFF'), '');
    if (text.isEmpty) {
      return const QrReadResult(error: 'O QR não contém texto legível.');
    }
    if (utf8.encode(text).length > 8192) {
      return const QrReadResult(
        error: 'O conteúdo excede o tamanho suportado.',
      );
    }
    dynamic json;
    try {
      json = jsonDecode(text);
    } catch (_) {
      /* Plain text is a valid external QR. */
    }
    if ((json is Map &&
            (json['format'] == 'karta-share' ||
                json.containsKey('version') && json.containsKey('data'))) ||
        text.contains('karta-share')) {
      try {
        return QrReadResult(fields: KartaQr.decode(text));
      } on FormatException catch (e) {
        return QrReadResult(error: e.message);
      }
    }
    if (RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]').hasMatch(text)) {
      return const QrReadResult(
        error: 'Este QR contém dados binários ou um formato não suportado.',
      );
    }
    final uri = Uri.tryParse(text);
    return QrReadResult(
      text: text,
      isLink:
          uri != null &&
          ['https', 'http'].contains(uri.scheme) &&
          uri.host.isNotEmpty,
    );
  }
}
