
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

/// Opaque pinned toolbar and a real widget-built, independently sliding wave.
/// Unlike a nested SliverAppBar, a downward drag reveals the hero at *any*
/// scroll position in ListView, PagedRecords, detail forms and short pages.
class AgentCollapsibleAppBar extends StatefulWidget {
  const AgentCollapsibleAppBar({
    super.key, required this.route, required this.title, required this.body,
  });
  final String route;
  final String title;
  final Widget body;

  @override State<AgentCollapsibleAppBar> createState() =>
      _AgentCollapsibleAppBarState();
}

class _AgentCollapsibleAppBarState extends State<AgentCollapsibleAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _height = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 250),
    value: 1,
  );
  bool expanded = true;
  double dragTravel = 0;
  int dragSign = 0;

  @override void dispose() {
    _height.dispose();
    super.dispose();
  }

  void _showHero(bool show) {
    if (show == expanded) return;
    expanded = show;
    if (show) {
      _height.animateTo(1, curve: Curves.easeOutCubic);
    } else {
      _height.animateTo(0, curve: Curves.easeInOutCubic);
    }
  }

  bool _onScroll(ScrollNotification note) {
    if (note.metrics.axis != Axis.vertical) return false;
    if (note is UserScrollNotification) {
      if (note.direction == ScrollDirection.reverse) _showHero(false);
      if (note.direction == ScrollDirection.forward) _showHero(true);
    }
    // Support overscroll at either end and accessibility scroll dispatches.
    if (note is OverscrollNotification && note.dragDetails != null) {
      if (note.overscroll < -2) _showHero(true);
      if (note.overscroll > 2) _showHero(false);
    }
    return false;
  }

  void _onPointer(PointerMoveEvent event) {
    if (event.delta.dy.abs() <= event.delta.dx.abs() * 1.5) return;
    final current = event.delta.dy > 0 ? 1 : -1;
    if (current != dragSign) {
      dragTravel = 0;
      dragSign = current;
    }
    dragTravel += event.delta.dy.abs();
    if (dragTravel >= 11) {
      _showHero(current > 0);
      dragTravel = 0;
    }
  }

  @override Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final extra = (textScale - 1).clamp(0.0, 1.0).toDouble();
    final home = widget.route == 'H05' || widget.route == 'H01';
    final heroHeight = (home ? 249.0 : 210.0) + extra * 135;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Column(children: [
        _pinnedToolbar(context),
        AnimatedBuilder(
          animation: _height,
          child: SizedBox(height: heroHeight,
            child: _AgentWaveHero(route: widget.route, title: widget.title)),
          builder: (context, child) {
            final visible = _height.value;
            return SizedBox(
              key: const ValueKey('agent-collapsing-wave-viewport'),
              height: heroHeight * visible,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: heroHeight,
                  maxHeight: heroHeight,
                  child: Transform.translate(
                    offset: Offset(0, -heroHeight * (1 - visible)),
                    child: child,
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
            onPointerUp: (_) { dragSign = 0; dragTravel = 0; },
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
    final root = widget.route == 'H05' || widget.route == 'H01';
    return Container(
      key: const ValueKey('agent-opaque-toolbar'),
      color: const Color(0xFF003F31),
      child: SafeArea(
        bottom: false,
        child: SizedBox(height: 61, child: Row(children: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: Navigator.of(context).canPop()
                ? context.tr('رجوع', 'Back')
                : context.tr('حسابي', 'Account'),
            onPressed: Navigator.of(context).canPop()
                ? () => Navigator.of(context).maybePop()
                : () => context.open('H08'),
            icon: Icon(Navigator.of(context).canPop()
                ? Icons.arrow_back_rounded : Icons.account_circle_outlined,
                color: Colors.white, size: 27),
          ),
          Expanded(child: Center(
            child: InkWell(
              key: const ValueKey('agent-workspace-selector'),
              borderRadius: BorderRadius.circular(15),
              onTap: () => _showWorkspaces(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const BrandLogo(size: 37),
                  const SizedBox(width: 8),
                  Flexible(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('مزرعتي', 'Mazraa'),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 21, fontWeight: FontWeight.w900)),
                      if (!root) Text(widget.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFCDE6D8),
                            fontSize: 10, height: 1.05)),
                    ],
                  )),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 17, color: Color(0xFFB8DBC7)),
                ]),
              ),
            ),
          )),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: context.tr('الإشعارات', 'Notifications'),
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white, size: 26),
            onPressed: () => context.open('H07'),
          ),
        ])),
      ),
    );
  }

  void _showWorkspaces(BuildContext context) {
    final app = context.app;
    final choices = AgentNavigationRegistry.available(app);
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
                icon: const Icon(Icons.home_outlined),
                onPressed: () { Navigator.pop(sheet); context.open('H05'); },
              ),
            ),
            for (final workspace in choices)
              ListTile(
                leading: Icon(_workspaceIcon(workspace)),
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

  IconData _workspaceIcon(AgentWorkspace workspace) => switch (workspace) {
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
  };
}

class _AgentWaveHero extends StatelessWidget {
  const _AgentWaveHero({required this.route, required this.title});
  final String route, title;
  bool get home => route == 'H05' || route == 'H01';

  @override Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final spec = screen(route);
    final asset = switch (spec.area) {
      Area.clinical => 'assets/images/agent_clinical.webp',
      Area.field => 'assets/images/agent_field.webp',
      Area.general => 'assets/images/home_header_yemeni_veterinary_store_hero.webp',
      _ => 'assets/images/agent_commerce.webp',
    };
    final name = str(context.app.user['name'] ??
        obj(context.app.profile['user'])['name']).trim();
    final greeting = name.isEmpty
        ? context.tr('مرحبًا بك في مزرعتي', 'Welcome to Mazraa')
        : context.tr('مرحبًا، ', 'Welcome, ') + name;
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return Stack(fit: StackFit.expand, children: [
      LoginHeaderWave(
        dark: dark,
        photoOnLeft: direction == TextDirection.rtl,
        imageAsset: asset,
      ),
      PositionedDirectional(
        top: 19, start: 13, end: 13, bottom: 45,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(home ? greeting : title,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: scale > 1.4 ? 17 : 20,
                height: 1.16,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(color: Color(0xA600261B), blurRadius: 8),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(home
                ? context.tr('صحة الحيوان وتجارة الفرع في مساحة عمل واحدة',
                    'Animal care and branch commerce in one workspace')
                : context.tr('مساحة عملك في مزرعتي',
                    'Your Mazraa workspace'),
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF2FFF5), fontSize: 11.5, height: 1.3,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(color: Color(0xC000261B), blurRadius: 6),
                ],
              ),
            ),
            const SizedBox(height: 11),
            // Stays attached immediately below greeting, never tied to
            // scroll offset or absolute positions on the page.
            const AgentHomeScopeStrip(),
          ],
        ),
      ),
    ]);
  }
}

/// Server-backed scope and availability. This is part of every hero in the
/// authenticated shell, not a duplicated card below the app bar.
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
    final doctor = app.access.doctor;
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 3, spacing: 7,
      children: [
        Text(context.tr('النطاق الحالي', 'Current scope'),
          style: const TextStyle(
              color: Colors.white, fontSize: 11,
              fontWeight: FontWeight.w800)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0x7F167659),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.storefront_outlined,
                color: Color(0xFFE8F8E9), size: 16),
            const SizedBox(width: 5),
            Text(
              app.grant == null
                ? context.tr('بدون فرع', 'No branch')
                : context.tr('مخزن ', 'Warehouse ') +
                    app.grant!.warehouse.toString(),
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700,
                fontSize: 10.5),
            ),
          ]),
        ),
        OutlinedButton(
          onPressed: () => context.open('H06'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFE9AD),
            side: const BorderSide(color: Color(0xFFFFD68E), width: 1.1),
            minimumSize: const Size(50, 34),
            padding: const EdgeInsets.symmetric(horizontal: 11),
            tapTargetSize: MaterialTapTargetSize.padded,
            shape: const StadiumBorder(),
          ),
          child: Text(context.tr('تبديل', 'Change'),
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800)),
        ),
        if (doctor) ...[
          Text(available
              ? context.tr('متاح', 'Available')
              : context.tr('غير متاح', 'Unavailable'),
            style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800,
              fontSize: 10.5)),
          SizedBox(width: 43, height: 34,
            child: FittedBox(
              child: Switch.adaptive(
                value: available,
                onChanged: busy ? null : (value) async {
                  setState(() => busy = true);
                  try {
                    await app.repo.write(
                        'PATCH', '/api/agent/availability',
                        {'available': value});
                    await app.refreshAccess();
                  } catch (error) {
                    if (context.mounted) {
                      toast(context, failureText(context, error));
                    }
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
                activeTrackColor: const Color(0xFF17B876),
                activeThumbColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
