import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/litly_mascot.dart';

import 'package:litly/database/db_helper.dart';
import 'package:litly/screens/home.dart';
import 'package:litly/screens/login.dart';
import 'package:litly/services/session_service.dart';

final Color _yellow = Color(0xFFFAE696);
final Color _purple = Color(0xFF6A4D67);
final Color _buttonColor = Color(0xFF6A4D67);

class SplashScreen extends StatefulWidget {
  SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _splashDuration = Duration(milliseconds: 6500);

  late final AnimationController _c;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _splashDuration)..forward();
    _restoreRememberedSession();
  }

  Future<void> _restoreRememberedSession() async {
    final splashAnimation = Future<void>.delayed(_splashDuration);
    try {
      if (!await SessionService.isSessionActive()) return;

      final sessionData = await SessionService.getSessionData();
      final email = sessionData['user_email'] as String? ?? '';
      if (email.isEmpty) return;

      final user = await DbHelper().getUserByEmail(email);
      if (user == null) return;

      await splashAnimation;
      if (!mounted || _hasNavigated) return;

      _hasNavigated = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(username: user.name)),
      );
    } catch (error) {
      await splashAnimation;
      if (!mounted || _hasNavigated) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memulihkan sesi: $error')));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Ambil progress 0..1 dari satu segmen waktu (begin..end) dengan curve tertentu
  double _seg(double t, double b, double e, [Curve curve = Curves.linear]) =>
      Interval(b, e, curve: curve).transform(t);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Ukuran bintang (radius terluar)
    final r3 =
        size.width * 0.55; // gambar 3: bintang besar, sebagian keluar layar
    final double r4 =
        85.0; // gambar 4: ukuran bintang kecil (sesuaikan dgn PNG)
    final halfDiag =
        sqrt(size.width * size.width + size.height * size.height) / 2;
    final r0 =
        halfDiag /
        0.4; // sangat besar -> bintang menutupi seluruh layar (gambar 1)

    final double mascotWidth = 215.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;

          // ---------- TIMELINE ----------
          // 0.00-0.08  mata diam
          // 0.08-0.22  kedip (mata kanan nutup lalu buka)
          // 0.26-0.46  kuning mengecil jadi bentuk bintang (gambar 3)
          // 0.50-0.74  bintang mengecil ke ukuran maskot (gambar 4)
          // 0.62-0.80  crossfade bintang polos -> PNG maskot
          // 0.78-0.90  maskot naik sedikit (gambar 5)
          // 0.88-1.00  teks & tombol muncul
          final blinkOpen =
              (1 -
                      _seg(t, 0.08, 0.13, Curves.easeIn) +
                      _seg(t, 0.17, 0.22, Curves.easeOut))
                  .clamp(0.0, 1.0);

          final s1 = _seg(t, 0.26, 0.46, Curves.easeInOutCubic);
          final s2 = _seg(t, 0.50, 0.74, Curves.easeInOutCubic);

          // Skala eksponensial -> terasa lebih smooth daripada linear
          final shrink2 = pow(r4 / r3, s2).toDouble();
          final starRadius = r0 * pow(r3 / r0, s1).toDouble() * shrink2;

          final eyeScale = shrink2;
          final eyeOpacity = 1 - _seg(t, 0.62, 0.72);
          final starOpacity = 1 - _seg(t, 0.70, 0.80);
          final mascotOpacity = _seg(t, 0.66, 0.78);

          final moveUp = _seg(t, 0.78, 0.90, Curves.easeOutCubic);
          final mascotDy = -65 * moveUp;

          final uiT = _seg(t, 0.88, 1.0, Curves.easeOut);

          return SafeArea(
            child: Stack(
              children: [
                // Bintang kuning + mata (digambar pakai CustomPainter)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StarEyesPainter(
                      starRadius: starRadius,
                      starOpacity: starOpacity,
                      eyeScale: eyeScale,
                      eyeOpacity: eyeOpacity,
                      rightEyeOpen: blinkOpen,
                    ),
                  ),
                ),

                // Maskot PNG
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: mascotOpacity,
                      child: Transform.translate(
                        offset: Offset(0, mascotDy),
                        child: LitlyMascot(
                          mood: LitlyMood.excited,
                          width: mascotWidth,
                        ),
                      ),
                    ),
                  ),
                ),

                // Judul
                Positioned(
                  top: size.height * 0.10,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: uiT,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - uiT)),
                      child: Text(
                        'Selamat datang di\nLITLY',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),

                // Subtitle
                Positioned(
                  top: size.height * 0.58,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: uiT,
                    child: Text(
                      'Aku Liti sahabat yang akan\nmenemani perjalanan kamu',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 2,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                // Tombol
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: uiT,
                    child: Center(
                      child: SizedBox(
                        width: 162,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: uiT >= 1
                              ? () {
                                  _hasNavigated = true;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LoginScreen(),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonColor,
                            disabledBackgroundColor: _buttonColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Letss goww',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StarEyesPainter extends CustomPainter {
  final double starRadius;
  final double starOpacity;
  final double eyeScale;
  final double eyeOpacity;
  final double rightEyeOpen; // 1 = terbuka, 0 = nutup (jadi garis)

  _StarEyesPainter({
    required this.starRadius,
    required this.starOpacity,
    required this.eyeScale,
    required this.eyeOpacity,
    required this.rightEyeOpen,
  });

  // Bintang 5 sudut dengan sudut membulat
  Path _roundedStar(Offset c, double outer) {
    final inner = outer * 0.5;
    final corner = outer * 0.15;
    final int n = 10;

    final pts = List.generate(n, (i) {
      final rad = i.isEven ? outer : inner;
      final a = -pi / 2 + i * pi / 5;
      return c + Offset(cos(a) * rad, sin(a) * rad);
    });

    final path = Path();
    for (var i = 0; i < n; i++) {
      final prev = pts[(i - 1 + n) % n];
      final cur = pts[i];
      final next = pts[(i + 1) % n];

      final d1 = prev - cur;
      final d2 = next - cur;
      final cut = min(corner, min(d1.distance, d2.distance) / 2);
      final p1 = cur + d1 / d1.distance * cut;
      final p2 = cur + d2 / d2.distance * cut;

      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.quadraticBezierTo(cur.dx, cur.dy, p2.dx, p2.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    // Bintang kuning
    if (starOpacity > 0) {
      canvas.drawPath(
        _roundedStar(c, starRadius),
        Paint()..color = _yellow.withValues(alpha: starOpacity.clamp(0, 1)),
      );
    }

    // Mata
    if (eyeOpacity <= 0) return;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(eyeScale);

    final purple = Paint()
      ..color = _purple.withValues(alpha: eyeOpacity.clamp(0, 1));
    final white = Paint()
      ..color = Colors.white.withValues(alpha: eyeOpacity.clamp(0, 1));

    void openEye(double cx, double open) {
      final h = 51.0 * open;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, 0), width: 37, height: h),
        purple,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - 4, 2 * open),
          width: 13,
          height: 25 * open,
        ),
        white,
      );
    }

    // Mata kiri selalu terbuka
    openEye(-26, 1);

    // Mata kanan: oval saat terbuka, garis lengkung saat nutup (wink)
    if (rightEyeOpen > 0.2) {
      openEye(26, rightEyeOpen);
    } else {
      final arc = Path()
        ..moveTo(12, -3)
        ..quadraticBezierTo(30, 6, 48, -3);
      canvas.drawPath(
        arc,
        Paint()
          ..color = _purple.withValues(alpha: eyeOpacity.clamp(0, 1))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StarEyesPainter old) => true;
}
