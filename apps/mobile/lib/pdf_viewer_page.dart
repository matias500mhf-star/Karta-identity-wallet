import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const documentChannel = MethodChannel('karta/documents');

class PdfViewerPage extends StatefulWidget {
  const PdfViewerPage({super.key, required this.bytes, required this.title});
  final Uint8List bytes;
  final String title;
  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  int pages = 0;
  int page = 0;
  bool busy = true;
  String? error;
  Uint8List? image;
  final transform = TransformationController();

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      pages = await documentChannel.invokeMethod<int>('openPdf', {'bytes': widget.bytes}) ?? 0;
      if (pages == 0) throw StateError('PDF sem páginas');
      if (mounted) await _render(0);
    } catch (_) {
      if (mounted) setState(() {
        busy = false;
        error = 'Não foi possível abrir o PDF. Pode estar danificado ou protegido por palavra-passe.';
      });
    }
  }

  Future<void> _render(int index) async {
    setState(() { busy = true; error = null; });
    try {
      final bytes = await documentChannel.invokeMethod<Uint8List>('renderPdf', {'page': index});
      if (bytes == null) throw StateError('Página indisponível');
      if (!mounted) return;
      transform.value = Matrix4.identity();
      setState(() { image = bytes; page = index; busy = false; });
    } catch (_) {
      if (mounted) setState(() { busy = false; error = 'Não foi possível apresentar esta página.'; });
    }
  }

  @override
  void dispose() {
    documentChannel.invokeMethod<void>('closePdf').catchError((Object _) {});
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: busy ? const Center(child: CircularProgressIndicator())
        : error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!)))
        : InteractiveViewer(
            transformationController: transform, maxScale: 5,
            child: Center(child: Image.memory(image!, gaplessPlayback: true, fit: BoxFit.contain)),
          ),
    bottomNavigationBar: SafeArea(child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(tooltip: 'Página anterior', onPressed: busy || page == 0 ? null : () => _render(page - 1), icon: const Icon(Icons.chevron_left)),
        Text(pages == 0 ? 'PDF' : 'Página ${page + 1} de $pages'),
        IconButton(tooltip: 'Página seguinte', onPressed: busy || page + 1 >= pages ? null : () => _render(page + 1), icon: const Icon(Icons.chevron_right)),
      ]),
    )),
  );
}
