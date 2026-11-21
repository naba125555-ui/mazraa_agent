import 'dart:ui';
import 'package:flutter/material.dart';
import 'navigation_registry.dart';

/// Compact frosted-glass dock; roughly half the visual height of the
/// original version. The center action is fixed and HOME is always first.
class AgentGlassNavigationBar extends StatelessWidget {
  const AgentGlassNavigationBar({
    super.key,
    required this.layout,
    required this.arabic,
    required this.selectedRoute,
    required this.onSelect,
  });

  final AgentNavLayout layout;
  final bool arabic;
  final String selectedRoute;
  final ValueChanged<AgentNavItem> onSelect;

  @override Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = layout.items[layout.primaryIndex];
    final before = layout.items.take(layout.primaryIndex).toList();
    final after = layout.items.skip(layout.primaryIndex + 1).toList();
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SizedBox(height: 69, child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0, right: 0, bottom: 0, height: 53,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 210),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: ClipRRect(
                  key: ValueKey(layout.workspace),
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: dark
                          ? const Color(0xD0004937)
                          : const Color(0xD390C2AF),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: dark
                            ? const Color(0x8AA6DAC5)
                            : const Color(0xD9FFFFFF),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3300261C),
                            blurRadius: 15,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(children: [
                        Expanded(child: Row(children: [
                          for (final item in before)
                            Expanded(child: _DockItem(
                              item: item,
                              arabic: arabic,
                              selected: selectedRoute == item.route,
                              dark: dark,
                              onTap: () => onSelect(item),
                            )),
                        ])),
                        const SizedBox(width: 53),
                        Expanded(child: Row(children: [
                          for (final item in after)
                            Expanded(child: _DockItem(
                              item: item,
                              arabic: arabic,
                              selected: selectedRoute == item.route,
                              dark: dark,
                              onTap: () => onSelect(item),
                            )),
                        ])),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: Semantics(
                button: true,
                label: primary.label(arabic),
                child: Tooltip(
                  message: primary.label(arabic),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const ValueKey('agent-primary-navigation'),
                      onTap: () => onSelect(primary),
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF38D782),
                              Color(0xFF08A66A),
                              Color(0xFF005C41),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0x99D9FFDF), width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x70001E14),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(primary.icon, size: 25,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 3,
              child: SizedBox(
                width: 54,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    primary.label(arabic),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: dark
                        ? Colors.white
                        : const Color(0xFF153C2E),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.item,
    required this.arabic,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  final AgentNavItem item;
  final bool arabic, selected, dark;
  final VoidCallback onTap;

  @override Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label(arabic),
      child: InkWell(
        key: ValueKey('agent-nav-' + item.route + '-' + item.ar),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 53,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  constraints: const BoxConstraints(maxWidth: 50),
                  height: 27, width: double.infinity,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF087D4D)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    item.icon,
                    size: 19,
                    color: selected
                      ? Colors.white
                      : dark
                        ? const Color(0xFFD3E5D9)
                        : const Color(0xFF255B49),
                  ),
                ),
                const SizedBox(height: 1),
                SizedBox(
                  height: 16,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label(arabic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.2,
                        fontWeight: selected
                            ? FontWeight.w900 : FontWeight.w700,
                        color: dark
                          ? Colors.white
                          : const Color(0xFF18402E),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
