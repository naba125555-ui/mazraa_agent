import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_agent/application/agent_app.dart';
import 'package:mazraa_agent/domain/models.dart';
import 'package:mazraa_agent/presentation/design/brand_theme.dart';
import 'package:mazraa_agent/presentation/features/home_insights_carousel.dart';
import 'package:mazraa_agent/presentation/features/home_insights_data.dart';
import 'package:mazraa_agent/presentation/navigation.dart';
import 'package:mazraa_agent/presentation/shared/scope.dart';
import 'fake_repository.dart';

class CountingRepository extends FakeRepository {
  final requested=<String>[];
  @override Future<dynamic> read(String path,{Json? query}) {
    requested.add(path);
    return super.read(path,query:query);
  }
}

AgentApp sample(CountingRepository repo,
    {bool doctor=true,int caps=2047,String language='ar'}) {
  final app=AgentApp(repo);
  app.starting=false;
  app.language=language;
  app.theme='light';
  app.bootstrap={
    ...FakeRepository.bootstrap,
    'doctorApproved':doctor,
    'delegations': caps==0 ? [] : [
      {'id':1,'storeId':1,'warehouseId':1,'cashBoxId':1,
       'capabilities':caps}
    ],
  };
  app.user={'name':'د. أحمد'};
  app.profile={'profile':{'isAvailable':true}};
  app.summary={'caseOffers':3,'activeCases':2,'pendingProposals':1,
    'openShifts':1,'serverTime':DateTime.now().toUtc().toIso8601String()};
  app.access=Access.from(app.bootstrap,app.summary);
  app.grantId=caps==0?null:1;
  return app;
}

Widget host(AgentApp app,{double textScale=1,GlobalKey? boundaryKey})=>
  AppScope(app:app,child:MaterialApp(
    locale:Locale(app.language),
    localizationsDelegates:GlobalMaterialLocalizations.delegates,
    supportedLocales:const [Locale('ar'),Locale('en')],
    theme:Brand.theme(app.theme=='dark'?Brightness.dark:Brightness.light),
    home:NavScope(open:(route,{id,seed}){},
      child:MediaQuery(
        data:MediaQueryData(textScaler:TextScaler.linear(textScale)),
        child:Scaffold(body:Padding(
          padding:const EdgeInsets.all(18),
          child:RepaintBoundary(key:boundaryKey,
            child:const HomeInsightsCarousel()))),
      )),
  ));

void main() {
  setUpAll(() async {
    final cairo=FontLoader('Cairo')
      ..addFont(rootBundle.load('assets/fonts/Cairo.ttf'));
    await cairo.load();
    final root=Platform.environment['FLUTTER_ROOT'];
    if(root!=null) {
      final path=File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
      if(path.existsSync()) {
        final bytes=await path.readAsBytes();
        final icons=FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(bytes)));
        await icons.load();
      }
    }
  });

  test('all eleven slides are permission-aware and role-ordered',() async {
    final repo=CountingRepository();
    final app=sample(repo);
    final available=HomeInsightsData.available(app);
    expect(available.first,InsightKind.overview);
    expect(available.length,11);
    expect(available[1],InsightKind.clinic);
    expect(available[2],InsightKind.field);
    app.dispose();

    final branch=sample(CountingRepository(),doctor:false,caps:Cap.cash);
    expect(HomeInsightsData.available(branch),
      [InsightKind.overview,InsightKind.finance]);
    branch.dispose();
    final purchaser=sample(CountingRepository(),doctor:false,caps:Cap.purchase);
    expect(HomeInsightsData.available(purchaser),
      [InsightKind.overview,InsightKind.purchasing]);
    final purchases=await HomeInsightsData.load(purchaser,InsightKind.purchasing);
    expect(purchases.headline,isNotNull);
    purchaser.dispose();
    final doctor=sample(CountingRepository(),doctor:true,caps:0);
    expect(HomeInsightsData.available(doctor),
      [InsightKind.overview,InsightKind.clinic,
       InsightKind.field,InsightKind.sync]);
    doctor.dispose();
  });

  test('exhaustive server figures are used without requesting sample lists', () async {
    final repo=CountingRepository();
    final app=sample(repo);
    final overview=await HomeInsightsData.load(app,InsightKind.overview);
    expect(overview.values.map((v)=>v.value),[3,2,1,1]);
    final clinic=await HomeInsightsData.load(app,InsightKind.clinic);
    expect(clinic.values.last.value,4);
    final finance=await HomeInsightsData.load(app,InsightKind.finance);
    expect(finance.headline,1200);
    expect(finance.currency,'SAR');
    expect(finance.series.first,200);
    expect(finance.secondary.first,20);
    final sales=await HomeInsightsData.load(app,InsightKind.sales);
    expect(sales.values.last.value,1);
    expect(sales.series.first,150);
    expect(sales.series,hasLength(7));
    expect(repo.requested,[
      '/api/agent/operations/insights/overview',
      '/api/agent/operations/insights/clinic',
      '/api/agent/operations/insights/finance',
      '/api/agent/operations/insights/sales',
    ]);
    app.dispose();
  });

  test('pickup readiness and sync history use the confirmed server counts', () async {
    final app=sample(CountingRepository());
    final pickup=await HomeInsightsData.load(app,InsightKind.pickup);
    expect(pickup.headline,3);
    expect(pickup.parts[1].value,2);
    final sync=await HomeInsightsData.load(app,InsightKind.sync);
    expect(sync.headline,0);
    expect(sync.values[1].value,2);
    app.dispose();
  });

  for(final lang in ['ar','en']) {
    testWidgets('native carousel is stable, lazy and swipeable in '+lang,
        (tester) async {
      tester.view.physicalSize=const Size(430,932);
      tester.view.devicePixelRatio=1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo=CountingRepository();
      final app=sample(repo,language:lang);
      await tester.pumpWidget(host(app));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-insights-card')),findsOneWidget);
      final frameSize=tester.getSize(
          find.byKey(const ValueKey('home-insights-card')));
      expect(repo.requested, ['/api/agent/operations/insights/overview']);
      expect(find.text(lang=='ar'?'نظرة عامة':'Overview'),findsOneWidget);
      final segment=find.byKey(const ValueKey('insight-segment-0'));
      expect(segment,findsOneWidget);
      expect(tester.getSize(segment).height,greaterThan(20));
      await tester.tap(find.byKey(const ValueKey('insight-dot-1')));
      await tester.pumpAndSettle();
      expect(find.text(lang=='ar'?'العيادة البيطرية':'Veterinary clinic'),
          findsOneWidget);
      expect(repo.requested, contains('/api/agent/operations/insights/clinic'));
      await tester.tap(find.byKey(const ValueKey('insight-dot-3')));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(const ValueKey('home-insights-card'))),
          frameSize);
      expect(repo.requested,contains('/api/agent/operations/insights/sales'));
      expect(tester.takeException(),isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
    });
  }
  testWidgets('all eleven graph designs are visualized without overflow',
      (tester) async {
    tester.view.physicalSize=const Size(430,932);
    tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo=CountingRepository();
    final app=sample(repo);
    final boundary=GlobalKey();
    await tester.pumpWidget(host(app,boundaryKey:boundary));
    await tester.pumpAndSettle();
    final expectedHeight=tester.getSize(
        find.byKey(const ValueKey('home-insights-card'))).height;
    for(var index=0;index<11;index++) {
      if(index>0) {
        await tester.tap(find.byKey(ValueKey('insight-dot-'+index.toString())));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(),isNull,reason:'insight '+index.toString());
      expect(tester.getSize(find.byKey(const ValueKey('home-insights-card'))).height,
        expectedHeight);
      final image=await tester.runAsync(() async {
        final object=boundary.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
        final raster=await object.toImage(pixelRatio:1);
        try{return await raster.toByteData(format:ui.ImageByteFormat.png);}
        finally{raster.dispose();}
      });
      expect(image,isNotNull);
      final file=File('build/previews/insight-ar-light-'+index.toString()+'.png');
      file.parent.createSync(recursive:true);
      file.writeAsBytesSync(image!.buffer.asUint8List());
    }
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets('small layout withstands 200 percent accessibility text',
      (tester) async {
    tester.view.physicalSize=const Size(320,740);
    tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app=sample(CountingRepository());
    await tester.pumpWidget(host(app,textScale:2));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-insights-card')),findsOneWidget);
    expect(tester.takeException(),isNull);
    await tester.tap(find.byKey(const ValueKey('insight-dot-4')));
    await tester.pumpAndSettle();
    expect(tester.takeException(),isNull,reason:'five inventory metrics');
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });
}
