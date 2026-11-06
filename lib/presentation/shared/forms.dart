import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../application/workflows.dart';
import '../../domain/models.dart';
import '../navigation.dart';
import 'labels.dart';
import 'scope.dart';
import 'widgets.dart';
import 'scanner.dart';

Future<Json?> openOperation(BuildContext context,String key,{int? id,Json seed=const {},Json initial=const {}})=>
  Navigator.of(context).push<Json>(MaterialPageRoute(builder:(_)=>OperationPage(operation:operations[key]!,id:id,seed:seed,initial:initial)));

class OperationPage extends StatefulWidget{
  const OperationPage({super.key,required this.operation,this.id,this.seed=const {},this.initial=const {},this.embedded=false});
  final Operation operation;final int? id;final Json seed,initial;final bool embedded;
  @override State<OperationPage> createState()=>_OperationPageState();
}
class _OperationPageState extends State<OperationPage>{
  final form=GlobalKey<FormState>();late Json values;bool busy=false,review=false;Object? error;
  @override void initState(){super.initState();values={for(final f in widget.operation.fields)f.key:f.initial,...widget.initial};}
  Future<void> submit()async{
    if(!form.currentState!.validate())return;form.currentState!.save();
    if(widget.operation.fields.any((f)=>f.kind==InputKind.boolean&&f.key.startsWith('items')&&values[f.key]!=true)){
      toast(context,context.tr('يجب توثيق التحقق الفعلي أولًا.','Confirm the physical verification first.'));return;
    }
    if(!review){setState(()=>review=true);return;}
    final app=context.app,op=widget.operation;
    if(op.doctor&&!app.access.doctor||op.cap!=0&&!app.allows(op.cap))return;
    if(op.path.contains('{id}')&&(widget.id??0)<=0)throw const Failure(422,'');
    setState((){busy=true;error=null;});
    try{
      final body=prepareBody(op,values,widget.seed,app.grantId,app.repo.session?.userId);
      final result=obj(await app.execute(op.path.replaceAll('{id}','${widget.id}'),body,method:op.method,title:app.tr(op.ar,op.en)));
      if(!mounted)return;
      final open=NavScope.of(context);
      if(op.key=='sale'){app.basket.clear();app.sale={};}
      toast(context,context.tr('تمت العملية بنجاح','Operation confirmed'));Navigator.pop(context,result);
      if(op.key=='sale'&&numId(result['documentId'])>0)open('T07',id:numId(result['documentId']));
    }catch(e){if(mounted)setState(()=>error=e);}finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context){final op=widget.operation,app=context.app;
    final allowed=(!op.doctor||app.access.doctor)&&(op.cap==0||app.allows(op.cap));
    final content=Form(key:form,child:PageBody(children:[
      if(!allowed)Notice(context.tr('لا تملك صلاحية هذه العملية في نطاق العمل الحالي.','This operation is unavailable in this work context.'),error:true),
      if(op.version)Padding(padding:const EdgeInsets.only(bottom:14),child:StatusTag(str(widget.seed['status']))),
      if(op.key=='profile')Padding(padding:const EdgeInsets.only(bottom:16),child:BusyButton(icon:Icons.account_circle_outlined,label:context.tr('تحديث الصورة الشخصية','Update profile photo'),run:()async{
        final image=await ImagePicker().pickImage(source:ImageSource.gallery,maxWidth:1000,imageQuality:85);if(image==null)return;
        await app.repo.upload('/api/users/me/avatar',image.name,await image.readAsBytes(),{});await app.refreshAccess();
      })),
      if(review)...[
        Notice(context.tr('راجع البيانات قبل التأكيد. لن تُعتمد العملية إلا بعد تأكيد السيرفر.','Review before confirming. The operation is final only after server confirmation.')),
        const SizedBox(height:14),Facts(values),const SizedBox(height:12),
        for(final field in op.fields.where((f)=>f.kind==InputKind.lines))...[
          Heading(word(context,field.key)),for(final row in maps(values[field.key]))Padding(padding:const EdgeInsets.only(bottom:10),child:Facts(row))],
        TextButton(onPressed:busy?null:()=>setState(()=>review=false),child:Text(context.tr('تعديل البيانات','Edit details'))),
      ],
      Offstage(offstage:review,child:Column(children:[for(final field in op.fields.where((f)=>!(op.key=='visitState'&&widget.seed['status']=='Scheduled'&&['diagnosis','findings','treatment','recommendations'].contains(f.key))))Padding(padding:const EdgeInsets.only(bottom:15),
        child:InputControl(spec:field,value:values[field.key],parentValues:values,onChanged:(v)=>setState(()=>values[field.key]=v)))])),
      if(error!=null)...[Notice(failureText(context,error!),error:true),const SizedBox(height:14)],
      FilledButton.icon(onPressed:!allowed||busy?null:submit,
        icon:busy?const SizedBox.square(dimension:18,child:CircularProgressIndicator(strokeWidth:2)):Icon(review?Icons.verified_outlined:Icons.fact_check_outlined),
        label:Text(review?context.tr('تأكيد العملية','Confirm operation'):context.tr('مراجعة البيانات','Review details'))),
      if(op.key=='note')TextButton.icon(onPressed:busy?null:()async{
        if(!form.currentState!.validate())return;form.currentState!.save();
        await app.saveNote({'caseId':widget.id,...values});if(!context.mounted)return;
        toast(context,context.tr('حُفظت مسودة لمدة 24 ساعة','Draft saved for 24 hours'));Navigator.pop(context);
      },icon:const Icon(Icons.save_outlined),label:Text(context.tr('حفظ مسودة محلية','Save a local draft'))),
    ]));
    return widget.embedded?content:Scaffold(appBar:AppBar(title:Text(app.tr(op.ar,op.en))),body:BotanicalBackground(child:content));
  }
}

class InputControl extends StatelessWidget{
  const InputControl({super.key,required this.spec,required this.value,required this.onChanged,this.parentValues=const {}});
  final InputSpec spec;final Object? value;final ValueChanged<Object?> onChanged;final Json parentValues;
  @override Widget build(BuildContext context){final f=spec;final title=word(context,f.key);
    switch(f.kind){
      case InputKind.boolean:return SwitchListTile.adaptive(contentPadding:const EdgeInsets.symmetric(horizontal:10),
        title:Text(title),value:value==true,onChanged:onChanged);
      case InputKind.choice:return DropdownButtonFormField<String>(initialValue:f.options.contains(value)?str(value):null,
        isExpanded:true,decoration:InputDecoration(labelText:title),items:[for(final item in f.options)DropdownMenuItem(value:item,child:Text(word(context,item)))],
        onChanged:onChanged,validator:(v)=>f.required&&v==null?context.tr('اختر قيمة','Choose a value'):null);
      case InputKind.date:return FormField<String>(initialValue:value as String?,validator:(v)=>f.required&&(v==null||v.isEmpty)?context.tr('اختر التاريخ والوقت','Choose date and time'):null,
        builder:(state)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[OutlinedButton.icon(onPressed:()async{
          final now=DateTime.now(),old=DateTime.tryParse(str(value))?.toLocal();
          final date=await showDatePicker(context:context,initialDate:old??now,firstDate:DateTime(2020),lastDate:DateTime(now.year+5));
          if(date==null||!context.mounted)return;
          final time=await showTimePicker(context:context,initialTime:TimeOfDay.fromDateTime(old??now));if(time==null)return;
          final result=DateTime(date.year,date.month,date.day,time.hour,time.minute).toUtc().toIso8601String();state.didChange(result);onChanged(result);
        },icon:const Icon(Icons.event_outlined),label:Text(value==null?title:'$title · ${display(context,value)}')),
          if(state.hasError)Text(state.errorText!,style:TextStyle(color:Theme.of(context).colorScheme.error))]));
      case InputKind.reference:return FormField<int>(initialValue:value==null?null:numId(value),validator:(v)=>f.required&&(v??0)<=0?context.tr('اختر السجل','Select a record'):null,
        builder:(state)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[OutlinedButton.icon(onPressed:()async{
          final result=await chooseReference(context,f.source!,parentValues:parentValues);if(result==null)return;
          final id=numId(result['id']);state.didChange(id);onChanged(id);
        },icon:const Icon(Icons.search),label:Text(value==null?title:'$title · #$value')),
          if(state.hasError)Text(state.errorText!,style:TextStyle(color:Theme.of(context).colorScheme.error))]));
      case InputKind.lines:return LineItems(mode:f.mode!,value:maps(value),onChanged:onChanged,parentValues:parentValues);
      case InputKind.photos:return PhotoCollector(value:value is List?(value as List).map(numId).toList():[],items:maps(parentValues['items']),onChanged:onChanged);
      default:return TextFormField(key:ValueKey('${f.key}:${f.key=='code'||f.key=='accessCode'?value:''}'),initialValue:value==null?'':str(value),decoration:InputDecoration(labelText:title,
          suffixText:f.required?null:context.tr('اختياري','Optional'),suffixIcon:f.key=='code'||f.key=='accessCode'?IconButton(icon:const Icon(Icons.qr_code_scanner),onPressed:()async{final code=await scanCode(context);if(code!=null)onChanged(code);}):null),
        obscureText:f.key.toLowerCase().contains('password'),autocorrect:!f.key.toLowerCase().contains('password'),enableSuggestions:!f.key.toLowerCase().contains('password'),
        maxLines:f.kind==InputKind.longText?4:1,maxLength:f.kind==InputKind.longText?4000:200,
        textDirection:[InputKind.integer,InputKind.number].contains(f.kind)?TextDirection.ltr:null,
        keyboardType:f.kind==InputKind.integer?TextInputType.number:f.kind==InputKind.number?const TextInputType.numberWithOptions(decimal:true,signed:true):TextInputType.multiline,
        validator:(text){final t=(text??'').trim();if(f.required&&t.isEmpty)return context.tr('هذا الحقل مطلوب','This field is required');
          if(f.key=='newPassword'&&t.length<8)return context.tr('ثمانية أحرف على الأقل','At least eight characters');
          if(f.key=='email'&&!t.contains('@'))return context.tr('أدخل بريدًا صالحًا','Enter a valid email');
          if(t.isNotEmpty&&f.kind==InputKind.integer&&int.tryParse(normalizeNumber(t))==null)return context.tr('أدخل رقمًا صحيحًا','Enter a whole number');
          if(t.isNotEmpty&&f.kind==InputKind.number&&double.tryParse(normalizeNumber(t))==null)return context.tr('أدخل رقمًا صالحًا','Enter a valid number');return null;},
        onSaved:(text){final t=(text??'').trim();onChanged(t.isEmpty?null:f.kind==InputKind.integer?int.parse(normalizeNumber(t)):
          f.kind==InputKind.number?double.parse(normalizeNumber(t)):t);},
        onChanged:(text){if((f.kind==InputKind.text||f.kind==InputKind.longText)&&f.key!='code'&&f.key!='accessCode')onChanged(text);});
    }
  }
}
String normalizeNumber(String value){const arabic='٠١٢٣٤٥٦٧٨٩',persian='۰۱۲۳۴۵۶۷۸۹';
  for(var i=0;i<10;i++){value=value.replaceAll(arabic[i],'$i').replaceAll(persian[i],'$i');}return value.replaceAll('٫','.');}

Future<Json?> chooseReference(BuildContext context,String source,{Json parentValues=const {}})=>showModalBottomSheet<Json>(context:context,
  isScrollControlled:true,useSafeArea:true,builder:(_)=>FractionallySizedBox(heightFactor:.88,child:ReferencePicker(source:source,parentValues:parentValues)));
class ReferencePicker extends StatefulWidget{
  const ReferencePicker({super.key,required this.source,this.parentValues=const {}});final String source;final Json parentValues;
  @override State<ReferencePicker> createState()=>_ReferencePickerState();
}
class _ReferencePickerState extends State<ReferencePicker>{
  String search='';
  Future<dynamic> load()async{final app=context.app;
    switch(widget.source){
      case 'products':return app.read('/api/product-variants');
      case 'suppliers':return app.read('/api/Suppliers');
      case 'customers':return app.read('/api/Users/customers');
      case 'warehouses':return app.read('/api/Warehouses');
      case 'animals':return app.read('/api/Animals');
      case 'documents':return app.all('/api/agent/commerce/documents',query:app.scoped());
      case 'originalItems':return obj(await app.record('document',numId(widget.parentValues['originalDocumentId'])))['items'];
      case 'batches':
        final stock=await app.all('/api/agent/commerce/inventory',query:app.scoped(),pageSize:100);
        return [for(final item in stock)for(final b in maps(item['batches'])){...b,'name':'${b['batchNumber']} · #${item['productVariantId']}','productVariantId':item['productVariantId']}];
      default:return [];
    }
  }
  @override Widget build(BuildContext context)=>Column(children:[Padding(padding:const EdgeInsets.all(16),child:TextField(
    decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:context.tr('بحث بالاسم أو الرقم','Search name or reference')),onChanged:(v)=>setState(()=>search=v.toLowerCase()))),
    Expanded(child:Resource(load:load,builder:(data,refresh){final list=rows(data).where((r)=>'${titleOf(r)} ${r['id']} ${r['sku']}'.toLowerCase().contains(search)).toList();
      return PageBody(children:list.isEmpty?[const Empty()]:[for(final row in list)RecordTile(row,onTap:()=>Navigator.pop(context,row),
        subtitle:str(row['sku']??row['email']??row['phone']))]);}))]);
}

class LineItems extends StatefulWidget{
  const LineItems({super.key,required this.mode,required this.value,required this.onChanged,this.parentValues=const {}});
  final String mode;final List<Json> value;final ValueChanged<Object?> onChanged;final Json parentValues;
  @override State<LineItems> createState()=>_LineItemsState();
}
class _LineItemsState extends State<LineItems>{
  List<InputSpec> get fields=>switch(widget.mode){
    'stock'=>[const InputSpec('batchId',kind:InputKind.reference,source:'batches'),const InputSpec('quantity',kind:InputKind.number)],
    'count'=>[const InputSpec('batchId',kind:InputKind.reference,source:'batches'),const InputSpec('counted',kind:InputKind.number)],
    'prescription'=>[const InputSpec('productVariantId',kind:InputKind.reference,source:'products'),const InputSpec('quantity',kind:InputKind.number),const InputSpec('instructions',kind:InputKind.longText)],
    'purchase'=>[const InputSpec('productVariantId',kind:InputKind.reference,source:'products'),const InputSpec('quantity',kind:InputKind.number),
      const InputSpec('unitCost',kind:InputKind.number),const InputSpec('batchNumber'),const InputSpec('expiryDate',kind:InputKind.date,required:false)],
    'return'=>[const InputSpec('originalItemId',kind:InputKind.reference,source:'originalItems'),const InputSpec('quantity',kind:InputKind.number)],
    'auction'=>[const InputSpec('productVariantId',kind:InputKind.reference,source:'products',required:false),const InputSpec('animalId',kind:InputKind.reference,source:'animals',required:false),
      const InputSpec('startPrice',kind:InputKind.number),const InputSpec('reservePrice',kind:InputKind.number,required:false),const InputSpec('minBidIncrement',kind:InputKind.number)],
    _=>[const InputSpec('productVariantId',kind:InputKind.reference,source:'products'),const InputSpec('quantity',kind:InputKind.number)],
  };
  Future<void> edit([int? index])async{
    final key=GlobalKey<FormState>(),values=<String,dynamic>{...?indexValue(index)};
    final result=await showModalBottomSheet<Json>(context:context,isScrollControlled:true,useSafeArea:true,builder:(c)=>StatefulBuilder(builder:(c,setModal)=>
      Padding(padding:EdgeInsets.fromLTRB(18,0,18,MediaQuery.viewInsetsOf(c).bottom+24),child:SingleChildScrollView(child:Form(key:key,child:Column(mainAxisSize:MainAxisSize.min,children:[
        Heading(c.tr('تفاصيل البند','Line details')),for(final field in fields)Padding(padding:const EdgeInsets.only(bottom:13),child:InputControl(
          spec:field,value:values[field.key],parentValues:widget.parentValues,onChanged:(v)=>setModal(()=>values[field.key]=v))),
        FilledButton(onPressed:()async{
          if(!key.currentState!.validate())return;key.currentState!.save();
          if(widget.mode=='auction'&&((values['animalId']==null)==(values['productVariantId']==null))){toast(c,c.tr('اختر حيوانًا أو منتجًا واحدًا للبند.','Choose exactly one animal or product.'));return;}
          if(widget.mode=='stock'){
            final stock=await context.app.all('/api/agent/commerce/inventory',query:context.app.scoped(),pageSize:100);
            final item=stock.where((s)=>maps(s['batches']).any((b)=>b['id']==values['batchId'])).firstOrNull;
            if(item==null)return;values['productVariantId']=item['productVariantId'];
          }
          if(c.mounted)Navigator.pop(c,values);
        },child:Text(c.tr('حفظ البند','Save line'))),
      ]))))));
    if(result==null||!mounted)return;final updated=widget.value.map((e)=>Map<String,dynamic>.from(e)).toList();
    if(index==null){updated.add(result);}else{updated[index]=result;}widget.onChanged(updated);
  }
  Json? indexValue(int? index)=>index==null?null:widget.value[index];
  @override Widget build(BuildContext context)=>FormField<List<Json>>(initialValue:widget.value,
    validator:(_)=>widget.value.isEmpty?context.tr('أضف بندًا واحدًا على الأقل','Add at least one line'):null,builder:(state)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Heading(context.tr('البنود والكميات','Items and quantities')),
      for(var i=0;i<widget.value.length;i++)Padding(padding:const EdgeInsets.only(bottom:10),child:Panel(child:Column(children:[
        Row(children:[Expanded(child:Text('#${i+1}')),IconButton(onPressed:()=>edit(i),icon:const Icon(Icons.edit_outlined)),
          IconButton(onPressed:(){final updated=[...widget.value]..removeAt(i);widget.onChanged(updated);},icon:const Icon(Icons.delete_outline))]),
        for(final e in widget.value[i].entries)Fact(e.key,e.value),
      ]))),
      OutlinedButton.icon(onPressed:()=>edit(),icon:const Icon(Icons.add),label:Text(context.tr('إضافة بند','Add item'))),
      if(state.hasError)Text(state.errorText!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
    ]));
}

class PhotoCollector extends StatefulWidget{
  const PhotoCollector({super.key,required this.value,required this.items,required this.onChanged});
  final List<int> value;final List<Json> items;final ValueChanged<Object?> onChanged;
  @override State<PhotoCollector> createState()=>_PhotoCollectorState();
}
class _PhotoCollectorState extends State<PhotoCollector>{
  bool uploading=false;
  Future<void> capture(ImageSource source)async{
    if(widget.items.isEmpty){toast(context,context.tr('أضف المعروض أولًا لربط الصورة به.','Add a lot before uploading its photo.'));return;}
    final lot=await showModalBottomSheet<Json>(context:context,builder:(c)=>ListView(shrinkWrap:true,children:[
      for(final item in widget.items)ListTile(title:Text('#${item['productVariantId']??item['animalId']}'),
        leading:Icon(item['animalId']==null?Icons.inventory_2_outlined:Icons.pets_outlined),onTap:()=>Navigator.pop(c,item))]));
    if(lot==null)return;
    final image=await ImagePicker().pickImage(source:source,maxWidth:1600,imageQuality:82);if(image==null||!mounted)return;
    setState(()=>uploading=true);
    try{
      final result=obj(await context.app.repo.upload('/api/Media/upload',image.name,await image.readAsBytes(),{
        'kind':'Image','type':lot['animalId']==null?'ProductItem':'Animal','entityId':lot['animalId']??lot['productVariantId']}));
      final id=numId(result['id']);if(id<=0)throw const Failure(422,'');
      widget.onChanged([...widget.value,id]);
    }catch(e){if(mounted)toast(context,failureText(context,e));}finally{if(mounted)setState(()=>uploading=false);}
  }
  @override Widget build(BuildContext context)=>FormField<List<int>>(validator:(_)=>widget.value.isEmpty?context.tr('أضف صورة للمعروض','Add a lot photo'):null,
    builder:(state)=>Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Heading(context.tr('صور المعروض','Lot photography')),
      if(uploading)const LinearProgressIndicator(),Wrap(spacing:8,children:[for(final id in widget.value)InputChip(label:Text('#$id'),avatar:const Icon(Icons.image_outlined),
        onDeleted:(){widget.onChanged([...widget.value]..remove(id));})]),
      Wrap(spacing:10,children:[OutlinedButton.icon(onPressed:uploading?null:()=>capture(ImageSource.camera),icon:const Icon(Icons.photo_camera_outlined),label:Text(context.tr('تصوير','Camera'))),
        OutlinedButton.icon(onPressed:uploading?null:()=>capture(ImageSource.gallery),icon:const Icon(Icons.photo_library_outlined),label:Text(context.tr('المعرض','Gallery')))]),
      if(state.hasError)Text(state.errorText!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
    ])));
}
