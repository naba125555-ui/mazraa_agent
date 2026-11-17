import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/screens.dart';
import '../design/screen_design.dart';
import '../navigation.dart';
import '../shared/charts.dart';
import '../shared/scope.dart';
import '../shared/section_banner.dart';
import '../shared/widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final theme = Theme.of(context);
    final name = str(
      app.user['name'] ?? obj(app.profile['user'])['name'],
    ).trim();
    final offers = app.summary['caseOffers'];
    final active = app.summary['activeCases'];
    final shifts = app.summary['openShifts'];
    final metrics = [
      if (app.access.doctor && offers != null)
        (
          'C01',
          Icons.mark_email_unread_outlined,
          context.tr('إحالات جديدة', 'New referrals'),
          offers,
        ),
      if (app.access.doctor && active != null)
        (
          'C01',
          Icons.monitor_heart_outlined,
          context.tr('حالات نشطة', 'Active cases'),
          active,
        ),
      if (app.allows(Cap.cash) && shifts != null)
        (
          'N03',
          Icons.account_balance_wallet_outlined,
          context.tr('ورديات مفتوحة', 'Open shifts'),
          shifts,
        ),
    ];
    return PageBody(
      children: [
        SectionBanner(
          art: SectionArt.workspace,
          title: name.isEmpty
              ? context.tr('مرحبًا بك في مزرعتي', 'Welcome to Mazraa')
              : '${context.tr('مرحبًا،', 'Welcome,')} $name',
          subtitle: context.tr(
            'متابعة العيادة والمهام والفرع',
            'Your cases, field work and branch',
          ),
        ),
        const SizedBox(height: 12),
        _WorkContextCard(),
        if (app.access.doctor) const _AvailabilityCard(),
        if (metrics.isNotEmpty) ...[
          Heading(context.tr('نظرة على العمل', 'Work at a glance')),
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 332
                  ? metrics.length
                  : metrics.length.clamp(1, 2);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: (box.maxWidth - (columns - 1) * 8) / columns,
                      child: MetricTile(
                        label: metric.$3,
                        value: display(context, metric.$4),
                        icon: metric.$2,
                        onTap: () => context.open(metric.$1),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        Heading(context.tr('إجراءات سريعة', 'Quick actions')),
        WorkspaceActions([
          if (app.access.doctor) 'C01',
          if (app.allows(Cap.cash | Cap.sell)) 'T02',
          'T03',
          if (app.allows(Cap.inventory)) 'I01',
          if (app.allows(Cap.cash)) 'N01',
          if (app.access.doctor) ...['C12', 'F03'],
        ]),
        if (app.access.doctor) ...[
          Heading(
            context.tr('المهام القادمة', 'Upcoming work'),
            action: TextButton(
              onPressed: () => context.open('F01'),
              child: Text(context.tr('عرض المهام', 'View tasks')),
            ),
          ),
          const _UpcomingTask(),
        ],
        if (offers != null && active != null && app.access.doctor) ...[
          Heading(context.tr('ملخص الاستشارات', 'Consultation overview')),
          RingChartCard(
            title: context.tr('الحالات حسب الحالة', 'Consultations by status'),
            values: [
              ChartValue(
                context.tr('إحالات جديدة', 'New referrals'),
                decimal(offers),
                theme.colorScheme.secondary,
              ),
              ChartValue(
                context.tr('حالات نشطة', 'Active cases'),
                decimal(active),
                theme.colorScheme.primary,
              ),
            ],
          ),
        ],
        if (!app.access.doctor && app.grant == null) ...[
          const SizedBox(height: 14),
          Empty(
            icon: Icons.verified_user_outlined,
            text: context.tr(
              'يمكنك متابعة اعتماد حسابك ونطاق العمل من صفحة الصلاحيات.',
              'Check your professional approval and work context on the access page.',
            ),
            action: OutlinedButton(
              onPressed: () => context.open('H04'),
              child: Text(context.tr('عرض الصلاحيات', 'View access')),
            ),
          ),
        ],
      ],
    );
  }
}

class _WorkContextCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final grant = app.grant;
    final theme = Theme.of(context);
    return RecordTile(
      {
        'title': grant == null
            ? context.tr('اختيار نطاق العمل', 'Choose work context')
            : grantName(context, grant),
      },
      icon: Icons.warehouse_outlined,
      subtitle: grant?.cashbox == null
          ? context.tr(
              'المخازن والصناديق المتاحة',
              'Assigned warehouses and cashboxes',
            )
          : str(grant!.json['cashBoxName']).isNotEmpty
          ? str(grant.json['cashBoxName'])
          : '${context.tr('الصندوق', 'Cashbox')} ${grant.cashbox}',
      onTap: () => context.open('H06'),
      trailing: Icon(Icons.unfold_more, color: theme.colorScheme.primary),
    );
  }
}

class _AvailabilityCard extends StatefulWidget {
  const _AvailabilityCard();

  @override
  State<_AvailabilityCard> createState() => _AvailabilityCardState();
}

class _AvailabilityCardState extends State<_AvailabilityCard> {
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final profile = payload(obj(app.profile['profile']));
    final available = profile['isAvailable'] == true;
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: SwitchListTile(
        secondary: const Icon(Icons.medical_services_outlined),
        title: Text(
          context.tr('التوفر للاستشارات', 'Consultation availability'),
        ),
        subtitle: Text(
          context.tr(
            available ? 'متاح الآن' : 'غير متاح الآن',
            available ? 'Available now' : 'Unavailable now',
          ),
        ),
        value: available,
        onChanged: saving
            ? null
            : (value) async {
                setState(() => saving = true);
                try {
                  await app.repo.write('PATCH', '/api/agent/availability', {
                    'available': value,
                  });
                  await app.refreshAccess();
                } catch (failure) {
                  if (context.mounted)
                    toast(context, failureText(context, failure));
                } finally {
                  if (mounted) setState(() => saving = false);
                }
              },
      ),
    );
  }
}

String grantName(BuildContext context, Grant grant) {
  final name = str(
    grant.json['warehouseName'] ?? obj(grant.json['warehouse'])['name'],
  ).trim();
  return name.isNotEmpty
      ? name
      : '${context.tr('المخزن', 'Warehouse')} #${grant.warehouse}';
}

class _UpcomingTask extends StatelessWidget {
  const _UpcomingTask();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Resource(
      embedded: true,
      identity: 'home-tasks:${app.revision}',
      load: () => app.page('/api/agent/field/tasks'),
      builder: (data, _) {
        final tasks =
            rows(data)
                .where(
                  (task) => ![
                    'Completed',
                    'Cancelled',
                    'Rejected',
                  ].contains(task['status']),
                )
                .toList()
              ..sort(
                (a, b) =>
                    str(a['scheduledDate']).compareTo(str(b['scheduledDate'])),
              );
        if (tasks.isEmpty)
          return Empty(
            icon: Icons.event_available_outlined,
            text: context.tr(
              'لا توجد مهام قادمة مسندة إليك.',
              'There are no upcoming tasks assigned to you.',
            ),
          );
        final task = tasks.first;
        return RecordTile(
          task,
          icon: Icons.event_outlined,
          subtitle: display(context, task['scheduledDate']),
          onTap: () => context.open('F02', id: numId(task['id']), seed: task),
        );
      },
    );
  }
}

class WorkspaceActions extends StatelessWidget {
  const WorkspaceActions(this.routes, {super.key});
  final List<String> routes;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 590
            ? 3
            : box.maxWidth >= 284
            ? 2
            : 1;
        const gap = 8.0;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final route in routes)
              if (app.canOpen(screen(route)))
                SizedBox(
                  width: (box.maxWidth - (columns - 1) * gap) / columns,
                  child: ActionTile(
                    title: app.tr(screen(route).ar, screen(route).en),
                    icon: screenDesigns[route]!.icon,
                    onTap: () => context.open(route),
                  ),
                ),
          ],
        );
      },
    );
  }
}
