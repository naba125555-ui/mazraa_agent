# إعادة البناء شاشةً بشاشة — الحساب والطب والميدان

**40 شاشة / 92**؛ تعريف وظيفي مستقل عن واجهات التطبيق القديمة. المرجع: [الخطة العامة](00-master-plan.md)، [عقود الهوية والطب](05-api-core-clinical.md)، [عقود الميدان](07-api-field-pickup-marketplace.md). حقول الـ DTO هنا مفاتيح مقصودة؛ **التعريف الكامل ونوع كل حقل** موجود في ملاحق Records المصدرية. أسماء الحقول المذكورة في نتائج القائمة هي ما تحتاجه الواجهة، وليست ضمانًا أن كل Route يعيدها حرفيًا في كل حالة؛ يُحسم shape باختبار Staging قبل البناء.

## الحساب والعموم

### H01 — الانطلاق والتحقق من الاتصال

- **القراءات اللازمة:** لا طلب عمل؛ حالة الحفظ المحلي ثم GET /api/agent/mobile/bootstrap عند وجود جلسة.
- **عمليات السيرفر:** —.
- **حقول الطلب (Inputs):** لغة وثيم محفوظان وإعداد API_BASE_URL آمن.
- **حقول/شكل الاستجابة (Outputs):** حالة الجلسة/صلاحية العقد/تاريخ UTC.
- **الصلاحية والسيناريو والتنقل:** لا تفتح شاشة عمليات قبل التفويض؛ خروج إلى H02 أو H04 أو H05.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### H02 — تسجيل دخول الموظف

- **القراءات اللازمة:** —.
- **عمليات السيرفر:** POST /api/Auth/login؛ POST /api/Auth/refresh؛ POST /api/Auth/logout.
- **حقول الطلب (Inputs):** LoginRequestDto: email,password,deviceName?,ipAddress?؛ RefreshRequestDto: refreshToken,deviceName?,ipAddress?.
- **حقول/شكل الاستجابة (Outputs):** AuthResponseDto: token,refreshToken,userId,roles,accessTokenExpiresAt,refreshTokenExpiresAt.
- **الصلاحية والسيناريو والتنقل:** حفظ Secure Storage؛ لا تسجيل مستخدم طبي من الهاتف؛ ثم H04.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### H03 — استعادة الوصول

- **القراءات اللازمة:** GET /api/support/faq-categories أو إرشاد اتصال الإدارة.
- **عمليات السيرفر:** POST /api/auth/forgot-password إذا تحقق دعم الهوية البريدية في staging.
- **حقول الطلب (Inputs):** ForgotPasswordDto ونموذج البريد؛ لا تدّع إرسال OTP دون اختبار.
- **حقول/شكل الاستجابة (Outputs):** نتيجة الخدمة العامة؛ لا إفصاح عن وجود الحساب.
- **الصلاحية والسيناريو والتنقل:** مسار مسؤول الترخيص/الفرع أساسي؛ رجوع H02.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### H04 — الأهلية والتفويض

- **القراءات اللازمة:** GET /api/agent/mobile/bootstrap؛ GET /api/agent/me؛ GET /api/agent/operations/home.
- **عمليات السيرفر:** PATCH /api/agent/availability فقط للطبيب المرخص.
- **حقول الطلب (Inputs):** available:bool مع عرض رقم الترخيص وتاريخ انتهائه ونطاقات التفويض.
- **حقول/شكل الاستجابة (Outputs):** doctorApproved,dispensingApproved,profile,canPractice,delegations,permissions.
- **الصلاحية والسيناريو والتنقل:** التمييز بين طبيب/مرخص صرف/وكيل؛ لا تمنح الواجهة صلاحية لا يمنحها السيرفر؛ إلى H06.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### H05 — الرئيسية التنفيذية

- **القراءات اللازمة:** GET /api/agent/operations/home؛ GET /api/agent/mobile/bootstrap؛ GET /api/agent/field/tasks?afterId=0؛ GET /api/notifications/unread-count.
- **عمليات السيرفر:** PATCH /api/agent/availability.
- **حقول الطلب (Inputs):** available:bool؛ لا تجلب 20 قائمة لتوليد بطاقات.
- **حقول/شكل الاستجابة (Outputs):** caseOffers,activeCases,pendingProposals,openShifts,serverTime,permissions والمهام الحديثة.
- **الصلاحية والسيناريو والتنقل:** بطاقات مرتبطة بـ C01/F01/T01/I01/N01/P01/A01/G01 حسب القدرات؛ لا أرقام اصطناعية.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### H06 — سياق المتجر والمخزن والصندوق

- **القراءات اللازمة:** GET /api/agent/mobile/bootstrap؛ GET /api/agent/me.
- **عمليات السيرفر:** تغيير محلي grantId فقط؛ لا تعديل تفويض إداري.
- **حقول الطلب (Inputs):** delegationId من delegations الفعالة؛ عرض storeId,warehouseId,cashBoxId,endsAt,capabilities.
- **حقول/شكل الاستجابة (Outputs):** الاختيار الحالي وحدود صلاحياته.
- **الصلاحية والسيناريو والتنقل:** يُفرغ السلة والمسودات المرتبطة بالنطاق وإعادة تحميل كل القراءات؛ إلى H05.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### H07 — صندوق الإشعارات

- **القراءات اللازمة:** GET /api/notifications?page=1&pageSize=…؛ GET /api/notifications/unread-count.
- **عمليات السيرفر:** POST /api/notifications/mark-read؛ POST /api/notifications/mark-all-read.
- **حقول الطلب (Inputs):** id أو قائمة معرّفات وفق DTO المسار؛ إشعار نوع/معرّف كيان.
- **حقول/شكل الاستجابة (Outputs):** eventType,entityId,read state,timestamp دون تفاصيل طبية سرية.
- **الصلاحية والسيناريو والتنقل:** الضغط يعيد طلب السجل بصلاحيات اللحظة ثم ينقل إلى تفاصيل C02/F02/I08/P03/A06/G03.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### H08 — حسابي والهوية

- **القراءات اللازمة:** GET /api/users/me؛ GET /api/agent/me.
- **عمليات السيرفر:** PUT /api/users/me؛ POST /api/users/me/avatar.
- **حقول الطلب (Inputs):** حقول تعديل الملف المدعومة فعليًا، وصورة Multipart بالطريقة الرسمية.
- **حقول/شكل الاستجابة (Outputs):** بيانات المستخدم ورابط الصورة وحالة الترخيص/الوكيل.
- **الصلاحية والسيناريو والتنقل:** روابط H04,H06,H09,H10,H11 والإعدادات، لا إدارة اعتماد الطبيب ذاتيًا.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### H09 — المسودات والمزامنة

- **القراءات اللازمة:** GET /api/agent/mobile/changes?since=&afterId=؛ GET /api/agent/mobile/requests/{requestId}.
- **عمليات السيرفر:** POST /api/agent/mobile/sync/clinical-notes.
- **حقول الطلب (Inputs):** MobileNoteOperation[]: requestId,caseId,body,sharedWithCustomer,amendsId (1–25).
- **حقول/شكل الاستجابة (Outputs):** results[]: requestId,status,result أو message؛ changes[],next,hasMore,serverTime.
- **الصلاحية والسيناريو والتنقل:** فقط ملاحظات طبية محلية مشفرة؛ العمليات المالية الغامضة للتحقق لا إعادة إنشاء.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### H10 — الدعم والتذاكر

- **القراءات اللازمة:** GET /api/support/ticket-options؛ GET /api/support/faqs؛ GET /api/support/tickets؛ GET /api/support/tickets/{id}.
- **عمليات السيرفر:** POST /api/support/tickets؛ POST /api/support/tickets/{id}/messages؛ POST /api/support/tickets/{id}/close.
- **حقول الطلب (Inputs):** موضوع، وصف، أولوية وخيار صالح؛ رد رسالة؛ تحقق من DTO العام.
- **حقول/شكل الاستجابة (Outputs):** قائمة تذاكر/حالة/رسائل واستجابة إنشاء أو رد.
- **الصلاحية والسيناريو والتنقل:** لا تستخدم الدعم لرفع ملف طبي خاص؛ إظهار تذكرة التفاصيل والرد.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### H11 — الجلسات والأمان

- **القراءات اللازمة:** GET /api/users/me/sessions.
- **عمليات السيرفر:** DELETE /api/users/me/sessions/{sessionId}؛ PUT /api/users/me/password؛ POST /api/Auth/logout.
- **حقول الطلب (Inputs):** sessionId:guid؛ currentPassword,newPassword؛ refreshToken للخروج.
- **حقول/شكل الاستجابة (Outputs):** قائمة جلسات وهوية أجهزة/وقت آخر نشاط؛ 204 لحذف جلسة.
- **الصلاحية والسيناريو والتنقل:** حظر عرض refreshToken؛ إنهاء الجلسة الحالية يوجه H02.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

## العيادة والاستشارات

### C01 — قائمة استشارات الطبيب

- **القراءات اللازمة:** GET /api/vet/cases?afterId=0؛ GET /api/agent/operations/home.
- **عمليات السيرفر:** —.
- **حقول الطلب (Inputs):** afterId؛ حالة/اسم العميل للبحث المحلي ضمن نتائج مأذونة.
- **حقول/شكل الاستجابة (Outputs):** قائمة cases تشمل id,status,version,animalId,doctorUserId وما يجيزه السيرفر.
- **الصلاحية والسيناريو والتنقل:** يتطلب اعتماد طبيب أو طرف مخول؛ بطاقة إلى C02؛ فلترة الجديد/النشط/المغلق.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### C02 — بطاقة الإحالة والقبول

- **القراءات اللازمة:** GET /api/vet/cases/{id}.
- **عمليات السيرفر:** POST /api/vet/cases/{id}/accept؛ POST /api/vet/cases/{id}/decline.
- **حقول الطلب (Inputs):** CaseVersionInput: requestId,version.
- **حقول/شكل الاستجابة (Outputs):** case id,status,version,reason,assigned doctor,consent metadata,animal info بحسب الدور.
- **الصلاحية والسيناريو والتنقل:** في Assigned معلومات محدودة قبل القبول؛ بعد Active إلى C03/C04/C06/C08/C09/C10/C15/C16.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### C03 — الذكاء الاصطناعي المشترك بموافقة العميل

- **القراءات اللازمة:** GET /api/vet/cases/{id}/shared-ai?afterId=0.
- **عمليات السيرفر:** لا يحق للطبيب تجديد موافقة العميل؛ إبطال الموافقة من دور المالك إذا سمح السيرفر.
- **حقول الطلب (Inputs):** caseId,afterId؛ قراءة متسلسلة مع نافذة معلومة.
- **حقول/شكل الاستجابة (Outputs):** رسائل AI المصرح بها حتى sharedThroughMessageId.
- **الصلاحية والسيناريو والتنقل:** إذا سُحبت الموافقة يتوقف العرض ويمسح الكاش؛ لا نسخ إلى إشعارات عامة.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### C04 — محادثة سريرية

- **القراءات اللازمة:** GET /api/vet/cases/{id}/messages?afterId=0.
- **عمليات السيرفر:** POST /api/vet/cases/{id}/messages.
- **حقول الطلب (Inputs):** CaseMessageInput: requestId,body.
- **حقول/شكل الاستجابة (Outputs):** رسائل المؤلف والتوقيت والمعرّف والحالة.
- **الصلاحية والسيناريو والتنقل:** بعد قبول الحالة فقط كتابة؛ إرسال واحد مؤكد؛ مرفقات C05.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### C05 — ملفات الحالة السرية

- **القراءات اللازمة:** GET /api/vet/cases/{id}/attachments؛ GET /api/vet/cases/{id}/attachments/{fileId}.
- **عمليات السيرفر:** POST /api/vet/cases/{id}/attachments.
- **حقول الطلب (Inputs):** multipart: requestId,file؛ PNG/JPEG/PDF؛ حد 5MiB و12 مرفقًا حسب السيرفر.
- **حقول/شكل الاستجابة (Outputs):** id,name,contentType,createdAt؛ تنزيل Byte stream محمي.
- **الصلاحية والسيناريو والتنقل:** منع روابط Media العامة؛ private/no-store؛ العودة C02/C04.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### C06 — ملف الحيوان وسجل الحالة

- **القراءات اللازمة:** GET /api/vet/cases/{id}؛ GET /api/vet/cases/{id}/record.
- **عمليات السيرفر:** لا إنشاء حيوان بدل العميل؛ تسجيل فحص ضمن F08.
- **حقول الطلب (Inputs):** caseId؛ تفاصيل الحيوان المرتبط بحقوق المالك.
- **حقول/شكل الاستجابة (Outputs):** animalId,notes,visits,workflow ضمن سجل الحالة.
- **الصلاحية والسيناريو والتنقل:** الحيوان مملوك للعميل؛ عدم تعديل الملكية؛ إلى C07/C08/F06.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### C07 — حيوانات مرتبطة بالقضية

- **القراءات اللازمة:** GET /api/vet/cases/{id}/record؛ GET /api/vet/cases/{id}.
- **عمليات السيرفر:** —.
- **حقول الطلب (Inputs):** caseId وليس GET كل الحيوانات من حسابات العملاء.
- **حقول/شكل الاستجابة (Outputs):** animal reference، visits، أي ترابط مصرّح به.
- **الصلاحية والسيناريو والتنقل:** قد يكون الحيوان الأساسي واحدًا للحالة؛ عدم اختلاق مجموعة ولا روابط عميل آخر.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### C08 — التقييم والملاحظات الموقعة

- **القراءات اللازمة:** GET /api/vet/cases/{id}/record.
- **عمليات السيرفر:** POST /api/vet/cases/{id}/notes؛ POST /api/agent/mobile/sync/clinical-notes للمسودات.
- **حقول الطلب (Inputs):** ClinicalNoteInput: requestId,body,sharedWithCustomer,amendsId?.
- **حقول/شكل الاستجابة (Outputs):** AgentCore.View<ClinicalNoteData>: body,sharedWithCustomer,amendsId,signedAt,licenseNumber,jurisdiction.
- **الصلاحية والسيناريو والتنقل:** ملاحظة غير قابلة للاستبدال؛ الملحق بتاريخ مستقل؛ عند إغلاق الحالة الملحق فقط.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### C09 — مواعيد الزيارة والحجز

- **القراءات اللازمة:** GET /api/vet/cases/{id}/record؛ GET /api/agent/field/tasks.
- **عمليات السيرفر:** POST /api/vet/cases/{id}/visits؛ POST /api/vet/cases/{id}/visits/{taskId}/reschedule.
- **حقول الطلب (Inputs):** ClinicalVisitInput: requestId,version,scheduledAt,location,reason؛ إعادة الجدولة DTO من الملحق.
- **حقول/شكل الاستجابة (Outputs):** حالة زيارة مرتبطة بمهمة FieldTask ومواعيد وزيارات السجل.
- **الصلاحية والسيناريو والتنقل:** لا تستخدم appointments القديم إذا كان سير عمل V2 يتطلب visits؛ إلى F02/F03.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### C10 — منشئ الوصفة

- **القراءات اللازمة:** GET /api/vet/cases/{id}؛ GET /api/vet/medicine-rules?afterId=؛ GET /api/product-variants؛ GET /api/agent/commerce/inventory?delegationId=.
- **عمليات السيرفر:** لا إرسال حتى C11؛ حفظ مسودة آمنة محلية.
- **حقول الطلب (Inputs):** caseId,validUntil,diagnosis,warnings,lines[{productVariantId,quantity,instructions}].
- **حقول/شكل الاستجابة (Outputs):** معاينة خطوط الوصفة وقواعد requiresPrescription,requir esInPerson,isVaccine والجنسية التنظيمية.
- **الصلاحية والسيناريو والتنقل:** تحقق من وجود زيارة مكتملة عند requiresInPerson؛ منع اقتراح الجرعة تلقائيًا؛ إلى C11.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### C11 — توقيع وإصدار الوصفة

- **القراءات اللازمة:** GET /api/vet/cases/{id}؛ GET /api/vet/medicine-rules.
- **عمليات السيرفر:** POST /api/vet/prescriptions.
- **حقول الطلب (Inputs):** PrescriptionInput: requestId,caseId,validUntil,diagnosis,warnings,lines:PrescribeLine[].
- **حقول/شكل الاستجابة (Outputs):** AgentCore.View<PrescriptionData>: caseId,animalId,jurisdiction,diagnosis,warnings,issuedAt,validUntil,lines.
- **الصلاحية والسيناريو والتنقل:** توقيع واعتماد الطبيب فقط؛ لا ترحيل بيع تلقائي؛ نجاح إلى C12.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### C12 — الوصفة وتاريخ الصرف

- **القراءات اللازمة:** GET /api/vet/prescriptions?afterId=؛ GET /api/vet/prescriptions/{id}.
- **عمليات السيرفر:** POST /api/vet/prescriptions/{id}/cancel.
- **حقول الطلب (Inputs):** RecordVersionInput: requestId,version.
- **حقول/شكل الاستجابة (Outputs):** lines[{productVariantId,quantity,instructions,dispensed}],status,validUntil,dispensations.
- **الصلاحية والسيناريو والتنقل:** لا إلغاء وصفة ليست في حالة يسمح بها السيرفر؛ مسار C13 أو C14 حسب الصلاحية.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### C13 — صرف مباشر من دفعة

- **القراءات اللازمة:** GET /api/vet/prescriptions/{id}؛ GET /api/agent/commerce/inventory?delegationId=؛ GET /api/agent/operations/cashbox?delegationId=.
- **عمليات السيرفر:** POST /api/vet/prescriptions/{id}/dispense.
- **حقول الطلب (Inputs):** DispenseInput: requestId,delegationId,version,customerId,lines[productVariantId,batchId,quantity],accessCode?.
- **حقول/شكل الاستجابة (Outputs):** DispensationData: prescriptionId,documentId,lines,dispensedAt؛ الفاتورة والنسخة بعد الصرف.
- **الصلاحية والسيناريو والتنقل:** رخصة صرف + 290 + وردية وصندوق صحيح؛ بيع جزئي وقيود مرة واحدة؛ إلى C12/T07.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### C14 — طلبات الشراء بوصفة وصرف الطلب

- **القراءات اللازمة:** GET /api/vet/prescription-orders?delegationId=&afterId=.
- **عمليات السيرفر:** POST /api/vet/prescription-orders/{orderId}/release؛ POST /api/agent/fulfillment/orders/{orderId}/prepare.
- **حقول الطلب (Inputs):** PrescriptionReleaseInput: requestId,delegationId,version,batches[]؛ prepare DTO راجعه في 06.
- **حقول/شكل الاستجابة (Outputs):** details[orderId,prescriptionId,lines,authorizedAt,batches],status,version.
- **الصلاحية والسيناريو والتنقل:** العميل وحده ينشئ checkout؛ الوكيل يطلق الدفعات بعد تحقق الدفع ثم تجهيز الطلب؛ لا صرف مرتين.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### C15 — المتابعة والقرار الطبي

- **القراءات اللازمة:** GET /api/vet/cases/{id}؛ GET /api/vet/cases/{id}/record.
- **عمليات السيرفر:** POST /api/vet/cases/{id}/workflow.
- **حقول الطلب (Inputs):** ClinicalWorkflowInput: requestId,version,stage,priority,followUpAt?,customerMessage.
- **حقول/شكل الاستجابة (Outputs):** stage,priority,followUpAt,customerMessage,updatedAt,version.
- **الصلاحية والسيناريو والتنقل:** الدكتور فقط؛ يفتح C02/C09/C16، وأي إخطار للعميل خال من التشخيص.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### C16 — إغلاق الحالة أو ملخصها

- **القراءات اللازمة:** GET /api/vet/cases/{id}/record؛ GET /api/vet/cases/{id}.
- **عمليات السيرفر:** POST /api/vet/cases/{id}/close.
- **حقول الطلب (Inputs):** CaseCloseInput: requestId,version,summary.
- **حقول/شكل الاستجابة (Outputs):** status=Closed وversion الجديد وsummary حسب endpoint.
- **الصلاحية والسيناريو والتنقل:** لا زيارات معلقة؛ لا تخفِ مستندًا أو وصفة مستمرة؛ بعد الإغلاق عرض للقراءة والملحقات المشروعة.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

## الميدان والحملات

### F01 — قائمة المهام المسندة

- **القراءات اللازمة:** GET /api/agent/field/tasks?afterId=.
- **عمليات السيرفر:** —.
- **حقول الطلب (Inputs):** afterId وحالة عرض محلية.
- **حقول/شكل الاستجابة (Outputs):** id,status,priority,scheduledAt,visits ضمن نوع استجابة FieldTask.
- **الصلاحية والسيناريو والتنقل:** طبيب مرخص صاحب المهمة؛ إلى F02/F03.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### F02 — تفاصيل التكليف والمراحل

- **القراءات اللازمة:** GET /api/agent/field/tasks?afterId=.
- **عمليات السيرفر:** POST /api/agent/field/tasks/{id}/state؛ POST /api/agent/field/tasks/{id}/visits.
- **حقول الطلب (Inputs):** FieldStateInput: requestId,expectedStatus,status؛ FieldVisitCreateInput: requestId,latitude?,longitude?,notes.
- **حقول/شكل الاستجابة (Outputs):** حالة المهمة والزيارات المرتبطة والتواريخ المحدّثة.
- **الصلاحية والسيناريو والتنقل:** لا تخمن expectedStatus؛ قبول/رفض/بدء/إنهاء فقط بحسب الانتقال الصحيح؛ إلى F04/F06.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### F03 — تقويم الزيارات والمواعيد

- **القراءات اللازمة:** GET /api/agent/field/tasks?afterId=؛ GET /api/vet/cases/{id}/record عند الحاجة.
- **عمليات السيرفر:** —؛ إعادة الجدولة عبر C09 وبالعقد الرسمي.
- **حقول الطلب (Inputs):** range محلي فوق صفحات مهام، لا تاريخ موحد يخمنه العميل.
- **حقول/شكل الاستجابة (Outputs):** visits[scheduledAt,startedAt,completedAt,status] المرتبطة بالمهمة.
- **الصلاحية والسيناريو والتنقل:** عرض يوم/أسبوع/قائمة مع تبويب المهام المتأخرة؛ إلى F02/F06.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### F04 — تفاصيل الموقع والملاحة

- **القراءات اللازمة:** GET /api/agent/field/tasks?afterId= أو تفاصيل المهمة المحمّلة.
- **عمليات السيرفر:** فتح تطبيق خرائط خارجي؛ لا mutation عند التنقل.
- **حقول الطلب (Inputs):** lat/long فقط إذا موجودة؛ مسار بديل عنوان مكتوب.
- **حقول/شكل الاستجابة (Outputs):** موقع/وصف المهمة من الخادم؛ لا جغرافيا مفبركة.
- **الصلاحية والسيناريو والتنقل:** إذن الموقع لبدء الزيارة F05 فقط؛ عرض خطأ غياب إحداثيات.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### F05 — تسجيل الوصول وبدء الزيارة

- **القراءات اللازمة:** GET /api/agent/field/tasks?afterId=.
- **عمليات السيرفر:** POST /api/agent/field/visits/{id}/state.
- **حقول الطلب (Inputs):** FieldVisitStateInput: requestId,expectedStatus=Scheduled,status=Started,latitude?,longitude?.
- **حقول/شكل الاستجابة (Outputs):** visit.status,startedAt وبيانات موقع مؤكدة.
- **الصلاحية والسيناريو والتنقل:** GPS بإذن صريح ووقت UTC؛ عند التعارض اقرأ حالة الزيارة من جديد؛ إلى F06.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### F06 — دفتر الزيارة

- **القراءات اللازمة:** GET /api/agent/field/tasks?afterId=؛ GET /api/vet/cases/{caseId}/record.
- **عمليات السيرفر:** تحديثات عبر F05/F08/F13 وليس كتابة عامة.
- **حقول الطلب (Inputs):** visitId,taskId,caseId بحسب ارتباط الخدمة.
- **حقول/شكل الاستجابة (Outputs):** status,diagnosis,findings,treatment,recommendations,startedAt,completedAt.
- **الصلاحية والسيناريو والتنقل:** التنقل F07/F08/F13؛ عرض إصدار ومصدر البيانات بدل JSON خام.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### F07 — حيوان الزيارة المرتبط

- **القراءات اللازمة:** GET /api/vet/cases/{caseId}/record؛ GET /api/vet/cases/{caseId}.
- **عمليات السيرفر:** —.
- **حقول الطلب (Inputs):** caseId يُستنتج من الربط المصرح به لا مسح كافة العملاء.
- **حقول/شكل الاستجابة (Outputs):** animalId، زيارات الحالة المعينة، بيانات الحيوان المرئية.
- **الصلاحية والسيناريو والتنقل:** لا فحص لحيوان غير مملوك لحالة مصرّح بها؛ إلى C06/F08.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### F08 — فحص الحيوان الميداني

- **القراءات اللازمة:** GET /api/vet/cases/{caseId}/record؛ GET /api/agent/field/tasks.
- **عمليات السيرفر:** POST /api/AnimalInspections فقط بعد تحقق إذن legacy؛ POST /api/agent/field/visits/{id}/state لتقرير الزيارة.
- **حقول الطلب (Inputs):** CreateAnimalInspectionDto بالحقول الرسمية animalId,weightKg?,healthStatus,findings,recommendations,notes؛ FieldVisitStateInput عند الإغلاق.
- **حقول/شكل الاستجابة (Outputs):** AnimalInspectionDto أو تحديث حالة زيارة حسب المسار.
- **الصلاحية والسيناريو والتنقل:** قد يتطلب /api/AnimalInspections صلاحية منفصلة؛ لا إنشاء سجل خارج حالة معتمدة؛ إلى F06/F13.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### F09 — قائمة الحملات

- **القراءات اللازمة:** GET /api/agent/field/campaigns?afterId=.
- **عمليات السيرفر:** —.
- **حقول الطلب (Inputs):** afterId؛ معايير البحث بحسب ما يدعمه السيرفر.
- **حقول/شكل الاستجابة (Outputs):** AgentCore.View<CampaignData>، status,version ومعلومات القرية واللقاح.
- **الصلاحية والسيناريو والتنقل:** الوصول حسب أعضاء الفريق/التفويض؛ إلى F10.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### F10 — تفاصيل الحملة والفريق والاعتماد

- **القراءات اللازمة:** GET /api/agent/field/campaigns/{id}/report؛ GET /api/agent/field/campaigns/{id}/reconciliation.
- **عمليات السيرفر:** POST /api/agent/field/campaigns/{id}/state؛ PUT /api/agent/field/campaigns/{id}/team؛ PUT /api/agent/field/campaigns/{id}/authority؛ POST /api/agent/field/campaigns/{id}/stops؛ POST /api/agent/field/campaigns/{id}/allocations.
- **حقول الطلب (Inputs):** CampaignStateInput: requestId,version,status,report؛ TeamInput:members[]؛ AuthorityInput: reference,allowGroups,allowFree,min/max Celsius,expiresAt؛ StopInput وAllocationInput في ملحق 07.
- **حقول/شكل الاستجابة (Outputs):** campaign,team,authority,stops,allocated batches,report,version.
- **الصلاحية والسيناريو والتنقل:** إجراءات الفريق/السلطة والعهود مشروطة بالإذن الإداري؛ عضو الفريق يعرض فقط ويبدأ عمله؛ إلى F11/F12.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### F11 — تسجيل نتيجة التلقيح

- **القراءات اللازمة:** GET /api/agent/field/campaigns/{id}/report؛ GET /api/agent/field/campaigns/{id}/reconciliation.
- **عمليات السيرفر:** POST /api/agent/field/campaigns/{id}/administrations.
- **حقول الطلب (Inputs):** CampaignAdministrationInput: requestId,outcome,animalId?,group?,animalCount,stopId?,batchId?,quantity,doseNumber,capturedAt,nextDueAt?,latitude?,longitude?,notes,prescriptionId?.
- **حقول/شكل الاستجابة (Outputs):** CampaignOutcomeData ونسخة سجل outcome؛ outcome=administered/deferred/excluded/waste/return.
- **الصلاحية والسيناريو والتنقل:** تأكد من team/authority/batch/cold-chain وشروط الوصفة، لا خصم ثاني عند الإعطاء؛ إلى F10/F12.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### F12 — حرارة الحفظ والهدر والعهدة

- **القراءات اللازمة:** GET /api/agent/field/campaigns/{id}/reconciliation؛ GET /api/agent/operations/batch-holds?delegationId=&afterId=.
- **عمليات السيرفر:** POST /api/agent/field/campaigns/{id}/temperatures؛ POST /api/agent/field/campaigns/{id}/outcomes/{outcomeId}/review؛ POST /api/agent/field/campaigns/{id}/reconciliation.
- **حقول الطلب (Inputs):** CampaignTemperatureInput: requestId,batchId,celsius,capturedAt,notes؛ ReviewInput:requestId,version,approve,notes.
- **حقول/شكل الاستجابة (Outputs):** temperatures,excursion,allocations,administered/sold/wasted/returned,reconciliation,version.
- **الصلاحية والسيناريو والتنقل:** عند تجاوز درجة الحرارة توقف الدفعة؛ مراجعة مستقلة للهدر/التسوية؛ لا صرف بعد الحظر.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.

### F13 — إتمام الزيارة والمهمة

- **القراءات اللازمة:** GET /api/agent/field/tasks?afterId=.
- **عمليات السيرفر:** POST /api/agent/field/visits/{id}/state ثم POST /api/agent/field/tasks/{taskId}/state.
- **حقول الطلب (Inputs):** FieldVisitStateInput: expectedStatus=Started,status=Completed,diagnosis,findings,treatment,recommendations,requestId؛ FieldStateInput:expectedStatus,status.
- **حقول/شكل الاستجابة (Outputs):** status=Completed,completedAt وسجل الحالة/المهمة المحدث.
- **الصلاحية والسيناريو والتنقل:** اربط الانتقالين على مراحل مستقلة؛ إذا الأول نجح والثاني تعثر لا تكرر الأول بقرار جديد.
- **حالات إلزامية:** تحميل أولي، قائمة فارغة، انقطاع/إعادة محاولة قراءة، 401/403/404/409/422 بحسب العملية، نجاح مؤكد ونسخة أحدث؛ لا تُعرض بيانات خارج النطاق.


## ملاحظات منع اللبس الطبية

- `GET /api/vet/cases/{id}/record` لا يعوض `GET /api/vet/cases/{id}` في اتخاذ قرار مبني على نسخة الحالة.
- قبل القبول قد يتعمد السيرفر قصر التفاصيل على معلومات بسيطة؛ عرض التشخيص قبل القبول أو بعد سحب المهمة خرق أمني.
- مسار الصرف المستقل ومسار صرف طلب الوصفة مرحلتان مختلفتان؛ لا تُدمجا في زر واحد بلا شروط ترخيص/دفع/دفعة/مخزن.
- `F11` في V2 يستخدم `administrations` وليس مسار `vaccinations` الأساسي وحده؛ يجب معرفة نوع الحملة وصلاحيات المراجع من خدمة السيرفر.
- `F08` عبر legacy يتطلب مراجعة guard وPermission في staging؛ إذا لم يسمح، يدون الفحص داخل حقول تقرير الزيارة المتاحة بدل تجاوز الصلاحيات.
