import 'dart:ui';
import 'package:flutter/material.dart';
import 'navigation_registry.dart';

/// Blurred, translucent, permission-aware dock with a fixed floating action.
class AgentGlassNavigationBar extends StatelessWidget {
  const AgentGlassNavigationBar({super.key,required this.layout,required this.arabic,required this.selectedRoute,required this.onSelect});
  final AgentNavLayout layout;
  final bool arabic;
  final String selectedRoute;
  final ValueChanged<AgentNavItem> onSelect;
  @override Widget build(BuildContext context) {
    final dark=Theme.of(context).brightness==Brightness.dark;
    final center=layout.items[layout.primaryIndex];
    final before=layout.items.take(layout.primaryIndex).toList();
    final after=layout.items.skip(layout.primaryIndex+1).toList();
    return SafeArea(top:false,minimum:const EdgeInsets.only(bottom:7),child:Padding(
      padding:const EdgeInsets.symmetric(horizontal:12),
      child:SizedBox(height:102,child:Stack(alignment:Alignment.bottomCenter,clipBehavior:Clip.none,children:[
        Positioned(left:0,right:0,bottom:0,height:81,child:AnimatedSwitcher(
          duration:const Duration(milliseconds:220),
          child:ClipRRect(key:ValueKey(layout.workspace),borderRadius:BorderRadius.circular(28),
            child:BackdropFilter(filter:ImageFilter.blur(sigmaX:20,sigmaY:20),
              child:DecoratedBox(decoration:BoxDecoration(
                borderRadius:BorderRadius.circular(28),
                color:dark?const Color(0xB0004B3A):const Color(0xAE73AE98),
                border:Border.all(color:dark?const Color(0x809ED8C0):const Color(0xC8FFFFFF),width:1.2),
                boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.18),blurRadius:20,offset:const Offset(0,8))],
              ),child:Row(children:[
                Expanded(child:Row(children:[for(final item in before) Expanded(child:_DockItem(
                  item:item,arabic:arabic,dark:dark,selected:selectedRoute==item.route,onTap:()=>onSelect(item)))])),
                const SizedBox(width:72),
                Expanded(child:Row(children:[for(final item in after) Expanded(child:_DockItem(
                  item:item,arabic:arabic,dark:dark,selected:selectedRoute==item.route,onTap:()=>onSelect(item)))])),
              ])),
            ),
          ),
        )),
        Positioned(top:0,child:Semantics(button:true,label:center.label(arabic),child:Tooltip(
          message:center.label(arabic),
          child:Material(color:Colors.transparent,child:InkWell(
            key:const ValueKey('agent-primary-navigation'),
            borderRadius:BorderRadius.circular(46),onTap:()=>onSelect(center),
            child:Container(width:69,height:69,decoration:BoxDecoration(
              shape:BoxShape.circle,
              gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
                colors:[Color(0xFF37D783),Color(0xFF0DA568),Color(0xFF00573B)]),
              border:Border.all(color:const Color(0x8BDAFFDE),width:1.4),
              boxShadow:const [BoxShadow(color:Color(0x88001B13),blurRadius:20,offset:Offset(0,8))],
            ),child:Icon(center.icon,size:31,color:Colors.white)),
          )),
        ))),
        Positioned(bottom:5,child:SizedBox(width:75,height:18,child:FittedBox(fit:BoxFit.scaleDown,child:Text(center.label(arabic),
          textAlign:TextAlign.center,maxLines:1,overflow:TextOverflow.ellipsis,
          style:TextStyle(fontWeight:FontWeight.w900,fontSize:10,color:dark?Colors.white:const Color(0xFF103D30)))))),
      ])),
    ));
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({required this.item,required this.arabic,required this.selected,required this.dark,required this.onTap});
  final AgentNavItem item;
  final bool arabic,selected,dark;
  final VoidCallback onTap;
  @override Widget build(BuildContext context)=>Semantics(button:true,selected:selected,label:item.label(arabic),
    child:InkWell(key:ValueKey('agent-nav-'+item.route+'-'+item.ar),borderRadius:BorderRadius.circular(18),onTap:onTap,
      child:Padding(padding:const EdgeInsets.symmetric(horizontal:1,vertical:4),
        child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          AnimatedContainer(duration:const Duration(milliseconds:210),curve:Curves.easeOutCubic,
            width:double.infinity,height:33,constraints:const BoxConstraints(maxWidth:60),
            decoration:BoxDecoration(borderRadius:BorderRadius.circular(25),
              color:selected?const Color(0xFF087C49):Colors.transparent),
            child:Icon(item.icon,size:22,color:selected?Colors.white:dark?const Color(0xFFCFDED8):const Color(0xFF215646))),
          const SizedBox(height:2),
          SizedBox(height:18,child:FittedBox(fit:BoxFit.scaleDown,child:Text(item.label(arabic),maxLines:1,
            style:TextStyle(fontSize:10.4,height:1.0,fontWeight:selected?FontWeight.w900:FontWeight.w700,
              color:dark?Colors.white:const Color(0xFF173C31))))),
        ]),
      ),
    ),
  );
}
