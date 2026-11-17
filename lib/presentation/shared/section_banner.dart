import 'package:flutter/material.dart';

enum SectionArt { workspace, clinical, commerce, field }

class SectionBanner extends StatelessWidget {
  const SectionBanner({
    super.key,
    required this.art,
    required this.title,
    this.subtitle,
    this.icon,
  });

  final SectionArt art;
  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(21),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/agent_${art.name}.webp',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: const [
                    Color(0xe911301f),
                    Color(0xc3122f21),
                    Color(0x53112b1e),
                  ],
                  stops: const [0, .57, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon case final glyph?) ...[
                    Icon(glyph, size: 22, color: const Color(0xffc0eaca)),
                    const SizedBox(height: 5),
                  ],
                  Text(title, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                  if (subtitle case final description?)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(description, style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xffe6f2e8))),
                    ),
                ],
              ),
            ),
          ),
        ],
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
