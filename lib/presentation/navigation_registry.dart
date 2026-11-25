import 'package:flutter/material.dart';
import '../application/agent_app.dart';
import '../domain/screens.dart';
import '../domain/models.dart';

/// The documented screen IDs, capabilities, and account context are the sole
/// source of destinations. A navigation tap opens a route/chooser, never posts
/// a transaction or silently bypasses the server's permission checks.
enum AgentWorkspace {
  home, clinic, field, branch, account,
  sales, inventory, finance, pickup, purchasing, auctions,
}

class AgentNavItem {
  const AgentNavItem(
    this.route, this.ar, this.en, this.icon, {
    this.highlight = false,
  });

  final String route, ar, en;
  final IconData icon;
  final bool highlight;

  String label(bool arabic) => arabic ? ar : en;

  AgentNavItem asPrimary() => AgentNavItem(route, ar, en, icon, highlight: true);
}

class AgentNavLayout {
  const AgentNavLayout(this.workspace, this.items, this.primaryIndex);
  final AgentWorkspace workspace;
  /// Logical order: right to left in Arabic, left to right in English.
  final List<AgentNavItem> items;
  final int primaryIndex;
}

abstract final class AgentNavigationRegistry {
  static String title(AgentWorkspace workspace, bool ar) => switch (workspace) {
    AgentWorkspace.home => ar ? 'الرئيسية' : 'Home',
    AgentWorkspace.clinic => ar ? 'العيادة' : 'Clinic',
    AgentWorkspace.field => ar ? 'الميدان' : 'Field',
    AgentWorkspace.branch => ar ? 'عمليات الفرع' : 'Branch',
    AgentWorkspace.account => ar ? 'حسابي' : 'Account',
    AgentWorkspace.sales => ar ? 'المبيعات' : 'Sales',
    AgentWorkspace.inventory => ar ? 'المخزون' : 'Inventory',
    AgentWorkspace.finance => ar ? 'المالية' : 'Finance',
    AgentWorkspace.pickup => ar ? 'الاستلام' : 'Pickup',
    AgentWorkspace.purchasing => ar ? 'المشتريات' : 'Purchasing',
    AgentWorkspace.auctions => ar ? 'المزادات' : 'Auctions',
  };

  static bool allowed(AgentApp app, String route) {
    return app.canOpen(screen(route));
  }

  static bool hasBranchAccess(AgentApp app) =>
      app.grant != null &&
      [Cap.inventory, Cap.sell, Cap.purchase, Cap.transfer, Cap.count,
       Cap.cash, Cap.pickup, Cap.auction]
          .any((capability) => app.allows(capability));

  static bool canEnter(AgentApp app, AgentWorkspace workspace) =>
      switch (workspace) {
        AgentWorkspace.home || AgentWorkspace.account => true,
        AgentWorkspace.clinic => allowed(app, 'C01'),
        AgentWorkspace.field => allowed(app, 'F01'),
        AgentWorkspace.branch => hasBranchAccess(app),
        AgentWorkspace.sales => ['T02','T06','T09'].any((route) => allowed(app, route)),
        AgentWorkspace.inventory => allowed(app, 'I01') || allowed(app, 'I09'),
        AgentWorkspace.finance => allowed(app, 'N01'),
        AgentWorkspace.pickup => allowed(app, 'P02'),
        AgentWorkspace.purchasing => allowed(app, 'T12') || allowed(app, 'T11'),
        AgentWorkspace.auctions => allowed(app, 'A01'),
      };

  static List<AgentWorkspace> available(AgentApp app) =>
      AgentWorkspace.values.where((item) => canEnter(app, item)).toList();

  static String entry(AgentApp app, AgentWorkspace workspace) {
    final choices = switch (workspace) {
      AgentWorkspace.home => ['H05'],
      AgentWorkspace.clinic => ['C01'],
      AgentWorkspace.field => ['F01'],
      AgentWorkspace.branch => ['T01', 'I01', 'N01', 'P02', 'A01'],
      AgentWorkspace.account => ['H08'],
      AgentWorkspace.sales => ['T02', 'T06', 'T09'],
      AgentWorkspace.inventory => ['I01', 'I09'],
      AgentWorkspace.finance => ['N01'],
      AgentWorkspace.pickup => ['P02'],
      AgentWorkspace.purchasing => ['T13','T11','T12'],
      AgentWorkspace.auctions => ['A01'],
    };
    return choices.firstWhere((route) => allowed(app, route),
        orElse: () => 'H05');
  }

  static AgentWorkspace? workspaceForEntry(String route) {
    if (route == 'H05' || route == 'H01') return AgentWorkspace.home;
    if (route.startsWith('H')) return AgentWorkspace.account;
    if (route.startsWith('C')) return AgentWorkspace.clinic;
    if (route.startsWith('F')) return AgentWorkspace.field;
    if (route.startsWith('I')) return AgentWorkspace.inventory;
    if (route.startsWith('N')) return AgentWorkspace.finance;
    if (route.startsWith('P')) return AgentWorkspace.pickup;
    if (route.startsWith('A')) return AgentWorkspace.auctions;
    if (route.startsWith('G') || route == 'T01') return AgentWorkspace.branch;
    if (route == 'T07') return null; // Receipt keeps its sales or purchase origin.
    if (['T10','T11','T12','T13','T14'].contains(route)) return AgentWorkspace.purchasing;
    return route.startsWith('T') ? AgentWorkspace.sales : null;
  }

  static AgentNavLayout resolve(AgentApp app, AgentWorkspace wanted) {
    final workspace = canEnter(app, wanted) ? wanted : AgentWorkspace.home;
    final side = <AgentNavItem>[];
    final candidates = <AgentNavItem>[];

    switch (workspace) {
      case AgentWorkspace.home:
        side.addAll(const [
          AgentNavItem('H05', 'الرئيسية', 'Home', Icons.home_rounded),
          AgentNavItem('C01', 'العيادة', 'Clinic', Icons.medical_services_outlined),
          AgentNavItem('F01', 'الميدان', 'Field', Icons.location_on_outlined),
          AgentNavItem('T01', 'الفرع', 'Branch', Icons.storefront_outlined),
        ]);
        candidates.addAll(const [
          AgentNavItem('T02', 'البيع', 'Sell', Icons.shopping_cart_outlined),
          AgentNavItem('I01', 'المخزون', 'Inventory', Icons.inventory_2_outlined),
          AgentNavItem('N01', 'المالية', 'Finance', Icons.account_balance_wallet_outlined),
          AgentNavItem('P02', 'الاستلام', 'Pickup', Icons.local_shipping_outlined),
          AgentNavItem('A01', 'المزادات', 'Auctions', Icons.gavel_outlined),
          AgentNavItem('T12', 'المشتريات', 'Purchases', Icons.add_shopping_cart_outlined),
          AgentNavItem('T01', 'الفرع', 'Branch', Icons.storefront_outlined),
          AgentNavItem('C01', 'استشاراتي', 'Cases', Icons.medical_services_outlined),
          AgentNavItem('F01', 'مهامي', 'Tasks', Icons.assignment_outlined),
        ]);
      case AgentWorkspace.clinic:
        side.addAll(const [
          AgentNavItem('C01', 'الإحالات', 'Referrals', Icons.assignment_outlined),
          AgentNavItem('C12', 'الوصفات', 'Prescriptions', Icons.medication_outlined),
        ]);
        candidates.add(const AgentNavItem('C01', 'استشاراتي', 'My cases', Icons.medical_services_outlined));
      case AgentWorkspace.field:
        side.addAll(const [
          AgentNavItem('F01', 'مهامي', 'My tasks', Icons.assignment_outlined),
          AgentNavItem('F03', 'التقويم', 'Calendar', Icons.calendar_month_outlined),
          AgentNavItem('F09', 'الحملات', 'Campaigns', Icons.groups_outlined),
        ]);
        candidates.add(const AgentNavItem('F05', 'زياراتي', 'Visits', Icons.location_on_outlined));
      case AgentWorkspace.branch:
        side.addAll(const [
          AgentNavItem('T06', 'الفواتير', 'Invoices', Icons.receipt_long_outlined),
          AgentNavItem('P02', 'الاستلام', 'Pickup', Icons.local_shipping_outlined),
          AgentNavItem('I01', 'المخزون', 'Inventory', Icons.inventory_2_outlined),
          AgentNavItem('N01', 'المالية', 'Finance', Icons.account_balance_wallet_outlined),
        ]);
        candidates.addAll(const [
          AgentNavItem('T02', 'البيع', 'Sell', Icons.shopping_cart_outlined),
          AgentNavItem('I01', 'المخزون', 'Inventory', Icons.inventory_2_outlined),
          AgentNavItem('N01', 'المالية', 'Finance', Icons.account_balance_wallet_outlined),
          AgentNavItem('P02', 'الاستلام', 'Pickup', Icons.local_shipping_outlined),
          AgentNavItem('A01', 'المزادات', 'Auctions', Icons.gavel_outlined),
          AgentNavItem('T12', 'المشتريات', 'Purchase', Icons.add_shopping_cart_outlined),
          AgentNavItem('T01', 'الفرع', 'Branch', Icons.storefront_outlined),
        ]);
      case AgentWorkspace.account:
        side.addAll(const [
          AgentNavItem('H07', 'التنبيهات', 'Alerts', Icons.notifications_none_rounded),
          AgentNavItem('H06', 'النطاق', 'Scope', Icons.storefront_outlined),
          AgentNavItem('H09', 'المزامنة', 'Sync', Icons.sync_outlined),
          AgentNavItem('H11', 'الأمان', 'Security', Icons.shield_outlined),
        ]);
        candidates.add(const AgentNavItem('H08', 'حسابي', 'Account', Icons.person_outline_rounded));
      case AgentWorkspace.sales:
        side.addAll(const [
          AgentNavItem('T06', 'الفواتير', 'Invoices', Icons.receipt_long_outlined),
          AgentNavItem('T09', 'العروض', 'Quotes', Icons.request_quote_outlined),
          AgentNavItem('T08', 'المرتجعات', 'Returns', Icons.assignment_return_outlined),
          AgentNavItem('N07', 'التسويات', 'Settlement', Icons.account_balance_outlined),
        ]);
        candidates.addAll(const [
          AgentNavItem('T02', 'نقطة البيع', 'Checkout', Icons.shopping_cart_outlined),
          AgentNavItem('T09', 'عروض الأسعار', 'Quotes', Icons.request_quote_outlined),
        ]);
      case AgentWorkspace.inventory:
        side.addAll(const [
          AgentNavItem('I01', 'الأرصدة', 'Stock', Icons.inventory_2_outlined),
          AgentNavItem('I06', 'التحويلات', 'Transfers', Icons.swap_horiz_outlined),
          AgentNavItem('I05', 'التنبيهات', 'Alerts', Icons.notifications_active_outlined),
        ]);
        candidates.addAll(const [
          AgentNavItem('I09', 'الجرد', 'Count', Icons.fact_check_outlined),
          AgentNavItem('I01', 'المخزون', 'Inventory', Icons.inventory_2_outlined),
        ]);
      case AgentWorkspace.finance:
        side.addAll(const [
          AgentNavItem('N01', 'الصندوق', 'Cashbox', Icons.account_balance_wallet_outlined),
          AgentNavItem('N02', 'الحركات', 'Movements', Icons.swap_horiz_outlined),
          AgentNavItem('N07', 'التسويات', 'Settlement', Icons.receipt_long_outlined),
          AgentNavItem('N05', 'الكشوف', 'Statements', Icons.article_outlined),
        ]);
        candidates.add(const AgentNavItem('N03', 'الوردية', 'Shift', Icons.access_time_outlined));
      case AgentWorkspace.pickup:
        side.addAll(const [
          AgentNavItem('P02', 'الطابور', 'Queue', Icons.list_alt_outlined),
          AgentNavItem('P01', 'نقاط الاستلام', 'Pickup points', Icons.location_on_outlined),
        ]);
        candidates.add(const AgentNavItem('P06', 'الجاهزة', 'Ready', Icons.handshake_outlined));
      case AgentWorkspace.purchasing:
        side.addAll(const [
          AgentNavItem('T11', 'المشتريات', 'Purchases', Icons.receipt_long_outlined),
          AgentNavItem('T10', 'الموردون', 'Suppliers', Icons.groups_outlined),
          AgentNavItem('T13', 'الاستلام', 'Receiving', Icons.inventory_2_outlined),
          AgentNavItem('T14', 'المرتجعات', 'Returns', Icons.assignment_return_outlined),
        ]);
        candidates.add(const AgentNavItem('T12', 'طلب شراء', 'Request', Icons.add_shopping_cart_outlined));
      case AgentWorkspace.auctions:
        side.addAll(const [
          AgentNavItem('A01', 'مزاداتي', 'Auctions', Icons.gavel_outlined),
        ]);
        candidates.add(const AgentNavItem('A02', 'مزاد جديد', 'New auction', Icons.add_circle_outline));
    }

    bool visible(AgentNavItem item) => allowed(app, item.route)
        && (item.route != 'T01' || hasBranchAccess(app));
    final primary = candidates.where(visible).firstOrNull;
    const home = AgentNavItem('H05', 'الرئيسية', 'Home', Icons.home_rounded);
    final options = <AgentNavItem>[home];
    final seen = {'H05', if (primary != null) primary.route};
    for (final item in side) {
      if (visible(item) && seen.add(item.route)) options.add(item);
    }
    if (primary == null) return AgentNavLayout(workspace, options.take(5).toList(), -1);
    final before = options.take(2).toList();
    return AgentNavLayout(workspace, [
      ...before, primary.asPrimary(), ...options.skip(2).take(2),
    ], before.length);
  }
}
