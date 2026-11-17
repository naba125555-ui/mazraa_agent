import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/screens.dart';
import '../shared/scope.dart';

enum ScreenLayout { workspace, collection, record, form, focused }

class ScreenDesign {
  const ScreenDesign(this.icon, this.layout, this.ar, this.en);
  final IconData icon;
  final ScreenLayout layout;
  final String ar;
  final String en;
}

const _work = ScreenLayout.workspace;
const _list = ScreenLayout.collection;
const _record = ScreenLayout.record;
const _form = ScreenLayout.form;
const _focus = ScreenLayout.focused;

const screenDesigns = <String, ScreenDesign>{
  'H01': ScreenDesign(
    Icons.spa_outlined,
    _work,
    'إدارة الاستشارات والمهام والفرع من تطبيق واحد.',
    'Manage consultations, field work and branch operations in one place.',
  ),
  'H02': ScreenDesign(
    Icons.login,
    _form,
    'استخدم البريد المخصص لك من الإدارة.',
    'Use the email assigned by your organization.',
  ),
  'H03': ScreenDesign(
    Icons.lock_reset,
    _record,
    'تواصل مع مسؤول الفرع لتأكيد الحساب واستعادة الوصول.',
    'Contact your branch administrator to verify and recover your account.',
  ),
  'H04': ScreenDesign(
    Icons.verified_user_outlined,
    _record,
    'تابع حالة الاعتماد البيطري وترخيص صرف الدواء.',
    'Check veterinary approval and dispensing authorization.',
  ),
  'H05': ScreenDesign(Icons.dashboard_outlined, _work, '', ''),
  'H06': ScreenDesign(
    Icons.warehouse_outlined,
    _list,
    'حدّد المخزن والصندوق المستخدمين في عمليات الفرع.',
    'Choose the warehouse and cashbox for branch operations.',
  ),
  'H07': ScreenDesign(
    Icons.notifications_none,
    _list,
    'راجع المستجدات وافتح السجل المرتبط بكل إشعار.',
    'Review updates and open the associated record.',
  ),
  'H08': ScreenDesign(Icons.person_outline, _work, '', ''),
  'H09': ScreenDesign(
    Icons.sync,
    _list,
    'تابع حالة المسودات والعمليات المعلقة قبل إعادة إرسالها.',
    'Check drafts and pending operations before resending.',
  ),
  'H10': ScreenDesign(
    Icons.support_agent,
    _list,
    'أنشئ تذكرة وتابع ردود فريق الدعم.',
    'Create a ticket and follow replies from support.',
  ),
  'H11': ScreenDesign(
    Icons.shield_outlined,
    _record,
    'أدر كلمة المرور والجلسات المتصلة بحسابك.',
    'Manage your password and connected sessions.',
  ),
  'C01': ScreenDesign(
    Icons.medical_services_outlined,
    _work,
    'راجع الإحالات الجديدة وتابع الحالات والوصفات.',
    'Review referrals and follow active cases and prescriptions.',
  ),
  'C02': ScreenDesign(Icons.assignment_ind_outlined, _record, '', ''),
  'C03': ScreenDesign(Icons.auto_awesome_outlined, _list, '', ''),
  'C04': ScreenDesign(Icons.forum_outlined, _focus, '', ''),
  'C05': ScreenDesign(
    Icons.collections_outlined,
    _list,
    'اطّلع على الصور والمستندات المرفقة بالحالة.',
    'Review images and documents attached to this case.',
  ),
  'C06': ScreenDesign(Icons.pets_outlined, _record, '', ''),
  'C07': ScreenDesign(Icons.cruelty_free_outlined, _list, '', ''),
  'C08': ScreenDesign(
    Icons.edit_note,
    _list,
    'دوّن التقييم السريري وراجع الإضافات المؤرخة.',
    'Document findings and review dated addenda.',
  ),
  'C09': ScreenDesign(
    Icons.event_available_outlined,
    _form,
    'حدّد توقيت الموعد وطريقة المتابعة مع العميل.',
    'Set the appointment time and how to follow up.',
  ),
  'C10': ScreenDesign(
    Icons.medication_liquid_outlined,
    _form,
    'حدّد الأدوية والجرعات قبل مراجعة الوصفة.',
    'Select medicines and doses before reviewing the prescription.',
  ),
  'C11': ScreenDesign(
    Icons.draw_outlined,
    _form,
    'تأكد من الأدوية والكميات والتعليمات قبل الاعتماد.',
    'Verify medicines, quantities and instructions before signing.',
  ),
  'C12': ScreenDesign(Icons.receipt_long_outlined, _record, '', ''),
  'C13': ScreenDesign(
    Icons.medication_outlined,
    _form,
    'سجّل الدفعات والكميات المصروفة لهذه الوصفة.',
    'Record the batches and quantities dispensed for this prescription.',
  ),
  'C14': ScreenDesign(Icons.shopping_bag_outlined, _list, '', ''),
  'C15': ScreenDesign(
    Icons.update,
    _form,
    'وثّق الخطوة التالية في متابعة الحالة.',
    'Document the next step in the case.',
  ),
  'C16': ScreenDesign(
    Icons.task_alt,
    _form,
    'أضف خلاصة الحالة ونتيجة المتابعة قبل إغلاقها.',
    'Add the case outcome and follow-up before closing.',
  ),
  'F01': ScreenDesign(
    Icons.assignment_outlined,
    _work,
    'تابع المهام المسندة إليك والزيارات والحملات.',
    'Follow assigned tasks, visits and campaigns.',
  ),
  'F02': ScreenDesign(Icons.assignment_ind_outlined, _record, '', ''),
  'F03': ScreenDesign(
    Icons.calendar_month_outlined,
    _list,
    'اختر تاريخًا لعرض المهام والزيارات المجدولة.',
    'Select a date to see scheduled tasks and visits.',
  ),
  'F04': ScreenDesign(
    Icons.directions_outlined,
    _record,
    'راجع موقع المهمة قبل فتح تطبيق الملاحة.',
    'Review the task location before opening navigation.',
  ),
  'F05': ScreenDesign(
    Icons.location_on_outlined,
    _form,
    'شارك موقع الوصول عند استعدادك لبدء الزيارة.',
    'Share your arrival location when you are ready to check in.',
  ),
  'F06': ScreenDesign(
    Icons.menu_book_outlined,
    _record,
    'راجع سجل الزيارة وانتقل إلى الإجراء المتاح حسب حالتها.',
    'Review the visit and continue with its available action.',
  ),
  'F07': ScreenDesign(Icons.pets_outlined, _list, '', ''),
  'F08': ScreenDesign(
    Icons.monitor_heart_outlined,
    _form,
    'سجّل مؤشرات الفحص والنتائج السريرية للحيوان.',
    'Record examination observations and clinical findings.',
  ),
  'F09': ScreenDesign(
    Icons.vaccines_outlined,
    _list,
    'افتح حملة لمراجعة التقدم والدفعات المخصصة لها.',
    'Open a campaign to review progress and allocated batches.',
  ),
  'F10': ScreenDesign(Icons.inventory_2_outlined, _record, '', ''),
  'F11': ScreenDesign(
    Icons.vaccines_outlined,
    _form,
    'وثّق الحيوان ودفعة اللقاح ونتيجة الإعطاء.',
    'Record the animal, vaccine batch and administration outcome.',
  ),
  'F12': ScreenDesign(
    Icons.thermostat_outlined,
    _record,
    'راجع سجل الحرارة وكميات اللقاح المخصصة والمستخدمة.',
    'Review temperature records and allocated and used vaccines.',
  ),
  'F13': ScreenDesign(
    Icons.fact_check_outlined,
    _form,
    'راجع تقرير الزيارة قبل إقفال المهمة.',
    'Review the visit report before closing the task.',
  ),
  'I01': ScreenDesign(
    Icons.inventory_2_outlined,
    _list,
    'راجع الأصناف والكميات المتاحة في المخزن المحدد.',
    'Review items and quantities in the selected warehouse.',
  ),
  'I02': ScreenDesign(Icons.inventory_outlined, _record, '', ''),
  'I03': ScreenDesign(
    Icons.qr_code_2,
    _list,
    'تتبّع أرقام الدفعات والصلاحية والأرقام التسلسلية.',
    'Track batch numbers, expiry and serial numbers.',
  ),
  'I04': ScreenDesign(
    Icons.swap_vert,
    _list,
    'راجع الإضافات والخصومات المسجلة على الصنف.',
    'Review the stock additions and deductions for this item.',
  ),
  'I05': ScreenDesign(
    Icons.warning_amber_outlined,
    _list,
    'راجع الدفعات القريبة من الانتهاء والأصناف غير المتوفرة.',
    'Review expiring batches and unavailable items.',
  ),
  'I06': ScreenDesign(
    Icons.swap_horiz,
    _list,
    'تابع التحويلات بين المخازن من الطلب إلى الاستلام.',
    'Follow warehouse transfers from request to receipt.',
  ),
  'I07': ScreenDesign(
    Icons.move_to_inbox_outlined,
    _form,
    'اختر مصدر التغذية وحدد الأصناف والكميات المطلوبة.',
    'Choose the stock source and requested items and quantities.',
  ),
  'I08': ScreenDesign(
    Icons.assignment_turned_in_outlined,
    _form,
    'طابق الكميات المستلمة مع مستند التحويل.',
    'Match received quantities to the transfer document.',
  ),
  'I09': ScreenDesign(
    Icons.checklist,
    _form,
    'سجّل الكمية الفعلية للأصناف المحددة في المخزن.',
    'Record the physical quantity for selected warehouse items.',
  ),
  'I10': ScreenDesign(
    Icons.difference_outlined,
    _list,
    'راجع فروق الجرد والتغييرات المسجلة في المخزن.',
    'Review count discrepancies and recorded warehouse changes.',
  ),
  'T01': ScreenDesign(Icons.storefront_outlined, _work, '', ''),
  'T02': ScreenDesign(Icons.point_of_sale, _list, '', ''),
  'T03': ScreenDesign(Icons.qr_code_scanner, _focus, '', ''),
  'T04': ScreenDesign(Icons.category_outlined, _record, '', ''),
  'T05': ScreenDesign(
    Icons.payments_outlined,
    _form,
    'راجع بنود البيع وحدد طريقة الدفع قبل إصدار الفاتورة.',
    'Review the sale and choose a payment method before issuing an invoice.',
  ),
  'T06': ScreenDesign(
    Icons.receipt_long_outlined,
    _list,
    'افتح فاتورة لمراجعة بنود البيع والإيصال.',
    'Open an invoice to review sale items and the receipt.',
  ),
  'T07': ScreenDesign(Icons.receipt_outlined, _record, '', ''),
  'T08': ScreenDesign(
    Icons.assignment_return_outlined,
    _form,
    'اربط المرتجع بفاتورة البيع وحدد البنود والكميات.',
    'Link the return to the sales invoice and select items and quantities.',
  ),
  'T09': ScreenDesign(
    Icons.request_quote_outlined,
    _form,
    'حدّد العميل والبنود لإنشاء عرض سعر.',
    'Choose the customer and items to create a quotation.',
  ),
  'T10': ScreenDesign(
    Icons.local_shipping_outlined,
    _list,
    'اختر موردًا لمراجعة بياناته.',
    'Select a supplier to review their details.',
  ),
  'T11': ScreenDesign(
    Icons.description_outlined,
    _list,
    'راجع مستندات المورد والبنود المستلمة.',
    'Review supplier documents and received items.',
  ),
  'T12': ScreenDesign(
    Icons.add_shopping_cart,
    _form,
    'اختر المورد وسجّل الأصناف والكميات المطلوبة.',
    'Choose a supplier and record the items and quantities needed.',
  ),
  'T13': ScreenDesign(
    Icons.inventory_outlined,
    _form,
    'طابق الأصناف الواردة مع طلب الشراء قبل تسجيل الاستلام.',
    'Match incoming items to the purchase request before recording receipt.',
  ),
  'T14': ScreenDesign(
    Icons.assignment_return_outlined,
    _form,
    'حدّد مستند الشراء والأصناف التي ستعاد للمورد.',
    'Select the purchase document and items to return to the supplier.',
  ),
  'N01': ScreenDesign(
    Icons.account_balance_wallet_outlined,
    _record,
    'راجع الصندوق المخصص للفرع ورصيد الوردية.',
    'Review the assigned cashbox and shift balance.',
  ),
  'N02': ScreenDesign(
    Icons.swap_vert,
    _list,
    'راجع الحركات النقدية المسجلة على الصندوق.',
    'Review cash transactions recorded for the cashbox.',
  ),
  'N03': ScreenDesign(
    Icons.access_time,
    _record,
    'ابدأ الوردية أو راجع حالة الوردية المفتوحة.',
    'Start a cash shift or review the open shift.',
  ),
  'N04': ScreenDesign(
    Icons.fact_check_outlined,
    _form,
    'قارن النقد الفعلي بالرصيد المتوقع قبل الإقفال.',
    'Compare counted cash with the expected balance before closing.',
  ),
  'N05': ScreenDesign(
    Icons.account_balance_outlined,
    _list,
    'حدّد الطرف والفترة لعرض حركات الحساب ورصيده.',
    'Choose an account and date range to view transactions and balances.',
  ),
  'N06': ScreenDesign(
    Icons.library_books_outlined,
    _list,
    'اعرض القيود المالية والمستندات المرتبطة بها.',
    'View financial entries and related documents.',
  ),
  'N07': ScreenDesign(
    Icons.price_check_outlined,
    _form,
    'حدّد الطرف والمبلغ لتسجيل التسوية.',
    'Choose the counterparty and amount to record a settlement.',
  ),
  'N08': ScreenDesign(
    Icons.insights_outlined,
    _work,
    'حلّل أداء الفرع حسب الفترة ونطاق العمل المحدد.',
    'Review branch performance by period and work context.',
  ),
  'P01': ScreenDesign(
    Icons.pin_drop_outlined,
    _list,
    'تابع نقاط الاستلام والطلبات المخصصة لنطاقك.',
    'Track pickup points and requests within your work context.',
  ),
  'P02': ScreenDesign(
    Icons.list_alt_outlined,
    _list,
    'افتح طلبًا لتحديد المرحلة والإجراء المتاح.',
    'Open a request to see its stage and available action.',
  ),
  'P03': ScreenDesign(Icons.inventory_outlined, _record, '', ''),
  'P04': ScreenDesign(
    Icons.move_to_inbox_outlined,
    _form,
    'وثّق استلام الشحنة من المصدر وسلامتها.',
    'Confirm receipt of the shipment from its source and its condition.',
  ),
  'P05': ScreenDesign(
    Icons.inventory_2_outlined,
    _form,
    'عيّن الرف وأكّد جاهزية الطلب للاستلام.',
    'Assign a shelf and mark the request ready for collection.',
  ),
  'P06': ScreenDesign(
    Icons.verified_outlined,
    _form,
    'تحقّق من رمز التسليم قبل تسليم الطلب.',
    'Verify the handover code before releasing the order.',
  ),
  'P07': ScreenDesign(
    Icons.report_problem_outlined,
    _form,
    'سجّل سبب التعذّر والإجراء المتخذ على الطلب.',
    'Record the issue and the action taken for this request.',
  ),
  'A01': ScreenDesign(
    Icons.gavel_outlined,
    _list,
    'أنشئ مزادًا أو تابع المزادات في نطاق عملك.',
    'Create an auction or follow auctions in your work context.',
  ),
  'A02': ScreenDesign(
    Icons.edit_calendar_outlined,
    _form,
    'حدّد عنوان المزاد ومواعيده وشروطه.',
    'Set the auction title, schedule and terms.',
  ),
  'A03': ScreenDesign(
    Icons.sell_outlined,
    _form,
    'أضف المعروض وحدّد سعر البدء والزيادة.',
    'Add auction lots, starting prices and bid increments.',
  ),
  'A04': ScreenDesign(
    Icons.add_a_photo_outlined,
    _form,
    'أرفق صورًا واضحة للعناصر المعروضة.',
    'Attach clear images for the items in the auction.',
  ),
  'A05': ScreenDesign(Icons.preview_outlined, _record, '', ''),
  'A06': ScreenDesign(
    Icons.publish_outlined,
    _form,
    'راجع بيانات المزاد والقرار المطلوب قبل النشر.',
    'Review auction details and the required decision before publishing.',
  ),
  'A07': ScreenDesign(
    Icons.equalizer,
    _record,
    'راجع المعروض والمزايدات المسجلة.',
    'Review auction lots and recorded bids.',
  ),
  'A08': ScreenDesign(
    Icons.local_shipping_outlined,
    _list,
    'تابع السداد والتسليم لكل طلب فائز.',
    'Track payment and delivery for winning orders.',
  ),
  'A09': ScreenDesign(
    Icons.qr_code_2,
    _record,
    'اعرض رمز المزاد أو شاركه.',
    'Show or share the auction code.',
  ),
  'G01': ScreenDesign(
    Icons.lightbulb_outline,
    _list,
    'تابع مقترحات المنتجات والخدمات ونتائج مراجعتها.',
    'Follow product and service proposals and their outcomes.',
  ),
  'G02': ScreenDesign(
    Icons.post_add,
    _form,
    'اشرح المقترح وأضف المعلومات التي تساعد الإدارة على تقييمه.',
    'Describe the proposal and add details that help reviewers assess it.',
  ),
  'G03': ScreenDesign(Icons.description_outlined, _record, '', ''),
  'G04': ScreenDesign(
    Icons.rule_outlined,
    _record,
    'راجع قرار الإدارة والملاحظات على الاقتراح.',
    'Review the decision and notes on the proposal.',
  ),
};

String areaName(BuildContext context, Area area) => switch (area) {
  Area.general => context.tr('مساحة العمل', 'Workspace'),
  Area.clinical => context.tr('الرعاية البيطرية', 'Veterinary care'),
  Area.field => context.tr('العمل الميداني', 'Field work'),
  Area.inventory => context.tr('المخزون', 'Inventory'),
  Area.trade => context.tr('عمليات الفرع', 'Branch operations'),
  Area.finance => context.tr('المالية', 'Finance'),
  Area.pickup => context.tr('الاستلام والتسليم', 'Pickup and handover'),
  Area.auction => context.tr('المزادات', 'Auctions'),
  Area.proposal => context.tr('المقترحات', 'Proposals'),
};

Color areaColor(BuildContext context, Area area) {
  final theme = Theme.of(context);
  final dark = theme.brightness == Brightness.dark;
  return switch (area) {
    Area.clinical => dark ? const Color(0xFF89D8CF) : const Color(0xFF176B64),
    Area.field => dark ? const Color(0xFFCEDD92) : const Color(0xFF526822),
    Area.finance => dark ? const Color(0xFFF2CC8F) : const Color(0xFF80551B),
    Area.auction => dark ? const Color(0xFFF2BAB0) : const Color(0xFF994434),
    Area.pickup => dark ? const Color(0xFFA9CBF9) : const Color(0xFF365F94),
    Area.proposal => dark ? const Color(0xFFC6BCEB) : const Color(0xFF65508D),
    _ => theme.colorScheme.primary,
  };
}

class ScreenIntroduction extends StatelessWidget {
  const ScreenIntroduction(
    this.spec, {
    super.key,
    this.recordId,
    this.record = const {},
  });
  final ScreenSpec spec;
  final int? recordId;
  final Json record;

  @override
  Widget build(BuildContext context) {
    final design = screenDesigns[spec.id]!;
    final theme = Theme.of(context);
    final color = areaColor(context, spec.area);
    final focused = design.layout == _focus;
    final workspace = design.layout == _work;
    final help = context.tr(design.ar, design.en);
    final value = titleOf(record);
    final contextLabel = recordId == null || recordId! <= 0
        ? null
        : value.startsWith('#')
        ? '${context.tr('السجل', 'Record')} #$recordId'
        : value;
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          16,
          focused ? 0 : 5,
          16,
          focused ? 5 : 10,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Container(
              padding: EdgeInsets.all(
                focused
                    ? 8
                    : workspace
                    ? 16
                    : 12,
              ),
              decoration: BoxDecoration(
                color: focused
                    ? Colors.transparent
                    : color.withValues(alpha: .075),
                borderRadius: BorderRadius.circular(17),
                border: focused
                    ? null
                    : Border.all(color: color.withValues(alpha: .19)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(focused ? 8 : 11),
                      child: Icon(
                        design.icon,
                        color: color,
                        size: focused ? 20 : 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            context.tr(spec.ar, spec.en),
                            style: workspace
                                ? theme.textTheme.headlineSmall
                                : theme.textTheme.titleLarge,
                          ),
                        ),
                        if (contextLabel != null)
                          Text(
                            contextLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: color,
                            ),
                          ),
                        if (help.isNotEmpty)
                          Text(
                            help,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WorkflowProgress extends StatelessWidget {
  const WorkflowProgress(this.route, {super.key});
  final String route;

  @override
  Widget build(BuildContext context) {
    final steps = switch (route) {
      'A02' || 'A03' || 'A04' => const ['A02', 'A03', 'A04'],
      'C10' || 'C11' => const ['C10', 'C11'],
      'T02' || 'T05' => const ['T02', 'T05'],
      _ => const <String>[],
    };
    if (steps.isEmpty) return const SizedBox.shrink();
    final current = steps.indexOf(route);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(19, 0, 19, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 710),
          child: Semantics(
            label: context.tr(
              'خطوة ${current + 1} من ${steps.length}',
              'Step ${current + 1} of ${steps.length}',
            ),
            child: Row(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0) const SizedBox(width: 7),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= current
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
