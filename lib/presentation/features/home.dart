import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../design/agent_ui.dart';
import '../navigation.dart';
import '../shared/scope.dart';
import '../shared/widgets.dart';

/// H05 — the permission-aware executive workspace.
///
/// All counters originate from the authenticated server bootstrap/home response.
/// Screens and mutations remain hidden without their effective delegation bits.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final color = Theme.of(context).colorScheme;
    final person = str(app.user['name'] ?? obj(app.profile['user'])['name']).trim();
    final name = person.isEmpty ? context.tr('شريكنا', 'Partner') : person;
    final doctor = app.access.doctor;
    final delegated = app.grant != null;
    final available = payload(obj(app.profile['profile']))['isAvailable'] == true;

    final primaryActions = <_ActionSpec>[
      if (doctor) _ActionSpec('C01', context.tr('الاستشارات', 'Consultations'),
        Icons.medical_services_outlined, AgentPalette.forest),
      if (doctor) _ActionSpec('F01', context.tr('المهام الميدانية', 'Field tasks'),
        Icons.location_on_outlined, AgentPalette.blue),
      if (doctor) _ActionSpec('F03', context.tr('جدول الزيارات', 'Visit calendar'),
        Icons.calendar_month_outlined, AgentPalette.violet),
      if (app.allows(Cap.sell | Cap.cash))
        _ActionSpec('T02', context.tr('إجراء بيع', 'New sale'),
          Icons.shopping_cart_checkout_rounded, AgentPalette.emerald),
      if (app.allows(Cap.inventory))
        _ActionSpec('I01', context.tr('المخزون', 'Inventory'),
          Icons.inventory_2_outlined, AgentPalette.amber),
      if (app.allows(Cap.dispense) && app.access.dispenser)
        _ActionSpec('C13', context.tr('صرف وصفة', 'Dispense prescription'),
          Icons.medication_liquid_outlined, AgentPalette.forest),
      if (app.allows(Cap.cash))
        _ActionSpec('N03', context.tr('الوردية النقدية', 'Cash shift'),
          Icons.account_balance_wallet_outlined, AgentPalette.violet),
      if (app.allows(Cap.auction))
        _ActionSpec('A01', context.tr('المزادات', 'Auctions'),
          Icons.gavel_rounded, AgentPalette.amber),
    ];
    final extraActions = <_ActionSpec>[
      if (doctor) _ActionSpec('C12', context.tr('الوصفات', 'Prescriptions'),
          Icons.medication_outlined, AgentPalette.forest),
      if (doctor) _ActionSpec('F09', context.tr('حملات التلقيح', 'Vaccination'),
          Icons.vaccines_outlined, AgentPalette.blue),
      if (app.allows(Cap.inventory))
        _ActionSpec('I05', context.tr('تنبيهات المخزون', 'Stock alerts'),
            Icons.notification_important_outlined, AgentPalette.amber),
      if (app.allows(Cap.transfer))
        _ActionSpec('I06', context.tr('التحويلات', 'Transfers'),
            Icons.move_up_outlined, AgentPalette.violet),
      if (app.allows(Cap.purchase))
        _ActionSpec('T12', context.tr('طلبات الشراء', 'Procurement'),
            Icons.add_shopping_cart_outlined, AgentPalette.emerald),
      if (app.allows(Cap.pickup))
        _ActionSpec('P01', context.tr('نقاط الاستلام', 'Pickup points'),
            Icons.store_mall_directory_outlined, AgentPalette.blue),
      if (app.allows(Cap.inventory))
        _ActionSpec('G01', context.tr('المقترحات', 'Proposals'),
            Icons.lightbulb_outlined, AgentPalette.amber),
      if (app.allows(Cap.inventory))
        _ActionSpec('N08', context.tr('تقارير الفرع', 'Branch reports'),
            Icons.query_stats_outlined, AgentPalette.forest),
      if (app.allows(Cap.inventory))
        _ActionSpec('T06', context.tr('فواتير المبيعات', 'Sales invoices'),
            Icons.receipt_long_outlined, AgentPalette.blue),
      if (app.allows(Cap.inventory))
        _ActionSpec('T03', context.tr('مسح باركود', 'Scan barcode'),
            Icons.qr_code_scanner, AgentPalette.violet),
    ];
    final stats = <_MetricSpec>[
      if (doctor)
        _MetricSpec(context.tr('استشارات جديدة', 'New consultations'),
          numId(app.summary['caseOffers']), Icons.mark_unread_chat_alt_outlined,
          'C01', AgentPalette.emerald),
      if (doctor)
        _MetricSpec(context.tr('حالات نشطة', 'Active cases'),
          numId(app.summary['activeCases']), Icons.monitor_heart_outlined,
          'C01', AgentPalette.blue),
      if (app.allows(Cap.cash))
        _MetricSpec(context.tr('ورديات مفتوحة', 'Open shifts'),
          numId(app.summary['openShifts']), Icons.account_balance_wallet_outlined,
          'N03', AgentPalette.violet),
      if (app.allows(Cap.inventory))
        _MetricSpec(context.tr('مقترحات معلقة', 'Pending proposals'),
          numId(app.summary['pendingProposals']), Icons.pending_actions_outlined,
          'G01', AgentPalette.amber),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        try { await app.refreshAccess(); }
        catch (error) { if (context.mounted) toast(context, failureText(context, error)); }
      },
      child: PageBody(children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 9, 0, 14),
          child: Row(children: [
            InkWell(
              onTap: () => context.open('H08'), borderRadius: BorderRadius.circular(50),
              child: CircleAvatar(radius: 27, backgroundColor: color.primaryContainer,
                child: Icon(Icons.person_rounded, color: color.primary, size: 30)),
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${context.tr('مرحبًا،', 'Welcome,')} $name',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900, fontSize: 17),
                overflow: TextOverflow.ellipsis, maxLines: 1),
              Text(doctor
                ? context.tr('طبيب بيطري معتمد', 'Approved veterinarian')
                : context.tr('مساحة عمل الوكيل', 'Agent workspace'),
                style: Theme.of(context).textTheme.bodySmall),
            ])),
            IconButton.filledTonal(
              tooltip: context.tr('الإشعارات', 'Notifications'),
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () => context.open('H07')),
          ]),
        ),
        AgentHero(
          title: context.tr('كل أعمالك في مكان واحد', 'Everything you need in one place'),
          subtitle: context.tr('الاستشارات والزيارات والمخزون والمبيعات، وفق صلاحياتك.',
              'Clinical work, visits and branch commerce — based on your access.'),
          art: 'assets/images/agent_workspace.webp',
          icon: Icons.spa_outlined,
        ),
        const SizedBox(height: 14),
        AgentSurface(padding: const EdgeInsets.all(13),
          onTap: () => context.open('H06'),
          child: Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(color: AgentPalette.mint,
                borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.storefront_outlined,
                color: AgentPalette.forest)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('نطاق العمل الحالي', 'Active work context'),
                  style: Theme.of(context).textTheme.labelLarge),
                Text(delegated
                  ? '${context.tr('المخزن', 'Warehouse')} #${app.grant!.warehouse} · ${context.tr('الفرع', 'Store')} #${app.grant!.store}'
                  : context.tr('لم يتم تفويض فرع بعد', 'No delegated branch yet'),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
              ])),
            const Icon(Icons.unfold_more_rounded, color: AgentPalette.forest),
          ])),
        if (doctor) ...[
          const SizedBox(height: 10),
          AgentSurface(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            child: Row(children: [
              Icon(Icons.verified_outlined, color: available
                ? AgentPalette.emerald : AgentPalette.amber),
              const SizedBox(width: 9),
              Expanded(child: Text(available
                ? context.tr('متاح لاستقبال الاستشارات', 'Available for consultations')
                : context.tr('استقبال الاستشارات متوقف', 'Consultations paused'),
                style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700))),
              Switch.adaptive(value: available, onChanged: (next) async {
                try {
                  await app.repo.write('PATCH', '/api/agent/availability',
                    {'available': next});
                  await app.refreshAccess();
                } catch (error) {
                  if (context.mounted) toast(context, failureText(context, error));
                }
              }),
            ])),
        ],
        if (stats.isNotEmpty) ...[
          AgentSectionHeading(title: context.tr('ملخص أعمالي', 'My activity'),
            icon: Icons.insights_outlined,
            action: TextButton(onPressed: () => context.open('N08'),
              child: Text(context.tr('التقارير', 'Reports')))),
          LayoutBuilder(builder: (context, constraints) {
            final cellWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(spacing: 10, runSpacing: 10, children: [
              for (final item in stats)
                SizedBox(width: cellWidth, child: AgentMetric(
                  label: item.title, value: display(context, item.count),
                  icon: item.icon, color: item.color,
                  onTap: () => context.open(item.route))),
            ]);
          }),
        ],
        if (primaryActions.isNotEmpty) ...[
          AgentSectionHeading(title: context.tr('إجراءات سريعة', 'Quick actions'),
            icon: Icons.bolt_rounded),
          _ActionGrid(primaryActions),
        ],
        if (doctor) ...[
          AgentSectionHeading(title: context.tr('المهام القادمة', 'Upcoming tasks'),
            icon: Icons.assignment_outlined,
            action: TextButton(onPressed: () => context.open('F01'),
              child: Text(context.tr('عرض الكل', 'See all')))),
          Resource(
            identity: 'home-tasks:${app.revision}:${app.refreshTick}',
            embedded: true,
            load: () => app.page('/api/agent/field/tasks'),
            builder: (data, refresh) {
              final items = rows(data).where((row) =>
                !{'Completed','Cancelled','Rejected'}.contains(str(row['status']))).toList();
              if (items.isEmpty) return AgentSurface(
                child: Row(children: [
                  const Icon(Icons.event_available_outlined, size: 30,
                    color: AgentPalette.forest),
                  const SizedBox(width: 12),
                  Expanded(child: Text(context.tr(
                    'لا توجد مهام معلقة في الوقت الحالي.',
                    'There are no pending tasks right now.'))),
                ]));
              items.sort((a, b) =>
                str(a['scheduledDate']).compareTo(str(b['scheduledDate'])));
              return Column(children: [
                for (final task in items.take(3)) ...[
                  AgentSurface(onTap: () => context.open('F02',
                    id: numId(task['id']), seed: task),
                    padding: const EdgeInsets.all(13),
                    child: Row(children: [
                      Container(width: 45, height: 45,
                        decoration: BoxDecoration(color: AgentPalette.mint,
                          borderRadius: BorderRadius.circular(13)),
                        child: const Icon(Icons.event_note_outlined,
                          color: AgentPalette.forest)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titleOf(task), maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge),
                          Text(display(context, task['scheduledDate']),
                            style: Theme.of(context).textTheme.bodySmall),
                        ])),
                      Icon(Icons.chevron_left_rounded, color: color.primary),
                    ])),
                  const SizedBox(height: 8),
                ],
              ]);
            },
          ),
        ],
        if (extraActions.isNotEmpty) ...[
          AgentSectionHeading(title: context.tr('المزيد من الخدمات', 'More services'),
            icon: Icons.apps_rounded),
          _ActionGrid(extraActions),
        ],
        if (!doctor && !delegated) ...[
          const SizedBox(height: 18),
          Notice(context.tr(
            'تظهر الخدمات بعد اعتماد الترخيص أو تفويضك داخل فرع. يمكنك مراجعة حالة حسابك.',
            'Services become available after approval or branch delegation.')),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => context.open('H04'),
            icon: const Icon(Icons.verified_user_outlined),
            label: Text(context.tr('التحقق من الصلاحيات', 'Review access'))),
        ],
        const SizedBox(height: 22),
        Center(child: Text(context.tr('مزرعتي • شريكك في كل خطوة',
          'Mazraa • With you at every step'),
          style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: color.onSurfaceVariant))),
      ]),
    );
  }
}

class _ActionSpec {
  const _ActionSpec(this.route, this.title, this.icon, this.color);
  final String route, title;
  final IconData icon;
  final Color color;
}

class _MetricSpec {
  const _MetricSpec(this.title, this.count, this.icon, this.route, this.color);
  final String title, route;
  final int count;
  final IconData icon;
  final Color color;
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid(this.items);
  final List<_ActionSpec> items;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final count = box.maxWidth >= 420 ? 4 : 3;
    final width = (box.maxWidth - 10 * (count - 1)) / count;
    return Wrap(spacing: 10, runSpacing: 10, children: [
      for (final item in items)
        SizedBox(width: width, child: AgentAction(
          title: item.title, icon: item.icon, color: item.color,
          onTap: () => context.open(item.route))),
    ]);
  });
}
