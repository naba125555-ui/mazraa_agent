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
import 'package:mazraa_agent/presentation/navigation.dart';
import 'package:mazraa_agent/presentation/shared/paged_records.dart';
import 'package:mazraa_agent/presentation/shared/scope.dart';
import 'package:mazraa_agent/presentation/design/screen_design.dart';
import 'package:mazraa_agent/main.dart';
import 'package:mazraa_agent/presentation/shell.dart';
import 'fake_repository.dart';

AgentApp fixture(String language, String mode) {
  final app = AgentApp(FakeRepository());
  app.starting = false;
  app.language = language;
  app.theme = mode;
  app.bootstrap = FakeRepository.bootstrap;
  app.user = {'name': 'د. أحمد', 'email': 'test@example.com'};
  app.profile = {
    'profile': {'isAvailable': true, 'specialty': 'طب حيوانات المزرعة'},
  };
  app.summary = {'caseOffers': 1, 'activeCases': 2, 'openShifts': 1};
  app.access = Access.from(app.bootstrap, {});
  app.grantId = 1;
  return app;
}

Widget host(AgentApp app, Widget child) => AppScope(
  app: app,
  child: MaterialApp(
    locale: Locale(app.language),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('ar'), Locale('en')],
    theme: Brand.theme(
      app.theme == 'dark' ? Brightness.dark : Brightness.light,
    ),
    home: NavScope(open: (route, {id, seed}) {}, child: child),
  ),
);
Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final context = key.currentContext!;
    await Future.wait([
      for (final asset in [
        'assets/branding/mazraa.png',
        for (final art in ['workspace', 'clinical', 'commerce', 'field'])
          'assets/images/agent_$art.webp',
      ])
        precacheImage(AssetImage(asset), context),
    ]);
  });
  await tester.pumpAndSettle();
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return await image.toByteData(format: ui.ImageByteFormat.png);
    } finally {
      image.dispose();
    }
  });
  expect(bytes, isNotNull, reason: name);
  final file = File('build/previews/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'Cairo': 'assets/fonts/Cairo.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(rootBundle.load(entry.value));
      await loader.load();
    }
  });
  for (final language in ['ar', 'en'])
    for (final mode in ['light', 'dark']) {
      testWidgets(
        'Home $language $mode renders at phone size with no overflow',
        (tester) async {
          tester.view.physicalSize = const Size(430, 932);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final app = fixture(language, mode), key = GlobalKey();
          await tester.pumpWidget(
            host(
              app,
              RepaintBoundary(key: key, child: const ScreenPage('H05')),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.textContaining(language == 'ar' ? 'مرحبًا' : 'Welcome'),
            findsOneWidget,
          );
          await capture(tester, key, 'home-$language-$mode');
          await tester.pumpWidget(const SizedBox.shrink());
          app.dispose();
        },
      );
    }
  testWidgets('Workspaces and the sale cart fit a narrow dark phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = fixture('ar', 'dark');
    for (final route in [
      'H02',
      'H05',
      'C01',
      'F01',
      'T01',
      'T02',
      'I01',
      'A01',
      'N01',
      'P01',
    ]) {
      await tester.pumpWidget(
        host(app, ScreenPage(route, key: ValueKey(route))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: route);
      if (route != 'H05')
        expect(find.byType(ScreenIntroduction), findsOneWidget, reason: route);
      if (route == 'T02') expect(find.text('عرض السلة'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    app.dispose();
  });

  testWidgets('A denied route does not change tabs or mount a screen', (
    tester,
  ) async {
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
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ScreenPage && widget.route != 'H05',
      ),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets(
    'A paged list keeps its first page through a failed continuation',
    (tester) async {
      final app = fixture('en', 'light');
      final requested = <int>[];
      await tester.pumpWidget(
        host(
          app,
          Scaffold(
            body: PagedRecords(
              pageSize: 2,
              load: (afterId) async {
                requested.add(afterId);
                if (afterId == 0)
                  return [
                    {'id': 1},
                    {'id': 2},
                  ];
                if (requested.length == 2) throw const Failure(503, '');
                return [
                  {'id': 3},
                ];
              },
              itemBuilder: (record) => Text('Record ${record['id']}'),
            ),
          ),
        ),
      );
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
    },
  );

  testWidgets('Cross-area details keep their originating navigation stack', (
    tester,
  ) async {
    final app = fixture('en', 'light');
    await tester.pumpWidget(host(app, const AppShell()));
    await tester.pumpAndSettle();
    final home = find.byWidgetPredicate(
      (widget) => widget is ScreenPage && widget.route == 'H05',
    );
    tester.element(home).open('C02', id: 1);
    await tester.pumpAndSettle();
    final casePage = find.byWidgetPredicate(
      (widget) => widget is ScreenPage && widget.route == 'C02',
    );
    expect(casePage, findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    tester.element(casePage).open('F02', id: 1);
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ScreenPage && widget.route == 'F02',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(casePage, findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(home, findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets('Welcome opens recovery and returns to the sign-in flow', (
    tester,
  ) async {
    final app = fixture('en', 'light');
    (app.repo as FakeRepository).session = null;
    await tester.pumpWidget(MazraaAgent(app: app));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Recover access'), findsOneWidget);
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ui-test@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'test-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets('All 92 screens have layouts and produce review images', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = fixture('ar', 'light');
    final expected = screens.map((spec) => spec.id).toSet();
    expect(screenDesigns.keys.toSet(), expected);
    const withRecord = {
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
      'F02',
      'F04',
      'F05',
      'F06',
      'F07',
      'F08',
      'F10',
      'F11',
      'F12',
      'F13',
      'I02',
      'I03',
      'I04',
      'I08',
      'T04',
      'T07',
      'T13',
      'N04',
      'N07',
      'P03',
      'P04',
      'P05',
      'P06',
      'P07',
      'A05',
      'A06',
      'A07',
      'A08',
      'A09',
      'G03',
      'G04',
    };
    const roots = {'H05', 'C01', 'F01', 'T01', 'H08'};
    for (final spec in screens) {
      final key = GlobalKey();
      await tester.pumpWidget(
        host(
          app,
          RepaintBoundary(
            key: key,
            child: roots.contains(spec.id)
                ? const AppShell()
                : ScreenPage(
                    spec.id,
                    id: withRecord.contains(spec.id) ? 1 : null,
                  ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (roots.contains(spec.id) && spec.id != 'H05') {
        tester.element(find.byType(ScreenPage)).open(spec.id);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull, reason: spec.id);
      if (!['H01', 'H05'].contains(spec.id)) {
        expect(find.text(spec.ar), findsWidgets, reason: spec.id);
      }
      await capture(tester, key, 'screens/${spec.id}');
      await tester.pumpWidget(const SizedBox.shrink());
    }
    app.dispose();
  });
}
