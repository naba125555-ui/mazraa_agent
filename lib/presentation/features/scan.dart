import 'package:flutter/material.dart';
import '../../domain/models.dart';
import '../navigation.dart';
import '../shared/scanner.dart';
import '../shared/scope.dart';
import '../shared/widgets.dart';

class ProductScanPage extends StatefulWidget{
  const ProductScanPage({super.key});
  @override State<ProductScanPage> createState()=>_ProductScanPageState();
}
class _ProductScanPageState extends State<ProductScanPage>{
  final code=TextEditingController();Json? match;bool busy=false;Object? error;
  @override void dispose(){code.dispose();super.dispose();}
  Future<void> resolve()async{
    if(code.text.trim().isEmpty)return;setState((){busy=true;error=null;match=null;});
    try{final result=obj(await context.app.read('/api/products/resolve',query:{'code':code.text.trim()}));if(mounted)setState(()=>match=result);}
    catch(e){if(mounted)setState(()=>error=e);}finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>PageBody(children:[
    Panel(child:Column(children:[Icon(Icons.qr_code_scanner,size:76,color:Theme.of(context).colorScheme.primary),const SizedBox(height:16),
      Text(context.tr('امسح باركود المنتج أو QR أو الرقم التسلسلي','Scan a product barcode, QR or serial'),textAlign:TextAlign.center),const SizedBox(height:16),
      FilledButton.icon(onPressed:busy?null:()async{final value=await scanCode(context);if(value==null)return;code.text=value;await resolve();},icon:const Icon(Icons.photo_camera_outlined),label:Text(context.tr('فتح الماسح','Open scanner')))])),
    const SizedBox(height:18),TextField(controller:code,textDirection:TextDirection.ltr,decoration:InputDecoration(labelText:context.tr('الرمز','Code'))),const SizedBox(height:14),
    BusyButton(label:context.tr('البحث عن المنتج','Find product'),run:resolve),if(busy)const LinearProgressIndicator(),
    if(error!=null)...[const SizedBox(height:14),Notice(failureText(context,error!),error:true)],
    if(match!=null)...[Heading(context.tr('النتيجة المطابقة','Matched result')),Facts(obj(match!['product'])),
      if(match!['variantId']!=null)FilledButton(onPressed:()=>context.open('T04',id:numId(match!['variantId'])),child:Text(context.tr('عرض الصنف','View variant')))
      else Resource(load:()=>context.app.read('/api/product-variants'),builder:(data,refresh)=>Column(children:[
        for(final variant in rows(data).where((v)=>v['productId']==match!['productId']))RecordTile(variant,onTap:()=>context.open('T04',id:numId(variant['id']))) ]))],
  ]);
}
