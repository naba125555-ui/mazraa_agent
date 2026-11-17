# ملحق عقود HTTP — التجارة والمخزون والمالية والتغذية

مستخرج من كود السيرفر `4f8c947866cde3729b11697ec5c44ce41f516595`؛ تعريفات C# مرجع لجميع حقول الطلب، ونتائج Ok المختصرة دليل فقط وليست ضمانًا لشكل JSON. قيود التفويض والنسخ والنقد في [الخطة الرئيسية](00-master-plan.md). ممنوع حساب التسعير أو الرصيد أو الضريبة أو الفاتورة من جهة التطبيق كمرجع نهائي.


## AgentCommerceController — `/api/agent/commerce`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentCommerceController.cs)

### GET `/api/agent/commerce/inventory`
- إجراء: `Inventory`؛ معاملات/DTO: `int delegationId, int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Db.Inventories.AsNoTracking().Where(x => x.WarehouseId == g.WarehouseId && !x.IsDeleted && x.Id > afterId).OrderBy(x => x.Id).Take(100) .Select(x => new { x.Id, x.ProductVariantId, x.QuantityOnHand, x.ReservedQuantity, x.AvailableQuantity, x.AverageCost, batches = x.Batches.Select(b => new { b.Id, b.BatchNum …`.

### POST `/api/agent/commerce/documents`
- إجراء: `Document`؛ معاملات/DTO: `AgentDocumentInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, "agent.document", input, async () => { await core.GrantAsync(actor, input.DelegationId, (input.Purchase ? AgentCapability.Purchase : AgentCapability.Sell) | AgentCapability.Cash, ct); }, async () => await AgentCommerceEngine.Post(core, documents, actor, input, ct), ct)); }  …`.

### GET `/api/agent/commerce/documents`
- إجراء: `Documents`؛ معاملات/DTO: `int delegationId, int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Db.Documents.Where(x => x.WarehouseId == g.WarehouseId && x.Id > afterId).OrderBy(x => x.Id).Take(50).Select(x => new { x.Id, x.DocumentNumber, x.Type, x.TotalAmount, x.Currency, x.IsPosted, x.PostedAt }).ToListAsync(ct)); }  …`.

### POST `/api/agent/commerce/transfers`
- إجراء: `Transfer`؛ معاملات/DTO: `AgentTransferInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, "agent.transfer.dispatch", input, async () => { await core.GrantAsync(actor, input.DelegationId, AgentCapability.Transfer, ct); }, async () => { var g = await core.GrantAsync(actor, input.DelegationId, AgentCapability.Transfer, ct); if (g.WarehouseId == input.DestinationWarehouseI …`.

### POST `/api/agent/commerce/transfers/{id}/receive`
- إجراء: `Receive`؛ معاملات/DTO: `int id, TransferReceiveInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.transfer.receive:{id}", input, async () => { var g = await core.GrantAsync(actor, input.DelegationId, AgentCapability.Transfer, ct); if ((await core.RecordAsync(id, AgentRecordKind.Transfer, ct)).OtherWarehouseId != g.WarehouseId) throw AgentCore.Denied(); }, async () => { …`.

### GET `/api/agent/commerce/transfers`
- إجراء: `Transfers`؛ معاملات/DTO: `int delegationId, int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok((await core.Db.Set<AgentRecord>().Where(x => x.Kind == AgentRecordKind.Transfer && x.Id > afterId && (x.WarehouseId == g.WarehouseId || x.OtherWarehouseId == g.WarehouseId)).OrderBy(x => x.Id).Take(50).ToListAsync(ct)).Select(AgentCore.View<TransferData>)); }  …`.

### POST `/api/agent/commerce/stock-counts`
- إجراء: `Count`؛ معاملات/DTO: `StockCountInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, "agent.stock-count", input, async () => { await core.GrantAsync(actor, input.DelegationId, AgentCapability.StockCount, ct); }, async () => { var g = await core.GrantAsync(actor, input.DelegationId, AgentCapability.StockCount, ct); if (input.Lines is not { Length: > 0 and <= 100 }  …`.

### POST `/api/agent/commerce/stock-counts/{id}/review`
- إجراء: `ReviewCount`؛ معاملات/DTO: `int id, ReviewInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.count.review:{id}", input, () => core.ManageAsync(User, "agent.operations.review", row.WarehouseId, ct), async () => { AgentCore.Version(row.Version, input.Version); if (row.OwnerId == actor || row.Status != AgentRecordStatus.Pending) throw AgentCore.Denied(); var data = A …`.

### POST `/api/agent/commerce/shifts`
- إجراء: `OpenShift`؛ معاملات/DTO: `ShiftOpenInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, "agent.shift.open", input, async () => { await core.GrantAsync(actor, input.DelegationId, AgentCapability.Cash, ct); }, async () => { var g = await core.GrantAsync(actor, input.DelegationId, AgentCapability.Cash, ct); var box = await core.BoxAsync(g, ct); if (await core.Db.Set<Age …`.

### POST `/api/agent/commerce/shifts/{id}/close`
- إجراء: `CloseShift`؛ معاملات/DTO: `int id, ShiftCloseInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.shift.close:{id}", input, async () => { var r = await core.RecordAsync(id, AgentRecordKind.CashShift, ct); var g = await core.GrantAsync(actor, input.DelegationId, AgentCapability.Cash, ct); if (r.OwnerId != actor || r.RelatedId != g.CashBoxId) throw AgentCore.Denied(); }, …`.

### POST `/api/agent/commerce/shifts/{id}/review`
- إجراء: `ReviewShift`؛ معاملات/DTO: `int id, ReviewInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.shift.review:{id}", input, () => core.ManageAsync(User, "agent.operations.review", r.WarehouseId, ct), async () => { AgentCore.Version(r.Version, input.Version); if (r.OwnerId == actor || r.Status != AgentRecordStatus.Pending) throw AgentCore.Denied(); var d = AgentCore.Re …`.

### تعريفات الطلب/الاستجابة المصرّح بها هنا
- `AgentDocumentLine(int ProductVariantId, int? BatchId, decimal Quantity, decimal UnitCost, string? BatchNumber, DateTime? ExpiryDate)`
- `AgentDocumentInput(Guid RequestId, int DelegationId, bool Purchase, int PartyId, AgentDocumentLine[] Lines, PaymentMethod PaymentMethod = PaymentMethod.Cash, decimal? PaidAmount = null, decimal DiscountPercent = 0, int? QuoteId = null, string? BankReference = null, int? CampaignId = null)`
- `AgentTransferInput(Guid RequestId, int DelegationId, int DestinationWarehouseId, string Notes, AgentStockLine[] Lines)`
- `TransferLine(int ProductVariantId, int BatchId, decimal Sent, decimal Received, string BatchNumber, decimal UnitCost, DateTime? ExpiryDate, DateTime? ProductionDate, decimal Resolved = 0)`
- `TransferData(TransferLine[] Lines, string Notes)`
- `TransferReceiveInput(Guid RequestId, int DelegationId, int Version, AgentStockLine[] Lines)`
- `StockCountLine(int BatchId, decimal Counted)`
- `StockCountInput(Guid RequestId, int DelegationId, string Reason, StockCountLine[] Lines)`
- `CountLine(int BatchId, decimal Expected, decimal Counted, DateTime? BatchUpdatedAt = null, string? BatchRowVersion = null)`
- `CountData(CountLine[] Lines, string Reason)`
- `ReviewInput(Guid RequestId, int Version, bool Approve, string Notes)`
- `ShiftOpenInput(Guid RequestId, int DelegationId, decimal CountedOpening)`
- `ShiftCloseInput(Guid RequestId, int DelegationId, int Version, decimal CountedClosing, string Notes)`
- `ShiftData(int CashBoxId, string Currency, decimal Opening, DateTime OpenedAt, DateTime? ClosedAt, decimal? ExpectedClosing, decimal? CountedClosing, string? Notes, int? AdjustmentTransactionId = null)`


## AgentCommercialController — `/api/agent/commercial`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentCommercialController.cs)

### PUT `/api/agent/commercial/policies/{delegationId}`
- إجراء: `Policy`؛ معاملات/DTO: `int delegationId, CommercePolicyInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.commerce.policy:{delegationId}", input, () => core.ManageAsync(User, "agent.delegations.manage", g.WarehouseId, ct), async () => { if (actor == g.UserId || input.MaxDiscountPercent is < 0 or > 100) throw AgentCore.Denied(); AgentCore.Money(input.MaxCreditAmount); if (input …`.

### POST `/api/agent/commercial/quotes`
- إجراء: `Quote`؛ معاملات/DTO: `AgentDocumentInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, "agent.sale.quote", input, async () => { await core.GrantAsync(actor, input.DelegationId, input.Purchase ? AgentCapability.Purchase : AgentCapability.Sell, ct); }, async () => { var g = await core.GrantAsync(actor, input.DelegationId, input.Purchase ? AgentCapability.Purchase : Ag …`.

### GET `/api/agent/commercial/quotes/{id}`
- إجراء: `GetQuote`؛ معاملات/DTO: `int id, CancellationToken ct`.
- صلاحيات ظاهرة: `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(AgentCore.View<SaleQuoteData>(row)); }  …`.

### POST `/api/agent/commercial/quotes/{id}/accept`
- إجراء: `AcceptQuote`؛ معاملات/DTO: `int id, QuoteAcceptanceInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.sale.quote.accept:{id}", input, async () => { if ((await core.RecordAsync(id, AgentRecordKind.SaleQuote, ct)).CustomerId != actor) throw AgentCore.Denied(); }, async () => { var row = await core.RecordAsync(id, AgentRecordKind.SaleQuote, ct); AgentCore.Version(row.Version, …`.

### POST `/api/agent/commercial/quotes/{id}/pay-wallet`
- إجراء: `PayWallet`؛ معاملات/DTO: `int id, QuoteAcceptanceInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.sale.quote.wallet:{id}", input, async () => { if ((await core.RecordAsync(id, AgentRecordKind.SaleQuote, ct)).CustomerId != actor) throw AgentCore.Denied(); }, async () => { var row = await core.RecordAsync(id, AgentRecordKind.SaleQuote, ct); var data = AgentCore.Read<Sale …`.

### GET `/api/agent/commercial/documents/{id}/receipt`
- إجراء: `Receipt`؛ معاملات/DTO: `int id, int? delegationId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(new { d.Id, d.DocumentNumber, d.Type, d.Currency, d.TotalAmount, d.PaidAmount, d.RemainingAmount, d.IsPosted, items = d.Items!.Select(x => new { x.Id, x.ProductVariantId, x.Quantity, x.UnitPrice, x.Discount, x.Tax, x.Total, x.BatchNumber }) }); } } public sealed record CommercePolicyInput(Guid RequestId, decimal MaxDis …`.

### تعريفات الطلب/الاستجابة المصرّح بها هنا
- `CommercePolicyInput(Guid RequestId, decimal MaxDiscountPercent, decimal MaxCreditAmount, bool AllowBank, bool AllowWallet, int? CountryId, int? CityId, bool RecoverPurchaseTax = false)`
- `QuoteAcceptanceInput(Guid RequestId, int Version)`


## AgentFinanceController — `/api/agent/finance`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentFinanceController.cs)

### POST `/api/agent/finance/documents/{id}/settle`
- إجراء: `Settle`؛ معاملات/DTO: `int id, AgentSettlementInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.document.settle:{id}", input, async () => { await core.GrantAsync(actor, input.DelegationId, AgentCapability.Cash, ct); }, async () => { var g = await core.GrantAsync(actor, input.DelegationId, AgentCapability.Cash, ct); var d = await core.Db.Documents.SingleOrDefaultAsync …`.

### GET `/api/agent/finance/statements`
- إجراء: `Statement`؛ معاملات/DTO: `int delegationId, int partyId, bool supplier, int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(new { partyId, supplier, balance, currency = core.CatalogCurrency, transactions = await rows.Where(x => x.Id > afterId).OrderBy(x => x.Id).Take(100).Select(x => new { x.Id, x.DocumentId, x.Amount, x.Direction, x.TransactionType, x.CreatedAt }).ToListAsync(ct) }); }  …`.

### GET `/api/agent/finance/journals`
- إجراء: `Journals`؛ معاملات/DTO: `int delegationId, int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Db.JournalEntries.Where(x => x.JournalEntryId > afterId && ((x.ReferenceType != null && x.ReferenceType.StartsWith("Agent:") && x.ReferenceId.HasValue && recordIds.Contains(x.ReferenceId.Value)) || (x.ReferenceType == "Document" && x.ReferenceId.HasValue && docIds.Contains(x.ReferenceId.Value)))) .OrderBy(x  …`.

### تعريفات الطلب/الاستجابة المصرّح بها هنا
- `AgentSettlementInput(Guid RequestId, int DelegationId, decimal Amount, PaymentMethod PaymentMethod, string Notes, string? BankReference = null)`


## AgentRefundController — `/api/agent/finance/refunds`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentRefundController.cs)

### POST `/api/agent/finance/refunds`
- إجراء: `Request`؛ معاملات/DTO: `CustomerRefundInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, "agent.refund.request", input, async () => { await OwnReturn(input.ReturnDocumentId, actor, ct); }, async () => { var doc = await OwnReturn(input.ReturnDocumentId, actor, ct); var amount = AgentCore.Money(AgentCore.Quantity(input.Amount)); if (amount <= 0) throw AgentCore.Bad("Ref …`.

### POST `/api/agent/finance/refunds/{id}/pay`
- إجراء: `Pay`؛ معاملات/DTO: `int id, CustomerRefundPayInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.GrantAsync`، `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.refund.pay:{id}", input, Authorize, async () => { AgentCore.Version(row.Version, input.Version); var d = AgentCore.Read<CustomerRefundData>(row); if (row.Status != AgentRecordStatus.Pending) throw AgentCore.Conflict("Refund is already closed."); if (!input.Approve) { Agent …`.

### POST `/api/agent/finance/refunds/{id}/cancel`
- إجراء: `Cancel`؛ معاملات/DTO: `int id, RecordVersionInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.refund.cancel:{id}", input, async () => { if ((await core.RecordAsync(id, AgentRecordKind.CustomerRefund, ct)).CustomerId != actor) throw AgentCore.Denied(); }, async () => { var row = await core.RecordAsync(id, AgentRecordKind.CustomerRefund, ct); AgentCore.Version(row.Ve …`.

### GET `/api/agent/finance/refunds`
- إجراء: `List`؛ معاملات/DTO: `int? delegationId, int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(rows.Select(r => { var d = AgentCore.Read<CustomerRefundData>(r); return new { r.Id, r.Version, r.Status, r.CustomerId, d.ReturnDocumentId, d.Amount, d.Currency, d.Method, d.ExpiresAt, d.PaidBy }; })); } private async Task<Document> OwnReturn(int id, int customer, CancellationToken ct) => await core.Db.Documents.Single …`.

### تعريفات الطلب/الاستجابة المصرّح بها هنا
- `CustomerRefundData(int ReturnDocumentId, decimal Amount, PaymentMethod Method, string Currency, string? CodeHash, DateTime ExpiresAt, int Attempts, int? PaidBy, string? Notes)`
- `CustomerRefundInput(Guid RequestId, int ReturnDocumentId, decimal Amount, PaymentMethod Method)`
- `CustomerRefundPayInput(Guid RequestId, int DelegationId, int Version, bool Approve, string? Code, string Notes)`


## AgentReturnsController — `/api/agent/returns`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentReturnsController.cs)

### POST `/api/agent/returns`
- إجراء: `RequestReturn`؛ معاملات/DTO: `AgentReturnInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, "agent.return.request", input, async () => { await core.GrantAsync(actor, input.DelegationId, AgentCapability.Inventory, ct); }, async () => { var g = await core.GrantAsync(actor, input.DelegationId, AgentCapability.Inventory, ct); var d = await core.Db.Documents.Include(x => x.It …`.

### POST `/api/agent/returns/{id}/review`
- إجراء: `Review`؛ معاملات/DTO: `int id, AgentReturnReviewInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.return.review:{id}", input, () => core.ManageAsync(User, "documents.returns.create", row.WarehouseId, ct), async () => { AgentCore.Version(row.Version, input.Version); if (row.OwnerId == actor || row.Status != AgentRecordStatus.Pending) throw AgentCore.Denied(); var data = …`.

### GET `/api/agent/returns`
- إجراء: `List`؛ معاملات/DTO: `int delegationId, int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok((await core.Db.Set<AgentRecord>().Where(x => x.Kind == AgentRecordKind.ReturnRequest && x.WarehouseId == g.WarehouseId && x.Id > afterId).OrderBy(x => x.Id).Take(50).ToListAsync(ct)).Select(AgentCore.View<AgentReturnData>)); } } public sealed record AgentReturnLine(int OriginalItemId, decimal Quantity); public sealed r …`.

### تعريفات الطلب/الاستجابة المصرّح بها هنا
- `AgentReturnLine(int OriginalItemId, decimal Quantity)`
- `AgentReturnInput(Guid RequestId, int DelegationId, int OriginalDocumentId, AgentReturnLine[] Lines, string Reason)`
- `AgentReturnData(int DelegationId, int OriginalDocumentId, AgentReturnLine[] Lines, string Reason, int? ReturnDocumentId, string? ReviewNotes)`
- `AgentReturnReviewInput(Guid RequestId, int Version, bool Approve, bool ItemsReceived, decimal RefundAmount, string Notes)`


## AgentSupplyController — `/api/agent/supply`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentSupplyController.cs)

### POST `/api/agent/supply/requests`
- إجراء: `RequestSupply`؛ معاملات/DTO: `SupplyRequestInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, "agent.supply.request", input, async () => { await core.GrantAsync(actor, input.DelegationId, AgentCapability.Transfer, ct); }, async () => { var g = await core.GrantAsync(actor, input.DelegationId, AgentCapability.Transfer, ct); if (input.SourceWarehouseId == g.WarehouseId || !aw …`.

### GET `/api/agent/supply/requests`
- إجراء: `Requests`؛ معاملات/DTO: `int delegationId, int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok((await core.Db.Set<AgentRecord>().Where(x => x.Kind == AgentRecordKind.TransferRequest && x.OwnerId == actor && x.WarehouseId == g.WarehouseId && x.Id > afterId).OrderBy(x => x.Id).Take(50).ToListAsync(ct)).Select(AgentCore.View<SupplyRequestData>)); }  …`.

### GET `/api/agent/supply/review-queue`
- إجراء: `Queue`؛ معاملات/DTO: `int sourceWarehouseId, int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok((await core.Db.Set<AgentRecord>().Where(x => x.Kind == AgentRecordKind.TransferRequest && x.OtherWarehouseId == sourceWarehouseId && (x.Status == AgentRecordStatus.Pending || x.Status == AgentRecordStatus.Approved) && x.Id > afterId).OrderBy(x => x.Id).Take(50).ToListAsync(ct)).Select(AgentCore.View<SupplyRequestData>) …`.

### POST `/api/agent/supply/requests/{id}/review`
- إجراء: `Review`؛ معاملات/DTO: `int id, ReviewInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.supply.review:{id}", input, async () => { await core.ManageAsync(User, "stock_transfers.create", r.OtherWarehouseId, ct); await core.ManageAsync(User, "stock_transfers.create", r.WarehouseId, ct); }, async () => { AgentCore.Version(r.Version, input.Version); if (r.Status ! …`.

### POST `/api/agent/supply/requests/{id}/dispatch`
- إجراء: `Dispatch`؛ معاملات/DTO: `int id, SupplyDispatchInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.supply.dispatch:{id}", input, async () => { await core.ManageAsync(User, "stock_transfers.create", r.OtherWarehouseId, ct); await core.ManageAsync(User, "stock_transfers.create", r.WarehouseId, ct); }, async () => { AgentCore.Version(r.Version, input.Version); var data = A …`.

### POST `/api/agent/supply/transfers/{id}/exceptions`
- إجراء: `Exception`؛ معاملات/DTO: `int id, TransferExceptionInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.transfer.exception:{id}", input, async () => { var g = await core.GrantAsync(actor, input.DelegationId, AgentCapability.Transfer, ct); if ((await core.RecordAsync(id, AgentRecordKind.Transfer, ct)).OtherWarehouseId != g.WarehouseId) throw AgentCore.Denied(); }, async () => …`.

### POST `/api/agent/supply/exceptions/{id}/review`
- إجراء: `Resolve`؛ معاملات/DTO: `int id, TransferResolutionInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.transfer.exception.review:{id}", input, async () => { await core.ManageAsync(User, "agent.operations.review", r.WarehouseId, ct); await core.ManageAsync(User, "agent.operations.review", r.OtherWarehouseId, ct); }, async () => { AgentCore.Version(r.Version, input.Version);  …`.

### تعريفات الطلب/الاستجابة المصرّح بها هنا
- `SupplyRequestInput(Guid RequestId, int DelegationId, int SourceWarehouseId, RxOrderLine[] Lines, string Reason)`
- `SupplyRequestData(int DelegationId, RxOrderLine[] Lines, string Reason, int? ReviewedBy, string? ReviewNotes, int? TransferId)`
- `SupplyDispatchInput(Guid RequestId, int Version, AgentStockLine[] Batches, string Notes)`
- `TransferExceptionInput(Guid RequestId, int DelegationId, int Version, int BatchId, decimal Quantity, string Reason, string Notes)`
- `TransferExceptionData(int BatchId, decimal Quantity, string Reason, string Notes, string? ReviewNotes)`
- `TransferResolutionInput(Guid RequestId, int Version, bool Approve, bool ReturnReceived, string Notes)`


## AgentProcurementController — `/api/agent/procurement`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentProcurementController.cs)

### POST `/api/agent/procurement`
- إجراء: `Request`؛ معاملات/DTO: `ProcurementInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, "agent.purchase.request", input, async () => { await core.GrantAsync(actor, input.DelegationId, AgentCapability.Purchase, ct); }, async () => { var g = await core.GrantAsync(actor, input.DelegationId, AgentCapability.Purchase, ct); if (!await core.Db.Suppliers.AnyAsync(x => x.Id = …`.

### POST `/api/agent/procurement/{id}/review`
- إجراء: `Review`؛ معاملات/DTO: `int id, ReviewInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.purchase.review:{id}", input, () => core.ManageAsync(User, "documents.create", row.WarehouseId, ct), async () => { AgentCore.Version(row.Version, input.Version); if (row.Status != AgentRecordStatus.Pending || row.OwnerId == actor) throw AgentCore.Denied(); AgentCore.Update …`.

### POST `/api/agent/procurement/{id}/receive`
- إجراء: `Receive`؛ معاملات/DTO: `int id, ProcurementReceiveInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.purchase.receive:{id}", input, async () => { if (row.OwnerId != actor) throw AgentCore.Denied(); await core.GrantAsync(actor, data.DelegationId, AgentCapability.Purchase | AgentCapability.Cash, ct); }, async () => { AgentCore.Version(row.Version, input.Version); var d = in …`.

### GET `/api/agent/procurement`
- إجراء: `Mine`؛ معاملات/DTO: `int delegationId, int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok((await core.Db.Set<AgentRecord>().Where(x => x.Kind == AgentRecordKind.PurchaseRequest && x.OwnerId == actor && x.WarehouseId == g.WarehouseId && x.Id > afterId).OrderBy(x => x.Id).Take(50).ToListAsync(ct)).Select(AgentCore.View<ProcurementData>)); } }  …`.

### تعريفات الطلب/الاستجابة المصرّح بها هنا
- `ProcurementLine(int ProductVariantId, decimal Quantity, decimal Received, decimal UnitCost)`
- `ProcurementData(int DelegationId, int SupplierId, ProcurementLine[] Lines, string Reason, int? ReviewedBy, string? ReviewNotes, int[] DocumentIds)`
- `ProcurementInput(Guid RequestId, int DelegationId, int SupplierId, AgentDocumentLine[] Lines, string Reason)`
- `ProcurementReceiveInput(Guid RequestId, int Version, AgentDocumentInput Document, bool ItemsReceived)`


## AgentOrderFulfillmentController — `/api/agent/fulfillment`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentOrderFulfillmentController.cs)

### POST `/api/agent/fulfillment/orders/{id}/prepare`
- إجراء: `Prepare`؛ معاملات/DTO: `int id, AgentPrepareInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.order.prepare:{id}", input, async () => { await Authorized(id, actor, input.DelegationId, ct); }, async () => { var order = await core.Db.Orders.SingleAsync(x => x.Id == id, ct); if (order.Status is OrderStatus.Cancelled or OrderStatus.Delivered or OrderStatus.Refunded or  …`.

### POST `/api/agent/fulfillment/auction-orders/{id}/code`
- إجراء: `Code`؛ معاملات/DTO: `int id, RecordVersionInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.auction.handoff.code:{id}", input, Authorize, async () => { var row = await Allocation(id, ct); AgentCore.Version(row.Version, input.Version); var d = AgentCore.Read<AuctionAllocationData>(row); if (row.Status != AgentRecordStatus.Approved || !d.PreparedAt.HasValue || awai …`.

### POST `/api/agent/fulfillment/auction-orders/{id}/complete`
- إجراء: `Complete`؛ معاملات/DTO: `int id, AuctionHandoffInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`، `AgentClinical.Dispenser`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.auction.handoff:{id}", input, async () => { await Authorized(id, actor, input.DelegationId, ct); }, async () => { var row = await Allocation(id, ct); AgentCore.Version(row.Version, input.Version); var d = AgentCore.Read<AuctionAllocationData>(row); var order = await core.D …`.

### تعريفات الطلب/الاستجابة المصرّح بها هنا
- `AgentPrepareInput(Guid RequestId, int DelegationId)`
- `AuctionHandoffInput(Guid RequestId, int DelegationId, int Version, string Code, bool ItemsVerified)`
