import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../application/agent_app.dart';
import '../../application/workflows.dart';
import '../../domain/models.dart';
import '../navigation.dart';
import '../shared/forms.dart';
import '../shared/paged_records.dart';
import '../shared/scope.dart';
import '../shared/section_banner.dart';
import '../design/agent_ui.dart';
import '../shared/widgets.dart';

class ClinicalPage extends StatelessWidget{
  const ClinicalPage(this.screen,{super.key,this.id,this.seed=const {}});
  final String screen;final int? id;final Json seed;
  @override Widget build(BuildContext context){final app=context.app;
    if (screen == 'C01') return const ConsultationsOverview();
    if((screen=='C12'||screen=='C13'||screen=='C14')&&id==null)return Resource(load:()=>app.all('/api/vet/prescriptions'),builder:(data,refresh)=>PageBody(children:[
      if(rows(data).isEmpty)const Empty(),for(final row in rows(data).reversed)RecordTile(row,icon:Icons.medication_outlined,onTap:()=>context.open(screen,id:numId(row['id'])))]));
    if(id==null)return const Empty();
    if(screen=='C03')return Resource(load:()=>app.all('/api/vet/cases/$id/shared-ai'),builder:(data,refresh)=>PageBody(children:[
      Notice(context.tr('هذا السجل مشترك بموافقة العميل حتى الحد الذي اختاره.','This history is shared with customer consent up to their selected cutoff.')),
      const SizedBox(height:16),if(rows(data).isEmpty)const Empty(),for(final row in rows(data))Padding(padding:const EdgeInsets.only(bottom:12),child:Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(row['role']=='assistant'?context.tr('المساعد الذكي','AI assistant'):context.tr('العميل','Customer'),style:Theme.of(context).textTheme.titleMedium),
        const SizedBox(height:7),SelectableText(str(row['content'])),Text(display(context,row['createdAt']),style:Theme.of(context).textTheme.bodySmall)]))),
    ]));
    if(screen=='C04')return ConsultationChat(caseId:id!);
    if(screen=='C05')return CaseAttachments(caseId:id!);
    if(screen=='C11')return OperationPage(embedded:true,operation:operations['prescribe']!,seed:{'caseId':id},initial:app.prescriptionDraft);
    final rx=['C12','C13','C14'].contains(screen);
    return Resource(identity:'$screen:$id:${app.revision}',load:()=>app.record(rx?'prescription':'case',id!,fresh:true),builder:(data,refresh){
      final row=obj(data),d=payload(row),versioned=rx?row:d;
      if(screen=='C02')return _ConsultationDetail(id:id!, row:row, refresh:refresh);
      if(screen=='C06'||screen=='C07')return PageBody(children:[
        Facts(obj(row['animal'])),const SizedBox(height:14),Notice(context.tr('الحيوان مرتبط بإحالة العميل. لتقييم حيوان آخر، يرسل العميل إحالة جديدة.','The animal is linked to this customer referral. Another animal requires a separate customer referral.')),
        Heading(context.tr('الفحوص والزيارات','Examinations and visits')),
        Resource(embedded:true,load:()=>app.read('/api/vet/cases/$id/record'),builder:(data,refresh)=>Column(children:[
          for(final visit in maps(obj(data)['visits']))RecordTile(visit,icon:Icons.assignment_outlined,onTap:()=>context.open('F06',id:numId(visit['id']),seed:visit)),
          for(final inspection in maps(obj(data)['inspections']))Padding(padding:const EdgeInsets.only(bottom:10),child:Facts(inspection)),
        ])),
      ]);
      if(screen=='C08')return PageBody(children:[
        FilledButton.icon(onPressed:()=>openOperation(context,'note',id:id,seed:versioned),icon:const Icon(Icons.add),label:Text(context.tr('ملاحظة سريرية جديدة','New clinical note'))),
        Heading(context.tr('الملاحظات السابقة','Previous notes')),
        Resource(embedded:true,load:()=>app.read('/api/vet/cases/$id/record'),builder:(record,r)=>Column(children:[for(final note in maps(obj(record)['notes']))Padding(padding:const EdgeInsets.only(bottom:12),child:Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(str(payload(note)['body'])),Fact('createdAt',note['createdAt']),Text(payload(note)['sharedWithCustomer']==true?context.tr('مشتركة مع العميل','Shared with customer'):context.tr('خاصة بالطبيب','Doctor private')),
          TextButton(onPressed:()=>openOperation(context,'note',id:id,seed:versioned,initial:{'amendsId':note['id']}),child:Text(context.tr('إضافة ملحق مؤرخ','Add a dated addendum'))),
        ])))])),
      ]);
      if(screen=='C09'||screen=='C15'||screen=='C16')return OperationPage(embedded:true,operation:operations[screen=='C09'?'appointment':screen=='C15'?'workflow':'closeCase']!,id:id,seed:versioned);
      if(screen=='C10')return PrescriptionDraft(caseId:id!,seed:versioned);
      if(screen=='C13')return OperationPage(embedded:true,operation:operations['dispense']!,id:id,seed:versioned,initial:{'customerId':row['customerId']});
      if(screen=='C14')return Resource(load:()=>app.all('/api/vet/prescription-orders',query:app.scoped()),builder:(orders,r)=>PageBody(children:[
        Notice(context.tr('يقبل العميل عرض الوصفة من تطبيقه. تظهر هنا طلبات الصرف المصرح لك بها.','The customer accepts the prescription in their app. Authorized dispensing orders appear here.')),
        for(final order in rows(orders))RecordTile(order,onTap:()=>openOperation(context,'releasePrescription',id:numId(payload(order)['orderId']),seed:order)),
      ]));
      return PageBody(children:[Facts(d),Heading(context.tr('الأدوية والكميات','Medicines and quantities')),
        for(final line in maps(d['lines']))Padding(padding:const EdgeInsets.only(bottom:12),child:Facts(line)),
        if(app.allows(290)&&app.access.dispenser)_RouteTile('C13',Icons.medication_outlined,id:id),
        _RouteTile('C14',Icons.receipt_long_outlined,id:id),
        if(row['ownerId']==app.repo.session?.userId&&row['status']=='Approved')OutlinedButton(onPressed:()=>openOperation(context,'cancelPrescription',id:id,seed:row),child:Text(context.tr('إلغاء الوصفة','Cancel prescription'))),
      ]);
    });
  }
}
/// C01 — server-paginated consultation queue. Text filters operate on fetched
/// authorized data; opening a card is the only trigger for a details GET.
class ConsultationsOverview extends StatefulWidget {
  const ConsultationsOverview({super.key});
  @override
  State<ConsultationsOverview> createState() => _ConsultationsOverviewState();
}

class _ConsultationsOverviewState extends State<ConsultationsOverview> {
  final search = TextEditingController();
  String filter = 'all';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  bool matches(Json row) {
    final status = str(row['status']).toLowerCase();
    final permittedStatus = switch (filter) {
      'new' => status == 'assigned' || status == 'requested',
      'active' => status == 'active' || status == 'consulting',
      'done' => status == 'closed' || status == 'cancelled',
      _ => true,
    };
    if (!permittedStatus) return false;
    final term = search.text.trim().toLowerCase();
    if (term.isEmpty) return true;
    final animal = obj(row['animal']);
    return [
      row['id'], row['animalName'], animal['name'], row['caseNumber'],
      row['status'], row['customerName'],
    ].any((v) => str(v).toLowerCase().contains(term));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final chips = [
      ('all', context.tr('الكل', 'All')),
      ('new', context.tr('جديدة', 'New')),
      ('active', context.tr('قيد المتابعة', 'Active')),
      ('done', context.tr('منتهية', 'Closed')),
    ];
    return PagedRecords(
      key: ValueKey('${app.revision}:$filter:${search.text}'),
      load: (afterId) => app.page('/api/vet/cases', afterId: afterId),
      include: matches,
      header: [
        AgentHero(
          title: context.tr('الاستشارات البيطرية', 'Veterinary consultations'),
          subtitle: context.tr(
            'الإحالات الطبية، سجلات الفحص، الوصفات والمتابعة.',
            'Referrals, examinations, prescriptions and follow-up.'),
          art: 'assets/images/agent_clinical.webp',
          icon: Icons.medical_services_outlined),
        const SizedBox(height: 16),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: context.tr('ابحث برقم الاستشارة أو الحيوان',
              'Search by case or animal'),
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: search.text.isEmpty ? null : IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () { search.clear(); setState(() {}); })),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 7, runSpacing: 7, children: [
          for (final entry in chips)
            ChoiceChip(
              label: Text(entry.$2),
              selected: filter == entry.$1,
              onSelected: (_) => setState(() => filter = entry.$1),
              selectedColor: AgentPalette.mint),
        ]),
        const SizedBox(height: 15),
        AgentSurface(
          onTap: () => context.open('C12'),
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Icon(Icons.medication_outlined, color: AgentPalette.forest),
            const SizedBox(width: 12),
            Expanded(child: Text(context.tr('الوصفات وطلبات الصرف',
              'Prescriptions and dispensing'),
              style: Theme.of(context).textTheme.labelLarge)),
            Icon(Directionality.of(context) == TextDirection.rtl
              ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
          ])),
        AgentSectionHeading(title: context.tr('قائمة الاستشارات', 'Consultation queue'),
          icon: Icons.format_list_bulleted_rounded),
      ],
      itemBuilder: (row) => _ConsultationTile(caseRow: row),
    );
  }
}

class _ConsultationTile extends StatelessWidget {
  const _ConsultationTile({required this.caseRow});
  final Json caseRow;

  @override
  Widget build(BuildContext context) {
    final id = numId(caseRow['id']);
    final status = str(caseRow['status']);
    final animal = obj(caseRow['animal']);
    final named = str(caseRow['animalName'] ?? animal['name']);
    final title = named.isEmpty
      ? '${context.tr('استشارة', 'Consultation')} #$id' : named;
    final subtitle = str(caseRow['customerName']);
    final latest = caseRow['updatedAt'] ?? caseRow['createdAt'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AgentSurface(
        onTap: id == 0 ? null : () => context.open('C02', id: id, seed: caseRow),
        child: Row(children: [
          Container(height: 55, width: 55,
            decoration: BoxDecoration(color: AgentPalette.mint,
              borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.pets_outlined,
              color: AgentPalette.forest, size: 28)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge),
              if (subtitle.isNotEmpty) Text(subtitle, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Row(children: [
                if (status.isNotEmpty) StatusTag(status),
                if (latest != null) ...[
                  const SizedBox(width: 6),
                  Flexible(child: Text(display(context, latest),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall)),
                ],
              ]),
            ])),
          Icon(Directionality.of(context) == TextDirection.rtl
            ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            color: AgentPalette.forest),
        ]),
      ),
    );
  }
}

/// C02 — a clinical workflow dashboard, not a dump of raw JSON fields.
class _ConsultationDetail extends StatelessWidget {
  const _ConsultationDetail({required this.id, required this.row,
    required this.refresh});
  final int id;
  final Json row;
  final VoidCallback refresh;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final detail = payload(row);
    final animal = obj(row['animal']);
    final customer = obj(row['customer']);
    final status = str(detail['status'] ?? row['status']);
    final name = str(animal['name']);
    final assigned = status.toLowerCase() == 'assigned';
    final actions = [
      ('C03', context.tr('السجل المشترك', 'Shared history'), Icons.auto_awesome_outlined, AgentPalette.violet),
      ('C04', context.tr('محادثة العميل', 'Customer chat'), Icons.chat_bubble_outline_rounded, AgentPalette.blue),
      ('C05', context.tr('المرفقات', 'Attachments'), Icons.attach_file_rounded, AgentPalette.amber),
      ('C06', context.tr('ملف الحيوان', 'Animal record'), Icons.pets_outlined, AgentPalette.forest),
      ('C08', context.tr('التقييم الطبي', 'Clinical notes'), Icons.edit_note_rounded, AgentPalette.emerald),
      ('C09', context.tr('طلب زيارة', 'Schedule visit'), Icons.event_rounded, AgentPalette.blue),
      ('C10', context.tr('إصدار وصفة', 'Issue prescription'), Icons.medication_outlined, AgentPalette.forest),
      ('C15', context.tr('المتابعة', 'Follow-up'), Icons.monitor_heart_outlined, AgentPalette.violet),
      ('C16', context.tr('إغلاق الحالة', 'Close case'), Icons.task_alt_rounded, AgentPalette.amber),
    ];

    return PageBody(children: [
      AgentHero(
        title: name.isEmpty ? context.tr('تفاصيل الاستشارة البيطرية',
          'Veterinary consultation details') : name,
        subtitle: context.tr('المعلومات الطبية والقرارات في مسار واحد.',
          'Medical record and next steps in one workspace.'),
        art: 'assets/images/agent_clinical.webp',
        icon: Icons.stethoscope_outlined),
      const SizedBox(height: 13),
      AgentSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('${context.tr('الاستشارة', 'Case')} #$id',
              style: Theme.of(context).textTheme.titleMedium)),
            if (status.isNotEmpty) StatusTag(status),
          ]),
          if (detail['reason'] != null) ...[
            const SizedBox(height: 10),
            Text(context.tr('سبب الاستشارة', 'Reason'),
              style: Theme.of(context).textTheme.bodySmall),
            Text(str(detail['reason']),
              style: Theme.of(context).textTheme.bodyLarge),
          ],
          if (detail['version'] != null || row['version'] != null) ...[
            const SizedBox(height: 8),
            Text('${context.tr('إصدار السجل', 'Record version')}: ${detail['version'] ?? row['version']}',
              style: Theme.of(context).textTheme.bodySmall),
          ],
        ])),
      AgentSectionHeading(title: context.tr('العميل والحيوان', 'Customer and animal'),
        icon: Icons.pets_outlined),
      AgentSurface(child: Column(children: [
        if (customer['name'] != null) Fact(context.tr('العميل', 'Customer'), customer['name']),
        if (customer['phone'] != null) Fact(context.tr('الهاتف', 'Phone'), customer['phone']),
        if (animal['name'] != null) Fact(context.tr('الحيوان', 'Animal'), animal['name']),
        if (animal['species'] != null) Fact(context.tr('النوع', 'Species'), animal['species']),
        if (animal['breed'] != null) Fact(context.tr('السلالة', 'Breed'), animal['breed']),
        if (animal['age'] != null) Fact(context.tr('العمر', 'Age'), animal['age']),
        if (customer.isEmpty && animal.isEmpty)
          Text(context.tr('لا تتوفر معلومات إضافية لهذا السجل.',
            'No additional details were provided for this record.')),
      ])),
      if (assigned) ...[
        AgentSectionHeading(title: context.tr('قرار التكليف', 'Assignment decision'),
          icon: Icons.assignment_turned_in_outlined),
        Notice(context.tr(
          'قبول هذه الإحالة يتيح الانتقال إلى الملاحظات والمحادثة وفق الصلاحيات الحالية.',
          'Accepting this case opens clinical activities within your permissions.')),
        const SizedBox(height: 14),
        BusyButton(
          label: context.tr('قبول الاستشارة', 'Accept consultation'),
          run: () async {
            await openOperation(context, 'accept', id: id,
              seed: detail); refresh();
          }),
        const SizedBox(height: 9),
        OutlinedButton.icon(
          onPressed: () async {
            await openOperation(context, 'decline', id: id,
              seed: detail); refresh();
          },
          icon: const Icon(Icons.close_outlined),
          label: Text(context.tr('الاعتذار عن التكليف', 'Decline assignment'))),
      ] else ...[
        AgentSectionHeading(title: context.tr('إدارة الحالة', 'Case workflow'),
          icon: Icons.dashboard_customize_outlined),
        LayoutBuilder(builder: (context, width) {
          final columns = width.maxWidth > 390 ? 3 : 2;
          final cell = (width.maxWidth - 10 * (columns - 1)) / columns;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (final entry in actions)
              SizedBox(width: cell, child: AgentAction(
                title: entry.$2, icon: entry.$3, color: entry.$4,
                onTap: () => context.open(entry.$1, id: id))),
          ]);
        }),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: refresh,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.tr('تحديث بيانات الاستشارة', 'Refresh case'))),
      ],
    ]);
  }
}

class _RouteTile extends StatelessWidget{
  const _RouteTile(this.route,this.icon,{this.id});
  final String route;final IconData icon;final int? id;
  @override Widget build(BuildContext context){const titles={
    'C03':['سجل المساعد','AI history'],'C04':['محادثة العميل','Customer chat'],'C05':['مرفقات الحالة','Attachments'],
    'C06':['ملف الحيوان','Animal record'],'C08':['التقييم والملاحظات','Assessment and notes'],'C09':['موعد وزيارة','Schedule a visit'],
    'C10':['وصفة جديدة','New prescription'],'C13':['صرف الدواء','Dispense medicine'],'C14':['طلبات الوصفة','Prescription orders'],
    'C15':['المتابعة','Follow-up'],'C16':['إغلاق الحالة','Close case']};final t=titles[route]!;
    return RecordTile({'title':context.tr(t[0],t[1])},icon:icon,onTap:()=>context.open(route,id:id));}
}
class PrescriptionDraft extends StatefulWidget{
  const PrescriptionDraft({super.key,required this.caseId,required this.seed});final int caseId;final Json seed;
  @override State<PrescriptionDraft> createState()=>_PrescriptionDraftState();
}
class _PrescriptionDraftState extends State<PrescriptionDraft>{
  final form=GlobalKey<FormState>();final Json values={};
  @override Widget build(BuildContext context)=>Form(key:form,child:PageBody(children:[Notice(context.tr('أدخل الأدوية وفق التقييم وسياسة البلد. تُراجع الوصفة قبل التوقيع.','Choose medicines according to the assessment and jurisdiction. Review the prescription before signing.')),
    const SizedBox(height:16),for(final f in operations['prescribe']!.fields)Padding(padding:const EdgeInsets.only(bottom:14),child:InputControl(spec:f,value:values[f.key],onChanged:(v)=>setState(()=>values[f.key]=v))),
    FilledButton(onPressed:(){if(!form.currentState!.validate())return;form.currentState!.save();context.app.prescriptionDraft={...values};context.open('C11',id:widget.caseId);},child:Text(context.tr('مراجعة الوصفة','Review prescription'))),
  ]));
}
class ConsultationChat extends StatefulWidget{
  const ConsultationChat({super.key,required this.caseId});final int caseId;
  @override State<ConsultationChat> createState()=>_ConsultationChatState();
}
class _ConsultationChatState extends State<ConsultationChat> with WidgetsBindingObserver{
  final text=TextEditingController();List<Json> messages=[];Timer? timer;bool sending=false,loading=true,refreshing=false;Object? error;
  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);WidgetsBinding.instance.addPostFrameCallback((_){load();timer=Timer.periodic(const Duration(seconds:5),(_)=>load());});}
  @override void dispose(){timer?.cancel();WidgetsBinding.instance.removeObserver(this);text.dispose();super.dispose();}
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state!=AppLifecycleState.resumed){timer?.cancel();}else{load();timer=Timer.periodic(const Duration(seconds:5),(_)=>load());}}
  Future<void> load()async{
    if(!mounted||refreshing)return;refreshing=true;
    try{final all=await context.app.all('/api/vet/cases/${widget.caseId}/messages');if(mounted)setState((){messages=all;error=null;loading=false;});}
    catch(e){if(mounted)setState((){error=e;loading=false;if(e is Failure&&(e.status==403||e.status==404))messages=[];});}
    finally{refreshing=false;}
  }
  @override Widget build(BuildContext context)=>Column(children:[
    if(loading)const LinearProgressIndicator(),if(error!=null)Notice(failureText(context,error!),error:true),
    Expanded(child:ListView.builder(padding:const EdgeInsets.all(18),itemCount:messages.length,itemBuilder:(c,i){final m=messages[i],mine=m['senderId']==context.app.repo.session?.userId;
      return Align(alignment:mine?AlignmentDirectional.centerEnd:AlignmentDirectional.centerStart,child:Container(constraints:BoxConstraints(maxWidth:MediaQuery.sizeOf(context).width*.8),
        padding:const EdgeInsets.all(14),margin:const EdgeInsets.only(bottom:12),decoration:BoxDecoration(color:mine?Theme.of(context).colorScheme.primaryContainer:Theme.of(context).colorScheme.surface,
          borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[SelectableText(str(m['body'])),Text(display(context,m['createdAt']),style:Theme.of(context).textTheme.bodySmall)])));})),
    SafeArea(top:false,child:Padding(padding:const EdgeInsets.all(12),child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
      IconButton(onPressed:()=>context.open('C05',id:widget.caseId),icon:const Icon(Icons.attach_file)),
      Expanded(child:TextField(controller:text,maxLines:4,minLines:1,maxLength:4000,decoration:InputDecoration(counterText:'',hintText:context.tr('اكتب ردك','Write your reply')))),
      IconButton(onPressed:sending?null:()async{
        if(text.text.trim().isEmpty)return;setState(()=>sending=true);
        try{await context.app.execute('/api/vet/cases/${widget.caseId}/messages',{'body':text.text.trim()},title:context.tr('رسالة استشارة','Consultation message'));text.clear();await load();}
        catch(e){if(context.mounted)toast(context,failureText(context,e));}finally{if(mounted)setState(()=>sending=false);}
      },icon:sending?const SizedBox.square(dimension:20,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_outlined)),
    ]))),
  ]);
}
class CaseAttachments extends StatelessWidget{
  const CaseAttachments({super.key,this.caseId=0,this.recordId});final int caseId;final int? recordId;
  String get endpoint=>recordId==null?'/api/vet/cases/$caseId/attachments':'/api/agent/mobile/records/$recordId/files';
  @override Widget build(BuildContext context)=>Resource(load:()=>context.app.read(endpoint),builder:(data,refresh)=>PageBody(children:[
    Notice(context.tr('صور وملفات PDF، حتى 5 ميجابايت للملف. تُعرض داخل الحساب المصرح له فقط.','Images and PDFs, up to 5 MiB per file. Access is limited to authorized participants.')),
    const SizedBox(height:16),BusyButton(icon:Icons.upload_file,label:context.tr('رفع مرفق','Upload attachment'),run:()async{
      final files=await FilePicker.pickFiles(type:FileType.custom,allowedExtensions:['jpg','jpeg','png','pdf'],withData:true);
      if(files==null||files.files.single.bytes==null||!context.mounted)return;final f=files.files.single;
      if(f.size>5*1024*1024)throw const Failure(422,'Maximum file size: 5 MiB');
      await context.app.repo.upload(endpoint,f.name,f.bytes!,{'requestId':uuid()});refresh();
    }),
    const SizedBox(height:10),BusyButton(icon:Icons.photo_camera_outlined,label:context.tr('التقاط صورة','Take a photo'),run:()async{
      final image=await ImagePicker().pickImage(source:ImageSource.camera,maxWidth:1600,imageQuality:82);if(image==null||!context.mounted)return;
      await context.app.repo.upload(endpoint,image.name,await image.readAsBytes(),{'requestId':uuid()});refresh();
    }),
    Heading(context.tr('المرفقات','Attachments')),for(final f in rows(data))RecordTile(f,icon:Icons.attach_file,onTap:()async{
      try{final bytes=await context.app.repo.download(recordId==null?'/api/vet/cases/$caseId/attachments/${f['id']}':'/api/agent/mobile/files/${f['id']}');if(!context.mounted)return;
        if(str(f['contentType']).startsWith('image/'))showDialog<void>(context:context,builder:(c)=>Dialog(child:InteractiveViewer(child:Image.memory(bytes))));
        else{final directory=await getTemporaryDirectory();final file=File('${directory.path}/agent-${uuid()}.pdf');await file.writeAsBytes(bytes,flush:true);await OpenFilex.open(file.path);}
      }catch(e){if(context.mounted)toast(context,failureText(context,e));}
    }),
  ]));
}
