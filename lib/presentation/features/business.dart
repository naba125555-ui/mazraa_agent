import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../application/workflows.dart';
import '../../domain/models.dart';
import '../../domain/screens.dart';
import '../navigation.dart';
import '../shared/charts.dart';
import '../shared/forms.dart';
import '../shared/labels.dart';
import '../shared/scope.dart';
import '../shared/widgets.dart';

const listBindings=<String,(String,String)>{
  'I01':('/api/agent/commerce/inventory','I02'),'I06':('/api/agent/commerce/transfers','I08'),
  'T06':('/api/agent/commerce/documents','T07'),'T10':('/api/Suppliers','T10'),
  'T11':('/api/agent/commerce/documents','T07'),'T13':('/api/agent/procurement','T13'),
  'P01':('/api/agent/pickup/points','P02'),'P02':('/api/agent/pickup/requests','P03'),
  'G01':('/api/agent/marketplace/proposals','G03'),
};
class BusinessPage extends StatelessWidget{
  const BusinessPage(this.screen,{super.key,this.id,this.seed=const {}});final String screen;final int? id;final Json seed;
  @override Widget build(BuildContext context){final app=context.app;
    if(screen=='T01')return const BusinessHub();
    if(screen=='T02')return const PointOfSale();
    if(screen=='N08')return const BusinessInsights();
    if(screen=='N05')return const AccountStatement();
    if(screen=='N06')return _RemoteList('/api/agent/finance/journals',query:app.scoped());
    if(screen=='I05')return const StockAlerts();
    if(screen=='I10')return _RemoteList('/api/agent/mobile/changes',query:const {},arrayKey:'changes',filter:(r)=>r['kind']=='StockCount');
    if(screen=='G02')return OperationPage(embedded:true,operation:operations['proposal']!);
    if(screen=='I09')return OperationPage(embedded:true,operation:operations['stockCount']!);
    if(screen=='I07')return PageBody(children:[
      Notice(context.tr('اطلب تغذية من مخزن مصدر، أو أرسل دفعات من مخزنك إلى مخزن آخر ضمن الفرع.','Request stock from a source warehouse, or dispatch your batches to another authorized warehouse.')),
      const SizedBox(height:16),BusyButton(label:context.tr('طلب تغذية مخزون','Request replenishment'),run:()async{await openOperation(context,'supply');}),
      const SizedBox(height:12),BusyButton(label:context.tr('تحويل من مخزني','Dispatch from my warehouse'),run:()async{await openOperation(context,'transfer');}),
      Heading(context.tr('طلبات التغذية','Stock requests')),
      _EmbeddedRecords(load:()=>app.all('/api/agent/supply/requests',query:app.scoped())),
    ]);
    if(screen=='T12')return OperationPage(embedded:true,operation:operations['procurement']!);
    if(screen=='T08'||screen=='T14')return OperationPage(embedded:true,operation:operations['return']!,initial:id==null?{}:{'originalDocumentId':id});
    if(screen=='T05')return OperationPage(embedded:true,operation:operations['sale']!,initial:{
      ...app.sale,'lines':app.basket.map((l)=>{for(final k in ['productVariantId','batchId','quantity'])k:l[k]}).toList(),
      'paidAmount':app.basket.fold(0.0,(s,l)=>s+decimal(l['quantity'])*decimal(l['unitPrice'])),'paymentMethod':'Cash'});
    if(screen=='A02'||screen=='A03'||screen=='A04')return AuctionWizard(screen:screen);
    if(screen=='A01')return Resource(identity:app.revision,load:()=>app.read('/api/agent/marketplace/auctions',query:app.scoped()),builder:(data,refresh)=>PageBody(children:[
      FilledButton.icon(onPressed:()=>context.open('A02'),icon:const Icon(Icons.add),label:Text(context.tr('إنشاء مزاد','Create auction'))),const SizedBox(height:16),
      if(maps(obj(data)['auctions']).isEmpty)const Empty(),for(final a in maps(obj(data)['auctions']))RecordTile(a,icon:Icons.gavel_outlined,onTap:()=>context.open('A05',id:numId(a['id']))),
    ]));
    if(['N01','N02','N03','N04'].contains(screen))return Resource(identity:app.revision,load:()=>app.read('/api/agent/operations/cashbox',query:app.scoped()),builder:(data,refresh){
      final box=obj(data),shifts=maps(box['shifts']),active=shifts.where((r)=>r['status']=='Active').firstOrNull;
      if(screen=='N04'){
        final shift=id==null?active:shifts.where((s)=>numId(s['id'])==id).firstOrNull;
        if(shift==null)return PageBody(children:[Empty(text:context.tr('لا توجد وردية مفتوحة','No active shift'))]);
        return OperationPage(embedded:true,operation:operations['closeShift']!,id:numId(shift['id']),seed:shift);
      }
      return PageBody(children:[Facts(box,fields:['name','currencyCode','currentBalance','openingBalance']),
        if(screen=='N01'||screen=='N03')...[
          Heading(context.tr('الوردية النقدية','Cash shift')),
          if(active==null)BusyButton(label:context.tr('فتح وردية','Open shift'),run:()async{await openOperation(context,'openShift');refresh();})
          else... [Facts(payload(active)),const SizedBox(height:12),FilledButton(onPressed:()=>context.open('N04',id:numId(active['id'])),child:Text(context.tr('مطابقة وإقفال الوردية','Reconcile and close shift')))],
          Heading(context.tr('الورديات السابقة','Previous shifts')),for(final shift in shifts)RecordTile(shift,onTap:()=>context.open('N04',id:numId(shift['id']))),
        ],
        if(screen=='N01')... [const SizedBox(height:12),OutlinedButton(onPressed:()=>context.open('N02'),child:Text(context.tr('عرض الحركات','View transactions')))],
        if(screen=='N02')... [Heading(context.tr('حركات الصندوق','Cash transactions')),for(final t in maps(box['transactions']))Padding(padding:const EdgeInsets.only(bottom:10),child:Facts(t))],
      ]);
    });
    if(screen=='T09')return PageBody(children:[
      FilledButton.icon(onPressed:()=>openOperation(context,'quote'),icon:const Icon(Icons.add),label:Text(context.tr('عرض سعر جديد','New quotation'))),
      Heading(context.tr('عروضي','My quotations')),
      _EmbeddedRecords(load:()async{
        final changes=maps(obj(await app.read('/api/agent/mobile/changes'))['changes']).where((v)=>v['kind']=='SaleQuote');
        return Future.wait(changes.map((c)=>app.read('/api/agent/commercial/quotes/${c['id']}')));
      }),
    ]);
    if(listBindings.containsKey(screen)&&!(screen=='T13'&&id!=null)){
      final binding=listBindings[screen]!;
      return Resource(identity:'$screen:${app.revision}',load:()=>binding.$1.startsWith('/api/agent/')?app.all(binding.$1,query:app.scoped(),pageSize:screen=='I01'?100:50):app.read(binding.$1),
        builder:(data,refresh){var list=rows(data);
          if(screen=='T06')list=list.where((r)=>str(r['type']).contains('Sales')).toList();
          if(screen=='T11')list=list.where((r)=>str(r['type']).contains('Purchase')).toList();
          if(screen=='P01')list=list.where((r)=>numId(r['warehouseId'])==app.grant?.warehouse).toList();
          return PageBody(children:[
            if(screen=='I01')_Shortcuts(const ['I05','I06','I07','I09']),
            if(screen=='T06')_Shortcuts(const ['T02','T08','T09']),
            if(screen=='T11')_Shortcuts(const ['T12','T13','T14']),
            if(screen=='G01')FilledButton.icon(onPressed:()=>context.open('G02'),icon:const Icon(Icons.add),label:Text(context.tr('اقتراح جديد','New proposal'))),
            const SizedBox(height:14),if(list.isEmpty)const Empty(),for(final row in list)RecordTile(row,onTap:(){
              if(screen=='T10'){showDialog<void>(context:context,builder:(c)=>AlertDialog(title:Text(titleOf(row)),content:Facts(row)));return;}
              context.open(binding.$2,id:numId(row['id']),seed:row);
            },subtitle:screen=='I01'?'${context.tr('المتاح','Available')}: ${display(context,row['availableQuantity'])}':null),
          ]);
        });
    }
    if(id==null)return _RecordSelector(target:screen);
    final kind=screen.startsWith('I')?'stock':screen.startsWith('P')?'pickup':screen.startsWith('A')?'auction':screen.startsWith('G')?'proposal':
      screen=='T13'?'procurement':screen=='I08'?'transfer':'document';
    final actualKind=screen=='I08'?'transfer':screen=='T04'?'variant':kind;
    return Resource(identity:'$screen:$id:${app.revision}',load:()=>actualKind=='variant'?app.read('/api/product-variants/$id'):app.record(actualKind,id!,fresh:true),builder:(data,refresh){
      final row=obj(data),d=payload(row);
      if(screen=='I08'||screen=='T13')return OperationPage(embedded:true,operation:operations[screen=='I08'?'receiveTransfer':'receivePurchase']!,id:id,seed:row);
      if(screen=='N07')return OperationPage(embedded:true,operation:operations['settle']!,id:id,seed:row);
      if(screen=='I04')return _RemoteList('/api/Inventory/$id/transactions');
      if(screen=='I02'||screen=='I03'||screen=='T04')return PageBody(children:[Facts(row),
        Heading(context.tr('الدفعات والصلاحية','Batches and expiry')),
        for(final batch in maps(row['batches']))Padding(padding:const EdgeInsets.only(bottom:12),child:Facts(batch)),
        if(screen=='I02')...[_InlineLink('I03',id!),_InlineLink('I04',id!)],
        if(app.allows(1))BusyButton(label:context.tr('حجز دفعة للمراجعة','Quarantine a batch'),run:()async{await openOperation(context,'hold');refresh();}),
      ]);
      if(screen=='T07')return PageBody(children:[Panel(child:Column(children:[const BrandLogo(size:54),const SizedBox(height:14),Text(str(row['documentNumber']),style:Theme.of(context).textTheme.titleLarge),StatusTag(row['isPosted']==true?'Completed':'Draft')])),
        const SizedBox(height:14),Facts(row),Heading(context.tr('الأصناف','Invoice items')),for(final line in maps(row['items']))Padding(padding:const EdgeInsets.only(bottom:10),child:Facts(line)),
        BusyButton(icon:Icons.share_outlined,label:context.tr('مشاركة الإيصال','Share receipt'),run:()async{
          final text='${row['documentNumber']}\n${word(context,str(row['type']))}\n${context.tr('الإجمالي','Total')}: ${row['totalAmount']} ${row['currency']}\n${context.tr('المدفوع','Paid')}: ${row['paidAmount']}';
          await SharePlus.instance.share(ShareParams(text:text));}),
        const SizedBox(height:12),OutlinedButton(onPressed:()=>context.open(str(row['type']).contains('Purchase')?'T14':'T08',id:id),child:Text(context.tr('طلب مرتجع مرتبط بالفاتورة','Request return against this invoice'))),
        if(app.allows(32))_InlineLink('N07',id!),
      ]);
      if(screen.startsWith('P')){
        final op={'P04':'custody','P05':'shelf','P06':'handover','P07':'pickupIssue'}[screen];
        if(op!=null)return OperationPage(embedded:true,operation:operations[op]!,id:id,seed:row);
        return PageBody(children:[Facts(row),Heading(context.tr('مراحل الاستلام','Pickup stages')),
          for(final step in ['P04','P05','P06','P07'])if(app.canOpen(screenById(step)))_InlineLink(step,id!),
          const SizedBox(height:12),BusyButton(label:context.tr('إنشاء رمز للسائق','Generate driver handoff code'),run:()async{
            final result=await openOperation(context,'driverCode',id:id,seed:row);if(result==null||!context.mounted)return;
            await showDialog<void>(context:context,builder:(c)=>AlertDialog(content:CodeCard(result)));refresh();}),
        ]);
      }
      if(screen.startsWith('A')){
        if(screen=='A09')return Resource(load:()=>app.read('/api/identifiers/auctions/$id'),builder:(label,r)=>PageBody(children:[CodeCard(obj(label))]));
        if(screen=='A08')return _RemoteList('/api/agent/marketplace/auctions/$id/fulfillment',onTap:(order)=>openOperation(context,'auctionHandover',id:numId(order['orderId']),seed:order));
        if(screen=='A07')return PageBody(children:[Facts(row),Heading(context.tr('المعروض والمزايدات','Lots and bids')),
          for(final lot in maps(row['items']))... [Facts(lot),_EmbeddedRecords(load:()=>app.read('/api/AuctionBids/auction-item/${lot['id']}'))]]);
        final review=obj(row['review']);
        return PageBody(children:[Facts(row),Heading(context.tr('حالة المراجعة','Review status')),Facts(payload(review)),StatusTag(str(review['status'])),
          Heading(context.tr('المعروض','Lots')),for(final lot in maps(row['items']))Padding(padding:const EdgeInsets.only(bottom:10),child:Facts(lot)),
          if(['Draft','NeedsChanges','Rejected'].contains(review['status']))BusyButton(label:context.tr('إرسال للمراجعة','Submit for review'),run:()async{await openOperation(context,'submitAuction',id:id,seed:row);refresh();}),
          if(review['status']=='Approved')BusyButton(label:context.tr('نشر المزاد','Publish auction'),run:()async{await openOperation(context,'publishAuction',id:id,seed:row);refresh();}),
          const SizedBox(height:12),_InlineLink('A07',id!),_InlineLink('A08',id!),_InlineLink('A09',id!),
          OutlinedButton(onPressed:()=>openOperation(context,'cancelAuction',id:id,seed:row),child:Text(context.tr('إلغاء المزاد','Cancel auction'))),
        ]);
      }
      if(screen.startsWith('G'))return PageBody(children:[Facts(d),const SizedBox(height:12),StatusTag(str(row['status'])),
        if(screen=='G03')_InlineLink('G04',id!),if(row['status']=='NeedsChanges')... [const SizedBox(height:14),
          BusyButton(label:context.tr('استكمال الاقتراح','Revise proposal'),run:()async{await openOperation(context,'reviseProposal',id:id,seed:row,initial:d);refresh();})],
        if(d['linkedEntityId']!=null)Notice('${context.tr('تم الربط بالسجل','Linked record')} #${d['linkedEntityId']}'),
      ]);
      throw StateError('Unbound business screen $screen');
    });
  }
}
ScreenSpec screenById(String id)=>screen(id);
class _InlineLink extends StatelessWidget{
  const _InlineLink(this.route,this.id);final String route;final int id;
  @override Widget build(BuildContext context){final spec=screenById(route);return RecordTile({'title':context.app.tr(spec.ar,spec.en)},onTap:()=>context.open(route,id:id));}
}
class _Shortcuts extends StatelessWidget{
  const _Shortcuts(this.routes);final List<String> routes;
  @override Widget build(BuildContext context)=>Wrap(spacing:8,runSpacing:8,children:[for(final route in routes)if(context.app.canOpen(screenById(route)))ActionChip(
    label:Text(context.app.tr(screenById(route).ar,screenById(route).en)),onPressed:()=>context.open(route))]);
}
class BusinessHub extends StatelessWidget{
  const BusinessHub({super.key});
  @override Widget build(BuildContext context)=>PageBody(children:[
    Heading(context.tr('إدارة العمل','Business workspace'),icon:Icons.storefront_outlined),
    for(final entry in [('T02',Icons.point_of_sale_outlined),('I01',Icons.inventory_2_outlined),('T06',Icons.receipt_long_outlined),('T09',Icons.request_quote_outlined),
      ('T11',Icons.shopping_bag_outlined),('T12',Icons.add_shopping_cart),('T10',Icons.local_shipping_outlined),('N01',Icons.account_balance_wallet_outlined),
      ('N05',Icons.account_balance_outlined),('N06',Icons.menu_book_outlined),('N08',Icons.bar_chart),('P01',Icons.storefront_outlined),
      ('P02',Icons.move_to_inbox_outlined),('A01',Icons.gavel_outlined),('G01',Icons.lightbulb_outline)])
      if(context.app.canOpen(screenById(entry.$1)))RecordTile({'title':context.app.tr(screenById(entry.$1).ar,screenById(entry.$1).en)},icon:entry.$2,onTap:()=>context.open(entry.$1)),
    if(context.app.access.grants.isEmpty)Notice(context.tr('لا يوجد تفويض تجاري نشط. تواصل مع الإدارة لتحديد نطاقك.','No active business delegation. Contact your administrator to assign a work context.')),
  ]);
}
class _RecordSelector extends StatelessWidget{
  const _RecordSelector({required this.target});final String target;
  @override Widget build(BuildContext context){final app=context.app;
    final binding=target.startsWith('I')?('/api/agent/commerce/inventory',true):target.startsWith('P')?('/api/agent/pickup/requests',true):
      target.startsWith('G')?('/api/agent/marketplace/proposals',false):('/api/agent/commerce/documents',true);
    return Resource(load:()=>app.all(binding.$1,query:binding.$2?app.scoped():null,pageSize:target.startsWith('I')?100:50),builder:(data,refresh)=>PageBody(children:[
      Notice(context.tr('اختر السجل للمتابعة','Choose a record to continue')),const SizedBox(height:14),if(rows(data).isEmpty)const Empty(),
      for(final row in rows(data))RecordTile(row,onTap:()=>context.open(target,id:numId(row['id']),seed:row)),
    ]));}
}
class _RemoteList extends StatelessWidget{
  const _RemoteList(this.path,{this.query,this.arrayKey,this.filter,this.onTap});final String path;final Json? query;final String? arrayKey;
  final bool Function(Json)? filter;final void Function(Json)? onTap;
  @override Widget build(BuildContext context)=>Resource(load:()=>context.app.read(path,query:query),builder:(data,refresh){
    final list=(arrayKey==null?rows(data):maps(obj(data)[arrayKey])).where((r)=>filter?.call(r)??true).toList();
    return PageBody(children:[if(list.isEmpty)const Empty(),for(final row in list)Padding(padding:const EdgeInsets.only(bottom:12),child:onTap==null?Facts(payload(row)):RecordTile(row,onTap:()=>onTap!(row)))]);
  });
}
class _EmbeddedRecords extends StatelessWidget{
  const _EmbeddedRecords({super.key,required this.load});final Future<dynamic> Function() load;
  @override Widget build(BuildContext context)=>Resource(load:load,builder:(data,refresh)=>Column(children:[if(rows(data).isEmpty)const Empty(),
    for(final row in rows(data))Padding(padding:const EdgeInsets.only(bottom:10),child:Facts(payload(row)))]));
}

class CodeCard extends StatelessWidget{
  const CodeCard(this.data,{super.key});final Json data;
  @override Widget build(BuildContext context){final code=str(data['code']??data['token']??data['qrPayload']??data['serialNumber']);
    return Panel(child:Column(mainAxisSize:MainAxisSize.min,children:[if(code.isNotEmpty)Container(color:Colors.white,padding:const EdgeInsets.all(12),child:QrImageView(data:code,size:190)),
      const SizedBox(height:14),SelectableText(code,textAlign:TextAlign.center,textDirection:TextDirection.ltr),if(data['expiresAt']!=null)Fact(context.tr('صالح حتى','Expires at'),data['expiresAt']),
      if(data['shareUrl']!=null||data['url']!=null)TextButton.icon(onPressed:()=>SharePlus.instance.share(ShareParams(text:str(data['shareUrl']??data['url']))),icon:const Icon(Icons.share),label:Text(context.tr('مشاركة الرابط','Share link'))),
    ]));}
}

class PointOfSale extends StatefulWidget{
  const PointOfSale({super.key});
  @override State<PointOfSale> createState()=>_PointOfSaleState();
}
class _PointOfSaleState extends State<PointOfSale>{
  String search='';
  Future<void> add(Json variant,Json stock)async{
    final batches=maps(stock['batches']).where((b){final expiry=DateTime.tryParse(str(b['expiryDate']));
      return decimal(b['quantity'])>0&&(expiry==null||expiry.isAfter(DateTime.now().toUtc()));}).toList();
    final batch=await showModalBottomSheet<Json>(context:context,builder:(c)=>PageBody(children:[
      Heading(c.tr('اختر الدفعة','Choose a batch')),if(batches.isEmpty)const Empty(),for(final b in batches)RecordTile(b,subtitle:'${display(c,b['quantity'])} · ${display(c,b['expiryDate'])}',onTap:()=>Navigator.pop(c,b)),
    ]));
    if(batch==null||!mounted)return;
    final basket=context.app.basket,index=basket.indexWhere((l)=>l['productVariantId']==variant['id']&&l['batchId']==batch['id']);
    setState((){if(index>=0){basket[index]['quantity']=decimal(basket[index]['quantity'])+1;}else{
      basket.add({'productVariantId':variant['id'],'batchId':batch['id'],'quantity':1,'name':titleOf(variant),
        'unitPrice':variant['salePrice']??variant['price'],'batchNumber':batch['batchNumber']});}});
  }
  @override Widget build(BuildContext context){final app=context.app;return Resource(load:()async=>{
    'catalog':await app.read('/api/product-variants'),'stock':await app.all('/api/agent/commerce/inventory',query:app.scoped(),pageSize:100)},builder:(data,refresh){
      final catalog=rows(obj(data)['catalog']),stock=maps(obj(data)['stock']);
      final products=catalog.where((v)=>'${titleOf(v)} ${v['sku']}'.toLowerCase().contains(search)&&stock.any((s)=>s['productVariantId']==v['id']&&decimal(s['availableQuantity'])>0)).toList();
      return PageBody(children:[TextField(decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:context.tr('اسم المنتج أو SKU','Product name or SKU'),
        suffixIcon:IconButton(icon:const Icon(Icons.qr_code_scanner),onPressed:()=>context.open('T03'))),onChanged:(v)=>setState(()=>search=v.toLowerCase())),
        Heading(context.tr('أصناف متاحة في مخزنك','Available in your warehouse')),
        if(products.isEmpty)const Empty(),for(final product in products.take(60))RecordTile(product,icon:Icons.add_shopping_cart,
          subtitle:'${display(context,product['salePrice']??product['price'])} ${app.currency}',onTap:()=>add(product,stock.firstWhere((s)=>s['productVariantId']==product['id']))),
        Heading(context.tr('سلة البيع','Sale cart'),action:TextButton(onPressed:()=>setState(()=>app.basket.clear()),child:Text(context.tr('إفراغ','Clear')))),
        if(app.basket.isEmpty)const Empty(icon:Icons.shopping_cart_outlined),
        for(var i=0;i<app.basket.length;i++)Padding(padding:const EdgeInsets.only(bottom:10),child:Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(str(app.basket[i]['name']),style:Theme.of(context).textTheme.titleMedium),Fact('batchNumber',app.basket[i]['batchNumber']),
          Row(children:[IconButton(onPressed:()=>setState((){final qty=decimal(app.basket[i]['quantity']);if(qty<=1){app.basket.removeAt(i);}else{app.basket[i]['quantity']=qty-1;}}),icon:const Icon(Icons.remove_circle_outline)),
            Text(display(context,app.basket[i]['quantity'])),IconButton(onPressed:()=>setState(()=>app.basket[i]['quantity']=decimal(app.basket[i]['quantity'])+1),icon:const Icon(Icons.add_circle_outline)),
            const Spacer(),Text('${display(context,decimal(app.basket[i]['quantity'])*decimal(app.basket[i]['unitPrice']))} ${app.currency}')]),
        ]))),
        if(app.basket.isNotEmpty)... [Notice(context.tr('تعرض السلة أسعار الكتالوج. تحدد الفاتورة المعتمدة الضرائب والخصومات النهائية.','The cart shows catalog prices. The posted invoice confirms final taxes and discounts.')),
          const SizedBox(height:16),FilledButton.icon(onPressed:()=>context.open('T05'),icon:const Icon(Icons.receipt_long_outlined),label:Text(context.tr('متابعة إلى الدفع','Continue to payment')))],
      ]);
    });}
}
class BusinessInsights extends StatefulWidget{
  const BusinessInsights({super.key});
  @override State<BusinessInsights> createState()=>_BusinessInsightsState();
}
class _BusinessInsightsState extends State<BusinessInsights>{
  int days=30;String? currency;
  @override Widget build(BuildContext context){final app=context.app,c=Theme.of(context).colorScheme;
    return Resource(identity:app.revision,load:()=>app.all('/api/agent/commerce/documents',query:app.scoped()),builder:(data,refresh){
      final all=rows(data),currencies=all.map((d)=>str(d['currency'])).where((v)=>v.isNotEmpty).toSet().toList()..sort();
      final current=currency??(currencies.contains(app.currency)?app.currency:currencies.firstOrNull);
      final cutoff=DateTime.now().toUtc().subtract(Duration(days:days));
      final documents=all.where((d)=>d['isPosted']==true&&d['currency']==current&&(DateTime.tryParse(str(d['postedAt']))?.isAfter(cutoff)??false)).toList();
      double amount(String type)=>documents.where((d)=>d['type']==type).fold(0,(s,d)=>s+decimal(d['totalAmount']));
      final sales=amount('SalesInvoice')-amount('SalesReturn'),purchases=amount('PurchaseInvoice')-amount('PurchaseReturn');
      final daily=<ChartValue>[];
      for(var i=6;i>=0;i--){final date=DateTime.now().subtract(Duration(days:i));final total=documents.where((d){
        final t=DateTime.tryParse(str(d['postedAt']))?.toLocal();return d['type']=='SalesInvoice'&&t!=null&&t.year==date.year&&t.month==date.month&&t.day==date.day;}).fold(0.0,(s,d)=>s+decimal(d['totalAmount']));
        daily.add(ChartValue('${date.day}/${date.month}',total,c.primary));}
      return PageBody(children:[Wrap(spacing:8,runSpacing:8,children:[for(final period in [7,30,90])ChoiceChip(label:Text('${display(context,period)} ${context.tr('يوم','days')}'),selected:days==period,onSelected:(_)=>setState(()=>days=period))]),
        if(currencies.isNotEmpty)DropdownButton<String>(value:current,items:[for(final code in currencies)DropdownMenuItem(value:code,child:Text(code))],onChanged:(v)=>setState(()=>currency=v)),
        Heading(context.tr('صافي الفواتير بعد المرتجعات','Invoices net of returns')),
        BarChartCard(title:context.tr('المبيعات والمشتريات','Sales and purchases'),unit:current??'',values:[
          ChartValue(context.tr('المبيعات','Sales'),sales,c.primary),ChartValue(context.tr('المشتريات','Purchases'),purchases,c.secondary)]),
        const SizedBox(height:16),BarChartCard(title:context.tr('مبيعات آخر سبعة أيام','Sales over the last seven days'),unit:current??'',values:daily),
        const SizedBox(height:16),RingChartCard(title:context.tr('توزيع المستندات','Document mix'),values:[
          for(final type in ['SalesInvoice','PurchaseInvoice','SalesReturn','PurchaseReturn'])ChartValue(word(context,type),documents.where((d)=>d['type']==type).length.toDouble(),
            type=='SalesInvoice'?c.primary:type=='PurchaseInvoice'?c.secondary:type=='SalesReturn'?c.tertiary:c.error)]),
        const SizedBox(height:16),Notice(context.tr('تعتمد الرسوم على الفواتير المرحلة في النطاق والفترة والعملة المحددة.','Charts use posted invoices in the selected work context, period and currency.')),
      ]);
    });}
}
class AccountStatement extends StatefulWidget{
  const AccountStatement({super.key});
  @override State<AccountStatement> createState()=>_AccountStatementState();
}
class _AccountStatementState extends State<AccountStatement>{
  bool supplier=false;Json? party;
  @override Widget build(BuildContext context)=>PageBody(children:[
    SwitchListTile(title:Text(context.tr('حساب مورد','Supplier account')),value:supplier,onChanged:(v)=>setState((){supplier=v;party=null;})),
    OutlinedButton.icon(onPressed:()async{final selected=await chooseReference(context,supplier?'suppliers':'customers');if(selected!=null)setState(()=>party=selected);},
      icon:const Icon(Icons.person_search_outlined),label:Text(party==null?context.tr('اختيار الحساب','Choose account'):titleOf(party!))),
    if(party!=null)... [Heading(context.tr('كشف الحساب','Account statement')),
      _EmbeddedRecords(key:ValueKey('${party!['id']}:$supplier'),load:()=>context.app.read('/api/agent/finance/statements',query:context.app.scoped({'partyId':party!['id'],'supplier':supplier})))],
  ]);
}
class StockAlerts extends StatelessWidget{
  const StockAlerts({super.key});
  @override Widget build(BuildContext context)=>Resource(load:()=>context.app.all('/api/agent/commerce/inventory',query:context.app.scoped(),pageSize:100),builder:(data,refresh){
    final now=DateTime.now().toUtc(),stocks=rows(data);
    final low=stocks.where((s)=>decimal(s['availableQuantity'])<=0).toList();
    final expiring=[for(final s in stocks)for(final b in maps(s['batches']))if(b['expiryDate']!=null&&
      (DateTime.tryParse(str(b['expiryDate']))??DateTime(2100)).isBefore(now.add(const Duration(days:30)))){...b,'stockId':s['id']}];
    return PageBody(children:[Heading(context.tr('دفعات منتهية أو تنتهي خلال 30 يومًا','Expired or expiring within 30 days')),
      if(expiring.isEmpty)const Empty(),for(final b in expiring)RecordTile(b,subtitle:display(context,b['expiryDate']),onTap:()=>context.open('I03',id:numId(b['stockId']))),
      Heading(context.tr('أصناف غير متاحة','Unavailable variants')),for(final s in low)RecordTile(s,onTap:()=>context.open('I02',id:numId(s['id']))),
    ]);
  });
}
class AuctionWizard extends StatefulWidget{
  const AuctionWizard({super.key,required this.screen});final String screen;
  @override State<AuctionWizard> createState()=>_AuctionWizardState();
}
class _AuctionWizardState extends State<AuctionWizard>{
  final form=GlobalKey<FormState>();
  @override Widget build(BuildContext context){final app=context.app,draft=app.auctionDraft;
    final fields=operations['auction']!.fields.where((f)=>widget.screen=='A02'?f.kind!=InputKind.lines&&f.kind!=InputKind.photos:
      widget.screen=='A03'?f.kind==InputKind.lines:f.kind==InputKind.photos).toList();
    return Form(key:form,child:PageBody(children:[
      Padding(padding:const EdgeInsets.only(bottom:20),child:LinearProgressIndicator(value:widget.screen=='A02'?.33:widget.screen=='A03'?.66:1)),
      for(final f in fields)Padding(padding:const EdgeInsets.only(bottom:14),child:InputControl(spec:f,value:draft[f.key],parentValues:draft,onChanged:(v)=>setState(()=>draft[f.key]=v))),
      if(widget.screen!='A04')FilledButton(onPressed:(){if(!form.currentState!.validate())return;form.currentState!.save();context.open(widget.screen=='A02'?'A03':'A04');},child:Text(context.tr('متابعة','Continue')))
      else BusyButton(label:context.tr('مراجعة وحفظ مسودة المزاد','Review and save auction'),run:()async{
        if(!form.currentState!.validate())return;form.currentState!.save();
        final result=await openOperation(context,'auction',initial:draft);if(result==null||!context.mounted)return;
        app.auctionDraft={};context.open('A05',id:numId(result['auctionId']));}),
    ]));}
}
