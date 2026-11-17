# إعادة البناء شاشةً بشاشة — المخزون والتجارة والمالية

**32 شاشة / 92**؛ جميع الشاشات مصممة انطلاقًا من عقد السيرفر المثبت لا من الواجهات القديمة. ملحق حقول الطلبات والطرق في [06-api-commerce-finance.md](06-api-commerce-finance.md) ومصدر السلطة في [00-master-plan.md](00-master-plan.md). كل سجل AgentRecord يتضمن id,status,version,details بنمط نوعه؛ لا تفترض أن جميع نتائج Legacy لها الشكل نفسه. ملاحظة: رموز المسارات والمعاملات هنا تهدف للتوثيق؛ صياغة GET عملية باستخدام علامة `?` و`&` والحقول المسماة.

## إدارة المخزون

### I01 — مخزون الفرع

- **قراءات:** GET /api/agent/commerce/inventory?delegationId&afterId; GET /api/agent/operations/batch-holds?delegationId&afterId.
- **عمليات/أفعال:** —.
- **حقول الطلب:** delegationId: تفويض فعال يملك Inventory؛ afterId: مؤشر مرتب.
- **نتائج الاستجابة المستخدمة:** Inventory[]: id,productVariantId,quantityOnHand,reservedQuantity,availableQuantity,averageCost,batches[id,batchNumber,quantity,expiryDate,unitCost].
- **قواعد التفويض وتسلسل الواجهة:** Inventory=1؛ بطاقات منتج + رصيد فعلي + دفعات؛ بحث وتصنيف محلي أو خدمة معتمدة دون تنزيل قاعدة كاملة؛ I02/I05.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### I02 — تفاصيل رصيد صنف

- **قراءات:** GET /api/agent/commerce/inventory?delegationId&afterId; GET /api/product-variants/{variantId}.
- **عمليات/أفعال:** —.
- **حقول الطلب:** inventoryId أو productVariantId + grantId؛ لا تعامل معرف المخزون كمعرف المنتج.
- **نتائج الاستجابة المستخدمة:** العنصر مع الرصيد المتاح والمحجوز والمتوسط وقائمة دفعاته + معلومات متغير المنتج.
- **قواعد التفويض وتسلسل الواجهة:** Inventory=1؛ إظهار تحذيرات الحظر/الانتهاء؛ إلى I03/I04/T04.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### I03 — الدفعات والتسلسل

- **قراءات:** GET /api/agent/commerce/inventory?delegationId&afterId; GET /api/agent/operations/batch-holds?delegationId&afterId.
- **عمليات/أفعال:** POST /api/agent/operations/batch-holds.
- **حقول الطلب:** BatchHoldInput(requestId,delegationId,batchId,reason).
- **نتائج الاستجابة المستخدمة:** دفعات id,batchNumber,quantity,expiryDate,unitCost؛ سجل BatchHold يحوي id,status,version,details.reason.
- **قواعد التفويض وتسلسل الواجهة:** Inventory=1؛ حظر دفعة مشكوك بها فورًا؛ فكها بعملية reviewer منفصلة لا زر صاحب الطلب؛ I05.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### I04 — حركات الصنف

- **قراءات:** GET /api/Inventory/{id}/transactions (legacy).
- **عمليات/أفعال:** —.
- **حقول الطلب:** id: معرف Inventory لا ProductVariant؛ أي معايير التصفح في controller القديم.
- **نتائج الاستجابة المستخدمة:** عناصر حركة المخزون وتاريخها ومرجع المستند كما يرجع مسار legacy.
- **قواعد التفويض وتسلسل الواجهة:** قد يتطلب إذن قراءة مستقل؛ عند 403 توضيح عدم الإتاحة لا تجاوز العزل؛ I02/T07.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### I05 — تنبيهات الصلاحية والنفاد والحجز

- **قراءات:** GET /api/agent/commerce/inventory?delegationId&afterId; GET /api/agent/operations/batch-holds?delegationId&afterId.
- **عمليات/أفعال:** POST /api/agent/operations/batch-holds.
- **حقول الطلب:** requestId,delegationId,batchId,reason عند الحجز.
- **نتائج الاستجابة المستخدمة:** availableQuantity، تواريخ expiryDate، active holds، الكميات المحجوزة.
- **قواعد التفويض وتسلسل الواجهة:** مشتق من بيانات المخزن بعد تحميل الصفحات؛ مؤشرات حد إعادة الطلب ينبغي إثبات مصدرها وليس التخمين؛ إلى I02/I03.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### I06 — التحويلات والطلبات

- **قراءات:** GET /api/agent/commerce/transfers?delegationId&afterId; GET /api/agent/supply/requests?delegationId&afterId.
- **عمليات/أفعال:** —.
- **حقول الطلب:** delegationId,afterId.
- **نتائج الاستجابة المستخدمة:** AgentRecord<TransferData>/AgentRecord<SupplyRequestData> مع id,status,version,warehouseId,otherWarehouseId,details.lines.
- **قواعد التفويض وتسلسل الواجهة:** Transfer=8؛ فصل الوارد والصادر وباقي الكميات والفروق؛ I07/I08.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### I07 — طلب تغذية أو تحويل

- **قراءات:** GET /api/agent/commerce/inventory?delegationId&afterId; GET /api/agent/supply/requests?delegationId&afterId; GET /api/Warehouses (legacy: ترخيص القراءة يُتحقق).
- **عمليات/أفعال:** POST /api/agent/supply/requests أو POST /api/agent/commerce/transfers.
- **حقول الطلب:** SupplyRequestInput(requestId,delegationId,sourceWarehouseId,lines[productVariantId,quantity],reason)؛ أو AgentTransferInput(requestId,delegationId,destinationWarehouseId,notes,lines[productVariantId,batchId,quantity]).
- **نتائج الاستجابة المستخدمة:** الطلب Pending ويحتاج موافقة مصدر مستقل؛ التحويل المباشر Active مع رقم الحركة وlines.sent/received.
- **قواعد التفويض وتسلسل الواجهة:** Transfer=8؛ التفريق بين طلب لمخزن آخر وبين تحويل يخصم من مخزن المصدر؛ إلى I06/I08؛ الموافقات في X screens.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### I08 — استلام جزئي ونقل العهدة

- **قراءات:** GET /api/agent/commerce/transfers?delegationId&afterId؛ اختيار id من السجل.
- **عمليات/أفعال:** POST /api/agent/commerce/transfers/{id}/receive؛ POST /api/agent/supply/transfers/{id}/exceptions.
- **حقول الطلب:** TransferReceiveInput(requestId,delegationId,version,lines[productVariantId,batchId,quantity])؛ TransferExceptionInput(requestId,delegationId,version,batchId,quantity,reason,notes).
- **نتائج الاستجابة المستخدمة:** TransferData.lines لكل batch مع sent,received,resolved؛ version,status وكمية النقل الباقية.
- **قواعد التفويض وتسلسل الواجهة:** يستلم المستودع الوجهة وحده ضمن صلاحية Transfer؛ partial receipt، تلف/فقد/مرتجع يتطلب مراجعة مستقلة؛ I06.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### I09 — الجرد الفعلي

- **قراءات:** GET /api/agent/commerce/inventory?delegationId&afterId.
- **عمليات/أفعال:** POST /api/agent/commerce/stock-counts.
- **حقول الطلب:** StockCountInput(requestId,delegationId,reason,lines[{batchId,counted}]).
- **نتائج الاستجابة المستخدمة:** AgentRecord<CountData>: id,status=Pending,version,details.lines[{batchId,expected,counted,batchUpdatedAt,batchRowVersion}].
- **قواعد التفويض وتسلسل الواجهة:** StockCount=16؛ snapshot متوقع ثابت؛ لا تسوية المخزون بمجرد إرسال الجرد؛ إلى I10.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### I10 — فروق الجرد والمراجعة

- **قراءات:** GET /api/agent/mobile/changes?since&afterId؛ GET /api/agent/operations/review-queue?warehouseId&kind=StockCount&afterId (للمراجع).
- **عمليات/أفعال:** POST /api/agent/commerce/stock-counts/{id}/review (مراجع مستقل فقط).
- **حقول الطلب:** ReviewInput(requestId,version,approve,notes).
- **نتائج الاستجابة المستخدمة:** status/version للطلب، details.lines.expected/count، نتيجة الاعتماد أو رفضه.
- **قواعد التفويض وتسلسل الواجهة:** العامل يتابع حالته؛ المراجع المصرح لا يعتمد جرده الذاتي؛ تغير الرصيد بعد العدّ ينتج 409؛ إلى I09.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

## التجارة والمبيعات والمشتريات

### T01 — مركز عمليات الفرع

- **قراءات:** GET /api/agent/mobile/bootstrap؛ GET /api/agent/operations/home؛ GET /api/agent/operations/cashbox?delegationId (إذا Cash).
- **عمليات/أفعال:** —.
- **حقول الطلب:** تفويض المخزن والصندوق المختار.
- **نتائج الاستجابة المستخدمة:** القدرات، openShifts، ملخص التشغيل النقدي إن سُمح.
- **قواعد التفويض وتسلسل الواجهة:** قائمة قدرات لا كل ميزات الإدارة؛ اختصارات T02,T06,T09,T11,T12,N01,I01,P01,A01,G01 بحسب التفويض.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### T02 — نقطة البيع وتجميع السلة

- **قراءات:** GET /api/agent/commerce/inventory?delegationId&afterId؛ GET /api/product-variants؛ GET /api/products/resolve عند المسح؛ GET /api/agent/operations/cashbox?delegationId إذا نقد.
- **عمليات/أفعال:** لا ترحيل من شاشة السلة؛ أمر POST الفاتورة يتم في T05.
- **حقول الطلب:** البحث، productVariantId,batchId,quantity,customer/partyId؛ لا تثق بسعر العميل.
- **نتائج الاستجابة المستخدمة:** SKU/variant، availableQuantity، دفعة، سعر الكتالوج من خدمة المنتجات (النهائي يقره الخادم عند الترحيل).
- **قواعد التفويض وتسلسل الواجهة:** Sell=2 للقائمة وCash=32 للنقد؛ توقف إذا رخصة أو عمر الدفعة غير صالح؛ T03/T04/T05.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### T03 — قارئ الباركود/QR للمنتج

- **قراءات:** GET /api/products/resolve مع المعامل المطابق للـ controller؛ GET /api/product-variants/{id}.
- **عمليات/أفعال:** —.
- **حقول الطلب:** النص الممسوح أو barcode/sku حسب عقد resolve؛ إذن الكاميرا.
- **نتائج الاستجابة المستخدمة:** معرف المنتج أو المتغير، حالة التعرف أو عدمه؛ مصدر الصورة إن وجد.
- **قواعد التفويض وتسلسل الواجهة:** قارئ عام لا يغير مخزون؛ في المبيعات يرجع T02، في الجرد I09؛ يمنع توليد معرف صنف محلي.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### T04 — اختيار المتغير والدفعة

- **قراءات:** GET /api/product-variants/{id}; GET /api/agent/commerce/inventory?delegationId&afterId; GET /api/agent/operations/batch-holds?delegationId&afterId.
- **عمليات/أفعال:** —.
- **حقول الطلب:** variantId,delegationId؛ batchId,quantity ضمن السلة المحلية.
- **نتائج الاستجابة المستخدمة:** بيانات المتغير المتاحة، الدفعات والكميات والأسعار المرجعية.
- **قواعد التفويض وتسلسل الواجهة:** Inventory=1 إن كانت رؤية مخزون مطلوبة؛ لا تعرض دفعة موقوفة أو منتهية على أنها قابلة للبيع؛ إلى T02/T05.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### T05 — مراجعة البيع وطريقة الدفع

- **قراءات:** GET /api/agent/operations/cashbox?delegationId; GET /api/agent/commercial/quotes/{quoteId} إذا عرض مقبول.
- **عمليات/أفعال:** POST /api/agent/commerce/documents.
- **حقول الطلب:** AgentDocumentInput(requestId,delegationId,purchase=false,partyId,lines[{productVariantId,batchId,quantity,unitCost?,batchNumber?,expiryDate?}],paymentMethod,paidAmount?,discountPercent,quoteId?,bankReference?,campaignId?).
- **نتائج الاستجابة المستخدمة:** مرجع المستند المنشور ورصيده المدفوع والمتبقي، currency,tax,discount، رقم الفاتورة حسب Result؛ يُعاد إحضار الإيصال من T07.
- **قواعد التفويض وتسلسل الواجهة:** Sell=2؛ نقد مع Cash=32 ووردية، بنك وفق policy وصندوق صالح، Credit حد مفوّض، Wallet بقبول العميل من مساره؛ UUID ثابت؛ إلى T07.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### T06 — فواتير المبيعات

- **قراءات:** GET /api/agent/commerce/documents?delegationId&afterId.
- **عمليات/أفعال:** —.
- **حقول الطلب:** delegationId,afterId؛ filter النوع SalesInvoice/SalesReturn حسب مسارات القوائم.
- **نتائج الاستجابة المستخدمة:** id,documentNumber,type,totalAmount,paidAmount,remainingAmount,currency,isPosted,postedAt إن كانت في projection.
- **قواعد التفويض وتسلسل الواجهة:** Inventory=1 للقراءة بحسب controller؛ صفحة تصاعدية، تفاصيل T07، مرتجع T08، تقارير N08.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### T07 — إيصال وفاتورة مرتبطة

- **قراءات:** GET /api/agent/commercial/documents/{id}/receipt?delegationId؛ GET /api/agent/commerce/documents?delegationId&afterId عند الحاجة.
- **عمليات/أفعال:** لا تكرر عملية ترحيل الفاتورة؛ السداد في N07 والمرتجع T08/T14.
- **حقول الطلب:** id: documentId,delegationId للاستعلام حسب إذن الموظف.
- **نتائج الاستجابة المستخدمة:** id,documentNumber,type,currency,totalAmount,paidAmount,remainingAmount,isPosted,items[id,productVariantId,quantity,unitPrice,discount,tax,total,batchNumber].
- **قواعد التفويض وتسلسل الواجهة:** بيان واضح صافي/ضريبة/مدفوع/آجل؛ مشاركة إيصال غير حساس بعد تحقق السياسة؛ إلى T08/N07.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### T08 — مرتجع مبيعات

- **قراءات:** GET /api/agent/commercial/documents/{id}/receipt?delegationId؛ GET /api/agent/returns?delegationId&afterId.
- **عمليات/أفعال:** POST /api/agent/returns.
- **حقول الطلب:** AgentReturnInput(requestId,delegationId,originalDocumentId,lines[{originalItemId,quantity}],reason).
- **نتائج الاستجابة المستخدمة:** AgentRecord<AgentReturnData>: status=Pending,version,details.originalDocumentId,lines,returnDocumentId?,reviewNotes.
- **قواعد التفويض وتسلسل الواجهة:** لا عكس النقد والمخزون بنفس الزر؛ reviewer يفحص السلع ويحدد refundAmount ويوافق؛ إلى X04/N07.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### T09 — عروض الأسعار والموافقة

- **قراءات:** GET /api/agent/mobile/changes?since&afterId (للمؤشر)؛ GET /api/agent/commercial/quotes/{id}.
- **عمليات/أفعال:** POST /api/agent/commercial/quotes؛ قبول العميل POST /api/agent/commercial/quotes/{id}/accept؛ دفع العميل عبر POST .../{id}/pay-wallet.
- **حقول الطلب:** AgentDocumentInput(purchase=false,partyId,lines,paymentMethod,discountPercent,requestId,delegationId)؛ QuoteAcceptanceInput(requestId,version) للدور الصحيح.
- **نتائج الاستجابة المستخدمة:** AgentRecord<SaleQuoteData>: delegationId,partyId,currency,lines,total,expiresAt,documentId?,customerAccepted.
- **قواعد التفويض وتسلسل الواجهة:** Sell=2؛ **لا يوجد GET قائمة عروض مستقل في controller**؛ التغييرات ليست مصدر paging أعمال موثوقًا؛ حاجة تحسين خادمي محتملة؛ العميل يقبل/يدفع بمحفظته بنفسه.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### T10 — دليل الموردين

- **قراءات:** GET /api/Suppliers (legacy).
- **عمليات/أفعال:** لا إنشاء/تعديل مورد دون إذن legacy وإثبات مسار كتابة.
- **حقول الطلب:** اسم أو رقم المورد ومؤشر التصفح الذي يدعمه legacy.
- **نتائج الاستجابة المستخدمة:** supplier id,name,contacts كما في Supplier DTO الرسمي.
- **قواعد التفويض وتسلسل الواجهة:** قد يتطلب permission خارج delegation؛ يستخدم في T12/N05؛ لا تُعرض بيانات حساسة بلا تخويل.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### T11 — المشتريات المستلمة/المرحّلة

- **قراءات:** GET /api/agent/commerce/documents?delegationId&afterId؛ GET /api/agent/procurement?delegationId&afterId.
- **عمليات/أفعال:** —.
- **حقول الطلب:** delegationId,afterId مع تصفية PurchaseInvoice/PurchaseReturn.
- **نتائج الاستجابة المستخدمة:** documentId,number,party/supplier,amounts,currency,status؛ procurement.details.documentIds.
- **قواعد التفويض وتسلسل الواجهة:** فرق بين طلب شراء Pending وبين فاتورة Posted؛ تفاصيل T07 أو استلام T13.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### T12 — إنشاء طلب شراء

- **قراءات:** GET /api/Suppliers (legacy)؛ GET /api/product-variants؛ GET /api/agent/procurement?delegationId&afterId.
- **عمليات/أفعال:** POST /api/agent/procurement.
- **حقول الطلب:** ProcurementInput(requestId,delegationId,supplierId,lines[AgentDocumentLine: productVariantId,batchId?,quantity,unitCost,batchNumber?,expiryDate?],reason).
- **نتائج الاستجابة المستخدمة:** AgentRecord<ProcurementData>: supplierId,lines[quantity,received,unitCost],reason,reviewNotes,documentIds,status,version.
- **قواعد التفويض وتسلسل الواجهة:** Purchase=4؛ يمر بالموافقة المستقلة ولا يتحول إلى فاتورة بإنشائه؛ إلى T13.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### T13 — استلام مشتريات ودفعها

- **قراءات:** GET /api/agent/procurement?delegationId&afterId؛ GET /api/agent/operations/cashbox?delegationId (إن نقد).
- **عمليات/أفعال:** POST /api/agent/procurement/{id}/receive.
- **حقول الطلب:** ProcurementReceiveInput(requestId,version,document:AgentDocumentInput[purchase=true,delegationId,partyId=supplierId,lines,paymentMethod,paidAmount?,bankReference?],itemsReceived).
- **نتائج الاستجابة المستخدمة:** ProcurementData.lines.received وdocumentIds بعد الفاتورة، نسخة وسند مخزون/نقد منشور.
- **قواعد التفويض وتسلسل الواجهة:** Purchase=4؛ نقد يحتاج Cash=32/shift، ويجب اعتماد طلب الشراء قبله؛ استلام جزئي مع دفعات فعلية؛ إلى T11/T07.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### T14 — مرتجع مشتريات

- **قراءات:** GET /api/agent/commerce/documents?delegationId&afterId؛ GET /api/agent/commercial/documents/{id}/receipt?delegationId.
- **عمليات/أفعال:** POST /api/agent/returns.
- **حقول الطلب:** AgentReturnInput(requestId,delegationId,originalDocumentId,lines[{originalItemId,quantity}],reason).
- **نتائج الاستجابة المستخدمة:** ReturnRequest: status,version,returnDocumentId?,reviewNotes؛ تقرير اعتماد مستقل.
- **قواعد التفويض وتسلسل الواجهة:** المراجع يراجع السلع والكمية والاسترداد؛ لا افتراض أن refund خارجي تم؛ إلى T11/X04.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

## الصناديق والمحاسبة والتقارير

### N01 — صناديق الفرع المصرح بها

- **قراءات:** GET /api/agent/mobile/bootstrap؛ GET /api/agent/operations/cashbox?delegationId&afterTransactionId=0.
- **عمليات/أفعال:** —.
- **حقول الطلب:** delegationId يتضمن Cash وCashBoxId حقيقي.
- **نتائج الاستجابة المستخدمة:** id,name,currencyCode,openingBalance,currentBalance,transactions[],shifts[].
- **قواعد التفويض وتسلسل الواجهة:** Cash=32؛ لا يوجد endpoint قائمة جميع صناديق الفرع للوكيل؛ يظهر الصندوق المربوط بالتفويض فقط؛ إلى N02/N03.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### N02 — حركات الصندوق

- **قراءات:** GET /api/agent/operations/cashbox?delegationId&afterTransactionId.
- **عمليات/أفعال:** لا إضافة قيد نقدي مباشر خارج العملية الأصلية.
- **حقول الطلب:** delegationId,afterTransactionId.
- **نتائج الاستجابة المستخدمة:** transactions[{id,direction,transactionType,amount,referenceType,referenceId,createdAt}],currentBalance.
- **قواعد التفويض وتسلسل الواجهة:** Cash=32؛ صفّح بالحركة (100)؛ اضغط المرجع للفاتورة T07 أو N06؛ مبالغ بعملة الصندوق فقط.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### N03 — الوردية النقدية وفتحها

- **قراءات:** GET /api/agent/operations/cashbox?delegationId.
- **عمليات/أفعال:** POST /api/agent/commerce/shifts.
- **حقول الطلب:** ShiftOpenInput(requestId,delegationId,countedOpening).
- **نتائج الاستجابة المستخدمة:** AgentRecord<ShiftData>: id,status=Active,version,details[cashBoxId,currency,opening,openedAt,closedAt,...].
- **قواعد التفويض وتسلسل الواجهة:** Cash=32؛ تتطابق الافتتاحية مع الرصيد الفعلي؛ وردية واحدة للصندوق بحسب القاعدة؛ إلى N04.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### N04 — مطابقة وإقفال وردية

- **قراءات:** GET /api/agent/operations/cashbox?delegationId.
- **عمليات/أفعال:** POST /api/agent/commerce/shifts/{id}/close؛ المراجعة POST /api/agent/commerce/shifts/{id}/review لمراجع إداري مستقل.
- **حقول الطلب:** ShiftCloseInput(requestId,delegationId,version,countedClosing,notes)؛ ReviewInput(requestId,version,approve,notes).
- **نتائج الاستجابة المستخدمة:** ShiftData.expectedClosing,countedClosing,closedAt,adjustmentTransactionId?,status/version بعد الإقفال والمراجعة.
- **قواعد التفويض وتسلسل الواجهة:** Cash=32 لإقفال ورديته؛ اختلاف الرصيد لا يؤدي لإنشاء حركة تلقائية؛ قرار المراجع من X02.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### N05 — كشف حساب عميل أو مورد

- **قراءات:** GET /api/agent/finance/statements?delegationId&partyId&supplier&afterId.
- **عمليات/أفعال:** —.
- **حقول الطلب:** delegationId,partyId,supplier:bool,afterId؛ اختيار الطرف من مصدر legacy المصرح.
- **نتائج الاستجابة المستخدمة:** partyId,supplier,balance,currency,transactions[{id,documentId,amount,direction,transactionType,createdAt}].
- **قواعد التفويض وتسلسل الواجهة:** Cash=32؛ عملة CatalogCurrency كما في التنفيذ؛ لا تجمع أرصدة عملات مختلفة؛ إلى T07/N07.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### N06 — القيود المحاسبية

- **قراءات:** GET /api/agent/finance/journals?delegationId&afterId.
- **عمليات/أفعال:** —.
- **حقول الطلب:** delegationId,afterId: JournalEntryId.
- **نتائج الاستجابة المستخدمة:** journalEntryId,entryNumber,entryDate,referenceType,referenceId,lines[{accountId,debitAmount,creditAmount}].
- **قواعد التفويض وتسلسل الواجهة:** Cash=32؛ قيود القراءة فقط حسب المخزن والمستند؛ لا قيود يدوية مستحدثة؛ إلى T07/N02.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### N07 — تسوية فاتورة عميل أو مورد

- **قراءات:** GET /api/agent/commercial/documents/{id}/receipt?delegationId؛ GET /api/agent/operations/cashbox?delegationId.
- **عمليات/أفعال:** POST /api/agent/finance/documents/{id}/settle.
- **حقول الطلب:** AgentSettlementInput(requestId,delegationId,amount,paymentMethod,notes,bankReference?)؛ amount<=remainingAmount.
- **نتائج الاستجابة المستخدمة:** حركة تسوية ونقد/بنك ثم إيصال updated paidAmount/remainingAmount من GET receipt.
- **قواعد التفويض وتسلسل الواجهة:** Cash=32؛ تحقّق نوع الصندوق ووردية النقد وسياسة البنك والعملة والرصد الكافي؛ إلى T07/N05.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

### N08 — لوحة تقارير المبيعات والمخزون

- **قراءات:** GET /api/agent/commerce/documents?delegationId&afterId؛ GET /api/agent/operations/cashbox?delegationId (اختياري).
- **عمليات/أفعال:** —.
- **حقول الطلب:** delegationId,rangeFrom/rangeTo محليان فقط إن لم يدعمهما endpoint؛ فلاتر currency.
- **نتائج الاستجابة المستخدمة:** documents[{type,totalAmount,postedAt,isPosted,currency,paidAmount,remainingAmount}],cashbox.currentBalance.
- **قواعد التفويض وتسلسل الواجهة:** Inventory=1 للوثائق؛ إحصاءات من الصفحات المستلمة فقط مع إظهار تغطية البيانات؛ لا تعرضها كتقرير كامل إلا بعد جلب جميع الصفحات المصرح بها أو إضافة API تجميعي.
- **حالات الواجهة:** بدء التحميل، عدم وجود نتائج، تغير النطاق، عدم الاتصال، 401/403/404/409/422، تأكيد خادمي وتحميل النسخة الجديدة، إلغاء بلا حركة عند الرجوع.

## قواعد مشتركة غير قابلة للتفاوض

1. لا تسمح سلة البيع بكمية تتجاوز `availableQuantity` المصرح بها، **مع إعادة التحقق في السيرفر أثناء الترحيل**. اختيار الدفعة صريح. لا تحوّل مخزون محجوزًا/محظورًا لبيع أو عرض.
2. عروض السعر تُنشأ من الوكيل، لكن **قبول العرض أو الدفع من محفظة العميل يجب أن يحدث تحت جلسة العميل نفسه**؛ لا تحاكيه بهوية الوكيل. لا تعرض `pay-wallet` كعملية وكيل.
3. سياسة خصم/ائتمان/بنك/ضريبة/نوع صندوق لا يختارها الوكيل من تلقائه؛ تعتمد إعدادات مخولة `PUT /api/agent/commercial/policies/{delegationId}` بواسطة الإدارة فقط. في كل تأكيد تظهر عملة المتجر وعملة الصندوق ومبلغ الدفع واسم الطرف ورقم المرجع.
4. كل POST/PUT بتبعات مالية يتطلب `requestId` ثابتًا لنفس الحمولة، وعلامة `Pending server confirmation` عندما يُفقد جواب الشبكة. قبل محاولة جديدة افحص receipt وربط السجل؛ لا تكرر أثرًا ماليًا.
5. المراجع مستقل عن منشئ الجرد/التحويل/طلب الشراء/المرتجع/إقفال الصندوق. شاشات القرارات الإدارية موضحة في [04-extra-flows-and-qa.md](04-extra-flows-and-qa.md).
6. الفاتورة المرسلة للعميل أو المعاينة تعرض القيم المعادة فعليًا من `GET /api/agent/commercial/documents/{id}/receipt`؛ لا تُنتج ضريبة أو إجمالي نهائي من الهاتف.
7. تقارير N08 تحتاج كل صفحات المدة المختارة، وإلا تعرض عبارة «البيانات الحالية فقط» أو تتطلب API تقرير خادمي مستقل؛ لا تجعل تخمين النسبة أرقامًا حقيقية.
