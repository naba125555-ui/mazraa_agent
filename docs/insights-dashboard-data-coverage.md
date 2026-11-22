# Home insights carousel — source coverage and backend gaps

This implementation uses the established agent endpoints and no new server contract. The eleven-slide widget is the first home container in `lib/presentation/features/home.dart`. Only authorized slides appear, and they are loaded on demand. It never performs a financial mutation.

| Slide | Read source | Exact supported scope | Known limitation |
|---|---|---|---|
| Overview | `GET /api/agent/operations/home` | `caseOffers, activeCases, pendingProposals, openShifts` as authorized | No single multi-area exhaustive workload count; don't infer missing metrics |
| Clinic | Home summary | Live assigned/new case counters | No full three-state (new/active/closed) historic aggregate, so closed shows unavailable |
| Sales | First 50 of `GET /api/agent/commerce/documents?delegationId&afterId=0` | Posted SalesInvoice documents with `postedAt,totalAmount,currency`; only same-currency amounts are combined | First 50 ordered ascending are not complete weekly history; chart explicitly marked partial unless exhausted |
| Field | First 50 of `GET /api/agent/field/tasks?afterId=0` | Embedded visits with documented `status,completedAt` | Cannot claim complete weekly visits while additional pages exist; parent task completion differs from visit |
| Inventory | First 100 of `GET /api/agent/commerce/inventory?delegationId&afterId=0` | `availableQuantity,reservedQuantity,batches[].expiryDate,quantity` | Flags count items and batches (may overlap), not unique affected products; reorder thresholds not evidenced |
| Finance | `GET /api/agent/operations/cashbox?delegationId&afterTransactionId=0` | Actual `currentBalance,currencyCode` plus first 100 categorized movements | Unrecognized direction codes suppress the flow chart; balances are not profits; history may be partial |
| Pickup | First 50 `GET /api/agent/pickup/requests?delegationId&afterId=0` | Server status values, counted verbatim | Custody cannot be inferred from a queue status. Ready requires an explicit Ready status |
| Auctions | First page `GET /api/agent/marketplace/auctions?delegationId&afterId=0` | Distinct `reviews[]` and `auctions[]` | Approval statuses are independent from published auction statuses; 50 reviews may be partial |
| Purchasing | First 50 `GET /api/agent/procurement?delegationId&afterId=0` | `AgentRecordStatus`, linked receiving documents | Linked document does not prove every ordered line was received |
| Proposals | First 50 `GET /api/agent/marketplace/proposals?afterId=0` | Agent's own proposal statuses | Do not infer an exhaustive total from incomplete pagination |
| Sync | Encrypted local clinical note drafts via `AgentApp.notes()` | Actual local pending count | The repository removes confirmed drafts, so historic synced total, last successful sync and completion percentage are not verifiable |

## Separate server requirements before exposing exhaustive historical charts

A backend analytics contract would need **server-side filtered aggregates** (not a client-side sweep of all paginated records), scoped to the authenticated doctor, active delegation, warehouse/cashbox, period and permitted currency. Requested measures: seven daily sales totals and returns by currency and posted date, visit completion by actual visit timestamp, three-state case totals, inventory exception counts with non-overlap semantics, daily classified cash inflow/outflow, custody-specific pickup state counts, independent auction-review and auction-stage counts, full proposal/procurement state totals, and confirmed clinical-note synchronization history. Prefer typed DTOs, server-provided interval/time zone/currency, and explicit coverage flags. This is **documentation of missing contracts, not an assertion that any endpoint exists**.

## UI guarantees and limitations

- The card has a constant height within a given viewport/text scaling, regardless of the selected slide.
- Theme and direction derive from Flutter; the chart drawing uses native Widgets/CustomPainter, no rasterized screenshots.
- Selecting a slide triggers its read only on first display; loading/error/empty all occupy the same geometry. Changing scope/revision invalidates cached results.
- Values missing in an authorized response render as an em dash rather than fabricated zero.
- All actions link to documented application routes and defer to existing authorization and navigation checks.
- Automated tests verify role filtering, lazy loading, data uncertainty and the two app locales. End-to-end staging/physical device smoothness are separate acceptance steps.
