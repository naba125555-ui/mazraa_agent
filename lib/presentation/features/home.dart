import 'package:flutter/material.dart';
import '../../domain/models.dart';
import '../navigation.dart';
import '../shared/charts.dart';
import '../shared/scope.dart';
import '../shared/section_banner.dart';
import '../shared/widgets.dart';

class HomePage extends StatelessWidget{
  const HomePage({super.key});
  @override Widget build(BuildContext context){final app=context.app,c=Theme.of(context).colorScheme;
    return Resource(identity: 'home:${app.revision}', load: () async {
      if (!app.access.doctor) return <Json>[];
      return app.page('/api/agent/field/tasks');
    }, builder: (data, refresh) {
      final offers = numId(app.summary['caseOffers']);
      final upcoming = rows(data)
          .where((r) => !['Completed', 'Cancelled', 'Rejected'].contains(r['status']))
          .toList()
        ..sort((a, b) => str(a['scheduledDate']).compareTo(str(b['scheduledDate'])));
      final current=payload(obj(app.profile['profile']));
      final name=str(app.user['name']??obj(app.profile['user'])['name']);
      return PageBody(children:[
        SectionBanner(
          art: SectionArt.workspace,
          title: name.isEmpty ? context.tr('مرحبًا بك في مزرعتي','Welcome to Mazraa') : '${context.tr('مرحبًا،','Welcome,')} $name',
          subtitle: context.tr('مساحة عمل الطبيب والوكيل','Doctor and agent workspace'),
        ),
        const SizedBox(height:12),
        Wrap(spacing:10,runSpacing:8,children:[
          ActionChip(avatar:const Icon(Icons.storefront_outlined,size:19),label:Text(app.grant==null?context.tr('نطاق العمل','Work context'):
            '${context.tr('المخزن','Warehouse')} #${app.grant!.warehouse}'),onPressed:()=>context.open('H06')),
          if(app.access.doctor)ActionChip(avatar:Icon(Icons.circle,size:10,color:current['isAvailable']==true?c.primary:c.secondary),
            label:Text(current['isAvailable']==true?context.tr('متاح للاستشارات','Available'):context.tr('غير متاح','Unavailable')),
            onPressed:()async{try{await app.repo.write('PATCH','/api/agent/availability',{'available':current['isAvailable']!=true});await app.refreshAccess();}
              catch(e){if(context.mounted)toast(context,failureText(context,e));}}),
        ]),const SizedBox(height:16),
        if (app.access.doctor || app.allows(Cap.cash))
          LayoutBuilder(builder: (context, constraints) {
            final metrics = [
              if (app.access.doctor)
                (Icons.chat_bubble_outline, context.tr('استشارات جديدة','New consultations'), offers, 'C01'),
              if (app.access.doctor)
                (Icons.monitor_heart_outlined, context.tr('استشارات نشطة','Active consultations'), numId(app.summary['activeCases']), 'C01'),
              if (app.allows(Cap.cash))
                (Icons.account_balance_wallet_outlined, context.tr('ورديات مفتوحة','Open shifts'), numId(app.summary['openShifts']), 'N03'),
            ];
            final columns = constraints.maxWidth < 335 ? 2 : metrics.length;
            return Wrap(spacing: 8, runSpacing: 8, children: [
              for (final metric in metrics)
                SizedBox(width: (constraints.maxWidth - (columns - 1) * 8) / columns,
                  child: MetricTile(label: metric.$2, value: display(context, metric.$3),
                    icon: metric.$1, onTap: () => context.open(metric.$4))),
            ]);
          }),
        if(upcoming.isNotEmpty)...[
          Heading(context.tr('مهمة قادمة','Upcoming task'),icon:Icons.calendar_month_outlined),
          Panel(onTap:()=>context.open('F02',id:numId(upcoming.first['id']),seed:upcoming.first),child:Row(children:[
            ClipRRect(borderRadius:BorderRadius.circular(13),child:Image.asset('assets/images/agent_field.webp',width:74,height:80,fit:BoxFit.cover)),
            const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(titleOf(upcoming.first),style:Theme.of(context).textTheme.titleMedium),Text(display(context,upcoming.first['scheduledDate'])),
              Text(str(upcoming.first['description']),maxLines:2,overflow:TextOverflow.ellipsis)])),const Icon(Icons.chevron_left)])),
        ],
        Heading(context.tr('إجراءات سريعة','Quick actions'),icon:Icons.bolt_outlined),
        LayoutBuilder(builder:(context,box)=>Wrap(spacing:10,runSpacing:10,children:[
          for(final action in [
            if(app.allows(34))(Icons.shopping_cart_outlined,context.tr('بيع جديد','New sale'),'T02'),
            (Icons.qr_code_scanner,context.tr('مسح رمز','Scan code'),'T03'),
            if(app.allows(1))(Icons.inventory_2_outlined,context.tr('المخزون','Inventory'),'I01'),
            if(app.allows(32))(Icons.account_balance_wallet_outlined,context.tr('الصناديق','Cashboxes'),'N01'),
            if(app.access.doctor)(Icons.medication_outlined,context.tr('الوصفات','Prescriptions'),'C12'),
            if(app.access.doctor)(Icons.calendar_today_outlined,context.tr('التقويم','Calendar'),'F03'),
          ])SizedBox(width:(box.maxWidth-10)/2,child:ActionTile(title:action.$2,icon:action.$1,onTap:()=>context.open(action.$3))),
        ])),
        if (app.access.doctor) ...[
          Heading(context.tr('ملخص الاستشارات','Consultation summary'), icon: Icons.insights_outlined),
          RingChartCard(title: context.tr('حالة الاستشارات','Case status'), values: [
            ChartValue(context.tr('استشارات جديدة','New cases'), offers.toDouble(), c.secondary),
            ChartValue(context.tr('استشارات نشطة','Active cases'), decimal(app.summary['activeCases']), c.primary),
          ]),
        ],
        if(!app.access.doctor&&app.access.grants.isEmpty)...[const SizedBox(height:16),Notice(context.tr(
          'سيظهر العمل بعد اعتماد حسابك أو منحك نطاقًا من الإدارة. يمكنك متابعة الحالة من صفحة الصلاحيات.',
          'Your work appears after professional approval or an administrative delegation. Check access status for details.'))],
      ]);
    });
  }
}
