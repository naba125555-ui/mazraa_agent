import '../domain/models.dart';

enum InputKind { text, longText, number, integer, boolean, choice, date, reference, lines, photos }
class InputSpec {
  const InputSpec(this.key,{this.kind=InputKind.text,this.required=true,this.options=const [],this.source,this.mode,this.initial});
  final String key;final InputKind kind;final bool required;final List<String> options;
  final String? source,mode;final Object? initial;
}
class Operation {
  const Operation(this.key,this.ar,this.en,this.path,this.fields,{this.cap=0,this.version=false,this.scope=false,this.constants=const {},this.method='POST',this.doctor=false});
  final String key,ar,en,path,method;final List<InputSpec> fields;final int cap;
  final bool version,scope,doctor;final Json constants;
}
const reason=InputSpec('reason',kind:InputKind.longText);
const notesField=InputSpec('notes',kind:InputKind.longText);
const stockLines=InputSpec('lines',kind:InputKind.lines,mode:'stock');
const purchaseLines=InputSpec('lines',kind:InputKind.lines,mode:'purchase');
const operations=<String,Operation>{
  'accept':Operation('accept','قبول الاستشارة','Accept consultation','/api/vet/cases/{id}/accept',[],version:true,doctor:true),
  'decline':Operation('decline','اعتذار عن الاستشارة','Decline consultation','/api/vet/cases/{id}/decline',[],version:true,doctor:true),
  'note':Operation('note','حفظ الملاحظة','Save clinical note','/api/vet/cases/{id}/notes',[
    InputSpec('body',kind:InputKind.longText),InputSpec('sharedWithCustomer',kind:InputKind.boolean,initial:false),
    InputSpec('amendsId',kind:InputKind.integer,required:false)],doctor:true),
  'appointment':Operation('appointment','طلب الزيارة','Request visit','/api/vet/cases/{id}/visits',[
    InputSpec('scheduledAt',kind:InputKind.date),InputSpec('location',kind:InputKind.longText),reason],version:true,doctor:true),
  'workflow':Operation('workflow','تحديث المتابعة','Update follow-up','/api/vet/cases/{id}/workflow',[
    InputSpec('stage',kind:InputKind.choice,options:['Consulting','AwaitingInformation','VisitRequested','FollowUp','Referred']),
    InputSpec('priority',kind:InputKind.choice,options:['normal','high','urgent']),
    InputSpec('followUpAt',kind:InputKind.date,required:false),InputSpec('customerMessage',kind:InputKind.longText)],version:true,doctor:true),
  'closeCase':Operation('closeCase','إغلاق الحالة','Close consultation','/api/vet/cases/{id}/close',[
    InputSpec('summary',kind:InputKind.longText)],version:true,doctor:true),
  'prescribe':Operation('prescribe','توقيع وإصدار الوصفة','Sign and issue','/api/vet/prescriptions',[
    InputSpec('validUntil',kind:InputKind.date),InputSpec('diagnosis',kind:InputKind.longText),
    InputSpec('warnings',kind:InputKind.longText),InputSpec('lines',kind:InputKind.lines,mode:'prescription')],doctor:true),
  'cancelPrescription':Operation('cancelPrescription','إلغاء الوصفة','Cancel prescription','/api/vet/prescriptions/{id}/cancel',[],version:true,doctor:true),
  'dispense':Operation('dispense','تأكيد الصرف','Confirm dispensation','/api/vet/prescriptions/{id}/dispense',[
    InputSpec('customerId',kind:InputKind.integer),stockLines,InputSpec('accessCode',required:false)],scope:true,version:true,cap:290),
  'releasePrescription':Operation('releasePrescription','اعتماد دفعات الوصفة','Release prescribed batches','/api/vet/prescription-orders/{id}/release',[
    InputSpec('batches',kind:InputKind.lines,mode:'stock')],scope:true,version:true,cap:256),
  'prepare':Operation('prepare','تجهيز الطلب','Prepare order','/api/agent/fulfillment/orders/{id}/prepare',[],scope:true),
  'taskState':Operation('taskState','تحديث المهمة','Update task','/api/agent/field/tasks/{id}/state',[
    InputSpec('status',kind:InputKind.choice,options:['Accepted','Rejected','InProgress','Completed'])],doctor:true),
  'createVisit':Operation('createVisit','إنشاء زيارة','Create visit','/api/agent/field/tasks/{id}/visits',[
    InputSpec('latitude',kind:InputKind.number,required:false),InputSpec('longitude',kind:InputKind.number,required:false),notesField],doctor:true),
  'visitState':Operation('visitState','توثيق الزيارة','Record visit','/api/agent/field/visits/{id}/state',[
    InputSpec('latitude',kind:InputKind.number,required:false),InputSpec('longitude',kind:InputKind.number,required:false),
    InputSpec('diagnosis',kind:InputKind.longText),InputSpec('findings',kind:InputKind.longText),
    InputSpec('treatment',kind:InputKind.longText),InputSpec('recommendations',kind:InputKind.longText)],doctor:true),
  'inspection':Operation('inspection','حفظ الفحص','Save examination','/api/AnimalInspections',[
    InputSpec('animalId',kind:InputKind.integer),InputSpec('weightKg',kind:InputKind.number,required:false),
    InputSpec('healthStatus'),InputSpec('findings',kind:InputKind.longText),InputSpec('recommendations',kind:InputKind.longText),notesField],doctor:true),
  'campaignState':Operation('campaignState','تحديث الحملة','Update campaign','/api/agent/field/campaigns/{id}/state',[
    InputSpec('status',kind:InputKind.choice,options:['Active','Rejected','Completed']),InputSpec('report',kind:InputKind.longText)],version:true,doctor:true),
  'vaccinate':Operation('vaccinate','توثيق النتيجة','Record outcome','/api/agent/field/campaigns/{id}/administrations',[
    InputSpec('outcome',kind:InputKind.choice,options:['administered','deferred','excluded','waste','return']),
    InputSpec('animalId',kind:InputKind.integer,required:false),InputSpec('group',required:false),
    InputSpec('animalCount',kind:InputKind.integer,initial:1),InputSpec('stopId',kind:InputKind.integer,required:false),
    InputSpec('batchId',kind:InputKind.reference,source:'batches',required:false),InputSpec('quantity',kind:InputKind.number),
    InputSpec('doseNumber',kind:InputKind.integer,initial:1),InputSpec('capturedAt',kind:InputKind.date),
    InputSpec('nextDueAt',kind:InputKind.date,required:false),InputSpec('prescriptionId',kind:InputKind.integer,required:false),notesField],doctor:true),
  'temperature':Operation('temperature','تسجيل درجة الحرارة','Record temperature','/api/agent/field/campaigns/{id}/temperatures',[
    InputSpec('batchId',kind:InputKind.reference,source:'batches'),InputSpec('celsius',kind:InputKind.number),
    InputSpec('capturedAt',kind:InputKind.date),notesField],doctor:true),
  'hold':Operation('hold','حجز الدفعة','Quarantine batch','/api/agent/operations/batch-holds',[
    InputSpec('batchId',kind:InputKind.reference,source:'batches'),reason],scope:true,cap:1),
  'supply':Operation('supply','إرسال طلب التغذية','Request stock','/api/agent/supply/requests',[
    InputSpec('sourceWarehouseId',kind:InputKind.reference,source:'warehouses'),
    InputSpec('lines',kind:InputKind.lines,mode:'supply'),reason],scope:true,cap:8),
  'transfer':Operation('transfer','إرسال التحويل','Dispatch stock','/api/agent/commerce/transfers',[
    InputSpec('destinationWarehouseId',kind:InputKind.reference,source:'warehouses'),stockLines,notesField],scope:true,cap:8),
  'receiveTransfer':Operation('receiveTransfer','تأكيد الاستلام الفعلي','Confirm receipt','/api/agent/commerce/transfers/{id}/receive',[
    stockLines],scope:true,version:true,cap:8),
  'stockCount':Operation('stockCount','إرسال الجرد للمراجعة','Submit stock count','/api/agent/commerce/stock-counts',[
    InputSpec('lines',kind:InputKind.lines,mode:'count'),reason],scope:true,cap:16),
  'sale':Operation('sale','ترحيل البيع','Post sale','/api/agent/commerce/documents',[
    InputSpec('partyId',kind:InputKind.reference,source:'customers'),stockLines,
    InputSpec('paymentMethod',kind:InputKind.choice,options:['Cash','BankTransfer','Wallet']),
    InputSpec('paidAmount',kind:InputKind.number),InputSpec('discountPercent',kind:InputKind.number,initial:0),
    InputSpec('bankReference',required:false),InputSpec('quoteId',kind:InputKind.integer,required:false)],scope:true,cap:34,constants:{'purchase':false}),
  'quote':Operation('quote','إرسال عرض السعر','Send quotation','/api/agent/commercial/quotes',[
    InputSpec('partyId',kind:InputKind.reference,source:'customers'),stockLines,
    InputSpec('paymentMethod',kind:InputKind.choice,options:['Cash','BankTransfer','Wallet']),
    InputSpec('discountPercent',kind:InputKind.number,initial:0)],scope:true,cap:2,constants:{'purchase':false}),
  'procurement':Operation('procurement','إرسال طلب الشراء','Submit purchase request','/api/agent/procurement',[
    InputSpec('supplierId',kind:InputKind.reference,source:'suppliers'),purchaseLines,reason],scope:true,cap:4),
  'receivePurchase':Operation('receivePurchase','استلام دفعات الشراء','Receive purchased batches','/api/agent/procurement/{id}/receive',[
    purchaseLines,InputSpec('paidAmount',kind:InputKind.number),InputSpec('paymentMethod',kind:InputKind.choice,options:['Cash','BankTransfer']),
    InputSpec('bankReference',required:false),InputSpec('itemsReceived',kind:InputKind.boolean,initial:false)],scope:true,version:true,cap:36),
  'return':Operation('return','إرسال المرتجع للمراجعة','Submit return','/api/agent/returns',[
    InputSpec('originalDocumentId',kind:InputKind.reference,source:'documents'),InputSpec('lines',kind:InputKind.lines,mode:'return'),reason],scope:true),
  'openShift':Operation('openShift','فتح الوردية','Open shift','/api/agent/commerce/shifts',[
    InputSpec('countedOpening',kind:InputKind.number)],scope:true,cap:32),
  'closeShift':Operation('closeShift','إقفال الوردية','Close shift','/api/agent/commerce/shifts/{id}/close',[
    InputSpec('countedClosing',kind:InputKind.number),notesField],scope:true,version:true,cap:32),
  'settle':Operation('settle','تسجيل السداد','Record settlement','/api/agent/finance/documents/{id}/settle',[
    InputSpec('amount',kind:InputKind.number),InputSpec('paymentMethod',kind:InputKind.choice,options:['Cash','BankTransfer']),
    notesField,InputSpec('bankReference',required:false)],scope:true,cap:32),
  'custody':Operation('custody','توثيق الحيازة','Confirm custody','/api/agent/pickup/requests/{id}/custody',[
    InputSpec('itemsVerified',kind:InputKind.boolean,initial:false),InputSpec('shelf'),InputSpec('deadline',kind:InputKind.date)],scope:true,version:true,cap:64),
  'driverCode':Operation('driverCode','رمز استلام السائق','Driver handoff code','/api/agent/pickup/requests/{id}/driver-code',[
    InputSpec('shelf'),InputSpec('deadline',kind:InputKind.date)],scope:true,version:true,cap:64),
  'shelf':Operation('shelf','تحديث موقع الحفظ','Update storage location','/api/agent/pickup/requests/{id}/shelf',[
    InputSpec('shelf'),InputSpec('deadline',kind:InputKind.date)],scope:true,version:true,cap:64),
  'handover':Operation('handover','تأكيد التسليم والتحصيل','Confirm handover','/api/agent/pickup/requests/{id}/complete',[
    InputSpec('code'),InputSpec('cashCollected',kind:InputKind.number)],scope:true,version:true,cap:96),
  'pickupIssue':Operation('pickupIssue','توثيق الاستثناء','Record pickup exception','/api/agent/pickup/requests/{id}/exceptions',[
    InputSpec('reason',kind:InputKind.choice,options:['damage','refused','uncollected','return-to-source']),notesField],scope:true,version:true,cap:64),
  'auction':Operation('auction','حفظ مسودة المزاد','Save auction draft','/api/agent/marketplace/auctions',[
    InputSpec('title'),InputSpec('description',kind:InputKind.longText),InputSpec('terms',kind:InputKind.longText),
    InputSpec('startAt',kind:InputKind.date),InputSpec('endAt',kind:InputKind.date),InputSpec('guaranteeAmount',kind:InputKind.number,initial:0),
    InputSpec('items',kind:InputKind.lines,mode:'auction'),InputSpec('photoMediaIds',kind:InputKind.photos)],scope:true,cap:128),
  'submitAuction':Operation('submitAuction','إرسال للمراجعة','Submit for review','/api/agent/marketplace/auctions/{id}/submit',[],version:true,cap:128),
  'publishAuction':Operation('publishAuction','نشر المزاد المعتمد','Publish approved auction','/api/agent/marketplace/auctions/{id}/publish',[],version:true,cap:128),
  'cancelAuction':Operation('cancelAuction','إلغاء المزاد','Cancel auction','/api/agent/marketplace/auctions/{id}/cancel',[reason],version:true,cap:128),
  'auctionHandover':Operation('auctionHandover','تسليم طلب المزاد','Handover auction order','/api/agent/fulfillment/auction-orders/{id}/complete',[
    InputSpec('code'),InputSpec('itemsVerified',kind:InputKind.boolean,initial:false)],scope:true,version:true,cap:128),
  'proposal':Operation('proposal','إرسال الاقتراح','Submit proposal','/api/agent/marketplace/proposals',[
    InputSpec('kind',kind:InputKind.choice,options:['product','purchase','improvement']),InputSpec('title'),
    InputSpec('description',kind:InputKind.longText),InputSpec('supplierId',kind:InputKind.reference,source:'suppliers',required:false),
    InputSpec('estimatedCost',kind:InputKind.number,required:false),InputSpec('currency',required:false)],scope:true,cap:1),
  'reviseProposal':Operation('reviseProposal','إرسال النسخة المعدلة','Submit revision','/api/agent/marketplace/proposals/{id}/revise',[
    InputSpec('title'),InputSpec('description',kind:InputKind.longText),InputSpec('supplierId',kind:InputKind.reference,source:'suppliers',required:false),
    InputSpec('estimatedCost',kind:InputKind.number,required:false),InputSpec('currency',required:false)],scope:true,version:true,cap:1),
};

Json prepareBody(Operation op,Json values,Json seed,int? grant,int? actor){
  var body=<String,dynamic>{...op.constants,...values};
  if(op.scope)body['delegationId']=grant;
  if(op.version)body['version']=numId(seed['version']);
  if(op.key=='prescribe')body['caseId']=numId(seed['caseId']??seed['id']);
  if(op.key=='taskState')body['expectedStatus']=seed['status'];
  if(op.key=='visitState'){
    body['expectedStatus']=seed['status'];body['status']=seed['status']=='Scheduled'?'Started':'Completed';
    if(body['status']=='Started')for(final k in ['diagnosis','findings','treatment','recommendations'])body[k]=null;
  }
  if(op.key=='inspection'){body['fieldVisitId']=seed['id'];body['inspectorUserId']=actor;body['resultStatus']='Pending';}
  if(op.key=='sale'||op.key=='quote'){
    body['lines']=maps(body['lines']).map((l)=>{...l,'unitCost':0}).toList();
  }
  if(op.key=='receivePurchase'){
    final d=payload(seed);
    body={'version':seed['version'],'itemsReceived':values['itemsReceived'],
      'document':{'requestId':uuidPlaceholder,'delegationId':grant,'purchase':true,'partyId':d['supplierId'],
        'lines':values['lines'],'paymentMethod':values['paymentMethod'],'paidAmount':values['paidAmount'],
        'discountPercent':0,'bankReference':values['bankReference']}};
  }
  return body;
}
const uuidPlaceholder='00000000-0000-4000-8000-000000000001';
