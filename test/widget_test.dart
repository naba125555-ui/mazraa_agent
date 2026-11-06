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
import 'package:mazraa_agent/presentation/shared/scope.dart';
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
      final image=await boundary.toImage();final bytes=await image.toByteData(format:ui.ImageByteFormat.png);
      final file=File('build/previews/home-$language-$mode.png');file.parent.createSync(recursive:true);file.writeAsBytesSync(bytes!.buffer.asUint8List());image.dispose();
      await tester.pumpWidget(const SizedBox.shrink());app.dispose();
    });
  }
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
