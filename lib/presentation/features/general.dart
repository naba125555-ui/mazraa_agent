import 'dart:convert';
import 'package:flutter/material.dart';
import '../../domain/models.dart';
import '../../domain/screens.dart';
import '../navigation.dart';
import '../shared/scope.dart';
import '../shared/widgets.dart';
import '../shared/section_banner.dart';
import '../design/agent_ui.dart';
import '../shared/forms.dart';

Future<Json?> _editProfile(BuildContext context)=>openOperation(context,'profile',seed:context.app.user,initial:context.app.user);
Future<Json?> _changePassword(BuildContext context)=>openOperation(context,'password');

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool hidden = true;
  bool busy = false;
  Object? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { busy = true; error = null; });
    try {
      await context.app.login(email.text.trim(), password.text);
    } catch (failure) {
      if (mounted) setState(() => error = failure);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void recovery() {
    showDialog<void>(context: context, builder: (dialog) => AlertDialog(
      title: Text(context.tr('استعادة الدخول', 'Recover access')),
      content: Text(context.tr(
        'حسابات الطبيب والوكيل تخضع لاعتماد الإدارة. تواصل مع المسؤول المخول لاستعادة الدخول أو مراجعة الترخيص.',
        'Doctor and agent accounts are managed by your organization. Contact an authorized administrator to recover access.')),
      actions: [TextButton(onPressed: () => Navigator.pop(dialog),
        child: Text(context.tr('فهمت', 'Got it')))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(body: BotanicalBackground(child: SafeArea(
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 490),
        child: AutofillGroup(child: Form(key: form, child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 32),
          children: [
            Row(children: [
              const BrandLogo(size: 62),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مزرعتي', style: type.headlineSmall
                    ?.copyWith(color: colors.primary, fontWeight: FontWeight.w900)),
                  Text(context.tr('تطبيق الطبيب والوكيل', 'Doctor & agent app'),
                    style: type.bodySmall),
                ])),
              IconButton.outlined(
                tooltip: context.tr('تبديل اللغة', 'Change language'),
                onPressed: () => context.app.preferences(
                  language: context.app.ar ? 'en' : 'ar'),
                icon: const Icon(Icons.language_rounded)),
            ]),
            const SizedBox(height: 22),
            AgentHero(
              title: context.tr('خدماتك البيطرية والتجارية في مكان واحد',
                'Veterinary care and branch commerce in one place'),
              subtitle: context.tr('آمن، سريع، ومُخصص لصلاحياتك.',
                'Secure, responsive and tailored to your permissions.'),
              art: 'assets/images/agent_clinical.webp',
              icon: Icons.medical_services_outlined),
            const SizedBox(height: 24),
            AgentSurface(padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.tr('مرحبًا بعودتك', 'Welcome back'),
                    style: type.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(context.tr('أدخل بيانات حسابك المعتمد للمتابعة.',
                      'Sign in with your approved work account.'),
                    style: type.bodySmall),
                  const SizedBox(height: 21),
                  TextFormField(
                    controller: email,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: InputDecoration(
                      labelText: context.tr('البريد الإلكتروني', 'Email address'),
                      hintText: 'example@company.com',
                      prefixIcon: const Icon(Icons.alternate_email_rounded)),
                    validator: (v) {
                      final email = (v ?? '').trim();
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                        return context.tr('أدخل بريدًا إلكترونيًا صحيحًا',
                          'Enter a valid email address');
                      }
                      return null;
                    }),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: password,
                    enabled: !busy,
                    obscureText: hidden,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText: context.tr('كلمة المرور', 'Password'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: context.tr(hidden ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                          hidden ? 'Show password' : 'Hide password'),
                        onPressed: () => setState(() => hidden = !hidden),
                        icon: Icon(hidden ? Icons.visibility_outlined :
                          Icons.visibility_off_outlined))),
                    validator: (v) => (v ?? '').isEmpty
                      ? context.tr('أدخل كلمة المرور', 'Password is required') : null),
                  if (error != null) ...[
                    const SizedBox(height: 17),
                    Notice(failureText(context, error!), error: true),
                  ],
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: busy ? null : submit,
                    icon: busy
                      ? const SizedBox.square(dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.login_rounded),
                    label: Text(context.tr('تسجيل الدخول بأمان', 'Secure sign in'))),
                  Align(alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: busy ? null : recovery,
                      child: Text(context.tr('هل نسيت كلمة المرور؟', 'Forgot password?')))),
                ])),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.verified_user_outlined, size: 17,
                color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(child: Text(context.tr(
                'لا تُفتح أدوات الفرع إلا بعد التحقق من التفويض.',
                'Branch tools require verified authorization.'),
                textAlign: TextAlign.center, style: type.bodySmall)),
            ]),
          ],
        ))),
      )),
    )));
  }
}

class GeneralPage extends StatelessWidget {
  const GeneralPage(this.id,{super.key});final String id;
  @override Widget build(BuildContext context){final app=context.app;
    switch(id){
      case 'H01':case 'H05':return const Empty();
      case 'H02':return const SignInPage();
      case 'H03':return PageBody(children:[Notice(context.tr('تواصل مع مسؤول الفرع لاستعادة حساب الطبيب والوكيل.','Contact your branch administrator to recover your account.')),
        const SizedBox(height:16),FilledButton(onPressed:()=>context.open('H10'),child:Text(context.tr('الدعم','Support')))]);
      case 'H04':return PageBody(children:[
        Panel(child:Column(children:[const BrandLogo(size:64),const SizedBox(height:12),Text(str(app.user['name']),style:Theme.of(context).textTheme.titleLarge),
          StatusTag(app.access.doctor?'Approved':'Pending'),const SizedBox(height:8),Text(context.tr('الاعتماد البيطري','Veterinary approval')),
          const SizedBox(height:14),StatusTag(app.access.dispenser?'Approved':'Pending'),Text(context.tr('ترخيص الصرف المستقل','Independent dispensing license'))])),
        Heading(context.tr('الترخيص','License')),Facts(obj(app.profile['profile'])),
        Heading(context.tr('الصلاحيات الفعلية','Effective permissions')),
        Panel(child:Wrap(spacing:6,runSpacing:6,children:[for(final p in app.access.permissions)Chip(label:Text(p))])),
        const SizedBox(height:16),BusyButton(label:context.tr('تحديث الصلاحيات','Refresh access'),run:app.refreshAccess),
      ]);
      case 'H06':return PageBody(children:[Notice(context.tr('اختر المخزن والصندوق اللذين تعمل ضمنهما. تغيير النطاق يفرغ سلة البيع الحالية.','Choose your warehouse and cashbox. Switching context clears the current sale cart.')),
        const SizedBox(height:16),if(app.access.grants.isEmpty)const Empty(),for(final g in app.access.grants)Padding(padding:const EdgeInsets.only(bottom:12),child:Panel(onTap:()=>app.selectGrant(g.id),child:Column(children:[
          Row(children:[Icon(g.id==app.grantId?Icons.radio_button_checked:Icons.radio_button_off),const SizedBox(width:10),Expanded(child:Text('${context.tr('المخزن','Warehouse')} #${g.warehouse}'))]),
          Fact(context.tr('الفرع','Store'),g.store),Fact(context.tr('الصندوق','Cashbox'),g.cashbox),Fact(context.tr('ينتهي في','Ends at'),g.json['endsAt'])])))]);
      case 'H07':return const NotificationsPage();
      case 'H08':return PageBody(children:[Panel(child:Column(children:[const BrandLogo(size:70),const SizedBox(height:12),
        Text(str(app.user['name']),style:Theme.of(context).textTheme.titleLarge),Text(str(app.user['email']))])),
        const SizedBox(height:12),OutlinedButton.icon(onPressed:()async{await _editProfile(context);await app.refreshAccess();},icon:const Icon(Icons.manage_accounts_outlined),label:Text(context.tr('تعديل الحساب','Edit account'))),
        Heading(context.tr('التفضيلات','Preferences')),Panel(child:Column(children:[
          ListTile(leading:const Icon(Icons.language),title:Text(context.tr('اللغة','Language')),trailing:DropdownButton<String>(value:app.language,items:const [DropdownMenuItem(value:'ar',child:Text('العربية')),DropdownMenuItem(value:'en',child:Text('English'))],onChanged:(v)=>app.preferences(language:v))),
          ListTile(leading:const Icon(Icons.dark_mode_outlined),title:Text(context.tr('المظهر','Appearance')),trailing:DropdownButton<String>(value:app.theme,items:[
            DropdownMenuItem(value:'system',child:Text(context.tr('النظام','System'))),DropdownMenuItem(value:'light',child:Text(context.tr('فاتح','Light'))),DropdownMenuItem(value:'dark',child:Text(context.tr('داكن','Dark')))],onChanged:(v)=>app.preferences(theme:v))),
        ])),Heading(context.tr('إدارة الحساب','Account management')),
        for(final row in [('H04',Icons.verified_user_outlined),('H06',Icons.storefront_outlined),('H09',Icons.sync),('H11',Icons.security_outlined),('H10',Icons.help_outline)])
          RecordTile({'title':app.tr(screen(row.$1).ar,screen(row.$1).en)},icon:row.$2,onTap:()=>context.open(row.$1)),
        const SizedBox(height:16),OutlinedButton.icon(onPressed:()async{if(await confirm(context,context.tr('تسجيل الخروج ومسح الملاحظات المحلية؟','Sign out and clear local clinical drafts?')))await app.logout();},
          icon:const Icon(Icons.logout),label:Text(context.tr('تسجيل الخروج','Sign out'))),
      ]);
      case 'H09':return Resource(identity:app.revision,load:()async=>{'notes':await app.notes(),'pending':await app.pending()},builder:(data,refresh)=>PageBody(children:[
        Notice(context.tr('الملاحظات محفوظة بأمان لمدة 24 ساعة. تُرسل العمليات المالية المعلقة فقط عند اختيار إعادة المحاولة.','Notes are stored securely for 24 hours. Pending financial operations are retried only when you choose to do so.')),
        Heading(context.tr('الملاحظات السريرية','Clinical drafts'),action:TextButton(onPressed:()async{try{await app.syncNotes();refresh();}catch(e){if(context.mounted)toast(context,failureText(context,e));}},child:Text(context.tr('مزامنة','Sync')))),
        for(final n in maps(obj(data)['notes']))RecordTile({'title':'#${n['caseId']}','status':n['state']},subtitle:str(n['body']),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()async{await app.deleteNote(str(n['requestId']));refresh();})),
        Heading(context.tr('عمليات تنتظر التأكيد','Unconfirmed operations')),
        for(final p in maps(obj(data)['pending']))Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(str(p['title'])),Fact('createdAt',p['createdAt']),
          BusyButton(label:context.tr('فحص النتيجة','Check result'),run:()async{final status=await app.commandStatus(str(p['id']));if(context.mounted)showDialog<void>(context:context,builder:(c)=>AlertDialog(content:Facts(obj(status))));}),
          const SizedBox(height:10),BusyButton(label:context.tr('إعادة نفس العملية','Retry same operation'),run:()async{await app.retry(p);refresh();})])),
        if(maps(obj(data)['notes']).isEmpty&&maps(obj(data)['pending']).isEmpty)const Empty(),
      ]));
      case 'H10':return const SupportPage();
      case 'H11':return Resource(load:()=>app.read('/api/users/me/sessions'),builder:(data,refresh)=>PageBody(children:[
        BusyButton(label:context.tr('تغيير كلمة المرور','Change password'),run:()async{await _changePassword(context);}),const SizedBox(height:16),
        for(final row in rows(data))RecordTile({'title':row['deviceName']??'#${row['id']}'},subtitle:display(context,row['createdAt']),trailing:IconButton(icon:const Icon(Icons.logout),onPressed:()async{
          if(!await confirm(context,context.tr('إلغاء هذه الجلسة؟','Revoke this session?')))return;
          try{await app.repo.write('DELETE','/api/users/me/sessions/${row['id']}',null);refresh();}catch(e){if(context.mounted)toast(context,failureText(context,e));}}))]));
      default:throw StateError('Unknown general screen: $id');
    }
  }
}

class NotificationsPage extends StatelessWidget{
  const NotificationsPage({super.key});
  @override Widget build(BuildContext context){final app=context.app;return Resource(load:()=>app.read('/api/notifications',query:{'pageSize':100}),builder:(data,refresh)=>PageBody(children:[
    Align(alignment:AlignmentDirectional.centerEnd,child:TextButton(onPressed:()async{await app.repo.write('POST','/api/notifications/mark-all-read',{});refresh();},child:Text(context.tr('قراءة الكل','Mark all read')))),
    if(rows(data).isEmpty)const Empty(),for(final n in rows(data))RecordTile({'title':n['title'],'status':n['isRead']==true?'':'Pending'},subtitle:str(n['body']),icon:Icons.notifications_none,onTap:()async{
      await app.repo.write('POST','/api/notifications/mark-read',[n['id']]);refresh();
      Json payload=obj(n['data']);if(n['dataJson'] is String){try{payload=obj(jsonDecode(n['dataJson']));}catch(_){}}
      final type=str(n['eventType']??payload['eventType']),id=numId(n['entityId']??payload['entityId']);
      final destination=notificationDestination(type);
      if(!context.mounted)return;
      if(destination==null||id<=0){toast(context,context.tr('لا تتوفر وجهة لهذا الإشعار.','No destination is available for this notification.'));return;}
      context.open(destination,id:id);
    })]));}
}
String? notificationDestination(String type){
  if(type.startsWith('vet.case.')||type=='vet.message'||type=='vet.record.updated'||type=='vet.appointment')return 'C02';
  if(type.startsWith('vet.prescription'))return 'C12';
  if(type.startsWith('agent.campaign.'))return 'F10';
  if(type.startsWith('agent.task.'))return 'F02';
  if(type.contains('pickup'))return 'P03';
  if(type.contains('auction'))return 'A06';
  if(type.contains('proposal'))return 'G03';
  if(type.contains('transfer'))return 'I08';
  return null;
}
class SupportPage extends StatefulWidget{
  const SupportPage({super.key});
  @override State<SupportPage> createState()=>_SupportPageState();
}
class _SupportPageState extends State<SupportPage>{
  final subject=TextEditingController(),message=TextEditingController();
  @override void dispose(){subject.dispose();message.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Resource(load:()=>context.app.read('/api/Support/tickets'),builder:(data,refresh)=>PageBody(children:[
    Heading(context.tr('طلب مساعدة','Request help')),TextField(controller:subject,decoration:InputDecoration(labelText:context.tr('الموضوع','Subject'))),const SizedBox(height:12),
    TextField(controller:message,maxLines:4,decoration:InputDecoration(labelText:context.tr('الرسالة','Message'))),const SizedBox(height:12),
    BusyButton(label:context.tr('إرسال التذكرة','Send ticket'),run:()async{if(subject.text.trim().isEmpty||message.text.trim().isEmpty)return;
      await context.app.repo.write('POST','/api/Support/tickets',{'subject':subject.text.trim(),'message':message.text.trim(),'priority':'normal'});subject.clear();message.clear();refresh();}),
    Heading(context.tr('تذاكري','My tickets')),for(final t in rows(data))RecordTile(t,onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>TicketPage(id:numId(t['id']))))),
  ]));
}
class TicketPage extends StatefulWidget{
  const TicketPage({super.key,required this.id});final int id;
  @override State<TicketPage> createState()=>_TicketPageState();
}
class _TicketPageState extends State<TicketPage>{
  final reply=TextEditingController();
  @override void dispose(){reply.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(context.tr('التذكرة','Support ticket'))),body:Resource(
    load:()=>context.app.read('/api/Support/tickets/${widget.id}'),builder:(data,refresh)=>PageBody(children:[Facts(obj(data)),
      for(final m in maps(obj(data)['messages']))Panel(child:Text(str(m['body']))),const SizedBox(height:16),
      TextField(controller:reply,decoration:InputDecoration(labelText:context.tr('الرد','Reply')),maxLines:3),const SizedBox(height:12),
      BusyButton(label:context.tr('إرسال الرد','Send reply'),run:()async{await context.app.repo.write('POST','/api/Support/tickets/${widget.id}/messages',{'body':reply.text});reply.clear();refresh();}),
    ])));
}
