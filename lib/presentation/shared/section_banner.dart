import 'package:flutter/material.dart';
import '../design/login_scenery.dart';

enum SectionArt { workspace, clinical, commerce, field }

/// A reusable live-wave hero: colors, curved emerald/gold ribbons and image
/// masking are identical to sign-in. Only the replaceable image changes.
class SectionBanner extends StatelessWidget {
  const SectionBanner({
    super.key,
    required this.art,
    required this.title,
    this.subtitle,
    this.icon,
  });

  static const homeHero =
      'assets/images/home_header_yemeni_veterinary_store_hero.webp';

  final SectionArt art;
  final String title;
  final String? subtitle;
  final IconData? icon;

  String get imageAsset => art == SectionArt.workspace
      ? homeHero
      : 'assets/images/agent_${art.name}.webp';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final dark = theme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: 212,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: LoginHeaderWave(
                  dark: dark,
                  photoOnLeft: rtl,
                  imageAsset: imageAsset,
                ),
              ),
              PositionedDirectional(
                top: 19,
                start: 18,
                width: (constraints.maxWidth * .56)
                    .clamp(150.0, 294.0)
                    .toDouble(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon case final glyph?) ...[
                      Icon(glyph, size: 20, color: const Color(0xFFFFE9B6)),
                      const SizedBox(height: 5),
                    ],
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.22,
                        fontWeight: FontWeight.w800,
                        shadows: const [
                          Shadow(color: Color(0x8800261C), blurRadius: 7),
                        ],
                      ),
                    ),
                    if (subtitle case final description?) ...[
                      const SizedBox(height: 5),
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFF1FFF5),
                          height: 1.3,
                          fontSize: 11.4,
                          fontWeight: FontWeight.w600,
                          shadows: const [
                            Shadow(color: Color(0x9900241B), blurRadius: 5),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({super.key, required this.title, required this.icon, required this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(11)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, size: 19, color: colors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.labelLarge)),
            ],
          ),
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value, required this.icon, this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 19, color: theme.colorScheme.primary),
              const SizedBox(height: 5),
              Text(value, style: theme.textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
              Text(label, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
