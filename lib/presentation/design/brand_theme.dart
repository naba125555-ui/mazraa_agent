import 'package:flutter/material.dart';

abstract final class Brand {
  static const forest=Color(0xFF155A37),orange=Color(0xFFC76532),ivory=Color(0xFFFCFAF2),
    night=Color(0xFF0D1510),mint=Color(0xFF83C99E);
  static ThemeData theme(Brightness brightness){
    final dark=brightness==Brightness.dark;
    final c=ColorScheme.fromSeed(seedColor:forest,brightness:brightness).copyWith(
      primary:dark?mint:forest,onPrimary:dark?night:Colors.white,
      primaryContainer:dark?const Color(0xFF174B31):const Color(0xFFE9F0E5),
      secondary:dark?const Color(0xFFFFA278):orange,
      surface:dark?const Color(0xFF17231B):const Color(0xFFFFFDF7),
      onSurface:dark?const Color(0xFFECEDE8):const Color(0xFF173E2B),
      onSurfaceVariant:dark?const Color(0xFFB3C0B5):const Color(0xFF77766D),
      outline:dark?const Color(0xFF536057):const Color(0xFFE8E1D2),
    );
    final border=OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide(color:c.outline));
    return ThemeData(useMaterial3:true,colorScheme:c,fontFamily:'Cairo',fontFamilyFallback:const ['Noto Sans Arabic','Arial'],
      scaffoldBackgroundColor:dark?night:ivory,
      textTheme:TextTheme(headlineLarge:TextStyle(fontSize:28,fontWeight:FontWeight.w800,color:c.onSurface),
        headlineSmall:TextStyle(fontSize:23,fontWeight:FontWeight.w800,color:c.onSurface),
        titleLarge:TextStyle(fontSize:20,fontWeight:FontWeight.w700,color:c.onSurface),
        titleMedium:TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:c.onSurface),
        bodyLarge:TextStyle(fontSize:15,height:1.65,color:c.onSurface),
        bodyMedium:TextStyle(fontSize:13,height:1.65,color:c.onSurface),
        labelLarge:TextStyle(fontSize:14,fontWeight:FontWeight.w700,color:c.onSurface)),
      appBarTheme:AppBarTheme(centerTitle:true,backgroundColor:dark?night:ivory,surfaceTintColor:Colors.transparent,elevation:0,
        titleTextStyle:TextStyle(fontFamily:'Cairo',fontSize:18,fontWeight:FontWeight.w700,color:c.onSurface)),
      cardTheme:CardThemeData(elevation:0,color:c.surface,margin:EdgeInsets.zero,
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18),side:BorderSide(color:c.outline.withValues(alpha:.7)))),
      inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:c.surface,border:border,enabledBorder:border,
        focusedBorder:border.copyWith(borderSide:BorderSide(color:c.primary,width:1.5)),contentPadding:const EdgeInsets.all(15)),
      filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(minimumSize:const Size(48,52),
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)))),
      outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(minimumSize:const Size(48,50),
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)))),
      navigationBarTheme:NavigationBarThemeData(height:72,backgroundColor:c.surface,indicatorColor:c.primaryContainer,
        labelTextStyle:WidgetStatePropertyAll(TextStyle(fontFamily:'Cairo',fontSize:11,fontWeight:FontWeight.w700,color:c.onSurface))),
      dividerTheme:DividerThemeData(color:c.outline,space:24),
      bottomSheetTheme:BottomSheetThemeData(backgroundColor:c.surface,showDragHandle:true,
        shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(28)))),
      snackBarTheme:const SnackBarThemeData(behavior:SnackBarBehavior.floating),
    );
  }
}
