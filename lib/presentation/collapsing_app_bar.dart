import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import 'design/login_scenery.dart';
import 'navigation.dart';
import 'navigation_registry.dart';
import 'shared/scope.dart';
import 'shared/section_banner.dart';
import 'shared/widgets.dart';

/// The toolbar stays fixed. Only Home adds the collapsible photo header.
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
  State<AgentCollapsibleAppBar> createState() => _AgentCollapsibleAppBarState();
}

class _AgentCollapsibleAppBarState extends State<AgentCollapsibleAppBar>
    with SingleTickerProviderStateMixin {
  static const _gestureThreshold = 18.0;
  static const _toolbarColor = Color(0xFF004233);

  late final _reveal = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 210),
  );
  late final _height = _reveal.drive(CurveTween(curve: Curves.easeInOutCubic));
  bool _visible = true;
  Axis? _gestureAxis;
  Offset _movement = Offset.zero;
  int? _pointer;

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _setVisible(bool next) {
    if (next == _visible) return;
    _visible = next;
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = next ? 1 : 0;
    } else if (next) {
      _reveal.forward();
    } else {
      _reveal.reverse();
    }
  }

  void _resetGesture() {
    _movement = Offset.zero;
    _gestureAxis = null;
    _pointer = null;
  }

  void _followDrag(Offset delta) {
    if (_gestureAxis == Axis.horizontal) return;
    if (_gestureAxis == null) {
      _movement += delta;
      final dx = _movement.dx.abs();
      final dy = _movement.dy.abs();
      if (dx < _gestureThreshold && dy < _gestureThreshold) return;
      if (dx >= dy * 1.25) {
        _gestureAxis = Axis.horizontal;
        return;
      }
      if (dy < dx * 1.25 || dy < _gestureThreshold) return;
      _gestureAxis = Axis.vertical;
    } else {
      final dy = _movement.dy.sign == delta.dy.sign
          ? _movement.dy + delta.dy
          : delta.dy;
      _movement = Offset(0, dy);
    }
    if (_movement.dy.abs() < _gestureThreshold) return;
    _setVisible(_movement.dy > 0);
    _movement = Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    final home = widget.route == 'H05';
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pinnedToolbar(context),
        if (home)
          SizeTransition(
            key: const ValueKey('agent-wave-viewport'),
            alignment: Alignment.bottomCenter,
            sizeFactor: _height,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _reveal,
                builder: (context, child) {
                  final interactive = _reveal.isCompleted;
                  return ExcludeSemantics(
                    excluding: !interactive,
                    child: ExcludeFocus(
                      excluding: !interactive,
                      child: IgnorePointer(
                        ignoring: !interactive,
                        child: child,
                      ),
                    ),
                  );
                },
                child: const _AgentWaveHero(toolbarColor: _toolbarColor),
              ),
            ),
          ),
        Expanded(child: widget.body),
      ],
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: home ? _listenForScroll(content) : content,
    );
  }

  Widget _listenForScroll(Widget child) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _resetGesture();
        _pointer = event.pointer;
      },
      onPointerMove: (event) {
        if (event.pointer == _pointer) _followDrag(event.delta);
      },
      onPointerUp: (event) {
        if (event.pointer == _pointer) _resetGesture();
      },
      onPointerCancel: (event) {
        if (event.pointer == _pointer) _resetGesture();
      },
      onPointerPanZoomStart: (_) => _resetGesture(),
      onPointerPanZoomUpdate: (event) => _followDrag(event.panDelta),
      onPointerPanZoomEnd: (_) => _resetGesture(),
      onPointerSignal: (event) {
        if (event is PointerScrollEvent &&
            event.scrollDelta.dy.abs() > event.scrollDelta.dx.abs()) {
          _setVisible(event.scrollDelta.dy < 0);
        }
      },
      child: child,
    );
  }

  Widget _pinnedToolbar(BuildContext context) {
    final home = widget.route == 'H05' || widget.route == 'H01';
    final canPop = Navigator.of(context).canPop();
    return Container(
      key: const ValueKey('agent-opaque-toolbar'),
      color: _toolbarColor,
      child: SafeArea(
        bottom: false,
        child: SizedBox(height: widget.route == 'H05' ? 58 : 70, child: Row(children: [
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

/// The photo, copy and live controls move together below the toolbar.
class _AgentWaveHero extends StatelessWidget {
  const _AgentWaveHero({required this.toolbarColor});

  final Color toolbarColor;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final name = str(app.user['name'] ?? obj(app.profile['user'])['name'])
        .trim();
    final greeting = name.isEmpty
        ? context.tr('مرحبًا بك في مزرعتي', 'Welcome to Mazraa')
        : context.tr('مرحبًا، ', 'Welcome, ') + name;

    return Stack(
      children: [
        Positioned.fill(
          child: LoginHeaderWave(
            dark: Theme.of(context).brightness == Brightness.dark,
            photoOnLeft: Directionality.of(context) == TextDirection.rtl,
            imageAsset: SectionBanner.homeHero,
            toolbarColor: toolbarColor,
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 200, maxWidth: 580),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 29, 16, 53),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      greeting,
                      key: const ValueKey('home-wave-greeting'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.18,
                        shadows: [
                          Shadow(color: Color(0xBB00180E), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    context.tr(
                      'صحة الحيوان وتجارة الفرع في مساحة عمل واحدة',
                      'Animal care and branch commerce in one workspace',
                    ),
                    key: const ValueKey('home-wave-description'),
                    style: const TextStyle(
                      color: Color(0xFFF1FFF5),
                      fontSize: 12,
                      height: 1.32,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(color: Color(0xBB00180E), blurRadius: 7),
                      ],
                    ),
                  ),
                  const AgentHomeScopeStrip(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Operates only on the actual delegated warehouse and live doctor availability.
class AgentHomeScopeStrip extends StatefulWidget {
  const AgentHomeScopeStrip({super.key});
  @override
  State<AgentHomeScopeStrip> createState() => _AgentHomeScopeStripState();
}

class _AgentHomeScopeStripState extends State<AgentHomeScopeStrip> {
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final available =
        payload(obj(app.profile['profile']))['isAvailable'] == true;
    const labelStyle = TextStyle(
      color: Colors.white,
      fontSize: 11.5,
      fontWeight: FontWeight.w800,
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(context.tr('النطاق الحالي', 'Current scope'), style: labelStyle),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xD029543F),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  app.grant == null
                      ? context.tr('بدون فرع', 'No branch')
                      : context.tr('مخزن ', 'Warehouse ') +
                            app.grant!.warehouse.toString(),
                  style: labelStyle,
                ),
              ],
            ),
          ),
        ),
        OutlinedButton(
          onPressed: () => context.open('H06'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFE9AC),
            backgroundColor: const Color(0x4000231A),
            side: const BorderSide(color: Color(0xFFFFE0A0)),
            minimumSize: const Size(54, 32),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: const StadiumBorder(),
          ),
          child: Text(
            context.tr('تبديل', 'Change'),
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
        ),
        if (app.access.doctor)
          MergeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  available
                      ? context.tr('متاح', 'Available')
                      : context.tr('غير متاح', 'Unavailable'),
                  style: labelStyle,
                ),
                const SizedBox(width: 3),
                Switch.adaptive(
                  value: available,
                  onChanged: busy
                      ? null
                      : (value) async {
                          setState(() => busy = true);
                          try {
                            await app.repo.write(
                              'PATCH',
                              '/api/agent/availability',
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
                  inactiveTrackColor: const Color(0xFF687D72),
                  activeThumbColor: Colors.white,
                  inactiveThumbColor: Colors.white,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
