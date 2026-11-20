import 'package:flutter/material.dart';

/// Login scenery built entirely from Flutter widget layers. This paints the
/// page's soft mint canvas and three bottom swells; it never stretches a
/// screenshot or other image over the page.
class LoginScenery extends StatelessWidget {
  const LoginScenery({super.key, required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final footerHeight = (height * .22).clamp(145.0, 260.0).toDouble();
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, .30, .57, .83, 1],
                  colors: dark
                      ? const [
                          Color(0xFF063F34),
                          Color(0xFF073D32),
                          Color(0xFF092E2A),
                          Color(0xFF063C31),
                          Color(0xFF075440),
                        ]
                      : const [
                          Color(0xFFCEF4DF),
                          Color(0xFFE6F9F0),
                          Color(0xFFF5FAFA),
                          Color(0xFFECF9F5),
                          Color(0xFFCAF3DF),
                        ],
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, .18),
                    radius: 1.03,
                    stops: const [0, .54, 1],
                    colors: dark
                        ? const [
                            Color(0x140DAE7C),
                            Color(0x0908A173),
                            Colors.transparent,
                          ]
                        : const [
                            Color(0xD9FFFFFF),
                            Color(0x66FFFFFF),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: footerHeight,
              child: Transform.flip(
                flipX: !rtl,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipPath(
                      clipper: const _FooterSwellClipper(layer: 0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: dark
                                ? const [
                                    Color(0x2217C58D),
                                    Color(0x400C8467),
                                  ]
                                : const [
                                    Color(0x2291E5BE),
                                    Color(0x5BB5EFDA),
                                  ],
                          ),
                        ),
                      ),
                    ),
                    ClipPath(
                      clipper: const _FooterSwellClipper(layer: 1),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: dark
                                ? const [
                                    Color(0x2E0EB386),
                                    Color(0x5507654E),
                                  ]
                                : const [
                                    Color(0x4AD4FFF0),
                                    Color(0x6C9DDFCA),
                                  ],
                          ),
                        ),
                      ),
                    ),
                    ClipPath(
                      clipper: const _FooterSwellClipper(layer: 2),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: dark
                                ? const [
                                    Color(0x2A079D70),
                                    Color(0x70045A47),
                                  ]
                                : const [
                                    Color(0x39D8FFEF),
                                    Color(0x96B2ECD7),
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Standalone, replaceable image header. The hero picture is the *only* bitmap
/// in the header; all green masking and flowing gold/emerald ribbons are live
/// Flutter gradients clipped by paths. Photo side remains fully transparent
/// in the *horizontal* green mask.
class LoginHeaderWave extends StatelessWidget {
  const LoginHeaderWave({
    super.key,
    required this.dark,
    required this.photoOnLeft,
    this.imageAsset = defaultImageAsset,
  });

  static const defaultImageAsset =
      'assets/images/login_header_yemeni_store_secure_access_hero.webp';

  final bool dark;
  final bool photoOnLeft;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: !photoOnLeft,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Broad emerald lower edge below the cream-gold highlight.
          ClipPath(
            clipper: const _HeaderWaveClipper(drop: 19),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: dark
                      ? const [
                          Color(0xFF00644D),
                          Color(0xFF05946B),
                          Color(0xFF83CFA1),
                        ]
                      : const [
                          Color(0xFF007E52),
                          Color(0xFF00A36B),
                          Color(0xFF78C891),
                        ],
                ),
              ),
            ),
          ),
          ClipPath(
            clipper: const _HeaderWaveClipper(drop: 9),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  stops: [0, .30, .65, 1],
                  colors: [
                    Color(0xFFC99B52),
                    Color(0xFFFFE9AC),
                    Color(0xFFFFD784),
                    Color(0xFFFFF0B9),
                  ],
                ),
              ),
            ),
          ),
          ClipPath(
            clipper: const _HeaderWaveClipper(drop: 0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: dark
                          ? const [
                              Color(0xFF003729),
                              Color(0xFF00654B),
                              Color(0xFF003F30),
                            ]
                          : const [
                              Color(0xFF004B37),
                              Color(0xFF008C5B),
                              Color(0xFF00583E),
                            ],
                    ),
                  ),
                ),
                Positioned.fill(
                  top: 0,
                  child: Image.asset(
                    imageAsset,
                    alignment: Alignment.topLeft,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
                // The picture emerges from the green upper canopy, matching
                // the reference image's green-to-photograph vertical fade.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, .15, .49, .83],
                        colors: dark
                            ? const [
                                Color(0xFF003D30),
                                Color(0xF9004837),
                                Color(0x23004938),
                                Colors.transparent,
                              ]
                            : const [
                                Color(0xFF00513E),
                                Color(0xF9006149),
                                Color(0x26007151),
                                Colors.transparent,
                              ],
                      ),
                    ),
                  ),
                ),
                // Left 28% is alpha=0, preserving every detail of the hero.
                // The opposite side becomes opaque forest green for labels.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: const [0, .28, .48, .68, 1],
                        colors: dark
                            ? const [
                                Colors.transparent,
                                Colors.transparent,
                                Color(0xA3004135),
                                Color(0xF8004937),
                                Color(0xFF00372C),
                              ]
                            : const [
                                Colors.transparent,
                                Colors.transparent,
                                Color(0xA7006845),
                                Color(0xFA006949),
                                Color(0xFF00523D),
                              ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderWaveClipper extends CustomClipper<Path> {
  const _HeaderWaveClipper({required this.drop});

  /// The visible colored ribbon is the distance between adjacent contours.
  final double drop;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final d = drop.clamp(0.0, h * .12).toDouble();
    return Path()
      ..moveTo(0, h * .80 + d)
      ..cubicTo(w * .14, h * .94 + d, w * .32, h * .70 + d,
          w * .49, h * .69 + d)
      ..cubicTo(w * .66, h * .67 + d, w * .75, h * .86 + d,
          w * .88, h * .75 + d)
      ..quadraticBezierTo(w * .97, h * .68 + d, w, h * .59 + d)
      ..lineTo(w, 0)
      ..lineTo(0, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant _HeaderWaveClipper old) => old.drop != drop;
}

class _FooterSwellClipper extends CustomClipper<Path> {
  const _FooterSwellClipper({required this.layer});
  final int layer;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final shift = layer * .12;
    return Path()
      ..moveTo(0, h * (.05 + shift))
      ..cubicTo(w * .20, h * (.56 + shift),
          w * .40, h * (.92 + shift), w * .60, h * (.76 + shift))
      ..cubicTo(w * .78, h * (.58 + shift),
          w * .92, h * (.18 + shift), w, h * (.10 + shift))
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
  }

  @override
  bool shouldReclip(covariant _FooterSwellClipper old) => old.layer != layer;
}
