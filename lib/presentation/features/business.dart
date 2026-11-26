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
import '../shared/paged_records.dart';
import '../shared/scope.dart';
import '../shared/section_banner.dart';
import '../shared/product_thumbnail.dart';
import '../shared/widgets.dart';
import 'clinical.dart';

const listBindings=<String,(String,String)>{
  'I01':('/api/agent/commerce/inventory','I02'),'I06':('/api/agent/commerce/transfers','I08'),
  'T06':('/api/agent/commerce/documents','T07'),
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
    if(screen=='N06') return PagedRecords(
      load: (afterId) async => [
        for (final row in await app.page('/api/agent/finance/journals',afterId:afterId,query:app.scoped()))
          {...row,'id':row['journalEntryId']},
      ],
      itemBuilder: (row) => Padding(padding: const EdgeInsets.only(bottom:10),child:RecordDetails(row)),
    );
    if(screen=='I05')return const StockAlerts();
    if(screen=='I10')return Resource(load:app.changes,builder:(data,r)=>PageBody(children:[
      Notice(context.tr('تُعتمد فروق الجرد بواسطة مراجع مستقل. تتحدث الحالة من سجل العمليات.','Stock differences require an independent reviewer. Status follows the operation record.')),
      const SizedBox(height:14),for(final row in rows(data).where((r)=>r['kind']=='StockCount'))RecordTile(row),
    ]));
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
    if ((screen=='T08'||screen=='T14') && id!=null) {
      return Resource(identity: '$screen:$id:${app.revision}', load: () => app.record('document', id!,fresh:true), builder: (data, refresh) {
        final invoice = obj(data);
        if (invoice['type'] != (screen == 'T08' ? 'SalesInvoice' : 'PurchaseInvoice') || invoice['isPosted'] != true) {
          return PageBody(children: [Notice(context.tr('هذه الفاتورة غير مؤهلة للمرتجع.', 'This invoice is not eligible for return.'))]);
        }
        return OperationPage(embedded:true,operation:operations['return']!, id:id, seed:invoice,initial:{'originalDocumentId':id});
      });
    }
    if(screen=='T05')return OperationPage(embedded:true,operation:operations['sale']!,initial:{
      ...app.sale,'lines':app.basket.map((l)=>{for(final k in ['productVariantId','batchId','quantity'])k:l[k]}).toList(),
      'paidAmount':null,'paymentMethod':'Cash'});
    if(screen=='A02'||screen=='A03'||screen=='A04')return AuctionWizard(screen:screen);
    if (screen == 'A01') return PagedRecords(
      key: ValueKey('auctions:${app.revision}'),
      loadPage: (afterId) async {
        final result = obj(await app.read('/api/agent/marketplace/auctions',
          query: app.scoped({'afterId': afterId})));
        final page = RecordPage.from(result);
        return RecordPage(maps(result['auctions']), page.nextAfterId);
      },
      header: [
        SectionBanner(art:SectionArt.workspace,icon:Icons.gavel_outlined,title:context.tr('مزادات الفرع','Branch auctions')),
        const SizedBox(height:12),
        FilledButton.icon(onPressed:()=>context.open('A02'),icon:const Icon(Icons.add),label:Text(context.tr('إنشاء مزاد','Create auction'))),
        const SizedBox(height:16),
      ],
      itemBuilder: (auction) => RecordTile(auction, icon: Icons.gavel_outlined,
        onTap: () => context.open('A05', id:numId(auction['id']), seed:auction)),
    );
    if (screen == 'N02') return PagedRecords(
      key: ValueKey('cash:${app.revision}'),
      pageSize: 100,
      load: (afterId) async => rows(await app.read('/api/agent/operations/cashbox',
        query: app.scoped({'afterTransactionId': afterId}))),
      header: [SectionBanner(art: SectionArt.commerce, title: context.tr('حركات الصندوق', 'Cash transactions')), const SizedBox(height: 12)],
      itemBuilder: (row) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Facts(row)),
    );
    if(['N01','N03','N04'].contains(screen))return Resource(identity:app.revision,load:()=>app.read('/api/agent/operations/cashbox',query:app.scoped()),builder:(data,refresh){
      final box=obj(data),shifts=maps(box['shifts']),active=shifts.where((r)=>r['status']=='Active').firstOrNull;
      if(screen=='N04'){
        final shift=id==null?active:shifts.where((s)=>numId(s['id'])==id).firstOrNull;
        if(shift==null)return PageBody(children:[Empty(text:context.tr('لا توجد وردية مفتوحة','No active shift'))]);
        if (shift['status'] != 'Active') return PageBody(children: [Facts(payload(shift)), StatusTag(str(shift['status']))]);
        return OperationPage(embedded:true,operation:operations['closeShift']!,id:numId(shift['id']),seed:shift);
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
          Heading(context.tr('الورديات السابقة','Previous shifts')),for(final shift in shifts)RecordTile(shift,onTap:()=>context.open('N04',id:numId(shift['id']))),
        ],
        if(screen=='N01')... [const SizedBox(height:12),OutlinedButton(onPressed:()=>context.open('N02'),child:Text(context.tr('عرض الحركات','View transactions')))],
        if(screen=='N02')... [Heading(context.tr('حركات الصندوق','Cash transactions')),for(final t in maps(box['transactions']))Padding(padding:const EdgeInsets.only(bottom:10),child:Facts(t))],
      ]);
    });
    if (screen == 'T09') return PagedRecords(
      key: ValueKey('quotes:${app.revision}'),
      loadPage: (afterId) => app.cursorPage('/api/agent/commercial/quotes', afterId: afterId, query: app.scoped()),
      header: [
        FilledButton.icon(onPressed: () => openOperation(context, 'quote'), icon: const Icon(Icons.add), label: Text(context.tr('عرض سعر جديد', 'New quotation'))),
        Heading(context.tr('عروضي', 'My quotations')),
      ],
      itemBuilder: (quote) => Padding(padding: const EdgeInsets.only(bottom: 10),
        child: RecordTile(quote, subtitle: '${display(context, payload(quote)['total'])} ${str(payload(quote)['currency'])}',
          onTap: () => showDialog<void>(context: context, builder: (_) => AlertDialog(
            title: Text(context.tr('عرض السعر', 'Quotation')),
            content: SingleChildScrollView(child: RecordDetails(payload(quote))),
          )))),
    );
    if (screen == 'T10') return PagedRecords(
      loadPage: (afterId) => app.cursorPage('/api/agent/directory/suppliers', afterId: afterId, query: app.scoped()),
      itemBuilder: (supplier) => RecordTile(supplier, onTap: () => showDialog<void>(
        context: context, builder: (_) => AlertDialog(title: Text(titleOf(supplier)), content: Facts(supplier)),
      )),
    );
    if (screen == 'I04' && id != null) return PagedRecords(
      loadPage: (afterId) => app.cursorPage('/api/agent/commerce/inventory/$id/transactions', afterId: afterId, query: app.scoped()),
      itemBuilder: (row) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Facts(row)),
    );
    if (listBindings.containsKey(screen) && !(screen == 'T13' && id != null)) {
      final binding = listBindings[screen]!;
      return PagedRecords(
        key: ValueKey('$screen:$id:${app.revision}'),
        load: (afterId) => app.page(binding.$1, query: app.scoped({
          if (screen == 'T06') 'type': 'SalesInvoice',
          if (screen == 'T11') 'type': 'PurchaseInvoice',
          if (screen == 'P02' && id != null) 'pointId': id,
        }), afterId: afterId),
        pageSize: screen == 'I01' ? 100 : 50,
        header: [
          if (['I01','T06','T11','P01','P02','G01'].contains(screen)) ...[
            SectionBanner(art:SectionArt.commerce, title:context.app.tr(screenById(screen).ar,screenById(screen).en)),
            const SizedBox(height:10),
          ],
          if (screen == 'I01') _Shortcuts(const ['I05','I06','I07','I09']),
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
      screen=='T13'?'procurement':screen=='N07'?'settlement':'document';
    final actualKind=screen=='I08'?'transfer':screen=='T04'?'variant':kind;
    return Resource(identity:'$screen:$id:${app.revision}',load:()async{
      if(actualKind=='variant') {
        final variant=await app.variant(id!);
        if(!app.allows(Cap.sell)) return variant;
        final stock=await app.cursorPage('/api/agent/directory/sale-stock',
          query:app.scoped({'productVariantId':id}));
        final batches=stock.items.expand((row)=>maps(row['batches'])).toList();
        return {...variant,'batches':batches};
      }
      final data=await app.record(actualKind,id!,fresh:true);
      if(actualKind!='stock')return data;
      try {
        final variant=await app.variant(numId(data['productVariantId']));
        return {...data,'variant':variant};
      }catch(_){return data;}
    },builder:(data,refresh){
      final row=obj(data),d=payload(row);
      if (screen=='I08'||screen=='T13') {
        final receivable = screen=='I08'
            ? row['status']=='Active' && numId(row['otherWarehouseId'])==app.grant?.warehouse
            : row['status']=='Approved' && app.allows(Cap.cash);
        if (!receivable) return PageBody(children: [StatusTag(str(row['status'])), Facts(d),
          for (final line in maps(d['lines'])) RecordDetails(line)]);
        return OperationPage(embedded:true,operation:operations[screen=='I08'?'receiveTransfer':'receivePurchase']!,id:id,seed:row);
      }
      if (screen=='N07') {
        if (decimal(row['remainingAmount']) <= 0) return PageBody(children: [Facts(row),
          Notice(context.tr('لا يوجد مبلغ متبقٍ للتسوية.', 'There is no amount left to settle.'))]);
        return OperationPage(embedded:true,operation:operations['settle']!,id:id,seed:row);
      }
      if(screen=='I02'||screen=='I03'||screen=='T04')return PageBody(children:[
        if(screen=='T04')
          RecordTile(row,icon:Icons.inventory_2_outlined,imageUrl:productImage(row),subtitle:str(row['sku']))
        else
          _StockTile(row:row),
        Facts(row,fields:['quantityOnHand','availableQuantity','reservedQuantity','averageCost']),
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
        if (row['isPosted']==true && ['SalesInvoice','PurchaseInvoice'].contains(row['type'])) ...[
          const SizedBox(height:12),OutlinedButton(onPressed:()=>context.open(row['type']=='PurchaseInvoice'?'T14':'T08',id:id),child:Text(context.tr('طلب مرتجع مرتبط بالفاتورة','Request return against this invoice'))),
          if(app.allows(Cap.cash) && decimal(row['remainingAmount'])>0)_InlineLink('N07',id!),
        ],
      ]);
      if (screen.startsWith('P')) {
        final movement = obj(row['movement']);
        final pending = row['status'] == 'Draft';
        final active = row['status'] == 'Active';
        final operationsForRecord = <String, String>{
          if (pending && movement.isEmpty && row['orderStatus']=='Processing') 'P04': 'custody',
          if (active && movement['status'] == 'Active') 'P05': 'shelf',
          if (row['canComplete'] == true) 'P06': 'handover',
          if (active) 'P07': 'pickupIssue',
        };
        final action = operationsForRecord[screen];
        if (screen != 'P03') {
          if (action == null) return PageBody(children: [Facts(row, fields:['status','paymentStatus','cashToCollect','currency']),
            Notice(row['requiresCash'] == true && row['cashShiftReady'] != true
              ? context.tr('يتطلب التحصيل صندوقًا مفوّضًا ووردية مفتوحة.', 'Cash collection requires an assigned cashbox and open shift.')
              : context.tr('الإجراء غير متاح لحالة هذا الطلب.', 'This action is unavailable for the current order status.'))]);
          if (screen=='P06' && row['codeIssued'] != true) return PageBody(children: [
            Notice(context.tr('اطلب من العميل إصدار رمز صالح للتسليم، ثم حدّث الطلب.', 'Ask the customer to issue a valid code, then refresh the order.')),
            OutlinedButton(onPressed:refresh,child:Text(context.tr('تحديث حالة الرمز','Refresh code status'))),
          ]);
          final actionSeed = screen=='P05' ? {...row, 'version': movement['version']} : row;
          return OperationPage(embedded:true,operation:operations[action]!,id:id,seed:actionSeed);
        }
        return PageBody(children:[
          Facts(row, fields: ['orderId','status','paymentStatus','cashToCollect','currency','readyAt','completedAt']),
          if (movement.isNotEmpty) Facts(movement, fields: ['status','shelf','deadline']),
          Heading(context.tr('مراحل الاستلام','Pickup stages')),
          for (final step in operationsForRecord.keys) _InlineLink(step, id!),
          if (active && row['requiresCash'] == true && row['cashShiftReady'] != true)
            Notice(context.tr('يحتاج الطلب إلى تحصيل نقدي عبر وردية مفوّضة.', 'Use an authorized cash shift to collect this order.')),
          if (pending && movement['status']=='Pending') BusyButton(
            label: context.tr('إنشاء رمز للسائق','Generate driver handoff code'),run:()async{
              final result=await openOperation(context,'driverCode',id:id,seed:{...row,'version':movement['version']});
              if(result==null||!context.mounted)return;
              await showDialog<void>(context:context,builder:(c)=>AlertDialog(content:CodeCard(result)));refresh();
            }),
        ]);
      }
      if(screen.startsWith('A')){
        if(screen=='A09')return Resource(load:()=>app.read('/api/identifiers/auctions/$id'),builder:(label,r)=>PageBody(children:[CodeCard(obj(label))]));
        if (screen == 'A08') return Resource(
          identity: 'auction-fulfillment:$id:${app.revision}',
          load: () => app.read('/api/agent/marketplace/auctions/$id/fulfillment'),
          builder: (data, refresh) => PageBody(children: [
            if (rows(data).isEmpty) const Empty(),
            for (final winner in rows(data)) ...[
              Facts(winner, fields: ['orderId','orderStatus','paymentStatus','finalPrice']),
              if (winner['canPrepare'] == true) BusyButton(label: context.tr('تجهيز الطلب', 'Prepare order'), run: () async {
                await openOperation(context, 'prepare', id: numId(winner['orderId']));
                refresh();
              }),
              if (winner['canHandover'] == true) BusyButton(label: context.tr('تسليم الطلب', 'Hand over order'), run: () async {
                final winners = rows(await app.read('/api/agent/marketplace/auctions/$id/fulfillment'));
                if (!context.mounted) return;
                final current = winners.where((row) => row['orderId'] == winner['orderId']).firstOrNull;
                if (current?['codeIssued'] != true) {
                  toast(context, context.tr('اطلب من العميل إصدار رمز تسليم صالح.', 'Ask the customer to issue a valid handover code.'));
                  refresh();
                  return;
                }
                await openOperation(context, 'auctionHandover', id: numId(current!['orderId']), seed: current);
                refresh();
              }),
              const SizedBox(height: 14),
            ],
          ]),
        );
        if(screen=='A07')return PageBody(children:[Facts(row),Heading(context.tr('المعروض والمزايدات','Lots and bids')),
          for(final lot in maps(row['items']))... [Facts(lot),_EmbeddedRecords(load:()=>app.read('/api/AuctionBids/auction-item/${lot['id']}'))]]);
        final review=obj(row['review']);
        return PageBody(children:[Facts(row),Heading(context.tr('حالة المراجعة','Review status')),Facts(payload(review)),StatusTag(str(review['status'])),
          Heading(context.tr('المعروض','Lots')),for(final lot in maps(row['items']))Padding(padding:const EdgeInsets.only(bottom:10),child:Facts(lot)),
          if(['Draft','NeedsChanges','Rejected'].contains(review['status']))BusyButton(label:context.tr('إرسال للمراجعة','Submit for review'),run:()async{await openOperation(context,'submitAuction',id:id,seed:row);refresh();}),
          if(review['status']=='Approved')BusyButton(label:context.tr('نشر المزاد','Publish auction'),run:()async{await openOperation(context,'publishAuction',id:id,seed:row);refresh();}),
          const SizedBox(height:12),
          if (['Scheduled','Active','Ended'].contains(row['status'])) ...[_InlineLink('A07',id!),_InlineLink('A08',id!),_InlineLink('A09',id!)],
          if (!['Ended','Cancelled'].contains(row['status']))
            OutlinedButton(onPressed:()=>openOperation(context,'cancelAuction',id:id,seed:row),child:Text(context.tr('إلغاء المزاد','Cancel auction'))),
        ]);
      }
      if(screen.startsWith('G'))return PageBody(children:[Facts(d),const SizedBox(height:12),StatusTag(str(row['status'])),
        const SizedBox(height:12),OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>Scaffold(appBar:AppBar(title:Text(context.tr('مرفقات الاقتراح','Proposal attachments'))),body:CaseAttachments(recordId:id)))),icon:const Icon(Icons.attach_file),label:Text(context.tr('مرفقات الاقتراح','Proposal attachments'))),
        if(screen=='G03')_InlineLink('G04',id!),if(row['status']=='NeedsChanges')... [const SizedBox(height:14),
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
    SectionBanner(art:SectionArt.commerce,icon:Icons.storefront_outlined,
      title:context.tr('إدارة الفرع','Manage your branch'),
      subtitle:context.tr('نقطة البيع والمخزون والصندوق','Point of sale, inventory and cashbox')),
    Heading(context.tr('عمليات الفرع','Branch operations')),
    LayoutBuilder(builder:(context,grid)=>Wrap(spacing:8,runSpacing:8,children:[
    for(final entry in [('T02',Icons.point_of_sale_outlined),('I01',Icons.inventory_2_outlined),('T06',Icons.receipt_long_outlined),('T09',Icons.request_quote_outlined),
      ('T11',Icons.shopping_bag_outlined),('T12',Icons.add_shopping_cart),('T10',Icons.local_shipping_outlined),('N01',Icons.account_balance_wallet_outlined),
      ('N05',Icons.account_balance_outlined),('N06',Icons.menu_book_outlined),('N08',Icons.bar_chart),('P01',Icons.storefront_outlined),
      ('P02',Icons.move_to_inbox_outlined),('A01',Icons.gavel_outlined),('G01',Icons.lightbulb_outline)])
      if(context.app.canOpen(screenById(entry.$1)))
        SizedBox(width:grid.maxWidth<340?grid.maxWidth:(grid.maxWidth-8)/2,
          child:ActionTile(title:context.app.tr(screenById(entry.$1).ar,screenById(entry.$1).en),
            icon:entry.$2,onTap:()=>context.open(entry.$1))),
    ])),
    if(context.app.access.grants.isEmpty)Notice(context.tr('لا يوجد تفويض تجاري نشط. تواصل مع الإدارة لتحديد نطاقك.','No active business delegation. Contact your administrator to assign a work context.')),
  ]);
}
class _RecordSelector extends StatelessWidget {
  const _RecordSelector({required this.target});
  final String target;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final (path, query, size) = switch (target) {
      'P06' => ('/api/agent/pickup/requests', {'status': 'Active'}, 50),
      'T08' => ('/api/agent/commerce/documents', {'type': 'SalesInvoice'}, 50),
      'T14' => ('/api/agent/commerce/documents', {'type': 'PurchaseInvoice'}, 50),
      'N07' => ('/api/agent/finance/settlements', <String,dynamic>{}, 50),
      'I03' => ('/api/agent/commerce/inventory', <String,dynamic>{}, 100),
      _ => ('', <String,dynamic>{}, 50),
    };
    if (path.isEmpty) return PageBody(children: [Empty(
      text: context.tr('افتح السجل المرتبط من قائمته أولًا.', 'Open the linked record from its list first.'),
    )]);
    return PagedRecords(
      pageSize: size,
      load: target=='N07' ? null : (afterId) => app.page(path, query: app.scoped(query), afterId: afterId),
      loadPage: target=='N07' ? (afterId) => app.cursorPage(path, query: app.scoped(), afterId: afterId) : null,
      include: (row) => !['T08','T14'].contains(target) || row['isPosted'] == true,
      header:[Heading(context.tr('اختر سجلًا للمتابعة','Choose a record to continue'))],
      itemBuilder: (row) => RecordTile(row, onTap: () => context.open(target,id:numId(row['id']),seed:row)),
    );
  }
}

class _EmbeddedRecords extends StatelessWidget{
  const _EmbeddedRecords({super.key,required this.load});final Future<dynamic> Function() load;
  @override Widget build(BuildContext context)=>Resource(embedded:true,load:load,builder:(data,refresh)=>Column(children:[
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
    final existing=basket.where((line)=>line['productVariantId']==variantId).firstOrNull;
    if (existing!=null && existing['batchId']!=batch['id']) {
      toast(context,context.tr('اختر دفعة واحدة لكل صنف في الفاتورة.', 'Choose one batch per product on this invoice.'));
      return;
    }
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
      Padding(padding:const EdgeInsets.symmetric(horizontal:18), child:TextField(
        controller:searchController,textInputAction:TextInputAction.search,
        decoration:InputDecoration(prefixIcon:const Icon(Icons.search),
          hintText:context.tr('اسم الصنف أو رمزه','Product name or SKU'),
          suffixIcon:IconButton(tooltip:context.tr('مسح رمز','Scan code'),
            icon:const Icon(Icons.qr_code_scanner),onPressed:()=>context.open('T03'))),
        onChanged:(value){if(value.isEmpty)setState(()=>search='');},
        onSubmitted:(value)=>setState(()=>search=value.trim()),
      )),
      const SizedBox(height:8),
      Expanded(child:PagedRecords(
        key:ValueKey('pos:${app.grantId}:${app.revision}:$search'),
        loadPage:(cursor)=>app.cursorPage('/api/agent/directory/sale-stock',
          query:app.scoped({if(search.isNotEmpty)'search':search}), afterId:cursor),
        header:[
          SectionBanner(art:SectionArt.commerce,icon:Icons.point_of_sale_outlined,
            title:context.tr('البيع من مخزنك','Sell from your inventory')),
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
              if(product['isAvailable']==false){
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
    final now=DateTime.now().toUtc();
    final before=DateTime.utc(now.year,now.month,now.day+1);
    final from=before.subtract(Duration(days:days));
    return Resource(identity:'report:$days:${app.revision}',load:()=>app.all('/api/agent/commerce/documents',query:app.scoped({
      'postedFrom':from.toIso8601String(),'postedBefore':before.toIso8601String(),
    })),builder:(data,refresh){
      final all=rows(data),currencies=all.map((d)=>str(d['currency'])).where((v)=>v.isNotEmpty).toSet().toList()..sort();
      final current=currencies.contains(currency)?currency:(currencies.contains(app.currency)?app.currency:currencies.firstOrNull);
      final documents=all.where((d)=>d['isPosted']==true&&d['currency']==current).toList();
      double amount(String type)=>documents.where((d)=>d['type']==type).fold(0,(s,d)=>s+decimal(d['totalAmount']));
      final sales=amount('SalesInvoice')-amount('SalesReturn'),purchases=amount('PurchaseInvoice')-amount('PurchaseReturn');
      final daily=<ChartValue>[];
      for(var i=6;i>=0;i--){final date=before.subtract(Duration(days:i+1));final total=documents.where((d){
        final t=DateTime.tryParse(str(d['postedAt']))?.toUtc();return d['type']=='SalesInvoice'&&t!=null&&t.year==date.year&&t.month==date.month&&t.day==date.day;}).fold(0.0,(s,d)=>s+decimal(d['totalAmount']));
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
    OutlinedButton.icon(onPressed:()async{final selected=await chooseReference(context,supplier?'statementSuppliers':'statementCustomers');if(selected!=null)setState(()=>party=selected);},
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
      Padding(padding:const EdgeInsets.only(bottom:20),child:LinearProgressIndicator(value:widget.screen == 'A02' ? 0.33 : widget.screen == 'A03' ? 0.66 : 1.0)),
      for(final f in fields)Padding(padding:const EdgeInsets.only(bottom:14),child:InputControl(spec:f,value:draft[f.key],parentValues:draft,onChanged:(v)=>setState(()=>draft[f.key]=v))),
      if(widget.screen!='A04')FilledButton(onPressed:(){if(!form.currentState!.validate())return;form.currentState!.save();context.open(widget.screen=='A02'?'A03':'A04');},child:Text(context.tr('متابعة','Continue')))
      else BusyButton(label:context.tr('مراجعة وحفظ مسودة المزاد','Review and save auction'),run:()async{
        if(!form.currentState!.validate())return;form.currentState!.save();
        final result=await openOperation(context,'auction',initial:draft);if(result==null||!context.mounted)return;
        app.auctionDraft={};context.open('A05',id:numId(result['auctionId']));}),
    ]));}
}
