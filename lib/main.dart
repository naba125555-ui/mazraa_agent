import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'application/agent_app.dart';
import 'data/remote_repository.dart';
import 'presentation/design/brand_theme.dart';
import 'presentation/features/general.dart';
import 'presentation/shared/scope.dart';
import 'presentation/shared/widgets.dart';
import 'presentation/shell.dart';

void main(){WidgetsFlutterBinding.ensureInitialized();final app=AgentApp(RemoteRepository());runApp(MazraaAgent(app:app));app.initialize();}
class MazraaAgent extends StatelessWidget{
  const MazraaAgent({super.key,required this.app});final AgentApp app;
  @override Widget build(BuildContext context)=>AppScope(app:app,child:AnimatedBuilder(animation:app,builder:(context,_)=>MaterialApp(
    debugShowCheckedModeBanner:false,onGenerateTitle:(c)=>app.tr('مزرعتي · الطبيب والوكيل','Mazraa · Doctor and agent'),
    locale:Locale(app.language),supportedLocales:const [Locale('ar'),Locale('en')],
    localizationsDelegates:GlobalMaterialLocalizations.delegates,
    theme:Brand.theme(Brightness.light),darkTheme:Brand.theme(Brightness.dark),
    themeMode:app.theme=='dark'?ThemeMode.dark:app.theme=='light'?ThemeMode.light:ThemeMode.system,
    home:app.starting?const Scaffold(body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[BrandLogo(size:86),SizedBox(height:24),CircularProgressIndicator()]))):
      app.signedIn?AppShell(key:ValueKey(app.repo.session!.userId)):const SignInPage(),
  )));
}
