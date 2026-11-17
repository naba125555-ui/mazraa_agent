# ملحق عقود HTTP — الهوية والطب والمزامنة

> توثيق تحليلي مولّد من ملفات السيرفر عند commit `4f8c947866cde3729b11697ec5c44ce41f516595` بتاريخ 2026-11-18؛ لا يُعد مواصفة OpenAPI منشورة. توقيعات DTO/Record مرجعية؛ يجب الرجوع إلى الكود لمعاني القيم والحالات، لأن استجابة JSON قد تُعاد عبر خدمات داخلية أو أنواع غير مضمنة. لا يوجد تنفيذ أو تغيير في السيرفر.

**مبدأ مفاتيح JSON:** ASP.NET Core يستخدم تسميات camelCase افتراضيًا لمعظم الاستجابات؛ أسماء PascalCase المعروضة مأخوذة من تعريفات C#، وليست بديلًا عن اختبار عقد تسلسلي. **النتائج** قد تشمل `AgentCore.View<T>`: `id, kind, status, version, ownerId, customerId, warehouseId, otherWarehouseId, relatedId, createdAt, updatedAt, details`.


## AgentMobileController — `/api/agent/mobile`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentMobileController.cs)

### GET `/api/agent/mobile/bootstrap`
- المعالج: `Bootstrap`؛ معاملات/DTO: `CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.GrantAsync`، `AgentClinical.Dispenser`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(new { dispensingApproved = dispensingJurisdiction != null, dispensingJurisdiction, serverTime = now, contractVersion = 2, currency = core.CatalogCurrency, doctorApproved = profile is { IsApproved: true } && profile.LicenseExpiresAt > now, delegations = active.Select(x => new { x.Id, x.StoreId, x.WarehouseId, x.CashBoxI …`.

### GET `/api/agent/mobile/changes`
- المعالج: `Changes`؛ معاملات/DTO: `DateTime? since, int afterId, CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(new { serverTime = DateTime.UtcNow, changes = allowed, next = candidates.Count == 0 ? null : new { since = candidates[^1].UpdatedAt, afterId = candidates[^1].Id }, hasMore = candidates.Count == 100 }); }  …`.

### POST `/api/agent/mobile/sync/clinical-notes`
- المعالج: `Sync`؛ معاملات/DTO: `MobileNoteOperation[] operations, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `AgentClinical.CaseAsync`، `core.VetAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(new { results }); }  …`.

### GET `/api/agent/mobile/requests/{requestId}`
- المعالج: `Receipt`؛ معاملات/DTO: `Guid requestId, CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `راجع تنفيذ الدالة؛ قد تكون الاستجابة غير Ok`.

### POST `/api/agent/mobile/records/{id}/files`
- المعالج: `Upload`؛ معاملات/DTO: `int id, [FromForm] Guid requestId, IFormFile file, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, requestId, $"agent.file:{id}", new { id, name, hash = Convert.ToHexString(SHA256.HashData(bytes)) }, () => AgentRecordAccess.Read(core, record, actor, ct), async () => { if (await core.Db.Set<AgentPrivateFile>().CountAsync(x => x.RecordId == id, ct) >= 12) throw AgentCore.Conflict("Attachment limi …`.

### GET `/api/agent/mobile/records/{id}/files`
- المعالج: `Files`؛ معاملات/DTO: `int id, CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Db.Set<AgentPrivateFile>().Where(x => x.RecordId == id).Select(x => new { x.Id, x.Name, x.ContentType, x.CreatedAt }).ToListAsync(ct)); }  …`.

### GET `/api/agent/mobile/files/{id}`
- المعالج: `Download`؛ معاملات/DTO: `int id, CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return File(file.Content, file.ContentType, file.Name); } }  …`.

### تعريفات حقول Records في الملف
- `MobileNoteOperation(Guid RequestId, int CaseId, string Body, bool SharedWithCustomer, int? AmendsId)`


## AgentProfilesController — `/api/agent`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentProfilesController.cs)

### GET `/api/agent/me`
- المعالج: `Me`؛ معاملات/DTO: `CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(new { user = await core.Db.Users.Where(x => x.Id == actor).Select(x => new { x.Id, x.Name, x.UserType, x.ProfileImageUrl }).SingleAsync(ct), profile, canPractice = profile is { IsApproved: true } && profile.LicenseExpiresAt > DateTime.UtcNow && await core.Db.Users.AnyAsync(x => x.Id == actor && x.UserType == UserType.D …`.

### PATCH `/api/agent/availability`
- المعالج: `Availability`؛ معاملات/DTO: `AvailabilityInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.VetAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(new { p.IsAvailable }); }  …`.

### GET `/api/agent/administration/veterinarians`
- المعالج: `Veterinarians`؛ معاملات/DTO: `int? userId, string? search, int afterId, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.ManageAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(new { Items = page.Take(50), NextAfterId = page.Count > 50 ? (int?)page[49].Id : null }); }  …`.

### GET `/api/agent/administration/delegations`
- المعالج: `Delegations`؛ معاملات/DTO: `int? warehouseId, string? search, int afterId, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.ManageAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(new { Warehouses = warehouses }); var location = warehouses.Find(w => w.Id == selected) ?? throw AgentCore.Missing(); var cashBoxes = await core.Db.CashBoxes.AsNoTracking() .Where(b => b.StoreId == location.StoreId && b.IsActive && b.Type == FinancialAccountType.Cash) .OrderBy(b => b.Name).ThenBy(b => b.Id).Select(b => …`.

### PUT `/api/agent/administration/veterinarians/{userId}`
- المعالج: `Profile`؛ معاملات/DTO: `int userId, ProfileInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `core.ManageAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.profile:{userId}", input, () => core.ManageAsync(User, "vet.profiles.manage", ct: ct), async () => { if (actor == userId) throw AgentCore.Denied(); if (!await core.Db.Users.AnyAsync(x => x.Id == userId && x.UserType == UserType.Doctor && x.IsActive && x.DeletedAt == null, ct …`.

### POST `/api/agent/administration/delegations`
- المعالج: `Delegate`؛ معاملات/DTO: `DelegationInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `core.ManageAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, "agent.delegation", input, () => core.ManageAsync(User, "agent.delegations.manage", input.WarehouseId, ct), async () => { if (actor == input.UserId || !await core.Db.Users.AnyAsync(x => x.Id == input.UserId && x.IsActive && x.DeletedAt == null && (x.UserType == UserType.Doctor ||  …`.

### DELETE `/api/agent/administration/delegations/{id}`
- المعالج: `Revoke`؛ معاملات/DTO: `int id, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.ManageAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return NoContent(); } } public sealed record AvailabilityInput(bool Available); public sealed record ProfileInput(Guid RequestId, string LicenseNumber, string Jurisdiction, string Specialty, DateTime ExpiresAt, bool Approved); public sealed record DelegationInput(Guid RequestId, int UserId, int WarehouseId, int? CashBoxId, Agent …`.

### تعريفات حقول Records في الملف
- `AvailabilityInput(bool Available)`
- `ProfileInput(Guid RequestId, string LicenseNumber, string Jurisdiction, string Specialty, DateTime ExpiresAt, bool Approved)`
- `DelegationInput(Guid RequestId, int UserId, int WarehouseId, int? CashBoxId, AgentCapability Capabilities, DateTime? EndsAt)`


## AgentOperationsController — `/api/agent/operations`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentOperationsController.cs)

### GET `/api/agent/operations/home`
- المعالج: `Home`؛ معاملات/DTO: `CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(new { serverTime = DateTime.UtcNow, contractVersion = 1, catalogCurrency = core.CatalogCurrency, permissions = await permissions.GetEffectivePermissionsAsync(User, ct), caseOffers = licensed ? await core.Db.Set<VetCase>().CountAsync(x => x.DoctorUserId == actor && x.Status == VetCaseStatus.Assigned, ct) : 0, activeCase …`.

### GET `/api/agent/operations/review-queue`
- المعالج: `Queue`؛ معاملات/DTO: `int warehouseId, AgentRecordKind kind, int afterId, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.ManageAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(rows.Select(x => new { x.Id, x.Kind, x.Status, x.Version, x.OwnerId, x.WarehouseId, x.RelatedId, details = JsonSerializer.Deserialize<JsonElement>(x.Payload) })); }  …`.

### GET `/api/agent/operations/cashbox`
- المعالج: `Cashbox`؛ معاملات/DTO: `int delegationId, int afterTransactionId, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.GrantAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(new { box.Id, box.Name, box.CurrencyCode, box.OpeningBalance, box.CurrentBalance, transactions = await core.Db.CashTransactions.AsNoTracking().Where(x => x.CashBoxId == box.Id && x.Id > afterTransactionId).OrderBy(x => x.Id).Take(100).Select(x => new { x.Id, x.Direction, x.TransactionType, x.Amount, x.ReferenceType, x. …`.

### POST `/api/agent/operations/batch-holds`
- المعالج: `Hold`؛ معاملات/DTO: `BatchHoldInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `core.GrantAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, "agent.batch.hold", input, async () => { await core.GrantAsync(actor, input.DelegationId, AgentCapability.Inventory, ct); }, async () => { var g = await core.GrantAsync(actor, input.DelegationId, AgentCapability.Inventory, ct); if (!await core.Db.ProductBatches.AnyAsync(x => x.Id  …`.

### POST `/api/agent/operations/batch-holds/{id}/release`
- المعالج: `Release`؛ معاملات/DTO: `int id, BatchReleaseInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `core.ManageAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"agent.batch.release:{id}", input, () => core.ManageAsync(User, "agent.operations.review", r.WarehouseId, ct), async () => { AgentCore.Version(r.Version, input.Version); if (r.Status != AgentRecordStatus.Active || r.OwnerId == actor) throw AgentCore.Denied(); AgentCore.Update(r,  …`.

### GET `/api/agent/operations/batch-holds`
- المعالج: `Holds`؛ معاملات/DTO: `int delegationId, int afterId, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.GrantAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok((await core.Db.Set<AgentRecord>().Where(x => x.Kind == AgentRecordKind.BatchHold && x.WarehouseId == g.WarehouseId && x.Id > afterId).OrderBy(x => x.Id).Take(50).ToListAsync(ct)).Select(AgentCore.View<BatchHoldData>)); } } public sealed record BatchHoldInput(Guid RequestId, int DelegationId, int BatchId, string Reason) …`.

### تعريفات حقول Records في الملف
- `BatchHoldInput(Guid RequestId, int DelegationId, int BatchId, string Reason)`
- `BatchHoldData(string Reason, string? ReleaseReason, int? ReleasedBy)`
- `BatchReleaseInput(Guid RequestId, int Version, string Reason)`


## VetCasesController — `/api/vet/cases`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/VetCasesController.cs)

### POST `/api/vet/cases`
- المعالج: `Create`؛ معاملات/DTO: `CaseInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, "vet.case.create", input, () => Task.CompletedTask, async () => { if (!await core.Db.Animals.AnyAsync(x => x.Id == input.AnimalId && x.OwnerUserId == actor, ct)) throw AgentCore.Denied(); if (input.AiConversationId.HasValue != input.ShareAiConsent || input.ShareAiConsent != input. …`.

### GET `/api/vet/cases`
- المعالج: `Mine`؛ معاملات/DTO: `int afterId, CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Db.Set<VetCase>().AsNoTracking().Where(x => x.Id > afterId && (x.CustomerUserId == actor || (licensed && x.DoctorUserId == actor))) .OrderBy(x => x.Id).Take(50).Select(x => new { x.Id, x.Status, x.Version, x.CreatedAt, x.UpdatedAt, x.DoctorUserId }).ToListAsync(ct)); }  …`.

### GET `/api/vet/cases/queue`
- المعالج: `Queue`؛ معاملات/DTO: `int afterId, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.ManageAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Db.Set<VetCase>().AsNoTracking().Where(x => x.Id > afterId && (x.Status == VetCaseStatus.Requested || x.Status == VetCaseStatus.Assigned)) .OrderBy(x => x.Id).Take(50).Select(x => new { x.Id, x.Status, x.Version, x.DoctorUserId, x.CreatedAt }).ToListAsync(ct)); }  …`.

### GET `/api/vet/cases/{id}`
- المعالج: `Details`؛ معاملات/DTO: `int id, CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(new { row.Id, row.Status, row.Version, row.CreatedAt }); core.Audit(actor, "vet.case.read", id); await core.Db.SaveChangesAsync(ct); return Ok(new { consultation = row, animal = await core.Db.Animals.Where(x => x.Id == row.AnimalId).Select(x => new { x.Id, x.Name, x.Species, x.Breed, x.Gender, x.DateOfBirth, x.WeightKg …`.

### POST `/api/vet/cases/{id}/assign`
- المعالج: `Assign`؛ معاملات/DTO: `int id, AssignCaseInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `core.ManageAsync`، `core.VetAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.case.assign:{id}", input, () => core.ManageAsync(User, "vet.cases.assign", ct: ct), async () => { var row = await Load(id, ct); AgentCore.Version(row.Version, input.Version); EnsureOpen(row); var linkedTasks = await AgentClinical.TaskIds(core.Db, row, ct); if (await core.Db. …`.

### POST `/api/vet/cases/{id}/accept`
- المعالج: `Accept`؛ معاملات/DTO: `int id, CaseVersionInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `راجع تنفيذ الدالة؛ قد تكون الاستجابة غير Ok`.

### POST `/api/vet/cases/{id}/decline`
- المعالج: `Decline`؛ معاملات/DTO: `int id, CaseVersionInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.case.decision:{id}:{accept}", input, async () => { var r = await Load(id, ct); await Participant(r, actor, true, ct); if (r.DoctorUserId != actor) throw AgentCore.Denied(); }, async () => { var row = await Load(id, ct); AgentCore.Version(row.Version, input.Version); if (row. …`.

### GET `/api/vet/cases/{id}/shared-ai`
- المعالج: `Ai`؛ معاملات/DTO: `int id, int afterId, CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(messages); }  …`.

### POST `/api/vet/cases/{id}/revoke-ai-consent`
- المعالج: `Revoke`؛ معاملات/DTO: `int id, CaseVersionInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.case.revoke:{id}", input, async () => { if ((await Load(id, ct)).CustomerUserId != actor) throw AgentCore.Denied(); }, async () => { var r = await Load(id, ct); AgentCore.Version(r.Version, input.Version); r.ConsentRevokedAt = DateTime.UtcNow; Touch(r); core.Audit(actor, "ve …`.

### GET `/api/vet/cases/{id}/messages`
- المعالج: `Messages`؛ معاملات/DTO: `int id, int afterId, CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Db.Set<ChatMessage>().AsNoTracking().Where(x => x.ConversationId == r.ChatConversationId && x.Id > afterId).OrderBy(x => x.Id).Take(50).Select(x => new { x.Id, x.SenderId, x.Body, x.CreatedAt, x.IsRead }).ToListAsync(ct)); }  …`.

### POST `/api/vet/cases/{id}/messages`
- المعالج: `Message`؛ معاملات/DTO: `int id, CaseMessageInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.case.message:{id}", input, async () => await Participant(await Load(id, ct), actor, false, ct), async () => { var r = await Load(id, ct); if (r.Status != VetCaseStatus.Active || r.ChatConversationId == null) throw AgentCore.Conflict("The consultation is not active."); var me …`.

### GET `/api/vet/cases/{id}/attachments`
- المعالج: `Files`؛ معاملات/DTO: `int id, CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Db.Set<VetCaseFile>().Where(x => x.CaseId == id).OrderBy(x => x.Id).Select(x => new { x.Id, x.Name, x.ContentType, x.UploadedBy, x.CreatedAt }).ToListAsync(ct)); }  …`.

### POST `/api/vet/cases/{id}/attachments`
- المعالج: `Upload`؛ معاملات/DTO: `int id, [FromForm] Guid requestId, IFormFile file, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, requestId, $"vet.case.file:{id}", new { name, hash = Convert.ToHexString(SHA256.HashData(bytes)) }, async () => await Participant(await Load(id, ct), actor, false, ct), async () => { if ((await Load(id, ct)).Status != VetCaseStatus.Active || await core.Db.Set<VetCaseFile>().CountAsync(x => x.CaseI …`.

### GET `/api/vet/cases/{id}/attachments/{fileId}`
- المعالج: `FileContent`؛ معاملات/DTO: `int id, int fileId, CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return File(f.Content, f.ContentType, f.Name); }  …`.

### POST `/api/vet/cases/{id}/appointments`
- المعالج: `Appointment`؛ معاملات/DTO: `int id, CaseAppointmentInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.case.appointment:{id}", input, async () => await Doctor(await Load(id, ct), actor, ct), async () => { var r = await Load(id, ct); AgentCore.Version(r.Version, input.Version); if (r.FieldTaskId != null || input.ScheduledAt <= DateTime.UtcNow || input.ScheduledAt > DateTime.Ut …`.

### POST `/api/vet/cases/{id}/close`
- المعالج: `Close`؛ معاملات/DTO: `int id, CaseCloseInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.case.close:{id}", input, async () => await Doctor(await Load(id, ct), actor, ct), async () => { var r = await Load(id, ct); AgentCore.Version(r.Version, input.Version); var linkedTasks = await AgentClinical.TaskIds(core.Db, r, ct); if (await core.Db.FieldVisits.AnyAsync(x => …`.

### POST `/api/vet/cases/{id}/cancel`
- المعالج: `Cancel`؛ معاملات/DTO: `int id, CaseVersionInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `core.VetAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.case.cancel:{id}", input, async () => { if ((await Load(id, ct)).CustomerUserId != actor) throw AgentCore.Denied(); }, async () => { var r = await Load(id, ct); AgentCore.Version(r.Version, input.Version); EnsureOpen(r); var linked = await AgentClinical.TaskIds(core.Db, r, c …`.

### تعريفات حقول Records في الملف
- `CaseInput(Guid RequestId, int AnimalId, string Reason, int? AiConversationId, int? SharedThroughMessageId, bool ShareAiConsent)`
- `AssignCaseInput(Guid RequestId, int Version, int DoctorId)`
- `CaseVersionInput(Guid RequestId, int Version)`
- `CaseMessageInput(Guid RequestId, string Body)`
- `CaseAppointmentInput(Guid RequestId, int Version, DateTime ScheduledAt, string LocationNotes)`
- `CaseCloseInput(Guid RequestId, int Version, string Summary)`


## AgentClinicalController — `/api/vet/cases`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentClinicalController.cs)

### GET `/api/vet/cases/{id}/record`
- المعالج: `Record`؛ معاملات/DTO: `int id, CancellationToken ct`.
- بوابات التحقق الظاهرة: `AgentClinical.CaseAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(new { c.Id, c.AnimalId, notes = notes.Where(x => doctor || AgentCore.Read<ClinicalNoteData>(x).SharedWithCustomer).Select(AgentCore.View<ClinicalNoteData>), visits = await core.Db.FieldVisits.Where(x => tasks.Contains(x.FieldTaskId)).Select(x => new { x.Id, x.FieldTaskId, x.Status, x.StartedAt, x.CompletedAt, x.Diagnos …`.

### POST `/api/vet/cases/{id}/notes`
- المعالج: `Note`؛ معاملات/DTO: `int id, ClinicalNoteInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `AgentClinical.CaseAsync`، `core.VetAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.case.note:{id}", input, async () => { await AgentClinical.CaseAsync(core, id, actor, true, ct); }, async () => { var c = await AgentClinical.CaseAsync(core, id, actor, true, ct); var p = await core.VetAsync(actor, ct); if (c.Status == VetCaseStatus.Closed && !input.AmendsId. …`.

### POST `/api/vet/cases/{id}/workflow`
- المعالج: `Workflow`؛ معاملات/DTO: `int id, ClinicalWorkflowInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `AgentClinical.CaseAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.case.workflow:{id}", input, async () => { await AgentClinical.CaseAsync(core, id, actor, true, ct); }, async () => { var c = await AgentClinical.CaseAsync(core, id, actor, true, ct); AgentCore.Version(c.Version, input.Version); if (c.Status != VetCaseStatus.Active || !Enum.I …`.

### POST `/api/vet/cases/{id}/visits`
- المعالج: `AddVisit`؛ معاملات/DTO: `int id, ClinicalVisitInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `AgentClinical.CaseAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.case.visit:{id}", input, async () => { await AgentClinical.CaseAsync(core, id, actor, true, ct); }, async () => { var c = await AgentClinical.CaseAsync(core, id, actor, true, ct); AgentCore.Version(c.Version, input.Version); if (c.Status != VetCaseStatus.Active || input.Sche …`.

### POST `/api/vet/cases/{id}/visits/{taskId}/reschedule`
- المعالج: `Reschedule`؛ معاملات/DTO: `int id, int taskId, ClinicalVisitInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `AgentClinical.CaseAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.case.reschedule:{id}:{taskId}", input, async () => { await AgentClinical.CaseAsync(core, id, actor, true, ct); }, async () => { var c = await AgentClinical.CaseAsync(core, id, actor, true, ct); AgentCore.Version(c.Version, input.Version); var ids = await AgentClinical.TaskId …`.

### تعريفات حقول Records في الملف
- `ClinicalNoteInput(Guid RequestId, string Body, bool SharedWithCustomer, int? AmendsId)`
- `ClinicalWorkflowInput(Guid RequestId, int Version, ClinicalStage Stage, string Priority, DateTime? FollowUpAt, string CustomerMessage)`
- `ClinicalVisitInput(Guid RequestId, int Version, DateTime ScheduledAt, string Location, string Reason)`


## VetMedicinesController — `/api/vet`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/VetMedicinesController.cs)

### GET `/api/vet/prescriptions`
- المعالج: `Prescriptions`؛ معاملات/DTO: `int afterId, CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok((await core.Db.Set<AgentRecord>().AsNoTracking().Where(x => x.Kind == AgentRecordKind.Prescription && x.Id > afterId && (x.CustomerId == actor || (licensed && x.OwnerId == actor))).OrderBy(x => x.Id).Take(50).ToListAsync(ct)).Select(AgentCore.View<PrescriptionData>)); }  …`.

### GET `/api/vet/medicine-rules`
- المعالج: `Rules`؛ معاملات/DTO: `int afterId, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.VetAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Db.Set<VetMedicineRule>().AsNoTracking().Where(x => x.ProductVariantId > afterId && x.IsActive).OrderBy(x => x.ProductVariantId).Take(100).ToListAsync(ct)); }  …`.

### PUT `/api/vet/medicine-rules/{variantId}`
- المعالج: `Rule`؛ معاملات/DTO: `int variantId, MedicineRuleInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `core.ManageAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.rule:{variantId}", input, () => core.ManageAsync(User, "vet.medicines.manage", ct: ct), async () => { if (!await core.Db.ProductVariants.AnyAsync(x => x.Id == variantId, ct)) throw AgentCore.Missing(); var rule = await core.Db.Set<VetMedicineRule>().FindAsync([variantId], ct …`.

### POST `/api/vet/prescriptions`
- المعالج: `Prescribe`؛ معاملات/DTO: `PrescriptionInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `core.VetAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, "vet.prescribe", input, async () => { await core.VetAsync(actor, ct); var c = await Case(input.CaseId, ct); if (c.DoctorUserId != actor || c.Status != VetCaseStatus.Active) throw AgentCore.Denied(); }, async () => { var c = await Case(input.CaseId, ct); var doctor = await core.Vet …`.

### GET `/api/vet/prescriptions/{id}`
- المعالج: `Prescription`؛ معاملات/DTO: `int id, int? delegationId, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.VetAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(AgentCore.View<PrescriptionData>(r)); }  …`.

### POST `/api/vet/prescriptions/{id}/cancel`
- المعالج: `Cancel`؛ معاملات/DTO: `int id, RecordVersionInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `core.VetAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.prescription.cancel:{id}", input, async () => { await core.VetAsync(actor, ct); if ((await core.RecordAsync(id, AgentRecordKind.Prescription, ct)).OwnerId != actor) throw AgentCore.Denied(); }, async () => { var r = await core.RecordAsync(id, AgentRecordKind.Prescription, ct …`.

### POST `/api/vet/prescriptions/{id}/dispense`
- المعالج: `Dispense`؛ معاملات/DTO: `int id, DispenseInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `AgentClinical.Dispenser`، `core.GrantAsync`، `core.VetAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.dispense:{id}", input, async () => { await AgentClinical.Dispenser(core, actor, ct); await core.GrantAsync(actor, input.DelegationId, AgentCapability.Dispense | AgentCapability.Sell | AgentCapability.Cash, ct); }, async () => { var g = await core.GrantAsync(actor, input.Dele …`.

### تعريفات حقول Records في الملف
- `MedicineRuleInput(Guid RequestId, string Jurisdiction, bool RequiresPrescription, bool RequiresInPerson, bool IsVaccine, bool IsActive)`
- `PrescribeLine(int ProductVariantId, decimal Quantity, string Instructions)`
- `PrescriptionInput(Guid RequestId, int CaseId, DateTime ValidUntil, string Diagnosis, string Warnings, PrescribeLine[] Lines)`
- `PrescriptionLine(int ProductVariantId, decimal Quantity, string Instructions, decimal Dispensed)`
- `PrescriptionData(int CaseId, int AnimalId, string Jurisdiction, string Diagnosis, string Warnings, DateTime IssuedAt, DateTime ValidUntil, PrescriptionLine[] Lines)`
- `DispenseInput(Guid RequestId, int DelegationId, int Version, int CustomerId, AgentStockLine[] Lines, string? AccessCode = null)`
- `DispensationData(int PrescriptionId, int DocumentId, AgentStockLine[] Lines, DateTime DispensedAt)`
- `RecordVersionInput(Guid RequestId, int Version)`


## AgentPrescriptionOrderController — `/api/vet`

[الكود الأصلي](https://github.com/naba125555-ui/Ecommerce_Api/blob/4f8c947866cde3729b11697ec5c44ce41f516595/Ecommerce_APP/Agent/AgentPrescriptionOrderController.cs)

### POST `/api/vet/prescriptions/{id}/checkout/preview`
- المعالج: `Preview`؛ معاملات/DTO: `int id, CreateOrderDto input, CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await checkout.PreviewAsync(actor, input, ct)); }  …`.

### POST `/api/vet/prescriptions/{id}/checkout`
- المعالج: `Checkout`؛ معاملات/DTO: `int id, CreateOrderDto input, CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(new { order.Id, order.Status, order.TotalPrice, order.Currency, prescriptionId = id }); }  …`.

### GET `/api/vet/prescription-orders`
- المعالج: `Orders`؛ معاملات/DTO: `int? delegationId, int afterId, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.GrantAsync`، `AgentClinical.Dispenser`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok((await core.Db.Set<AgentRecord>().Where(x => x.Kind == AgentRecordKind.PrescriptionOrder && x.Id > afterId && (warehouse.HasValue ? x.OwnerId == actor && x.WarehouseId == warehouse : x.CustomerId == actor)).OrderBy(x => x.Id).Take(50).ToListAsync(ct)).Select(AgentCore.View<PrescriptionOrderData>)); }  …`.

### POST `/api/vet/prescription-orders/{orderId}/release`
- المعالج: `Release`؛ معاملات/DTO: `int orderId, PrescriptionReleaseInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `core.GrantAsync`، `AgentClinical.Dispenser`، `core.VetAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.order.release:{orderId}", input, async () => { var g = await core.GrantAsync(actor, input.DelegationId, AgentCapability.Dispense, ct); await AgentClinical.Dispenser(core, actor, ct); var row = await AgentPrescriptionOrders.ForOrder(core.Db, orderId, ct) ?? throw AgentCore.Mi …`.

### POST `/api/vet/prescriptions/{id}/access`
- المعالج: `Consent`؛ معاملات/DTO: `int id, PrescriptionConsentInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `core.GrantAsync`، `AgentClinical.Dispenser`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.prescription.access:{id}", input, async () => { if ((await core.RecordAsync(id, AgentRecordKind.Prescription, ct)).CustomerId != actor) throw AgentCore.Denied(); }, async () => { var g = await core.Db.Set<AgentDelegation>().SingleOrDefaultAsync(x => x.Id == input.DelegationI …`.

### DELETE `/api/vet/prescription-access/{id}`
- المعالج: `Revoke`؛ معاملات/DTO: `int id, CancellationToken ct`.
- بوابات التحقق الظاهرة: قد تكون ضمن خدمة أو استدعاء مساعد؛ راجع المصدر.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return NoContent(); }  …`.

### PUT `/api/vet/administration/dispensers/{userId}`
- المعالج: `License`؛ معاملات/DTO: `int userId, DispensingLicenseInput input, CancellationToken ct`.
- بوابات التحقق الظاهرة: `core.Run`، `core.ManageAsync`.
- مؤشر استجابة من التنفيذ (ليس JSON schema نهائيًا): `return Ok(await core.Run(actor, input.RequestId, $"vet.dispenser.license:{userId}", input, () => core.ManageAsync(User, "vet.profiles.manage", ct: ct), async () => { if (actor == userId || !await core.Db.Users.AnyAsync(x => x.Id == userId && x.IsActive && x.DeletedAt == null && (x.UserType == UserType.Staff || x.UserType == User …`.

### تعريفات حقول Records في الملف
- `PrescriptionReleaseInput(Guid RequestId, int DelegationId, int Version, AgentStockLine[] Batches)`
- `PrescriptionConsentInput(Guid RequestId, int DelegationId)`
- `DispensingLicenseInput(Guid RequestId, string Number, string Jurisdiction, DateTime ExpiresAt, bool Approved, string Notes)`
