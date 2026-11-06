import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../domain/models.dart';
import 'labels.dart';
import 'scope.dart';

class BrandLogo extends StatelessWidget{
  const BrandLogo({super.key,this.size=48});final double size;
  @override Widget build(BuildContext context)=>ClipRRect(borderRadius:BorderRadius.circular(size*.23),
    child:Image.asset('assets/branding/mazraa.png',width:size,height:size,fit:BoxFit.cover));
}
class BotanicalBackground extends StatelessWidget{
  const BotanicalBackground({super.key,required this.child});final Widget child;
  @override Widget build(BuildContext context)=>Stack(children:[
    PositionedDirectional(bottom:0,start:-35,child:IgnorePointer(child:Opacity(opacity:.32,child:
      SvgPicture.asset('assets/decorations/leaf_pattern.svg',width:230,height:310,fit:BoxFit.cover,colorFilter:ColorFilter.mode(Theme.of(context).colorScheme.primary,BlendMode.srcIn))))),
    PositionedDirectional(top:120,end:-95,child:IgnorePointer(child:Opacity(opacity:.20,child:
      Transform.rotate(angle:3.14,child:SvgPicture.asset('assets/decorations/leaf_pattern.svg',width:280,height:340,fit:BoxFit.cover,colorFilter:ColorFilter.mode(Theme.of(context).colorScheme.primary,BlendMode.srcIn)))))),
    Positioned.fill(child:child),
  ]);
}
class Panel extends StatelessWidget{
  const Panel({super.key,required this.child,this.onTap,this.padding=const EdgeInsets.all(16)});
  final Widget child;final VoidCallback? onTap;final EdgeInsetsGeometry padding;
  @override Widget build(BuildContext context)=>Card(clipBehavior:Clip.antiAlias,child:InkWell(onTap:onTap,child:Padding(padding:padding,child:child)));
}
class PageBody extends StatelessWidget{
  const PageBody({super.key,required this.children});final List<Widget> children;
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(18,8,18,32),
    physics:const AlwaysScrollableScrollPhysics(),children:children);
}
class Heading extends StatelessWidget{
  const Heading(this.title,{super.key,this.icon,this.action});final String title;final IconData? icon;final Widget? action;
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(top:22,bottom:12),child:Row(children:[
    if(icon!=null)...[Icon(icon,size:22,color:Theme.of(context).colorScheme.primary),const SizedBox(width:8)],
    Expanded(child:Text(title,style:Theme.of(context).textTheme.titleMedium)),if(action!=null)action!,
  ]));
}
class Notice extends StatelessWidget{
  const Notice(this.text,{super.key,this.error=false});final String text;final bool error;
  @override Widget build(BuildContext context){final c=Theme.of(context).colorScheme;return Container(
    padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:error?c.errorContainer:c.primaryContainer.withValues(alpha:.55),borderRadius:BorderRadius.circular(14)),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(error?Icons.error_outline:Icons.info_outline,size:21,color:error?c.error:c.primary),
      const SizedBox(width:10),Expanded(child:Text(text))]));}
}
String failureText(BuildContext context,Object e){
  if(e is Failure){
    if(e.status==401)return context.tr('انتهت الجلسة. سجّل الدخول مجددًا.','Your session expired. Sign in again.');
    if(e.status==403||e.status==404)return context.tr('السجل غير متاح ضمن صلاحياتك أو انتهى الإسناد.','This record is unavailable or its assignment has ended.');
    if(e.status==409)return context.tr('تغيّر السجل أو تعارضت العملية. حدّث البيانات وراجعها.','The record changed or the operation conflicts. Refresh and review.');
    if(e.uncertain)return context.tr('تعذر تأكيد النتيجة. راجع العمليات المعلقة قبل إنشاء عملية أخرى.','The result is unconfirmed. Check pending operations before creating another.');
    if(e.message.isNotEmpty)return e.message;
  }
  return context.tr('تعذر الاتصال بالخدمة. تحقق من الشبكة وأعد المحاولة.','Could not reach the service. Check your connection and retry.');
}
class Empty extends StatelessWidget{
  const Empty({super.key,this.text,this.action,this.icon=Icons.inbox_outlined});final String? text;final Widget? action;final IconData icon;
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:40,horizontal:20),child:Column(mainAxisSize:MainAxisSize.min,children:[
    Icon(icon,size:55,color:Theme.of(context).colorScheme.primary.withValues(alpha:.6)),const SizedBox(height:16),
    Text(text??context.tr('لا توجد سجلات حاليًا','No records yet'),textAlign:TextAlign.center),if(action!=null)...[const SizedBox(height:16),action!]]));
}
class Resource extends StatefulWidget{
  const Resource({super.key,required this.load,required this.builder,this.identity});
  final Future<dynamic> Function() load;final Widget Function(dynamic,VoidCallback) builder;final Object? identity;
  @override State<Resource> createState()=>_ResourceState();
}
class _ResourceState extends State<Resource>{
  late Future<dynamic> future;
  @override void initState(){super.initState();future=widget.load();}
  @override void didUpdateWidget(covariant Resource old){super.didUpdateWidget(old);if(old.identity!=widget.identity)future=widget.load();}
  void refresh(){setState(()=>future=widget.load());}
  @override Widget build(BuildContext context)=>FutureBuilder<dynamic>(future:future,builder:(c,s){
    if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
    if(s.hasError)return PageBody(children:[Empty(text:failureText(context,s.error!),icon:Icons.cloud_off_outlined,
      action:OutlinedButton.icon(onPressed:refresh,icon:const Icon(Icons.refresh),label:Text(context.tr('إعادة المحاولة','Retry'))))]);
    return RefreshIndicator(onRefresh:()async{refresh();try{await future;}catch(_){}},child:widget.builder(s.data,refresh));
  });
}
class StatusTag extends StatelessWidget{
  const StatusTag(this.value,{super.key});final String value;
  @override Widget build(BuildContext context){final c=Theme.of(context).colorScheme;
    final color=['Rejected','Cancelled','revoked','conflict'].contains(value)?c.error:
      ['Pending','Assigned','Requested','Draft','NeedsChanges','local'].contains(value)?c.secondary:c.primary;
    return Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:3),decoration:BoxDecoration(color:color.withValues(alpha:.1),borderRadius:BorderRadius.circular(8)),
      child:Text(word(context,value),style:TextStyle(color:color,fontSize:11,fontWeight:FontWeight.w700)));}
}
class RecordTile extends StatelessWidget{
  const RecordTile(this.data,{super.key,this.onTap,this.icon=Icons.description_outlined,this.subtitle,this.trailing});
  final Json data;final VoidCallback? onTap;final IconData icon;final String? subtitle;final Widget? trailing;
  @override Widget build(BuildContext context){final status=str(data['status']??payload(data)['status']);return Padding(padding:const EdgeInsets.only(bottom:10),child:Panel(onTap:onTap,child:Row(children:[
    Container(width:44,height:44,decoration:BoxDecoration(color:Theme.of(context).colorScheme.primaryContainer,borderRadius:BorderRadius.circular(13)),
      child:Icon(icon,color:Theme.of(context).colorScheme.primary)),const SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(titleOf(data),style:Theme.of(context).textTheme.titleMedium),
      if(subtitle!=null)Text(subtitle!,maxLines:2,overflow:TextOverflow.ellipsis),if(status.isNotEmpty)...[const SizedBox(height:4),StatusTag(status)]])),
    trailing??Icon(Directionality.of(context)==TextDirection.rtl?Icons.chevron_left:Icons.chevron_right,size:21),
  ])));}
}
String display(BuildContext context,Object? v){
  if(v==null)return '—';if(v is bool)return context.tr(v?'نعم':'لا',v?'Yes':'No');
  if(v is num)return NumberFormat('#,##0.##',context.app.language).format(v);
  final text=str(v),date=DateTime.tryParse(str(v));
  if(text.contains('T')&&date!=null)return DateFormat('d MMM y · HH:mm',context.app.language).format(date.toLocal());
  return word(context,text);
}
class Fact extends StatelessWidget{
  const Fact(this.name,this.value,{super.key});final String name;final Object? value;
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Expanded(child:Text(word(context,name),style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant))),const SizedBox(width:12),
    Expanded(child:SelectableText(display(context,value),textAlign:TextAlign.end))]));
}
class Facts extends StatelessWidget{
  const Facts(this.data,{super.key,this.fields});final Json data;final List<String>? fields;
  @override Widget build(BuildContext context)=>Panel(child:Column(children:[
    for(final key in fields??data.keys.where(words.containsKey).toList())
      if(data[key]!=null&&data[key] is! Map&&data[key] is! List)Fact(key,data[key]),
  ]));
}
class RecordDetails extends StatelessWidget{
  const RecordDetails(this.data,{super.key});final Json data;
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Facts(data),
    for(final key in ['lines','items','batches'])if(maps(data[key]).isNotEmpty)...[
      Heading(word(context,key)),for(final row in maps(data[key]))Padding(padding:const EdgeInsets.only(bottom:10),child:Facts(row))],
  ]);
}
class BusyButton extends StatefulWidget{
  const BusyButton({super.key,required this.label,required this.run,this.icon=Icons.check});
  final String label;final Future<void> Function() run;final IconData icon;
  @override State<BusyButton> createState()=>_BusyButtonState();
}
class _BusyButtonState extends State<BusyButton>{
  bool busy=false;
  @override Widget build(BuildContext context)=>FilledButton.icon(onPressed:busy?null:()async{
    setState(()=>busy=true);try{await widget.run();}catch(e){if(context.mounted)toast(context,failureText(context,e));}
    finally{if(mounted)setState(()=>busy=false);}},icon:busy?const SizedBox.square(dimension:19,child:CircularProgressIndicator(strokeWidth:2)):Icon(widget.icon),label:Text(widget.label));
}
void toast(BuildContext context,String message)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message)));
Future<bool> confirm(BuildContext context,String message)async=>await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
  title:Text(context.tr('تأكيد العملية','Confirm operation')),content:Text(message),actions:[
    TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(context.tr('رجوع','Back'))),
    FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(context.tr('تأكيد','Confirm'))),
  ]))??false;
