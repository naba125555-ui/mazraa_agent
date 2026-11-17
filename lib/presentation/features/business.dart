import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../application/workflows.dart';
import '../../domain/models.dart';
import '../../domain/screens.dart';
import '../navigation.dart';
import '../design/screen_design.dart';
import 'home.dart';
import '../shared/charts.dart';
import '../shared/forms.dart';
import '../shared/labels.dart';
import '../shared/paged_records.dart';
import '../shared/scope.dart';
import '../shared/section_banner.dart';
import '../shared/product_thumbnail.dart';
import '../shared/widgets.dart';
import 'clinical.dart';

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
    if(screen=='I10')return Resource(load:app.changes,builder:(data,refresh){
      final counts=rows(data).where((row)=>row['kind']=='StockCount').toList();
      return PageBody(children:[
        Notice(context.tr('تُعتمد فروق الجرد بواسطة مراجع مستقل. تتحدث الحالة من سجل العمليات.','Stock differences require an independent reviewer. Status follows the operation record.')),
        const SizedBox(height:14),
        if(counts.isEmpty)Empty(icon:Icons.difference_outlined,
          text:context.tr('لا توجد فروق جرد مسجّلة في نطاقك.','No count discrepancies are recorded in your work context.')),
        for(final row in counts)
          RecordTile({...row,'title':'${context.tr('جرد المخزون','Stock count')} ${row['id']}'},
            icon:Icons.checklist,subtitle:str(row['updatedAt']).isEmpty?null:display(context,row['updatedAt'])),
      ]);
    });
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
      'paidAmount':null,'paymentMethod':'Cash'});
    if(screen=='A02'||screen=='A03'||screen=='A04')return AuctionWizard(screen:screen);
    if(screen=='A01')return Resource(identity:app.revision,load:()=>app.read('/api/agent/marketplace/auctions',query:app.scoped()),builder:(data,refresh)=>PageBody(children:[
      FilledButton.icon(onPressed:()=>context.open('A02'),icon:const Icon(Icons.add),label:Text(context.tr('إنشاء مزاد','Create auction'))),const SizedBox(height:16),
      if(maps(obj(data)['auctions']).isEmpty)
        Empty(icon:Icons.gavel_outlined,text:context.tr('لا توجد مزادات في نطاق العمل الحالي.','There are no auctions in the current work context.')),
      for(final a in maps(obj(data)['auctions']))RecordTile(a,icon:Icons.gavel_outlined,
        subtitle:a['startAt']==null?null:display(context,a['startAt']),
        onTap:()=>context.open('A05',id:numId(a['id']),seed:a)),
    ]));
    if(['N01','N02','N03','N04'].contains(screen))return Resource(identity:app.revision,load:()=>app.read('/api/agent/operations/cashbox',query:app.scoped()),builder:(data,refresh){
      final box=obj(data),shifts=maps(box['shifts']),active=shifts.where((r)=>r['status']=='Active').firstOrNull;
      if(screen=='N04'){
        final shift=id==null?active:shifts.where((s)=>numId(s['id'])==id).firstOrNull;
        if(shift==null)return PageBody(children:[Empty(text:context.tr('لا توجد وردية مفتوحة','No active shift'))]);
        if(shift['status']!='Active')return PageBody(children:[RecordDetails({...payload(shift),'status':shift['status']})]);
        return OperationPage(
          embedded:true,operation:operations['closeShift']!,id:numId(shift['id']),seed:shift,
          summary:{
            'expectedClosing':payload(shift)['expectedClosing']??box['currentBalance'],
            'currencyCode':box['currencyCode'],
          },
        );
      }
      return PageBody(children:[
        SectionBanner(art:SectionArt.commerce,icon:Icons.account_balance_wallet_outlined,
          title:str(box['name']).isEmpty?context.tr('صندوق الفرع','Branch cashbox'):str(box['name']),
          subtitle:'${context.tr('الرصيد الحالي','Current balance')}  ${display(context,box['currentBalance'])} ${str(box['currencyCode'])}'),
        const SizedBox(height:12),
        Facts(box,fields:['openingBalance','currencyCode']),
        if(screen=='N01'||screen=='N03')...[
          Heading(context.tr('الوردية النقدية','Cash shift')),
          if(active==null)BusyButton(label:context.tr('فتح وردية','Open shift'),run:()async{await openOperation(context,'openShift');refresh();})
          else... [Facts(payload(active)),const SizedBox(height:12),FilledButton(onPressed:()=>context.open('N04',id:numId(active['id'])),child:Text(context.tr('مطابقة وإقفال الوردية','Reconcile and close shift')))],
          if(shifts.any((shift)=>shift['status']!='Active'))Heading(context.tr('الورديات السابقة','Previous shifts')),
          for(final shift in shifts.where((shift)=>shift['status']!='Active'))
            RecordTile({...shift,'title':'${context.tr('وردية','Shift')} #${shift['id']}'},
              subtitle:shift['closedAt']==null?null:display(context,shift['closedAt']),
              icon:Icons.history,onTap:()=>context.open('N04',id:numId(shift['id']),seed:shift)),
        ],
        if(screen=='N01')... [const SizedBox(height:12),OutlinedButton(onPressed:()=>context.open('N02'),child:Text(context.tr('عرض الحركات','View transactions')))],
        if(screen=='N02')... [
          Heading(context.tr('الحركات المسجلة','Recorded transactions')),
          if(maps(box['transactions']).isEmpty)
            Empty(icon:Icons.receipt_long_outlined,text:context.tr('لا توجد حركات مسجلة على هذا الصندوق.','This cashbox has no recorded transactions.')),
          for(final t in maps(box['transactions']))Padding(padding:const EdgeInsets.only(bottom:8),child:Facts(t)),
        ],
      ]);
    });
    if(screen=='T09')return PageBody(children:[
      FilledButton.icon(onPressed:()=>openOperation(context,'quote'),icon:const Icon(Icons.add),label:Text(context.tr('عرض سعر جديد','New quotation'))),
      Heading(context.tr('عروضي','My quotations')),
      _EmbeddedRecords(load:()async{
        final changes=(await app.changes()).where((v)=>v['kind']=='SaleQuote');
        return Future.wait(changes.map((c)=>app.read('/api/agent/commercial/quotes/${c['id']}')));
      }),
    ]);
    if (screen == 'T10') {
      return Resource(
        load: () => app.read('/api/Suppliers'),
        builder: (data, _) => PageBody(children: [
          if (rows(data).isEmpty) const Empty(),
          for (final supplier in rows(data))
            RecordTile(supplier, onTap: () => showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(title: Text(titleOf(supplier)), content: Facts(supplier)),
            )),
        ]),
      );
    }
    if (listBindings.containsKey(screen) && !(screen == 'T13' && id != null)) {
      final binding = listBindings[screen]!;
      return PagedRecords(
        key: ValueKey('$screen:$id:${app.revision}'),
        load: (afterId) => app.page(binding.$1, query: app.scoped(), afterId: afterId),
        pageSize: screen == 'I01' ? 100 : 50,
        include: (row) => switch (screen) {
          'T06' => str(row['type']).contains('Sales'),
          'T11' => str(row['type']).contains('Purchase'),
          'P01' => numId(row['warehouseId']) == app.grant?.warehouse,
          'P02' when id != null => numId(row['pointId']) == id,
          _ => true,
        },
        header: [
          if (screen == 'I01') _Shortcuts(const ['I05','I06','I07','I09','I10']),
          if (screen == 'T06') _Shortcuts(const ['T02','T08','T09']),
          if (screen == 'T11') _Shortcuts(const ['T12','T13','T14']),
          if (screen == 'G01') FilledButton.icon(
            onPressed: () => context.open('G02'), icon: const Icon(Icons.add),
            label: Text(context.tr('اقتراح جديد', 'New proposal')),
          ),
          const SizedBox(height: 14),
        ],
        itemBuilder: (row) {
          final open=()=>context.open(binding.$2,id:numId(row['id']),seed:row);
          if(screen=='I01')return _StockTile(row:row,onTap:open);
          final subtitle = switch (screen) {
            'T06' || 'T11' => '${display(context,row['totalAmount'])} ${str(row['currency'])}',
            'P01' => str(row['address']),
            'P02' => display(context,row['deadline']),
            'G01' => str(payload(row)['description']),
            _ => '',
          };
          final icon=switch(screen){
            'T06'||'T11'=>Icons.receipt_long_outlined,
            'P01'||'P02'=>Icons.local_shipping_outlined,
            'G01'=>Icons.lightbulb_outline,
            _=>Icons.swap_horiz,
          };
          return RecordTile(row,icon:icon,subtitle:subtitle,onTap:open);
        },
      );
    }
    if(id==null)return _RecordSelector(target:screen);
    final kind=screen.startsWith('I')?'stock':screen.startsWith('P')?'pickup':screen.startsWith('A')?'auction':screen.startsWith('G')?'proposal':
      screen=='T13'?'procurement':screen=='I08'?'transfer':'document';
    final actualKind=screen=='I08'?'transfer':screen=='T04'?'variant':kind;
    return Resource(identity:'$screen:$id:${app.revision}',load:()async{
      if(actualKind=='variant')return app.variant(id!);
      final data=await app.record(actualKind,id!,fresh:true);
      if(actualKind!='stock')return data;
      try {
        final variant=await app.variant(numId(data['productVariantId']));
        return {...data,'variant':variant};
      }catch(_){return data;}
    },builder:(data,refresh){
      final row=obj(data),d=payload(row);
      if(screen=='I08'||screen=='T13')return OperationPage(embedded:true,operation:operations[screen=='I08'?'receiveTransfer':'receivePurchase']!,id:id,seed:row);
      if(screen=='N07')return OperationPage(embedded:true,operation:operations['settle']!,id:id,seed:row);
      if(screen=='I04')return _RemoteList('/api/Inventory/$id/transactions');
      if(screen=='I02')return PageBody(children:[
        _StockTile(row:row),
        Heading(context.tr('الرصيد في المخزن','Warehouse balance'),icon:Icons.inventory_2_outlined),
        Facts(row,fields:['quantityOnHand','availableQuantity','reservedQuantity','averageCost']),
        Heading(context.tr('تتبّع الصنف','Stock tracking')),
        _InlineLink('I03',id!),
        _InlineLink('I04',id!),
      ]);
      if(screen=='I03')return PageBody(children:[
        _StockTile(row:row),
        Heading(context.tr('الدفعات المسجلة','Recorded batches'),icon:Icons.qr_code_2),
        if(maps(row['batches']).isEmpty)
          Empty(icon:Icons.qr_code_2,text:context.tr('لا توجد دفعات مسجلة لهذا الصنف.','No batches are recorded for this item.')),
        for(final batch in maps(row['batches']))
          Padding(padding:const EdgeInsets.only(bottom:8),child:Facts(batch)),
        if(app.allows(Cap.inventory))
          BusyButton(icon:Icons.pause_circle_outline,label:context.tr('حجز دفعة للمراجعة','Quarantine a batch'),
            run:()async{await openOperation(context,'hold');refresh();}),
      ]);
      if(screen=='T04')return PageBody(children:[
        RecordTile(row,icon:Icons.inventory_2_outlined,imageUrl:productImage(row),subtitle:str(row['sku'])),
        Heading(context.tr('بيانات المتغير','Variant details')),
        Facts(row,fields:['name','sku','price','salePrice','isAvailable','description']),
        if(maps(row['batches']).isNotEmpty)...[
          Heading(context.tr('الدفعات','Batches')),
          for(final batch in maps(row['batches']))Padding(padding:const EdgeInsets.only(bottom:8),child:Facts(batch)),
        ],
        if(app.canOpen(screenById('I01')))OutlinedButton.icon(
          onPressed:()=>context.open('I01'),icon:const Icon(Icons.warehouse_outlined),
          label:Text(context.tr('فتح مخزون نطاق العمل','Open warehouse inventory')),
        ),
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
        final reviewStatus=str(review['status']);
        final lots=maps(row['items']);
        if(screen=='A06')return PageBody(children:[
          RecordTile(row,icon:Icons.gavel_outlined,subtitle:context.tr('قرار المراجعة والنشر','Review and publishing decision')),
          Heading(context.tr('قرار المراجعة','Review decision'),icon:Icons.fact_check_outlined),
          if(reviewStatus.isEmpty)Empty(icon:Icons.fact_check_outlined,
            text:context.tr('لا يوجد قرار مراجعة مسجّل لهذا المزاد.','There is no recorded review decision for this auction.')),
          if(reviewStatus.isNotEmpty)Facts({...payload(review),'status':reviewStatus}),
          const SizedBox(height:12),
          if(['Draft','NeedsChanges','Rejected'].contains(reviewStatus))
            BusyButton(icon:Icons.send_outlined,label:context.tr('إرسال للمراجعة','Submit for review'),
              run:()async{await openOperation(context,'submitAuction',id:id,seed:row);refresh();}),
          if(reviewStatus=='Approved')BusyButton(icon:Icons.publish_outlined,label:context.tr('نشر المزاد','Publish auction'),
            run:()async{await openOperation(context,'publishAuction',id:id,seed:row);refresh();}),
          OutlinedButton(onPressed:()=>openOperation(context,'cancelAuction',id:id,seed:row),
            child:Text(context.tr('إلغاء المزاد','Cancel auction'))),
        ]);
        return PageBody(children:[
          RecordTile(row,icon:Icons.gavel_outlined),
          Facts(row,fields:['startAt','endAt','terms','guaranteeAmount']),
          Heading(context.tr('العناصر المعروضة','Auction lots'),icon:Icons.sell_outlined),
          if(lots.isEmpty)Empty(icon:Icons.sell_outlined,
            text:context.tr('لا توجد عناصر معروضة في هذا المزاد.','This auction has no listed lots.')),
          for(final lot in lots)Padding(padding:const EdgeInsets.only(bottom:8),child:Facts(lot)),
          Heading(context.tr('إدارة المزاد','Auction management')),
          _InlineLink('A06',id!),_InlineLink('A07',id!),_InlineLink('A08',id!),_InlineLink('A09',id!),
        ]);
      }

      if(screen=='G04')return PageBody(children:[
        RecordTile({...row,'title':titleOf(row)},icon:Icons.rule_outlined),
        Heading(context.tr('ملاحظات المراجع','Reviewer notes')),
        if(str(d['reviewNotes']??row['reviewNotes']).isEmpty)
          Empty(icon:Icons.speaker_notes_outlined,text:context.tr('لا توجد ملاحظات مراجعة مسجلة.','There are no recorded review notes.'))
        else Panel(child:SelectableText(str(d['reviewNotes']??row['reviewNotes']))),
        if(d['linkedEntityId']!=null)Fact(context.tr('السجل المرتبط','Linked record'),d['linkedEntityId']),
        if(row['status']=='NeedsChanges')...[
          const SizedBox(height:12),
          BusyButton(label:context.tr('تعديل الاقتراح','Revise proposal'),
            run:()async{await openOperation(context,'reviseProposal',id:id,seed:row,initial:d);refresh();}),
        ],
      ]);
      if(screen=='G03')return PageBody(children:[RecordTile(row,icon:Icons.lightbulb_outline),Facts(d),
        const SizedBox(height:12),OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>Scaffold(appBar:AppBar(title:Text(context.tr('مرفقات الاقتراح','Proposal attachments'))),body:CaseAttachments(recordId:id)))),icon:const Icon(Icons.attach_file),label:Text(context.tr('مرفقات الاقتراح','Proposal attachments'))),
        _InlineLink('G04',id!),if(row['status']=='NeedsChanges')... [const SizedBox(height:14),
          BusyButton(label:context.tr('استكمال الاقتراح','Revise proposal'),run:()async{await openOperation(context,'reviseProposal',id:id,seed:row,initial:d);refresh();})],
        if(d['linkedEntityId']!=null)Notice('${context.tr('تم الربط بالسجل','Linked record')} #${d['linkedEntityId']}'),
      ]);
      throw StateError('Unbound business screen $screen');
    });
  }
}
ScreenSpec screenById(String id)=>screen(id);
class _StockTile extends StatelessWidget {
  const _StockTile({required this.row,this.onTap});

  final Json row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context){
    final app=context.app;
    final variantId=numId(row['productVariantId']);
    final saved=obj(row['variant']);
    Widget card(Json variant){
      final batches=maps(row['batches']).length;
      return RecordTile(
        {...row,...variant,'id':row['id']},
        imageUrl:productImage(variant),icon:Icons.inventory_2_outlined,
        subtitle:'${context.tr('المتاح','Available')}  ${display(context,row['availableQuantity'])}   ·   ${context.tr('الدفعات','Batches')}  ${display(context,batches)}',
        onTap:onTap,
      );
    }
    if(saved.isNotEmpty||variantId==0)return card(saved);
    return FutureBuilder<Json>(
      future:app.variant(variantId),builder:(context,snapshot)=>card(snapshot.data??{}),
    );
  }
}

class _InlineLink extends StatelessWidget{
  const _InlineLink(this.route,this.id);final String route;final int id;
  @override Widget build(BuildContext context){final spec=screenById(route);return RecordTile({'title':context.app.tr(spec.ar,spec.en)},icon:screenDesigns[route]!.icon,onTap:()=>context.open(route,id:id));}
}
class _Shortcuts extends StatelessWidget{
  const _Shortcuts(this.routes);final List<String> routes;
  @override Widget build(BuildContext context)=>Wrap(spacing:8,runSpacing:8,children:[for(final route in routes)if(context.app.canOpen(screenById(route)))ActionChip(
    label:Text(context.app.tr(screenById(route).ar,screenById(route).en)),onPressed:()=>context.open(route))]);
}
class BusinessHub extends StatelessWidget{
  const BusinessHub({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final groups = [
      (context.tr('البيع والفواتير', 'Sales and billing'), ['T02', 'T06', 'T09', 'T03']),
      (context.tr('المخزون والتوريد', 'Stock and procurement'), ['I01', 'I06', 'T11', 'T12', 'T10']),
      (context.tr('الصندوق والحسابات', 'Cash and accounts'), ['N01', 'N03', 'N05', 'N06', 'N08']),
      (context.tr('الاستلام والسوق', 'Pickup and marketplace'), ['P01', 'P02', 'A01', 'G01']),
    ];
    return PageBody(children: [
      if (app.grant case final grant?)
        RecordTile({'title': grantName(context, grant)}, icon: Icons.warehouse_outlined,
          subtitle: context.tr('تغيير نطاق عمليات الفرع', 'Change branch work context'),
          onTap: () => context.open('H06'))
      else
        Empty(
          icon: Icons.warehouse_outlined,
          text: context.tr('لا يوجد تفويض تجاري نشط في هذا الحساب.', 'This account has no active trading delegation.'),
          action: OutlinedButton(onPressed: () => context.open('H06'),
            child: Text(context.tr('عرض نطاق العمل', 'View work context'))),
        ),
      for (final group in groups)
        if (group.$2.any((route) => app.canOpen(screenById(route)))) ...[
          Heading(group.$1),
          WorkspaceActions(group.$2),
        ],
    ]);
  }
}
class _RecordSelector extends StatelessWidget{
  const _RecordSelector({required this.target});final String target;
  @override Widget build(BuildContext context){final app=context.app;
    final binding=target.startsWith('I')?('/api/agent/commerce/inventory',true):target.startsWith('P')?('/api/agent/pickup/requests',true):
      target.startsWith('G')?('/api/agent/marketplace/proposals',false):('/api/agent/commerce/documents',true);
    return PagedRecords(
      load:(cursor)=>app.page(binding.$1,query:binding.$2?app.scoped():null,afterId:cursor),
      pageSize:target.startsWith('I')?100:50,
      header:[Heading(context.tr('اختر سجلًا للمتابعة','Choose a record to continue'))],
      itemBuilder:(row)=>RecordTile(row,onTap:()=>context.open(target,id:numId(row['id']),seed:row)),
    );
  }
}
class _RemoteList extends StatelessWidget{
  const _RemoteList(this.path,{this.query,this.onTap});final String path;final Json? query;
  final void Function(Json)? onTap;
  @override Widget build(BuildContext context)=>Resource(load:()=>context.app.read(path,query:query),builder:(data,refresh){
    final list=rows(data);
    return PageBody(children:[if(list.isEmpty)const Empty(),for(final row in list)Padding(padding:const EdgeInsets.only(bottom:12),child:onTap==null?RecordDetails(payload(row)):RecordTile(row,onTap:()=>onTap!(row)))]);
  });
}
class _EmbeddedRecords extends StatelessWidget{
  const _EmbeddedRecords({super.key,required this.load});final Future<dynamic> Function() load;
  @override Widget build(BuildContext context)=>Resource(embedded:true,load:load,builder:(data,refresh)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    if(data is Map)RecordDetails(payload(obj(data))),
    if(rows(data).isEmpty&&data is! Map)const Empty(),
    for(final row in rows(data))Padding(padding:const EdgeInsets.only(bottom:10),child:RecordDetails(payload(row)))]));
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
class _PointOfSaleState extends State<PointOfSale> {
  final searchController=TextEditingController();
  String search='';

  @override
  void dispose(){
    searchController.dispose();
    super.dispose();
  }

  void changeQuantity(Json line,double desired){
    final basket=context.app.basket;
    final inOtherBatches=basket.where((other)=>other!=line&&other['productVariantId']==line['productVariantId'])
        .fold(0.0,(total,other)=>total+decimal(other['quantity']));
    if(desired>decimal(line['maxQuantity'])||desired+inOtherBatches>decimal(line['availableStock'])){
      toast(context,context.tr('الكمية المطلوبة تتجاوز الرصيد المتاح.','The requested quantity exceeds available stock.'));
      return;
    }
    setState((){
      if(desired<=0){basket.remove(line);}
      else{line['quantity']=desired;if(!basket.contains(line))basket.add(line);}
    });
  }

  Future<void> add(Json variant,Json stock)async{
    final batches=maps(stock['batches']).where((batch){
      final expiry=DateTime.tryParse(str(batch['expiryDate']));
      return decimal(batch['quantity'])>0&&(expiry==null||expiry.isAfter(DateTime.now().toUtc()));
    }).toList();
    final batch=await showModalBottomSheet<Json>(context:context,useSafeArea:true,builder:(sheet)=>PageBody(children:[
      Heading(sheet.tr('اختر الدفعة','Choose a batch')),
      if(batches.isEmpty)Empty(text:sheet.tr('لا توجد دفعة صالحة للبيع','No eligible batch is available')),
      for(final item in batches)
        RecordTile(item,icon:Icons.inventory_2_outlined,
          subtitle:'${display(sheet,item['quantity'])} · ${display(sheet,item['expiryDate'])}',
          onTap:()=>Navigator.pop(sheet,item)),
    ]));
    if(batch==null||!mounted)return;
    final variantId=numId(stock['productVariantId']);
    final basket=context.app.basket;
    final existing=basket.where((line)=>line['productVariantId']==variantId&&line['batchId']==batch['id']).firstOrNull;
    final line=existing??{
      'productVariantId':variantId,'batchId':batch['id'],'quantity':0,
      'name':titleOf(variant),'unitPrice':variant['salePrice']??variant['price'],'batchNumber':batch['batchNumber'],
      'maxQuantity':batch['quantity'],'availableStock':stock['availableQuantity'],
    };
    changeQuantity(line,decimal(line['quantity'])+1);
  }

  Future<void> openCart()async{
    final app=context.app;
    final continueToPayment=await showModalBottomSheet<bool>(
      context:context,useSafeArea:true,isScrollControlled:true,
      builder:(sheet)=>StatefulBuilder(builder:(context,refresh)=>FractionallySizedBox(
        heightFactor:.78,
        child:Column(children:[
          Expanded(child:PageBody(children:[
            Heading(context.tr('سلة البيع','Sale cart')),
            if(app.basket.isEmpty)const Empty(icon:Icons.shopping_cart_outlined),
            for(final line in app.basket)
              Padding(padding:const EdgeInsets.only(bottom:8),child:Panel(child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  Text(str(line['name']),style:Theme.of(context).textTheme.titleMedium),
                  Fact('batchNumber',line['batchNumber']),
                  Row(children:[
                    IconButton(tooltip:context.tr('إنقاص الكمية','Decrease quantity'),
                      onPressed:()=>refresh(()=>changeQuantity(line,decimal(line['quantity'])-1)),
                      icon:const Icon(Icons.remove_circle_outline)),
                    Text(display(context,line['quantity'])),
                    IconButton(tooltip:context.tr('زيادة الكمية','Increase quantity'),
                      onPressed:()=>refresh(()=>changeQuantity(line,decimal(line['quantity'])+1)),
                      icon:const Icon(Icons.add_circle_outline)),
                    const Spacer(),
                    Text('${display(context,decimal(line['quantity'])*decimal(line['unitPrice']))} ${app.currency}'),
                  ]),
                ],
              ))),
          ])),
          Padding(padding:const EdgeInsets.fromLTRB(18,8,18,18),child:SizedBox(
            width:double.infinity,
            child:FilledButton.icon(
              onPressed:app.basket.isEmpty?null:()=>Navigator.pop(sheet,true),
              icon:const Icon(Icons.receipt_long_outlined),
              label:Text(context.tr('مراجعة المبلغ والدفع','Review amount and payment')),
            ),
          )),
        ]),
      )),
    );
    if(continueToPayment==true&&mounted)context.open('T05');
  }

  @override
  Widget build(BuildContext context){
    final app=context.app,theme=Theme.of(context);
    final count=app.basket.fold(0.0,(total,line)=>total+decimal(line['quantity']));
    final subtotal=app.basket.fold(0.0,(total,line)=>total+decimal(line['quantity'])*decimal(line['unitPrice']));
    return Column(children:[
      Expanded(child:PagedRecords(
        key:ValueKey('pos:${app.grantId}:${app.revision}'),
        pageSize:100,
        load:(cursor)=>app.page('/api/agent/commerce/inventory',query:app.scoped(),afterId:cursor),
        include:(row)=>decimal(row['availableQuantity'])>0,
        header:[
          TextField(controller:searchController,textInputAction:TextInputAction.search,
            decoration:InputDecoration(prefixIcon:const Icon(Icons.search),
              hintText:context.tr('اسم الصنف أو رمزه','Product name or SKU'),
              suffixIcon:IconButton(tooltip:context.tr('مسح رمز','Scan code'),
                icon:const Icon(Icons.qr_code_scanner),onPressed:()=>context.open('T03'))),
            onChanged:(value){
              if(value.isEmpty)setState(()=>search='');
            },
            onSubmitted:(value)=>setState(()=>search=value.trim().toLowerCase()),
          ),
          const SizedBox(height:12),
        ],
        itemBuilder:(stock){
          final id=numId(stock['productVariantId']);
          return FutureBuilder<Json>(
            future:app.variant(id),
            builder:(context,snapshot){
              final product=snapshot.data;
              if(product==null){
                if(snapshot.hasError && search.isEmpty){
                  return RecordTile({'title':'${context.tr('صنف المخزون','Stock item')} #$id'},
                    icon:Icons.inventory_2_outlined,subtitle:context.tr('تعذر تحميل تفاصيل الصنف','Product details unavailable'));
                }
                return snapshot.connectionState==ConnectionState.done?const SizedBox.shrink():
                  const Padding(padding:EdgeInsets.all(14),child:LinearProgressIndicator());
              }
              if(product['isAvailable']==false||
                 !'${titleOf(product)} ${str(product['sku'])}'.toLowerCase().contains(search)){
                return const SizedBox.shrink();
              }
              return RecordTile(product,imageUrl:productImage(product),icon:Icons.add_shopping_cart,
                subtitle:'${display(context,product['salePrice']??product['price'])} ${app.currency}  ·  ${context.tr('متاح','Available')} ${display(context,stock['availableQuantity'])}',
                onTap:()=>add(product,stock));
            },
          );
        },
      )),
      Material(color:theme.colorScheme.surface,child:SafeArea(
        top:false,
        child:Padding(padding:const EdgeInsets.symmetric(horizontal:18,vertical:10),child:Row(children:[
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
            Text('${display(context,count)} ${context.tr('وحدة في السلة','units in cart')}',style:theme.textTheme.bodySmall),
            Text('${display(context,subtotal)} ${app.currency}',style:theme.textTheme.titleMedium),
          ])),
          FilledButton.icon(onPressed:count>0?openCart:null,icon:const Icon(Icons.shopping_basket_outlined),
            label:Text(context.tr('عرض السلة','View cart'))),
        ])),
      )),
    ]);
  }
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
      for(final f in fields)Padding(padding:const EdgeInsets.only(bottom:14),child:InputControl(spec:f,value:draft[f.key],parentValues:draft,onChanged:(v)=>setState(()=>draft[f.key]=v))),
      if(widget.screen!='A04')FilledButton(onPressed:(){if(!form.currentState!.validate())return;form.currentState!.save();context.open(widget.screen=='A02'?'A03':'A04');},child:Text(context.tr('متابعة','Continue')))
      else BusyButton(label:context.tr('مراجعة وحفظ مسودة المزاد','Review and save auction'),run:()async{
        if(!form.currentState!.validate())return;form.currentState!.save();
        final result=await openOperation(context,'auction',initial:draft);if(result==null||!context.mounted)return;
        app.auctionDraft={};context.open('A05',id:numId(result['auctionId']));}),
    ]));}
}
