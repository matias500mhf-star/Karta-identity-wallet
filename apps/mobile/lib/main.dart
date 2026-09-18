import 'qr_page.dart';
import 'session_guard.dart';
import 'services/biometric_service.dart';
import 'security_page.dart';
import 'backup_page.dart';
import 'online_page.dart';
import 'services/backup_store.dart';
import 'premium_widgets.dart';
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
      builder: (context, child) => SessionGuard(
        lockPageBuilder: (unlock) =>
            UnlockPage(store: SessionStore(), onUnlocked: unlock),
        child: child!,
      ),
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
    await BackupStore().recoverInterruptedRestore();
    final exists = await store.walletCreated();
    if (!mounted) {
      return;
    }
    setState(() {
      created = exists;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
            const Text(
              'A sua identidade. Na sua KARTA.',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const Text(
              'Carteira local para credenciais de teste e cópias digitais cifradas de documentos.',
              style: TextStyle(
                color: HmatiasBrand.muted,
                fontSize: 17,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            const _Feature(
              icon: Icons.lock_outline,
              text: 'Protegida por PIN no dispositivo',
            ),
            const _Feature(
              icon: Icons.badge_outlined,
              text: 'Credenciais locais de teste',
            ),
            const _Feature(
              icon: Icons.document_scanner_outlined,
              text: 'Frente/verso e anexos PDF/imagem cifrados',
            ),
            const SizedBox(height: 20),
            Card(
              child: CheckboxListTile(
                value: accepted,
                onChanged: (v) => setState(() => accepted = v ?? false),
                title: const Text('Compreendo que esta é uma versão Alpha.'),
                subtitle: const Text(
                  'As cópias guardadas não substituem documentos oficiais nem credenciais verificadas.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: accepted
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CreatePinPage(store: widget.store),
                      ),
                    )
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: const Text('Criar a minha KARTA'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                final restored = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BackupPage(restore: true),
                  ),
                );
                if (restored == true && context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => UnlockPage(store: widget.store),
                    ),
                    (_) => false,
                  );
                }
              },
              icon: const Icon(Icons.restore),
              label: const Text('Restaurar um backup'),
            ),
            TextButton.icon(
              onPressed: () async {
                final restored = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OnlinePage(restore: true),
                  ),
                );
                if (restored == true && context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => UnlockPage(store: widget.store),
                    ),
                    (_) => false,
                  );
                }
              },
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Recuperar backup online'),
            ),
            const Text(
              'KARTA Alpha 0.9 · HMATIAS',
              textAlign: TextAlign.center,
              style: TextStyle(color: HmatiasBrand.muted, fontSize: 12),
            ),
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
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
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
    SessionSecurity.unlock();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => WalletPage(store: widget.store)),
      (_) => false,
    );
  }

  void _error(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

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
              const Text(
                'Proteja a sua KARTA',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Este PIN desbloqueia a carteira neste dispositivo.',
                style: TextStyle(color: HmatiasBrand.muted),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: pin,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'PIN de 6 dígitos',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirm,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'Confirmar PIN'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: busy ? null : _create,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: busy
                    ? const CircularProgressIndicator()
                    : const Text('Criar carteira'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UnlockPage extends StatefulWidget {
  const UnlockPage({
    super.key,
    required this.store,
    this.onUnlocked,
    this.biometricService,
  });
  final SessionStore store;
  final VoidCallback? onUnlocked;
  final BiometricService? biometricService;

  @override
  State<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends State<UnlockPage> {
  final pin = TextEditingController();
  late final biometrics = widget.biometricService ?? BiometricService();
  bool busy = false;
  bool biometric = false;
  String? error;
  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final enabled =
        await widget.store.biometricEnabled() && await biometrics.available();
    if (mounted) {
      setState(() => biometric = enabled);
    }
  }

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  void _enter() {
    SessionSecurity.unlock();
    if (widget.onUnlocked != null) {
      widget.onUnlocked!();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => WalletPage(store: widget.store)),
    );
  }

  Future<void> _unlock({bool useBiometric = false}) async {
    if (busy) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final valid = useBiometric
          ? await widget.store.biometricEnabled() &&
                await biometrics.authenticate()
          : await widget.store.verifyPin(pin.text.trim());
      if (!mounted) {
        return;
      }
      pin.clear();
      if (valid) {
        _enter();
      } else {
        setState(
          () => error = useBiometric
              ? 'Autenticação não concluída. Tente novamente ou use o PIN.'
              : 'PIN incorreto.',
        );
      }
    } on StateError catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Demasiadas tentativas. Aguarde antes de tentar novamente.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Não foi possível desbloquear. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        children: [
          const Icon(Icons.account_balance_wallet_rounded, size: 70),
          const SizedBox(height: 24),
          const Text(
            'Desbloquear KARTA',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: pin,
            enabled: !busy,
            keyboardType: TextInputType.number,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            maxLength: 6,
            textAlign: TextAlign.center,
            onSubmitted: (_) => _unlock(),
            decoration: const InputDecoration(labelText: 'PIN'),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(error!),
            ),
          FilledButton(
            onPressed: busy ? null : () => _unlock(),
            child: Text(busy ? 'A verificar…' : 'Desbloquear'),
          ),
          if (biometric) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : () => _unlock(useBiometric: true),
              icon: const Icon(Icons.fingerprint),
              label: const Text('Usar biometria'),
            ),
          ],
        ],
      ),
    ),
  );
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
    if (!mounted) {
      return;
    }
    setState(() {
      walletName = name;
      credentials = items;
      loading = false;
    });
  }

  Future<void> _addCredential() async {
    final added = await Navigator.of(context).push<LocalCredential>(
      MaterialPageRoute<LocalCredential>(
        builder: (_) => AddCredentialPage(store: credentialStore),
      ),
    );
    if (added != null) {
      await _load();
    }
  }

  Future<void> _openCredential(LocalCredential credential) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CredentialDetailsPage(
          credential: credential,
          store: credentialStore,
        ),
      ),
    );
    if (changed == true) {
      await _load();
    }
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
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Carteira',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            selectedIcon: Icon(Icons.folder_copy),
            label: 'Documentos',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'QR',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Definições',
          ),
        ],
      ),
    );
  }

  Widget _wallet() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A sua identidade, consigo.',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'KARTA · Um produto HMATIAS',
                      style: TextStyle(color: HmatiasBrand.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Bloquear carteira',
                onPressed: SessionSecurity.lock,
                icon: const Icon(Icons.lock_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          WalletHero(name: walletName, credentialCount: credentials.length),
          const SizedBox(height: 28),
          const Text(
            'Tudo à mão',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          KartaActionPair(
            first: KartaAction(
              icon: Icons.folder_copy_outlined,
              title: 'Documentos',
              subtitle: 'Consultar e guardar as suas cópias',
              onTap: () => setState(() => index = 1),
            ),
            second: KartaAction(
              icon: Icons.qr_code_rounded,
              title: 'Partilhar por QR',
              subtitle: 'Escolha os dados que quer mostrar',
              onTap: () => setState(() => index = 2),
            ),
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Credenciais',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              Text(
                '${credentials.length}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (credentials.isEmpty)
            const KartaEmptyState(
              icon: Icons.badge_outlined,
              title: 'A sua carteira começa aqui',
              message: 'Adicione uma credencial local ou guarde um documento para o ter sempre à mão.',
            )
          else
            ...credentials.map(_credentialTile),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _addCredential,
            icon: const Icon(Icons.add_card_outlined),
            label: const Text('Adicionar credencial local'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => setState(() => index = 1),
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Abrir cofre de documentos'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Credenciais e documentos desta Alpha são locais e não representam validação por uma entidade emissora.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HmatiasBrand.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _credentialTile(LocalCredential credential) {
    final reference = credential.reference;
    final masked = reference.length <= 4
        ? reference
        : '•••• ${reference.substring(reference.length - 4)}';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _openCredential(credential),
        leading: const CircleAvatar(child: Icon(Icons.badge_outlined)),
        title: Text(
          credential.type,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
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
        Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Conta e backup online'),
            subtitle: const Text('Ligação opcional · beta'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const OnlinePage()),
            ),
          ),
        ),
        const Text(
          'Definições',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil de identidade'),
            subtitle: const Text('Consultar e editar os meus dados'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => ProfilePage(store: widget.store),
                ),
              );
              if (changed == true && mounted) {
                await _load();
              }
            },
          ),
        ),

        Card(
          child: ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Segurança e biometria'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => SecurityPage(store: widget.store),
              ),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup cifrado'),
            subtitle: const Text(
              'Guardar uma cópia para recuperar noutro dispositivo',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const BackupPage()),
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.cloud_off_outlined),
            title: Text('Modo local'),
            subtitle: Text('A Alpha funciona sem conta online'),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Document Vault'),
            subtitle: Text(
              'Ficheiros cifrados com AES-GCM no armazenamento privado da app',
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('KARTA Alpha 0.9'),
            subtitle: Text('Um produto HMATIAS · Documentos e QR'),
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: SessionSecurity.lock,
          icon: const Icon(Icons.lock_outline),
          label: const Text('Bloquear KARTA'),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _deleteWallet,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Apagar carteira deste dispositivo'),
        ),
      ],
    );
  }

  Future<void> _deleteWallet() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Apagar carteira local?'),
            content: const Text(
              'Isto remove a KARTA, credenciais e todas as cópias cifradas de documentos deste dispositivo.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Apagar'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    await credentialStore.clear();
    await documentStore.clear();
    await widget.store.deleteWallet();
    SessionSecurity.reset();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => WelcomePage(store: widget.store)),
      (_) => false,
    );
  }
}

class AddCredentialPage extends StatefulWidget {
  const AddCredentialPage({super.key, required this.store});
  final CredentialStore store;

  @override
  State<AddCredentialPage> createState() => _AddCredentialPageState();
}

class _AddCredentialPageState extends State<AddCredentialPage> {
  static const types = [
    'Bilhete de Identidade',
    'Passaporte',
    'Carta de Condução',
    'Cartão profissional',
    'Outro',
  ];
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha entidade e referência.')),
      );
      return;
    }
    setState(() => busy = true);
    final credential = await widget.store.add(
      type: type,
      issuer: issuer.text,
      reference: reference.text,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar credencial')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Registo local de teste',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const Text(
            'Este registo é manual, local e não verificado por uma entidade emissora.',
            style: TextStyle(color: HmatiasBrand.muted),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: types
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => type = value ?? types.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: issuer,
            decoration: const InputDecoration(labelText: 'Entidade / origem'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: reference,
            decoration: const InputDecoration(labelText: 'Referência / número'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : _save,
            child: busy
                ? const CircularProgressIndicator()
                : const Text('Guardar credencial'),
          ),
        ],
      ),
    );
  }
}

class CredentialDetailsPage extends StatelessWidget {
  const CredentialDetailsPage({
    super.key,
    required this.credential,
    required this.store,
  });
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
          ListTile(
            title: const Text('Entidade'),
            subtitle: Text(credential.issuer),
          ),
          ListTile(
            title: const Text('Referência'),
            subtitle: Text(credential.reference),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => QrSharePage(
                  fields: {
                    'documentType': credential.type,
                    'issuer': credential.issuer,
                    'reference': credential.reference,
                  },
                ),
              ),
            ),
            icon: const Icon(Icons.qr_code),
            label: const Text('Partilhar por QR'),
          ),
          FilledButton.tonalIcon(
            onPressed: () async {
              await store.remove(credential.id);
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remover credencial'),
          ),
        ],
      ),
    );
  }
}
