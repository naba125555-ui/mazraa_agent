import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/screens.dart';
import 'design/screen_design.dart';
import 'features/business.dart';
import 'features/entry.dart';
import 'features/clinical.dart';
import 'features/field.dart';
import 'features/general.dart';
import 'features/home.dart';
import 'features/scan.dart';
import 'navigation.dart';
import 'shared/scope.dart';
import 'shared/widgets.dart';

const implementedScreens = <String>{
  'H01',
  'H02',
  'H03',
  'H04',
  'H05',
  'H06',
  'H07',
  'H08',
  'H09',
  'H10',
  'H11',
  'C01',
  'C02',
  'C03',
  'C04',
  'C05',
  'C06',
  'C07',
  'C08',
  'C09',
  'C10',
  'C11',
  'C12',
  'C13',
  'C14',
  'C15',
  'C16',
  'F01',
  'F02',
  'F03',
  'F04',
  'F05',
  'F06',
  'F07',
  'F08',
  'F09',
  'F10',
  'F11',
  'F12',
  'F13',
  'I01',
  'I02',
  'I03',
  'I04',
  'I05',
  'I06',
  'I07',
  'I08',
  'I09',
  'I10',
  'T01',
  'T02',
  'T03',
  'T04',
  'T05',
  'T06',
  'T07',
  'T08',
  'T09',
  'T10',
  'T11',
  'T12',
  'T13',
  'T14',
  'N01',
  'N02',
  'N03',
  'N04',
  'N05',
  'N06',
  'N07',
  'N08',
  'P01',
  'P02',
  'P03',
  'P04',
  'P05',
  'P06',
  'P07',
  'A01',
  'A02',
  'A03',
  'A04',
  'A05',
  'A06',
  'A07',
  'A08',
  'A09',
  'G01',
  'G02',
  'G03',
  'G04',
};

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  static const roots = ['H05', 'C01', 'F01', 'T01', 'H08'];
  final keys = List.generate(roots.length, (_) => GlobalKey<NavigatorState>());
  final visited = <int>{0};
  final detail = List.filled(roots.length, false);
  final observers = <NavigatorObserver>[];
  int index = 0;
  int? scopeRevision;
  Timer? timer;
  bool refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (var tab = 0; tab < roots.length; tab++) {
      observers.add(observerFor(tab));
    }
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

  NavigatorObserver observerFor(int tab) => _PageObserver((isDetail) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && detail[tab] != isDetail) {
        setState(() => detail[tab] = isDetail);
      }
    });
  });

  void open(String route, {int? id, Json? seed}) {
    if (!implementedScreens.contains(route) || entryRoutes.contains(route))
      return;
    final app = context.app;
    if (!app.canOpen(screen(route))) {
      toast(
        context,
        context.tr(
          'هذه الخدمة غير متاحة في نطاق العمل الحالي.',
          'This service is unavailable in the current work context.',
        ),
      );
      return;
    }
    final root = roots.indexOf(route);
    if (root >= 0) {
      selectTab(root);
      return;
    }
    keys[index].currentState?.push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: route),
        builder: (_) => ScreenPage(route, id: id, seed: seed ?? {}),
      ),
    );
  }

  void selectTab(int tab) {
    if (tab == index)
      keys[tab].currentState?.popUntil((entry) => entry.isFirst);
    setState(() {
      index = tab;
      visited.add(tab);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    if (app.bootstrap.isEmpty) {
      final failure = app.accessError;
      if (failure == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return Scaffold(
        body: SafeArea(
          child: PageBody(
            children: [
              Notice(failureText(context, failure), error: true),
              const SizedBox(height: 16),
              BusyButton(
                label: context.tr('إعادة الاتصال', 'Reconnect'),
                run: app.refreshAccess,
              ),
              TextButton(
                onPressed: app.logout,
                child: Text(context.tr('تسجيل الخروج', 'Sign out')),
              ),
            ],
          ),
        ),
      );
    }

    if (scopeRevision != app.scopeRevision) {
      scopeRevision = app.scopeRevision;
      for (var tab = 0; tab < roots.length; tab++) {
        keys[tab] = GlobalKey<NavigatorState>();
        observers[tab] = observerFor(tab);
        detail[tab] = false;
        if (tab != index) visited.remove(tab);
      }
    }
    final available = [
      for (var i = 0; i < roots.length; i++)
        if (app.canOpen(screen(roots[i]))) i,
    ];
    if (!available.contains(index)) {
      index = 0;
      visited.add(index);
    }
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: context.tr('الرئيسية', 'Home'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.chat_bubble_outline),
        selectedIcon: const Icon(Icons.chat_bubble),
        label: context.tr('الاستشارات', 'Cases'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.assignment_outlined),
        selectedIcon: const Icon(Icons.assignment),
        label: context.tr('المهام', 'Tasks'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.storefront_outlined),
        selectedIcon: const Icon(Icons.storefront),
        label: context.tr('تجارتي', 'Business'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: context.tr('حسابي', 'Account'),
      ),
    ];

    return NavScope(
      open: open,
      child: PopScope(
        canPop: index == 0 && !detail[0],
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (await keys[index].currentState?.maybePop() == true) return;
          if (mounted && index != 0) selectTab(0);
        },
        child: Scaffold(
          body: IndexedStack(
            index: index,
            children: [
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
            ],
          ),
          bottomNavigationBar: detail[index]
              ? null
              : NavigationBar(
                  selectedIndex: available.indexOf(index),
                  onDestinationSelected: (destination) =>
                      selectTab(available[destination]),
                  destinations: [
                    for (final tab in available) destinations[tab],
                  ],
                ),
        ),
      ),
    );
  }
}

class _PageObserver extends NavigatorObserver {
  _PageObserver(this.onTop);
  final ValueChanged<bool> onTop;

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    if (topRoute is PageRoute) onTop(!topRoute.isFirst);
  }
}

class ScreenPage extends StatelessWidget {
  const ScreenPage(this.route, {super.key, this.id, this.seed = const {}});
  final String route;
  final int? id;
  final Json seed;

  @override
  Widget build(BuildContext context) {
    if (entryRoutes.contains(route)) return EntryPage(route: route);
    final app = context.app;
    final spec = screen(route);
    final root = _AppShellState.roots.contains(route);
    final allowed = app.canOpen(spec);
    final Widget body;
    if (!allowed) {
      body = PageBody(
        children: [
          Empty(
            icon: Icons.lock_outline,
            text: context.tr(
              'هذه الخدمة غير متاحة لحسابك في نطاق العمل المختار.',
              'This service is unavailable in your current work context.',
            ),
            action: OutlinedButton(
              onPressed: () => context.open('H04'),
              child: Text(
                context.tr('عرض الاعتماد والصلاحيات', 'View access status'),
              ),
            ),
          ),
        ],
      );
    } else {
      body = switch (route) {
        'H05' => const HomePage(),
        'T03' => const ProductScanPage(),
        _ => switch (spec.area) {
          Area.general => GeneralPage(route),
          Area.clinical => ClinicalPage(route, id: id, seed: seed),
          Area.field => FieldPage(route, id: id, seed: seed),
          _ => BusinessPage(route, id: id, seed: seed),
        },
      };
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: root ? 17 : 0,
        title: Row(
          children: [
            if (root) ...[const BrandLogo(size: 32), const SizedBox(width: 10)],
            Flexible(
              child: Text(
                root
                    ? context.tr('مزرعتي', 'Mazraa')
                    : areaName(context, spec.area),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (root)
            IconButton(
              tooltip: context.tr('الإشعارات', 'Notifications'),
              icon: const Icon(Icons.notifications_none),
              onPressed: () => context.open('H07'),
            ),
          if (route == 'H05')
            IconButton(
              tooltip: context.tr('نطاق العمل', 'Work context'),
              icon: const Icon(Icons.warehouse_outlined),
              onPressed: () => context.open('H06'),
            ),
          const SizedBox(width: 7),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: !root,
        child: Column(
          children: [
            if (route != 'H05')
              ScreenIntroduction(spec, record: seed, recordId: id),
            if (allowed) WorkflowProgress(route),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: SizedBox.expand(child: body),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
