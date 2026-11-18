import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_agent/application/agent_app.dart';
import 'package:mazraa_agent/domain/models.dart';
import 'package:mazraa_agent/domain/screens.dart';
import 'package:mazraa_agent/presentation/design/brand_theme.dart';
import 'package:mazraa_agent/presentation/design/agent_ui.dart';
import 'package:mazraa_agent/presentation/navigation.dart';
import 'package:mazraa_agent/presentation/shared/paged_records.dart';
import 'package:mazraa_agent/presentation/shared/scope.dart';
import 'package:mazraa_agent/presentation/shared/section_banner.dart';
import 'package:mazraa_agent/presentation/shell.dart';
import 'fake_repository.dart';

AgentApp fixture(String language,String mode){
  final app=AgentApp(FakeRepository());app.starting=false;app.language=language;app.theme=mode;
  app.bootstrap=FakeRepository.bootstrap;app.user={'name':'د. أحمد','email':'test@example.com'};
  app.profile={'profile':{'isAvailable':true}};app.summary={'activeCases':2};
  app.access=Access.from(app.bootstrap,{});app.grantId=1;return app;
}
Widget host(AgentApp app,Widget child)=>AppScope(app:app,child:MaterialApp(locale:Locale(app.language),
  localizationsDelegates:GlobalMaterialLocalizations.delegates,supportedLocales:const [Locale('ar'),Locale('en')],
  theme:Brand.theme(app.theme=='dark'?Brightness.dark:Brightness.light),
  home:NavScope(open:(route,{id,seed}){},child:child)));
void main(){
  setUpAll(()async{final loader=FontLoader('Cairo')..addFont(rootBundle.load('assets/fonts/Cairo.ttf'));await loader.load();});
  for(final language in ['ar','en'])for(final mode in ['light','dark']){
    testWidgets('Home $language $mode renders at phone size with no overflow',(tester)async{
      tester.view.physicalSize=const Size(430,932);tester.view.devicePixelRatio=1;
      addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
      final app=fixture(language,mode),key=GlobalKey();
      await tester.pumpWidget(host(app,RepaintBoundary(key:key,child:const ScreenPage('H05'))));await tester.pumpAndSettle();
      expect(tester.takeException(),isNull);expect(find.textContaining(language=='ar'?'مرحبًا':'Welcome'),findsOneWidget);
      final boundary=key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      // Rasterization and PNG encoding use engine futures. Run them outside
      // FakeAsync to avoid hanging the entire widget-test suite.
      final bytes=await tester.runAsync(() async {
        final image=await boundary.toImage();
        try{return await image.toByteData(format:ui.ImageByteFormat.png);}
        finally{image.dispose();}
      });
      expect(bytes,isNotNull);
      final file=File('build/previews/home-$language-$mode.png');
      file.parent.createSync(recursive:true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
      await tester.pumpWidget(const SizedBox.shrink());app.dispose();
    });
  }
  testWidgets('Branded module banners and the sale cart fit a narrow phone',(tester)async{
    tester.view.physicalSize=const Size(360,800);
    tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app=fixture('ar','dark');
    for(final route in ['H02','H05','C01','F01','T01','T02','I01','A01','N01','P01']){
      await tester.pumpWidget(host(app,ScreenPage(route,key:ValueKey(route))));
      await tester.pumpAndSettle();
      expect(tester.takeException(),isNull,reason:route);
      if (['H02','H05','C01'].contains(route)) {
        expect(find.byType(AgentHero), findsOneWidget, reason: route);
      } else {
        expect(find.byType(SectionBanner), findsOneWidget, reason: route);
      }
      if(route=='T02')expect(find.text('عرض السلة'),findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    app.dispose();
  });

  testWidgets('A denied route does not change tabs or mount a screen', (tester) async {
    final app = fixture('en', 'light');
    app.access = const Access();
    await tester.pumpWidget(host(app, const AppShell()));
    await tester.pumpAndSettle();
    final navigation = find.byType(NavigationBar);
    expect(tester.widget<NavigationBar>(navigation).destinations, hasLength(3));
    final context = tester.element(find.byType(ScreenPage));
    context.open('C02', id: 7);
    context.open('I01');
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationBar>(navigation).selectedIndex, 0);
    expect(find.byWidgetPredicate((widget) => widget is ScreenPage && widget.route != 'H05'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets('A paged list keeps its first page through a failed continuation', (tester) async {
    final app = fixture('en', 'light');
    final requested = <int>[];
    await tester.pumpWidget(host(app, Scaffold(body: PagedRecords(
      pageSize: 2,
      load: (afterId) async {
        requested.add(afterId);
        if (afterId == 0) return [{'id': 1}, {'id': 2}];
        if (requested.length == 2) throw const Failure(503, '');
        return [{'id': 3}];
      },
      itemBuilder: (record) => Text('Record ${record['id']}'),
    ))));
    await tester.pumpAndSettle();
    expect(requested, [0]);
    expect(find.text('Record 1'), findsOneWidget);
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(requested, [0, 2]);
    expect(find.text('Record 1'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(requested, [0, 2, 2]);
    expect(find.text('Record 3'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets('All 92 routes render without uncaught errors',(tester)async{
    tester.view.physicalSize=const Size(430,932);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final app=fixture('ar','light');
    for(final spec in screens){
      await tester.pumpWidget(host(app,ScreenPage(spec.id,key:ValueKey(spec.id),id:1)));
      await tester.pumpAndSettle();
      expect(tester.takeException(),isNull,reason:spec.id);
      await tester.pumpWidget(const SizedBox.shrink());
    }app.dispose();
  });
}
