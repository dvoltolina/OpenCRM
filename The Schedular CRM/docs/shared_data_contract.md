# CRM Shared Data Contract (Aligned with Scheduler)

Source of truth: `The Scheduler/docs/shared_data_contract.md`. Shared Cloud Functions, Firestore rules, Firestore indexes, and the canonical shared data contract are deployed from `The Scheduler`. This doc mirrors required/shared collections and notes CRM extensions only. All tenant data is scoped under `businesses/{businessId}/`.

## Roles
- owner, admin, manager, staff, sales, provider, frontDesk, client. Claims/profiles may include `teamIds`/`managedTeamIds`. Legacy roles such as `assistant`, `sales_rep`, `marketing`, and `user` must be normalized before use.

## Shared Collections (from Scheduler)
Use these paths/fields exactly as in Scheduler.

### `users/{uid}` (top-level)
```
- businessId: string
- role: 'owner' | 'admin' | 'manager' | 'staff' | 'sales' | 'provider' | 'frontDesk' | 'client'
- email: string
- displayName: string
- createdAt: Timestamp
- providerId?: string
- clientId?: string
- teamIds?: string[]
- managedTeamIds?: string[]
```

### CRM ownership/sharing (shareable across apps)
Required fields on create: `ownerId`, `ownerName?`, `teamIds: string[]`, optional `visibility: 'private' | 'team' | 'org'` (default team). Rules: read/write allowed for admin/owner/manager when ownerId matches or team overlap; delete/ownership reassignment admin/owner only; stages inherit parent pipeline access. Team scope comes from token claims (`teamIds`, `managedTeamIds`) or user profile.
Collections:
- `businesses/{businessId}/pipelines/{pipelineId}` — name, isDefault, isActive, ownerId, ownerName, teamIds[], visibility (private|team|org), createdAt, updatedAt?
- `businesses/{businessId}/stages/{stageId}` — pipelineId, name, order, colorHex, probability, isActive, ownerId, ownerName, teamIds[], visibility (private|team|org), createdAt, updatedAt?
- `businesses/{businessId}/leads/{leadId}` — firstName, lastName, email, phone?, companyName?, title?, status, source, score?, assigneeId?, assigneeName?, tags[], notes?, customFields?, convertedToClientId?, convertedToDealId?, convertedAt?, ownerId, ownerName, teamIds[], visibility (private|team|org), createdAt, updatedAt?
- `businesses/{businessId}/deals/{dealId}` — pipelineId, stageId, title, valueCents, currency, probability, expectedCloseDate?, status (open|won|lost), wonLostReason?, closedAt?, clientId?, clientName?, companyId?, companyName?, assigneeId?, assigneeName?, tags[], notes?, customFields?, ownerId, ownerName, teamIds[], visibility (private|team|org), createdAt, updatedAt?
- `businesses/{businessId}/companies/{companyId}` — name, industry?, size?, website?, phone?, email?, address?, notes?, tags[], customFields?, ownerId?, ownerName?, teamIds?, visibility?, createdAt, updatedAt?
- `businesses/{businessId}/sales_activities/{activityId}` — type (call|email|meeting|note|task), title, description?, dealId?, clientId?, leadId?, companyId?, dueDate?, slaAt?, slaMinutes?, reminderAt?, templateId?, isCompleted, completedAt?, assigneeId?, assigneeName?, createdById, createdByName, ownerId, ownerName, teamIds[], visibility (private|team|org), createdAt, updatedAt?
- `businesses/{businessId}/automation_rules/{ruleId}` — name, description?, trigger{type,fromStatus?,toStatus?,fromStageId?,toStageId?,overdueDays?,reminderType?}, action{type,target,taskTemplate?,emailTemplate?,tag?,fieldUpdate?}, status (enabled|disabled), ownerId, ownerName, teamIds[], visibility?, createdById, createdByName, businessId?, createdAt, updatedAt?, lastRunAt?
- `businesses/{businessId}/automation_runs/{runId}` — businessId, ruleId, triggerType, actionType, target, entityType, entityId, status (success|skipped|rate_limited|failed), executedAt, createdAt, updatedAt?, correlationId, dryRun, errorCode?, errorMessage?

### Other shared collections (selected)
- `businesses/{businessId}/clients/{clientId}` — firstName, lastName, email, phone, lifecycle, tags, userId?, companyId?, companyName?, title?, crmNotes?, lastContactedAt?, leadSource?, ownerId?, ownerName?, teamIds?, visibility?, createdAt, updatedAt?
- `businesses/{businessId}/providers/{providerId}` — assignee lookup; see Scheduler for full schema.
- `businesses/{businessId}/appointments/{appointmentId}` — read-only in CRM; see Scheduler for full schema.
- `businesses/{businessId}/message_history/{messageId}` — read-only communication metadata for contact and deal context (`clientId`, `type`, `direction`, `preview`, `sentAt`, `status`, optional `subject`).
- `businesses/{businessId}/clientRiskScores/{clientId}` — read-only AI risk summary; CRM may display but never write.
- `businesses/{businessId}/sentimentResults/{resultId}` — read-only sentiment snapshots keyed by `clientId`; CRM may display but never write.
- `businesses/{businessId}/payments/{paymentId}` — see Scheduler for full schema.
- `businesses/{businessId}/report_views/{viewId}` — name, description?, filters{startDate?, endDate?, pipelineId?, stageIds[], statuses[], assigneeIds[], leadSources[], ownerIds?, teamIds?}, ownerId, ownerName, teamIds[], createdAt, updatedAt?
- `businesses/{businessId}/reporting_aggregates/{aggregateId}` — pipelineId, ownerId, teamIds[], bucket, startDate, endDate, metrics{}, stageBreakdown[], createdAt.
- `businesses/{businessId}/report_exports/{exportId}` — name, description?, format (csv|pdf), cadence (once|daily|weekly), status (scheduled|running|completed|failed|paused), nextRunAt, lastRunAt?, lastRunStatus?, filters (ReportingAggregationFilters hashed/sanitized), delivery{method (email|link), targetEmail?, expiresAt?, downloadUrl?}, ownerId, ownerName, teamIds[], visibility?, createdAt, updatedAt?
- `businesses/{businessId}/integrations/{integrationId}/tokens/oauth` — encrypted `{accessToken, refreshToken, expiresAt, providerUserId?, staffId?, keyVersion?}`. Stored encrypted; never read directly from UI.
- `businesses/{businessId}/integrations/{integrationId}/sync_state/{stateId}` — cursor, lastSyncedAt, lastAttemptAt, lastStatus (success|failed|backoff), backoffUntil?, retried?, fromCache?, checksumHash?, conflictCount?
- `businesses/{businessId}/webhook_dead_letters/{id}` — destination (HTTPS only), reason?, attempts, payloadHash, status (pending|retrying|failed|deleted), lastAttemptAt, nextRetryAt?, errorCode?, lastHttpStatus?, replayCursor? (no payload bodies).
- `businesses/{businessId}/lead_intake_events/{id}` — id, type, payloadHash, occurredAt, receivedAt, status?, fromCache? (no raw payload).
- `businesses/{businessId}/import_sessions/{sessionId}` — entityType, createdBy, createdByRole, processedRows, totalRows, errorCount?, errors[]?, resumeToken (immutable), status (pending|validating|running|paused|completed|failed), startedAt, updatedAt?, expiresAt, backoffUntil?, lastErrorHash?, validationHash? (no row data/PHI).
- `businesses/{businessId}/export_jobs/{exportId}` — entityType, format (csv|pdf), status (queued|running|completed|failed), filtersHash, delivery{method (email|link), targetEmail?, expiresAt?, downloadUrl?, checksumHash?}, createdBy, createdByRole, createdAt, updatedAt, nextRunAt?, lastRunAt? (no raw payloads)
- See Scheduler contract for all other shared collections (services, locations, resources, schedules, availability, files, notes, magic_link_tokens, modification_requests, integrations, message templates/history, audit_logs, AI collections, etc.).

**Feature flags (`settings/feature_flags`)** — booleans to gate UI + Functions: `enableAdvancedReporting`, `enableReportSavedViews`, `enableReporting`, `enableImportExport`, `enableAutomation`, `enableCalendarSync`, `enableEmailIntegration`, `enableMarketing`, `enableWaitlist`, `enableLocations`, `enableResources`, `enableResourceConflicts`, `enableClientPortal`, `enableSessionNotes`, `enableIntakeBuilder`, `waitlistNotifyChannels[]`. Defaults: `enableAdvancedReporting`, `enableReportSavedViews`, `enableImportExport`, and `enableAutomation` should stay **false in production** until entitlements/backends are active.

## Unsupported Scheduler Collections for CRM UI
CRM UI does not write: `posTransactions/`, `retailProducts/`, `giftCards/`, `giftCardTemplates/`, `timeEntries/`, `clientRiskScores/`, `sentimentResults/`, `optimizedRoutes/`, `tasks/`, `join_codes/`, `invites/`, `join_requests/`, `billing_sessions/`.

## Indexes & Rules
- Shared composite indexes live in `The Scheduler/firestore.indexes.json`. CRM may document recommendations here, but it is not a deploy source of truth.
- Shared rules are deployed from `The Scheduler/firestore.rules`. CRM-only additions must align with Scheduler contract and rule posture and then be implemented in the Scheduler repo.
- Recommended indexes for integrations/import/export/reporting/automation: provider+status and status+lastSyncAt (integrations); provider+lastAttemptAt (sync_state); status+nextRetryAt/lastAttemptAt (webhook_dead_letters); type+occurredAt(desc) (lead_intake_events); status+createdAt(desc) and status+expiresAt (import_sessions); status+createdAt(desc) and status+nextRunAt (export_jobs); status+nextRunAt, cadence+nextRunAt, ownerId+nextRunAt (report_exports); ruleId+createdAt(desc) and correlationId+createdAt(desc) (automation_runs).

## Coordination
- When shared schema changes, update Scheduler’s `docs/shared_data_contract.md`, this file, Admin mirror, models, seeds, and indexes.
- Keep CRM writes to shared collections backward-compatible; Scheduler ignores unknown CRM-only fields.***
