import 'package:flutter/material.dart';
import '../domain/models.dart';

typedef OpenScreen=void Function(String screen,{int? id,Json? seed});
class NavScope extends InheritedWidget{
  const NavScope({super.key,required this.open,required super.child});final OpenScreen open;
  static OpenScreen of(BuildContext c)=>c.dependOnInheritedWidgetOfExactType<NavScope>()!.open;
  @override bool updateShouldNotify(covariant NavScope old)=>open!=old.open;
}
extension NavigationContext on BuildContext{
  void open(String screen,{int? id,Json? seed})=>NavScope.of(this)(screen,id:id,seed:seed);
}
