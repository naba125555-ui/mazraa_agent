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
                height: (height * .20).clamp(130.0, 220.0),
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

/// Pure canvas geometry: the artwork is created at runtime at the device's
/// logical pixel size, and is never a bitmap, SVG or clipped screenshot.
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

  // The header wave is calculated entirely as proportions of the widget.
  // Its three bezier sections intentionally leave plenty of clear space for
  // the form and keep the title on the green area in either text direction.
  Path _headerCurve(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(0, h * .58)
      ..cubicTo(w * .18, h * .77, w * .32, h * .40, w * .52, h * .72)
      ..cubicTo(w * .70, h * .98, w * .85, h * .80, w, h * .90);
  }

  void _header(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final curve = _headerCurve(size);
    final rect = Offset.zero & size;

    // A broad emerald edge is painted first, then the dark green top wave
    // is filled over it, creating depth without any decorative image.
    canvas.drawPath(
      curve,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 23
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF009567),
            Color(0xFF14BD82),
            Color(0xFF74CE91),
            Color(0xFF008E65),
          ],
        ).createShader(rect),
    );

    final headerFill = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * .90)
      ..cubicTo(w * .85, h * .80, w * .70, h * .98, w * .52, h * .72)
      ..cubicTo(w * .32, h * .40, w * .18, h * .77, 0, h * .58)
      ..close();
    canvas.drawPath(
      headerFill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, .45, 1],
          colors: dark
              ? const [
                  Color(0xFF002C24),
                  Color(0xFF00634C),
                  Color(0xFF003A2D),
                ]
              : const [
                  Color(0xFF003B30),
                  Color(0xFF008366),
                  Color(0xFF005740),
                ],
        ).createShader(rect),
    );

    // Separate gold and highlight paths produce the slim flowing trim.
    canvas.drawPath(
      curve,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFD39E4C),
            Color(0xFFFFE9B5),
            Color(0xFFFFD27A),
            Color(0xFFFFF0BF),
          ],
        ).createShader(rect),
    );
    canvas.drawPath(
      curve,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xAAFFF5D4),
    );
  }

  Path _hillLine(Size size, int index) {
    final w = size.width;
    final h = size.height;
    final offset = index * .105;
    return Path()
      ..moveTo(0, h * (.32 + offset))
      ..cubicTo(
        w * .17, h * (.12 + offset),
        w * .32, h * (.77 + offset),
        w * .55, h * (.49 + offset),
      )
      ..cubicTo(
        w * .76, h * (.18 + offset),
        w * .87, h * (.14 + offset),
        w, h * (.38 + offset),
      );
  }

  void _footer(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // Landscape bands mimic layered agricultural terraces. Each band is a
    // real filled cubic path rather than a flattened background picture.
    for (var i = 0; i < 5; i++) {
      final line = _hillLine(size, i);
      final path = Path.from(line)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      final t = i / 4;
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [
                    Color.lerp(
                      const Color(0xFF007D58),
                      const Color(0xFF00432F), t)!,
                    Color.lerp(
                      const Color(0xFF006345),
                      const Color(0xFF002B25), t)!,
                  ]
                : [
                    Color.lerp(
                      const Color(0xFFC8F7DF),
                      const Color(0xFF00996D), t)!,
                    Color.lerp(
                      const Color(0xFF8BDDB9),
                      const Color(0xFF006547), t)!,
                  ],
          ).createShader(rect),
      );
    }

    // A gold-edged foreground swell ties the footer to the header. Unlike
    // a stroked image outline, it scales correctly on any screen width.
    final front = _hillLine(size, 3);
    canvas.drawPath(
      front,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFB78E3E),
            Color(0xFFFFE9AA),
            Color(0xFFFFD781),
            Color(0xFFAFBB6C),
          ],
        ).createShader(rect),
    );
    canvas.drawPath(
      front,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xBFFFF6D7),
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
