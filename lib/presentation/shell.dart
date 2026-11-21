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
  int? scopeRevision;
  Timer? timer;
  bool refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    final target = switch (spec.area) {
      Area.clinical => app.canOpen(screen('C01')) ? 1 : 3,
      Area.field => 2,
      Area.general => route == 'H05' ? 0 : 4,
      _ => 3,
    };
    final scope = app.scopeRevision;
    void push() {
      if (!mounted || app.scopeRevision != scope || !app.canOpen(spec)) return;
      final navigator = keys[target].currentState;
      if (navigator == null) return;
      if (route == roots[target]) {
        navigator.popUntil((entry) => entry.isFirst);
        return;
      }
      navigator.push(MaterialPageRoute<void>(
        settings: RouteSettings(name: route),
        builder: (_) => ScreenPage(route, id: id, seed: seed ?? {}),
      ));
    }

    final needsMount = !visited.contains(target);
    if (index != target || needsMount) selectTab(target);
    if (needsMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => push());
    } else {
      push();
    }
  }

  void selectTab(int tab) => setState(() {
    index = tab;
    visited.add(tab);
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
        if (tab != index) visited.remove(tab);
      }
    }
    final available = [for (var i = 0; i < roots.length; i++)
      if (app.canOpen(screen(roots[i]))) i];
    if (!available.contains(index)) index = 0;
    final destinations = [
      NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: context.tr('الرئيسية', 'Home')),
      NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), selectedIcon: const Icon(Icons.chat_bubble), label: context.tr('الاستشارات', 'Cases')),
      NavigationDestination(icon: const Icon(Icons.assignment_outlined), selectedIcon: const Icon(Icons.assignment), label: context.tr('المهام', 'Tasks')),
      NavigationDestination(icon: const Icon(Icons.storefront_outlined), selectedIcon: const Icon(Icons.storefront), label: context.tr('تجارتي', 'Business')),
      NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: context.tr('حسابي', 'Account')),
    ];

    return NavScope(open: open, child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await keys[index].currentState?.maybePop() == true) return;
        if (mounted && index != 0) setState(() => index = 0);
      },
      child: Scaffold(
        body: IndexedStack(index: index, children: [
          for (var i = 0; i < roots.length; i++)
            if (available.contains(i) && visited.contains(i))
              Navigator(
                key: keys[i],
                onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => ScreenPage(roots[i])),
              )
            else
              const SizedBox.shrink(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: available.indexOf(index),
          onDestinationSelected: (destination) => selectTab(available[destination]),
          destinations: [for (final tab in available) destinations[tab]],
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
    return Scaffold(appBar:AppBar(title:route=='H05'?const BrandLogo(size:44):Text(app.tr(spec.ar,spec.en)),
      leading:route=='H05'?IconButton(tooltip:context.tr('حسابي','My account'),icon:const Icon(Icons.account_circle_outlined),onPressed:()=>context.open('H08')):null,
      actions:[if(route!='H07')IconButton(tooltip:context.tr('الإشعارات','Notifications'),icon:const Icon(Icons.notifications_none),onPressed:()=>context.open('H07'))]),
      body:BotanicalBackground(child:body));
  }
}
