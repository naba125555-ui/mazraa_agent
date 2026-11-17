# إعادة البناء شاشةً بشاشة — الاستلام والمزادات والمقترحات

**20 شاشة / 92**. الوثيقة تفصل بين إجراء الموظف، إجراء **العميل**، إجراء **السائق**، وإجراء **المراجع المخول**. أوصاف URL تستعمل placeholders دون قيود نوع ASP.NET؛ الحقول وأسماء أنواع C# الدقيقة في [07-api-field-pickup-marketplace.md](07-api-field-pickup-marketplace.md) و[06-api-commerce-finance.md](06-api-commerce-finance.md). المرجع [00-master-plan.md](00-master-plan.md).

## نقاط الاستلام والتسليم

### P01 — نقاط استلام المتجر

- **مصادر القراءة:** GET /api/agent/pickup/points?afterId؛ GET /api/agent/mobile/bootstrap.
- **نهايات الكتابة:** POST /api/agent/pickup/points (مراجع إداري مخول فقط)؛ POST /api/agent/pickup/points/{id}/deactivate (مراجع).
- **حقول الطلب:** PickupPointInput(requestId,delegationId,name,address,latitude,longitude,openingHours,capacity) للإنشاء الإداري؛ afterId لقائمة النقاط.
- **استجابات/حقول واجهة:** GET: [{id,warehouseId,name,address,latitude,longitude,openingHours}] دون صندوق أو كود؛ العمليات الإدارية تعيد id,status,version.
- **القيود والصلاحيات والتتابع:** Pickup=64 لإدارة طابور النقطة عبر P02؛ listing النقاط عامة للمستخدم المسجل؛ لا تضع زر تعطيل أو إنشاء لدى الحارس العادي؛ إيقاف نقطة بها طلبات معلقة ممنوع.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### P02 — طابور الطلبات والنقطة

- **مصادر القراءة:** GET /api/agent/pickup/requests?delegationId&afterId؛ GET /api/agent/pickup/points?afterId.
- **نهايات الكتابة:** —.
- **حقول الطلب:** delegationId تفويض Pickup،afterId؛ pointId فلتر واجهة فقط إذا لم تدعمه API.
- **استجابات/حقول واجهة:** [{id,version,status,pointId,orderId,readyAt,completedAt}]؛ لا ترجع قائمة الطلبات رموز/هاش QR.
- **القيود والصلاحيات والتتابع:** Pickup=64؛ فصل قيد الوصول من السائق/في الرف/جاهز/سُلّم/استثناء وفق الوقائع؛ P03؛ لا تُدخل كل طلبات المدينة ضمن واجهة الحارس.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### P03 — تفاصيل طلب ونقل الحيازة

- **مصادر القراءة:** GET /api/agent/pickup/requests?delegationId&afterId؛ GET /api/agent/pickup/requests/{id}/custody-details?delegationId.
- **نهايات الكتابة:** —؛ الحالات بعمليات P04–P07.
- **حقول الطلب:** requestId ليس مطلوبًا في GET؛ pickupId,delegationId؛ GET التفاصيل الأخرى قد يحتاج order route من صلاحياته.
- **استجابات/حقول واجهة:** request: id,version,status,pointId,orderId,readyAt,completedAt؛ movement: id,version,status,sourceWarehouseId,shelf,deadline,shipmentId.
- **القيود والصلاحيات والتتابع:** احتفظ بنسختين منفصلتين: pickup.version مقابل movement.version؛ لا تخلطهما في POST؛ إلى P04/P05/P06/P07.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### P04 — قبول حيازة محلية أو من سائق

- **مصادر القراءة:** GET /api/agent/pickup/requests/{id}/custody-details?delegationId؛ GET /api/agent/pickup/requests?delegationId&afterId.
- **نهايات الكتابة:** POST /api/agent/pickup/requests/{id}/custody (طلب محلي)؛ POST /api/agent/pickup/requests/{id}/driver-code (وارد)؛ تأكيد السائق POST /api/agent/pickup/requests/{id}/driver-handoff بهوية السائق.
- **حقول الطلب:** PickupCustodyInput(requestId,delegationId,version,itemsVerified,shelf?,deadline?)؛ PickupShelfInput(requestId,delegationId,version,shelf,deadline) لكود السائق؛ PickupDriverInput(requestId,version,shipmentId,code,itemsVerified) في تطبيق السائق فقط.
- **استجابات/حقول واجهة:** local: pickup.status/version؛ incoming driver-code: code,expiresAt,version للحيازة؛ driver-handoff: accepted,version عند السائق؛ يظهر movement.shipmentId عند الوصول.
- **القيود والصلاحيات والتتابع:** Pickup=64؛ تحقق طلب مجهّز وعدد قطع فعلي؛ الرمز المؤقت يُعرض فقط عند إصداره؛ لا تدّع استلامًا واردًا قبل تأكيد السائق.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### P05 — الرف والمهلة والتجهيز

- **مصادر القراءة:** GET /api/agent/pickup/requests/{id}/custody-details?delegationId.
- **نهايات الكتابة:** POST /api/agent/pickup/requests/{id}/shelf.
- **حقول الطلب:** PickupShelfInput(requestId,delegationId,version **نسخة حركة الحيازة**،shelf,deadline).
- **استجابات/حقول واجهة:** movement: id,version,status,sourceWarehouseId,shelf,deadline,shipmentId؛ التحديث يعيد version.
- **القيود والصلاحيات والتتابع:** Pickup=64؛ shelf<=80 حرفًا، deadline مستقبلية بحد 30 يومًا وفق التنفيذ؛ تغيير الرف ليس نفس عملية التسليم النهائي؛ إلى P06.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### P06 — تسليم العميل والتحصيل

- **مصادر القراءة:** GET /api/agent/pickup/requests?delegationId&afterId؛ GET /api/agent/pickup/requests/{id}/custody-details?delegationId؛ GET /api/agent/operations/cashbox?delegationId للـ COD.
- **نهايات الكتابة:** POST /api/agent/pickup/requests/{id}/complete؛ إصدار كود العميل POST /api/agent/pickup/requests/{id}/code **بجلسة العميل فقط**.
- **حقول الطلب:** PickupCompleteInput(requestId,delegationId,version **نسخة Pickup**،code,cashCollected).
- **استجابات/حقول واجهة:** accepted:true|false,version؛ عند النجاح order delivered + بيانات إقفال؛ فشل code قد يرجع 200 ويزيد محاولات.
- **القيود والصلاحيات والتتابع:** Pickup=64 وCash=32 عند التحصيل؛ كود لمرة واحدة صالح ~10 دقائق، 5 محاولات؛ prepaid cashCollected=0؛ تحصيل COD بالعملة المطابقة ومن وردية مفتوحة.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### P07 — استثناء تلف/رفض/تأخر وإعادة للمصدر

- **مصادر القراءة:** GET /api/agent/pickup/requests/{id}/custody-details?delegationId؛ GET /api/agent/pickup/requests?delegationId&afterId.
- **نهايات الكتابة:** POST /api/agent/pickup/requests/{id}/exceptions؛ POST /api/agent/pickup/exceptions/{id}/review (مراجع مستقل).
- **حقول الطلب:** PickupIssueInput(requestId,delegationId,version,reason,notes)؛ PickupExceptionReview(requestId,version,returnReceivedAtSource,resumeCustody,notes) للمراجع.
- **استجابات/حقول واجهة:** PickupException status/version وقرار الإرجاع الفعلي، refundDue إن وُجد على مسار التدفق.
- **القيود والصلاحيات والتتابع:** Pickup=64؛ لا تعتبر رفض العميل تسليمًا مكتملًا؛ إعادة مخزون مصدر مؤكدة ماديًا ومراجعة مستقلة؛ الاسترداد الحقيقي منفصل في X09.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

## المزادات

### A01 — قائمة مزادات الوكيل

- **مصادر القراءة:** GET /api/agent/marketplace/auctions?delegationId&afterId.
- **نهايات الكتابة:** POST /api/agent/marketplace/auctions عبر المعالج A02–A05.
- **حقول الطلب:** delegationId,afterId.
- **استجابات/حقول واجهة:** JSON object: reviews[] (AgentRecord<AuctionReviewData>) + auctions[] [{id,title,description,terms,status,startAt,endAt,guaranteeAmount,items[]}].
- **القيود والصلاحيات والتتابع:** Auction=128؛ انضمام auctions إلى reviews عبر review.details.auctionId أو relatedId لا افتراض تساوي المعرفين؛ إلى A02/A05/A06.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### A02 — مسودة معلومات المزاد وشروطه

- **مصادر القراءة:** GET /api/agent/marketplace/auctions?delegationId&afterId؛ GET /api/agent/mobile/bootstrap.
- **نهايات الكتابة:** لا كتابة حتى A05؛ POST /api/agent/marketplace/auctions أو PUT /api/agent/marketplace/auctions/{id} بعد المعاينة.
- **حقول الطلب:** AgentAuctionInput: requestId,delegationId,title,description,terms,startAt,endAt,guaranteeAmount,items[],photoMediaIds[]؛ edit: AgentAuctionEditInput(requestId,version,auction).
- **استجابات/حقول واجهة:** عند الحفظ: auctionId,reviewId,version,status؛ عند القراءة كامل بيانات المزاد.
- **القيود والصلاحيات والتتابع:** Auction=128؛ تكوين شروط وتواريخ مستقبلية وضمان؛ المسودة ليست منشورة؛ إلى A03؛ التعديل فقط في Draft/NeedsChanges/Rejected وبنسخة صالحة.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### A03 — عناصر المزاد والحدود السعرية

- **مصادر القراءة:** GET /api/agent/commerce/inventory?delegationId&afterId؛ GET /api/product-variants؛ GET /api/Animals فقط ضمن ملكية المزايد وبصلاحية legacy؛ GET /api/agent/marketplace/auctions?delegationId&afterId.
- **نهايات الكتابة:** يتبع حفظ المسودة A05؛ لا مزايدة من هوية الوكيل.
- **حقول الطلب:** items[]: AgentAuctionItemInput(animalId? XOR productVariantId?,startPrice,reservePrice?,minBidIncrement).
- **استجابات/حقول واجهة:** auction.items[id,animalId,productVariantId,startPrice,reservePrice,minBidIncrement]؛ حجز أصل/وحدة بعد النشر.
- **القيود والصلاحيات والتتابع:** المنتج في مخزن التفويض، الحيوان مملوك للمنشئ؛ وحدة واحدة/حيوان واحد لكل عنصر؛ لا أدوية وصفة في مزاد؛ إلى A04.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### A04 — صور عناصر المزاد وملكية الوسائط

- **مصادر القراءة:** GET /api/agent/marketplace/auctions?delegationId&afterId؛ GET أصل الحيوان/المنتج المصرح.
- **نهايات الكتابة:** POST /api/Media/upload وفق مسار entity ownership المعتمد في backend (ليس كملف طبي سري).
- **حقول الطلب:** Media مرتبطة بأصل Animal أو ProductItem يملكه منشئ المزاد؛ photoMediaIds:int[] ضمن AgentAuctionInput؛ راجع DTO رفع Media legacy قبل التنفيذ.
- **استجابات/حقول واجهة:** Media IDs صالحة ومُلكية مثبتة؛ تخزن المراجع لا Data URLs.
- **القيود والصلاحيات والتتابع:** Auction=128؛ لا تستخدم صور مخزن آخر أو ملفات مريض سرية؛ تحديث الصور يبطل hash المراجعة؛ إلى A05.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### A05 — المعاينة والإنشاء والتعديل

- **مصادر القراءة:** GET /api/agent/marketplace/auctions?delegationId&afterId.
- **نهايات الكتابة:** POST /api/agent/marketplace/auctions؛ PUT /api/agent/marketplace/auctions/{id}.
- **حقول الطلب:** Create AgentAuctionInput؛ Edit AgentAuctionEditInput(requestId,version,auction:{requestId,delegationId,title,description,terms,startAt,endAt,guaranteeAmount,items,photoMediaIds})؛ تحقق استقلال UUID والغلاف من C#.
- **استجابات/حقول واجهة:** Create: {auctionId,reviewId,version,status}؛ edit: سجل النسخة والحالة.
- **القيود والصلاحيات والتتابع:** معاينة نهائية لكل مادة وأسعار ووسائط وتاريخ وملكية؛ إجراءان صريحان حفظ مسودة أو متابعة؛ إلى A06.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### A06 — إرسال للمراجعة والنشر والإلغاء

- **مصادر القراءة:** GET /api/agent/marketplace/auctions?delegationId&afterId.
- **نهايات الكتابة:** POST /api/agent/marketplace/auctions/{id}/submit؛ POST /api/agent/marketplace/auctions/{id}/publish؛ POST /api/agent/marketplace/auctions/{id}/cancel؛ مراجعة الإدارة POST .../{id}/review.
- **حقول الطلب:** RecordVersionInput(requestId,version) للإرسال والنشر؛ AuctionCancelInput(requestId,version,reason) للإلغاء؛ ProposalReviewInput(requestId,version,status,notes,linkedEntityId?) للمراجع.
- **استجابات/حقول واجهة:** review.status = Draft/Pending/Approved/NeedsChanges/Rejected؛ hash submittedHash،reviewedBy؛ publish يؤدي إلى Scheduled حسب الجدولة.
- **القيود والصلاحيات والتتابع:** لا يستطيع المنشئ اعتماد مزاده؛ أي تعديل على المحتوى بعد المراجعة يبطل الموافقة؛ الإلغاء بعد عروض أو ضمان مدفوع يتطلب تسوية إدارية خارج زر عادي.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### A07 — العروض والمزايدات أثناء المزاد

- **مصادر القراءة:** GET /api/agent/marketplace/auctions?delegationId&afterId؛ GET /api/AuctionBids/auction-item/{itemId} (legacy).
- **نهايات الكتابة:** لا POST مزايدة باسم الزبون من وكيل الفرع؛ المزاد العام له عقود عملاء منفصلة.
- **حقول الطلب:** itemId الخاص بجدول AuctionItem،afterId إن كان في legacy.
- **استجابات/حقول واجهة:** العطاءات/المبالغ/الوقت والهوية المصرح بها، حالة المزاد الحية حسب API.
- **القيود والصلاحيات والتتابع:** Auction=128؛ تحديث دوري مع عدم تكرار طلبات غير لازمة؛ لا تعرض قائمة عامة بدون permission legacy؛ إلى A08.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### A08 — الفائز والسداد والتجهيز والتسليم

- **مصادر القراءة:** GET /api/agent/marketplace/auctions/{id}/fulfillment؛ GET /api/agent/marketplace/auctions?delegationId&afterId.
- **نهايات الكتابة:** POST /api/agent/fulfillment/orders/{orderId}/prepare؛ POST /api/agent/fulfillment/auction-orders/{orderId}/code؛ POST /api/agent/fulfillment/auction-orders/{orderId}/complete.
- **حقول الطلب:** AgentPrepareInput(requestId,delegationId)؛ إنشاء code حسب DTO الخاص بالـ endpoint (راجع ملحق 06)؛ AuctionHandoffInput(requestId,delegationId,version,code,itemsVerified).
- **استجابات/حقول واجهة:** fulfillment[]: auctionItemId,finalPrice,status,paymentDueAt,paidAt,orderId,orderStatus,paymentStatus؛ code مع expiry/version؛ handover accepted:true|false/version.
- **القيود والصلاحيات والتتابع:** Auction=128؛ لا تجهيز قبل دفع الفائز واستيفاء ضمانه؛ رمز تسليم مرة واحدة، وفحص مادي وأي رحلة سائق سارية تمنع المسار المباشر؛ خطأ رمز 200 accepted:false.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### A09 — رمز ومشاركة المزاد

- **مصادر القراءة:** GET /api/identifiers/auctions/{id} (legacy بعد النشر)؛ GET /api/agent/marketplace/auctions?delegationId&afterId.
- **نهايات الكتابة:** مشاركة رابط ثابت من مخرجات السيرفر فقط.
- **حقول الطلب:** id: auctionId معروف ومصرح نشره.
- **استجابات/حقول واجهة:** link / identifier / qr payload إن أعادها endpoint العام؛ لا تفترض الشكل قبل DTO legacy.
- **القيود والصلاحيات والتتابع:** لا مشاركة المسودة أو مزاد ملغى كقابل للمزايدة؛ الرجوع A06/A07.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

## المقترحات

### G01 — قائمة المقترحات الشخصية

- **مصادر القراءة:** GET /api/agent/marketplace/proposals?afterId.
- **نهايات الكتابة:** —.
- **حقول الطلب:** afterId؛ يحصل على سجلات منشئ المقترح فقط.
- **استجابات/حقول واجهة:** AgentRecord<ProposalData>[]: id,status,version,warehouseId,details[kind,title,description,supplierId,estimatedCost,currency,mediaIds,reviewedBy,...].
- **القيود والصلاحيات والتتابع:** Inventory=1 لإنشاء وفق المسار؛ READ الحالي يعود لصاحب المقترح؛ إلى G02/G03.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### G02 — اقتراح منتج/شراء/تطوير

- **مصادر القراءة:** GET /api/Suppliers (legacy إذن)، GET /api/agent/mobile/bootstrap؛ مصادر media المملوكة.
- **نهايات الكتابة:** POST /api/agent/marketplace/proposals.
- **حقول الطلب:** ProposalInput(requestId,delegationId,kind='product'|'purchase'|'improvement',title,description,supplierId?,estimatedCost?,currency?,mediaIds?).
- **استجابات/حقول واجهة:** AgentRecord<ProposalData> status=Pending,id,version,details؛ لا ينشئ منتجًا منشورًا.
- **القيود والصلاحيات والتتابع:** Inventory=1؛ صور عامة مملوكة حسب نوع المقترح، وإرفاق خاص بعد الإنشاء إذا انطبق؛ إلى G03.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### G03 — تفاصيل الاقتراح ومرفقاته

- **مصادر القراءة:** GET /api/agent/marketplace/proposals?afterId؛ GET /api/agent/mobile/records/{recordId}/files.
- **نهايات الكتابة:** POST /api/agent/mobile/records/{recordId}/files؛ POST /api/agent/marketplace/proposals/{id}/revise فقط بعد NeedsChanges.
- **حقول الطلب:** multipart: requestId,file ≤5MiB؛ ProposalReviseInput(requestId,delegationId,version,title,description,supplierId?,estimatedCost?,currency?,mediaIds?).
- **استجابات/حقول واجهة:** details,version,status,reviewNotes,linkedEntityId?؛ files[id,name,contentType,createdAt].
- **القيود والصلاحيات والتتابع:** لا افتراض GET /proposals/{id} مخصص؛ صَفّح حتى السجل؛ النسخ السابقة محفوظة ProposalRevision على السيرفر لكن لا يوجد GET revisions مستقل مثبت؛ إلى G04.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

### G04 — قرار المقترح والناتج

- **مصادر القراءة:** GET /api/agent/marketplace/proposals?afterId؛ GET /api/agent/mobile/changes?since&afterId.
- **نهايات الكتابة:** POST /api/agent/marketplace/proposals/{id}/review **للمراجع الإداري المستقل**؛ مراجعة بيانات النتيجة لصاحب المقترح قراءة فقط.
- **حقول الطلب:** ProposalReviewInput(requestId,version,status,notes,linkedEntityId?)؛ الصلاحية agent.proposals.review والملكية المغايرة.
- **استجابات/حقول واجهة:** status=Approved/Rejected/NeedsChanges،details.reviewedBy,reviewedAt,linkedEntityId,notes/version.
- **القيود والصلاحيات والتتابع:** الموافقة لا تنشئ صنفًا أو فاتورة تلقائيًا؛ الرابط إلى الأصل الموجود فقط بعد التحقق من صلاحيات قراءته؛ G03 أو مساحة المراجعات X03.
- **حالات إلزامية:** تحميل، فارغ، انقطاع، انتفاء تفويض، انتهاء صلاحية رمز أو موعد، تزاحم 409، تحقق 422، نجاح مشروط بالـ JSON الفعلي لا HTTP وحده؛ إعادة قراءة النسخة بعد العملية.

## محاذير خاصة

- استلام وارد عبر سائق: لا يُنشئ الوكيل quote عن العميل ولا يؤكد `driver-handoff` باسمه؛ `POST /api/agent/pickup/points/{id}/incoming-quotes` للعميل ثم checkout في تطبيق العميل ثم `driver-code` يصدره مسؤول النقطة ثم `driver-handoff` تحت جلسة السائق.
- `/api/agent/pickup/requests/{id}/code` إصدار **رمز العميل** لا رمز السائق؛ لا تخزنه في تنبيهات دائمة ولا تُعد استخدامه؛ `accepted:false` يتطلب إظهار «رمز غير صحيح» ومزامنة `version` الجديدة.
- إن رجع للمصدر مستند مرتجع مع `refundDue` فذلك مطالبة برد مال وليس إثبات دفع خارجي؛ مسار رد المال المعتمد مستقل، موثق في [04-extra-flows-and-qa.md](04-extra-flows-and-qa.md).
- قائمة المزادات ترجع `{reviews,auctions}` ولا ترجع list مباشرة. كل review يصف كيان Auction مختلف المعرف؛ البيانات تبقى مفصولة حتى يتم الربط على `relatedId`.
- `photoMediaIds` تخضع لفحص ownership في السيرفر؛ رفع صورة لا يُجيز تلقائيًا نشر المزاد. مزاد يحتوي عطاءات أو ضمانات مدفوعة لا يُلغى من الوكيل بمجرد الضغط على زر.
- ظهور قائمة مراجعات إدارية أو موافقة من الهيئة/الإدارة مشروط بإذن الإدارة الحقيقي. واجهة الطبيب/الوكيل العادي لا تُعرض فيها كأزرار ذات صلاحية مفترضة.
