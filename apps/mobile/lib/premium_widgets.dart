import 'package:flutter/material.dart';
import 'brand_theme.dart';

class WalletHero extends StatelessWidget {
  const WalletHero({super.key, required this.name, required this.credentialCount});
  final String name;
  final int credentialCount;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [HmatiasBrand.navy, Color(0xFF074880), HmatiasBrand.blue],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [BoxShadow(color: Color(0x22062D56), blurRadius: 24, offset: Offset(0, 12))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Icon(Icons.blur_on_rounded, color: HmatiasBrand.sky, size: 32),
        Text('KARTA', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
        Text('IDENTITY WALLET', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5)),
      ]),
      const SizedBox(height: 36),
      const Text('A SUA CARTEIRA', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 2)),
      const SizedBox(height: 8),
      Text(name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
      const SizedBox(height: 26),
      Wrap(spacing: 18, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_outline_rounded, color: HmatiasBrand.sky, size: 16),
          SizedBox(width: 6),
          Text('Armazenamento local', style: TextStyle(color: Colors.white, fontSize: 12)),
        ]),
        Text('$credentialCount credenciais', style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    ]),
  );
}

class KartaAction extends StatelessWidget {
  const KartaAction({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: HmatiasBrand.blue),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: HmatiasBrand.muted, fontSize: 12, height: 1.5)),
        ]),
      ),
    ),
  );
}

class KartaActionPair extends StatelessWidget {
  const KartaActionPair({super.key, required this.first, required this.second});
  final Widget first;
  final Widget second;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    if (constraints.maxWidth < 340 || MediaQuery.textScalerOf(context).scale(16) > 22) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [first, second]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: first), const SizedBox(width: 12), Expanded(child: second),
    ]);
  });
}

class KartaEmptyState extends StatelessWidget {
  const KartaEmptyState({super.key, required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: Column(children: [
      Icon(icon, color: HmatiasBrand.blue, size: 40),
      const SizedBox(height: 16),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: HmatiasBrand.muted, height: 1.5)),
    ]),
  ));
}
