# Admin Shared Data Contract (Aligned with Scheduler)

Source of truth: `The Scheduler/docs/shared_data_contract.md`. Shared Cloud Functions, Firestore rules, Firestore indexes, and the canonical shared schema deploy from `The Scheduler`. This doc lists collections the Admin dashboard uses/writes and calls out unsupported ones. All tenant data is under `businesses/{businessId}/`; top-level `users/{uid}` holds `businessId, role, email, displayName, createdAt, providerId?, clientId?`.

- **Roles:** owner, admin, manager, staff, sales, provider, frontDesk, client. Claims and profiles may include `teamIds`/`managedTeamIds`. Legacy values such as `assistant`, `sales_rep`, `marketing`, and `user` must be normalized before use.
- **CRM ownership/sharing (pipelines, stages, leads, deals, companies, sales_activities):** require `ownerId`, `ownerName?`, `teamIds`, optional `visibility` (default team). Rules allow admin/owner/manager to read/write when ownerId matches or team overlap; delete/ownership reassignment admin/owner-only; stages inherit parent pipeline access.
  - Collections:
    - `businesses/{businessId}/pipelines/{pipelineId}` — name, isDefault, isActive, ownerId, ownerName, teamIds[], visibility (private|team|org), createdAt, updatedAt?
    - `businesses/{businessId}/stages/{stageId}` — pipelineId, name, order, colorHex, probability, isActive, ownerId, ownerName, teamIds[], visibility (private|team|org), createdAt, updatedAt?
    - `businesses/{businessId}/leads/{leadId}` — firstName, lastName, email, phone?, companyName?, title?, status, source, score?, assigneeId?, assigneeName?, tags[], notes?, customFields?, convertedToClientId?, convertedToDealId?, convertedAt?, ownerId, ownerName, teamIds[], visibility (private|team|org), createdAt, updatedAt?
    - `businesses/{businessId}/deals/{dealId}` — pipelineId, stageId, title, valueCents, currency, probability, expectedCloseDate?, status (open|won|lost), wonLostReason?, closedAt?, clientId?, clientName?, companyId?, companyName?, assigneeId?, assigneeName?, tags[], notes?, customFields?, ownerId, ownerName, teamIds[], visibility (private|team|org), createdAt, updatedAt?
    - `businesses/{businessId}/companies/{companyId}` — name, industry?, size?, website?, phone?, email?, address?, notes?, tags[], customFields?, ownerId?, ownerName?, teamIds?, visibility?, createdAt, updatedAt?
    - `businesses/{businessId}/sales_activities/{activityId}` — type (call|email|meeting|note|task), title, description?, dealId?, clientId?, leadId?, companyId?, dueDate?, isCompleted, completedAt?, assigneeId?, assigneeName?, createdById, createdByName, ownerId, ownerName, teamIds[], visibility (private|team|org), createdAt, updatedAt?

## Collections Used by Admin

Use paths/fields exactly as in Scheduler (Admin may add legacy mirrors; keep contract fields primary):

- `providers/{providerId}` — firstName, lastName, email, phone, serviceIds, locationIds, colorHex, createdAt
- `clients/{clientId}` — firstName, lastName, email, phone, lifecycle, tags, createdAt, userId?
- `services/{serviceId}` — name, durationMinutes, price, category, providerIds, requiredResources, bufferMinutes, isActive, createdAt
- `locations/{locationId}` — name, address, city, state, zipCode, timezone, createdAt
- `resources/{resourceId}` — name, type, locationId, capacity, isActive, maintenanceSchedule, description, createdAt
- `resourceMaintenanceLogs/{logId}` — resourceId, note, status, createdBy, createdAt
- `weekly_schedules/{scheduleId}` — providerId, locationId, dayOfWeek, timeBlocks[], isActive, createdAt, updatedAt
- `availability/{availabilityId}` — providerId, locationId, startTime, endTime, type, reason, specificDate, createdAt, updatedAt
- `appointments/{appointmentId}` — clientId, providerId, serviceId, locationId, startTime, endTime, date, status (pending|confirmed|cancelled|completed|noShow), isGroupSession?, capacity?, attendeeIds[], createdAt
- `waitlist_entries/{entryId}` — clientId, clientName, serviceId, providerId, locationId, earliestDate, latestDate, priorityScore, notificationPreference, status, preferredDaysOfWeek[], timeOfDayPreferences[], createdAt, updatedAt, notes
- `payments/{paymentId}` — appointmentId?, clientId, amountCents, currency, status (pending|completed|failed|refunded|partially_refunded|none), type (deposit|full|subscription|reschedule_fee|cancellation_fee|refund), createdAt, updatedAt?
- `intakeFormTemplates/{templateId}`, `intakeFormSubmissions/{submissionId}`, `intakeFormDrafts/{draftId}`
- `session_notes/{noteId}` — noteType, visibility, encryptedContent, title?, tags[], isLocked, createdAt, updatedAt?, createdBy, createdByName, lastEditedBy?, lastEditedByName?, auditLog[], retainIndefinitely?, isPsychotherapyNote?
- `clients/{clientId}/files/{fileId}` — name, contentType, sizeBytes, storagePath, storageUrl/downloadUrl, uploadedAt, uploaderId, accessLevel, isSensitive, metadata, category, appointmentId?, intakeFormId?, intakeSubmissionId?, notes?
- `magic_link_tokens/{tokenId}` — appointmentId, clientId, clientEmail, token, createdAt, expiresAt, hasBeenUsed, accessCount, status
- `modification_requests/{requestId}` — appointmentId, clientId, providerId, type, status, requestedStartTime, requestedDurationMinutes, reason, policyWindowBreached, feeRequired, feeCollected, createdAt, updatedAt
- `integrations/{integrationId}` — provider (googleCalendar|outlookCalendar|zoom|googleMeet|sendGrid|twilio|awsSes|awsSns), status, scopes[], displayName, email, connectedAt, lastSyncAt, errorMessage?, calendarSettings?, telehealthSettings?
  - `integrations/{integrationId}/tokens/oauth` — encrypted `{accessToken, refreshToken, expiresAt, providerUserId?, staffId?, keyVersion?}` (no client-side reads; written by privileged roles/Functions only)
  - `integrations/{integrationId}/sync_state/{stateId}` — `cursor`, `lastSyncedAt`, `lastAttemptAt`, `lastStatus` (success|failed|backoff), `backoffUntil?`, `retried?`, `fromCache?`, `checksumHash?`, `conflictCount?`
- `staff_integrations/{staffId}` — calendarProvider, telehealthProvider
- `message_templates/{templateId}`, `message_history/{messageId}`
- `campaigns/{campaignId}` — name, description?, channels (email[]/sms[] semantics expressed as `channels: ('email'|'sms')[]`), templateIds{email?, sms?}, template? (legacy fallback body), emailSubjectTemplate?, emailBodyTemplate?, smsBodyTemplate?, subjectLine?, smsBodyPreview?, filters{tags[], lastVisitMode, lastVisitDays, upcomingMode, upcomingDays}, status (draft|scheduled|sending|sent|failed|cancelled), audienceStats?, createdAt, updatedAt?, scheduledFor?, sentAt?, recipientCount?
- `automation_rules/{ruleId}` — name, description?, trigger{type (leadCreated|leadStatusChanged|dealStageChanged|taskOverdue), fromStatus?, toStatus?, fromStageId?, toStageId?, overdueDays?}, action{type (createTask|sendEmailTemplate|addTag|updateField), target (lead|deal|contact|activity), taskTemplate{title, description?, dueInDays?, assigneeId?, assigneeName?, activityType?}, emailTemplate{templateId, templateType?, recipient, subjectOverride?}, tag?, fieldUpdate{field (status|stageId|assigneeId|assigneeName|leadSource|probability), value}}, status (enabled|disabled), ownerId, ownerName, teamIds[], visibility?, createdById, createdByName?, businessId?, lastRunAt?, createdAt, updatedAt?
- `automation_runs/{runId}` — businessId, ruleId, triggerType, actionType, target, entityId, entityType, status (success|skipped|rate_limited|failed), executedAt, createdAt, updatedAt?, correlationId, dryRun, errorCode?, errorMessage?
- `lead_intake_events/{eventId}` — `type`, `payloadHash`, `occurredAt`, `receivedAt`, `status?`, `fromCache?` (no payload bodies)
- `webhook_dead_letters/{deadLetterId}` — `destination` (HTTPS only), `payloadHash`, `status` (pending|retrying|failed|deleted), `attempts`, `lastAttemptAt`, `nextRetryAt?`, `errorCode?`, `lastHttpStatus?`, `replayCursor?`
- `import_sessions/{sessionId}` — `entityType` (lead|client|appointment|deal|company), `status` (pending|validating|running|paused|completed|failed), `processedRows`, `totalRows`, `errorCount`, `resumeToken`, `backoffUntil?`, `createdBy`, `createdByRole`, `startedAt`, `updatedAt`, `expiresAt`, `lastErrorHash?`, `validationHash?` (no row payloads/PHI)
- `export_jobs/{exportId}` — `entityType`, `format` (csv|pdf), `status` (queued|running|completed|failed), `filtersHash`, `delivery{method (email|link), targetEmail?, expiresAt?, downloadUrl?, checksumHash?}`, `createdBy`, `createdByRole`, `createdAt`, `updatedAt`, `nextRunAt?`, `lastRunAt?` (no raw payloads)
- `businesses/{businessId}/report_views/{viewId}` — name, description?, filters{startDate?, endDate?, pipelineId?, stageIds[], statuses[], assigneeIds[], leadSources[], ownerIds?, teamIds?}, ownerId, ownerName, teamIds[], createdAt, updatedAt?
- `businesses/{businessId}/reporting_aggregates/{aggregateId}` — pipelineId?, ownerId?, teamIds[], bucket (daily|weekly|monthly), startDate, endDate, metrics{openCount, wonCount, lostCount, openValueCents, wonValueCents, lostValueCents, averageCycleDays}, stageBreakdown[], stageConversions[], lostReasons[], velocity{averageCycleDays, averageOpenDays, throughputPerDay, winRate}, createdAt, updatedAt?
- `businesses/{businessId}/report_exports/{exportId}` — name, description?, format (csv|pdf), cadence (once|daily|weekly), status (scheduled|running|completed|failed|paused), nextRunAt, lastRunAt?, lastRunStatus?, filters (ReportingAggregationFilters hashed/sanitized), delivery{method (email|link), targetEmail?, expiresAt?, downloadUrl?}, ownerId, ownerName, teamIds[], visibility?, createdAt, updatedAt?
- `subscriptions/current`, `settings/feature_flags`
- `users/{uid}` (top-level) — businessId, role, email, displayName, createdAt, providerId?, clientId?

**Feature flags (`settings/feature_flags`)**: managed booleans for gating UI + Functions. Required keys: `enableAdvancedReporting`, `enableReportSavedViews`, `enableReporting`, `enableImportExport`, `enableAutomation`, `enableCalendarSync`, `enableEmailIntegration`, `enableMarketing`, `enableWaitlist`, `enableLocations`, `enableResources`, `enableResourceConflicts`, `enableClientPortal`, `enableSessionNotes`, `enableIntakeBuilder`, `waitlistNotifyChannels[]`. Defaults: `enableAdvancedReporting`, `enableReportSavedViews`, `enableImportExport`, and `enableAutomation` should be **false in production** unless entitlements/backends are live.

## Unsupported Scheduler Collections (Admin does NOT write)

Admin dashboard does not use/write: `posTransactions/`, `retailProducts/`, `giftCards/`, `giftCardTemplates/`, `timeEntries/`, `clientRiskScores/`, `sentimentResults/`, `optimizedRoutes/`, `tasks/`, `billing_sessions/`. (Onboarding collections `join_codes/`, `invites/`, `join_requests/` exist in Scheduler; Admin should keep contract in sync even if not used.)

## Indexes

Composite indexes to keep (see Scheduler for full list):
- Appointments: providerId+startTime; clientId+startTime; isGroupSession+startTime; serviceId+startTime; locationId+startTime; status+startTime; publicVisibility+{serviceId|providerId|locationId}+startTime.
- Appointment files: appointmentId+uploadedAt.
- Session notes: clientId+createdAt(desc); providerId+createdAt(desc); appointmentId+createdAt(desc); noteType+createdAt(desc).
- Waitlist: status+serviceId+providerId+createdAt; clientId+status+createdAt.
- Magic link tokens: token+businessId; appointmentId+status; expiresAt+status.
- Tasks (if/when Admin supports): assignedToProviderId+dueDate; assignedToProviderId+status; status+priority+dueDate; linkedClientId+dueDate; linkedAppointmentId.
- Join codes/invites/join requests (if/when Admin supports onboarding flows): codeHash+status; status+expiresAt; status+createdAt(desc); tokenHash+status; email+status.
- Automation runs: ruleId+createdAt(desc); correlationId+createdAt(desc) (idempotency/recent history).

## Deployment

- Shared rules/indexes deploy from `The Scheduler`.
- Shared schema changes must be reflected here, in Admin models/writes, and in Scheduler docs/seeds.
