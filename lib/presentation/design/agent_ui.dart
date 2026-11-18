import 'package:flutter/material.dart';

/// Shared, accessible visual language for the agent rebuild.
/// These widgets render native Flutter controls; artwork is decoration only.
abstract final class AgentPalette {
  static const forest = Color(0xFF075C3B);
  static const emerald = Color(0xFF119656);
  static const mint = Color(0xFFE5F6EB);
  static const ink = Color(0xFF18352A);
  static const blue = Color(0xFF3570B7);
  static const amber = Color(0xFFB57518);
  static const violet = Color(0xFF6F5BB3);
}

class AgentSurface extends StatelessWidget {
  const AgentSurface({super.key, required this.child, this.padding = const EdgeInsets.all(16),
    this.color, this.onTap, this.radius = 20});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: color ?? scheme.surface,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outline.withValues(alpha: .43)),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AgentHero extends StatelessWidget {
  const AgentHero({super.key, required this.title, required this.subtitle,
    this.art = 'assets/images/agent_workspace.webp', this.icon = Icons.eco_outlined,
    this.trailing});
  final String title, subtitle, art;
  final IconData icon;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 170),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AgentPalette.forest.withValues(alpha: .12),
          blurRadius: 24, offset: const Offset(0, 10))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(children: [
          Positioned.fill(child: Image.asset(art, fit: BoxFit.cover,
            alignment: AlignmentDirectional.centerEnd, excludeFromSemantics: true)),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: const [Color(0xFA075333), Color(0xE60A613E),
                Color(0x700B6441), Color(0x150B6441)],
              stops: const [0, .38, .78, 1])))),
          Padding(padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: const Color(0xFFE4F9DB), size: 29),
                const SizedBox(height: 12),
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 245),
                  child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: type.titleLarge?.copyWith(color: Colors.white,
                      fontWeight: FontWeight.w900, height: 1.35))),
                const SizedBox(height: 4),
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 255),
                  child: Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: type.bodySmall?.copyWith(color: const Color(0xFFE2F7E9),
                      fontWeight: FontWeight.w600))),
                if (trailing != null) ...[const SizedBox(height: 10), trailing!],
              ])),
        ]),
      ),
    );
  }
}

class AgentSectionHeading extends StatelessWidget {
  const AgentSectionHeading({super.key, required this.title, this.icon, this.action});
  final String title;
  final IconData? icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: 24, bottom: 12),
    child: Row(children: [
      if (icon != null) ...[
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 23),
        const SizedBox(width: 9),
      ],
      Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontSize: 17, fontWeight: FontWeight.w900))),
      if (action != null) action!,
    ]),
  );
}

class AgentMetric extends StatelessWidget {
  const AgentMetric({super.key, required this.label, required this.value,
    required this.icon, required this.color, this.onTap, this.caption});
  final String label, value;
  final IconData icon;
  final Color color;
  final String? caption;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    return Semantics(button: onTap != null, label: '$label: $value',
      child: AgentSurface(color: color.withValues(alpha: .095), onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 43, height: 43,
              decoration: BoxDecoration(color: color.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 25)),
            const Spacer(),
            if (onTap != null) Icon(Icons.arrow_outward_rounded,
              size: 17, color: color.withValues(alpha: .78)),
          ]),
          const SizedBox(height: 12),
          Text(value, style: type.headlineSmall?.copyWith(color: color,
            fontSize: 24, fontWeight: FontWeight.w900),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: type.bodySmall?.copyWith(fontWeight: FontWeight.w800)),
          if (caption != null) Text(caption!, maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: type.labelSmall?.copyWith(color: color)),
        ])),
    );
  }
}

class AgentAction extends StatelessWidget {
  const AgentAction({super.key, required this.title, required this.icon,
    required this.color, required this.onTap, this.subtitle});
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    return AgentSurface(onTap: onTap, padding: const EdgeInsets.symmetric(
      horizontal: 9, vertical: 15), child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        Container(width: 49, height: 49, decoration: BoxDecoration(
          color: color.withValues(alpha: .105),
          borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, size: 27, color: color)),
        const SizedBox(height: 10),
        Text(title, textAlign: TextAlign.center, maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: type.bodySmall?.copyWith(fontWeight: FontWeight.w800,
            height: 1.3)),
        if (subtitle != null) Text(subtitle!, textAlign: TextAlign.center,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: type.labelSmall),
      ],
    ));
  }
}

class AgentPill extends StatelessWidget {
  const AgentPill({super.key, required this.label, required this.color,
    this.icon});
  final String label;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(30)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, color: color, size: 15),
        const SizedBox(width: 5)],
      Flexible(child: Text(label, style: Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: color, fontWeight: FontWeight.w800),
        maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]),
  );
}
