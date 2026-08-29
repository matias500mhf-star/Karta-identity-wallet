import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/session_store.dart';

void main() => runApp(const KartaApp());

class KartaApp extends StatelessWidget {
  const KartaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'KARTA',
        theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF7F8FA), colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF111827))),
        home: const AuthGate(),
      );
}

class AuthGate extends StatefulWidget { const AuthGate({super.key}); @override State<AuthGate> createState() => _AuthGateState(); }
class _AuthGateState extends State<AuthGate> {
  final api = ApiService(); final store = SessionStore(); bool loading = true;
  @override void initState() { super.initState(); _restore(); }
  Future<void> _restore() async { final token = await store.accessToken(); if (token != null) { api.accessToken = token; try { await api.me(); if (mounted) setState(() => loading = false); return; } catch (_) {} } if (mounted) setState(() => loading = false); }
  @override Widget build(BuildContext context) { if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator())); return AuthPage(api: api, store: store); }
}

class AuthPage extends StatefulWidget { final ApiService api; final SessionStore store; const AuthPage({super.key, required this.api, required this.store}); @override State<AuthPage> createState() => _AuthPageState(); }
class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController(), password = TextEditingController(); bool register = false, busy = false, obscure = true;
  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 8) { _error('Use um email válido e uma palavra-passe com pelo menos 8 caracteres.'); return; }
    setState(() => busy = true);
    try {
      if (register) { await widget.api.register(email.text.trim(), password.text); }
      final result = await widget.api.login(email.text.trim(), password.text);
      final access = result['accessToken']?.toString(), refresh = result['refreshToken']?.toString();
      if (access == null || refresh == null) throw ApiException('Resposta de autenticação incompleta.');
      await widget.store.save(accessToken: access, refreshToken: refresh); widget.api.accessToken = access;
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => WalletPage(api: widget.api, store: widget.store)));
    } catch (e) { if (mounted) _error(e.toString().replaceFirst('Exception: ', '')); } finally { if (mounted) setState(() => busy = false); }
  }
  void _error(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Container(width: 64, height: 64, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)), child: const Text('K', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900))),
    const SizedBox(height: 28), Text(register ? 'Criar conta KARTA' : 'Bem-vindo à KARTA', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(register ? 'Crie a sua carteira de identidade digital.' : 'A sua identidade. Segura e sempre consigo.', style: const TextStyle(color: Colors.black54, fontSize: 16)), const SizedBox(height: 32),
    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder())), const SizedBox(height: 16),
    TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Palavra-passe', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))), const SizedBox(height: 24),
    FilledButton(onPressed: busy ? null : submit, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(register ? 'Criar conta' : 'Entrar')),
    const SizedBox(height: 12), TextButton(onPressed: busy ? null : () => setState(() => register = !register), child: Text(register ? 'Já tenho uma conta' : 'Criar uma conta')),
  ]))))));
}

class WalletPage extends StatefulWidget { final ApiService api; final SessionStore store; const WalletPage({super.key, required this.api, required this.store}); @override State<WalletPage> createState() => _WalletPageState(); }
class _WalletPageState extends State<WalletPage> {
  int index = 0; String name = 'KARTA'; List<Map<String, dynamic>> docs = []; bool loading = true;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { try { final me = await widget.api.me(); final d = await widget.api.documents(); if (mounted) setState(() { name = (me['email'] ?? 'KARTA').toString(); docs = d; loading = false; }); } catch (_) { if (mounted) setState(() => loading = false); } }
  Future<void> logout() async { await widget.store.clear(); if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => AuthPage(api: widget.api, store: widget.store)), (_) => false); }
  @override Widget build(BuildContext context) { final pages = [_wallet(), const ScanPage(), _profile()]; return Scaffold(body: SafeArea(child: pages[index]), bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (i) => setState(() => index = i), destinations: const [NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'), NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: 'Verificar'), NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil')])); }
  Widget _wallet() => RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(20), children: [const SizedBox(height: 8), Row(children: [Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)), child: const Text('K', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))), const SizedBox(width: 12), const Expanded(child: Text('KARTA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.4))), IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded))]), const SizedBox(height: 18), Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(28)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('IDENTITY WALLET', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6)), Icon(Icons.verified_rounded, color: Colors.white)]), SizedBox(height: 32), Text('A sua identidade está protegida', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)), SizedBox(height: 8), Text('Os seus documentos ficam disponíveis de forma segura.', style: TextStyle(color: Colors.white70, height: 1.4))])), const SizedBox(height: 28), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Os meus documentos', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), TextButton(onPressed: load, child: const Text('Atualizar'))]), const SizedBox(height: 8), if (loading) const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())), if (!loading && docs.isEmpty) _empty(), if (!loading) ...docs.map(_docTile)]));
  Widget _empty() => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: const Column(children: [Icon(Icons.folder_open_outlined, size: 42), SizedBox(height: 12), Text('Ainda não existem documentos.', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('Quando a API estiver configurada, os documentos aparecerão aqui.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54))]));
  Widget _docTile(Map<String, dynamic> d) { final title = (d['title'] ?? d['documentType'] ?? 'Documento').toString(); final status = (d['status'] ?? 'PENDING').toString(); return Card(margin: const EdgeInsets.only(bottom: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)), child: ListTile(contentPadding: const EdgeInsets.all(10), leading: Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFF0F1F3), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.badge_outlined)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(status, style: const TextStyle(fontWeight: FontWeight.w700)), trailing: const Icon(Icons.chevron_right_rounded)); }
  Widget _profile() => ListView(padding: const EdgeInsets.all(20), children: [const SizedBox(height: 20), const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 42)), const SizedBox(height: 18), const Text('Perfil', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)), const SizedBox(height: 30), Card(child: ListTile(leading: const Icon(Icons.security_outlined), title: const Text('Segurança'), subtitle: const Text('Sessão protegida no dispositivo'))), Card(child: ListTile(leading: const Icon(Icons.info_outline), title: const Text('KARTA Alpha 0.1'), subtitle: const Text('Digital Identity Wallet'))), const SizedBox(height: 18), OutlinedButton.icon(onPressed: logout, icon: const Icon(Icons.logout), label: const Text('Terminar sessão'))]);
}

class ScanPage extends StatelessWidget { const ScanPage({super.key}); @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 92, height: 92, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(28)), child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 52)), const SizedBox(height: 24), const Text('Verificar identidade', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)), const SizedBox(height: 10), const Text('A verificação por QR Code será ligada ao serviço KARTA Verify na próxima etapa.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, height: 1.5)), const SizedBox(height: 24), FilledButton.icon(onPressed: null, icon: const Icon(Icons.qr_code_scanner), label: const Text('Ler QR Code'))])); }
