import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/agent_app.dart';
import '../../domain/models.dart';
import '../navigation.dart';
import '../shared/forms.dart';
import '../shared/labels.dart';
import '../shared/scope.dart';
import '../shared/widgets.dart';

class SaleCheckout extends StatefulWidget {
  const SaleCheckout({
    super.key,
    required this.quote,
    this.existingQuote = const {},
  });

  final bool quote;
  final Json existingQuote;

  @override
  State<SaleCheckout> createState() => _SaleCheckoutState();
}

class _SaleCheckoutState extends State<SaleCheckout> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _paid = TextEditingController();
  final _bank = TextEditingController();
  final _discount = TextEditingController();
  final _customerFocus = FocusNode();
  late List<Json> _lines;
  int? _scope;
  int _partyId = 0;
  int _searchGeneration = 0;
  Timer? _debounce;
  List<Json> _matches = [];
  List<String> _knownNames = [];
  bool _searching = false, _busy = false, _uncertain = false;
  Object? _lookupError, _checkoutError;
  String? _method, _confirmationId;
  Json? _confirmedBody, _preview;

  bool get _fromQuote => widget.existingQuote.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final details = payload(widget.existingQuote);
    if (_fromQuote) {
      _partyId = numId(details['partyId']);
      _name.text = str(details['customerName']);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scope != null) return;
    final app = context.app;
    _scope = app.scopeRevision;
    _lines =
        (_fromQuote ? maps(payload(widget.existingQuote)['lines']) : app.basket)
            .map((line) => Map<String, dynamic>.of(line))
            .toList();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _paid.dispose();
    _bank.dispose();
    _discount.dispose();
    _customerFocus.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    final generation = ++_searchGeneration;
    final term = value.trim();
    setState(() {
      _partyId = 0;
      _matches = [];
      _knownNames = [];
      _lookupError = null;
      _searching = term.length >= 2;
    });
    if (!_searching) return;
    final app = context.app;
    _debounce = Timer(const Duration(milliseconds: 260), () async {
      try {
        final data = obj(
          await app.read(
            '/api/agent/directory/customers',
            query: app.scoped({'purpose': 'checkout', 'search': term}),
          ),
        );
        if (!mounted ||
            generation != _searchGeneration ||
            _scope != app.scopeRevision)
          return;
        setState(() {
          _matches = rows(data).take(8).toList();
          _knownNames =
              (data['knownNames'] as List?)?.whereType<String>().toList() ?? [];
          _searching = false;
        });
      } catch (error) {
        if (!mounted ||
            generation != _searchGeneration ||
            _scope != app.scopeRevision)
          return;
        setState(() {
          _searching = false;
          _lookupError = error;
        });
      }
    });
  }

  void _selectCustomer(String name, int partyId) {
    _debounce?.cancel();
    _searchGeneration++;
    _name.text = name;
    _customerFocus.unfocus();
    setState(() {
      _partyId = partyId;
      _matches = [];
      _knownNames = [];
      _searching = false;
      _lookupError = null;
    });
  }

  List<String> _methods(Json options) => [
    if (options['cashShiftOpen'] == true) 'Cash',
    if (options['bankTransfer'] == true) 'BankTransfer',
    if (_partyId > 0 && options['credit'] == true) 'Credit',
  ];

  double? _number(TextEditingController input) {
    final value = double.tryParse(normalizeNumber(input.text.trim()));
    return value != null && value.isFinite ? value : null;
  }

  Future<void> _review(String? method) async {
    final app = context.app;
    if (_busy || _scope != app.scopeRevision || !_form.currentState!.validate())
      return;
    _customerFocus.unfocus();
    setState(() {
      _busy = true;
      _checkoutError = null;
    });
    final body = <String, dynamic>{
      'delegationId': app.grantId,
      'purchase': false,
      'partyId': _partyId,
      if (_partyId == 0) 'customerName': _name.text.trim(),
      'lines': [
        for (final line in _lines)
          {
            'productVariantId': line['productVariantId'],
            'quantity': line['quantity'],
            'unitCost': 0,
          },
      ],
      'discountPercent': _number(_discount) ?? 0,
      if (method != null) 'paymentMethod': method,
      if (method == 'Credit')
        'paidAmount': 0
      else if (method != null && _partyId > 0 && _paid.text.trim().isNotEmpty)
        'paidAmount': _number(_paid),
      if (method == 'BankTransfer') 'bankReference': _bank.text.trim(),
      if (_fromQuote) 'quoteId': widget.existingQuote['id'],
    };
    try {
      final preview = _fromQuote
          ? payload(widget.existingQuote)
          : obj(
              await app.repo.write(
                'POST',
                '/api/agent/commercial/quotes/preview',
                {...body, 'requestId': uuid()},
              ),
            );
      if (!mounted || _scope != app.scopeRevision) return;
      if (preview['total'] is! num) throw const Failure(503, '');
      if (decimal(body['paidAmount']) > decimal(preview['total'])) {
        setState(
          () => _checkoutError = Failure(
            422,
            context.tr(
              'المبلغ المدفوع يتجاوز إجمالي الفاتورة.',
              'Payment exceeds the invoice total.',
            ),
          ),
        );
        return;
      }
      setState(() {
        _confirmedBody = {...body, 'expectedTotal': preview['total']};
        _preview = preview;
        _confirmationId = uuid();
        _uncertain = false;
      });
    } catch (error) {
      if (mounted) setState(() => _checkoutError = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final app = context.app;
    if (_busy || _confirmedBody == null || _scope != app.scopeRevision) return;
    setState(() {
      _busy = true;
      _checkoutError = null;
    });
    try {
      final response = obj(
        await app.execute(
          widget.quote
              ? '/api/agent/commercial/quotes'
              : '/api/agent/commerce/documents',
          _confirmedBody!,
          requestId: _confirmationId,
        ),
      );
      if (!mounted || _scope != app.scopeRevision) return;
      final id = numId(response[widget.quote ? 'id' : 'documentId']);
      if (id <= 0 || (!widget.quote && response['isPosted'] != true)) {
        throw const Failure(503, '', uncertain: true);
      }
      final open = NavScope.of(context);
      if (!widget.quote && !_fromQuote) {
        app.basket.clear();
        app.changed();
      }
      toast(
        context,
        widget.quote
            ? context.tr('تم حفظ عرض السعر', 'Quotation saved')
            : context.tr('تم ترحيل فاتورة البيع', 'Sales invoice posted'),
      );
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop();
      if (widget.quote) {
        open('T09');
      } else {
        open('T07', id: id);
      }
    } catch (error) {
      if (mounted)
        setState(() {
          _checkoutError = error;
          _uncertain = error is Failure && error.uncertain;
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    if (_scope != app.scopeRevision ||
        !app.allows(widget.quote ? Cap.sell : Cap.sell | Cap.cash)) {
      return PageBody(
        children: [
          Empty(
            text: context.tr(
              'تغيّر نطاق العمل أو صلاحية العملية.',
              'Work scope or permission has changed.',
            ),
          ),
        ],
      );
    }
    if (_lines.isEmpty) {
      return PageBody(
        children: [
          Empty(
            text: context.tr(
              'أضف أصنافًا من نقطة البيع أولًا.',
              'Add items from the point of sale first.',
            ),
            action: TextButton(
              onPressed: () => context.open('T02'),
              child: Text(context.tr('نقطة البيع', 'Point of sale')),
            ),
          ),
        ],
      );
    }
    return Resource(
      identity: 'pos-options:$_scope',
      load: () => app.read(
        '/api/agent/commercial/checkout-options',
        query: app.scoped(),
      ),
      builder: (data, update) {
        final options = obj(data), methods = _methods(options);
        final method = methods.contains(_method)
            ? _method
            : methods.firstOrNull;
        final preview = _preview;
        final amount = preview == null ? 0.0 : decimal(preview['total']);
        final paid = _confirmedBody?['paidAmount'] is num
            ? decimal(_confirmedBody!['paidAmount'])
            : amount;
        final currency = str(preview?['currency'] ?? app.currency);
        final maxDiscount = decimal(options['maxDiscountPercent']);
        return Column(
          children: [
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                  children: [
                    Heading(
                      widget.quote
                          ? context.tr('فاتورة عرض سعر', 'Quotation')
                          : context.tr('إتمام البيع', 'Complete sale'),
                    ),
                    if (_fromQuote || preview != null)
                      Facts({
                        'customerName':
                            preview?['customerName'] ??
                            (_name.text.isEmpty ? '#$_partyId' : _name.text),
                      })
                    else ...[
                      TextFormField(
                        controller: _name,
                        focusNode: _customerFocus,
                        maxLength: 100,
                        key: const ValueKey('checkout-customer'),
                        decoration: InputDecoration(
                          labelText: context.tr('اسم العميل', 'Customer name'),
                          hintText: context.tr(
                            'اكتب الاسم أو ابحث بالهاتف أو البريد',
                            'Enter a name or search by phone or email',
                          ),
                        ),
                        onChanged: _search,
                        validator: (value) {
                          final term = (value ?? '').trim();
                          if (_partyId > 0 ||
                              (term.isNotEmpty &&
                                  !term.contains('@') &&
                                  !RegExp(r'^[+\d\s()-]+$').hasMatch(term)))
                            return null;
                          return context.tr(
                            'أدخل الاسم أو اختر عميلًا من النتائج.',
                            'Enter a name or select a customer from the results.',
                          );
                        },
                      ),
                      if (_partyId > 0)
                        Notice(
                          context.tr(
                            'تم ربط المستند بحساب العميل.',
                            'This document is linked to the customer account.',
                          ),
                        ),
                      if (_searching) const LinearProgressIndicator(),
                      if (_lookupError != null)
                        Notice(
                          failureText(context, _lookupError!),
                          error: true,
                        ),
                      for (final customer in _matches)
                        RecordTile(
                          customer,
                          icon: Icons.person_outline,
                          subtitle: '#${customer['id']}',
                          onTap: () => _selectCustomer(
                            titleOf(customer),
                            numId(customer['id']),
                          ),
                        ),
                      for (final name in _knownNames)
                        RecordTile(
                          {'name': name},
                          icon: Icons.history,
                          subtitle: context.tr(
                            'اسم من فاتورة سابقة',
                            'Name from a previous invoice',
                          ),
                          onTap: () => _selectCustomer(name, 0),
                        ),
                      if (_partyId == 0 && _name.text.trim().isNotEmpty)
                        Notice(
                          context.tr(
                            'سيُحفظ الاسم في المستند.',
                            'The name will be saved on the document.',
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                    if (preview == null) ...[
                      for (final item in _lines)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(titleOf(item)),
                          trailing: Text(
                            '× ${display(context, item['quantity'])}',
                          ),
                        ),
                      if (!_fromQuote && maxDiscount > 0)
                        TextFormField(
                          controller: _discount,
                          key: const ValueKey('checkout-discount'),
                          decoration: InputDecoration(
                            labelText: context.tr('الخصم (%)', 'Discount (%)'),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (_) =>
                              _amountError(_discount, maxDiscount),
                        ),
                      if (!widget.quote) ...[
                        const SizedBox(height: 10),
                        if (options['cash'] == true &&
                            options['cashShiftOpen'] != true)
                          BusyButton(
                            label: context.tr(
                              'فتح وردية نقدية',
                              'Open a cash shift',
                            ),
                            run: () async {
                              await openOperation(context, 'openShift');
                              if (mounted) update();
                            },
                          ),
                        if (methods.isNotEmpty)
                          DropdownButtonFormField<String>(
                            key: ValueKey(methods.join(',')),
                            initialValue: method,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: context.tr(
                                'طريقة الدفع',
                                'Payment method',
                              ),
                            ),
                            items: [
                              for (final choice in methods)
                                DropdownMenuItem(
                                  value: choice,
                                  child: Text(word(context, choice)),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _method = value),
                          ),
                        if (method == null)
                          Notice(
                            context.tr(
                              'لا توجد وسيلة دفع متاحة لهذا العميل في التفويض الحالي.',
                              'No payment method is available for this customer in the current work scope.',
                            ),
                          ),
                        if (method == 'BankTransfer')
                          TextFormField(
                            controller: _bank,
                            maxLength: 150,
                            decoration: InputDecoration(
                              labelText: context.tr(
                                'مرجع التحويل البنكي',
                                'Bank transfer reference',
                              ),
                            ),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? context.tr(
                                    'أدخل مرجع التحويل.',
                                    'Enter the transfer reference.',
                                  )
                                : null,
                          ),
                        if (method != null &&
                            method != 'Credit' &&
                            options['credit'] == true &&
                            _partyId > 0)
                          TextFormField(
                            controller: _paid,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: context.tr(
                                'المبلغ المدفوع',
                                'Amount paid',
                              ),
                              helperText: context.tr(
                                'اتركه فارغًا للسداد الكامل.',
                                'Leave blank for full payment.',
                              ),
                            ),
                            validator: (_) => _amountError(_paid, 100000000),
                          ),
                      ],
                    ] else ...[
                      Heading(
                        context.tr(
                          'الإجمالي المؤكد من السيرفر',
                          'Server-confirmed total',
                        ),
                      ),
                      Facts({
                        'totalAmount': amount,
                        'currency': currency,
                        if (!widget.quote)
                          'paymentMethod': _confirmedBody!['paymentMethod'],
                        if (!widget.quote) 'paidAmount': paid,
                        if (!widget.quote) 'remainingAmount': amount - paid,
                      }),
                      for (final item in maps(preview['lines']))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            titleOf(
                              _lines.firstWhere(
                                (line) =>
                                    line['productVariantId'] ==
                                    item['productVariantId'],
                                orElse: () => item,
                              ),
                            ),
                          ),
                          subtitle: Text(
                            '${display(context, item['quantity'])} × ${display(context, item['unitPrice'])}',
                          ),
                          trailing: Text(
                            '${display(context, item['total'])} $currency',
                          ),
                        ),
                      if (!_uncertain)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                  _preview = null;
                                  _confirmedBody = null;
                                  _checkoutError = null;
                                }),
                          child: Text(
                            context.tr('تعديل البيانات', 'Edit details'),
                          ),
                        ),
                    ],
                    if (_checkoutError != null)
                      Notice(
                        failureText(context, _checkoutError!),
                        error: true,
                      ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('checkout-submit'),
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fact_check_outlined),
                    onPressed:
                        _busy ||
                            (preview == null && !widget.quote && method == null)
                        ? null
                        : preview == null
                        ? () => _review(widget.quote ? null : method)
                        : _confirm,
                    label: Text(
                      preview == null
                          ? context.tr('مراجعة الإجمالي', 'Review total')
                          : widget.quote
                          ? context.tr('حفظ عرض السعر', 'Save quotation')
                          : context.tr(
                              'تأكيد وترحيل البيع',
                              'Confirm and post sale',
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String? _amountError(TextEditingController input, double max) {
    if (input.text.trim().isEmpty) return null;
    final value = _number(input);
    return value == null || value < 0 || value > max
        ? context.tr(
            'أدخل مبلغًا من صفر إلى $max.',
            'Enter an amount from zero to $max.',
          )
        : null;
  }
}
