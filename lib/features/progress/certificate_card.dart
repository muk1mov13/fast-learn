import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';

/// Sertifikatni to'liq Flutter'da chizadigan premium widget.
///
/// PNG rasm o'rniga ishlatiladi — shu sababli talaba ismi va markaziy muhr
/// dinamik bo'ladi (overlap muammosi yo'q), va `RepaintBoundary` orqali toza
/// sifatli PDF yuklab olish mumkin.
class CertificateCard extends StatelessWidget {
  final String studentName;
  final String dateText;

  const CertificateCard({
    super.key,
    required this.studentName,
    required this.dateText,
  });

  // Dizayn ranglari (sertifikat.svg dan)
  static const _navy = Color(0xFF13224A);
  static const _muted = Color(0xFF6A7388);
  static const _ink = Color(0xFF1A2238);
  static const _goldA = Color(0xFFF4C66B);
  static const _goldB = Color(0xFFC9912F);

  static const _goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_goldA, _goldB],
  );

  @override
  Widget build(BuildContext context) {
    final hasName = studentName.trim().isNotEmpty;

    return AspectRatio(
      aspectRatio: 1600 / 1131,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          // SVG koordinata tizimi 1600 px keng — barcha o'lchamlar shunga
          // proporsional bo'lishi uchun masshtab koeffitsienti.
          final s = w / 1600;
          double sp(double svg) => svg * s;

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.36),
                radius: 0.95,
                colors: [Color(0xFFFFFFFF), Color(0xFFFBFAF5)],
              ),
            ),
            child: CustomPaint(
              painter: _CertificateFramePainter(s: s),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: sp(118),
                  vertical: sp(86),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Sarlavha bloki ──────────────────────────────
                    Column(
                      children: [
                        _TopEmblem(size: sp(84)),
                        SizedBox(height: sp(16)),
                        Text(
                          'BUXORO DAVLAT PEDAGOGIKA INSTITUTI',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.sora(
                            fontSize: sp(17),
                            fontWeight: FontWeight.w700,
                            letterSpacing: sp(3),
                            color: _navy,
                          ),
                        ),
                        SizedBox(height: sp(10)),
                        _GoldDivider(width: sp(300), height: sp(2)),
                        SizedBox(height: sp(20)),
                        ShaderMask(
                          shaderCallback: (r) => const LinearGradient(
                            colors: [Color(0xFF13224A), Color(0xFF24407F)],
                          ).createShader(r),
                          child: Text(
                            'SERTIFIKAT',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.sora(
                              fontSize: sp(74),
                              fontWeight: FontWeight.w800,
                              letterSpacing: sp(14),
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                        SizedBox(height: sp(6)),
                        Text(
                          'muvaffaqiyatli yakunlagani uchun',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: sp(21),
                            fontStyle: FontStyle.italic,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),

                    // ── Markaziy blok: ism + matn + muhr ────────────
                    Column(
                      children: [
                        Text(
                          'Ushbu sertifikat',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: sp(19),
                            color: _ink,
                          ),
                        ),
                        SizedBox(height: sp(14)),
                        // Talaba ismi — bitta marta render qilinadi (overlap yo'q)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            hasName
                                ? studentName.trim()
                                : '[ Talaba ismi va familiyasi ]',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: GoogleFonts.sora(
                              fontSize: sp(46),
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                              fontStyle: hasName
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                          ),
                        ),
                        SizedBox(height: sp(8)),
                        Container(
                          width: sp(760),
                          height: sp(1.5),
                          color: _muted.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: sp(20)),
                        Text(
                          '“Texnik ijodkorlik va konstruksiyalash” fani bo‘yicha '
                          'barcha 8 mavzuni',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: sp(21),
                            color: _ink,
                            height: 1.45,
                          ),
                        ),
                        Text(
                          'to‘liq o‘zlashtirib, yuqori natijaga erishgani uchun '
                          'taqdim etiladi.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: sp(21),
                            color: _ink,
                            height: 1.45,
                          ),
                        ),
                        SizedBox(height: sp(22)),
                        // 90%+ o'rniga: oltin medal + yulduz muhri
                        _MedalSeal(size: sp(150)),
                      ],
                    ),

                    // ── Pastki blok: imzolar + futer ────────────────
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _SignatureLine(
                              s: s,
                              label: 'Sana',
                              value: dateText,
                            ),
                            _SignatureLine(
                              s: s,
                              label: 'O\'qituvchi imzosi',
                              value: '',
                            ),
                          ],
                        ),
                        SizedBox(height: sp(18)),
                        Text(
                          'TEXNIK IJODKORLIK VA KONSTRUKSIYALASH',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.sora(
                            fontSize: sp(13),
                            fontWeight: FontWeight.w700,
                            letterSpacing: sp(3),
                            color: _navy.withValues(alpha: 0.85),
                          ),
                        ),
                        SizedBox(height: sp(3)),
                        Text(
                          'mobil o\'quv ilovasi',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: sp(12),
                            fontStyle: FontStyle.italic,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Yuqori emblema — ko'k doira, oltin halqa va akademik shapka ikonkasi.
class _TopEmblem extends StatelessWidget {
  final double size;
  const _TopEmblem({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        border: Border.all(
          color: CertificateCard._goldA,
          width: size * 0.045,
        ),
      ),
      child: Icon(
        Icons.school_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  final double width;
  final double height;
  const _GoldDivider({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(gradient: CertificateCard._goldGradient),
    );
  }
}

/// Imzo chizig'i: tepada qiymat (sana / imzo), chiziq, ostida yorliq.
class _SignatureLine extends StatelessWidget {
  final double s;
  final String label;
  final String value;
  const _SignatureLine({
    required this.s,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 20 * s,
          child: Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 16 * s,
              fontWeight: FontWeight.w600,
              color: CertificateCard._navy,
            ),
          ),
        ),
        Container(width: 260 * s, height: 1.5 * s, color: CertificateCard._navy),
        SizedBox(height: 6 * s),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 16 * s,
            fontWeight: FontWeight.w600,
            letterSpacing: s,
            color: CertificateCard._muted,
          ),
        ),
      ],
    );
  }
}

/// Markaziy oltin medal: nurlar (laurel), oltin doira, oq halqa, yulduz va
/// "A'LO" yozuvi, hamda lentachalar (ribbon).
class _MedalSeal extends StatelessWidget {
  final double size;
  const _MedalSeal({required this.size});

  @override
  Widget build(BuildContext context) {
    final d = size;
    final circle = d * 0.66;
    return SizedBox(
      width: d,
      height: d * 1.18,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Lentachalar (medalning orqasida, pastda)
          Positioned(
            top: d * 0.5,
            child: _Ribbon(width: d * 0.5, height: d * 0.55),
          ),
          // Nur (laurel) chiziqlari
          SizedBox(
            width: d,
            height: d,
            child: CustomPaint(painter: _SealRaysPainter()),
          ),
          // Oltin doira
          Positioned(
            top: (d - circle) / 2,
            child: Container(
              width: circle,
              height: circle,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: CertificateCard._goldGradient,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x55C9912F),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(circle * 0.08),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.75),
                      width: circle * 0.025,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: circle * 0.42,
                      ),
                      Text(
                        'A\'LO',
                        style: GoogleFonts.sora(
                          fontSize: circle * 0.16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: circle * 0.02,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Medal ostidagi ikki lentacha (ribbon).
class _Ribbon extends StatelessWidget {
  final double width;
  final double height;
  const _Ribbon({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width * 1.7,
      height: height,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Transform.rotate(
            angle: 0.32,
            alignment: Alignment.topCenter,
            child: _ribbonTail(),
          ),
          Transform.rotate(
            angle: -0.32,
            alignment: Alignment.topCenter,
            child: _ribbonTail(),
          ),
        ],
      ),
    );
  }

  Widget _ribbonTail() {
    return ClipPath(
      clipper: _RibbonTailClipper(),
      child: Container(
        width: width * 0.42,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1463FF), Color(0xFF0B46C0)],
          ),
        ),
      ),
    );
  }
}

class _RibbonTailClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(size.width, 0);
    p.lineTo(size.width, size.height);
    p.lineTo(size.width / 2, size.height - size.width * 0.5);
    p.lineTo(0, size.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Medal atrofidagi nur (laurel) chiziqlari.
class _SealRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final inner = size.width * 0.40;
    final outer = size.width * 0.49;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [CertificateCard._goldA, CertificateCard._goldB],
      ).createShader(Rect.fromCircle(center: center, radius: outer))
      ..strokeWidth = size.width * 0.018
      ..strokeCap = StrokeCap.round;

    const count = 28;
    for (var i = 0; i < count; i++) {
      final a = (2 * math.pi / count) * i;
      final p1 = center + Offset(math.cos(a), math.sin(a)) * inner;
      final p2 = center + Offset(math.cos(a), math.sin(a)) * outer;
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Sertifikat ramkasi: navy tashqi chegara, oltin ichki chegara, burchak
/// bezaklari va markazdagi xira konsentrik doiralar.
class _CertificateFramePainter extends CustomPainter {
  final double s;
  _CertificateFramePainter({required this.s});

  @override
  void paint(Canvas canvas, Size size) {
    // Markazdagi xira konsentrik doiralar
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s
      ..color = AppColors.primary.withValues(alpha: 0.05);
    final cc = Offset(800 * s, 430 * s);
    for (final r in [300.0, 230.0, 160.0]) {
      canvas.drawCircle(cc, r * s, faint);
    }

    // Tashqi navy ramka
    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(46 * s, 46 * s, 1508 * s, 1039 * s),
      Radius.circular(10 * s),
    );
    final navyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 * s
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B2E5E), Color(0xFF0E1C40)],
      ).createShader(outerRect.outerRect);
    canvas.drawRRect(outerRect, navyPaint);

    // Ichki oltin ramka
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(62 * s, 62 * s, 1476 * s, 1007 * s),
      Radius.circular(6 * s),
    );
    final goldStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [CertificateCard._goldA, CertificateCard._goldB],
      ).createShader(innerRect.outerRect);
    canvas.drawRRect(innerRect, goldStroke);

    // Burchak bezaklari
    _drawCorners(canvas, size);
  }

  void _drawCorners(Canvas canvas, Size size) {
    final goldFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [CertificateCard._goldA, CertificateCard._goldB],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final goldLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * s
      ..shader = goldFill.shader;

    // (x, y, dirX, dirY) — har bir burchak ichkariga yo'naladi
    final corners = [
      [92.0, 92.0, 1.0, 1.0],
      [1508.0, 92.0, -1.0, 1.0],
      [92.0, 1039.0, 1.0, -1.0],
      [1508.0, 1039.0, -1.0, -1.0],
    ];
    for (final c in corners) {
      final x = c[0] * s, y = c[1] * s, dx = c[2], dy = c[3];
      // L-shaklidagi ikki chiziq
      canvas.drawLine(Offset(x, y), Offset(x + 90 * s * dx, y), goldLine);
      canvas.drawLine(Offset(x, y), Offset(x, y + 90 * s * dy), goldLine);
      // 45° burilgan romb
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(math.pi / 4);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 14 * s),
        goldFill,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CertificateFramePainter oldDelegate) =>
      oldDelegate.s != s;
}
