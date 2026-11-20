import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable, image-free agricultural scenery. Gradients, hills and
/// gold-edged waves are painted at the actual widget size, never stretched
/// from a screenshot. Only the botanical illustrations are separate SVGs.
class NaturePalette {
  const NaturePalette._();

  static const ink = Color(0xFF003B2C);
  static const forest = Color(0xFF004A38);
  static const emerald = Color(0xFF008C5B);
  static const mint = Color(0xFFD9FFF0);
  static const gold = Color(0xFFFFD58A);

  static List<Color> page(bool dark) => dark
      ? const [
          Color(0xFF002920),
          Color(0xFF004836),
          Color(0xFF003A30),
          Color(0xFF002D26),
        ]
      : const [
          Color(0xFFE7FAEF),
          Color(0xFFF7FFF9),
          Color(0xFFEEFFF8),
          Color(0xFFDCF9E8),
        ];

  static List<Color> header(bool dark) => dark
      ? const [
          Color(0xFF00271E),
          Color(0xFF00654B),
          Color(0xFF004130),
        ]
      : const [
          Color(0xFF00392F),
          Color(0xFF008565),
          Color(0xFF006749),
        ];
}

/// Can be put behind login, onboarding, dashboard and other pages.
class NatureBackdrop extends StatelessWidget {
  const NatureBackdrop({
    super.key,
    required this.dark,
    this.showOrnaments = true,
    this.showFooter = true,
  });

  final bool dark;
  final bool showOrnaments;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (context, bounds) {
        final width = bounds.maxWidth;
        final height = bounds.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: NaturePalette.page(dark),
                  stops: const [0, .36, .71, 1],
                ),
              ),
            ),
            Positioned(
              top: height * .22,
              left: width * -.42,
              width: width * 1.5,
              height: height * .5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: dark
                        ? const [Color(0x2202A576), Colors.transparent]
                        : const [Color(0x99FFFFFF), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _NatureLandscapePainter(dark: dark, reverse: rtl),
              ),
            ),
            if (showOrnaments) ...[
              PositionedDirectional(
                top: height * .22,
                end: -19,
                child: Opacity(
                  opacity: dark ? .19 : .27,
                  child: _Botanical(
                    'assets/decorations/mazraa_sprig.svg',
                    width: width.clamp(290.0, 580.0).toDouble() * .37,
                    flip: rtl,
                  ),
                ),
              ),
              PositionedDirectional(
                top: height * .48,
                start: -45,
                child: Opacity(
                  opacity: dark ? .13 : .12,
                  child: _Botanical(
                    'assets/decorations/mazraa_sprig.svg',
                    width: width.clamp(290.0, 580.0).toDouble() * .39,
                    flip: !rtl,
                  ),
                ),
              ),
              PositionedDirectional(
                bottom: height * .16,
                end: -35,
                child: Opacity(
                  opacity: dark ? .25 : .22,
                  child: _Botanical(
                    'assets/decorations/mazraa_sprig.svg',
                    width: width.clamp(290.0, 580.0).toDouble() * .36,
                    flip: rtl,
                  ),
                ),
              ),
            ],
            if (showFooter)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 115,
                child: NatureWaveBand(
                  dark: dark,
                  footer: true,
                  reverse: rtl,
                ),
              ),
            if (showOrnaments && showFooter) ...[
              PositionedDirectional(
                bottom: -12,
                start: -14,
                child: Opacity(
                  opacity: dark ? .9 : .72,
                  child: _Botanical(
                    'assets/decorations/mazraa_branch.svg',
                    width: width.clamp(290.0, 570.0).toDouble() * .30,
                    flip: !rtl,
                  ),
                ),
              ),
              PositionedDirectional(
                bottom: -11,
                end: -12,
                child: _Botanical(
                  'assets/decorations/mazraa_flora.svg',
                  width: width.clamp(290.0, 570.0).toDouble() * .34,
                  flip: rtl,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Reusable wave band: [footer] selects hill/field waves rather than a header.
/// Both variants use cubic paths and independent gold/emerald layers.
class NatureWaveBand extends StatelessWidget {
  const NatureWaveBand({
    super.key,
    required this.dark,
    this.footer = false,
    this.reverse = false,
  });
  final bool dark;
  final bool footer;
  final bool reverse;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _NatureWavePainter(
          dark: dark,
          footer: footer,
          reverse: reverse,
        ),
        child: const SizedBox.expand(),
      );
}

/// Images are self-contained transparent vector assets, not screen backgrounds.
class NatureIllustration extends StatelessWidget {
  const NatureIllustration({
    super.key,
    required this.asset,
    required this.width,
    this.opacity = 1,
    this.flip = false,
  });
  final String asset;
  final double width;
  final double opacity;
  final bool flip;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: opacity,
        child: _Botanical(asset, width: width, flip: flip),
      );
}

class _Botanical extends StatelessWidget {
  const _Botanical(this.asset, {required this.width, required this.flip});
  final String asset;
  final double width;
  final bool flip;

  @override
  Widget build(BuildContext context) => Transform.flip(
        flipX: flip,
        child: SvgPicture.asset(
          asset,
          width: width,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      );
}

class _NatureWavePainter extends CustomPainter {
  const _NatureWavePainter({
    required this.dark,
    required this.footer,
    required this.reverse,
  });
  final bool dark;
  final bool footer;
  final bool reverse;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (reverse) {
      canvas.save();
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    if (footer) {
      _footer(canvas, size);
    } else {
      _header(canvas, size);
    }
    if (reverse) canvas.restore();
  }

  void _header(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;

    final lower = Path()
      ..moveTo(0, h * .62)
      ..cubicTo(w * .28, h * .99, w * .43, h * .27, w * .68, h * .57)
      ..cubicTo(w * .85, h * .78, w * .92, h * .61, w, h * .16)
      ..lineTo(w, 0)
      ..lineTo(0, 0)
      ..close();
    c.drawPath(
      lower,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: NaturePalette.header(dark),
        ).createShader(Offset.zero & s),
    );
    final gold = Path()
      ..moveTo(0, h * .625)
      ..cubicTo(w * .28, h * .99, w * .43, h * .27, w * .68, h * .57)
      ..cubicTo(w * .85, h * .78, w * .92, h * .61, w, h * .16);
    c.drawPath(
      gold,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFD58A), Color(0xFFFFE5AF), Color(0xFF95D99D), Color(0xFFFFD58A)],
        ).createShader(Offset.zero & s),
    );
    final green = Path()
      ..moveTo(0, h * .705)
      ..cubicTo(w * .28, h * 1.09, w * .43, h * .38, w * .68, h * .64)
      ..cubicTo(w * .85, h * .86, w * .92, h * .69, w, h * .25);
    c.drawPath(
      green,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..shader = const LinearGradient(
          colors: [Color(0xFF008F60), Color(0xFF1BD093), Color(0xFF98D58E)],
        ).createShader(Offset.zero & s),
    );
  }

  void _footer(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    for (var layer = 0; layer < 4; layer++) {
      final y = h * (.31 + layer * .14);
      final path = Path()
        ..moveTo(0, y)
        ..cubicTo(w * .24, y - 53, w * .36, y + 64, w * .55, y + 25)
        ..cubicTo(w * .73, y - 13, w * .82, y - 49, w, y - 26)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      c.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [
                    Color.lerp(const Color(0xFF006649), const Color(0xFF00402F), layer / 4)!,
                    Color.lerp(const Color(0xFF005C47), const Color(0xFF002C26), layer / 4)!,
                  ]
                : [
                    Color.lerp(const Color(0xFFCAF4E1), const Color(0xFF5BCC9B), layer / 4)!,
                    Color.lerp(const Color(0xFFB7EBC9), const Color(0xFF00845C), layer / 4)!,
                  ],
          ).createShader(Offset.zero & s),
      );
    }
    final gold = Path()
      ..moveTo(0, h * .69)
      ..cubicTo(w * .23, h * .02, w * .41, h * 1.35, w * .62, h * .76)
      ..cubicTo(w * .82, h * .24, w * .88, h * .18, w, h * .43);
    c.drawPath(
      gold,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFD990), Color(0xFFFFE8B6), Color(0xFFC9DB8D), Color(0xFFFFD082)],
        ).createShader(Offset.zero & s),
    );
  }

  @override
  bool shouldRepaint(covariant _NatureWavePainter old) =>
      old.dark != dark || old.footer != footer || old.reverse != reverse;
}

class _NatureLandscapePainter extends CustomPainter {
  const _NatureLandscapePainter({required this.dark, required this.reverse});
  final bool dark;
  final bool reverse;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (reverse) {
      canvas.save();
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final w = size.width;
    final h = size.height;
    final horizon = h * .82;
    final hill = Path()
      ..moveTo(0, horizon + 8)
      ..cubicTo(w * .2, horizon - 47, w * .28, horizon + 39, w * .51, horizon + 5)
      ..cubicTo(w * .77, horizon - 48, w * .89, horizon - 40, w, horizon - 9)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      hill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0x1809B77F), Color(0x00002A20)]
              : const [Color(0x6686DDB5), Color(0x00D7F8E4)],
        ).createShader(Offset.zero & size),
    );
    if (!dark) {
      for (var i = 0; i < 6; i++) {
        final stripe = Path()
          ..moveTo(-w * .2, horizon + 92 + i * 13)
          ..quadraticBezierTo(w * .35, horizon + 50 - i * 8, w * 1.2, horizon - 18 + i * 11);
        canvas.drawPath(
          stripe,
          Paint()
            ..color = const Color(0x2256B88F)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
      }
    }
    if (reverse) canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NatureLandscapePainter old) =>
      old.dark != dark || old.reverse != reverse;
}
