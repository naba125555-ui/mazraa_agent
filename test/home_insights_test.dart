import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
    final doctor=sample(CountingRepository(),doctor:true,caps:0);
    expect(HomeInsightsData.available(doctor),
      [InsightKind.overview,InsightKind.clinic,
       InsightKind.field,InsightKind.sync]);
    doctor.dispose();
  });

  test('server summary counters are not manufactured when fields are absent',
      () async {
    final app=sample(CountingRepository());
    app.summary={'activeCases':2};
    final overview=await HomeInsightsData.load(app,InsightKind.overview);
    expect(overview.values.map((v)=>v.label(true)).toList(),['حالات نشطة']);
    final clinic=await HomeInsightsData.load(app,InsightKind.clinic);
    expect(clinic.headline,2);
    expect(clinic.values.first.value,isNull);
    expect(clinic.values.last.value,isNull);
    app.dispose();
  });

  test('cash balance is real; unverified history stays explicitly partial',
      () async {
    final repo=CountingRepository();
    final app=sample(repo);
    final finance=await HomeInsightsData.load(app,InsightKind.finance);
    expect(finance.headline,1200);
    expect(finance.currency,'SAR');
    expect(repo.requested,contains('/api/agent/operations/cashbox'));
    final sales=await HomeInsightsData.load(app,InsightKind.sales);
    expect(sales.values.last.value,1);
    expect(repo.requested,contains('/api/agent/commerce/documents'));
    app.dispose();
  });

  test('pickup status never equates Active with Ready; synced ratio is unknown',
      () async {
    final app=sample(CountingRepository());
    final pickup=await HomeInsightsData.load(app,InsightKind.pickup);
    expect(pickup.headline,isNull);
    expect(pickup.parts.first.ar,'Active');
    final sync=await HomeInsightsData.load(app,InsightKind.sync);
    expect(sync.values[1].value,isNull);
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
      expect(repo.requested,isEmpty); // Summary slide uses bootstrap state.
      expect(find.text(lang=='ar'?'نظرة عامة':'Overview'),findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('insight-dot-1')));
      await tester.pumpAndSettle();
      expect(find.text(lang=='ar'?'العيادة البيطرية':'Veterinary clinic'),
          findsOneWidget);
      expect(repo.requested,isEmpty); // Clinic uses summary state too.
      await tester.tap(find.byKey(const ValueKey('insight-dot-3')));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(const ValueKey('home-insights-card'))),
          frameSize);
      expect(repo.requested,contains('/api/agent/commerce/documents'));
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
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });
}
