import 'package:flutter/material.dart';
import 'services/session_store.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.store});
  final SessionStore store;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nationality = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _failed = false; });
    try {
      final profile = await widget.store.readProfile();
      if (!mounted) return;
      _name.text = profile['name'] ?? '';
      _nationality.text = profile['nationality'] ?? '';
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.store.saveProfile(
        name: _name.text.trim(), nationality: _nationality.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível guardar. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _nationality.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil de identidade')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed
              ? Center(child: TextButton(onPressed: _load, child: const Text('Não foi possível carregar. Tentar novamente')))
              : Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Icon(Icons.person_outline, size: 64),
                      const SizedBox(height: 20),
                      const Text('O meu perfil', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      const Text('Dados declarados por si, guardados neste dispositivo. Este perfil não constitui uma identidade verificada. Use dados fictícios nesta Alpha.'),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _name,
                        enabled: !_saving,
                        maxLength: 120,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nome completo'),
                        validator: (value) => (value ?? '').trim().isEmpty ? 'Indique o nome.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nationality,
                        enabled: !_saving,
                        maxLength: 80,
                        decoration: const InputDecoration(labelText: 'Nacionalidade (opcional)'),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'A guardar…' : 'Guardar perfil'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
