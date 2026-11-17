# قاموس حمولات العمليات والنماذج المشتركة (Domain / Payload)

> **مصدر الحقيقة:** كود السيرفر عند commit `4f8c947866cde3729b11697ec5c44ce41f516595`. هذه الأنواع تتبع أسماء C#؛ عند التراسل JSON سيظهر غالبًا camelCase، وبعض enums قد تكون strings بواسطة serializer؛ يلزم اختبار Contract HTTP لحسم أي تعارض. حقول `null` اختيارية بحسب النوع **لكن ليست بالضرورة مقبولة في جميع حالات انتقال العمل**. في تطبيق Flutter أنشئ Typed Models مع `fromJson/toJson` واختبارات عكسية، ولا تستخدم Map ديناميكيًا لمعالجة الأموال والحالات.

## 1. أغلفة السجلات والقراءات

- `AgentCore.View<T>(AgentRecord r)` يعيد: `id,kind,status,version,ownerId,customerId,warehouseId,otherWarehouseId,relatedId,createdAt,updatedAt,details` حيث `details` من نوع `T` الذي يختلف حسب `kind`.
- `GET /api/agent/mobile/changes?since&afterId` يعيد `serverTime,changes[],next:{since,afterId}|null,hasMore`. التغييرات ليست بديلًا عن قائمة تفاصيل كاملة؛ والعناصر `revoked:true` تخفي/تمحو البيانات المحلية وتحتاج تحقق الصلاحيات.
- `GET /api/agent/commerce/inventory` ليس `AgentRecord`: يعيد صفوف inventory مع nested `batches`. `GET /api/agent/marketplace/auctions` يعيد `{reviews,auctions}` وليس مصفوفة فقط. `GET /api/agent/operations/cashbox` يعيد `{id,name,currencyCode,openingBalance,currentBalance,transactions,shifts}`.
- النتيجة المعادة عند `AgentCore.Run` قد تكون DTO مختلفة عن `AgentRecord.View`؛ لا تفترض أن جميع POST يعيدون version أو status أو id بدون فحص الـ controller.
- `GET /api/vet/prescription-orders?delegationId&afterId` يعيد `AgentRecord<PrescriptionOrderData>[]` لصاحب صلاحية الصرف ضمن المستودع المحدد، ويعيد سجلات العميل عند غياب التفويض حسب التنفيذ؛ لا تستخدمها كقائمة وكيل بدون `delegationId`.

## 2. نماذج الرخصة والتفويض

- `AgentCapability`: Inventory 1, Sell 2, Purchase 4, Transfer 8, StockCount 16, Cash 32, Pickup 64, Auction 128, Dispense 256, Credit 512, Discount 1024.
- `AgentRecordStatus`: Draft, Pending, Approved, Active, Completed, Rejected, Cancelled, NeedsChanges؛ `VetCaseStatus`: Requested,Assigned,Active,Closed,Cancelled.
- يفرق تطبيق الصلاحيات بين `doctorApproved` من bootstrap و`canPractice` من profile ومنح المستودع ورخصة الصرف وصلاحية الإدارة؛ مجرد إعطاء Pickup + Cash لا يكفي دون صندوق ووردية للعملية النقدية.
- `AgentDelegation`: id,userId,storeId,warehouseId,cashBoxId,capabilities,isActive,endsAt,grantedBy,updatedAt؛ ظهور grant لا يجيز إلا المسارات التي تعيد تفويضه آنيًا.
- `VetProfile`: userId,licenseNumber,jurisdiction,specialty,licenseExpiresAt,isApproved,isAvailable,reviewedBy,reviewedAt؛ التراخيص والموافقة إدارة فقط، ولا يُسمح بالتعديل الذاتي.

## AgentAuctionStock

[ملف التعريف عند النسخة المثبتة](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentAuctionStock.cs)

- **`AuctionAllocationData`**: `int AuctionId, int ItemId, int? ProductVariantId, int? BatchId, int? AnimalId, int? OrderId = null, DateTime? PreparedAt = null, string? HandoffHash = null, DateTime? HandoffExpiresAt = null, int Attempts = 0`.

## AgentCampaignStock

[ملف التعريف عند النسخة المثبتة](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentCampaignStock.cs)

- **`CampaignStockLine`**: `int ProductVariantId, int BatchId, decimal Issued, decimal Administered, decimal Sold, decimal Wasted, decimal Returned`.

- **`CampaignAllocationData`**: `int CampaignId, CampaignStockLine[] Lines, string Notes`.

- **`CampaignAuthorityData`**: `string Reference, bool AllowGroups, bool AllowFree, decimal MinimumCelsius, decimal MaximumCelsius, DateTime ExpiresAt, int ReviewedBy, bool PrescriptionExemption = false`.

- **`CampaignTeamData`**: `int[] Members`.

- **`CampaignStopData`**: `string Name, decimal Latitude, decimal Longitude, DateTime ScheduledAt, DateTime? ArrivedAt, DateTime? CompletedAt, string Notes`.

- **`CampaignOutcomeData`**: `int CampaignId, int? StopId, int? AnimalId, string? Group, int AnimalCount, string Outcome, int? BatchId, decimal Quantity, int DoseNumber, DateTime CapturedAt, DateTime RecordedAt, DateTime? NextDueAt, decimal? Latitude, decimal? Longitude, string Notes, int? PrescriptionId`.

- **`CampaignTemperatureData`**: `int CampaignId, int BatchId, decimal Celsius, DateTime CapturedAt, bool Excursion, string Notes`.

## AgentClinical

[ملف التعريف عند النسخة المثبتة](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentClinical.cs)

- **enum `ClinicalStage`**: `Consulting = 1, AwaitingInformation, VisitRequested, FollowUp, Referred`.

- **`VisitScheduleData`**: `int TaskId, int DoctorId, DateTime ScheduledAt, string Location, string Reason, DateTime? PreviousDate = null`.

- **`DispensingLicenseData`**: `string Number, string Jurisdiction, DateTime ExpiresAt, int ReviewedBy, string Notes`.

- **`CaseWorkflowData`**: `ClinicalStage Stage, string Priority, DateTime? FollowUpAt, string CustomerMessage`.

- **`ClinicalNoteData`**: `string Body, bool SharedWithCustomer, int? AmendsId, DateTime SignedAt, string LicenseNumber, string Jurisdiction`.

## AgentCommerceEngine

[ملف التعريف عند النسخة المثبتة](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentCommerceEngine.cs)

- **`CommercePolicyData`**: `decimal MaxDiscountPercent, decimal MaxCreditAmount, bool AllowBank, bool AllowWallet, int? CountryId, int? CityId, bool RecoverPurchaseTax = false`.

- **`CommercialLine`**: `int ProductVariantId, int? BatchId, decimal Quantity, decimal UnitPrice, decimal Discount, decimal Tax, decimal Total, string? BatchNumber, DateTime? ExpiryDate`.

- **`SaleQuoteData`**: `int DelegationId, bool Purchase, int PartyId, string Currency, CommercialLine[] Lines, decimal Total, DateTime ExpiresAt, int? DocumentId, bool CustomerAccepted = false, int? CampaignId = null`.

- **`CommercialPostingData`**: `int DocumentId, bool RecoverPurchaseTax`.

## AgentPrescriptionOrders

[ملف التعريف عند النسخة المثبتة](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentPrescriptionOrders.cs)

- **`RxOrderLine`**: `int ProductVariantId, decimal Quantity`.

- **`PrescriptionOrderData`**: `int PrescriptionId, int OrderId, int DelegationId, RxOrderLine[] Lines, AgentStockLine[] Batches, DateTime? AuthorizedAt, DateTime? DispensedAt, int? DocumentId`.

- **`PrescriptionAccessData`**: `int DelegationId, string TokenHash, DateTime ExpiresAt`.

## AgentStock

[ملف التعريف عند النسخة المثبتة](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentStock.cs)

- **`AgentStockLine`**: `int ProductVariantId, int BatchId, decimal Quantity`.

## AgentModels

[ملف التعريف عند النسخة المثبتة](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentModels.cs)

- **enum `AgentCapability`**: `None = 0, Inventory = 1, Sell = 2, Purchase = 4, Transfer = 8, StockCount = 16, Cash = 32, Pickup = 64, Auction = 128, Dispense = 256, Credit = 512, Discount = 1024`.

- **enum `VetCaseStatus`**: `Requested = 1, Assigned, Active, Closed, Cancelled`.

- **enum `AgentRecordKind`**: `Prescription = 1, Dispensation, Campaign, Vaccination, Transfer, TransferReceipt, StockCount, CashShift, PickupPoint, Pickup, AuctionReview, Proposal, BatchHold, ClinicalNote, CaseWorkflow, VisitSchedule, PrescriptionOrder, PrescriptionAccess, DispensingLicense, CommercePolicy, SaleQuote, PurchaseRequest, TransferRequest, TransferException, CampaignTeam, CampaignStop, CampaignAllocation, CampaignOutcome, CampaignTemperature, CampaignReconciliation, PickupMovement, PickupException, PickupProxy, FinancialAdjustment, AuctionAllocation, ProposalRevision, SyncReceipt, PatientConsent, ReturnRequest, CommercialPosting, CampaignAuthority, CustomerRefund`.

- **enum `AgentRecordStatus`**: `Draft = 1, Pending, Approved, Active, Completed, Rejected, Cancelled, NeedsChanges`.

## 3. أنواع legacy الأساسية التي لا يصح تخمينها

- `AuthResponseDto`: `token,tokenType,refreshToken,accessTokenExpiresAt,refreshTokenExpiresAt,userId,email,role,roles`; انظر [AuthResponseDto.cs](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/DTOs/Auth/AuthResponseDto.cs).
- `LoginRequestDto`: `email,password,deviceName?,ipAddress?`؛ `RefreshRequestDto`: `refreshToken,deviceName,ipAddress`.
- `CreateOrderDto` (لعميل الوصفة، **ليس** للوكيل كي يتقمص العميل): `userId,addressId,checkoutRequestId,prescriptionId,dispensingDelegationId,warehouseId,deliveryZoneId,deliverySlotId,deliveryQuoteId,deliveryTermsAccepted,couponCode,items[],paymentMethod`. معاينة الوصفة `POST /api/vet/prescriptions/{id}/checkout/preview` وشراءها `POST .../checkout` هما دور العميل. [مرجع](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/DTOs/Orders/CreateOrderDto.cs).
- `OrderResponseDto` (في المسارات التي تُعيده فعليًا): `id,userId,userName,storeId,warehouseId,addressId,subtotal,discountAmount,taxAmount,deliveryFee,totalPrice,storeName,status,paymentStatus,shipmentId,shipmentStatus,canCancel,canReturn,canRate,address,createdAt,totalItemsCount,isPaid,paymentMethod,items`. [مرجع](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/DTOs/Orders/OrderResponseDto.cs).
- `ProductVariantDetailsDto`: `id,productId,product,sku,price,salePrice,hasAvailableCoupon,totalStock,weight,length,width,height,unitId,unit,manufacturerId,manufacturer,isAvailable,storeId,createdByUserId,createdAt,images,barcode,purchasePrice,basePrice,minStockLevel,totalPieces,totalBoxes,piecesPerBox,countryOfOrigin,productionDate,expiryDate,formula,usageMethod`. **هذه ليست كمية المتوفر داخل مخزن الوكيل**؛ المرجع لإتاحته للبيع هو inventory scoped وقرار الخادم. [مرجع](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/DTOs/ProductVariant/ProductVariantDetailsDto.cs).
- `InventoryDetailsDto` القديم يحتوي أيضًا على `minimumStock,maximumStock,reorderPoint,safetyStock,lastPurchaseCost,lastMovementDate,transactions,reservations`، لكن **إخراج endpoint الوكيل `GET /api/agent/commerce/inventory` لا يُرجع هذه الحقول**؛ للحصول عليها يلزم واجهة قراءة ذات صلاحية مثبتة أو تعديل خلفي منفصل. [مرجع](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/DTOs/Inventory/InventoryDetailsDto.cs).

## 4. شجرة التعويل بين النماذج

```text
Session/AuthResponse
  -> Bootstrap + AgentMe + OperationsHome
  -> Active Delegation + Doctor License + Dispenser License
    -> InventorySummary -> Batches -> StockLines / CountLines / TransferLines
    -> Cashbox -> ShiftData -> Documents -> Receipt / Statements / Journals
    -> VetCase -> ClinicalRecord -> PrescriptionData -> DispensationData OR PrescriptionOrderData
    -> FieldTask -> FieldVisit -> CampaignData -> Team/Stops/Authority/Outcome/Reconciliation
    -> PickupPoint -> PickupData + PickupMovementData -> One-time codes -> order/handover
    -> AuctionReviewData -> Auction + Items -> Allocation -> winner/order/guarantee
    -> ProposalData -> ProposalRevision -> Independent Review
```

## 5. قواعد تحويل إلى طبقة البيانات

1. عميل HTTP يميز JSON object/list/binary/multipart و`204 NoContent`، ويرفض خلطهما في parser واحد صامت. لكل endpoint توقيع DTO واختبار body/response.
2. `decimal` دقيق باستخدام `Decimal` مناسب في Dart أو تمثيل نصي/وحدات صحيحة لتجنب فقد الدقة؛ لا تُحسب ضرائب نهائية على الهاتف.
3. `DateTime` في UTC من الخادم؛ تفويض `endsAt`/رمز `expiresAt`/صلاحية الوصفة من وقت الخادم المرجعي؛ اعرض محليًا فقط.
4. خيارات `PaymentMethod` و`AgentRecordStatus` و`FieldTaskStatus` ليست محارف مجانية؛ استخدم قيم enum التي يدعمها JSON serializer والـ controller، واختبر عينة فعلية.
5. كل GET يمر ببوابة تفويض المستودع وscope المناسبة؛ ألغِ الاستعلام الجاري عند تغير `delegationId` وامسح كاش كل البيانات القابلة للتحديد.
6. عينة contract يجب حفظها آليًا في مشروع الاختبارات على staging، لا تُدرج بيانات شخصية أو رموز حقيقية في المستودع.
