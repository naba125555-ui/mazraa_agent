import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import '../../domain/models.dart';
import '../design/login_scenery.dart';
import 'labels.dart';
import 'scope.dart';
import 'product_thumbnail.dart';

/// The user-supplied Mazraa store artwork, shared by every app bar and
/// the sign-in/splash brand marks. Store it as an optimized, local WebP asset.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 48});
  static const assetPath = 'assets/branding/mazraa_store_dashboard_icon.webp';
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * .23),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          semanticLabel: 'Mazraa',
        ),
      );
}
/// Every authenticated screen (including all nested routes) shares the same
/// responsive live-wave scenery as sign-in; the scrollable page remains above
/// the non-interactive scenery and never loses hit-testing or scroll behavior.
class BotanicalBackground extends StatelessWidget {
  const BotanicalBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: LoginScenery(dark: dark),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
class Panel extends StatelessWidget{
  const Panel({super.key,required this.child,this.onTap,this.padding=const EdgeInsets.all(16)});
  final Widget child;final VoidCallback? onTap;final EdgeInsetsGeometry padding;
  @override Widget build(BuildContext context)=>Card(clipBehavior:Clip.antiAlias,child:InkWell(onTap:onTap,child:Padding(padding:padding,child:child)));
}
/// Standard padded content, with an opt-in edge-to-edge first item for
/// the home hero. Subsequent controls retain their readable 18px margins.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.fullBleedFirstChild = false,
  });
  final List<Widget> children;
  final bool fullBleedFirstChild;

  @override
  Widget build(BuildContext context) => ListView(
        padding: fullBleedFirstChild
            ? const EdgeInsets.only(bottom: 124)
            : const EdgeInsets.fromLTRB(18, 8, 18, 124),
        physics: const AlwaysScrollableScrollPhysics(),
        children: fullBleedFirstChild && children.isNotEmpty
            ? [
                children.first,
                for (final item in children.skip(1))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: item,
                  ),
              ]
            : children,
      );
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
  const Resource({super.key,required this.load,required this.builder,this.identity,this.embedded=false});
  final Future<dynamic> Function() load;final Widget Function(dynamic,VoidCallback) builder;final Object? identity;final bool embedded;
  @override State<Resource> createState()=>_ResourceState();
}
class _ResourceState extends State<Resource>{
  late Future<dynamic> future;
  @override void initState(){super.initState();future=widget.load();}
  @override void didUpdateWidget(covariant Resource old){super.didUpdateWidget(old);if(old.identity!=widget.identity)future=widget.load();}
  void refresh(){setState(()=>future=widget.load());}
  @override Widget build(BuildContext context)=>FutureBuilder<dynamic>(future:future,builder:(c,s){
    if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
    if(s.hasError){
      final error=Empty(text:failureText(context,s.error!),icon:Icons.cloud_off_outlined,
        action:OutlinedButton.icon(onPressed:refresh,icon:const Icon(Icons.refresh),label:Text(context.tr('إعادة المحاولة','Retry'))));
      return widget.embedded?error:PageBody(children:[error]);
    }
    if(widget.embedded)return widget.builder(s.data,refresh);
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
  const RecordTile(this.data,{super.key,this.onTap,this.icon=Icons.description_outlined,this.subtitle,this.trailing,this.imageUrls=const []});
  final Json data;final VoidCallback? onTap;final IconData icon;final String? subtitle;final List<String> imageUrls;final Widget? trailing;
  @override Widget build(BuildContext context){final status=str(data['status']??payload(data)['status']);return Padding(padding:const EdgeInsets.only(bottom:10),child:Panel(onTap:onTap,child:Row(children:[
    ProductThumbnail(urls:imageUrls,size:imageUrls.isEmpty?44:54,icon:icon),const SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(titleOf(data),style:Theme.of(context).textTheme.titleMedium),
      if(subtitle?.isNotEmpty==true)Text(subtitle!,maxLines:2,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.bodySmall),if(status.isNotEmpty)...[const SizedBox(height:4),StatusTag(status)]])),
    if(trailing!=null)trailing!
    else if(onTap!=null)Icon(Directionality.of(context)==TextDirection.rtl?Icons.chevron_left:Icons.chevron_right,size:21),
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
  @override Widget build(BuildContext context) {
    final visible=(fields??data.keys.where(words.containsKey))
        .where((key)=>data[key]!=null&&data[key] is! Map&&data[key] is! List)
        .toList();
    if(visible.isEmpty)return const SizedBox.shrink();
    return Panel(child:Column(children:[
      for(var i=0;i<visible.length;i++) ...[
        if(i>0)const Divider(height:13),
        Fact(visible[i],data[visible[i]]),
      ],
    ]));
  }
}
class RecordDetails extends StatelessWidget{
  const RecordDetails(this.data,{super.key});final Json data;
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[ItemFacts(data),
    for(final key in ['lines','items','batches'])if(maps(data[key]).isNotEmpty)...[
      Heading(word(context,key)),for(final row in maps(data[key]))Padding(padding:const EdgeInsets.only(bottom:10),child:ItemFacts(row))],
  ]);
}
class ItemFacts extends StatelessWidget {
  const ItemFacts(this.data, {super.key});
  final Json data;

  @override
  Widget build(BuildContext context) {
    final id = numId(data['productVariantId']);
    if (id <= 0) return Facts(data);
    final images = productImages(data);
    Widget row(List<String> thumbnails) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductThumbnail(urls: thumbnails, size: 44),
        const SizedBox(width: 8),
        Expanded(child: Facts(data)),
      ],
    );
    if (images.isNotEmpty) return row(images);
    return FutureBuilder<Json>(
      future: context.app.variant(id),
      builder: (context, snapshot) => row(productImages(snapshot.data ?? const {})),
    );
  }
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
