import 'qr_page.dart';
import 'brand_theme.dart';
import 'package:flutter/material.dart';

import 'document_vault_page.dart';
import 'profile_page.dart';
import 'services/credential_store.dart';
import 'services/document_store.dart';
import 'services/session_store.dart';

void main() => runApp(const KartaApp());

class KartaApp extends StatelessWidget {
  const KartaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KARTA',
      theme: HmatiasBrand.theme,
      home: const WalletGate(),
    );
  }
}

class WalletGate extends StatefulWidget {
  const WalletGate({super.key});

  @override
  State<WalletGate> createState() => _WalletGateState();
}

class _WalletGateState extends State<WalletGate> {
  final SessionStore store = SessionStore();
  bool loading = true;
  bool created = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final exists = await store.walletCreated();
    if (!mounted) return;
    setState(() {
      created = exists;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return created ? UnlockPage(store: store) : WelcomePage(store: store);
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.store});
  final SessionStore store;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const SizedBox(height: 60),
            const KartaBrandHeader(),
            const SizedBox(height: 28),
            const Text('A sua identidade. Na sua KARTA.', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            const Text(
              'Carteira local para credenciais de teste e cópias digitais cifradas de documentos.',
              style: TextStyle(color: HmatiasBrand.muted, fontSize: 17, height: 1.45),
            ),
            const SizedBox(height: 24),
            const _Feature(icon: Icons.lock_outline, text: 'Protegida por PIN no dispositivo'),
            const _Feature(icon: Icons.badge_outlined, text: 'Credenciais locais de teste'),
            const _Feature(icon: Icons.document_scanner_outlined, text: 'Frente/verso e anexos PDF/imagem cifrados'),
            const SizedBox(height: 20),
            Card(
              child: CheckboxListTile(
                value: accepted,
                onChanged: (v) => setState(() => accepted = v ?? false),
                title: const Text('Compreendo que esta é uma versão Alpha.'),
                subtitle: const Text('As cópias guardadas não substituem documentos oficiais nem credenciais verificadas.'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: accepted
                  ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CreatePinPage(store: widget.store)))
                  : null,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              child: const Text('Criar a minha KARTA'),
            ),
            const SizedBox(height: 12),
            const Text('KARTA Alpha 0.6 · Document Vault', textAlign: TextAlign.center, style: TextStyle(color: HmatiasBrand.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [Icon(icon), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)))]),
      );
}

class CreatePinPage extends StatefulWidget {
  const CreatePinPage({super.key, required this.store});
  final SessionStore store;

  @override
  State<CreatePinPage> createState() => _CreatePinPageState();
}

class _CreatePinPageState extends State<CreatePinPage> {
  final pin = TextEditingController();
  final confirm = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    pin.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final value = pin.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      _error('Crie um PIN de exatamente 6 dígitos.');
      return;
    }
    if (value != confirm.text.trim()) {
      _error('Os PINs não coincidem.');
      return;
    }
    setState(() => busy = true);
    await widget.store.createWallet(pin: value);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => WalletPage(store: widget.store)), (_) => false);
  }

  void _error(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar PIN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Proteja a sua KARTA', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              const Text('Este PIN desbloqueia a carteira neste dispositivo.', style: TextStyle(color: HmatiasBrand.muted)),
              const SizedBox(height: 28),
              TextField(controller: pin, keyboardType: TextInputType.number, obscureText: true, maxLength: 6, decoration: const InputDecoration(labelText: 'PIN de 6 dígitos')),
              const SizedBox(height: 12),
              TextField(controller: confirm, keyboardType: TextInputType.number, obscureText: true, maxLength: 6, decoration: const InputDecoration(labelText: 'Confirmar PIN')),
              const Spacer(),
              FilledButton(
                onPressed: busy ? null : _create,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: busy ? const CircularProgressIndicator() : const Text('Criar carteira'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UnlockPage extends StatefulWidget {
  const UnlockPage({super.key, required this.store});
  final SessionStore store;

  @override
  State<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends State<UnlockPage> {
  final pin = TextEditingController();

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final valid = await widget.store.verifyPin(pin.text.trim());
    if (!mounted) return;
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN incorreto.')));
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => WalletPage(store: widget.store)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.account_balance_wallet_rounded, size: 70),
              const SizedBox(height: 24),
              const Text('Desbloquear KARTA', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 28),
              TextField(controller: pin, keyboardType: TextInputType.number, obscureText: true, maxLength: 6, textAlign: TextAlign.center, onSubmitted: (_) => _unlock(), decoration: const InputDecoration(labelText: 'PIN')),
              const SizedBox(height: 14),
              FilledButton(onPressed: _unlock, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)), child: const Text('Desbloquear')),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class WalletPage extends StatefulWidget {
  const WalletPage({super.key, required this.store});
  final SessionStore store;

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final CredentialStore credentialStore = CredentialStore();
  final DocumentStore documentStore = DocumentStore();
  int index = 0;
  String walletName = 'A minha KARTA';
  List<LocalCredential> credentials = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await widget.store.walletName();
    final items = await credentialStore.list();
    if (!mounted) return;
    setState(() {
      walletName = name;
      credentials = items;
      loading = false;
    });
  }

  Future<void> _addCredential() async {
    final added = await Navigator.of(context).push<LocalCredential>(
      MaterialPageRoute<LocalCredential>(builder: (_) => AddCredentialPage(store: credentialStore)),
    );
    if (added != null) await _load();
  }

  Future<void> _openCredential(LocalCredential credential) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => CredentialDetailsPage(credential: credential, store: credentialStore)),
    );
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _wallet(),
      DocumentVaultPage(store: documentStore),
      const QrHubPage(),
      _settings(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Carteira'),
          NavigationDestination(icon: Icon(Icons.folder_copy_outlined), selectedIcon: Icon(Icons.folder_copy), label: 'Documentos'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: 'QR'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Definições'),
        ],
      ),
    );
  }

  Widget _wallet() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          const Text('KARTA · HMATIAS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: HmatiasBrand.navy, borderRadius: BorderRadius.circular(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('IDENTITY WALLET', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, letterSpacing: 1.4)), Icon(Icons.shield_outlined, color: Colors.white)]),
                const SizedBox(height: 30),
                Text(walletName, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('Carteira, credenciais e documentos protegidos localmente.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Credenciais', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), Text('${credentials.length}', style: const TextStyle(fontWeight: FontWeight.w800))]),
          const SizedBox(height: 10),
          if (loading)
            const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()))
          else if (credentials.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Ainda não existem credenciais locais.', textAlign: TextAlign.center)))
          else
            ...credentials.map(_credentialTile),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: _addCredential, icon: const Icon(Icons.add_card_outlined), label: const Text('Adicionar credencial local')),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => setState(() => index = 1), icon: const Icon(Icons.document_scanner_outlined), label: const Text('Abrir cofre de documentos')),
          const SizedBox(height: 10),
          const Text('Credenciais e documentos desta Alpha são locais e não representam validação por uma entidade emissora.', textAlign: TextAlign.center, style: TextStyle(color: HmatiasBrand.muted, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  Widget _credentialTile(LocalCredential credential) {
    final reference = credential.reference;
    final masked = reference.length <= 4 ? reference : '•••• ${reference.substring(reference.length - 4)}';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _openCredential(credential),
        leading: const CircleAvatar(child: Icon(Icons.badge_outlined)),
        title: Text(credential.type, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${credential.issuer}\n$masked'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  Widget _settings() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 18),
        const KartaBrandHeader(),
        const SizedBox(height: 24),
        const Text('Definições', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),
        Card(child: ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Perfil de identidade'),
          subtitle: const Text('Consultar e editar os meus dados'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(builder: (_) => ProfilePage(store: widget.store)),
            );
            if (changed == true && mounted) await _load();
          },
        )),
        const Card(child: ListTile(leading: Icon(Icons.fingerprint), title: Text('Biometria'), subtitle: Text('Prevista para uma próxima versão'))),
        const Card(child: ListTile(leading: Icon(Icons.cloud_off_outlined), title: Text('Modo local'), subtitle: Text('A Alpha funciona sem conta online'))),
        const Card(child: ListTile(leading: Icon(Icons.lock_outline), title: Text('Document Vault'), subtitle: Text('Ficheiros cifrados com AES-GCM no armazenamento privado da app'))),
        const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('KARTA Alpha 0.6'), subtitle: Text('Local Identity Wallet + Document Vault'))),
        const SizedBox(height: 18),
        OutlinedButton.icon(onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => UnlockPage(store: widget.store)), (_) => false), icon: const Icon(Icons.lock_outline), label: const Text('Bloquear KARTA')),
        const SizedBox(height: 10),
        TextButton.icon(onPressed: _deleteWallet, icon: const Icon(Icons.delete_outline), label: const Text('Apagar carteira deste dispositivo')),
      ],
    );
  }

  Future<void> _deleteWallet() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Apagar carteira local?'),
            content: const Text('Isto remove a KARTA, credenciais e todas as cópias cifradas de documentos deste dispositivo.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await credentialStore.clear();
    await documentStore.clear();
    await widget.store.deleteWallet();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => WelcomePage(store: widget.store)), (_) => false);
  }
}

class AddCredentialPage extends StatefulWidget {
  const AddCredentialPage({super.key, required this.store});
  final CredentialStore store;

  @override
  State<AddCredentialPage> createState() => _AddCredentialPageState();
}

class _AddCredentialPageState extends State<AddCredentialPage> {
  static const types = ['Bilhete de Identidade', 'Passaporte', 'Carta de Condução', 'Cartão profissional', 'Outro'];
  final issuer = TextEditingController();
  final reference = TextEditingController();
  String type = types.first;
  bool busy = false;

  @override
  void dispose() {
    issuer.dispose();
    reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (issuer.text.trim().length < 2 || reference.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha entidade e referência.')));
      return;
    }
    setState(() => busy = true);
    final credential = await widget.store.add(type: type, issuer: issuer.text, reference: reference.text);
    if (!mounted) return;
    Navigator.of(context).pop(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar credencial')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Registo local de teste', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text('Este registo é manual, local e não verificado por uma entidade emissora.', style: TextStyle(color: HmatiasBrand.muted)),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'Tipo'), items: types.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setState(() => type = value ?? types.first)),
          const SizedBox(height: 14),
          TextField(controller: issuer, decoration: const InputDecoration(labelText: 'Entidade / origem')),
          const SizedBox(height: 14),
          TextField(controller: reference, decoration: const InputDecoration(labelText: 'Referência / número')),
          const SizedBox(height: 24),
          FilledButton(onPressed: busy ? null : _save, child: busy ? const CircularProgressIndicator() : const Text('Guardar credencial')),
        ],
      ),
    );
  }
}

class CredentialDetailsPage extends StatelessWidget {
  const CredentialDetailsPage({super.key, required this.credential, required this.store});
  final LocalCredential credential;
  final CredentialStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(credential.type)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Chip(label: Text('NÃO VERIFICADA')),
          const SizedBox(height: 20),
          ListTile(title: const Text('Tipo'), subtitle: Text(credential.type)),
          ListTile(title: const Text('Entidade'), subtitle: Text(credential.issuer)),
          ListTile(title: const Text('Referência'), subtitle: Text(credential.reference)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.push<void>(context, MaterialPageRoute(builder: (_) => QrSharePage(fields: {
              'documentType': credential.type, 'issuer': credential.issuer, 'reference': credential.reference,
            }))),
            icon: const Icon(Icons.qr_code), label: const Text('Partilhar por QR'),
          ),
          FilledButton.tonalIcon(
            onPressed: () async {
              await store.remove(credential.id);
              if (context.mounted) Navigator.of(context).pop(true);
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remover credencial'),
          ),
        ],
      ),
    );
  }
}

