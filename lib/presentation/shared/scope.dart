import 'package:flutter/material.dart';
import '../../application/agent_app.dart';

class AppScope extends InheritedNotifier<AgentApp>{
  const AppScope({super.key,required AgentApp app,required super.child}):super(notifier:app);
  static AgentApp of(BuildContext context)=>context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
extension AppContext on BuildContext {
  AgentApp get app=>AppScope.of(this);
  String tr(String ar,String en)=>app.tr(ar,en);
}
