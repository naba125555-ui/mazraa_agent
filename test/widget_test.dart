import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazraa_agent/application/agent_app.dart';
import 'package:mazraa_agent/domain/models.dart';
import 'package:mazraa_agent/domain/screens.dart';
import 'package:mazraa_agent/presentation/design/brand_theme.dart';
import 'package:mazraa_agent/presentation/design/login_scenery.dart';
import 'package:mazraa_agent/presentation/collapsing_app_bar.dart';
import 'package:mazraa_agent/presentation/glass_navigation_bar.dart';
import 'package:mazraa_agent/presentation/features/sign_in.dart';
import 'package:mazraa_agent/presentation/features/home_insights_carousel.dart';
import 'package:mazraa_agent/presentation/navigation.dart';
import 'package:mazraa_agent/presentation/shared/paged_records.dart';
import 'package:mazraa_agent/presentation/shared/scope.dart';
import 'package:mazraa_agent/presentation/shared/section_banner.dart';
import 'package:mazraa_agent/presentation/shared/widgets.dart';
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
  setUpAll(() async {
    final loader = FontLoader('Cairo')
      ..addFont(rootBundle.load('assets/fonts/Cairo.ttf'));
    await loader.load();

    // The test binding does not bundle MaterialIcons automatically. Load the
    // installed Flutter font for faithful visual snapshots when available.
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      final iconFile = File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (iconFile.existsSync()) {
        final iconBytes = await iconFile.readAsBytes();
        final icons = FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(iconBytes)));
        await icons.load();
      }
    }
  });
  // H02 is independently rendered in four locale/theme combinations.
  for (final language in ['ar', 'en']) {
    for (final mode in ['light', 'dark']) {
      testWidgets('Sign-in $language $mode uses real controls without overflow',
          (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final app = fixture(language, mode);
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(host(
          app,
          RepaintBoundary(
            key: boundaryKey,
            child: const SignInPage(),
          ),
        ));
        await tester.pumpAndSettle();
        // Wait for the asset decoder before taking the *first* light-mode
        // screenshot; an Image widget can mount before its WebP frame arrives.
        await tester.runAsync(() async {
          final element = tester.element(find.byType(SignInPage));
          await Future.wait([
            precacheImage(
              const AssetImage(LoginHeaderWave.defaultImageAsset),
              element,
            ),
            precacheImage(const AssetImage(BrandLogo.assetPath), element),
            precacheImage(
              const AssetImage('assets/decorations/botanical_hanging_sprig.webp'),
              element,
            ),
          ]);
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(TextFormField), findsNWidgets(2));
        // The page and gold/emerald waves are real Flutter gradient layers.
        expect(find.byType(LoginScenery), findsOneWidget);
        expect(find.byType(LoginHeaderWave), findsOneWidget);
        expect(find.byType(BrandLogo), findsOneWidget);
        expect(BrandLogo.assetPath,
            'assets/branding/mazraa_store_dashboard_icon.webp');
        expect(
          find.text(language == 'ar' ? 'مزرعة' : 'Mazraa'),
          findsOneWidget,
        );
        final header =
            tester.widget<LoginHeaderWave>(find.byType(LoginHeaderWave));
        expect(header.photoOnLeft, language == 'ar');
        expect(header.imageAsset, LoginHeaderWave.defaultImageAsset);
        expect(find.byType(ClipPath), findsAtLeastNWidgets(5));
        // Exactly one replaceable hero image and two transparent side sprigs;
        // the waves and page gradients are still made by real widgets.
        final images = tester.widgetList<Image>(find.byType(Image)).toList();
        final assets = images.map((widget) =>
            (widget.image as AssetImage).assetName).toList();
        expect(assets, contains(LoginHeaderWave.defaultImageAsset));
        expect(
          assets.where((name) =>
              name == 'assets/decorations/botanical_hanging_sprig.webp'),
          hasLength(2),
        );
        expect(
          find.text(language == 'ar' ? 'مرحباً بك' : 'Welcome'),
          findsOneWidget,
        );
        final boundary = boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final screenshot = await boundary.toImage();
          try {
            return await screenshot.toByteData(format: ui.ImageByteFormat.png);
          } finally {
            screenshot.dispose();
          }
        });
        expect(bytes, isNotNull);
        final file = File('build/previews/login-$language-$mode.png');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes!.buffer.asUint8List());
        await tester.pumpWidget(const SizedBox.shrink());
        app.dispose();
      });
    }
  }

  for(final language in ['ar','en'])for(final mode in ['light','dark']){
    testWidgets('Home $language $mode renders at phone size with no overflow',(tester)async{
      tester.view.physicalSize=const Size(430,932);tester.view.devicePixelRatio=1;
      addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
      final app=fixture(language,mode),key=GlobalKey();
      app.user['name']=language=='ar'?'د. سامر · عرض مزرعتي':'Dr. Samer · Mazraa showcase';
      await tester.pumpWidget(host(app,RepaintBoundary(key:key,child:const AppShell())));await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final element = tester.element(find.byType(ScreenPage));
        await Future.wait([
          precacheImage(const AssetImage(SectionBanner.homeHero), element),
          precacheImage(const AssetImage(BrandLogo.assetPath), element),
          precacheImage(
            const AssetImage('assets/decorations/botanical_hanging_sprig.webp'),
            element,
          ),
        ]);
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(),isNull);
      expect(find.byType(BotanicalBackground), findsOneWidget);
      expect(find.byType(LoginScenery), findsOneWidget);
      expect(find.byType(LoginHeaderWave), findsOneWidget);
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(find.text(language=='ar'?'لوحة أعمالي':'My workspace'), findsNothing);
      expect(find.text(language=='ar'?'مزرعتي':'Mazraa'), findsWidgets);
      expect(find.byType(AgentCollapsibleAppBar), findsOneWidget);
      expect(find.byType(AgentHomeScopeStrip), findsOneWidget);
      expect(find.byType(AgentGlassNavigationBar), findsOneWidget);
      expect(find.byType(HomeInsightsCarousel), findsOneWidget);
      expect(find.byKey(const ValueKey('home-insights-card')),findsOneWidget);
      final insightsHeight=tester.getSize(find.byKey(
        const ValueKey('home-insights-card'))).height;
      expect(insightsHeight,greaterThanOrEqualTo(376));
      final dock=tester.widget<AgentGlassNavigationBar>(find.byType(AgentGlassNavigationBar));
      expect(dock.layout.items[dock.layout.primaryIndex].highlight,isTrue);
      expect(dock.layout.items.length,lessThanOrEqualTo(5));
      expect(find.byType(SectionBanner), findsNothing);
      expect(find.byType(NestedScrollView), findsNothing);
      expect(find.byKey(const ValueKey('agent-opaque-toolbar')), findsOneWidget);
      expect(find.byKey(const ValueKey('agent-wave-viewport')), findsOneWidget);
      expect(tester.getSize(find.byType(AgentGlassNavigationBar)).height, lessThan(120));
      final page = tester.widget<PageBody>(find.byType(PageBody).first);
      expect(page.fullBleedFirstChild, isFalse);
      final wave = tester.widget<LoginHeaderWave>(find.byType(LoginHeaderWave));
      expect(wave.imageAsset, SectionBanner.homeHero);
      expect(wave.photoOnLeft, language=='ar');
      expect(wave.toolbarColor, isNotNull);
      final toolbar = find.byKey(const ValueKey('agent-opaque-toolbar'));
      final viewport = find.byKey(const ValueKey('agent-wave-viewport'));
      final greeting = find.byKey(const ValueKey('home-wave-greeting'));
      final description = find.byKey(const ValueKey('home-wave-description'));
      expect(tester.getRect(viewport).top, tester.getRect(toolbar).bottom);
      expect(tester.getRect(description).top-tester.getRect(greeting).bottom, closeTo(0, .1));
      expect(tester.getRect(find.byType(AgentHomeScopeStrip)).top-tester.getRect(description).bottom, closeTo(0, .1));
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
  testWidgets('Home wave is inside the pinned app bar and follows scroll', (tester) async {
    tester.view.physicalSize=const Size(390,844);
    tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app=fixture('ar','dark');
    await tester.pumpWidget(host(app,const ScreenPage('H05')));
    await tester.pumpAndSettle();
    expect(find.byType(AgentHomeScopeStrip),findsOneWidget);
    expect(find.byType(SliverAppBar),findsNothing);
    expect(find.byType(SectionBanner),findsNothing);
    final wave = find.byKey(const ValueKey('agent-wave-viewport'));
    final fullHeight = tester.getSize(wave).height;
    final toolbar = find.byKey(const ValueKey('agent-opaque-toolbar'));
    final pinned = tester.getRect(toolbar);
    final list = find.byType(ListView).first;
    expect(fullHeight, inInclusiveRange(190, 245));

    // The statistics use a horizontal gesture and must not move the header.
    final slider = find.byType(PageView);
    await tester.drag(slider, const Offset(155, -8));
    await tester.pumpAndSettle();
    expect(tester.getSize(wave).height, closeTo(fullHeight, 1));

    await tester.drag(list, const Offset(0, -460));
    await tester.pumpAndSettle();
    expect(tester.getSize(wave).height, lessThan(1));
    expect(tester.getRect(toolbar), pinned);

    // A reverse drag restores the header while the list is still scrolled.
    final position = tester.state<ScrollableState>(
      find.descendant(of: list, matching: find.byType(Scrollable)).first,
    ).position;
    expect(position.pixels, greaterThan(82));
    await tester.drag(list, const Offset(0, 82));
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
    expect(tester.getSize(wave).height, closeTo(fullHeight, 1));
    expect(tester.getRect(toolbar), pinned);

    // Reversing direction mid-animation continues from the current height.
    final gesture = await tester.startGesture(tester.getCenter(list));
    await gesture.moveBy(const Offset(0, -35));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    final collapsingHeight = tester.getSize(wave).height;
    expect(collapsingHeight, inExclusiveRange(0, fullHeight));
    await gesture.moveBy(const Offset(0, 35));
    await tester.pump();
    expect(tester.getSize(wave).height, closeTo(collapsingHeight, 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getSize(wave).height, closeTo(fullHeight, 1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets('320dp glass dock stays usable at 200 percent text scale',(tester)async{
    tester.view.physicalSize=const Size(320,740);
    tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app=fixture('ar','dark');
    await tester.pumpWidget(host(app,MediaQuery(
      data:const MediaQueryData(textScaler:TextScaler.linear(2)),
      child:const AppShell(),
    )));
    await tester.pumpAndSettle();
    expect(find.byType(AgentGlassNavigationBar),findsOneWidget);
    expect(find.byKey(const ValueKey('agent-primary-navigation')),findsOneWidget);
    expect(tester.getSize(find.byType(AgentGlassNavigationBar)).height,lessThan(120));
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

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
      expect(find.byType(AgentCollapsibleAppBar), findsOneWidget,reason:route);
      expect(find.byKey(const ValueKey('agent-opaque-toolbar')),findsOneWidget,reason:route);
      expect(find.byKey(const ValueKey('agent-wave-viewport')),route=='H05'?findsOneWidget:findsNothing,reason:route);
      if(route=='H05')expect(find.byType(SectionBanner),findsNothing);
      else if(route!='H02')expect(find.byType(SectionBanner),findsOneWidget,reason:route);
      else expect(find.text('تسجيل الدخول'),findsWidgets);
      if(route=='T02')expect(find.text('عرض السلة'),findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    app.dispose();
  });

  testWidgets('Home stays first, route taps are idempotent, tabs stay mounted',(tester)async{
    tester.view.physicalSize=const Size(390,844);
    tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app=fixture('ar','dark');
    await tester.pumpWidget(host(app,const AppShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'تبديل'));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w)=>w is ScreenPage && w.route=='H06'),findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('agent-nav-H05-الرئيسية')));
    await tester.pumpAndSettle();
    final original=tester.element(find.byType(ScreenPage).first);
    original.open('T02');
    original.open('T02');
    original.open('T02');
    await tester.pumpAndSettle();
    final sale=find.byWidgetPredicate((w)=>w is ScreenPage && w.route=='T02',skipOffstage:false);
    expect(sale,findsOneWidget);
    final dock=tester.widget<AgentGlassNavigationBar>(find.byType(AgentGlassNavigationBar));
    expect(dock.layout.items.first.route,'H05');
    await tester.tap(find.byKey(const ValueKey('agent-nav-H05-الرئيسية')));
    await tester.pumpAndSettle();
    expect(sale,findsOneWidget); // Offstage sale tab is kept alive.
    expect(tester.widget<AgentGlassNavigationBar>(
        find.byType(AgentGlassNavigationBar)).selectedRoute,'H05');
    final homeContext=tester.element(find.byType(ScreenPage).first);
    homeContext.open('T02');
    await tester.pumpAndSettle();
    expect(sale,findsOneWidget);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets('A denied route does not change tabs or mount a screen', (tester) async {
    final app = fixture('en', 'light');
    app.access = const Access();
    await tester.pumpWidget(host(app, const AppShell()));
    await tester.pumpAndSettle();
    final navigation = find.byType(AgentGlassNavigationBar);
    final dock = tester.widget<AgentGlassNavigationBar>(navigation);
    expect(dock.layout.items.length, inInclusiveRange(2,5));
    expect(dock.layout.items.any((item) => item.route=='C01'||item.route=='I01'), isFalse);
    final context = tester.element(find.byType(ScreenPage));
    context.open('C02', id: 7);
    context.open('I01');
    await tester.pumpAndSettle();
    expect(tester.widget<AgentGlassNavigationBar>(navigation).selectedRoute, 'H05');
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
      expect(find.byKey(const ValueKey('agent-wave-viewport')),
        spec.id=='H05'?findsOneWidget:findsNothing,reason:spec.id);
      expect(find.byType(AgentHomeScopeStrip),
        spec.id=='H05'?findsOneWidget:findsNothing,reason:spec.id);
      await tester.pumpWidget(const SizedBox.shrink());
    }app.dispose();
  });
}
