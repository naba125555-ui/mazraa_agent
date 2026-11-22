import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../application/agent_app.dart';
import '../../domain/models.dart';
import '../../domain/screens.dart';

/// Only the eleven documented workspaces. These identifiers never create
/// endpoints or guess a capability from a friendly display label.
enum InsightKind {
  overview, clinic, sales, field, inventory, finance,
  pickup, auctions, purchasing, proposals, sync,
}

extension InsightKindInfo on InsightKind {
  String get route => switch (this) {
    InsightKind.overview => 'H05',
    InsightKind.clinic => 'C01',
    InsightKind.sales => 'T06',
    InsightKind.field => 'F01',
    InsightKind.inventory => 'I05',
    InsightKind.finance => 'N02',
    InsightKind.pickup => 'P02',
    InsightKind.auctions => 'A01',
    InsightKind.purchasing => 'T11',
    InsightKind.proposals => 'G01',
    InsightKind.sync => 'H09',
  };
  IconData get icon => switch (this) {
    InsightKind.overview => Icons.insights_rounded,
    InsightKind.clinic => Icons.medical_services_outlined,
    InsightKind.sales => Icons.shopping_cart_outlined,
    InsightKind.field => Icons.location_on_outlined,
    InsightKind.inventory => Icons.inventory_2_outlined,
    InsightKind.finance => Icons.account_balance_wallet_outlined,
    InsightKind.pickup => Icons.local_shipping_outlined,
    InsightKind.auctions => Icons.gavel_outlined,
    InsightKind.purchasing => Icons.local_shipping_outlined,
    InsightKind.proposals => Icons.lightbulb_outline,
    InsightKind.sync => Icons.cloud_sync_outlined,
  };
  String title(bool ar) => (ar ? const [
    'نظرة عامة', 'العيادة البيطرية', 'المبيعات', 'العمل الميداني',
    'حالة المخزون', 'المالية والصندوق', 'الاستلام والتسليم',
    'المزادات', 'المشتريات والتوريد', 'مقترحاتي', 'المزامنة',
  ] : const [
    'Overview', 'Veterinary clinic', 'Sales', 'Field work',
    'Inventory health', 'Finance & cashbox', 'Pickup & handover',
    'Auctions', 'Purchasing', 'My proposals', 'Sync',
  ])[index];
  String subtitle(bool ar) => (ar ? const [
    'أهم أعمالك التي تحتاج متابعة',
    'حالاتك وإحالاتك الطبية',
    'الفواتير المؤكدة في السجلات المحمّلة',
    'المهام والزيارات المسندة إليك',
    'الأرصدة والدفعات التي تستحق الانتباه',
    'رصيد صندوقك وحركاته المحمّلة',
    'حالات الطلبات ضمن نطاقك',
    'حالة المزادات ومراجعاتها',
    'دورة طلبات الشراء المفوّضة',
    'نتائج المقترحات التي قدمتها',
    'مسودات الملاحظات السريرية المحلية',
  ] : const [
    'Your work requiring attention',
    'Assigned veterinary cases and offers',
    'Confirmed invoices in the loaded records',
    'Assigned field tasks and visits',
    'Stock items and batches requiring attention',
    'Your cash balance and loaded transactions',
    'Order statuses in your scope',
    'Your auctions and their reviews',
    'Authorized purchase request pipeline',
    'Status of your submitted proposals',
    'Local clinical note drafts',
  ])[index];
  String action(bool ar) => (ar ? const [
    'عرض أعمالي', 'الانتقال إلى استشاراتي',
    'تفاصيل الفواتير', 'استعراض مهامي',
    'مراجعة تنبيهات المخزون', 'عرض حركات الصندوق',
    'فتح طابور التسليم', 'إدارة مزاداتي',
    'متابعة المشتريات', 'متابعة مقترحاتي', 'إدارة المزامنة',
  ] : const [
    'My workspace', 'Open consultations',
    'Open invoices', 'View field tasks',
    'Review stock alerts', 'View cash movements',
    'Open pickup queue', 'Manage auctions',
    'View purchasing', 'View proposals', 'Manage sync',
  ])[index];
}

/// Counts/values are nullable by design. Null means no verified figure exists;
/// zero means a verified source really reported zero.
class InsightValue {
  const InsightValue(this.ar, this.en, this.value, {this.unitAr='',this.unitEn=''});
  final String ar, en;
  final double? value;
  final String unitAr, unitEn;
  String label(bool arabic) => arabic ? ar : en;
  String unit(bool arabic) => arabic ? unitAr : unitEn;
}

class InsightSnapshot {
  const InsightSnapshot({
    this.headline,
    required this.headlineAr,
    required this.headlineEn,
    this.currency,
    this.values=const [],
    this.parts=const [],
    this.series=const [],
    this.secondary=const [],
    this.days=const [],
    this.periodAr='الحالة الحالية',
    this.periodEn='Current',
    this.noteAr='',
    this.noteEn='',
    this.partial=false,
  });
  final double? headline;
  final String headlineAr, headlineEn;
  final String? currency;
  final List<InsightValue> values, parts;
  final List<double> series, secondary;
  final List<String> days;
  final String periodAr, periodEn, noteAr, noteEn;
  final bool partial;
  String headlineLabel(bool ar) => ar ? headlineAr : headlineEn;
  String period(bool ar) => ar ? periodAr : periodEn;
  String note(bool ar) => ar ? noteAr : noteEn;
}

abstract final class HomeInsightsData {
  static List<InsightKind> available(AgentApp app) {
    final base = <InsightKind>[InsightKind.overview];
    final doctor = <InsightKind>[
      InsightKind.clinic, InsightKind.field, InsightKind.sales,
      InsightKind.inventory, InsightKind.finance, InsightKind.pickup,
      InsightKind.auctions, InsightKind.purchasing, InsightKind.proposals,
      InsightKind.sync,
    ];
    final merchant = <InsightKind>[
      InsightKind.sales, InsightKind.inventory, InsightKind.finance,
      InsightKind.pickup, InsightKind.auctions, InsightKind.purchasing,
      InsightKind.proposals, InsightKind.clinic, InsightKind.field,
      InsightKind.sync,
    ];
    for(final kind in app.access.doctor ? doctor : merchant) {
      if(kind == InsightKind.sync && !app.access.doctor) continue;
      if(app.canOpen(screen(kind.route)) && !base.contains(kind)) base.add(kind);
    }
    return base;
  }

  static Future<InsightSnapshot> load(AgentApp app, InsightKind kind) async {
    if(kind != InsightKind.overview && !app.canOpen(screen(kind.route))) {
      throw const Failure(403, '');
    }
    switch(kind) {
      case InsightKind.overview: return _overview(app);
      case InsightKind.clinic: return _clinic(app);
      case InsightKind.sales: return _sales(app);
      case InsightKind.field: return _field(app);
      case InsightKind.inventory: return _inventory(app);
      case InsightKind.finance: return _finance(app);
      case InsightKind.pickup: return _pickup(app);
      case InsightKind.auctions: return _auctions(app);
      case InsightKind.purchasing: return _purchasing(app);
      case InsightKind.proposals: return _proposals(app);
      case InsightKind.sync: return _sync(app);
    }
  }

  static double? _number(Object? value) {
    if(value is num) return value.toDouble();
    return double.tryParse(str(value));
  }

  static double? _key(Json map, String key) {
    if(!map.containsKey(key)) return null;
    return _number(map[key]);
  }

  static DateTime? _date(Object? raw) =>
      DateTime.tryParse(str(raw))?.toLocal();

  static DateTime _now(AgentApp app) =>
      _date(app.summary['serverTime']) ?? DateTime.now();

  static List<DateTime> _week(AgentApp app) {
    final now=_now(app);
    final today=DateTime(now.year,now.month,now.day);
    return [for(var i=6;i>=0;i--)today.subtract(Duration(days:i))];
  }
  static List<String> _labels(List<DateTime> week, String language) =>
      [for(final day in week) DateFormat('E',language).format(day)];

  static bool _sameDay(DateTime x,DateTime y) =>
      x.year==y.year && x.month==y.month && x.day==y.day;

  static String _status(Object? value) {
    final status=str(value).trim();
    // AgentRecordStatus comes from the documented 08-domain-payloads enum.
    if(value is num) return switch(value.toInt()) {
      1=>'Draft', 2=>'Pending', 3=>'Approved', 4=>'Active',
      5=>'Completed', 6=>'Rejected', 7=>'Cancelled',
      8=>'NeedsChanges', _=>status,
    };
    return status;
  }

  // Domain-specific enums (visit, auction, pickup, document) are NOT
  // AgentRecordStatus. Preserve their raw wire representation instead of
  // guessing that an integer value maps to the AgentRecord enum.
  static String _rawStatus(Object? status) => str(status).trim();

  static int _matching(List<Json> source, Set<String> statuses) =>
      source.where((row)=>statuses.contains(_status(row['status']))).length;

  static InsightSnapshot _overview(AgentApp app) {
    final s=app.summary;
    final values=<InsightValue>[
      if(app.access.doctor && _key(s,'caseOffers')!=null)
        InsightValue('إحالات جديدة','New referrals',_key(s,'caseOffers')),
      if(app.access.doctor && _key(s,'activeCases')!=null)
        InsightValue('حالات نشطة','Active cases',_key(s,'activeCases')),
      if(app.allows(Cap.inventory) && _key(s,'pendingProposals')!=null)
        InsightValue('مقترحات معلّقة','Pending proposals',_key(s,'pendingProposals')),
      if(app.allows(Cap.cash) && _key(s,'openShifts')!=null)
        InsightValue('ورديات مفتوحة','Open shifts',_key(s,'openShifts')),
    ];
    final known=values.fold<double>(0,(sum,m)=>sum+(m.value??0));
    return InsightSnapshot(
      headline:values.isEmpty?null:known,
      headlineAr:'مؤشرات العمل المتاحة',headlineEn:'Available work indicators',
      values:values,parts:values,
      noteAr:values.isEmpty
        ? 'لا تتوفر مؤشرات مفوّضة من ملخص السيرفر.'
        : 'عدد عناصر عمل من أنواع مختلفة، وليس مجموعًا ماليًا.',
      noteEn:values.isEmpty
        ? 'No authorized counters are available from the server summary.'
        : 'Counts of different work items; no monetary amounts are combined.',
    );
  }

  static InsightSnapshot _clinic(AgentApp app) {
    final active=_key(app.summary,'activeCases');
    final offers=_key(app.summary,'caseOffers');
    final values=<InsightValue>[
      InsightValue('إحالات جديدة','New referrals',offers),
      InsightValue('قيد المتابعة','Active cases',active),
      const InsightValue('مغلقة','Closed',null),
    ];
    return InsightSnapshot(
      headline:active,headlineAr:'حالات نشطة',headlineEn:'Active cases',
      values:values,parts:values.take(2).where((v)=>v.value!=null).toList(),
      periodAr:'بيانات مباشرة',periodEn:'Live counters',
      noteAr:'الجديد والنشط من ملخص السيرفر؛ عدد المغلق غير متاح كتجميع.',
      noteEn:'New and active are server counters; no aggregate closed count is provided.',
    );
  }

  /// This endpoint returns only fifty ASCENDING documents per call, not a
  /// complete weekly sales report. We never call it a full-period total.
  static Future<InsightSnapshot> _sales(AgentApp app) async {
    final documents=await app.page('/api/agent/commerce/documents',query:app.scoped());
    final week=_week(app);
    final posted=documents.where((d)=>
      _status(d['type']).toLowerCase()=='salesinvoice' &&
      d['isPosted']==true && _date(d['postedAt'])!=null).toList();
    final currencies=posted.map((d)=>str(d['currency'])).where((s)=>s.isNotEmpty).toSet();
    final unknownDocumentType=documents.any((d)=>
      d['isPosted']==true && d['type'] is num);
    final sameCurrency=!unknownDocumentType && currencies.length<=1 &&
        posted.every((d)=>d['currency']!=null && _number(d['totalAmount'])!=null);
    final amounts=<double>[for(final _ in week)0];
    var invoices=0;
    for(final d in posted){
      final date=_date(d['postedAt'])!;
      final day=week.indexWhere((w)=>_sameDay(w,date));
      if(day<0)continue;
      invoices++;
      if(sameCurrency) amounts[day]+=_number(d['totalAmount'])??0;
    }
    final sum=sameCurrency ? amounts.fold<double>(0,(a,b)=>a+b) : null;
    final complete=documents.length<50;
    return InsightSnapshot(
      headline:sum,
      headlineAr:complete?'مبيعات الأسبوع المعتمدة':'مبيعات المستندات المحمّلة',
      headlineEn:complete?'Confirmed weekly sales':'Loaded confirmed invoices',
      currency:sameCurrency
          ? (currencies.isEmpty ? app.currency : currencies.first)
          : null,
      periodAr:'آخر 7 أيام',periodEn:'Last 7 days',
      values:[
        InsightValue('فواتير الفترة','Invoices in period',invoices.toDouble()),
        InsightValue('متوسط الفاتورة','Average invoice',
          sum==null||invoices==0?null:sum/invoices),
        InsightValue('سجلات محمّلة','Records loaded',documents.length.toDouble()),
      ],
      series:sameCurrency?amounts:[],
      days:_labels(week,app.language),partial:!complete,
      noteAr:!sameCurrency
          ? 'نوع المستند أو العملة أو المبلغ لا يتيح رسمًا موثوقًا.'
          : complete
            ? 'مستندات المستودع المصرح بها خلال الفترة.'
            : 'الصفحة الأولى فقط؛ ليس إجمالي مبيعات الأسبوع.',
      noteEn:!sameCurrency
          ? 'Document types, amounts or a single currency could not be verified.'
          : complete
            ? 'Authorized warehouse documents in the selected period.'
            : 'First page only; not a complete weekly sales total.',
    );
  }

  static Future<InsightSnapshot> _field(AgentApp app) async {
    final tasks=await app.page('/api/agent/field/tasks');
    final week=_week(app);
    final counts=<double>[for(final _ in week)0];
    var completed=0;
    var visits=0;
    var unknownVisitStatus=false;
    for(final task in tasks) {
      for(final visit in maps(task['visits'])) {
        visits++;
        if(visit['status'] is num) unknownVisitStatus=true;
        if(_rawStatus(visit['status'])!='Completed')continue;
        final date=_date(visit['completedAt']);
        if(date==null)continue;
        final day=week.indexWhere((w)=>_sameDay(w,date));
        if(day>=0){counts[day]++;completed++;}
      }
    }
    final complete=tasks.length<50;
    return InsightSnapshot(
      headline:unknownVisitStatus?null:completed.toDouble(),headlineAr:'زيارات مكتملة في الفترة',
      headlineEn:'Completed visits in period',
      periodAr:'آخر 7 أيام',periodEn:'Last 7 days',
      values:[
        InsightValue('مهام محمّلة','Loaded tasks',tasks.length.toDouble()),
        InsightValue('زيارات مرتبطة','Linked visits',visits.toDouble()),
        InsightValue('مكتملة في الفترة','Completed in period',
          unknownVisitStatus?null:completed.toDouble()),
      ],
      series:unknownVisitStatus?[]:counts,days:_labels(week,app.language),
      partial:!complete,
      noteAr:unknownVisitStatus?'ترميز حالة الزيارة لا يتيح إجماليًا مؤكدًا.' :
          complete?'زيارات مكتملة فعلًا، وليست حالات مهام مكتملة.'
          :'حسب أول 50 مهمة فقط؛ ليس العدد الإجمالي للزيارات.',
      noteEn:unknownVisitStatus?'Visit status encoding is not verified.' :
          complete?'Completed visits, not completed parent tasks.'
          :'From the first 50 tasks only; not all visits.',
    );
  }

  static Future<InsightSnapshot> _inventory(AgentApp app) async {
    final stocks=await app.page('/api/agent/commerce/inventory',query:app.scoped());
    final now=_now(app);
    final horizon=now.add(const Duration(days:30));
    var empty=0,soon=0,reserved=0;
    for(final stock in stocks) {
      final available=_number(stock['availableQuantity']);
      if(available!=null && available<=0) empty++;
      final holding=_number(stock['reservedQuantity']);
      if(holding!=null && holding>0) reserved++;
      for(final batch in maps(stock['batches'])){
        final expiry=_date(batch['expiryDate']);
        final quantity=_number(batch['quantity']);
        if(expiry!=null && quantity!=null && quantity>0 &&
           !expiry.isAfter(horizon)) soon++;
      }
    }
    final complete=stocks.length<100;
    return InsightSnapshot(
      headline:(empty+soon+reserved).toDouble(),
      headlineAr:'تنبيهات في العينة',headlineEn:'Flags in loaded records',
      periodAr:'الحالة الحالية',periodEn:'Current snapshot',
      values:[
        InsightValue('أصناف نافدة','Out of stock',empty.toDouble(),
          unitAr:'صنف',unitEn:'item'),
        InsightValue('دفعات قاربت الانتهاء','Expired / expiring',soon.toDouble(),
          unitAr:'دفعة',unitEn:'batch'),
        InsightValue('أصناف لها حجز','Items with reservations',reserved.toDouble(),
          unitAr:'صنف',unitEn:'item'),
      ],
      parts:[
        InsightValue('نفاد','Out of stock',empty.toDouble()),
        InsightValue('صلاحية','Expiry',soon.toDouble()),
        InsightValue('حجز','Reserved',reserved.toDouble()),
      ],
      partial:!complete,
      noteAr:'المجموع تنبيهات لا أصناف فريدة؛ '+(complete
          ? 'تمت تغطية القائمة.'
          : 'أول 100 سجل فقط.'),
      noteEn:'Sum of flags, not unique SKUs; '+(complete
          ? 'list fully covered.' : 'first 100 records only.'),
    );
  }

  static Future<InsightSnapshot> _finance(AgentApp app) async {
    final box=obj(await app.read('/api/agent/operations/cashbox',
        query:app.scoped({'afterTransactionId':0})));
    final transactions=maps(box['transactions']);
    final week=_week(app);
    final income=<double>[for(final _ in week)0];
    final expense=<double>[for(final _ in week)0];
    var recognized=0;
    for(final t in transactions) {
      final date=_date(t['createdAt']);
      if(date==null)continue;
      final day=week.indexWhere((w)=>_sameDay(w,date));
      if(day<0)continue;
      final amount=_number(t['amount']);
      if(amount==null)continue;
      final direction=str(t['direction']).toLowerCase();
      if(['in','income','inbound','credit','receipt'].contains(direction)) {
        income[day]+=amount;recognized++;
      } else if(['out','expense','outbound','debit','payment'].contains(direction)) {
        expense[day]+=amount;recognized++;
      }
    }
    final balance=_key(box,'currentBalance');
    final shift=maps(box['shifts']).where((s)=>
      ['Active','Open'].contains(_status(s['status']))).isNotEmpty;
    return InsightSnapshot(
      headline:balance,headlineAr:'الرصيد الحالي للصندوق',
      headlineEn:'Current cashbox balance',
      currency:str(box['currencyCode']).isNotEmpty
          ? str(box['currencyCode']) : app.currency,
      values:[
        InsightValue('تحصيلات محمّلة','Loaded receipts',
          recognized==0 && transactions.isNotEmpty ? null :
          income.fold<double>(0,(a,b)=>a+b)),
        InsightValue('مصروفات محمّلة','Loaded outflows',
          recognized==0 && transactions.isNotEmpty ? null :
          expense.fold<double>(0,(a,b)=>a+b)),
        InsightValue('وردية مفتوحة','Open shift',shift?1:0),
      ],
      series:recognized>0?income:[],
      secondary:recognized>0?expense:[],
      days:_labels(week,app.language),
      periodAr:'الرصيد الحالي',periodEn:'Current balance',
      partial:transactions.length>=100,
      noteAr:recognized==0 && transactions.isNotEmpty
          ? 'الرصيد مؤكد؛ اتجاه الحركات لا يطابق تصنيفًا معروفًا للرسم.'
          : transactions.length>=100
            ? 'الرصيد مؤكد؛ حركات الرسم من أول 100 قيد فقط.'
            : 'تحصيل وصرف نقدي، وليس صافي الربح.',
      noteEn:recognized==0 && transactions.isNotEmpty
          ? 'Balance is verified; transaction directions were not recognized.'
          : transactions.length>=100
            ? 'Balance is verified; chart uses only the first 100 transactions.'
            : 'Cash movements are not business profit.',
    );
  }

  static Future<InsightSnapshot> _pickup(AgentApp app) async {
    final requests=await app.page('/api/agent/pickup/requests',query:app.scoped());
    final statuses=<String,int>{};
    for(final r in requests) {
      final status=_rawStatus(r['status']);
      if(status.isNotEmpty) statuses[status]=(statuses[status]??0)+1;
    }
    final parts=[for(final entry in statuses.entries.take(4))
      InsightValue(entry.key,entry.key,entry.value.toDouble())];
    final ready=statuses['Ready']??statuses['ReadyForPickup'];
    final complete=requests.length<50;
    return InsightSnapshot(
      headline:ready?.toDouble(),
      headlineAr:'طلبات جاهزة حسب الحالة',
      headlineEn:'Requests explicitly marked ready',
      values:[
        InsightValue('طلبات محمّلة','Loaded requests',requests.length.toDouble()),
        InsightValue('جاهزة (مؤكدة)','Explicitly ready',ready?.toDouble()),
        InsightValue('حالات مميزة','Distinct statuses',statuses.length.toDouble()),
      ],
      parts:parts,periodAr:'الحالة الحالية',periodEn:'Current status',
      partial:!complete,
      noteAr:'الحالات معروضة بأسمائها الفعلية؛ لا تفترض استلام الحيازة.'
          +(complete?'':' أول 50 طلبًا فقط.'),
      noteEn:'Actual server statuses; no custody is inferred.'
          +(complete?'':' First 50 requests only.'),
    );
  }

  static Future<InsightSnapshot> _auctions(AgentApp app) async {
    final data=obj(await app.read('/api/agent/marketplace/auctions',
        query:app.scoped({'afterId':0})));
    final auctions=maps(data['auctions']);
    final reviews=maps(data['reviews']);
    final unknownAuctionStatuses=auctions.any((a)=>a['status'] is num);
    final active=auctions.where((a)=>
        ['Active','Published','Scheduled'].contains(_rawStatus(a['status']))).length;
    final drafts=_matching(reviews,{'Draft'});
    final pending=_matching(reviews,{'Pending'});
    final ended=auctions.where((a)=>
        ['Completed','Ended','Closed'].contains(_rawStatus(a['status']))).length;
    final complete=reviews.length<50;
    return InsightSnapshot(
      headline:unknownAuctionStatuses?null:active.toDouble(),
      headlineAr:'مزادات منشورة أو نشطة',
      headlineEn:'Published / active auctions',
      values:[
        InsightValue('مسودات مراجعة','Draft reviews',drafts.toDouble()),
        InsightValue('بانتظار المراجعة','Pending reviews',pending.toDouble()),
        InsightValue('منشورة أو نشطة','Published / active',
          unknownAuctionStatuses?null:active.toDouble()),
        InsightValue('منتهية','Ended auctions',
          unknownAuctionStatuses?null:ended.toDouble()),
      ],
      parts:[
        InsightValue('مسودة','Draft',drafts.toDouble()),
        InsightValue('مراجعة','Review',pending.toDouble()),
        InsightValue('منشورة','Published',
          unknownAuctionStatuses?null:active.toDouble()),
        InsightValue('منتهية','Ended',
          unknownAuctionStatuses?null:ended.toDouble()),
      ],
      partial:!complete,
      noteAr:'المسودات من سجلات المراجعة؛ النشر والانتهاء من المزادات نفسها.'
          +(complete?'':' عرض جزئي.'),
      noteEn:'Draft/review use review records; publish/end use actual auctions.'
          +(complete?'':' Partial list.'),
    );
  }

  static Future<InsightSnapshot> _purchasing(AgentApp app) async {
    final orders=await app.page('/api/agent/procurement',query:app.scoped());
    final pending=_matching(orders,{'Pending','NeedsChanges'});
    final draft=_matching(orders,{'Draft'});
    final approved=_matching(orders,{'Approved'});
    final received=orders.where((o)=>maps(obj(o['details'])['documentIds']).isNotEmpty ||
        (obj(o['details'])['documentIds'] is List &&
         (obj(o['details'])['documentIds'] as List).isNotEmpty)).length;
    final complete=orders.length<50;
    return InsightSnapshot(
      headline:pending.toDouble(),
      headlineAr:'طلبات تحتاج متابعة',
      headlineEn:'Requests needing attention',
      values:[
        InsightValue('مسودات','Draft',draft.toDouble()),
        InsightValue('معلّقة','Pending',pending.toDouble()),
        InsightValue('موافق عليها','Approved',approved.toDouble()),
        InsightValue('لها مستندات استلام','With posted documents',received.toDouble()),
      ],
      parts:[
        InsightValue('مسودة','Draft',draft.toDouble()),
        InsightValue('بانتظار قرار','Pending',pending.toDouble()),
        InsightValue('معتمدة','Approved',approved.toDouble()),
        InsightValue('مستلمة','Received',received.toDouble()),
      ],
      partial:!complete,
      noteAr:'وجود مستند استلام لا يساوي بالضرورة استلام كامل الكمية.'
          +(complete?'':' أول 50 طلبًا فقط.'),
      noteEn:'A receipt document does not prove complete receipt.'
          +(complete?'':' First 50 requests only.'),
    );
  }

  static Future<InsightSnapshot> _proposals(AgentApp app) async {
    final proposals=await app.page('/api/agent/marketplace/proposals');
    final pending=_matching(proposals,{'Pending','Draft'});
    final needs=_matching(proposals,{'NeedsChanges'});
    final approved=_matching(proposals,{'Approved'});
    final rejected=_matching(proposals,{'Rejected'});
    final complete=proposals.length<50;
    return InsightSnapshot(
      headline:(pending+needs).toDouble(),
      headlineAr:'مقترحات تنتظر المتابعة',
      headlineEn:'Proposals needing attention',
      values:[
        InsightValue('معلقة','Pending',pending.toDouble()),
        InsightValue('تحتاج تعديلًا','Needs changes',needs.toDouble()),
        InsightValue('مقبولة','Approved',approved.toDouble()),
        InsightValue('مرفوضة','Rejected',rejected.toDouble()),
      ],
      parts:[
        InsightValue('معلقة','Pending',pending.toDouble()),
        InsightValue('تعديل','Needs changes',needs.toDouble()),
        InsightValue('مقبولة','Approved',approved.toDouble()),
        InsightValue('مرفوضة','Rejected',rejected.toDouble()),
      ],
      partial:!complete,
      noteAr:complete?'مقترحاتك الشخصية فقط.':'من أول 50 مقترحًا فقط.',
      noteEn:complete?'Only your own proposals.':'First 50 proposals only.',
    );
  }

  static Future<InsightSnapshot> _sync(AgentApp app) async {
    final notes=await app.notes();
    return InsightSnapshot(
      headline:notes.length.toDouble(),
      headlineAr:'مسودات محلية تنتظر التأكيد',
      headlineEn:'Local drafts awaiting confirmation',
      values:[
        InsightValue('في الانتظار','Pending',notes.length.toDouble()),
        const InsightValue('نجحت مزامنتها','Confirmed synced',null),
        const InsightValue('آخر تأكيد','Last confirmation',null),
      ],
      periodAr:'الحالة المحلية',periodEn:'Local state',
      noteAr:'لا يحتفظ المصدر بإجمالي تاريخي للمزامنات الناجحة؛ النسبة غير متاحة.',
      noteEn:'No verified historical total of synced notes is stored; percentage unavailable.',
    );
  }
}
