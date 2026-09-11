import 'package:flutter/material.dart';

import 'services/session_store.dart';

void main() => runApp(const KartaApp());

class KartaApp extends StatelessWidget {
  const KartaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KARTA',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF111827)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
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
  final store = SessionStore();
  bool loading = true;
  bool created = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    created = await store.walletCreated();
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return created
        ? UnlockPage(store: store)
        : WelcomePage(store: store);
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.store});
  final SessionStore store;

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
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Text(
                    'K',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'A sua identidade. Na sua KARTA.',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const Text(
                'Crie uma carteira digital protegida neste dispositivo. Não precisa de conta, email ou ligação a um servidor para começar.',
                style: TextStyle(color: Colors.black54, fontSize: 17, height: 1.45),
              ),
              const SizedBox(height: 28),
              const _Feature(icon: Icons.lock_outline, text: 'Protegida por PIN no dispositivo'),
              const _Feature(icon: Icons.badge_outlined, text: 'Preparada para credenciais digitais'),
              const _Feature(icon: Icons.qr_code_rounded, text: 'Partilha e verificação por QR Code em evolução'),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TermsPage(store: store),
                    ),
                  );
                },
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: const Text('Criar a minha KARTA'),
              ),
              const SizedBox(height: 10),
              const Text(
                'KARTA Alpha · carteira local experimental',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class TermsPage extends StatefulWidget {
  const TermsPage({super.key, required this.store});
  final SessionStore store;

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  bool accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Antes de começar')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'A KARTA está em fase Alpha.',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              const Text(
                'Nesta versão, a carteira é criada localmente no seu dispositivo. Ainda não substitui documentos oficiais e não deve ser usada como prova legal de identidade.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: accepted,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => accepted = value ?? false),
                title: const Text('Compreendo e quero continuar.'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: accepted
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CreatePinPage(store: widget.store),
                          ),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => WalletPage(store: widget.store)),
      (_) => false,
    );
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

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
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: pin,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'PIN de 6 dígitos'),
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
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
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
    if (await widget.store.verifyPin(pin.text.trim())) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => WalletPage(store: widget.store)),
      );
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN incorreto.')),
      );
    }
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
              const Text(
                'Desbloquear KARTA',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Introduza o PIN criado neste dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: pin,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                textAlign: TextAlign.center,
                onSubmitted: (_) => _unlock(),
                decoration: const InputDecoration(labelText: 'PIN'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _unlock,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: const Text('Desbloquear'),
              ),
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
  int index = 0;
  String walletName = 'A minha KARTA';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await widget.store.walletName();
    if (mounted) setState(() => walletName = value);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_wallet(), const VerifyPage(), _profile()];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Verificar',
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        const Text('KARTA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('IDENTITY WALLET', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                  Icon(Icons.shield_outlined, color: Colors.white),
                ],
              ),
              const SizedBox(height: 30),
              Text(walletName, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Carteira criada e protegida localmente.', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Text('Credenciais', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
          child: const Column(
            children: [
              Icon(Icons.badge_outlined, size: 44),
              SizedBox(height: 12),
              Text('Ainda não existem credenciais.', style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text('A próxima etapa é permitir receber e guardar credenciais digitais verificáveis.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.add_card_outlined),
          label: const Text('Adicionar credencial — em breve'),
        ),
      ],
    );
  }

  Widget _profile() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 18),
        const Text('Definições', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),
        const Card(
          child: ListTile(
            leading: Icon(Icons.fingerprint),
            title: Text('Biometria'),
            subtitle: Text('Será integrada numa próxima versão'),
            trailing: Icon(Icons.lock_clock_outlined),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.cloud_off_outlined),
            title: Text('Modo local'),
            subtitle: Text('Esta versão não depende de conta online'),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('KARTA Alpha 0.2'),
            subtitle: Text('Digital Identity Wallet'),
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => UnlockPage(store: widget.store)),
              (_) => false,
            );
          },
          icon: const Icon(Icons.lock_outline),
          label: const Text('Bloquear KARTA'),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Apagar carteira local?'),
                    content: const Text('Isto remove a KARTA criada neste dispositivo.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
                    ],
                  ),
                ) ??
                false;
            if (!confirmed) return;
            await widget.store.deleteWallet();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => WelcomePage(store: widget.store)),
              (_) => false,
            );
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Apagar carteira deste dispositivo'),
        ),
      ],
    );
  }
}

class VerifyPage extends StatelessWidget {
  const VerifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner_rounded, size: 82),
            const SizedBox(height: 22),
            const Text('Verificar identidade', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const Text(
              'A leitura e apresentação de QR Code será ligada ao motor de credenciais verificáveis na próxima etapa.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Ler QR Code — em breve'),
            ),
          ],
        ),
      ),
    );
  }
}
