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
  final routeKeys = List<String>.of(roots.map((route) => route + ':root'));
  final pendingKeys = List<String?>.filled(roots.length, null);
  late List<NavigatorObserver> observers;
  int? scopeRevision;
  Timer? timer;
  bool refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    observers = List.generate(roots.length,
        (tab) => _TabRouteObserver((settings) => _onRouteChanged(tab, settings)));
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

  static String _signature(String route, int? id) =>
      route + ':' + (id?.toString() ?? 'root');

  void _onRouteChanged(int tab, RouteSettings? settings) {
    final active = settings?.name ?? roots[tab];
    final id = settings?.arguments is int ? settings!.arguments as int : null;
    routeKeys[tab] = _signature(active, id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || tabRoutes[tab] == active) return;
      setState(() {
        tabRoutes[tab] = active;
        if (tab == index) {
          final entry = AgentNavigationRegistry.workspaceForEntry(active);
          if (entry != null &&
              AgentNavigationRegistry.canEnter(context.app, entry)) {
            workspace = entry;
          }
        }
      });
    });
  }

  void _selectNavigation(AgentNavItem item) {
    final destination = item.openRoute;
    if (destination != item.route) {
      toast(context, context.tr(
        'اختر سجلًا من القائمة لإكمال الإجراء.',
        'Select an authorized record from the list to continue.',
      ));
    }
    open(destination);
  }

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

    // Home is permanently available from every dock and never disposes the
    // other IndexedStack navigators (including their filters and back stacks).
    if (route == 'H05') {
      if (index != 0 || workspace != AgentWorkspace.home) {
        setState(() {
          index = 0;
          visited.add(0);
          workspace = AgentWorkspace.home;
        });
      }
      keys[0].currentState?.popUntil((entry) => entry.isFirst);
      return;
    }

    final target = switch (spec.area) {
      Area.clinical => app.canOpen(screen('C01')) ? 1 : 3,
      Area.field => 2,
      Area.general => 4,
      _ => 3,
    };
    final signature = _signature(route, id);
    final destinationWorkspace =
        AgentNavigationRegistry.workspaceForEntry(route);
    final scope = app.scopeRevision;

    // Repeated presses on the same destination never add an identical route,
    // even when the first navigation push has not rendered its next frame.
    if (routeKeys[target] == signature || pendingKeys[target] == signature) {
      if (index != target) selectTab(target);
      if (destinationWorkspace != null &&
          AgentNavigationRegistry.canEnter(app, destinationWorkspace) &&
          workspace != destinationWorkspace) {
        setState(() => workspace = destinationWorkspace);
      }
      return;
    }

    final needsMount = !visited.contains(target);
    if (index != target || needsMount) selectTab(target);
    if (destinationWorkspace != null &&
        AgentNavigationRegistry.canEnter(app, destinationWorkspace)) {
      if (workspace != destinationWorkspace) {
        setState(() => workspace = destinationWorkspace);
      }
    }

    // Reserve the destination independently of the nested Navigator's
    // initial didPush notification. The initial root route must not cancel a
    // pending deep-link when switching to a previously unvisited tab.
    pendingKeys[target] = signature;
    void push() {
      if (!mounted || app.scopeRevision != scope ||
          !app.canOpen(spec) || pendingKeys[target] != signature) return;
      final navigator = keys[target].currentState;
      if (navigator == null) return;
      pendingKeys[target] = null;
      routeKeys[target] = signature;
      if (route == roots[target]) {
        navigator.popUntil((entry) => entry.isFirst);
      } else {
        navigator.push(MaterialPageRoute<void>(
          settings: RouteSettings(name: route, arguments: id),
          builder: (_) => ScreenPage(route, id: id, seed: seed ?? {}),
        ));
      }
    }
    if (needsMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => push());
    } else {
      push();
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
        observers[tab] = _TabRouteObserver((settings) => _onRouteChanged(tab, settings));
        tabRoutes[tab] = roots[tab];
        routeKeys[tab] = _signature(roots[tab], null);
        pendingKeys[tab] = null;
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

    return NavScope(open: open, child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await keys[index].currentState?.maybePop() == true) return;
        if (mounted && index != 0) selectTab(0);
      },
      child: Scaffold(
        extendBody: true,
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
          selectedRoute: tabRoutes[index],
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

class _TabRouteObserver extends NavigatorObserver {
  _TabRouteObserver(this.onRoute);
  final ValueChanged<RouteSettings?> onRoute;
  @override void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRoute(route.settings);
  }
  @override void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRoute(previousRoute?.settings);
  }
  @override void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onRoute(newRoute?.settings);
  }
}
