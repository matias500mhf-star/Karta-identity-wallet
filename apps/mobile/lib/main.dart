import 'package:flutter/material.dart';

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
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF111827)),
        fontFamily: 'Inter',
      ),
      home: const WalletHomePage(),
    );
  }
}

class WalletHomePage extends StatelessWidget {
  const WalletHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(child: _Header()),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              sliver: SliverToBoxAdapter(child: _IdentityCard()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My documents', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    TextButton(onPressed: () {}, child: const Text('View all')),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.builder(
                itemCount: 3,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DocumentTile(index: index),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add document'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)), child: const Text('K', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('KARTA', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.4)), Text('Your identity, secured.', style: TextStyle(color: Colors.black54))])),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
        ],
      );
}

class _IdentityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 24, offset: const Offset(0, 12))]),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('IDENTITY WALLET', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6)), Icon(Icons.verified_rounded, color: Colors.white)]),
          SizedBox(height: 36),
          Text('Your identity is ready', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text('Documents are protected and available when you need them.', style: TextStyle(color: Colors.white70, height: 1.4)),
        ]),
      );
}

class _DocumentTile extends StatelessWidget {
  final int index;
  const _DocumentTile({required this.index});

  @override
  Widget build(BuildContext context) {
    const docs = [('National ID', 'Verified', Icons.badge_outlined), ('Passport', 'Verified', Icons.public_outlined), ('Residence Permit', 'Pending', Icons.home_work_outlined)];
    final doc = docs[index];
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(children: [
            Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFF0F1F3), borderRadius: BorderRadius.circular(16)), child: Icon(doc.$3)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(doc.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(height: 5), Text(doc.$2, style: TextStyle(color: doc.$2 == 'Verified' ? Colors.green.shade700 : Colors.orange.shade700, fontWeight: FontWeight.w700, fontSize: 12))])),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ]),
        ),
      ),
    );
  }
}
