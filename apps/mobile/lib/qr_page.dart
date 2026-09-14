import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'brand_theme.dart';
import 'pdf_viewer_page.dart';
import 'services/qr_payload.dart';
import 'services/session_store.dart';

class QrHubPage extends StatelessWidget {
  const QrHubPage({super.key});
  Future<void> _profile(BuildContext context) async {
    try {
      final fields = await SessionStore().readProfile();
      if (!context.mounted) return;
      if (fields.values.every((s) => s.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha o perfil em Definições antes de gerar o QR.')));
        return;
      }
      await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => QrSharePage(fields: fields)));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível carregar o perfil.')));
      }
    }
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('QR KARTA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
    const SizedBox(height: 16),
    const Text('Partilhe apenas os dados que escolher. Para criar um QR de documento ou credencial, abra o respectivo registo.'),
    const SizedBox(height: 20),
    FilledButton.icon(onPressed: () => _profile(context), icon: const Icon(Icons.qr_code), label: const Text('Gerar QR do perfil')),
    const SizedBox(height: 12),
    OutlinedButton.icon(onPressed: () => Navigator.push<void>(context, MaterialPageRoute(builder: (_) => const QrScanPage())),
      icon: const Icon(Icons.qr_code_scanner), label: const Text('Ler QR pela câmara ou imagem')),
    const SizedBox(height: 20),
    const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Os QR desta Alpha contêm dados declarados pelo utilizador. A leitura não comprova a identidade nem a autenticidade de documentos.'))),
  ]);
}

class QrSharePage extends StatefulWidget {
  const QrSharePage({super.key, required this.fields});
  final Map<String, String> fields;
  @override
  State<QrSharePage> createState() => _QrSharePageState();
}

class _QrSharePageState extends State<QrSharePage> {
  final selected = <String>{};
  final imageKey = GlobalKey();
  String? payload;
  bool busy = false;

  void _generate() {
    try {
      final data = KartaQr.encode({for (final key in selected) key: widget.fields[key]!});
      setState(() => payload = data);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escolha dados válidos para partilhar. Campos demasiado longos devem ser reduzidos.')));
    }
  }

  Future<void> _saveImage() async {
    setState(() => busy = true);
    try {
      final boundary = imageKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) throw StateError('Imagem indisponível');
      final saved = await documentChannel.invokeMethod<bool>('exportFile', {
        'bytes': bytes.buffer.asUint8List(), 'name': 'karta-qr.png', 'mime': 'image/png',
      });
      if (mounted && saved == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR guardado.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível guardar o QR.')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Partilhar por QR')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Escolha o que será visível', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      const Text('Qualquer pessoa que leia ou fotografe o QR poderá conservar os dados seleccionados. O QR não inclui o PDF nem a imagem original.'),
      for (final entry in widget.fields.entries.where((e) => KartaQr.labels.containsKey(e.key) && e.value.trim().isNotEmpty))
        CheckboxListTile(
          title: Text(KartaQr.labels[entry.key]!), subtitle: Text(entry.value),
          value: selected.contains(entry.key),
          onChanged: busy ? null : (value) => setState(() {
            if (value == true) { selected.add(entry.key); } else { selected.remove(entry.key); }
            payload = null;
          }),
        ),
      FilledButton(onPressed: selected.isEmpty || busy ? null : _generate, child: const Text('Gerar QR')),
      if (payload != null) ...[
        const SizedBox(height: 20),
        Center(child: RepaintBoundary(key: imageKey, child: Container(
          color: Colors.white, padding: const EdgeInsets.all(16),
          child: QrImageView(data: payload!, size: 220, backgroundColor: Colors.white, padding: const EdgeInsets.all(16)),
        ))),
        const SizedBox(height: 12),
        const Text('KARTA · Um produto HMATIAS', textAlign: TextAlign.center, style: TextStyle(color: HmatiasBrand.navy)),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: busy ? null : _saveImage, icon: const Icon(Icons.download_outlined), label: const Text('Guardar imagem QR')),
      ],
    ]),
  );
}

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});
  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool reading = true;
  bool busy = false;
  Map<String, String>? fields;
  String? error;
  String? comparison;

  void _decode(String raw) {
    try {
      final result = KartaQr.decode(raw);
      setState(() { reading = false; fields = result; error = null; comparison = null; });
    } catch (_) {
      setState(() { reading = false; fields = null; error = 'QR inválido ou incompatível com a KARTA. Nenhuma ligação foi aberta.'; });
    }
  }

  Future<void> _gallery() async {
    if (busy) return;
    setState(() { busy = true; reading = false; fields = null; error = null; comparison = null; });
    final controller = MobileScannerController(autoStart: false);
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final capture = await controller.analyzeImage(image.path);
      if (!mounted) return;
      final codes = capture?.barcodes.where((b) => b.rawValue != null).toList() ?? [];
      if (codes.isEmpty) {
        setState(() => error = 'Não foi encontrado um QR nesta imagem.');
      } else {
        _decode(codes.first.rawValue!);
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Não foi possível ler a imagem.');
    } finally {
      await controller.dispose();
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _compare() async {
    setState(() => busy = true);
    try {
      final file = await openFile();
      if (file == null) return;
      final digest = await KartaQr.fingerprint(await file.readAsBytes());
      if (!mounted) return;
      setState(() => comparison = digest == fields!['sha256']
        ? 'O ficheiro corresponde à impressão digital do QR. Isto não comprova a sua origem nem a identidade do titular.'
        : 'O ficheiro é diferente do identificado neste QR.');
    } catch (_) {
      if (mounted) setState(() => comparison = 'Não foi possível comparar o ficheiro.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ler QR KARTA')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      if (reading) SizedBox(height: 300, child: MobileScanner(
        onDetect: (capture) {
          if (!reading || busy) return;
          for (final barcode in capture.barcodes) {
            if (barcode.rawValue != null) { _decode(barcode.rawValue!); break; }
          }
        },
        errorBuilder: (context, error) => const Center(child: Padding(padding: EdgeInsets.all(20),
          child: Text('Câmara indisponível. Verifique a permissão nas definições do Android ou seleccione uma imagem.'))),
      )),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: busy ? null : _gallery, icon: const Icon(Icons.image_outlined), label: const Text('Ler QR de uma imagem')),
      OutlinedButton.icon(onPressed: busy ? null : () => setState(() { reading = true; fields = null; error = null; comparison = null; }),
        icon: const Icon(Icons.qr_code_scanner), label: const Text('Ler outro QR')),
      if (busy) const LinearProgressIndicator(),
      if (error != null) Text(error!),
      if (fields != null) ...[
        const Chip(label: Text('DADOS DECLARADOS · NÃO VERIFICADOS')),
        for (final entry in fields!.entries)
          ListTile(title: Text(KartaQr.labels[entry.key]!), subtitle: SelectableText(entry.value)),
        if (fields!.containsKey('sha256'))
          FilledButton(onPressed: busy ? null : _compare, child: const Text('Comparar com um ficheiro')),
        if (comparison != null) Text(comparison!),
        const SizedBox(height: 12),
        const Text('Estes dados não têm assinatura de uma entidade emissora. Um QR legível não é prova de identidade.'),
      ],
    ]),
  );
}
