import 'package:flutter/material.dart';

/// Shared with the HMATIAS website's style.css and typography.css.
class HmatiasBrand {
  static const navy = Color(0xFF062D56);
  static const blue = Color(0xFF0065CC);
  static const sky = Color(0xFF48BAF5);
  static const ink = Color(0xFF102D4D);
  static const muted = Color(0xFF627387);
  static const light = Color(0xFFF4F8FC);
  static const border = Color(0xFFDCE6F0);

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(seedColor: blue).copyWith(
      primary: blue, onPrimary: Colors.white,
      secondary: navy, onSecondary: Colors.white,
      surface: Colors.white, onSurface: ink,
      outline: muted, outlineVariant: border,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: scheme,
      scaffoldBackgroundColor: light,
      cardTheme: CardThemeData(
        color: Colors.white, surfaceTintColor: Colors.transparent,
        elevation: 0, margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, space: 28),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        iconColor: blue,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white, foregroundColor: navy,
        surfaceTintColor: Colors.transparent, centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: blue, foregroundColor: Colors.white,
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: navy, minimumSize: const Size(48, 48),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      )),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: blue, width: 2),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white, indicatorColor: Color(0xFFDCEEFF),
      ),
    );
  }
}

class KartaBrandHeader extends StatelessWidget {
  const KartaBrandHeader({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Image.asset('assets/brand/hmatias.png', height: 84, fit: BoxFit.contain,
        semanticLabel: 'HMATIAS — Prestação de Serviços'),
      const SizedBox(height: 20),
      Container(width: 40, height: 4, color: HmatiasBrand.sky),
      const SizedBox(height: 12),
      const Text('KARTA', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
        color: HmatiasBrand.navy, letterSpacing: 1.6)),
      const Text('Um produto HMATIAS', style: TextStyle(color: HmatiasBrand.muted,
        fontWeight: FontWeight.w600)),
    ],
  );
}
