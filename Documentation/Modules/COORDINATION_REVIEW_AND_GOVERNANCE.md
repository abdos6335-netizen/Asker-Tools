# Clash management and engineering approval workflow

## Clash Manager (0.1.0)
Provides an in-memory review/tracking layer for exact clash records: stable clash ID, owner, status, due date, notes, and severity classification. Current severity mapping is intentionally conservative and provisional (mesh interference HIGH; clearance violation MEDIUM; other states INFORMATION) and is not a project risk standard. Selecting a clash selects its two scene nodes; it does not isolate or modify them. The initial rollout exposes exact-mesh scanning, a clash list with discipline/name context, node selection, and session-level owner/status/due-date/note editing. Tracking is still in-memory and is not persisted between sessions.

## Governance and transaction layer (0.1.0)
Approval requires a candidate already marked simulation-validated, a successful exact simulation, no introduced clashes, no missing rules, no critical violations, a named approver, date, and reason. Applying is a separate explicit call and is limited to a translation on the candidate's affected node. The transform captured with the geometry snapshot is recorded and must still match at apply time; stale scene state blocks application. Rollback restores the original transform only if the node still matches the transform produced by that transaction, preventing rollback from overwriting later edits. Duplicate transaction IDs are rejected. Audit events are retained in memory for the session.

APIs:
- `AT_ClashManager.load clashes`, `counts`, `selectClash index`, `setTracking clashId owner:<string> status:<string> dueDate:<string> note:<string>`
- `AT_CoordinationGovernance.approve candidate simulation approver reason approvalDate`
- `AT_CoordinationGovernance.applyTranslation proposalId nodeRef offset transactionId`
- `AT_CoordinationGovernance.rollback transactionId reason`

## Safety limits
The current tracking and audit records are session-memory only; durable project storage, user identity authentication, concurrency control, full scene snapshots, linked-document revision locking, and multi-node atomic transactions are not implemented. Apply supports translation only and must not be used as an unattended engineering decision. A real project deployment requires in-host QA and explicit engineering review.
