import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import '../domain/models.dart';
import '../domain/screens.dart';
import 'design/login_scenery.dart';
import 'navigation.dart';
import 'navigation_registry.dart';
import 'shared/scope.dart';
import 'shared/widgets.dart';

/// A reusable app header for every authenticated route. The toolbar remains
/// opaque and pinned; only the wave hero is animated. A downward gesture
/// reveals it from ANY scroll offset, including an unscrollable short page.
class AgentCollapsibleAppBar extends StatefulWidget {
  const AgentCollapsibleAppBar({
    super.key,
    required this.route,
    required this.title,
    required this.body,
  });

  final String route;
  final String title;
  final Widget body;

  @override
  State<AgentCollapsibleAppBar> createState() =>
      _AgentCollapsibleAppBarState();
}

class _AgentCollapsibleAppBarState extends State<AgentCollapsibleAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 300),
    reverseDuration: const Duration(milliseconds: 240),
  );
  bool visible = true;
  double pointerTravel = 0;
  int pointerDirection = 0;

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _setVisible(bool next) {
    if (next == visible) return;
    visible = next;
    if (next) {
      _reveal.animateTo(1, curve: Curves.easeOutCubic);
    } else {
      _reveal.animateTo(0, curve: Curves.easeInOutCubic);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        _setVisible(false);
      } else if (notification.direction == ScrollDirection.forward) {
        _setVisible(true);
      }
    } else if (notification is OverscrollNotification &&
        notification.dragDetails != null) {
      if (notification.overscroll < -2) _setVisible(true);
      if (notification.overscroll > 2) _setVisible(false);
    }
    return false;
  }

  // Lists with few items may not emit UserScrollNotification. Listen for
  // deliberate vertical pointer motion as well, without swallowing gestures.
  void _onPointer(PointerMoveEvent event) {
    if (event.delta.dy.abs() < event.delta.dx.abs() * 1.5) return;
    final direction = event.delta.dy > 0 ? 1 : -1;
    if (pointerDirection != direction) {
      pointerDirection = direction;
      pointerTravel = 0;
    }
    pointerTravel += event.delta.dy.abs();
    if (pointerTravel >= 14) {
      _setVisible(direction > 0);
      pointerTravel = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scaledText = MediaQuery.textScalerOf(context).scale(16) / 16;
    final extra = ((scaledText - 1).clamp(0, 1) * 155).toDouble();
    final heroHeight = (width < 365 ? 300.0 : 274.0) + extra;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Column(children: [
        _pinnedToolbar(context),
        AnimatedBuilder(
          animation: _reveal,
          child: SizedBox(
            height: heroHeight,
            child: _AgentWaveHero(route: widget.route, title: widget.title),
          ),
          builder: (context, child) {
            final factor = _reveal.value;
            return SizedBox(
              key: const ValueKey('agent-wave-viewport'),
              height: heroHeight * factor,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: heroHeight,
                  maxHeight: heroHeight,
                  child: Transform.translate(
                    offset: Offset(0, -heroHeight * (1 - factor)),
                    child: IgnorePointer(
                      ignoring: factor < .97,
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Expanded(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerMove: _onPointer,
            onPointerUp: (_) {
              pointerDirection = 0;
              pointerTravel = 0;
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: widget.body,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _pinnedToolbar(BuildContext context) {
    final home = widget.route == 'H05' || widget.route == 'H01';
    final canPop = Navigator.of(context).canPop();
    return Container(
      key: const ValueKey('agent-opaque-toolbar'),
      color: const Color(0xFF004233),
      child: SafeArea(
        bottom: false,
        child: SizedBox(height: 70, child: Row(children: [
          IconButton(
            tooltip: canPop ? context.tr('رجوع', 'Back') :
                context.tr('حسابي', 'Account'),
            onPressed: canPop
                ? () => Navigator.of(context).maybePop()
                : () => context.open('H08'),
            icon: Icon(canPop ? Icons.arrow_back_rounded :
                Icons.account_circle_outlined,
                color: Colors.white, size: 27),
          ),
          Expanded(
            child: Center(
              child: InkWell(
                key: const ValueKey('agent-workspace-selector'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showWorkspaces(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const BrandLogo(size: 38),
                    const SizedBox(width: 7),
                    Flexible(
                      child: SizedBox(
                        height: home ? 31 : 43,
                        child: FittedBox(
                          alignment: AlignmentDirectional.centerStart,
                          fit: BoxFit.scaleDown,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(context.tr('مزرعتي', 'Mazraa'),
                                maxLines: 1,
                                style: const TextStyle(color: Colors.white,
                                  fontSize: 22, fontWeight: FontWeight.w900)),
                              if (!home) Text(widget.title,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Color(0xFFE4F3E9), fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: Color(0xFFE4F3E9)),
                  ]),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: context.tr('الإشعارات', 'Notifications'),
            onPressed: () => context.open('H07'),
            icon: const Icon(Icons.notifications_none_rounded,
              color: Colors.white, size: 26),
          ),
        ])),
      ),
    );
  }

  void _showWorkspaces(BuildContext context) {
    final app = context.app;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheet).height * .72),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
          children: [
            ListTile(
              title: Text(context.tr('الأقسام ومساحات العمل', 'Workspaces'),
                style: Theme.of(sheet).textTheme.titleLarge),
              trailing: IconButton(
                tooltip: context.tr('الرئيسية', 'Home'),
                onPressed: () {
                  Navigator.pop(sheet);
                  context.open('H05');
                },
                icon: const Icon(Icons.home_outlined),
              ),
            ),
            for (final workspace in AgentNavigationRegistry.available(app))
              ListTile(
                leading: Icon(switch (workspace) {
                  AgentWorkspace.home => Icons.home_outlined,
                  AgentWorkspace.clinic => Icons.medical_services_outlined,
                  AgentWorkspace.field => Icons.location_on_outlined,
                  AgentWorkspace.branch => Icons.storefront_outlined,
                  AgentWorkspace.account => Icons.person_outline,
                  AgentWorkspace.sales => Icons.shopping_cart_outlined,
                  AgentWorkspace.inventory => Icons.inventory_2_outlined,
                  AgentWorkspace.finance => Icons.account_balance_wallet_outlined,
                  AgentWorkspace.pickup => Icons.local_shipping_outlined,
                  AgentWorkspace.purchasing => Icons.add_shopping_cart_outlined,
                  AgentWorkspace.auctions => Icons.gavel_outlined,
                }),
                title: Text(AgentNavigationRegistry.title(workspace, app.ar)),
                trailing: const Icon(Icons.chevron_left),
                onTap: () {
                  Navigator.pop(sheet);
                  context.open(AgentNavigationRegistry.entry(app, workspace));
                },
              ),
          ],
        ),
      )),
    );
  }
}

/// The greeting, subtitle, scope selector and availability are one interactive
/// body, in order, entirely inside the curved photo header.
class _AgentWaveHero extends StatelessWidget {
  const _AgentWaveHero({required this.route, required this.title});
  final String route;
  final String title;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final isHome = route == 'H05' || route == 'H01';
    final imageAsset = switch (screen(route).area) {
      Area.clinical => 'assets/images/agent_clinical.webp',
      Area.field => 'assets/images/agent_field.webp',
      Area.general => 'assets/images/home_header_yemeni_veterinary_store_hero.webp',
      _ => 'assets/images/agent_commerce.webp',
    };
    final name = str(app.user['name'] ??
        obj(app.profile['user'])['name']).trim();
    final greeting = name.isEmpty
        ? context.tr('مرحبًا بك في مزرعتي', 'Welcome to Mazraa')
        : context.tr('مرحبًا، ', 'Welcome, ') + name;
    return Stack(fit: StackFit.expand, children: [
      LoginHeaderWave(
        dark: Theme.of(context).brightness == Brightness.dark,
        photoOnLeft: Directionality.of(context) == TextDirection.rtl,
        imageAsset: imageAsset,
      ),
      PositionedDirectional(
        start: 16, end: 16, top: 16, bottom: 48,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isHome ? greeting : title,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                height: 1.19,
                shadows: [
                  Shadow(color: Color(0xAE00180E), blurRadius: 7),
                ],
              )),
            const SizedBox(height: 5),
            Text(isHome
                ? context.tr('صحة الحيوان وتجارة الفرع في مساحة عمل واحدة',
                    'Animal care and branch commerce in one workspace')
                : context.tr('مساحة العمل والخدمات المتاحة',
                    'Your authorized services and workspace'),
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11.7,
                height: 1.3,
                color: Color(0xFFF1FFF5),
                shadows: [
                  Shadow(color: Color(0x99001912), blurRadius: 5),
                ],
              ),
            ),
            const SizedBox(height: 9),
            const AgentHomeScopeStrip(),
          ],
        ),
      ),
    ]);
  }
}

/// Operates only on the actual delegated warehouse and live doctor availability.
class AgentHomeScopeStrip extends StatefulWidget {
  const AgentHomeScopeStrip({super.key});
  @override State<AgentHomeScopeStrip> createState() =>
      _AgentHomeScopeStripState();
}

class _AgentHomeScopeStripState extends State<AgentHomeScopeStrip> {
  bool busy = false;

  @override Widget build(BuildContext context) {
    final app = context.app;
    final available =
        payload(obj(app.profile['profile']))['isAvailable'] == true;
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 7,
      runSpacing: 4,
      children: [
        Text(context.tr('النطاق الحالي', 'Current scope'),
          style: const TextStyle(color: Colors.white,
            fontSize: 11.2, fontWeight: FontWeight.w800)),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0x90006B4D),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.storefront_outlined,
              color: Colors.white, size: 17),
            const SizedBox(width: 5),
            Text(app.grant == null
                ? context.tr('بدون فرع', 'No branch')
                : context.tr('مخزن ', 'Warehouse ') +
                    app.grant!.warehouse.toString(),
              style: const TextStyle(color: Colors.white,
                fontSize: 10.6, fontWeight: FontWeight.w700)),
          ]),
        ),
        OutlinedButton(
          onPressed: () => context.open('H06'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFE9AC),
            side: const BorderSide(
                color: Color(0xFFFFE0A0), width: 1.2),
            minimumSize: const Size(54, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: const StadiumBorder(),
          ),
          child: Text(context.tr('تبديل', 'Change'),
            style: const TextStyle(fontSize: 11,
                fontWeight: FontWeight.w800)),
        ),
        if (app.access.doctor) ...[
          Text(available
              ? context.tr('متاح', 'Available')
              : context.tr('غير متاح', 'Unavailable'),
            style: const TextStyle(color: Colors.white,
              fontSize: 11, fontWeight: FontWeight.w800)),
          SizedBox(
            height: 38, width: 47,
            child: FittedBox(child: Switch.adaptive(
              value: available,
              onChanged: busy ? null : (value) async {
                setState(() => busy = true);
                try {
                  await app.repo.write(
                    'PATCH', '/api/agent/availability',
                    {'available': value},
                  );
                  await app.refreshAccess();
                } catch (error) {
                  if (context.mounted) {
                    toast(context, failureText(context, error));
                  }
                } finally {
                  if (mounted) setState(() => busy = false);
                }
              },
              activeTrackColor: const Color(0xFF18B978),
              activeThumbColor: Colors.white,
            )),
          ),
        ],
      ],
    );
  }
}
