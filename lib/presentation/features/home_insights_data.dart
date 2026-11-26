import 'package:flutter/material.dart';
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
    InsightKind.purchasing => 'T12',
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
    'الفواتير المرحّلة خلال الفترة',
    'المهام والزيارات المسندة إليك',
    'الأرصدة والدفعات التي تستحق الانتباه',
    'الرصيد وحركة الصندوق خلال الفترة',
    'حالات الطلبات ضمن نطاقك',
    'حالة المزادات ومراجعاتها',
    'دورة طلبات الشراء المفوّضة',
    'نتائج المقترحات التي قدمتها',
    'مسودات الملاحظات السريرية المحلية',
  ] : const [
    'Your work requiring attention',
    'Assigned veterinary cases and offers',
    'Posted invoices during the reporting period',
    'Assigned field tasks and visits',
    'Stock items and batches requiring attention',
    'Balance and cash movements during the period',
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
    'Open work areas', 'Open consultations',
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
    if (!available(app).contains(kind)) throw const Failure(403, '');
    final revision = app.scopeRevision;
    final response = obj(await app.read(
      '/api/agent/operations/insights/${kind.name}',
      query: app.scoped(),
    ));
    if (revision != app.scopeRevision) throw const Failure(403, '');
    if (response['contractVersion'] != 1 || response['section'] != kind.name ||
        response['data'] is! Map) {
      throw const Failure(503, '');
    }
    final data = obj(response['data']);
    final period = obj(response['period']);
    final from = DateTime.tryParse(str(period['from']));
    final before = DateTime.tryParse(str(period['before']));
    final days = from != null && before != null
        ? [
            for (var day = from; day.isBefore(before); day = day.add(const Duration(days: 1)))
              day,
          ]
        : <DateTime>[];
    final labels = [
      for (final day in days)
        (app.ar ? const ['اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد']
            : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])[day.weekday - 1],
    ];
    final periodAr = days.isEmpty ? 'الحالة الحالية' : '${days.length} أيام · UTC';
    final periodEn = days.isEmpty ? 'Current' : '${days.length} days · UTC';

    InsightValue value(String ar, String en, String key) =>
        InsightValue(ar, en, _number(data[key]));

    List<double> daily(List<Json> records, String key) {
      final totals = <String, double>{};
      for (final row in records) {
        final date = str(row['date']).split('T').first;
        totals.update(date, (amount) => amount + decimal(row[key]),
            ifAbsent: () => decimal(row[key]));
      }
      return [for (final day in days) totals[day.toIso8601String().split('T').first] ?? 0];
    }

    switch (kind) {
      case InsightKind.overview:
        final values = [
          value('إحالات جديدة', 'New referrals', 'assignedCases'),
          value('حالات نشطة', 'Active cases', 'activeCases'),
          value('مقترحات معلّقة', 'Pending proposals', 'pendingProposals'),
          value('ورديات مفتوحة', 'Open shifts', 'openShifts'),
        ].where((item) => item.value != null).toList();
        return InsightSnapshot(headlineAr: 'المتابعة', headlineEn: 'Work to review',
          values: values, parts: values);
      case InsightKind.clinic:
        final values = [
          value('إحالات جديدة', 'Assigned referrals', 'currentAssigned'),
          value('حالات نشطة', 'Active cases', 'currentActive'),
          value('أُغلقت خلال الفترة', 'Closed during period', 'recordedClosuresInPeriod'),
        ];
        return InsightSnapshot(headline: values[1].value, headlineAr: 'حالات نشطة', headlineEn: 'Active cases',
          values: values, parts: values, periodAr: periodAr, periodEn: periodEn);
      case InsightKind.sales:
        final totals = maps(data['totalsByCurrency']);
        final selected = totals.where((row) => row['currency'] == app.currency).firstOrNull
            ?? totals.firstOrNull;
        final currency = str(selected?['currency'] ?? app.currency);
        final records = maps(data['daily']).where((row) => row['currency'] == currency).toList();
        return InsightSnapshot(headline: selected == null ? 0 : _number(selected['gross']),
          headlineAr: 'إجمالي الفواتير', headlineEn: 'Invoiced sales',
          currency: currency, periodAr: periodAr, periodEn: periodEn, days: labels,
          series: daily(records.where((row) => row['type'] == 'SalesInvoice').toList(), 'amount'),
          secondary: daily(records.where((row) => row['type'] == 'SalesReturn').toList(), 'amount'),
          values: [
            InsightValue('متوسط الفاتورة', 'Average invoice', _number(selected?['averageInvoice'])),
            InsightValue('مرتجعات البيع', 'Sales returns', selected == null ? 0 : _number(selected['salesReturns'])),
            InsightValue('عدد الفواتير', 'Invoice count', selected == null ? 0 : _number(selected['invoiceCount'])),
          ],
          noteAr: totals.length > 1 ? 'تعرض البطاقة مبالغ $currency فقط.' : '',
          noteEn: totals.length > 1 ? 'This chart shows $currency amounts.' : '');
      case InsightKind.field:
        final tasks = _breakdown(data['scheduledTaskStates']);
        return InsightSnapshot(headline: _number(data['completed']), headlineAr: 'زيارات مكتملة', headlineEn: 'Completed visits',
          periodAr: periodAr, periodEn: periodEn, days: labels, series: daily(maps(data['completedByDay']), 'count'),
          values: [
            value('زيارات جارية بدأت في الفترة', 'Visits started in period', 'startedInPeriod'),
            InsightValue('مهام بانتظار القبول', 'Tasks awaiting acceptance',
                tasks.where((item) => item.en == 'Assigned').firstOrNull?.value ?? 0),
          ]);
      case InsightKind.inventory:
        final values = [
          value('نافدة', 'Out of stock', 'unavailable'),
          value('عند حد إعادة الطلب', 'At reorder threshold', 'belowReorderPoint'),
          value('قريبة الانتهاء', 'Expiring batches', 'expiringBatches'),
          value('منتهية الصلاحية', 'Expired batches', 'expiredBatches'),
          value('دفعات محجوزة', 'Held batches', 'heldBatches'),
        ];
        return InsightSnapshot(headline: _number(data['totalStockRows']), headlineAr: 'أرصدة الأصناف', headlineEn: 'Stock records',
          values: values, parts: values,
          noteAr: 'تصف مؤشرات الدفعات أسبابًا قد تجتمع على الدفعة نفسها.',
          noteEn: 'A batch may meet more than one condition.');
      case InsightKind.finance:
        final records = maps(data['daily']);
        return InsightSnapshot(headline: _number(data['currentBalance']), headlineAr: 'الرصيد الحالي', headlineEn: 'Current balance',
          currency: str(data['currencyCode']), periodAr: periodAr, periodEn: periodEn, days: labels,
          series: daily(records.where((row) => row['direction'] == 'In').toList(), 'amount'),
          secondary: daily(records.where((row) => row['direction'] == 'Out').toList(), 'amount'),
          values: [value('تحصيل', 'Inflow', 'inflow'), value('صرف', 'Outflow', 'outflow')]);
      case InsightKind.pickup:
        final values = [
          value('بانتظار الحيازة', 'Awaiting custody', 'awaitingCustody'),
          value('جاهزة للتسليم', 'Ready to hand over', 'ready'),
          value('مسلّمة', 'Delivered', 'delivered'),
          value('استثناءات', 'Exceptions', 'exceptions'),
        ];
        return InsightSnapshot(headline: _number(data['total']), headlineAr: 'إجمالي الطلبات', headlineEn: 'Total requests',
          values: values, parts: values);
      case InsightKind.auctions:
      case InsightKind.purchasing:
      case InsightKind.proposals:
        final parts = _breakdown(data[switch (kind) {
          InsightKind.auctions => 'auctionsByStatus',
          InsightKind.purchasing => 'requestsByStatus',
          _ => 'proposalsByStatus',
        }]);
        return InsightSnapshot(headline: parts.fold<double>(0, (sum, item) => sum + (item.value ?? 0)),
          headlineAr: switch (kind) {
            InsightKind.auctions => 'إجمالي المزادات',
            InsightKind.purchasing => 'إجمالي طلبات الشراء',
            _ => 'إجمالي المقترحات',
          },
          headlineEn: switch (kind) {
            InsightKind.auctions => 'Total auctions',
            InsightKind.purchasing => 'Total purchase requests',
            _ => 'Total proposals',
          }, values: kind == InsightKind.auctions ? _breakdown(data['reviewsByStatus']) : parts, parts: parts);
      case InsightKind.sync:
        final local = (await app.notes()).length.toDouble();
        final last = DateTime.tryParse(str(data['lastConfirmedAt']))?.toLocal();
        return InsightSnapshot(headline: local, headlineAr: 'مسودات محلية', headlineEn: 'Local drafts',
          periodAr: periodAr, periodEn: periodEn,
          values: [InsightValue('المسودات', 'Drafts', local),
            value('أكد السيرفر مزامنتها', 'Confirmed by the server', 'confirmedInPeriod')],
          noteAr: last == null ? 'لم يُسجّل تأكيد مزامنة بعد.' : 'آخر تأكيد · ${last.toString().substring(0, 16)}',
          noteEn: last == null ? 'No confirmation has been recorded yet.' : 'Last confirmation · ${last.toString().substring(0, 16)}');
    }
  }

  static double? _number(Object? value) => value is num ? value.toDouble() : double.tryParse(str(value));

  static List<InsightValue> _breakdown(Object? source) => [
    for (final row in maps(source))
      InsightValue(switch (str(row['status'])) {
        'Draft' => 'مسودة',
        'Pending' => 'قيد المراجعة',
        'Approved' => 'معتمدة',
        'Active' => 'نشطة',
        'Completed' => 'مكتملة',
        'Rejected' => 'مرفوضة',
        'Cancelled' => 'ملغاة',
        'NeedsChanges' => 'تحتاج تعديلًا',
        'Scheduled' => 'مجدولة',
        'Ended' => 'منتهية',
        _ => str(row['status']),
      }, str(row['status']), _number(row['count'])),
  ];
}
