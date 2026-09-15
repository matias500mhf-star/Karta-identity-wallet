import 'package:flutter/material.dart';

import 'services/session_store.dart';
import 'services/biometric_service.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key, required this.store});
  final SessionStore store;
  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final biometric = BiometricService();
  final pin = TextEditingController();
  bool enabled = false;
  bool available = false;
  bool busy = true;
  String? message;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await widget.store.biometricEnabled();
    final a = await biometric.available();
    if (mounted) {
      setState(() {
        enabled = e;
        available = a;
        busy = false;
      });
    }
  }

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  Future<void> _change() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (!await widget.store.verifyPin(pin.text.trim())) {
        throw StateError('PIN incorreto.');
      }
      if (!enabled && !await biometric.authenticate()) {
        throw StateError('Biometria não confirmada.');
      }
      await widget.store.setBiometricEnabled(!enabled);
      if (mounted) {
        setState(() {
          enabled = !enabled;
          message = enabled ? 'Biometria ativada.' : 'Biometria desativada.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Não foi possível alterar. Confirme o PIN e a biometria; após várias tentativas, aguarde.',
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Segurança e biometria')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.fingerprint, size: 64),
        const SizedBox(height: 20),
        Text(
          enabled ? 'Biometria ativada' : 'Biometria desativada',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          available
              ? 'Use a biometria registada neste dispositivo. Qualquer biometria autorizada pelo sistema poderá desbloquear a carteira.'
              : 'Não foi encontrada biometria disponível. Configure-a nas definições do dispositivo e volte a abrir este ecrã.',
        ),
        const SizedBox(height: 20),
        if (available || enabled) ...[
          TextField(
            controller: pin,
            enabled: !busy,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Confirme o PIN da KARTA',
            ),
          ),
          FilledButton(
            onPressed: busy ? null : _change,
            child: Text(enabled ? 'Desativar biometria' : 'Ativar biometria'),
          ),
        ],
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(message!),
          ),
        const SizedBox(height: 24),
        const ListTile(
          leading: Icon(Icons.lock_clock_outlined),
          title: Text('Bloqueio automático'),
          subtitle: Text(
            'Ao colocar a app em segundo plano ou após 5 minutos sem interação.',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.password),
          title: Text('PIN alternativo'),
          subtitle: Text(
            'Mantenha o PIN guardado num local seguro. As tentativas incorretas são limitadas.',
          ),
        ),
      ],
    ),
  );
}
