# ملحق عقود HTTP — الميدان والحملات ونقاط الاستلام والمزادات والمقترحات

مستخرج من كود السيرفر `4f8c947866cde3729b11697ec5c44ce41f516595`؛ طلبات Records كما في C# وتعابير الاستجابة مختصرة وليست مخطط JSON كاملًا. المسارات المعتمدة للجهاز/العميل/المراجع قد تكون مختلفة عن صلاحيات الطبيب؛ اقرأ مسؤولية كل دور في الخطة. بعض مسارات السائق ليست مخصصة لتطبيق الوكيل.


## AgentFieldController — `/api/agent/field`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentFieldController.cs)

### GET `/api/agent/field/tasks`
- إجراء: `Tasks`؛ معاملات/DTO: `int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.VetAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Db.FieldTasks.AsNoTracking().Where(x => x.DoctorId == actor && x.Id > afterId).OrderBy(x => x.Id).Take(50) .Select(x => new { x.Id, x.Title, x.Description, x.TaskType, x.ScheduledDate, x.Priority, x.Status, x.LocationId, visits = x.Visits.Select(v => new { v.Id, v.Status, v.StartedAt, v.CompletedAt, v.Latitu …`.

### POST `/api/agent/field/tasks/{id}/state`
- إجراء: `TaskState`؛ معاملات/DTO: `int id, FieldStateInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.VetAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.field.state:{id}", input, async () => { await core.VetAsync(actor, ct); await TaskFor(id, actor, ct); }, async () => { var task = await TaskFor(id, actor, ct); if (task.Status != input.ExpectedStatus || !CanChangeTask(task.Status, input.Status)) throw AgentCore.Conflict("I …`.

### POST `/api/agent/field/tasks/{id}/visits`
- إجراء: `Visit`؛ معاملات/DTO: `int id, FieldVisitCreateInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.VetAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.field.visit:{id}", input, async () => { await core.VetAsync(actor, ct); await TaskFor(id, actor, ct); }, async () => { var task = await TaskFor(id, actor, ct); if (task.Status is not (FieldTaskStatus.Accepted or FieldTaskStatus.InProgress)) throw AgentCore.Conflict("Accept …`.

### POST `/api/agent/field/visits/{id}/state`
- إجراء: `VisitState`؛ معاملات/DTO: `int id, FieldVisitStateInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.VetAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.visit.state:{id}", input, async () => { await core.VetAsync(actor, ct); if (!await core.Db.FieldVisits.AnyAsync(x => x.Id == id && x.DoctorId == actor && x.FieldTask.DoctorId == actor, ct)) throw AgentCore.Denied(); }, async () => { var v = await core.Db.FieldVisits.Includ …`.

### POST `/api/agent/field/campaigns`
- إجراء: `Campaign`؛ معاملات/DTO: `CampaignInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`، `core.VetAsync`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, "agent.campaign.create", input, () => core.ManageAsync(User, "field_tasks.create", g.WarehouseId, ct), async () => { await core.VetAsync(g.UserId, ct); await core.GrantAsync(g.UserId, g.Id, AgentCapability.Dispense | AgentCapability.Inventory, ct); if (input.TargetAnimals is < 1 o …`.

### GET `/api/agent/field/campaigns`
- إجراء: `Campaigns`؛ معاملات/DTO: `int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.VetAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok((await core.Db.Set<AgentRecord>().Where(x => x.Kind == AgentRecordKind.Campaign && x.OwnerId == actor && x.Id > afterId).OrderBy(x => x.Id).Take(50).ToListAsync(ct)).Select(AgentCore.View<CampaignData>)); }  …`.

### POST `/api/agent/field/campaigns/{id}/state`
- إجراء: `CampaignState`؛ معاملات/DTO: `int id, CampaignStateInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.VetAsync`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.campaign.state:{id}", input, async () => { await core.VetAsync(actor, ct); if ((await core.RecordAsync(id, AgentRecordKind.Campaign, ct)).OwnerId != actor) throw AgentCore.Denied(); }, async () => { var r = await core.RecordAsync(id, AgentRecordKind.Campaign, ct); AgentCor …`.

### POST `/api/agent/field/campaigns/{id}/vaccinations`
- إجراء: `Vaccinate`؛ معاملات/DTO: `int id, VaccinationInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.VetAsync`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.vaccination:{id}", input, async () => { await core.VetAsync(actor, ct); if ((await core.RecordAsync(id, AgentRecordKind.Campaign, ct)).OwnerId != actor) throw AgentCore.Denied(); }, async () => { var campaign = await core.RecordAsync(id, AgentRecordKind.Campaign, ct); var  …`.

### GET `/api/agent/field/campaigns/{id}/report`
- إجراء: `Report`؛ معاملات/DTO: `int id, CancellationToken ct`.
- صلاحيات ظاهرة: `core.ManageAsync`، `core.VetAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(new { campaign = AgentCore.View<CampaignData>(c), animals = vaccines.Select(x => x.AnimalId).Distinct().Count(), doses = vaccines.Sum(x => x.Quantity), vaccinations = vaccines }); } public static bool CanChangeTask(FieldTaskStatus from, FieldTaskStatus to) => (from, to) is (FieldTaskStatus.Assigned, FieldTaskStatus.Acc …`.

### تعريفات الطلب/الاستجابة المصرّح بها هنا
- `FieldStateInput(Guid RequestId, FieldTaskStatus ExpectedStatus, FieldTaskStatus Status)`
- `FieldVisitCreateInput(Guid RequestId, decimal? Latitude, decimal? Longitude, string Notes)`
- `FieldVisitStateInput(Guid RequestId, FieldVisitStatus ExpectedStatus, FieldVisitStatus Status, decimal? Latitude, decimal? Longitude, string? Diagnosis, string? Findings, string? Treatment, string? Recommendations)`
- `CampaignInput(Guid RequestId, int DelegationId, string Name, string Village, decimal Latitude, decimal Longitude, DateTime ScheduledAt, int VaccineVariantId, int TargetAnimals)`
- `CampaignData(int DelegationId, int TaskId, string Name, string Village, decimal Latitude, decimal Longitude, int VaccineVariantId, int TargetAnimals, string? Report)`
- `CampaignStateInput(Guid RequestId, int Version, AgentRecordStatus Status, string Report)`
- `VaccinationInput(Guid RequestId, int AnimalId, int DispensationId, int BatchId, decimal Quantity, int DoseNumber, DateTime? NextDueAt, string Notes)`
- `VaccinationData(int CampaignId, int AnimalId, int DispensationId, int BatchId, decimal Quantity, int DoseNumber, DateTime AdministeredAt, DateTime? NextDueAt, string Notes)`


## AgentCampaignOperationsController — `/api/agent/field/campaigns`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentCampaignOperationsController.cs)

### PUT `/api/agent/field/campaigns/{id}/team`
- إجراء: `Team`؛ معاملات/DTO: `int id, CampaignTeamInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.campaign.team:{id}", input, () => core.ManageAsync(User, "field_tasks.edit", c.WarehouseId, ct), async () => { if (input.Members.Length > 30 || input.Members.Distinct().Count() != input.Members.Length || await core.Db.Users.CountAsync(x => input.Members.Contains(x.Id) && x …`.

### PUT `/api/agent/field/campaigns/{id}/authority`
- إجراء: `Authority`؛ معاملات/DTO: `int id, CampaignAuthorityInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.campaign.authority:{id}", input, () => core.ManageAsync(User, "vet.medicines.manage", c.WarehouseId, ct), async () => { if (actor == c.OwnerId || input.ExpiresAt <= DateTime.UtcNow || input.MinimumCelsius >= input.MaximumCelsius || input.MinimumCelsius < -100 || input.Maxi …`.

### POST `/api/agent/field/campaigns/{id}/stops`
- إجراء: `Stop`؛ معاملات/DTO: `int id, CampaignStopInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.campaign.stop:{id}", input, () => core.ManageAsync(User, "field_tasks.edit", c.WarehouseId, ct), async () => { if (input.Latitude is < -90 or > 90 || input.Longitude is < -180 or > 180) throw AgentCore.Bad("Invalid stop coordinates."); var row = core.Add(AgentRecordKind.Ca …`.

### POST `/api/agent/field/campaigns/{id}/stops/{stopId}/state`
- إجراء: `StopState`؛ معاملات/DTO: `int id, int stopId, CampaignStopStateInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.campaign.stop.state:{id}:{stopId}", input, async () => { await AgentCampaignStock.Member(core, id, actor, false, ct); }, async () => { var row = await core.RecordAsync(stopId, AgentRecordKind.CampaignStop, ct); if (row.RelatedId != id) throw AgentCore.Denied(); AgentCore.V …`.

### POST `/api/agent/field/campaigns/{id}/allocations`
- إجراء: `Allocate`؛ معاملات/DTO: `int id, CampaignAllocationInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.campaign.allocate:{id}", input, () => core.ManageAsync(User, "inventory_reservations.create", c.WarehouseId, ct), async () => { if (c.Status is not (AgentRecordStatus.Pending or AgentRecordStatus.Active) || input.Lines is not { Length: > 0 and <= 100 } || input.Lines.Selec …`.

### POST `/api/agent/field/campaigns/{id}/administrations`
- إجراء: `Administration`؛ معاملات/DTO: `int id, CampaignAdministrationInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.VetAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.campaign.administration:{id}", input, async () => { await AgentCampaignStock.Member(core, id, actor, input.Outcome == "administered", ct); }, async () => { var c = await AgentCampaignStock.Member(core, id, actor, input.Outcome == "administered", ct); if (c.Status != AgentR …`.

### POST `/api/agent/field/campaigns/{id}/outcomes/{outcomeId}/review`
- إجراء: `ReviewOutcome`؛ معاملات/DTO: `int id, int outcomeId, ReviewInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.campaign.outcome.review:{outcomeId}", input, () => core.ManageAsync(User, "agent.operations.review", c.WarehouseId, ct), async () => { var row = await core.RecordAsync(outcomeId, AgentRecordKind.CampaignOutcome, ct); AgentCore.Version(row.Version, input.Version); var d = A …`.

### POST `/api/agent/field/campaigns/{id}/temperatures`
- إجراء: `Temperature`؛ معاملات/DTO: `int id, CampaignTemperatureInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.campaign.temperature:{id}", input, async () => { await AgentCampaignStock.Member(core, id, actor, false, ct); }, async () => { var c = await AgentCampaignStock.Member(core, id, actor, false, ct); if (input.Celsius is < -100 or > 100 || input.CapturedAt > DateTime.UtcNow.Ad …`.

### GET `/api/agent/field/campaigns/{id}/reconciliation`
- إجراء: `Reconciliation`؛ معاملات/DTO: `int id, CancellationToken ct`.
- صلاحيات ظاهرة: قد تكون في خدمات مساعدة؛ افحص المصدر.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(new { c.Id, c.Status, allocations = records.Where(x => x.Kind == AgentRecordKind.CampaignAllocation).Select(AgentCore.View<CampaignAllocationData>), outcomes = records.Where(x => x.Kind == AgentRecordKind.CampaignOutcome).Select(r => { var d = AgentCore.Read<CampaignOutcomeData>(r); return new { r.Id, r.Version, r.Stat …`.

### POST `/api/agent/field/campaigns/{id}/reconciliation`
- إجراء: `Close`؛ معاملات/DTO: `int id, ReviewInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.campaign.reconcile:{id}", input, () => core.ManageAsync(User, "agent.operations.review", c.WarehouseId, ct), async () => { AgentCore.Version(c.Version, input.Version); if (actor == c.OwnerId || c.Status != AgentRecordStatus.Active) throw AgentCore.Denied(); var stocks = aw …`.

### تعريفات الطلب/الاستجابة المصرّح بها هنا
- `CampaignTeamInput(Guid RequestId, int[] Members)`
- `CampaignAuthorityInput(Guid RequestId, string Reference, bool AllowGroups, bool AllowFree, decimal MinimumCelsius, decimal MaximumCelsius, DateTime ExpiresAt, bool PrescriptionExemption = false)`
- `CampaignStopInput(Guid RequestId, string Name, decimal Latitude, decimal Longitude, DateTime ScheduledAt, string Notes)`
- `CampaignStopStateInput(Guid RequestId, int Version, AgentRecordStatus Status, string Notes)`
- `CampaignAllocationInput(Guid RequestId, AgentStockLine[] Lines, string Notes)`
- `CampaignAdministrationInput(Guid RequestId, string Outcome, int? AnimalId, string? Group, int AnimalCount, int? StopId, int? BatchId, decimal Quantity, int DoseNumber, DateTime CapturedAt, DateTime? NextDueAt, decimal? Latitude, decimal? Longitude, string Notes, int? PrescriptionId = null)`
- `CampaignTemperatureInput(Guid RequestId, int BatchId, decimal Celsius, DateTime CapturedAt, string Notes)`


## AgentMarketplaceController — `/api/agent/marketplace`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentMarketplaceController.cs)

### POST `/api/agent/marketplace/auctions`
- إجراء: `CreateAuction`؛ معاملات/DTO: `AgentAuctionInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, "agent.auction.create", input, async () => { await core.GrantAsync(actor, input.DelegationId, AgentCapability.Auction, ct); }, async () => { var g = await core.GrantAsync(actor, input.DelegationId, AgentCapability.Auction, ct); var a = new Auction { CreatedByUserId = actor, Status …`.

### PUT `/api/agent/marketplace/auctions/{id}`
- إجراء: `EditAuction`؛ معاملات/DTO: `int id, AgentAuctionEditInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.auction.edit:{id}", input, async () => { await OwnAuction(id, actor, ct); await core.GrantAsync(actor, input.Auction.DelegationId, AgentCapability.Auction, ct); }, async () => { var r = await OwnAuction(id, actor, ct); AgentCore.Version(r.Version, input.Version); var d = A …`.

### POST `/api/agent/marketplace/auctions/{id}/submit`
- إجراء: `SubmitAuction`؛ معاملات/DTO: `int id, RecordVersionInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.auction.submit:{id}", input, async () => { var r = await OwnAuction(id, actor, ct); await core.GrantAsync(actor, AgentCore.Read<AuctionReviewData>(r).DelegationId, AgentCapability.Auction, ct); }, async () => { var r = await OwnAuction(id, actor, ct); AgentCore.Version(r.V …`.

### POST `/api/agent/marketplace/auctions/{id}/review`
- إجراء: `ReviewAuction`؛ معاملات/DTO: `int id, ProposalReviewInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.auction.review:{id}", input, () => core.ManageAsync(User, "agent.operations.review", r.WarehouseId, ct), async () => { AgentCore.Version(r.Version, input.Version); if (r.OwnerId == actor || r.Status != AgentRecordStatus.Pending || input.Status is not (AgentRecordStatus.App …`.

### POST `/api/agent/marketplace/auctions/{id}/publish`
- إجراء: `Publish`؛ معاملات/DTO: `int id, RecordVersionInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.auction.publish:{id}", input, async () => { var r = await OwnAuction(id, actor, ct); await core.GrantAsync(actor, AgentCore.Read<AuctionReviewData>(r).DelegationId, AgentCapability.Auction, ct); }, async () => { var r = await OwnAuction(id, actor, ct); AgentCore.Version(r. …`.

### POST `/api/agent/marketplace/auctions/{id}/cancel`
- إجراء: `CancelAuction`؛ معاملات/DTO: `int id, AuctionCancelInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.auction.cancel:{id}", input, async () => { var r = await OwnAuction(id, actor, ct); await core.GrantAsync(actor, AgentCore.Read<AuctionReviewData>(r).DelegationId, AgentCapability.Auction, ct); }, async () => { var r = await OwnAuction(id, actor, ct); AgentCore.Version(r.V …`.

### GET `/api/agent/marketplace/auctions`
- إجراء: `Auctions`؛ معاملات/DTO: `int delegationId, int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(new { reviews = rows.Select(AgentCore.View<AuctionReviewData>), auctions = await core.Db.Auctions.Where(x => ids.Contains(x.Id)).Select(x => new { x.Id, x.Title, x.Description, x.Terms, x.Status, x.StartAt, x.EndAt, x.GuaranteeAmount, items = x.Items.Select(i => new { i.Id, i.AnimalId, i.ProductVariantId, i.StartPrice, …`.

### GET `/api/agent/marketplace/auctions/{id}/fulfillment`
- إجراء: `Fulfillment`؛ معاملات/DTO: `int id, CancellationToken ct`.
- صلاحيات ظاهرة: `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Db.AuctionWinners.Where(x => x.AuctionItem!.AuctionId == id).Select(x => new { x.AuctionItemId, x.FinalPrice, x.Status, x.PaymentDueAt, x.PaidAt, x.OrderId, orderStatus = x.Order != null ? x.Order.Status : null, paymentStatus = x.Order != null && x.Order.Payment != null ? (PaymentStatus?)x.Order.Payment.Stat …`.

### POST `/api/agent/marketplace/proposals`
- إجراء: `Propose`؛ معاملات/DTO: `ProposalInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, "agent.proposal", input, async () => { await core.GrantAsync(actor, input.DelegationId, AgentCapability.Inventory, ct); }, async () => { var g = await core.GrantAsync(actor, input.DelegationId, AgentCapability.Inventory, ct); if (input.Kind is not ("product" or "purchase" or "impr …`.

### GET `/api/agent/marketplace/proposals`
- إجراء: `Proposals`؛ معاملات/DTO: `int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: قد تكون في خدمات مساعدة؛ افحص المصدر.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok((await core.Db.Set<AgentRecord>().Where(x => x.Kind == AgentRecordKind.Proposal && x.OwnerId == actor && x.Id > afterId).OrderBy(x => x.Id).Take(50).ToListAsync(ct)).Select(AgentCore.View<ProposalData>)); }  …`.

### POST `/api/agent/marketplace/proposals/{id}/revise`
- إجراء: `Revise`؛ معاملات/DTO: `int id, ProposalReviseInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.proposal.revise:{id}", input, async () => { var r = await core.RecordAsync(id, AgentRecordKind.Proposal, ct); var g = await core.GrantAsync(actor, input.DelegationId, AgentCapability.Inventory, ct); if (r.OwnerId != actor || r.WarehouseId != g.WarehouseId) throw AgentCore. …`.

### POST `/api/agent/marketplace/proposals/{id}/review`
- إجراء: `ReviewProposal`؛ معاملات/DTO: `int id, ProposalReviewInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.proposal.review:{id}", input, () => core.ManageAsync(User, "agent.proposals.review", r.WarehouseId, ct), async () => { AgentCore.Version(r.Version, input.Version); if (r.OwnerId == actor || r.Status != AgentRecordStatus.Pending || input.Status is not (AgentRecordStatus.App …`.

### تعريفات الطلب/الاستجابة المصرّح بها هنا
- `AgentAuctionItemInput(int? AnimalId, int? ProductVariantId, decimal StartPrice, decimal? ReservePrice, decimal MinBidIncrement)`
- `AgentAuctionInput(Guid RequestId, int DelegationId, string Title, string Description, string Terms, DateTime StartAt, DateTime EndAt, decimal GuaranteeAmount, AgentAuctionItemInput[] Items, int[] PhotoMediaIds)`
- `AgentAuctionEditInput(Guid RequestId, int Version, AgentAuctionInput Auction)`
- `AuctionReviewData(int DelegationId, int AuctionId, int[] PhotoMediaIds, string? SubmittedHash, int? ReviewedBy, string? Notes)`
- `ProposalInput(Guid RequestId, int DelegationId, string Kind, string Title, string Description, int? SupplierId = null, decimal? EstimatedCost = null, string? Currency = null, int[]? MediaIds = null)`
- `ProposalData(string Kind, string Title, string Description, string? Notes, int? LinkedEntityId, int? ReviewedBy, DateTime? ReviewedAt, int? SupplierId = null, decimal? EstimatedCost = null, string? Currency = null, int[]? MediaIds = null)`
- `ProposalReviseInput(Guid RequestId, int DelegationId, int Version, string Title, string Description, int? SupplierId = null, decimal? EstimatedCost = null, string? Currency = null, int[]? MediaIds = null)`
- `ProposalReviewInput(Guid RequestId, int Version, AgentRecordStatus Status, string Notes, int? LinkedEntityId)`
- `AuctionCancelInput(Guid RequestId, int Version, string Reason)`


## AgentPickupController — `/api/agent/pickup`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentPickupController.cs)

### POST `/api/agent/pickup/points`
- إجراء: `Point`؛ معاملات/DTO: `PickupPointInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, "agent.pickup.point", input, () => core.ManageAsync(User, "agent.operations.review", grant.WarehouseId, ct), async () => { await core.GrantAsync(grant.UserId, grant.Id, AgentCapability.Pickup, ct); if (input.Latitude is < -90 or > 90 || input.Longitude is < -180 or > 180 || input. …`.

### GET `/api/agent/pickup/points`
- إجراء: `Points`؛ معاملات/DTO: `int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: قد تكون في خدمات مساعدة؛ افحص المصدر.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(result); }  …`.

### POST `/api/agent/pickup/points/{id}/deactivate`
- إجراء: `Deactivate`؛ معاملات/DTO: `int id, RecordVersionInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.pickup.deactivate:{id}", input, () => core.ManageAsync(User, "agent.operations.review", point.WarehouseId, ct), async () => { AgentCore.Version(point.Version, input.Version); if (await core.Db.Set<AgentRecord>().AnyAsync(x => x.Kind == AgentRecordKind.Pickup && x.RelatedId …`.

### POST `/api/agent/pickup/points/{id}/reassign`
- إجراء: `Reassign`؛ معاملات/DTO: `int id, PickupReassignInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.ManageAsync`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.pickup.reassign:{id}", input, () => core.ManageAsync(User, "agent.operations.review", point.WarehouseId, ct), async () => { AgentCore.Version(point.Version, input.Version); var grant = await core.Db.Set<AgentDelegation>().SingleOrDefaultAsync(x => x.Id == input.DelegationI …`.

### POST `/api/agent/pickup/points/{id}/quote`
- إجراء: `Quote`؛ معاملات/DTO: `int id, PickupQuoteInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.pickup.quote:{id}", input, () => Task.CompletedTask, async () => { var point = await core.RecordAsync(id, AgentRecordKind.PickupPoint, ct); var data = AgentCore.Read<PickupPointData>(point); if (!await PointEnabled(point, data, ct)) throw AgentCore.Conflict("Pickup point u …`.

### GET `/api/agent/pickup/requests`
- إجراء: `Requests`؛ معاملات/DTO: `int? delegationId, int afterId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(result); }  …`.

### POST `/api/agent/pickup/requests/{id}/cancel`
- إجراء: `Cancel`؛ معاملات/DTO: `int id, RecordVersionInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.pickup.cancel:{id}", input, async () => { if ((await core.RecordAsync(id, AgentRecordKind.Pickup, ct)).CustomerId != actor) throw AgentCore.Denied(); }, async () => { var r = await core.RecordAsync(id, AgentRecordKind.Pickup, ct); AgentCore.Version(r.Version, input.Version …`.

### POST `/api/agent/pickup/requests/{id}/custody`
- إجراء: `Custody`؛ معاملات/DTO: `int id, PickupCustodyInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.pickup.custody:{id}", input, async () => await Custodian(id, actor, input.DelegationId, ct), async () => { var r = await core.RecordAsync(id, AgentRecordKind.Pickup, ct); AgentCore.Version(r.Version, input.Version); var d = AgentCore.Read<PickupData>(r); if (r.Status != Ag …`.

### POST `/api/agent/pickup/requests/{id}/code`
- إجراء: `Code`؛ معاملات/DTO: `int id, RecordVersionInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.pickup.code:{id}", input, async () => { await Recipient(id, actor, ct); }, async () => { var r = await core.RecordAsync(id, AgentRecordKind.Pickup, ct); AgentCore.Version(r.Version, input.Version); var d = AgentCore.Read<PickupData>(r); if (r.Status != AgentRecordStatus.Ac …`.

### POST `/api/agent/pickup/requests/{id}/complete`
- إجراء: `Complete`؛ معاملات/DTO: `int id, PickupCompleteInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.pickup.complete:{id}", input, async () => await Custodian(id, actor, input.DelegationId, ct), async () => { var r = await core.RecordAsync(id, AgentRecordKind.Pickup, ct); AgentCore.Version(r.Version, input.Version); var d = AgentCore.Read<PickupData>(r); if (r.Status != A …`.

### تعريفات الطلب/الاستجابة المصرّح بها هنا
- `PickupPointInput(Guid RequestId, int DelegationId, string Name, string Address, decimal Latitude, decimal Longitude, string OpeningHours, int Capacity)`
- `PickupPointData(int DelegationId, string Name, string Address, decimal Latitude, decimal Longitude, string OpeningHours, int Capacity)`
- `PickupQuoteInput(Guid RequestId, int AddressId, bool TermsAccepted)`
- `PickupData(Guid QuoteId, int? OrderId, DateTime? ReadyAt, string? TokenHash, DateTime? TokenExpiresAt, int Attempts, DateTime? CompletedAt)`
- `PickupCustodyInput(Guid RequestId, int DelegationId, int Version, bool ItemsVerified, string? Shelf = null, DateTime? Deadline = null)`
- `PickupCompleteInput(Guid RequestId, int DelegationId, int Version, string Code, decimal CashCollected)`
- `PickupReassignInput(Guid RequestId, int Version, int DelegationId, string Reason)`


## AgentPickupMovementController — `/api/agent/pickup`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentPickupMovementController.cs)

### POST `/api/agent/pickup/points/{id}/incoming-quotes`
- إجراء: `Quotes`؛ معاملات/DTO: `int id, IncomingPickupInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.pickup.incoming:{id}", input, () => Task.CompletedTask, async () => { var point = await core.RecordAsync(id, AgentRecordKind.PickupPoint, ct); var p = AgentCore.Read<PickupPointData>(point); await core.GrantAsync(point.OwnerId, p.DelegationId, AgentCapability.Pickup, ct);  …`.

### POST `/api/agent/pickup/requests/{id}/driver-code`
- إجراء: `DriverCode`؛ معاملات/DTO: `int id, PickupShelfInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.pickup.driver-code:{id}", input, async () => { await Custodian(id, actor, input.DelegationId, ct); }, async () => { var pickup = await Custodian(id, actor, input.DelegationId, ct); var move = await Movement(core, id, ct); AgentCore.Version(move.Version, input.Version); if  …`.

### POST `/api/agent/pickup/requests/{id}/driver-handoff`
- إجراء: `DriverHandoff`؛ معاملات/DTO: `int id, PickupDriverInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.pickup.driver-handoff:{id}", input, Authorize, async () => { var pickup = await core.RecordAsync(id, AgentRecordKind.Pickup, ct); var move = await Movement(core, id, ct); var data = AgentCore.Read<PickupMovementData>(move); AgentCore.Version(move.Version, input.Version); v …`.

### GET `/api/agent/pickup/requests/{id}/custody-details`
- إجراء: `Details`؛ معاملات/DTO: `int id, int delegationId, CancellationToken ct`.
- صلاحيات ظاهرة: قد تكون في خدمات مساعدة؛ افحص المصدر.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(new { row.Id, row.Version, row.Status, d.SourceWarehouseId, d.Shelf, d.Deadline, d.ShipmentId }); }  …`.

### POST `/api/agent/pickup/requests/{id}/shelf`
- إجراء: `Shelf`؛ معاملات/DTO: `int id, PickupShelfInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.pickup.shelf:{id}", input, async () => { await Custodian(id, actor, input.DelegationId, ct); }, async () => { var row = await Movement(core, id, ct); AgentCore.Version(row.Version, input.Version); if (row.Status != AgentRecordStatus.Active || input.Deadline <= DateTime.Utc …`.

### POST `/api/agent/pickup/requests/{id}/proxy`
- إجراء: `Proxy`؛ معاملات/DTO: `int id, PickupProxyInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.pickup.proxy:{id}", input, async () => { if ((await core.RecordAsync(id, AgentRecordKind.Pickup, ct)).CustomerId != actor) throw AgentCore.Denied(); }, async () => { if (input.ExpiresAt <= DateTime.UtcNow || input.ExpiresAt > DateTime.UtcNow.AddDays(2) || !await core.Db.Us …`.

### POST `/api/agent/pickup/requests/{id}/proxy/revoke`
- إجراء: `RevokeProxy`؛ معاملات/DTO: `int id, RecordVersionInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.pickup.proxy.revoke:{id}", input, async () => { if ((await core.RecordAsync(id, AgentRecordKind.Pickup, ct)).CustomerId != actor) throw AgentCore.Denied(); }, async () => { var pickup = await core.RecordAsync(id, AgentRecordKind.Pickup, ct); AgentCore.Version(pickup.Versio …`.

### POST `/api/agent/pickup/requests/{id}/exceptions`
- إجراء: `Exception`؛ معاملات/DTO: `int id, PickupIssueInput input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.Run`، `core.GrantAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.pickup.exception:{id}", input, async () => { await Custodian(id, actor, input.DelegationId, ct); }, async () => { var pickup = await Custodian(id, actor, input.DelegationId, ct); AgentCore.Version(pickup.Version, input.Version); if (pickup.Status != AgentRecordStatus.Activ …`.

### تعريفات الطلب/الاستجابة المصرّح بها هنا
- `PickupMovementData(int SourceWarehouseId, string Shelf, DateTime? Deadline, string? DriverTokenHash, DateTime? DriverTokenExpires, int Attempts = 0, int? ShipmentId = null)`
- `IncomingPickupInput(Guid RequestId, int AddressId, int SourceWarehouseId, bool TermsAccepted, DeliveryCartLine[] Items)`
- `PickupShelfInput(Guid RequestId, int DelegationId, int Version, string Shelf, DateTime Deadline)`
- `PickupDriverInput(Guid RequestId, int Version, int ShipmentId, string Code, bool ItemsVerified)`
- `PickupProxyData(int AuthorizedUserId, DateTime ExpiresAt)`
- `PickupProxyInput(Guid RequestId, int AuthorizedUserId, DateTime ExpiresAt)`
- `PickupIssueInput(Guid RequestId, int DelegationId, int Version, string Reason, string Notes)`


## AgentPickupExceptionController — `/api/agent/pickup/exceptions`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentPickupExceptionController.cs)

### POST `/api/agent/pickup/exceptions/{id}/review`
- إجراء: `Review`؛ معاملات/DTO: `int id, PickupExceptionReview input, CancellationToken ct`.
- صلاحيات ظاهرة: `core.ManageAsync`، `core.Run`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(await core.Run(actor, input.RequestId, $"agent.pickup.exception.review:{id}", input, Authorize, async () => { AgentCore.Version(issue.Version, input.Version); if (issue.OwnerId == actor || issue.Status != AgentRecordStatus.Pending || pickup.Status != AgentRecordStatus.NeedsChanges || order.Status == OrderStatus.Deliver …`.

### تعريفات الطلب/الاستجابة المصرّح بها هنا
- `PickupExceptionReview(Guid RequestId, int Version, bool ReturnReceivedAtSource, bool ResumeCustody, string Notes)`


## AgentDiagnosticsController — `/api/agent/administration/diagnostics`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentDiagnosticsController.cs)

### GET `/api/agent/administration/diagnostics`
- إجراء: `Get`؛ معاملات/DTO: `int warehouseId, CancellationToken ct`.
- صلاحيات ظاهرة: `core.ManageAsync`.
- دليل الاستجابة من التنفيذ (ليس JSON Schema): `return Ok(new { contractVersion = 2, serverTime = now, notifications = new { pending = await outbox.CountAsync(x => x.SentAt == null && x.FailedAt == null, ct), failed = await outbox.CountAsync(x => x.FailedAt != null, ct), oldestPendingAt = await outbox.Where(x => x.SentAt == null && x.FailedAt == null).MinAsync(x => (DateTime? …`.

### تعريفات الطلب/الاستجابة المصرّح بها هنا
لا توجد سجلات عامة في الملف.
