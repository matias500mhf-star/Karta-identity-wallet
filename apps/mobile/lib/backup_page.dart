import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

import 'services/backup_store.dart';
import 'services/session_store.dart';
import 'pdf_viewer_page.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key, this.restore = false});
  final bool restore;
  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final password = TextEditingController();
  final confirm = TextEditingController();
  final pin = TextEditingController();
  bool busy = false;
  String? message;
  @override
  void dispose() {
    password.dispose();
    confirm.dispose();
    pin.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (widget.restore) {
        final file = await openFile();
        if (file == null) {
          return;
        }
        if (await file.length() > BackupCodec.maxBytes) {
          throw const FormatException('Backup demasiado grande.');
        }
        await BackupStore().restore(await file.readAsBytes(), password.text);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        if (password.text != confirm.text) {
          throw const FormatException('As palavras-passe não coincidem.');
        }
        if (!await SessionStore().verifyPin(pin.text.trim())) {
          throw const FormatException('PIN incorreto.');
        }
        final bytes = await BackupStore().export(password.text);
        final saved = await documentChannel.invokeMethod<bool>('exportFile', {
          'bytes': bytes,
          'name': 'karta-backup.kartabackup',
          'mime': 'application/octet-stream',
        });
        if (mounted) {
          setState(
            () => message = saved == true
                ? 'Backup cifrado guardado. Conserve a palavra-passe e o PIN em segurança.'
                : 'Gravação cancelada.',
          );
        }
      }
    } on FormatException catch (e) {
      if (mounted) {
        setState(() => message = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = widget.restore
              ? 'Não foi possível restaurar. Verifique a palavra-passe, o ficheiro e se o dispositivo está sem carteira.'
              : 'Não foi possível criar o backup. Confirme o PIN e tente novamente.',
        );
      }
    } finally {
      pin.clear();
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.restore ? 'Restaurar carteira' : 'Backup cifrado'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.restore
                ? 'Restaure um backup KARTA numa instalação sem carteira. Depois use o PIN que tinha quando criou o backup. A biometria terá de ser ativada novamente.'
                : 'Guarde uma cópia cifrada do perfil, credenciais e documentos. Nesta versão são suportados até 16 MB de ficheiros cifrados.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Sem a palavra-passe do backup não é possível recuperar os dados. Guarde-a separadamente do ficheiro.',
          ),
          const SizedBox(height: 24),
          if (!widget.restore)
            TextField(
              controller: pin,
              enabled: !busy,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'PIN da KARTA'),
            ),
          TextField(
            controller: password,
            enabled: !busy,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Palavra-passe do backup',
              helperText: 'Pelo menos 12 caracteres',
            ),
          ),
          if (!widget.restore) ...[
            const SizedBox(height: 16),
            TextField(
              controller: confirm,
              enabled: !busy,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar palavra-passe',
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : _run,
            child: Text(
              busy
                  ? 'A processar…'
                  : widget.restore
                  ? 'Escolher backup e restaurar'
                  : 'Criar e guardar backup',
            ),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(message!),
            ),
        ],
      ),
    ),
  );
}
