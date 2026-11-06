import 'package:flutter/material.dart';
import '../../domain/models.dart';
import '../navigation.dart';
import '../shared/charts.dart';
import '../shared/scope.dart';
import '../shared/widgets.dart';

class HomePage extends StatelessWidget{
  const HomePage({super.key});
  @override Widget build(BuildContext context){final app=context.app,c=Theme.of(context).colorScheme;
    return Resource(identity:'home:${app.revision}',load:()async{
      final cases=app.access.doctor?await app.all('/api/vet/cases'):<Json>[];
      final tasks=app.access.doctor?await app.all('/api/agent/field/tasks'):<Json>[];
      final pickups=app.allows(Cap.pickup)?await app.all('/api/agent/pickup/requests',query:app.scoped()):<Json>[];
      return {'cases':cases,'tasks':tasks,'pickups':pickups};
    },builder:(data,refresh){
      final cases=maps(obj(data)['cases']),tasks=maps(obj(data)['tasks']),pickups=maps(obj(data)['pickups']);
      final offers=cases.where((r)=>r['status']=='Assigned').toList();
      final upcoming=tasks.where((r)=>!['Completed','Cancelled','Rejected'].contains(r['status'])).toList()
        ..sort((a,b)=>str(a['scheduledDate']).compareTo(str(b['scheduledDate'])));
      final current=payload(obj(app.profile['profile']));
      final name=str(app.user['name']??obj(app.profile['user'])['name']);
      return PageBody(children:[
        const SizedBox(height:6),Text('${context.tr('مرحبًا،','Welcome,')} $name',style:Theme.of(context).textTheme.headlineSmall),
        Text(context.tr('مزرعتي · الطبيب والوكيل','Mazraa · Doctor and agent'),style:TextStyle(color:c.onSurfaceVariant)),const SizedBox(height:14),
        Wrap(spacing:10,runSpacing:8,children:[
          ActionChip(avatar:const Icon(Icons.storefront_outlined,size:19),label:Text(app.grant==null?context.tr('نطاق العمل','Work context'):
            '${context.tr('المخزن','Warehouse')} #${app.grant!.warehouse}'),onPressed:()=>context.open('H06')),
          if(app.access.doctor)ActionChip(avatar:Icon(Icons.circle,size:10,color:current['isAvailable']==true?c.primary:c.secondary),
            label:Text(current['isAvailable']==true?context.tr('متاح للاستشارات','Available'):context.tr('غير متاح','Unavailable')),
            onPressed:()async{try{await app.repo.write('PATCH','/api/agent/availability',{'available':current['isAvailable']!=true});await app.refreshAccess();}
              catch(e){if(context.mounted)toast(context,failureText(context,e));}}),
        ]),const SizedBox(height:16),
        LayoutBuilder(builder:(context,box)=>Wrap(spacing:10,runSpacing:10,children:[
          for(final metric in [
            (Icons.chat_bubble_outline,offers.length,context.tr('استشارات جديدة','New cases'),'C01'),
            (Icons.assignment_outlined,upcoming.length,context.tr('مهام مفتوحة','Open tasks'),'F01'),
            (Icons.inventory_2_outlined,pickups.where((p)=>p['status']=='Active').length,context.tr('طلبات جاهزة','Ready pickups'),'P02')])
            SizedBox(width:(box.maxWidth-20)/3,child:Panel(padding:const EdgeInsets.all(12),onTap:()=>context.open(metric.$4),child:Column(children:[
              Icon(metric.$1,color:c.primary,size:28),const SizedBox(height:5),Text(display(context,metric.$2),style:Theme.of(context).textTheme.headlineSmall),
              Text(metric.$3,style:const TextStyle(fontSize:11),textAlign:TextAlign.center,maxLines:2)]))),
        ])),
        if(offers.isNotEmpty)...[
          Heading(context.tr('بانتظار ردك','Waiting for your response'),icon:Icons.auto_awesome_outlined),
          Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            StatusTag('Assigned'),const SizedBox(height:14),Row(children:[
              Container(width:70,height:70,decoration:BoxDecoration(color:c.primaryContainer,borderRadius:BorderRadius.circular(16)),child:Icon(Icons.chat_bubble_outline,size:38,color:c.primary)),
              const SizedBox(width:16),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(context.tr('استشارة بيطرية','Veterinary consultation'),style:Theme.of(context).textTheme.titleLarge),Text('#${offers.first['id']}')]))]),
            const SizedBox(height:16),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>context.open('C02',id:numId(offers.first['id'])),
              icon:const Icon(Icons.arrow_forward),label:Text(context.tr('مراجعة الاستشارة','Review consultation')))),
          ])),
        ],
        if(upcoming.isNotEmpty)...[
          Heading(context.tr('مهمتك القادمة','Your next task'),icon:Icons.calendar_month_outlined),
          Panel(onTap:()=>context.open('F02',id:numId(upcoming.first['id'])),child:Row(children:[
            ClipRRect(borderRadius:BorderRadius.circular(13),child:Image.asset('assets/images/veterinary_vaccine.webp',width:74,height:80,fit:BoxFit.cover)),
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
          ])SizedBox(width:(box.maxWidth-10)/2,child:Panel(onTap:()=>context.open(action.$3),child:Row(children:[
            Icon(action.$1,color:c.primary),const SizedBox(width:10),Expanded(child:Text(action.$2))]))),
        ])),
        Heading(context.tr('ملخص النشاط','Activity summary'),icon:Icons.insights_outlined),
        RingChartCard(title:context.tr('الاستشارات والمهام','Cases and tasks'),values:[
          ChartValue(context.tr('استشارات نشطة','Active cases'),decimal(app.summary['activeCases']),c.primary),
          ChartValue(context.tr('مهام مفتوحة','Open tasks'),upcoming.length.toDouble(),c.secondary),
          ChartValue(context.tr('مهام مكتملة','Completed tasks'),tasks.where((t)=>t['status']=='Completed').length.toDouble(),c.tertiary)]),
        if(!app.access.doctor&&app.access.grants.isEmpty)...[const SizedBox(height:16),Notice(context.tr(
          'سيظهر العمل بعد اعتماد حسابك أو منحك نطاقًا من الإدارة. يمكنك متابعة الحالة من صفحة الصلاحيات.',
          'Your work appears after professional approval or an administrative delegation. Check access status for details.'))],
      ]);
    });
  }
}
