import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/models.dart';
import '../domain/screens.dart';
import 'features/business.dart';
import 'features/clinical.dart';
import 'features/field.dart';
import 'features/general.dart';
import 'features/home.dart';
import 'features/scan.dart';
import 'navigation.dart';
import 'navigation_registry.dart';
import 'glass_navigation_bar.dart';
import 'collapsing_app_bar.dart';
import 'shared/scope.dart';
import 'shared/widgets.dart';

const implementedScreens=<String>{
 'H01','H02','H03','H04','H05','H06','H07','H08','H09','H10','H11',
 'C01','C02','C03','C04','C05','C06','C07','C08','C09','C10','C11','C12','C13','C14','C15','C16',
 'F01','F02','F03','F04','F05','F06','F07','F08','F09','F10','F11','F12','F13',
 'I01','I02','I03','I04','I05','I06','I07','I08','I09','I10',
 'T01','T02','T03','T04','T05','T06','T07','T08','T09','T10','T11','T12','T13','T14',
 'N01','N02','N03','N04','N05','N06','N07','N08','P01','P02','P03','P04','P05','P06','P07',
 'A01','A02','A03','A04','A05','A06','A07','A08','A09','G01','G02','G03','G04',
};
class AppShell extends StatefulWidget{
  const AppShell({super.key});
  @override State<AppShell> createState()=>_AppShellState();
}
class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  static const roots = ['H05', 'C01', 'F01', 'T01', 'H08'];
  final keys = List.generate(roots.length, (_) => GlobalKey<NavigatorState>());
  final visited = <int>{0};
  int index = 0;
  AgentWorkspace workspace = AgentWorkspace.home;
  final tabRoutes = List<String>.of(roots);
  final routeKeys = List<String>.of(roots.map((route) => '$route:root'));
  final pendingKeys = List<String?>.filled(roots.length, null);
  final stackKeys = List.generate(roots.length, (_) => <String>[]);
  late List<NavigatorObserver> observers;
  int? scopeRevision;
  Timer? timer;
  bool refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    observers = List.generate(roots.length,
        (tab) => _TabRouteObserver((route, stack) => _onRouteChanged(tab, route, stack)));
    startPolling();
  }

  void startPolling() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
      startPolling();
    } else {
      timer?.cancel();
    }
  }

  Future<void> refresh() async {
    if (!mounted || refreshing) return;
    refreshing = true;
    try {
      await context.app.refreshAccess();
    } catch (_) {
      // AgentApp exposes the failure to the connection screen.
    } finally {
      refreshing = false;
    }
  }

  static String _routeKey(String route, int? id) =>
      '$route:${id ?? 'root'}';

  static String _settingsKey(RouteSettings settings) =>
      _routeKey(settings.name ?? 'H05',
          settings.arguments is int ? settings.arguments as int : null);

  void _onRouteChanged(int tab, RouteSettings? current,
      List<RouteSettings> history) {
    final active = current?.name ?? roots[tab];
    routeKeys[tab] = current == null
        ? _routeKey(roots[tab], null)
        : _settingsKey(current);
    stackKeys[tab]
      ..clear()
      ..addAll(history.map(_settingsKey));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final entry = AgentNavigationRegistry.workspaceForEntry(active);
      final nextWorkspace = tab == index && entry != null &&
              AgentNavigationRegistry.canEnter(context.app, entry)
          ? entry : workspace;
      if (tabRoutes[tab] == active && workspace == nextWorkspace) return;
      setState(() {
        tabRoutes[tab] = active;
        if (tab == index) workspace = nextWorkspace;
      });
    });
  }

  void _selectNavigation(AgentNavItem item) => open(item.route);

  void open(String route, {int? id, Json? seed}) {
    if (!implementedScreens.contains(route)) return;
    final app = context.app;
    final spec = screen(route);
    if (!app.canOpen(spec)) {
      toast(context, context.tr(
        'هذه الخدمة غير متاحة في نطاق العمل الحالي.',
        'This service is unavailable in the current work context.',
      ));
      return;
    }

    // Home is always reachable from any screen. The other navigators remain
    // in IndexedStack, preserving their scroll positions, inputs and filters.
    if (route == 'H05') {
      if (index != 0 || workspace != AgentWorkspace.home) {
        setState(() {
          index = 0;
          visited.add(0);
          workspace = AgentWorkspace.home;
        });
      }
      keys[0].currentState?.popUntil((route) => route.isFirst);
      return;
    }

    final target = switch (spec.area) {
      Area.clinical => app.canOpen(screen('C01')) ? 1 : 3,
      Area.field => 2,
      Area.general => 4,
      _ => 3,
    };
    final signature = _routeKey(route, id);
    final targetWorkspace = AgentNavigationRegistry.workspaceForEntry(route);
    final scope = app.scopeRevision;

    void activate() {
      if (index != target || !visited.contains(target)) {
        selectTab(target);
      }
      if (targetWorkspace != null &&
          AgentNavigationRegistry.canEnter(app, targetWorkspace) &&
          workspace != targetWorkspace) {
        setState(() => workspace = targetWorkspace);
      }
    }

    // Also reserve pending routes before their Navigator is first mounted.
    if (pendingKeys[target] == signature ||
        routeKeys[target] == signature) {
      activate();
      return;
    }

    final alreadyInStack = stackKeys[target].contains(signature);
    final needsMount = !visited.contains(target);
    activate();
    pendingKeys[target] = signature;

    void navigate() {
      if (!mounted || scope != app.scopeRevision ||
          !app.canOpen(spec) || pendingKeys[target] != signature) {
        return;
      }
      final navigator = keys[target].currentState;
      if (navigator == null) return;
      pendingKeys[target] = null;

      if (route == roots[target]) {
        navigator.popUntil((entry) => entry.isFirst);
      } else if (alreadyInStack) {
        navigator.popUntil((entry) => _settingsKey(entry.settings) == signature);
      } else {
        navigator.push(MaterialPageRoute<void>(
          settings: RouteSettings(name: route, arguments: id),
          builder: (_) => ScreenPage(route, id: id, seed: seed ?? {}),
        ));
      }
    }

    if (needsMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => navigate());
    } else {
      navigate();
    }
  }

  void selectTab(int tab) => setState(() {
    index = tab;
    visited.add(tab);
    workspace = switch (tab) {
      0 => AgentWorkspace.home,
      1 => AgentWorkspace.clinic,
      2 => AgentWorkspace.field,
      3 => AgentWorkspace.branch,
      _ => AgentWorkspace.account,
    };
  });

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    if (app.bootstrap.isEmpty) {
      final failure = app.accessError;
      if (failure == null) {
        return const Scaffold(body: BotanicalBackground(child: Center(child: CircularProgressIndicator())));
      }
      return Scaffold(body: BotanicalBackground(child: SafeArea(child: PageBody(children: [
        Notice(failureText(context, failure), error: true),
        const SizedBox(height: 16),
        BusyButton(label: context.tr('إعادة الاتصال', 'Reconnect'), run: app.refreshAccess),
        TextButton(onPressed: app.logout, child: Text(context.tr('تسجيل الخروج', 'Sign out'))),
      ]))));
    }

    if (scopeRevision != app.scopeRevision) {
      scopeRevision = app.scopeRevision;
      for (final tab in [1, 2, 3]) {
        keys[tab] = GlobalKey<NavigatorState>();
        observers[tab] = _TabRouteObserver(
            (route, stack) => _onRouteChanged(tab, route, stack));
        tabRoutes[tab] = roots[tab];
        routeKeys[tab] = _routeKey(roots[tab], null);
        pendingKeys[tab] = null;
        stackKeys[tab].clear();
        if (tab != index) visited.remove(tab);
      }
    }
    final available = [for (var i = 0; i < roots.length; i++)
      if (app.canOpen(screen(roots[i]))) i];
    if (!available.contains(index)) {
      index = 0;
      workspace = AgentWorkspace.home;
    }
    final layout = AgentNavigationRegistry.resolve(app, workspace);
    final activeRoute = tabRoutes[index];
    final selectedRoute = layout.items.any((item) => item.route == activeRoute)
        ? activeRoute : AgentNavigationRegistry.entry(app, layout.workspace);

    return NavScope(open: open, child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await keys[index].currentState?.maybePop() == true) return;
        if (mounted && index != 0) selectTab(0);
      },
      child: Scaffold(
        extendBody: !const {'T02','T05'}.contains(activeRoute),
        body: IndexedStack(index: index, children: [
          for (var i = 0; i < roots.length; i++)
            if (available.contains(i) && visited.contains(i))
              Navigator(
                key: keys[i],
                observers: [observers[i]],
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  settings: RouteSettings(name: roots[i]),
                  builder: (_) => ScreenPage(roots[i]),
                ),
              )
            else
              const SizedBox.shrink(),
        ]),
        bottomNavigationBar: AgentGlassNavigationBar(
          layout: layout,
          arabic: app.ar,
          selectedRoute: selectedRoute,
          onSelect: _selectNavigation,
        ),
      ),
    ));
  }
}
class ScreenPage extends StatelessWidget{
  const ScreenPage(this.route,{super.key,this.id,this.seed=const {}});final String route;final int? id;final Json seed;
  @override Widget build(BuildContext context){final app=context.app,spec=screen(route);Widget body;
    if(!app.canOpen(spec)){
      body=PageBody(children:[Empty(icon:Icons.lock_outline,text:context.tr('هذه الخدمة غير متاحة لحسابك في نطاق العمل المختار.','This service is unavailable in your current work context.'),
        action:OutlinedButton(onPressed:()=>context.open('H04'),child:Text(context.tr('عرض الاعتماد والصلاحيات','View access status'))))]);
    }else if(route=='H05'||route=='H01'){body=const HomePage();}
    else if(route=='T03'){body=const ProductScanPage();}
    else if(spec.area==Area.general){body=GeneralPage(route);}
    else if(spec.area==Area.clinical){body=ClinicalPage(route,id:id,seed:seed);}
    else if(spec.area==Area.field){body=FieldPage(route,id:id,seed:seed);}
    else{body=BusinessPage(route,id:id,seed:seed);}
    final pageTitle = route == 'H05' || route == 'H01'
        ? context.tr('مزرعتي', 'Mazraa')
        : app.tr(spec.ar, spec.en);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BotanicalBackground(
        child: AgentCollapsibleAppBar(
          route: route,
          title: pageTitle,
          body: body,
        ),
      ),
    );
  }
}

typedef _RouteStackChanged = void Function(
    RouteSettings? current, List<RouteSettings> stack);

class _TabRouteObserver extends NavigatorObserver {
  _TabRouteObserver(this.onChanged);

  final _RouteStackChanged onChanged;
  final stack = <Route<dynamic>>[];

  void _notify() => onChanged(
      stack.isEmpty ? null : stack.last.settings,
      stack.map((route) => route.settings).toList());

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    stack.add(route);
    _notify();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    stack.remove(route);
    _notify();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    stack.remove(route);
    _notify();
  }

  @override
  void didReplace({
    Route<dynamic>? newRoute,
    Route<dynamic>? oldRoute,
  }) {
    if (oldRoute == null) {
      if (newRoute != null) stack.add(newRoute);
      _notify();
      return;
    }
    final i = stack.indexOf(oldRoute);
    if (i >= 0) {
      if (newRoute == null) {
        stack.removeAt(i);
      } else {
        stack[i] = newRoute;
      }
    }
    _notify();
  }
}
