# جدول التتبع التنفيذي — جميع شاشات التطبيق الـ92

هذه الوثيقة قائمة تفقد **صادرة من فهرس الشاشات الحالي للمراجعة فقط** ومطابقة لأوصاف 01–03 دون استخدام الشكل البصري الحالي كأساس للتصميم. لكل شاشة مسارات القراءة والتغيير المستخرجة من مواصفتها؛ **حقول الطلب ونتائج الاستجابة والنسخة والصلاحيات والتنقل** في المستند المصدر الموجود بجوارها. كل من X وE المشروطة مذكور في [04-extra-flows-and-qa.md](04-extra-flows-and-qa.md)، وليست مضافة إلى العدّ الأساسي الـ92.

> تنفيذ أي endpoint يجب أن يُراجع من ملفات C# المثبتة في [05](05-api-core-clinical.md)، [06](06-api-commerce-finance.md)، [07](07-api-field-pickup-marketplace.md) و[08](08-domain-payloads.md). URI في هذه القائمة مقتبس من مواصفة الشاشة وقد يحتوي معاملات استعلام مرجعية؛ يُبنى الطلب النهائي بالـ URI encoder لا بلصق النص. **لا تعتمد على البتات الموجودة في Flutter الحالي لتفويض الإدارة**؛ الأمر النهائي من السيرفر.

## الحساب والرئيسية — 11 شاشة

| رمز الشاشة | الهدف المعتمد | قراءة API | تغيير API | ملف العقد التفصيلي | دليل الاختبار |
|---|---|---|---|---|---|
| **H01** | الانطلاق والتحقق من الاتصال | `GET /api/agent/mobile/bootstrap` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `ID-01` |
| **H02** | تسجيل دخول الموظف | — (قراءة/عملية محلية موثقة في الملف) | `POST /api/Auth/login`؛ `POST /api/Auth/refresh`؛ `POST /api/Auth/logout` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `ID-01`, `ID-03` |
| **H03** | استعادة الوصول | `GET /api/support/faq-categories` | `POST /api/auth/forgot-password` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `UI-01` |
| **H04** | الأهلية والتفويض | `GET /api/agent/mobile/bootstrap`؛ `GET /api/agent/me`؛ `GET /api/agent/operations/home` | `PATCH /api/agent/availability` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `ID-01`, `ID-04`, `ID-07` |
| **H05** | الرئيسية التنفيذية | `GET /api/agent/operations/home`؛ `GET /api/agent/mobile/bootstrap`؛ `GET /api/agent/field/tasks?afterId=0`؛ `GET /api/notifications/unread-count` | `PATCH /api/agent/availability` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `ID-01`, `ID-02`, `ID-05` |
| **H06** | سياق المتجر والمخزن والصندوق | `GET /api/agent/mobile/bootstrap`؛ `GET /api/agent/me` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `ID-06`, `ID-07` |
| **H07** | صندوق الإشعارات | `GET /api/notifications?page=1&pageSize=…`؛ `GET /api/notifications/unread-count` | `POST /api/notifications/mark-read`؛ `POST /api/notifications/mark-all-read` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `ID-02` |
| **H08** | حسابي والهوية | `GET /api/users/me`؛ `GET /api/agent/me` | `PUT /api/users/me`؛ `POST /api/users/me/avatar` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `UI-02` |
| **H09** | المسودات والمزامنة | `GET /api/agent/mobile/changes?since=&afterId=`؛ `GET /api/agent/mobile/requests/{requestId}` | `POST /api/agent/mobile/sync/clinical-notes` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-05`, `CL-06`, `BM-06` |
| **H10** | الدعم والتذاكر | `GET /api/support/ticket-options`؛ `GET /api/support/faqs`؛ `GET /api/support/tickets`؛ `GET /api/support/tickets/{id}` | `POST /api/support/tickets`؛ `POST /api/support/tickets/{id}/messages`؛ `POST /api/support/tickets/{id}/close` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `UI-03` |
| **H11** | الجلسات والأمان | `GET /api/users/me/sessions` | `DELETE /api/users/me/sessions/{sessionId}`؛ `PUT /api/users/me/password`؛ `POST /api/Auth/logout` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `ID-01`, `ID-03` |

## الاستشارات والوصفات — 16 شاشة

| رمز الشاشة | الهدف المعتمد | قراءة API | تغيير API | ملف العقد التفصيلي | دليل الاختبار |
|---|---|---|---|---|---|
| **C01** | قائمة استشارات الطبيب | `GET /api/vet/cases?afterId=0`؛ `GET /api/agent/operations/home` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `ID-04`, `ID-05`, `CL-01` |
| **C02** | بطاقة الإحالة والقبول | `GET /api/vet/cases/{id}` | `POST /api/vet/cases/{id}/accept`؛ `POST /api/vet/cases/{id}/decline` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-01`, `CL-02`, `CL-03` |
| **C03** | الذكاء الاصطناعي المشترك بموافقة العميل | `GET /api/vet/cases/{id}/shared-ai?afterId=0` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-01`, `CL-02`, `CL-03` |
| **C04** | محادثة سريرية | `GET /api/vet/cases/{id}/messages?afterId=0` | `POST /api/vet/cases/{id}/messages` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-02`, `CL-04` |
| **C05** | ملفات الحالة السرية | `GET /api/vet/cases/{id}/attachments`؛ `GET /api/vet/cases/{id}/attachments/{fileId}` | `POST /api/vet/cases/{id}/attachments` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-03`, `CL-04` |
| **C06** | ملف الحيوان وسجل الحالة | `GET /api/vet/cases/{id}`؛ `GET /api/vet/cases/{id}/record` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `UI-04` |
| **C07** | حيوانات مرتبطة بالقضية | `GET /api/vet/cases/{id}/record`؛ `GET /api/vet/cases/{id}` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `UI-05` |
| **C08** | التقييم والملاحظات الموقعة | `GET /api/vet/cases/{id}/record` | `POST /api/vet/cases/{id}/notes`؛ `POST /api/agent/mobile/sync/clinical-notes` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-05`, `CL-06` |
| **C09** | مواعيد الزيارة والحجز | `GET /api/vet/cases/{id}/record`؛ `GET /api/agent/field/tasks` | `POST /api/vet/cases/{id}/visits`؛ `POST /api/vet/cases/{id}/visits/{taskId}/reschedule` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-07` |
| **C10** | منشئ الوصفة | `GET /api/vet/cases/{id}`؛ `GET /api/vet/medicine-rules?afterId=`؛ `GET /api/product-variants`؛ `GET /api/agent/commerce/inventory?delegationId=` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-08` |
| **C11** | توقيع وإصدار الوصفة | `GET /api/vet/cases/{id}`؛ `GET /api/vet/medicine-rules` | `POST /api/vet/prescriptions` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-08` |
| **C12** | الوصفة وتاريخ الصرف | `GET /api/vet/prescriptions?afterId=`؛ `GET /api/vet/prescriptions/{id}` | `POST /api/vet/prescriptions/{id}/cancel` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-08`, `CL-09` |
| **C13** | صرف مباشر من دفعة | `GET /api/vet/prescriptions/{id}`؛ `GET /api/agent/commerce/inventory?delegationId=`؛ `GET /api/agent/operations/cashbox?delegationId=` | `POST /api/vet/prescriptions/{id}/dispense` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-09`, `CL-10`, `FD-06` |
| **C14** | طلبات الشراء بوصفة وصرف الطلب | `GET /api/vet/prescription-orders?delegationId=&afterId=` | `POST /api/vet/prescription-orders/{orderId}/release`؛ `POST /api/agent/fulfillment/orders/{orderId}/prepare` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-10`, `CL-11` |
| **C15** | المتابعة والقرار الطبي | `GET /api/vet/cases/{id}`؛ `GET /api/vet/cases/{id}/record` | `POST /api/vet/cases/{id}/workflow` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `UI-06` |
| **C16** | إغلاق الحالة أو ملخصها | `GET /api/vet/cases/{id}/record`؛ `GET /api/vet/cases/{id}` | `POST /api/vet/cases/{id}/close` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `ID-04`, `CL-05`, `CL-12` |

## الميدان والحملات — 13 شاشة

| رمز الشاشة | الهدف المعتمد | قراءة API | تغيير API | ملف العقد التفصيلي | دليل الاختبار |
|---|---|---|---|---|---|
| **F01** | قائمة المهام المسندة | `GET /api/agent/field/tasks?afterId=` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `ID-04`, `FD-01` |
| **F02** | تفاصيل التكليف والمراحل | `GET /api/agent/field/tasks?afterId=` | `POST /api/agent/field/tasks/{id}/state`؛ `POST /api/agent/field/tasks/{id}/visits` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-07`, `FD-01`, `FD-02` |
| **F03** | تقويم الزيارات والمواعيد | `GET /api/agent/field/tasks?afterId=`؛ `GET /api/vet/cases/{id}/record` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-07`, `FD-02` |
| **F04** | تفاصيل الموقع والملاحة | `GET /api/agent/field/tasks?afterId=` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `FD-03` |
| **F05** | تسجيل الوصول وبدء الزيارة | `GET /api/agent/field/tasks?afterId=` | `POST /api/agent/field/visits/{id}/state` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-07`, `FD-01`, `FD-03` |
| **F06** | دفتر الزيارة | `GET /api/agent/field/tasks?afterId=`؛ `GET /api/vet/cases/{caseId}/record` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `CL-12` |
| **F07** | حيوان الزيارة المرتبط | `GET /api/vet/cases/{caseId}/record`؛ `GET /api/vet/cases/{caseId}` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `FD-04` |
| **F08** | فحص الحيوان الميداني | `GET /api/vet/cases/{caseId}/record`؛ `GET /api/agent/field/tasks` | `POST /api/AnimalInspections`؛ `POST /api/agent/field/visits/{id}/state` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `FD-04` |
| **F09** | قائمة الحملات | `GET /api/agent/field/campaigns?afterId=` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `FD-05` |
| **F10** | تفاصيل الحملة والفريق والاعتماد | `GET /api/agent/field/campaigns/{id}/report`؛ `GET /api/agent/field/campaigns/{id}/reconciliation` | `POST /api/agent/field/campaigns/{id}/state`؛ `PUT /api/agent/field/campaigns/{id}/team`؛ `PUT /api/agent/field/campaigns/{id}/authority`؛ `POST /api/agent/field/campaigns/{id}/stops`؛ `POST /api/agent/field/campaigns/{id}/allocations` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `FD-05` |
| **F11** | تسجيل نتيجة التلقيح | `GET /api/agent/field/campaigns/{id}/report`؛ `GET /api/agent/field/campaigns/{id}/reconciliation` | `POST /api/agent/field/campaigns/{id}/administrations` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `FD-05`, `FD-07` |
| **F12** | حرارة الحفظ والهدر والعهدة | `GET /api/agent/field/campaigns/{id}/reconciliation`؛ `GET /api/agent/operations/batch-holds?delegationId=&afterId=` | `POST /api/agent/field/campaigns/{id}/temperatures`؛ `POST /api/agent/field/campaigns/{id}/outcomes/{outcomeId}/review`؛ `POST /api/agent/field/campaigns/{id}/reconciliation` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `FD-06`, `FD-07` |
| **F13** | إتمام الزيارة والمهمة | `GET /api/agent/field/tasks?afterId=`؛ `GET /api/vet/cases/{id}/record``؛ `GET /api/vet/cases/{id}`` | `POST /api/agent/field/visits/{id}/state`؛ `POST /api/agent/field/tasks/{taskId}/state` | [حقول/نتائج/سيناريوهات](01-general-clinical-field.md) | `FD-01` |

## المخزون — 10 شاشة

| رمز الشاشة | الهدف المعتمد | قراءة API | تغيير API | ملف العقد التفصيلي | دليل الاختبار |
|---|---|---|---|---|---|
| **I01** | مخزون الفرع | `GET /api/agent/commerce/inventory?delegationId&afterId;`؛ `GET /api/agent/operations/batch-holds?delegationId&afterId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `ID-02`, `BM-01` |
| **I02** | تفاصيل رصيد صنف | `GET /api/agent/commerce/inventory?delegationId&afterId;`؛ `GET /api/product-variants/{variantId}` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-01` |
| **I03** | الدفعات والتسلسل | `GET /api/agent/commerce/inventory?delegationId&afterId;`؛ `GET /api/agent/operations/batch-holds?delegationId&afterId` | `POST /api/agent/operations/batch-holds` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `CL-09`, `FD-06` |
| **I04** | حركات الصنف | `GET /api/Inventory/{id}/transactions` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `UI-07` |
| **I05** | تنبيهات الصلاحية والنفاد والحجز | `GET /api/agent/commerce/inventory?delegationId&afterId;`؛ `GET /api/agent/operations/batch-holds?delegationId&afterId` | `POST /api/agent/operations/batch-holds` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `UI-08` |
| **I06** | التحويلات والطلبات | `GET /api/agent/commerce/transfers?delegationId&afterId;`؛ `GET /api/agent/supply/requests?delegationId&afterId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `UI-09` |
| **I07** | طلب تغذية أو تحويل | `GET /api/agent/commerce/inventory?delegationId&afterId;`؛ `GET /api/agent/supply/requests?delegationId&afterId;`؛ `GET /api/Warehouses` | `POST /api/agent/supply/requests`؛ `POST /api/agent/commerce/transfers` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-08` |
| **I08** | استلام جزئي ونقل العهدة | `GET /api/agent/commerce/transfers?delegationId&afterId` | `POST /api/agent/commerce/transfers/{id}/receive`؛ `POST /api/agent/supply/transfers/{id}/exceptions` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-08`, `BM-09` |
| **I09** | الجرد الفعلي | `GET /api/agent/commerce/inventory?delegationId&afterId` | `POST /api/agent/commerce/stock-counts` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-10` |
| **I10** | فروق الجرد والمراجعة | `GET /api/agent/mobile/changes?since&afterId`؛ `GET /api/agent/operations/review-queue?warehouseId&kind=StockCount&afterId` | `POST /api/agent/commerce/stock-counts/{id}/review` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-10` |

## التجارة — 14 شاشة

| رمز الشاشة | الهدف المعتمد | قراءة API | تغيير API | ملف العقد التفصيلي | دليل الاختبار |
|---|---|---|---|---|---|
| **T01** | مركز عمليات الفرع | `GET /api/agent/mobile/bootstrap`؛ `GET /api/agent/operations/home`؛ `GET /api/agent/operations/cashbox?delegationId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `ID-05` |
| **T02** | نقطة البيع وتجميع السلة | `GET /api/agent/commerce/inventory?delegationId&afterId`؛ `GET /api/product-variants`؛ `GET /api/products/resolve`؛ `GET /api/agent/operations/cashbox?delegationId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `ID-06`, `BM-02` |
| **T03** | قارئ الباركود/QR للمنتج | `GET /api/products/resolve`؛ `GET /api/product-variants/{id}` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-03` |
| **T04** | اختيار المتغير والدفعة | `GET /api/product-variants/{id};`؛ `GET /api/agent/commerce/inventory?delegationId&afterId;`؛ `GET /api/agent/operations/batch-holds?delegationId&afterId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `ID-06`, `BM-02`, `BM-03` |
| **T05** | مراجعة البيع وطريقة الدفع | `GET /api/agent/operations/cashbox?delegationId;`؛ `GET /api/agent/commercial/quotes/{quoteId}` | `POST /api/agent/commerce/documents` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `ID-07`, `BM-02`, `BM-04`, `BM-05`, `BM-06` |
| **T06** | فواتير المبيعات | `GET /api/agent/commerce/documents?delegationId&afterId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `UI-10` |
| **T07** | إيصال وفاتورة مرتبطة | `GET /api/agent/commercial/documents/{id}/receipt?delegationId`؛ `GET /api/agent/commerce/documents?delegationId&afterId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `CL-09`, `BM-06`, `BM-13` |
| **T08** | مرتجع مبيعات | `GET /api/agent/commercial/documents/{id}/receipt?delegationId`؛ `GET /api/agent/returns?delegationId&afterId` | `POST /api/agent/returns` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-13` |
| **T09** | عروض الأسعار والموافقة | `GET /api/agent/mobile/changes?since&afterId`؛ `GET /api/agent/commercial/quotes/{id}` | `POST /api/agent/commercial/quotes`؛ `POST /api/agent/commercial/quotes/{id}/accept` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-04` |
| **T10** | دليل الموردين | `GET /api/Suppliers` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `UI-11` |
| **T11** | المشتريات المستلمة/المرحّلة | `GET /api/agent/commerce/documents?delegationId&afterId`؛ `GET /api/agent/procurement?delegationId&afterId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `UI-12` |
| **T12** | إنشاء طلب شراء | `GET /api/Suppliers`؛ `GET /api/product-variants`؛ `GET /api/agent/procurement?delegationId&afterId` | `POST /api/agent/procurement` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-07` |
| **T13** | استلام مشتريات ودفعها | `GET /api/agent/procurement?delegationId&afterId`؛ `GET /api/agent/operations/cashbox?delegationId` | `POST /api/agent/procurement/{id}/receive` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-07` |
| **T14** | مرتجع مشتريات | `GET /api/agent/commerce/documents?delegationId&afterId`؛ `GET /api/agent/commercial/documents/{id}/receipt?delegationId` | `POST /api/agent/returns` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-14` |

## الصناديق والمالية — 8 شاشة

| رمز الشاشة | الهدف المعتمد | قراءة API | تغيير API | ملف العقد التفصيلي | دليل الاختبار |
|---|---|---|---|---|---|
| **N01** | صناديق الفرع المصرح بها | `GET /api/agent/mobile/bootstrap`؛ `GET /api/agent/operations/cashbox?delegationId&afterTransactionId=0` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-05`, `BM-11` |
| **N02** | حركات الصندوق | `GET /api/agent/operations/cashbox?delegationId&afterTransactionId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-11`, `PK-04` |
| **N03** | الوردية النقدية وفتحها | `GET /api/agent/operations/cashbox?delegationId` | `POST /api/agent/commerce/shifts` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `CL-10`, `BM-05`, `BM-11`, `PK-05` |
| **N04** | مطابقة وإقفال وردية | `GET /api/agent/operations/cashbox?delegationId` | `POST /api/agent/commerce/shifts/{id}/close`؛ `POST /api/agent/commerce/shifts/{id}/review` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-11` |
| **N05** | كشف حساب عميل أو مورد | `GET /api/agent/finance/statements?delegationId&partyId&supplier&afterId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-12` |
| **N06** | القيود المحاسبية | `GET /api/agent/finance/journals?delegationId&afterId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-12` |
| **N07** | تسوية فاتورة عميل أو مورد | `GET /api/agent/commercial/documents/{id}/receipt?delegationId`؛ `GET /api/agent/operations/cashbox?delegationId` | `POST /api/agent/finance/documents/{id}/settle` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `BM-12` |
| **N08** | لوحة تقارير المبيعات والمخزون | `GET /api/agent/commerce/documents?delegationId&afterId`؛ `GET /api/agent/operations/cashbox?delegationId`؛ `GET /api/agent/commercial/documents/{id}/receipt`` | `PUT /api/agent/commercial/policies/{delegationId}`` | [حقول/نتائج/سيناريوهات](02-inventory-trade-finance.md) | `UI-13` |

## الاستلام — 7 شاشة

| رمز الشاشة | الهدف المعتمد | قراءة API | تغيير API | ملف العقد التفصيلي | دليل الاختبار |
|---|---|---|---|---|---|
| **P01** | نقاط استلام المتجر | `GET /api/agent/pickup/points?afterId`؛ `GET /api/agent/mobile/bootstrap` | `POST /api/agent/pickup/points`؛ `POST /api/agent/pickup/points/{id}/deactivate` | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `PK-06` |
| **P02** | طابور الطلبات والنقطة | `GET /api/agent/pickup/requests?delegationId&afterId`؛ `GET /api/agent/pickup/points?afterId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `PK-01`, `PK-06` |
| **P03** | تفاصيل طلب ونقل الحيازة | `GET /api/agent/pickup/requests?delegationId&afterId`؛ `GET /api/agent/pickup/requests/{id}/custody-details?delegationId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `PK-01`, `PK-02` |
| **P04** | قبول حيازة محلية أو من سائق | `GET /api/agent/pickup/requests/{id}/custody-details?delegationId`؛ `GET /api/agent/pickup/requests?delegationId&afterId` | `POST /api/agent/pickup/requests/{id}/custody`؛ `POST /api/agent/pickup/requests/{id}/driver-code`؛ `POST /api/agent/pickup/requests/{id}/driver-handoff` | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `PK-01`, `PK-02` |
| **P05** | الرف والمهلة والتجهيز | `GET /api/agent/pickup/requests/{id}/custody-details?delegationId` | `POST /api/agent/pickup/requests/{id}/shelf` | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `PK-01` |
| **P06** | تسليم العميل والتحصيل | `GET /api/agent/pickup/requests?delegationId&afterId`؛ `GET /api/agent/pickup/requests/{id}/custody-details?delegationId`؛ `GET /api/agent/operations/cashbox?delegationId` | `POST /api/agent/pickup/requests/{id}/complete`؛ `POST /api/agent/pickup/requests/{id}/code` | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `PK-03`, `PK-04`, `PK-05` |
| **P07** | استثناء تلف/رفض/تأخر وإعادة للمصدر | `GET /api/agent/pickup/requests/{id}/custody-details?delegationId`؛ `GET /api/agent/pickup/requests?delegationId&afterId` | `POST /api/agent/pickup/requests/{id}/exceptions`؛ `POST /api/agent/pickup/exceptions/{id}/review` | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `PK-07` |

## المزادات — 9 شاشة

| رمز الشاشة | الهدف المعتمد | قراءة API | تغيير API | ملف العقد التفصيلي | دليل الاختبار |
|---|---|---|---|---|---|
| **A01** | قائمة مزادات الوكيل | `GET /api/agent/marketplace/auctions?delegationId&afterId` | `POST /api/agent/marketplace/auctions` | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `UI-14` |
| **A02** | مسودة معلومات المزاد وشروطه | `GET /api/agent/marketplace/auctions?delegationId&afterId`؛ `GET /api/agent/mobile/bootstrap` | `POST /api/agent/marketplace/auctions`؛ `PUT /api/agent/marketplace/auctions/{id}` | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `AU-01` |
| **A03** | عناصر المزاد والحدود السعرية | `GET /api/agent/commerce/inventory?delegationId&afterId`؛ `GET /api/product-variants`؛ `GET /api/Animals`؛ `GET /api/agent/marketplace/auctions?delegationId&afterId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `AU-01` |
| **A04** | صور عناصر المزاد وملكية الوسائط | `GET /api/agent/marketplace/auctions?delegationId&afterId` | `POST /api/Media/upload` | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `AU-01` |
| **A05** | المعاينة والإنشاء والتعديل | `GET /api/agent/marketplace/auctions?delegationId&afterId` | `POST /api/agent/marketplace/auctions`؛ `PUT /api/agent/marketplace/auctions/{id}` | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `AU-01`, `AU-02` |
| **A06** | إرسال للمراجعة والنشر والإلغاء | `GET /api/agent/marketplace/auctions?delegationId&afterId` | `POST /api/agent/marketplace/auctions/{id}/submit`؛ `POST /api/agent/marketplace/auctions/{id}/publish`؛ `POST /api/agent/marketplace/auctions/{id}/cancel` | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `AU-02`, `AU-05` |
| **A07** | العروض والمزايدات أثناء المزاد | `GET /api/agent/marketplace/auctions?delegationId&afterId`؛ `GET /api/AuctionBids/auction-item/{itemId}` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `AU-03` |
| **A08** | الفائز والسداد والتجهيز والتسليم | `GET /api/agent/marketplace/auctions/{id}/fulfillment`؛ `GET /api/agent/marketplace/auctions?delegationId&afterId` | `POST /api/agent/fulfillment/orders/{orderId}/prepare`؛ `POST /api/agent/fulfillment/auction-orders/{orderId}/code`؛ `POST /api/agent/fulfillment/auction-orders/{orderId}/complete` | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `AU-03`, `AU-04` |
| **A09** | رمز ومشاركة المزاد | `GET /api/identifiers/auctions/{id}`؛ `GET /api/agent/marketplace/auctions?delegationId&afterId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `UI-15` |

## المقترحات — 4 شاشة

| رمز الشاشة | الهدف المعتمد | قراءة API | تغيير API | ملف العقد التفصيلي | دليل الاختبار |
|---|---|---|---|---|---|
| **G01** | قائمة المقترحات الشخصية | `GET /api/agent/marketplace/proposals?afterId` | — (قراءة/عملية محلية موثقة في الملف) | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `UI-16` |
| **G02** | اقتراح منتج/شراء/تطوير | `GET /api/Suppliers`؛ `GET /api/agent/mobile/bootstrap` | `POST /api/agent/marketplace/proposals` | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `PR-01` |
| **G03** | تفاصيل الاقتراح ومرفقاته | `GET /api/agent/marketplace/proposals?afterId`؛ `GET /api/agent/mobile/records/{recordId}/files` | `POST /api/agent/mobile/records/{recordId}/files`؛ `POST /api/agent/marketplace/proposals/{id}/revise` | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `PR-01` |
| **G04** | قرار المقترح والناتج | `GET /api/agent/marketplace/proposals?afterId`؛ `GET /api/agent/mobile/changes?since&afterId` | `POST /api/agent/marketplace/proposals/{id}/review`؛ `POST /api/agent/pickup/points/{id}/incoming-quotes`` | [حقول/نتائج/سيناريوهات](03-pickup-auctions-proposals.md) | `PR-01`, `PR-02` |

## تحقق التغطية

- تحقق العدّ: `H=11 + C=16 + F=13 + I=10 + T=14 + N=8 + P=7 + A=9 + G=4 = 92`.
- الفهرس: 92 معرفًا متطابقًا مع [screens.dart](https://github.com/naba125555-ui/mazraa_agent/blob/f7d681e6b0663e44a63c6157b77f345be42814cf/lib/domain/screens.dart). لا توجد شاشة مفقودة أو مكررة في المواصفات 01–03.
- حضور الحقول/النتائج/السيناريوهات في كل فقرة تحقق بالتحليل النصي للوثائق. لا يعني ذلك إثبات نجاح اختبار API حي أو اكتمال كل DTO legacy؛ راجع [الفجوات](04-extra-flows-and-qa.md) لإغلاقها على staging.
- ظهور مرجع اختبار في الجدول هو ربط بنوع السيناريو لا إثباتًا بأن الاختبار شُغّل؛ إثبات التشغيل المستقبلي شرط بوابة الإطلاق. يوجد 72 اختبارًا معرفًا في وثيقة 04 تشمل كل شاشة مرجعية بالاسم.
- مجموع مراجع طلبات القراءة المتكررة عبر الشاشات: **172**، ومراجع الكتابة المتكررة: **95** (ليست عدد مسارات فريدة؛ شاشة قد تستدعي المسار نفسه الذي تستدعيه شاشة أخرى).
