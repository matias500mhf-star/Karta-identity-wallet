import 'pdf_viewer_page.dart';
import 'brand_theme.dart';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/document_store.dart';

class DocumentVaultPage extends StatefulWidget {
  const DocumentVaultPage({super.key, required this.store});

  final DocumentStore store;

  @override
  State<DocumentVaultPage> createState() => _DocumentVaultPageState();
}

class _DocumentVaultPageState extends State<DocumentVaultPage> {
  List<VaultDocument> documents = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await widget.store.list();
    if (!mounted) return;
    setState(() {
      documents = items;
      loading = false;
    });
  }

  Future<void> _add() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddDocumentPage(store: widget.store),
      ),
    );
    if (added == true) await _load();
  }

  Future<void> _open(VaultDocument item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => DocumentDetailsPage(store: widget.store, item: item),
      ),
    );
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          const Text('Documentos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
            'Guarde cópias digitais cifradas de documentos neste dispositivo. Estas cópias não são documentos oficiais verificados.',
            style: TextStyle(color: HmatiasBrand.muted, height: 1.45),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Adicionar documento'),
          ),
          const SizedBox(height: 18),
          if (loading)
            const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
          else if (documents.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.folder_copy_outlined, size: 44),
                    SizedBox(height: 12),
                    Text('Ainda não existem documentos.', style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 6),
                    Text('Pode fotografar frente/verso ou anexar PDF/imagem.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ...documents.map(
              (item) => Card(
                child: ListTile(
                  onTap: () => _open(item),
                  leading: Icon(item.type == 'Passaporte' ? Icons.menu_book_outlined : Icons.badge_outlined),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${item.type} · cópia local não verificada'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AddDocumentPage extends StatefulWidget {
  const AddDocumentPage({super.key, required this.store});
  final DocumentStore store;

  @override
  State<AddDocumentPage> createState() => _AddDocumentPageState();
}

class _AddDocumentPageState extends State<AddDocumentPage> {
  static const types = [
    'Bilhete de Identidade',
    'Passaporte',
    'Carta de Condução',
    'Certidão',
    'Outro',
  ];

  final ImagePicker picker = ImagePicker();
  final title = TextEditingController();
  String type = types.first;
  Uint8List? front;
  Uint8List? back;
  Uint8List? attachment;
  String? attachmentName;
  String? attachmentMime;
  bool busy = false;

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  Future<void> _camera(bool isFront) async {
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      maxWidth: 2400,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      if (isFront) {
        front = bytes;
      } else {
        back = bytes;
      }
    });
  }

  Future<void> _gallery(bool isFront) async {
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90, maxWidth: 2400);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      if (isFront) {
        front = bytes;
      } else {
        back = bytes;
      }
    });
  }

  Future<void> _pickAttachment() async {
    try {
      final file = await openFile(acceptedTypeGroups: const [
        XTypeGroup(
          label: 'PDF e imagens',
          extensions: ['pdf', 'jpg', 'jpeg', 'png'],
          mimeTypes: ['application/pdf', 'image/jpeg', 'image/png'],
          uniformTypeIdentifiers: ['com.adobe.pdf', 'public.jpeg', 'public.png'],
        ),
      ]);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final ext = file.name.split('.').last.toLowerCase();
      setState(() {
        attachment = bytes;
        attachmentName = file.name;
        attachmentMime = ext == 'pdf' ? 'application/pdf' : ext == 'png' ? 'image/png' : 'image/jpeg';
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o anexo. Tente novamente.')),
      );
    }
  }

  Future<void> _save() async {
    if (front == null && back == null && attachment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos uma imagem ou ficheiro.')),
      );
      return;
    }
    setState(() => busy = true);
    try {
      await widget.store.add(
        type: type,
        title: title.text.trim().isEmpty ? type : title.text.trim(),
        frontBytes: front,
        backBytes: back,
        attachmentBytes: attachment,
        attachmentName: attachmentName,
        attachmentMime: attachmentMime,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível guardar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar documento')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Card(
              child: ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('Cópia local cifrada'),
                subtitle: Text('O ficheiro é guardado cifrado e marcado como não verificado.'),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Tipo de documento'),
              items: types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) => setState(() => type = value ?? types.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Nome opcional', hintText: 'Ex.: Meu BI'),
            ),
            const SizedBox(height: 22),
            _sideCard('Frente', front, () => _camera(true), () => _gallery(true)),
            const SizedBox(height: 12),
            _sideCard('Verso', back, () => _camera(false), () => _gallery(false)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickAttachment,
              icon: const Icon(Icons.attach_file),
              label: Text(attachmentName == null ? 'Anexar PDF ou imagem' : 'Anexo: $attachmentName'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: busy ? null : _save,
              child: busy ? const CircularProgressIndicator() : const Text('Guardar no cofre'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sideCard(String label, Uint8List? bytes, VoidCallback camera, VoidCallback gallery) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (bytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(bytes, height: 150, width: double.infinity, fit: BoxFit.cover),
              )
            else
              const SizedBox(height: 90, child: Center(child: Icon(Icons.image_outlined, size: 40))),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: camera, icon: const Icon(Icons.camera_alt_outlined), label: const Text('Câmara'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: gallery, icon: const Icon(Icons.photo_library_outlined), label: const Text('Galeria'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentDetailsPage extends StatefulWidget {
  const DocumentDetailsPage({super.key, required this.store, required this.item});
  final DocumentStore store;
  final VaultDocument item;

  @override
  State<DocumentDetailsPage> createState() => _DocumentDetailsPageState();
}

class _DocumentDetailsPageState extends State<DocumentDetailsPage> {
  Uint8List? front;
  Uint8List? back;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool working = false;
  String? loadError;

  Future<void> _load() async {
    setState(() { loading = true; loadError = null; });
    try {
      final f = widget.item.frontFile == null ? null : await widget.store.readEncrypted(widget.item.frontFile!);
      final b = widget.item.backFile == null ? null : await widget.store.readEncrypted(widget.item.backFile!);
      if (mounted) setState(() { front = f; back = b; });
    } catch (_) {
      if (mounted) setState(() => loadError = 'Não foi possível carregar as imagens.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _fileAction(String file, String name, String mime, bool export) async {
    if (working) return;
    if (export) {
      final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Guardar cópia fora da KARTA?'),
        content: const Text('A cópia no destino escolhido não terá a protecção da carteira.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continuar')),
        ],
      ));
      if (confirmed != true || !mounted) return;
    }
    setState(() => working = true);
    try {
      final bytes = await widget.store.readEncrypted(file);
      if (!mounted) return;
      if (export) {
        final saved = await documentChannel.invokeMethod<bool>('exportFile', {
          'bytes': bytes, 'name': name, 'mime': mime,
        });
        if (saved == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cópia guardada.')));
        }
      } else if (mime == 'application/pdf' || name.toLowerCase().endsWith('.pdf')) {
        await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => PdfViewerPage(bytes: bytes, title: name)));
      } else {
        await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => Scaffold(
          appBar: AppBar(title: Text(name)),
          body: InteractiveViewer(maxScale: 5, child: Center(child: Image.memory(bytes,
            errorBuilder: (_, error, stack) => const Text('Não foi possível abrir esta imagem.')))),
        )));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possível abrir ou guardar o ficheiro. A cópia na carteira foi mantida.'),
      ));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Widget _fileButtons(String file, String name, String mime) => Wrap(spacing: 8, children: [
    FilledButton.icon(onPressed: working ? null : () => _fileAction(file, name, mime, false),
      icon: const Icon(Icons.open_in_new), label: const Text('Abrir')),
    OutlinedButton.icon(onPressed: working ? null : () => _fileAction(file, name, mime, true),
      icon: const Icon(Icons.download_outlined), label: const Text('Guardar cópia')),
  ]);

  Future<void> _delete() async {
    final yes = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Apagar documento?'),
            content: const Text('A cópia cifrada será removida deste dispositivo.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
            ],
          ),
        ) ??
        false;
    if (!yes) return;
    await widget.store.remove(widget.item);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.title), actions: [IconButton(onPressed: working ? null : _delete, icon: const Icon(Icons.delete_outline))]),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (loadError != null) Text(loadError!),
                if (working) const LinearProgressIndicator(),
                const Chip(label: Text('CÓPIA DIGITAL · NÃO VERIFICADA')),
                const SizedBox(height: 12),
                Text(widget.item.type, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 18),
                if (front != null) ...[
                  const Text('Frente', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(front!)),
                  _fileButtons(widget.item.frontFile!, 'frente.jpg', 'image/jpeg'),
                  const SizedBox(height: 18),
                ],
                if (back != null) ...[
                  const Text('Verso', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(back!)),
                  _fileButtons(widget.item.backFile!, 'verso.jpg', 'image/jpeg'),
                  const SizedBox(height: 18),
                ],
                if (widget.item.attachmentName != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(widget.item.attachmentName!),
                      subtitle: Text(widget.item.attachmentMime ?? 'ficheiro cifrado'),
                    ),
                  ),
                if (widget.item.attachmentFile != null)
                  _fileButtons(widget.item.attachmentFile!, widget.item.attachmentName ?? 'documento.pdf', widget.item.attachmentMime ?? 'application/pdf'),
                const SizedBox(height: 12),
                const Text(
                  'Esta cópia serve apenas para armazenamento privado e consulta. Não substitui o documento físico nem uma credencial digital emitida por autoridade competente.',
                  style: TextStyle(color: HmatiasBrand.muted, height: 1.45),
                ),
              ],
            ),
    );
  }
}
