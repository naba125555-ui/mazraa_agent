import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../application/workflows.dart';
import '../../domain/models.dart';
import '../navigation.dart';
import '../shared/charts.dart';
import '../shared/forms.dart';
import '../shared/paged_records.dart';
import '../shared/scope.dart';
import '../shared/section_banner.dart';
import '../design/agent_ui.dart';
import '../shared/widgets.dart';

class FieldPage extends StatelessWidget{
  const FieldPage(this.screen,{super.key,this.id,this.seed=const {}});final String screen;final int? id;final Json seed;
  @override Widget build(BuildContext context){final app=context.app;
    if (screen == 'F01' || screen == 'F09') {
      final tasks = screen == 'F01';
      return PagedRecords(
        key: ValueKey(app.revision),
        load: (afterId) => app.page(
          '/api/agent/field/${tasks ? 'tasks' : 'campaigns'}', afterId: afterId,
        ),
        header: [
          if (tasks)
            AgentHero(
              title: context.tr('العمل الميداني', 'Field work'),
              subtitle: context.tr('مهامك وزياراتك المسندة، حسب التاريخ والحالة.',
                'Assigned tasks and visits by date and status.'),
              art: 'assets/images/agent_field.webp',
              icon: Icons.location_on_outlined,
              emblem: 'assets/decorations/agent_medical_emblem.svg')
          else
            SectionBanner(art: SectionArt.field, icon: Icons.vaccines_outlined,
              title: context.tr('الحملات الميدانية', 'Field campaigns')),
          const SizedBox(height: 13),
          if (tasks) Wrap(spacing: 8, runSpacing: 8, children: [
            ActionChip(
              avatar: const Icon(Icons.calendar_month_outlined),
              label: Text(context.tr('التقويم', 'Calendar')),
              onPressed: () => context.open('F03')),
            ActionChip(
              avatar: const Icon(Icons.vaccines_outlined),
              label: Text(context.tr('الحملات', 'Campaigns')),
              onPressed: () => context.open('F09')),
          ]),
          AgentSectionHeading(
            title: tasks
              ? context.tr('المهام والزيارات', 'Tasks and visits')
              : context.tr('الحملات المتاحة', 'Available campaigns'),
            icon: tasks ? Icons.assignment_outlined : Icons.vaccines_outlined),
        ],
        itemBuilder: (row) => _FieldCard(
          row: row, campaign: !tasks,
          onOpen: () => context.open(tasks ? 'F02' : 'F10',
            id: numId(row['id']), seed: row)),
      );
    }
    if(screen=='F03')return const FieldCalendar();
    if(id==null)return Resource(load:()=>app.all('/api/agent/field/tasks'),builder:(data,refresh)=>PageBody(children:[
      for(final task in rows(data))for(final visit in maps(task['visits']))RecordTile(visit,onTap:()=>context.open(screen,id:numId(visit['id']),seed:visit))]));
    if(screen=='F04')return DirectionsPage(id:id!,seed:seed);
    final campaign=['F10','F11','F12'].contains(screen);
    final task=screen=='F02';
    return Resource(identity:'$screen:$id:${app.revision}',load:()=>app.record(campaign?'campaign':task?'task':'visit',id!,fresh:true),builder:(data,refresh){
      final root=obj(data),row=campaign?obj(root['campaign']):root,d=payload(row);
      if(screen=='F02')return PageBody(children: [
        AgentHero(
          title: titleOf(row),
          subtitle: context.tr('تفاصيل المهمة وإجراءات الزيارة', 'Task and visit actions'),
          art: 'assets/images/agent_field.webp',
          icon: Icons.assignment_turned_in_outlined,
          emblem: 'assets/decorations/agent_medical_emblem.svg'),
        const SizedBox(height: 14),
        AgentSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(context.tr('المهمة', 'Task') + ' #' + str(row['id']),
                style: Theme.of(context).textTheme.titleMedium)),
              if(str(row['status']).isNotEmpty) StatusTag(str(row['status'])),
            ]),
            if (row['description'] != null) ...[
              const SizedBox(height: 10),
              Text(str(row['description']), style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (row['scheduledDate'] != null) ...[
              const SizedBox(height: 8),
              Fact(context.tr('الموعد', 'Schedule'), row['scheduledDate']),
            ],
            if (row['priority'] != null)
              Fact(context.tr('الأولوية', 'Priority'), row['priority']),
          ])),
        AgentSectionHeading(title: context.tr('إجراءات المهمة', 'Task actions'),
          icon: Icons.task_alt_outlined),
        if(!['Completed','Cancelled','Rejected'].contains(row['status']))
          BusyButton(label: context.tr('تحديث حالة المهمة', 'Update task state'),
            run: () async { await openOperation(context, 'taskState', id:id, seed:row); refresh(); }),
        const SizedBox(height: 9),
        OutlinedButton.icon(onPressed: () => context.open('F04', id:id, seed:row),
          icon: const Icon(Icons.near_me_outlined),
          label: Text(context.tr('الموقع والملاحة', 'Directions'))),
        AgentSectionHeading(title: context.tr('الزيارات المرتبطة', 'Related visits'),
          icon: Icons.event_note_outlined),
        if(maps(row['visits']).isEmpty)
          AgentSurface(child: Text(context.tr('لا توجد زيارات مسجلة لهذه المهمة بعد.',
            'No visits have been registered for this task yet.'))),
        for(final visit in maps(row['visits']))
          _FieldCard(row:visit, campaign:false,
            onOpen: () => context.open('F06', id:numId(visit['id']),seed:visit)),
        if(['Accepted','InProgress'].contains(row['status'])) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await openOperation(context,'createVisit',id:id,seed:row);
              refresh();
            },
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(context.tr('إضافة زيارة', 'Add a visit'))),
        ],
      ]);
      if(screen=='F05')return VisitCheckIn(visit:row);
      if(screen=='F06')return PageBody(children:[Facts(row),Heading(context.tr('إجراءات الزيارة','Visit actions')),
        if(row['status']=='Scheduled')_FieldLink('F05',id!,Icons.location_on_outlined),
        if(row['status']=='Started')...[_FieldLink('F08',id!,Icons.monitor_heart_outlined),_FieldLink('F13',id!,Icons.task_alt)],
        _FieldLink('F07',id!,Icons.pets_outlined),
      ]);
      if(screen=='F07')return Resource(load:()async{
        final output=<Json>[];
        for(final c in await app.all('/api/vet/cases')){
          if(!['Active','Closed'].contains(c['status']))continue;
          final record=obj(await app.read('/api/vet/cases/${c['id']}/record'));
          if(maps(record['visits']).any((v)=>numId(v['id'])==id)){final detail=await app.record('case',numId(c['id']));output.add({'caseId':c['id'],...obj(detail['animal'])});}
        }return output;
      },builder:(animals,r)=>PageBody(children:[if(rows(animals).isEmpty)Empty(text:context.tr('لا يوجد حيوان مرتبط بهذه الزيارة عبر إحالة مصرح بها.','No animal is linked to this visit through an authorized referral.')),
        for(final animal in rows(animals))RecordTile(animal,icon:Icons.pets_outlined,onTap:()=>context.open('C06',id:numId(animal['caseId'])))]));
      if(screen=='F08')return OperationPage(embedded:true,operation:operations['inspection']!,id:id,seed:row,initial:seed);
      if(screen=='F13')return PageBody(children:[Facts(row),const SizedBox(height:16),
        BusyButton(label:context.tr('إكمال تقرير الزيارة','Complete visit report'),run:()async{await openOperation(context,'visitState',id:id,seed:row);refresh();}),
        const SizedBox(height:12),BusyButton(label:context.tr('مراجعة المهمة وإقفالها','Review and close task'),run:()async{
          final parent=await app.record('task',numId(row['taskId']),fresh:true);if(!context.mounted)return;
          await openOperation(context,'taskState',id:numId(parent['id']),seed:parent,initial:{'status':'Completed'});refresh();}),
      ]);
      if(screen=='F11')return OperationPage(embedded:true,operation:operations['vaccinate']!,id:id,seed:row);
      if(screen=='F12')return PageBody(children:[Facts(d),const SizedBox(height:16),
        BusyButton(label:context.tr('تسجيل حرارة الدفعة','Record batch temperature'),run:()async{await openOperation(context,'temperature',id:id,seed:row);refresh();}),
        const SizedBox(height:12),BusyButton(label:context.tr('توثيق هدر أو إرجاع','Record waste or return'),run:()async{await openOperation(context,'vaccinate',id:id,seed:row,initial:{'outcome':'waste'});refresh();}),
        Heading(context.tr('مطابقة العهدة','Custody reconciliation')),
        Resource(embedded:true,load:()=>app.read('/api/agent/field/campaigns/$id/reconciliation'),builder:(result,r)=>Column(children:[Facts(obj(result)),
          for(final key in ['allocations','outcomes','temperatures','stops'])...[
            Heading(context.tr(key=='allocations'?'الدفعات المخصصة':key=='outcomes'?'النتائج':key=='temperatures'?'سجل الحرارة':'المحطات',key)),
            for(final item in maps(obj(result)[key]))Padding(padding:const EdgeInsets.only(bottom:10),child:Facts(payload(item)))],
        ])),
      ]);
      final c=Theme.of(context).colorScheme;
      return PageBody(children:[Facts(d),const SizedBox(height:16),
        RingChartCard(title:context.tr('تقدم التلقيح','Vaccination progress'),values:[
          ChartValue(context.tr('حيوانات موثقة','Recorded animals'),decimal(root['animals']),c.primary),
          ChartValue(context.tr('المتبقي من المستهدف','Remaining target'),(decimal(d['targetAnimals'])-decimal(root['animals'])).clamp(0,double.infinity).toDouble(),c.secondary)]),
        Heading(context.tr('إجراءات الحملة','Campaign actions')),
        _FieldLink('F11',id!,Icons.vaccines_outlined),_FieldLink('F12',id!,Icons.thermostat_outlined),
        BusyButton(label:context.tr('حالة الحملة والتقرير','Campaign state and report'),run:()async{await openOperation(context,'campaignState',id:id,seed:row);refresh();}),
      ]);
    });
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.row, required this.campaign,
    required this.onOpen});
  final Json row;
  final bool campaign;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final date = row['scheduledDate'] ?? payload(row)['scheduledAt'];
    final status = str(row['status']);
    final title = titleOf(row);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AgentSurface(onTap: onOpen, padding: const EdgeInsets.all(13),
        child: Row(children: [
          Container(width: 52, height: 52,
            decoration: BoxDecoration(
              color: campaign
                ? AgentPalette.violet.withValues(alpha: .11) : AgentPalette.mint,
              borderRadius: BorderRadius.circular(16)),
            child: Icon(campaign ? Icons.vaccines_outlined
              : Icons.location_on_outlined,
              color: campaign ? AgentPalette.violet : AgentPalette.forest,
              size: 27)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge),
              if(date != null)
                Text(display(context,date), maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
              if(status.isNotEmpty) ...[
                const SizedBox(height: 4),
                StatusTag(status),
              ],
            ])),
          Icon(Directionality.of(context) == TextDirection.rtl
            ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.primary),
        ]),
      ),
    );
  }
}

class _FieldLink extends StatelessWidget{
  const _FieldLink(this.route,this.id,this.icon);final String route;final int id;final IconData icon;
  @override Widget build(BuildContext context){final titles={
    'F05':[context.tr('بدء الزيارة','Start visit')],'F07':[context.tr('حيوانات الزيارة','Visit animals')],
    'F08':[context.tr('فحص الحيوان','Animal examination')],'F13':[context.tr('إنهاء الزيارة','Complete visit')],
    'F11':[context.tr('تسجيل التلقيح','Record vaccination')],'F12':[context.tr('التبريد والعهدة','Cold chain and custody')]};
    return RecordTile({'title':titles[route]!.first},icon:icon,onTap:()=>context.open(route,id:id));}
}
class FieldCalendar extends StatefulWidget{
  const FieldCalendar({super.key});
  @override State<FieldCalendar> createState()=>_FieldCalendarState();
}
class _FieldCalendarState extends State<FieldCalendar>{
  DateTime selected=DateTime.now();
  @override Widget build(BuildContext context)=>Resource(load:()=>context.app.all('/api/agent/field/tasks'),builder:(data,refresh)=>PageBody(children:[
    Panel(child:CalendarDatePicker(initialDate:selected,firstDate:DateTime(2020),lastDate:DateTime(DateTime.now().year+5),onDateChanged:(v)=>setState(()=>selected=v))),
    Heading(context.tr('مواعيد اليوم المختار','Selected day')),
    for(final task in rows(data).where((t){final date=DateTime.tryParse(str(t['scheduledDate']))?.toLocal();return date!=null&&date.year==selected.year&&date.month==selected.month&&date.day==selected.day;}))
      RecordTile(task,onTap:()=>context.open('F02',id:numId(task['id']))),
  ]));
}
Future<Position> currentPosition()async{
  if(!await Geolocator.isLocationServiceEnabled())throw const Failure(422,'Location service is disabled.');
  var permission=await Geolocator.checkPermission();if(permission==LocationPermission.denied)permission=await Geolocator.requestPermission();
  if(permission==LocationPermission.denied||permission==LocationPermission.deniedForever)throw const Failure(403,'');
  return Geolocator.getCurrentPosition(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high,timeLimit:Duration(seconds:20)));
}
class VisitCheckIn extends StatefulWidget{
  const VisitCheckIn({super.key,required this.visit});final Json visit;
  @override State<VisitCheckIn> createState()=>_VisitCheckInState();
}
class _VisitCheckInState extends State<VisitCheckIn>{
  Json coordinates={};
  @override Widget build(BuildContext context)=>PageBody(children:[Facts(widget.visit),const SizedBox(height:16),
    Notice(context.tr('وثق موقع الوصول قبل بدء المعاينة.','Record your arrival location before starting the visit.')),
    const SizedBox(height:16),BusyButton(icon:Icons.my_location,label:context.tr('تحديد موقعي الحالي','Use my current location'),run:()async{final p=await currentPosition();setState(()=>coordinates={'latitude':p.latitude,'longitude':p.longitude});}),
    if(coordinates.isNotEmpty)...[const SizedBox(height:12),Facts(coordinates)],const SizedBox(height:16),
    BusyButton(label:context.tr('بدء الزيارة','Start visit'),run:()async{await openOperation(context,'visitState',id:numId(widget.visit['id']),seed:widget.visit,initial:coordinates);}),
  ]);
}
class DirectionsPage extends StatelessWidget{
  const DirectionsPage({super.key,required this.id,this.seed=const {}});final int id;final Json seed;
  @override Widget build(BuildContext context)=>Resource(load:()=>context.app.record('task',id,fresh:true),builder:(data,refresh){
    final task=obj(data),visit=maps(task['visits']).where((v)=>v['latitude']!=null&&v['longitude']!=null).firstOrNull;
    final latitude=seed['latitude']??visit?['latitude'],longitude=seed['longitude']??visit?['longitude'];
    final address=str(task['description']);
    return PageBody(children:[Panel(child:Column(children:[Icon(Icons.location_on_outlined,size:68,color:Theme.of(context).colorScheme.primary),
      const SizedBox(height:16),Text(titleOf(task),style:Theme.of(context).textTheme.titleLarge),Text(address),
      if(latitude!=null)...[Fact('latitude',latitude),Fact('longitude',longitude)]])),const SizedBox(height:16),
      if(latitude==null&&address.isEmpty)Notice(context.tr('لم يُحدد عنوان أو إحداثيات لهذه المهمة بعد.','No destination has been set for this task.')),
      if(latitude!=null||address.isNotEmpty)BusyButton(icon:Icons.navigation_outlined,label:context.tr('فتح الملاحة','Open navigation'),run:()async{
        final destination=latitude==null?address:'$latitude,$longitude';
        if(!await launchUrl(Uri.https('www.google.com','/maps/dir/',{'api':'1','destination':destination}),mode:LaunchMode.externalApplication))throw const Failure(422,'');}),
    ]);
  });
}
