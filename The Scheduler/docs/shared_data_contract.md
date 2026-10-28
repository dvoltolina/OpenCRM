# Shared Data Contract (Mobile + Admin)

Canonical Firestore schema, field names, and indexes used by **The Scheduler** (mobile) and the Admin Dashboard. Use this as the single source of truth when updating models, seeds, rules, or indexes.

## Paths and Collections
All tenant data is scoped under `businesses/{businessId}`.

- **Roles (tokens + user docs):** owner, admin, manager, staff, sales, provider, frontDesk, client. Claims and user profiles may include `teamIds` and `managedTeamIds` for sharing/RBAC.
- **CRM ownership/sharing (pipelines, stages, leads, deals, companies, sales_activities):**
  - Required fields on create: `ownerId`, `ownerName?`, `teamIds: string[]`, optional `visibility: 'private' | 'team' | 'org'` (default team).
  - Firestore rules: read/write allowed for admin/owner/manager when ownerId matches or team overlap; delete/ownership reassignment admin/owner only; stages inherit parent pipeline access.
  - Team scope comes from token claims (`teamIds`, `managedTeamIds`) or user profile; lists are deduped before checks.
  - Collections:
    - `businesses/{businessId}/pipelines/{pipelineId}` — name, isDefault, isActive, ownerId, ownerName, teamIds[], visibility (private|team|org), createdAt, updatedAt?
    - `businesses/{businessId}/stages/{stageId}` — pipelineId, name, order, colorHex, probability, isActive, ownerId, ownerName, teamIds[], visibility (private|team|org), createdAt, updatedAt?
    - `businesses/{businessId}/leads/{leadId}` — firstName, lastName, email, phone?, companyName?, title?, status, source, score?, assigneeId?, assigneeName?, tags[], notes?, customFields?, convertedToClientId?, convertedToDealId?, convertedAt?, ownerId, ownerName, teamIds[], visibility (private|team|org), createdAt, updatedAt?
    - `businesses/{businessId}/deals/{dealId}` — pipelineId, stageId, title, valueCents, currency, probability, expectedCloseDate?, status (open|won|lost), wonLostReason?, closedAt?, clientId?, clientName?, companyId?, companyName?, assigneeId?, assigneeName?, tags[], notes?, customFields?, ownerId, ownerName, teamIds[], visibility (private|team|org), createdAt, updatedAt?
    - `businesses/{businessId}/companies/{companyId}` — name, industry?, size?, website?, phone?, email?, address?, notes?, tags[], customFields?, ownerId?, ownerName?, teamIds?, visibility?, createdAt, updatedAt?
    - `businesses/{businessId}/sales_activities/{activityId}` — type (call|email|meeting|note|task), title, description?, dealId?, clientId?, leadId?, companyId?, dueDate?, isCompleted, completedAt?, assigneeId?, assigneeName?, createdById, createdByName, ownerId, ownerName, teamIds[], visibility (private|team|org), createdAt, updatedAt?

- `providers/{providerId}` — firstName, lastName, displayName, email, phone, role, status, serviceIds, locationIds, colorHex, telehealthLink?, appAccess?, moduleAccess?, createdAt, createdBy?, updatedAt?, updatedBy?, deactivatedAt?
- `clients/{clientId}` — firstName, lastName, email, phone, lifecycle, tags, createdAt, userId? (Auth link)
- `services/{serviceId}` — name, durationMinutes, price, category, providerIds, requiredResources, bufferMinutes, isActive, createdAt
- `locations/{locationId}` — name, address, city, state, zipCode, timezone, createdAt
- `resources/{resourceId}` — name, type (room|equipment|vehicle|other), locationId, capacity, isActive, maintenanceSchedule, description, createdAt
- `resourceMaintenanceLogs/{logId}` — resourceId, note, status, createdBy, createdAt
- `weekly_schedules/{scheduleId}` — providerId, locationId, dayOfWeek, timeBlocks[{startHour,startMinute,endHour,endMinute}], isActive, createdAt, updatedAt
- `availability/{availabilityId}` — providerId, locationId, startTime, endTime, type (available|blocked|override), reason, specificDate, createdAt, updatedAt
- `appointments/{appointmentId}` — clientId, providerId, serviceId, locationId, startTime, endTime, date, status (pending|confirmed|cancelled|completed|noShow), isGroupSession?, capacity?, attendeeIds[], createdAt
- `appointments/{appointmentId}/attendees/{attendeeId}` — clientId, displayName, email, phone, status (registered|attended|noShow|cancelled), paymentStatus (none|pending|completed|failed|refunded|partiallyRefunded), refundStatus, paymentId?, notes?, joinedAt
- `waitlist_entries/{entryId}` — clientId, clientName, serviceId, providerId, locationId, earliestDate, latestDate, priorityScore, notificationPreference (email|sms|both), status (active|notified|expired|converted), preferredDaysOfWeek[], timeOfDayPreferences[], createdAt, updatedAt, notes
- `payments/{paymentId}` — appointmentId, clientId, amountCents, currency, status (pending|completed|failed|refunded|partially_refunded|none), type (deposit|full|subscription|reschedule_fee|cancellation_fee|refund), stripeInvoiceId?, stripePaymentIntentId?, stripeSubscriptionId?, stripeCustomerId?, receiptUrl?, hostedInvoiceUrl?, invoicePdfUrl?, paidAt?, failedAt?, failureReason?, createdAt, updatedAt? (+refund fields as needed)
- `giftCards/{giftCardId}` — code, originalAmountCents, remainingBalanceCents, currency, status (pending|active|depleted|expired|voided), activatedAt?, expiresAt?, purchaserEmail, purchaserName?, purchasedAt, paymentId?, recipientEmail?, recipientName?, personalMessage?, delivered, createdAt, lastRedeemedAt?, redemptions[], templateId?, customImageUrl?
- `giftCardTemplates/{templateId}` — name, description, imageUrl, backgroundColor, textColor, presetAmountsCents[]?, minAmountCents?, maxAmountCents?, validityDays?, isActive, createdAt
- `products/{productId}` — name, description?, sku?, barcode?, priceCents, costCents?, category (skincare|haircare|supplements|equipment|merchandise|consumables|other), tags[], trackInventory, stockQuantity?, lowStockThreshold?, imageUrl?, additionalImages[], isActive, availableForSale, taxable, taxCategoryId?, linkedServiceId?, sortOrder, createdAt, updatedAt?
- `posTransactions/{transactionId}` — transactionDate, staffId, staffName?, clientId?, clientName?, appointmentId?, lineItems[{productId, productName, sku?, quantity, unitPriceCents, totalCents, discountCents, discountReason?, taxCents, taxable}], subtotalCents, taxCents, taxRate, discountCents, discountReason?, totalCents, paymentMethod (card|cash|gift_card|split|account), paymentStatus (none|pending|completed|failed|refunded|partially_refunded), stripePaymentId?, giftCardCode?, splitPayments[{method, amountCents, reference?, stripePaymentId?, giftCardCode?}]?, cashTenderedCents?, changeCents?, receiptNumber, receiptUrl?, receiptEmailed, notes?, isVoided, voidReason?, voidedAt?, voidedBy?, createdAt, updatedAt?
- `timeEntries/{entryId}` — staffId, clockInTime, clockOutTime?, clockInLatitude?, clockInLongitude?, clockInAddress?, clockOutLatitude?, clockOutLongitude?, clockOutAddress?, clockInLocationId?, clockOutLocationId?, clockInOutsideGeofence, clockOutOutsideGeofence, breaks[{startTime, endTime?, type (meal|rest)}], totalMinutes?, breakMinutes?, workedMinutes?, status (active|pending|approved|rejected), approvedByUserId?, approvedAt?, rejectionReason?, staffNotes?, managerNotes?, createdAt, updatedAt
- `tasks/{taskId}` — id, businessId, title, description?, createdAt, dueDate?, priority (low|medium|high|urgent), status (pending|inProgress|completed|cancelled), assignedToProviderId?, assignedToProviderName?, linkedClientId?, linkedClientName?, linkedAppointmentId?, completedAt?, createdByUserId?, createdByUserName?, updatedAt?
- `intakeFormTemplates/{templateId}` — name, description, fields[], applicableIndustries, isActive, createdAt, updatedAt, version
- `intakeFormSubmissions/{submissionId}` — clientId, templateId, templateName, templateVersion, responses{}, status, submittedAt, createdAt, updatedAt
- `intakeFormDrafts/{draftId}` — clientId, templateId, responses{}, status, createdAt, updatedAt, expiresAt, attachments[]
- `session_notes/{noteId}` — id, businessId, appointmentId, clientId, providerId, noteType (soap|progressNote|treatmentPlan|procedureLog|adjustmentNote|intakeAssessment|dischargeNote|psychNote|custom), visibility (providerOnly|businessOnly|shared), encryptedContent, title?, tags[], isLocked, createdAt, updatedAt?, createdBy, createdByName, lastEditedBy?, lastEditedByName?, auditLog[], retainIndefinitely, isPsychotherapyNote
- `clients/{clientId}/files/{fileId}` — name, contentType, sizeBytes, storagePath, storageUrl/downloadUrl, uploadedAt, uploaderId, accessLevel, isSensitive, metadata, category, appointmentId?, intakeFormId?, intakeSubmissionId?
- `appointments/{appointmentId}/files/{fileId}` — session material metadata (name, contentType, sizeBytes, storagePath, downloadUrl, uploadedAt, uploaderId/uploaderName, accessLevel, category, notes)
- `magic_link_tokens/{tokenId}` — appointmentId, clientId, clientEmail, token, createdAt, expiresAt, hasBeenUsed, accessCount, status (active|expired|revoked)
- `modification_requests/{requestId}` — appointmentId, clientId, providerId, type (reschedule|cancel), status, requestedStartTime, requestedDurationMinutes, reason, policyWindowBreached, feeRequired, feeCollected, createdAt, updatedAt
- `integrations/{integrationId}` — provider (googleCalendar|outlookCalendar|zoom|googleMeet|sendGrid|twilio|awsSes|awsSns), status, scopes[], displayName, email, connectedAt, lastSyncAt, errorMessage?, calendarSettings?, telehealthSettings?
  - `integrations/{integrationId}/tokens/oauth` — accessToken, refreshToken, expiresAt (encrypted at rest)
- `staff_integrations/{staffId}` — calendarProvider, telehealthProvider
- `calendar_connections/{connectionId}` — businessId, userId, userName, provider (google|outlook), accessToken, refreshToken, tokenExpiresAt, settings{syncDirection, defaultCalendarId, syncMeetings, syncCalls, syncTasks, lookbackDays, lookforwardDays}, status (active|disconnected), lastSyncStatus (success|partial|failed), lastSyncError?, lastCalendarId?, createdAt, updatedAt
  - `accessToken` / `refreshToken` store encrypted token blobs at rest under generic field names; clients must never log or expose their contents.
- `calendar_sync_mappings/{mappingId}` — businessId, userId, provider, connectionId, activityId, externalEventId, syncDirection, status (pending|synced|conflict|failed), lastSyncedAt?, conflictSnapshot?, createdAt, updatedAt
- `message_templates/{templateId}` — channel (email|sms), type, subject?, body
- `campaigns/{campaignId}` — name, description?, channels (`('email'|'sms')[]`), templateIds{email?, sms?}, template? (legacy fallback body used when channel-specific content is missing), emailSubjectTemplate?, emailBodyTemplate?, smsBodyTemplate?, subjectLine?, smsBodyPreview?, filters{tags[], lastVisitMode, lastVisitDays, upcomingMode, upcomingDays}, status (draft|scheduled|sending|sent|failed|cancelled), audienceStats?, createdAt, updatedAt?, scheduledFor?, sentAt?, recipientCount?
- `automation_rules/{ruleId}` — type, enabled, emailEnabled, smsEnabled, timingMinutes?, templateId
- `message_history/{messageId}` — clientId, appointmentId, channel, type, recipient, status, sentAt, subject?, body?
- `audit_logs/{logId}` — businessId, userId, actionType (loginSuccess|loginFailure|phiRead|phiReadList|phiWrite|dataExport|securityEvent), entityType, entityId, timestamp (server-set), ipAddress (Functions only), deviceInfo?, correlationId?, metadata{} (no PHI/free text)
- `clientRiskScores/{clientId}` — id, clientId, businessId, calculatedAt, churnRiskScore (0-100), satisfactionScore (0-100), vipScore (0-100), overallHealthScore (0-100), churnTrend (improving|stable|declining), satisfactionTrend, vipTrend, churnScoreChange?, satisfactionScoreChange?, riskIndicators[], vipIndicators[], topRiskFactors[], topVipFactors[], textsAnalyzed, analysisStartDate, analysisEndDate, averageSentiment, sentimentStdDev, recommendedActions[], recentNoshowCount?, recentCancellationCount?, daysSinceLastVisit?, visitFrequencyTrend?, scoringVersion, expiresAt
- `clientRiskScores/{clientId}/history/{timestamp}` — archived ClientRiskScore documents for trend tracking
- `sentimentResults/{resultId}` — id, businessId, clientId, source (smsReply|emailReply|intakeFormText|sessionNote|cancellationReason|rescheduleReason|feedbackText|staffNote), sourceDocumentId?, analyzedText, sentimentScore (-1.0 to 1.0), confidence, riskIndicators[], vipIndicators[], summary?, recommendedAction?, modelVersion, analyzedAt, expiresAt, processingTimeMs?
- `optimizedRoutes/{routeId}` — id, businessId, providerId, providerName, routeDate, status (planned|inProgress|completed|cancelled|needsReoptimization), stops[{id, sequenceOrder, stopType, status, name, address, lat, lng, windowStart, windowEnd, scheduledArrival, serviceDurationMinutes, appointmentId?, clientId?}], segments[], startTime, expectedEndTime, totalDistanceMeters, totalTravelTimeSeconds, totalServiceTimeSeconds, optimizerVersion, optimizedAt, updatedAt
- `locations/{locationId}/routing/data` — latitude?, longitude?, placeId?, isMobileServiceBase, defaultTravelBufferMinutes, timezone?, serviceRadiusKm?, lastGeocodedAt?, geocodingFailed, geocodingError?
- `clients/{clientId}/routing/data` — requiresMobileService, serviceAddress?, serviceCity?, serviceState?, serviceZipCode?, serviceLatitude?, serviceLongitude?, servicePlaceId?, arrivalNotes?, preferredWindowStart?, preferredWindowEnd?, availableDays[]?, averageServiceDurationMinutes?, extraBufferMinutes?, lastGeocodedAt?, geocodingFailed, geocodingError?
- `subscriptions/current` — status, planId, currentPeriodStart, currentPeriodEnd, cancelAtPeriodEnd, usage{}
- `exportJobs/{exportId}` — businessId, requestedBy, status (queued|processing|completed|failed), format, scope, createdAt, updatedAt
- `workspaceDeletionRequests/{requestId}` — businessId, requestedBy, status (requested|processing|completed|cancelled|failed), reason?, createdAt, updatedAt
- `settings/feature_flags` — enable* booleans, waitlistNotifyChannels[]
- `users/{uid}` (top-level) — businessId, role, email, displayName, createdAt, providerId?, clientId?, teamIds?, managedTeamIds?

**Staff Onboarding Collections (under `businesses/{businessId}/`):**
- `join_codes/{codeId}` — codeHash (SHA-256, never plaintext), createdBy (userId), createdAt, expiresAt, maxUses, uses, role (admin|manager|staff|sales|provider|frontDesk), status (active|revoked|expired), lastUsedAt?, lastUsedBy?, notes?
- `invites/{inviteId}` — email, role (admin|manager|staff|sales|provider|frontDesk), tokenHash (SHA-256), createdBy (userId), createdAt, expiresAt, status (active|revoked|expired|used), usedAt?, usedBy?
- `join_requests/{requestId}` — email, displayName?, role (admin|manager|staff|sales|provider|frontDesk), codeId?, inviteId?, requestorUserId?, deviceInfo?, createdAt, status (pending|approved|denied), reviewedBy?, reviewedAt?, denialReason?

**Business-scoped AI Collections:**
- `geocodeCache/{addressHash}` — id, originalAddress (MASKED for privacy), latitude, longitude, placeId?, provider (google|openStreetMap|manual|imported), accuracy (rooftop|rangeInterpolated|geometricCenter|approximate|unknown), geocodedAt, expiresAt, timezone?, viewport? (NOTE: formattedAddress and addressComponents are NOT stored for HIPAA compliance)

## Indexes (composite)
Declare in `firestore.indexes.json` (single-field indexes are auto-managed).
- Appointments: providerId+startTime; clientId+startTime; isGroupSession+startTime; serviceId+startTime; locationId+startTime; status+startTime; (legacy admin) staffId+start; clientId+start.
- Appointment files: appointmentId+uploadedAt (for session materials ordered by upload time).
- Group sessions filters: publicVisibility+serviceId+startTime; publicVisibility+providerId+startTime; publicVisibility+locationId+startTime (for filtered client listings).
- Session notes: clientId+createdAt(desc); providerId+createdAt(desc); appointmentId+createdAt(desc); noteType+createdAt(desc).
- Waitlist: status+serviceId+providerId+createdAt; clientId+status+createdAt.
- Magic link tokens: token+businessId (if querying by token + tenant).
- Gift cards: code (unique lookup); status+expiresAt (expiration job); status+createdAt(desc) (admin listing); purchaserEmail+createdAt(desc) (purchaser lookup).
- Products: isActive+sortOrder+name (product listing); isActive+category+sortOrder+name (filtered by category); sku (unique lookup); barcode (unique lookup); isActive+trackInventory (inventory report).
- POS transactions: transactionDate(desc) (recent transactions); staffId+transactionDate(desc) (staff sales); clientId+transactionDate(desc) (client purchase history); appointmentId+transactionDate(desc) (appointment add-ons); paymentStatus+transactionDate(desc) (status filter); isVoided+transactionDate(desc) (active transactions); receiptNumber (receipt lookup).
- Time entries: staffId+clockInTime(desc) (staff timesheet); staffId+status (active entry lookup); status+clockInTime(desc) (admin pending approvals); staffId+clockInTime(asc) (date range queries).
- Tasks: assignedToProviderId+dueDate (provider's task list); assignedToProviderId+status (filtered task views); status+priority+dueDate (admin task management); linkedClientId+dueDate (client-linked tasks); linkedAppointmentId (appointment-linked tasks).
- Client risk scores: churnRiskScore(desc) (high risk clients); vipScore(desc) (VIP clients); calculatedAt(desc) (history ordering).
- Sentiment results: clientId+analyzedAt(desc) (client sentiment history); sourceDocumentId (source lookup); expiresAt (TTL cleanup).
- Optimized routes: providerId+routeDate (provider's daily route); status+routeDate (route listing by status).
- Join codes: codeHash+status (COLLECTION_GROUP for cross-business hash lookup in join flow); status+expiresAt (expiration cleanup job); status+createdAt(desc) (admin listing).
- Invites: tokenHash+status (COLLECTION_GROUP for cross-business hash lookup in accept flow); email+status (check existing invites); status+expiresAt (expiration cleanup job); status+createdAt(desc) (admin listing).
- Join requests: status+createdAt(asc) (admin pending approvals); requestorUserId+createdAt(desc) (user request history).

## Seeds
- Mobile: `functions/src/seed.ts`
- Admin: `scripts/seed-firestore.mjs`
Both seeds now write the same paths/field names; run with `BUSINESS_ID`, `ADMIN_UID`, `ADMIN_EMAIL`, `ADMIN_NAME`, and `GOOGLE_APPLICATION_CREDENTIALS` set.

## Deploy
- Functions: deploy from **The Scheduler** (mobile) repo
  ```bash
  cd The\ Scheduler
  firebase deploy --only functions --project <your-project>
  ```
- Rules/indexes: deploy from **The Scheduler** (source of truth for Firestore config)
  ```bash
  cd The\ Scheduler
  firebase deploy --only firestore:rules,firestore:indexes --project <your-project>
  ```

## AI Services API Contracts

### Route Optimization Service (`ai_server/routing`)

**Base URL:** Configured via `AIConfig.routeOptimizationUrl`

**Authentication:** `X-API-Key` header required in production

#### POST `/api/v1/routes/optimize`

**Request:**
```json
{
  "business_id": "string",
  "provider_id": "string",
  "route_date": "ISO8601 datetime",
  "depot_latitude": "float [-90, 90]",
  "depot_longitude": "float [-180, 180]",
  "depot_address": "string",
  "return_to_depot": "boolean (default: true)",
  "waypoints": [{
    "id": "string",
    "name": "string",
    "latitude": "float",
    "longitude": "float",
    "window_start": "ISO8601 datetime",
    "window_end": "ISO8601 datetime",
    "service_duration_minutes": "int",
    "priority": "int [1-10] (default: 1)",
    "client_id": "string?",
    "appointment_id": "string?"
  }],
  "earliest_departure": "ISO8601 datetime",
  "latest_return": "ISO8601 datetime",
  "objective": "minimizeTime|minimizeDistance|balanced (default: minimizeTime)",
  "buffer_between_stops_minutes": "int (default: 5)"
}
```

**Response:**
```json
{
  "id": "route_xxx",
  "business_id": "string",
  "provider_id": "string",
  "status": "planned|partial|optimizationFailed",
  "stops": [{
    "id": "string",
    "sequence_order": "int",
    "stop_type": "depot|appointment|breakStop|endDepot",
    "scheduled_arrival": "ISO8601 datetime",
    "travel_to_next_minutes": "int?"
  }],
  "total_distance_meters": "int",
  "total_travel_time_seconds": "int",
  "time_saved_seconds": "int",
  "optimization_improvement_percent": "float"
}
```

**Errors:** 401 (auth), 400 (validation), 500 (server)

---

## Coordination Rules
- When adding/modifying fields, update: models/types, seeds, README data contract (this file), and indexes (if queries change).
- Keep path names consistent (e.g., `providers/` not `staff/`, `intakeFormTemplates/` not `intake_forms/`, nested `clients/{id}/files/` for attachments).
- If admin needs legacy paths, mirror them explicitly in seeds until UI is migrated.
