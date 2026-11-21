import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../navigation.dart';
import '../shared/scope.dart';
import '../shared/widgets.dart';

/// A permission-aware workspace. Only server-backed counters are displayed;
/// unavailable commerce totals are deliberately not replaced with demo data.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final colors = Theme.of(context).colorScheme;
    final isDoctor = app.access.doctor;
    final hasBranch = app.grant != null;

    final priority = <_HomeLink>[
      if (isDoctor)
        _HomeLink(context.tr('الاستشارات', 'Consultations'),
            Icons.medical_services_outlined, 'C01'),
      if (app.allows(Cap.sell | Cap.cash))
        _HomeLink(context.tr('نقطة البيع', 'Point of sale'),
            Icons.point_of_sale_outlined, 'T02'),
      if (app.allows(Cap.inventory))
        _HomeLink(context.tr('المخزون', 'Inventory'),
            Icons.inventory_2_outlined, 'I01'),
      if (isDoctor)
        _HomeLink(context.tr('المهام الميدانية', 'Field tasks'),
            Icons.assignment_outlined, 'F01'),
      if (app.allows(Cap.cash))
        _HomeLink(context.tr('صناديق الفرع', 'Cashboxes'),
            Icons.account_balance_wallet_outlined, 'N01'),
      if (app.allows(Cap.auction))
        _HomeLink(context.tr('المزادات', 'Auctions'),
            Icons.gavel_outlined, 'A01'),
    ];

    final more = <_HomeLink>[
      if (isDoctor)
        _HomeLink(context.tr('تقويم الزيارات', 'Visit calendar'),
            Icons.calendar_month_outlined, 'F03'),
      if (isDoctor)
        _HomeLink(context.tr('حملات التلقيح', 'Vaccination campaigns'),
            Icons.vaccines_outlined, 'F09'),
      if (app.allows(Cap.inventory))
        _HomeLink(context.tr('تنبيهات المخزون', 'Stock alerts'),
            Icons.notification_important_outlined, 'I05'),
      if (app.allows(Cap.transfer))
        _HomeLink(context.tr('التحويلات', 'Stock transfers'),
            Icons.swap_horiz_outlined, 'I06'),
      if (app.allows(Cap.count))
        _HomeLink(context.tr('جرد المخزون', 'Stock count'),
            Icons.fact_check_outlined, 'I09'),
      if (app.allows(Cap.purchase))
        _HomeLink(context.tr('طلبات الشراء', 'Purchase requests'),
            Icons.add_shopping_cart_outlined, 'T12'),
      if (app.allows(Cap.pickup))
        _HomeLink(context.tr('نقاط الاستلام', 'Pickup points'),
            Icons.local_shipping_outlined, 'P01'),
      if (app.allows(Cap.inventory))
        _HomeLink(context.tr('مقترحاتي', 'My proposals'),
            Icons.lightbulb_outline, 'G01'),
      if (app.allows(Cap.inventory))
        _HomeLink(context.tr('تقارير الفرع', 'Branch reports'),
            Icons.query_stats_outlined, 'N08'),
      if (app.allows(Cap.inventory))
        _HomeLink(context.tr('فواتير المبيعات', 'Sales invoices'),
            Icons.receipt_long_outlined, 'T06'),
      if (app.allows(Cap.cash))
        _HomeLink(context.tr('الوردية النقدية', 'Cash shift'),
            Icons.punch_clock_outlined, 'N03'),
      if (app.allows(Cap.inventory))
        _HomeLink(context.tr('مسح منتج', 'Scan product'),
            Icons.qr_code_scanner_outlined, 'T03'),
    ];

    final metrics = <_HomeMetricData>[
      if (isDoctor)
        _HomeMetricData(
          context.tr('استشارات جديدة', 'New consultations'),
          numId(app.summary['caseOffers']),
          Icons.mark_unread_chat_alt_outlined, 'C01',
          colors.secondary,
        ),
      if (isDoctor)
        _HomeMetricData(
          context.tr('حالات قيد المتابعة', 'Active cases'),
          numId(app.summary['activeCases']),
          Icons.monitor_heart_outlined, 'C01',
          colors.primary,
        ),
      if (app.allows(Cap.cash))
        _HomeMetricData(
          context.tr('ورديات مفتوحة', 'Open cash shifts'),
          numId(app.summary['openShifts']),
          Icons.account_balance_wallet_outlined, 'N03',
          colors.primary,
        ),
      if (app.allows(Cap.inventory))
        _HomeMetricData(
          context.tr('مقترحات معلقة', 'Pending proposals'),
          numId(app.summary['pendingProposals']),
          Icons.pending_actions_outlined, 'G01',
          colors.secondary,
        ),
    ];

    // The hero, warehouse context and availability now live in the pinned,
    // scroll-collapsing SliverAppBar, not in a duplicate body banner.
    return PageBody(children: [
      const SizedBox(height: 4),
      if (metrics.isNotEmpty) ...[
        _HomeHeading(context.tr('نظرة سريعة', 'At a glance'),
            subtitle: context.tr('بيانات مباشرة من حسابك', 'Live account figures')),
        LayoutBuilder(builder: (context, box) {
          final width = (box.maxWidth - 10) / 2;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (final metric in metrics)
              SizedBox(width: width, child: _HomeMetricCard(metric)),
          ]);
        }),
      ],

      if (priority.isNotEmpty) ...[
        _HomeHeading(context.tr('عمليات سريعة', 'Quick operations'),
            subtitle: context.tr('الأدوات الأكثر استخدامًا', 'Your everyday tools')),
        _HomeActionGrid(priority),
      ],

      if (isDoctor) ...[
        _HomeHeading(
          context.tr('جدول العمل والمتابعة', 'Schedule and follow-up'),
          action: TextButton(
            onPressed: () => context.open('F01'),
            child: Text(context.tr('كل المهام', 'All tasks')),
          ),
        ),
        Resource(
          identity: 'home-tasks:${app.revision}:${app.refreshTick}',
          embedded: true,
          load: () => app.page('/api/agent/field/tasks'),
          builder: (data, refresh) {
            final upcoming = rows(data).where((task) {
              final status = str(task['status']).toLowerCase();
              return !['completed', 'cancelled', 'rejected'].contains(status);
            }).toList()
              ..sort((a, b) {
                final first = DateTime.tryParse(str(a['scheduledDate']));
                final second = DateTime.tryParse(str(b['scheduledDate']));
                if (first == null) return second == null ? 0 : 1;
                if (second == null) return -1;
                return first.compareTo(second);
              });
            if (upcoming.isEmpty) {
              return _HomeEmptyTasks(
                onTap: () => context.open('F03'),
              );
            }
            return Column(children: [
              for (final task in upcoming.take(2)) ...[
                _HomeTaskCard(task),
                const SizedBox(height: 8),
              ],
            ]);
          },
        ),
      ],

      if (more.isNotEmpty) ...[
        _HomeHeading(context.tr('خدمات وإدارة الفرع', 'Services and branch management'),
            subtitle: context.tr(
              'إدارة العمليات حسب الصلاحيات الممنوحة لك',
              'Operations available to your current permissions',
            )),
        _HomeActionGrid(more),
      ],

      if (!isDoctor && !hasBranch) ...[
        const SizedBox(height: 22),
        Notice(context.tr(
          'ستظهر أدواتك فور اعتماد الحساب أو تفويضك في فرع. راجع الأهلية والصلاحيات.',
          'Your workspace appears after account approval or branch delegation. Review your access.',
        )),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => context.open('H04'),
          icon: const Icon(Icons.verified_user_outlined),
          label: Text(context.tr('الأهلية والصلاحيات', 'Access and eligibility')),
        ),
      ],

      Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Center(child: Text(
          context.tr('مزرعتي • شريكك في كل خطوة', 'Mazraa • With you at every step'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        )),
      ),
    ]);
  }
}

class _HomeLink {
  const _HomeLink(this.title, this.icon, this.route);
  final String title, route;
  final IconData icon;
}

class _HomeMetricData {
  const _HomeMetricData(this.label, this.value, this.icon, this.route, this.accent);
  final String label, route;
  final int value;
  final IconData icon;
  final Color accent;
}

class _HomeHeading extends StatelessWidget {
  const _HomeHeading(this.title, {this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 23, bottom: 11),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 4, height: subtitle == null ? 24 : 36,
          decoration: BoxDecoration(
            color: colors.secondary,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            if (subtitle != null)
              Text(subtitle!, style: text.bodySmall,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        )),
        if (action != null) action!,
      ]),
    );
  }
}

class _HomeMetricCard extends StatelessWidget {
  const _HomeMetricCard(this.metric);
  final _HomeMetricData metric;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.open(metric.route),
        child: Container(
          constraints: const BoxConstraints(minHeight: 122),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline.withValues(alpha: .65)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                height: 35, width: 35,
                decoration: BoxDecoration(
                  color: metric.accent.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(metric.icon, color: metric.accent, size: 21),
              ),
              Icon(Icons.arrow_outward_rounded, color: colors.onSurfaceVariant, size: 17),
            ]),
            const SizedBox(height: 7),
            Text(display(context, metric.value),
                style: text.headlineSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                )),
            Text(metric.label, style: text.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ), maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

class _HomeActionGrid extends StatelessWidget {
  const _HomeActionGrid(this.links);
  final List<_HomeLink> links;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final columns = box.maxWidth >= 350 ? 3 : 2;
      final width = (box.maxWidth - 10 * (columns - 1)) / columns;
      return Wrap(spacing: 10, runSpacing: 10, children: [
        for (final link in links)
          SizedBox(width: width, child: _HomeActionCard(link)),
      ]);
    });
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard(this.link);
  final _HomeLink link;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.open(link.route),
        child: Container(
          height: 104,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: colors.outline.withValues(alpha: .65)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: .75),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(link.icon, size: 25, color: colors.primary),
            ),
            const SizedBox(height: 7),
            Expanded(child: Center(child: Text(
              link.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 11.5,
                height: 1.25,
              ),
            ))),
          ]),
        ),
      ),
    );
  }
}

class _HomeTaskCard extends StatelessWidget {
  const _HomeTaskCard(this.task);
  final Json task;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final date = task['scheduledDate'];
    final subtitle = str(task['description']).trim();
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.open('F02', id: numId(task['id']), seed: task),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: colors.outline.withValues(alpha: .75)),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/agent_field.webp',
                width: 67, height: 72, fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titleOf(task),
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                if (date != null)
                  Text(display(context, date),
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left : Icons.chevron_right,
              color: colors.primary,
            ),
          ]),
        ),
      ),
    );
  }
}

class _HomeEmptyTasks extends StatelessWidget {
  const _HomeEmptyTasks({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: .46),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(Icons.event_available_outlined, color: colors.primary, size: 27),
        const SizedBox(width: 12),
        Expanded(child: Text(
          context.tr('لا توجد مهام قادمة في القائمة الحالية', 'No upcoming tasks in this list'),
          style: Theme.of(context).textTheme.bodyMedium,
        )),
        TextButton(
          onPressed: onTap,
          child: Text(context.tr('التقويم', 'Calendar')),
        ),
      ]),
    );
  }
}
