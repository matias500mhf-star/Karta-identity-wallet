import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'services/backup_store.dart';
import 'services/session_store.dart';
import 'pdf_viewer_page.dart';

class OnlinePage extends StatefulWidget {
  const OnlinePage({super.key, this.restore = false});
  final bool restore;
  @override
  State<OnlinePage> createState() => _OnlinePageState();
}

class _OnlinePageState extends State<OnlinePage> {
  final api = ApiService();
  final email = TextEditingController();
  final password = TextEditingController();
  final invite = TextEditingController();
  final backupPassword = TextEditingController();
  final backupConfirm = TextEditingController();
  final pin = TextEditingController();
  bool busy = false;
  bool registering = false;
  String? message;
  Map<String, dynamic>? metadata;
  @override
  void dispose() {
    for (final c in [
      email,
      password,
      invite,
      backupPassword,
      backupConfirm,
      pin,
    ]) {
      c.dispose();
    }
    api.close();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!mounted || busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => message = e.message);
    } on FormatException catch (e) {
      if (mounted) setState(() => message = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Não foi possível concluir. Confirme as palavras-passe e o PIN. Os dados locais foram mantidos.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _login() => _run(() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      throw const ApiException('Preencha o email e a palavra-passe da conta.');
    }
    if (registering) {
      if (password.text.length < 12)
        throw const ApiException(
          'Use pelo menos 12 caracteres na palavra-passe da conta.',
        );
      await api.register(email.text, password.text, invite.text);
    }
    await api.login(email.text, password.text);
    password.clear();
    invite.clear();
    metadata = await api.metadata();
  });
  Future<bool> _confirm(String title, String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _upload() async {
    if (!await _confirm(
      'Guardar backup online?',
      'Será enviada uma cópia cifrada do perfil, credenciais e documentos para a sua conta. Substitui o backup anterior. A palavra-passe do backup não é enviada.',
    )) {
      return;
    }
    await _run(() async {
      if (backupPassword.text != backupConfirm.text) {
        throw const ApiException('As palavras-passe do backup não coincidem.');
      }
      if (!await SessionStore().verifyPin(pin.text.trim())) {
        throw const ApiException('PIN incorreto.');
      }
      pin.clear();
      final bytes = await BackupStore().export(backupPassword.text);
      await api.upload(bytes);
      backupPassword.clear();
      backupConfirm.clear();
      metadata = await api.metadata();
      message = 'Backup online confirmado.';
    });
  }

  Future<void> _download() => _run(() async {
    final bytes = await api.download();
    if (widget.restore) {
      await BackupStore().restore(bytes, backupPassword.text);
      if (mounted) Navigator.pop(context, true);
    } else {
      final saved = await documentChannel.invokeMethod<bool>('exportFile', {
        'bytes': bytes,
        'name': 'karta-backup.kartabackup',
        'mime': 'application/octet-stream',
      });
      message = saved == true
          ? 'Backup cifrado guardado no destino escolhido.'
          : 'Gravação cancelada.';
    }
  });
  Future<void> _deleteBackup() async {
    if (!await _confirm(
      'Apagar backup online?',
      'A cópia no servidor será removida. Os documentos neste telemóvel não serão apagados.',
    )) {
      return;
    }
    await _run(() async {
      await api.deleteBackup();
      metadata = null;
      message = 'Backup online removido.';
    });
  }

  Future<void> _deleteAccount() async {
    if (password.text.isEmpty) {
      setState(() => message = 'Confirme a palavra-passe da conta.');
      return;
    }
    if (!await _confirm(
      'Apagar conta online?',
      'Apaga a conta, as sessões e o backup online. Esta ação não apaga a carteira local.',
    )) {
      return;
    }
    await _run(() async {
      await api.deleteAccount(password.text);
      password.clear();
      metadata = null;
      message = 'Conta online apagada.';
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.restore ? 'Recuperar backup online' : 'Conta e backup online',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.cloud_outlined, size: 56),
          const SizedBox(height: 16),
          if (!api.configured) ...[
            const Text(
              'Serviço online em preparação',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'A carteira local e o backup em ficheiro continuam disponíveis. Esta versão ainda não está ligada a um servidor HMATIAS.',
            ),
          ] else ...[
            const Text(
              'Beta por convite. O backup é cifrado no dispositivo. Guarde a sua palavra-passe do backup e o PIN original: a conta online não os recupera.',
            ),
            const SizedBox(height: 20),
            if (api.accessToken == null) ...[
              TextField(
                controller: email,
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                enabled: !busy,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Palavra-passe da conta',
                ),
              ),
              if (registering) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: invite,
                  enabled: !busy,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Código de convite',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy ? null : _login,
                child: Text(registering ? 'Criar conta e entrar' : 'Entrar'),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() => registering = !registering),
                child: Text(
                  registering ? 'Já tenho conta' : 'Criar conta com convite',
                ),
              ),
            ] else ...[
              Text(
                email.text.trim(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                metadata == null
                    ? 'Ainda não existe backup online.'
                    : 'Último backup: ${metadata!['updatedAt']}\nTamanho: ${((metadata!['size'] as num) / 1048576).toStringAsFixed(1)} MB',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: backupPassword,
                enabled: !busy,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Palavra-passe do backup',
                  helperText: 'Diferente da palavra-passe da conta; mínimo 12 caracteres',
                ),
              ),
              if (!widget.restore) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: backupConfirm,
                  enabled: !busy,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar palavra-passe do backup',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pin,
                  enabled: !busy,
                  obscureText: true,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'PIN da carteira',
                  ),
                ),
                FilledButton.icon(
                  onPressed: busy ? null : _upload,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Criar backup online'),
                ),
              ],
              if (metadata != null) ...[
                OutlinedButton.icon(
                  onPressed: busy ? null : _download,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: Text(
                    widget.restore
                        ? 'Restaurar nesta instalação vazia'
                        : 'Descarregar backup cifrado',
                  ),
                ),
                TextButton(
                  onPressed: busy ? null : _deleteBackup,
                  child: const Text('Apagar backup online'),
                ),
              ],
              const Divider(),
              TextButton(
                onPressed: busy
                    ? null
                    : () => _run(() async {
                        await api.logout();
                        metadata = null;
                      }),
                child: const Text('Terminar sessão'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: password,
                enabled: !busy,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Palavra-passe da conta para a apagar',
                ),
              ),
              TextButton(
                onPressed: busy ? null : _deleteAccount,
                child: const Text('Apagar conta online'),
              ),
            ],
          ],
          if (busy) const LinearProgressIndicator(),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(message!),
            ),
        ],
      ),
    ),
  );
}
