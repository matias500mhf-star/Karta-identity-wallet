import 'package:flutter/material.dart';

/// KARTA visual identity. HMATIAS remains the institutional owner signature,
/// while the product itself uses a distinct identity-wallet brand system.
class HmatiasBrand {
  static const midnight = Color(0xFF04111F);
  static const navy = Color(0xFF062D56);
  static const blue = Color(0xFF087CFF);
  static const cyan = Color(0xFF21DFF2);
  static const mint = Color(0xFF58F3CF);
  static const sky = Color(0xFF48BAF5);
  static const ink = Color(0xFF102D4D);
  static const muted = Color(0xFF627387);
  static const light = Color(0xFFF4F8FC);
  static const border = Color(0xFFDCE6F0);

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(seedColor: blue).copyWith(
      primary: blue,
      onPrimary: Colors.white,
      secondary: navy,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: ink,
      outline: muted,
      outlineVariant: border,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: scheme,
      scaffoldBackgroundColor: light,
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
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
        backgroundColor: Colors.white,
        foregroundColor: navy,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: blue, width: 2),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFDCEEFF),
      ),
    );
  }
}

/// Vector KARTA mark used inside the Flutter UI. It deliberately avoids a
/// raster dependency so the symbol remains crisp at every device density.
class KartaMark extends StatelessWidget {
  const KartaMark({
    super.key,
    this.size = 72,
    this.withBackground = true,
    this.monochrome = false,
  });

  final double size;
  final bool withBackground;
  final bool monochrome;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: withBackground ? HmatiasBrand.midnight : Colors.transparent,
            borderRadius: BorderRadius.circular(size * .24),
            border: withBackground
                ? Border.all(color: const Color(0x3321DFF2))
                : null,
            boxShadow: withBackground
                ? const [
                    BoxShadow(
                      color: Color(0x33087CFF),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(size * .14),
            child: CustomPaint(
              painter: _KartaMarkPainter(monochrome: monochrome),
            ),
          ),
        ),
      );
}

class _KartaMarkPainter extends CustomPainter {
  const _KartaMarkPainter({required this.monochrome});

  final bool monochrome;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..isAntiAlias = true;
    if (monochrome) {
      paint.color = Colors.white;
    } else {
      paint.shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          HmatiasBrand.mint,
          HmatiasBrand.cyan,
          HmatiasBrand.blue,
          Color(0xFF575BFF),
        ],
        stops: [0, .32, .68, 1],
      ).createShader(rect);
    }

    final w = size.width;
    final h = size.height;
    final radius = Radius.circular(w * .07);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .10, h * .05, w * .22, h * .90),
        radius,
      ),
      paint,
    );

    final upper = Path()
      ..moveTo(w * .27, h * .52)
      ..lineTo(w * .72, h * .06)
      ..quadraticBezierTo(w * .77, h * .01, w * .84, h * .04)
      ..lineTo(w * .92, h * .10)
      ..quadraticBezierTo(w * .96, h * .15, w * .91, h * .20)
      ..lineTo(w * .43, h * .66)
      ..close();
    canvas.drawPath(upper, paint);

    final lower = Path()
      ..moveTo(w * .38, h * .49)
      ..lineTo(w * .91, h * .83)
      ..quadraticBezierTo(w * .98, h * .88, w * .93, h * .94)
      ..lineTo(w * .85, h * .99)
      ..quadraticBezierTo(w * .80, h, w * .75, h * .96)
      ..lineTo(w * .27, h * .61)
      ..close();
    canvas.drawPath(lower, paint);
  }

  @override
  bool shouldRepaint(covariant _KartaMarkPainter oldDelegate) =>
      oldDelegate.monochrome != monochrome;
}

class KartaBrandHeader extends StatelessWidget {
  const KartaBrandHeader({super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              KartaMark(size: 74),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KARTA',
                      style: TextStyle(
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                        color: HmatiasBrand.navy,
                        letterSpacing: 5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'IDENTITY WALLET',
                      style: TextStyle(
                        color: HmatiasBrand.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Os teus documentos. A tua identidade. Sob o teu controlo.',
            style: TextStyle(
              color: HmatiasBrand.ink,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Um produto HMATIAS',
            style: TextStyle(
              color: HmatiasBrand.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}
