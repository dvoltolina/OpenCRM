import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const BUSINESS_ID = process.env.BUSINESS_ID || 'test-business';
const ADMIN_UID = process.env.ADMIN_UID;
const ADMIN_EMAIL = process.env.ADMIN_EMAIL;
const ADMIN_NAME = process.env.ADMIN_NAME || 'Owner';

if (!ADMIN_UID || !ADMIN_EMAIL) {
  console.error('Set ADMIN_UID and ADMIN_EMAIL env vars before running the seed script.');
  process.exit(1);
}

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.warn(
    'Tip: export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json before running.',
  );
}

initializeApp({
  credential: applicationDefault(),
});

const db = getFirestore();
const now = () => new Date();
const dateOnly = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());

async function seed() {
  console.log(`Seeding Firestore for business '${BUSINESS_ID}'...`);

  const clientId = 'client-demo';
  const providerId = ADMIN_UID; // mirror as staff for admin UI compatibility
  const staffId = providerId;
  const serviceId = 'svc-consult';
  const appointmentId = 'apt-demo';
  const groupAppointmentId = 'apt-group-demo';
  const waitlistId = 'wait-1';
  const paymentId = 'pay-1';
  const locationId = 'loc-main';
  const resourceId = 'res-room-1';
  const maintenanceLogId = 'maint-1';
  const templateId = 'template-intake';
  const submissionId = 'submission-1';
  const draftId = 'draft-1';
  const sessionNoteId = 'note-1';
  const fileId = 'file-1';
  const magicLinkId = 'magic-1';
  const modificationRequestId = 'modreq-1';
  const weeklyScheduleId = 'weekly-1';
  const availabilityId = 'avail-1';
  const integrationId = 'int-google';
  const messageTemplateId = 'tmpl-booking';
  const automationRuleId = 'auto-booking';
  const messageHistoryId = 'msg-1';

  const start = now();
  const end = new Date(start.getTime() + 60 * 60 * 1000);
  const date = dateOnly(start);
  const groupStart = new Date(Date.now() + 24 * 60 * 60 * 1000);
  const groupEnd = new Date(groupStart.getTime() + 60 * 60 * 1000);
  const batch = db.batch();

  // User profile
  batch.set(
    db.doc(`users/${ADMIN_UID}`),
    {
      businessId: BUSINESS_ID,
      role: 'owner',
      displayName: ADMIN_NAME,
      email: ADMIN_EMAIL,
      createdAt: now(),
      providerId: providerId,
    },
    { merge: true },
  );

  // Business root doc
  batch.set(
    db.doc(`businesses/${BUSINESS_ID}`),
    {
      name: `${ADMIN_NAME}'s Business`,
      createdAt: now(),
      updatedAt: now(),
      contactEmail: ADMIN_EMAIL,
    },
    { merge: true },
  );

  // Providers (mobile) and staff (admin)
  const providerDoc = {
    id: providerId,
    businessId: BUSINESS_ID,
    firstName: ADMIN_NAME,
    lastName: 'Owner',
    displayName: `${ADMIN_NAME} Owner`,
    email: ADMIN_EMAIL,
    phone: '555-0200',
    serviceIds: [serviceId],
    locationIds: [locationId],
    colorHex: '4285F4',
    role: 'owner',
    status: 'active',
    createdAt: now(),
  };
  batch.set(db.doc(`businesses/${BUSINESS_ID}/providers/${providerId}`), providerDoc);

  // Client
  batch.set(db.doc(`businesses/${BUSINESS_ID}/clients/${clientId}`), {
    id: clientId,
    businessId: BUSINESS_ID,
    firstName: 'Demo',
    lastName: 'Client',
    email: 'client@example.com',
    phone: '555-0100',
    createdAt: now(),
    lifecycle: 'newClient',
    tags: ['demo'],
  });

  // Service
  batch.set(db.doc(`businesses/${BUSINESS_ID}/services/${serviceId}`), {
    id: serviceId,
    businessId: BUSINESS_ID,
    name: 'Initial Consultation',
    durationMinutes: 60,
    price: 150,
    category: 'General',
    providerIds: [providerId],
    requiredResources: [resourceId],
    bufferMinutes: 10,
    isActive: true,
    createdAt: now(),
  });

  // Location
  batch.set(db.doc(`businesses/${BUSINESS_ID}/locations/${locationId}`), {
    id: locationId,
    businessId: BUSINESS_ID,
    name: 'Main Location',
    address: '123 Demo St',
    city: 'New York',
    state: 'NY',
    zipCode: '10001',
    timezone: 'America/New_York',
    createdAt: now(),
  });

  // Resource + maintenance
  batch.set(db.doc(`businesses/${BUSINESS_ID}/resources/${resourceId}`), {
    id: resourceId,
    businessId: BUSINESS_ID,
    name: 'Room 1',
    type: 'room',
    locationId,
    capacity: 1,
    isActive: true,
    createdAt: now(),
    maintenanceSchedule: [],
    description: 'Primary consult room',
  });

  batch.set(db.doc(`businesses/${BUSINESS_ID}/resourceMaintenanceLogs/${maintenanceLogId}`), {
    id: maintenanceLogId,
    resourceId,
    note: 'Initial setup',
    status: 'available',
    createdBy: ADMIN_NAME,
    createdAt: now(),
  });

  // Weekly schedule + availability
  batch.set(db.doc(`businesses/${BUSINESS_ID}/weekly_schedules/${weeklyScheduleId}`), {
    id: weeklyScheduleId,
    providerId,
    locationId,
    dayOfWeek: 'monday',
    timeBlocks: [
      { startHour: 9, startMinute: 0, endHour: 12, endMinute: 0 },
      { startHour: 13, startMinute: 0, endHour: 17, endMinute: 0 },
    ],
    isActive: true,
    createdAt: now(),
    updatedAt: now(),
  });

  batch.set(db.doc(`businesses/${BUSINESS_ID}/availability/${availabilityId}`), {
    id: availabilityId,
    providerId,
    locationId,
    startTime: start,
    endTime: end,
    type: 'available',
    reason: 'Demo availability block',
    specificDate: date,
    createdAt: now(),
    updatedAt: now(),
  });

  // Appointments (1:1 + group)
  batch.set(db.doc(`businesses/${BUSINESS_ID}/appointments/${appointmentId}`), {
    id: appointmentId,
    businessId: BUSINESS_ID,
    clientId,
    providerId,
    serviceId,
    locationId,
    startTime: start,
    endTime: end,
    date,
    status: 'confirmed',
    isGroupSession: false,
    attendeeIds: [],
    createdAt: now(),
    // Admin UI compatibility
    staffId: providerId,
    start: start.toISOString(),
    end: end.toISOString(),
  });

  batch.set(db.doc(`businesses/${BUSINESS_ID}/appointments/${groupAppointmentId}`), {
    id: groupAppointmentId,
    businessId: BUSINESS_ID,
    clientId,
    providerId,
    serviceId,
    locationId,
    startTime: groupStart,
    endTime: groupEnd,
    date: dateOnly(groupStart),
    status: 'confirmed',
    isGroupSession: true,
    capacity: 10,
    attendeeIds: [clientId],
    createdAt: now(),
    staffId: providerId,
    start: groupStart.toISOString(),
    end: groupEnd.toISOString(),
  });

  // Waitlist
  batch.set(db.doc(`businesses/${BUSINESS_ID}/waitlist_entries/${waitlistId}`), {
    id: waitlistId,
    businessId: BUSINESS_ID,
    clientId,
    clientName: 'Demo Client',
    serviceId,
    serviceName: 'Initial Consultation',
    providerId,
    providerName: ADMIN_NAME,
    locationId,
    earliestDate: date,
    latestDate: new Date(date.getTime() + 7 * 24 * 60 * 60 * 1000),
    priorityScore: 0.5,
    notificationPreference: 'email',
    status: 'active',
    preferredDaysOfWeek: [1, 2, 3, 4, 5],
    timeOfDayPreferences: ['morning', 'afternoon'],
    createdAt: now(),
    updatedAt: now(),
    notes: 'Prefers mornings',
    // Admin UI compatibility
    preferredStart: null,
    preferredEnd: null,
    priority: 'standard',
    notificationChannel: 'email',
  });

  // Payments
  batch.set(db.doc(`businesses/${BUSINESS_ID}/payments/${paymentId}`), {
    id: paymentId,
    businessId: BUSINESS_ID,
    appointmentId,
    clientId,
    amountCents: 15000,
    currency: 'USD',
    status: 'completed',
    type: 'full',
    createdAt: now(),
    // Admin UI compatibility
    amount: 150,
    statusLegacy: 'succeeded',
    currencyLegacy: 'usd',
  });

  // Intake templates/submissions/drafts
  batch.set(db.doc(`businesses/${BUSINESS_ID}/intakeFormTemplates/${templateId}`), {
    id: templateId,
    businessId: BUSINESS_ID,
    name: 'New Patient Intake',
    description: 'Basic intake form',
    fields: [
      { id: 'reason', label: 'Reason for visit', type: 'text', required: true },
      { id: 'consent', label: 'I consent to treatment', type: 'checkbox', required: true },
    ],
    applicableIndustries: ['therapy'],
    isActive: true,
    createdAt: now(),
    updatedAt: now(),
    version: 1,
  });

  batch.set(db.doc(`businesses/${BUSINESS_ID}/intakeFormSubmissions/${submissionId}`), {
    id: submissionId,
    businessId: BUSINESS_ID,
    clientId,
    templateId,
    templateName: 'New Patient Intake',
    templateVersion: 1,
    responses: {
      reason: 'Consultation',
      consent: 'true',
    },
    status: 'submitted',
    submittedAt: now(),
    createdAt: now(),
    updatedAt: now(),
  });

  batch.set(db.doc(`businesses/${BUSINESS_ID}/intakeFormDrafts/${draftId}`), {
    id: draftId,
    businessId: BUSINESS_ID,
    templateId,
    clientId,
    responses: { reason: 'Draft reason' },
    status: 'draft',
    createdAt: now(),
    updatedAt: now(),
    expiresAt: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
    attachments: [],
  });

  // Session notes
  batch.set(db.doc(`businesses/${BUSINESS_ID}/session_notes/${sessionNoteId}`), {
    id: sessionNoteId,
    businessId: BUSINESS_ID,
    clientId,
    providerId,
    appointmentId,
    noteType: 'progressNote',
    visibility: 'providerOnly',
    encryptedContent: 'encrypted-note-placeholder',
    title: 'Initial session note',
    tags: ['initial'],
    isLocked: false,
    createdAt: now(),
    updatedAt: now(),
    createdBy: ADMIN_UID,
    createdByName: ADMIN_NAME,
    retainIndefinitely: false,
    isPsychotherapyNote: false,
    auditLog: [
      {
        id: 'audit-1',
        action: 'created',
        userId: ADMIN_UID,
        userFullName: ADMIN_NAME,
        timestamp: now(),
      },
    ],
    // Legacy/admin-only fields
    providerName: ADMIN_NAME,
    date: start,
  });

  // File attachment (nested path) + legacy root for admin UI
  const fileDoc = {
    id: fileId,
    businessId: BUSINESS_ID,
    clientId,
    name: 'example.pdf',
    fileName: 'example.pdf',
    contentType: 'application/pdf',
    fileType: 'application/pdf',
    sizeBytes: 12345,
    fileSize: 12345,
    storagePath: 'businesses/test-business/clients/client-demo/files/file-1',
    storageUrl: 'https://storage.googleapis.com/example-bucket/example.pdf',
    downloadUrl: 'https://storage.googleapis.com/example-bucket/example.pdf',
    uploadedBy: providerId,
    uploaderId: providerId,
    uploadedAt: now(),
    accessLevel: 'clientOnly',
    isSensitive: false,
    metadata: {},
    category: 'general',
    notes: 'Sample upload',
  };
  batch.set(
    db.doc(`businesses/${BUSINESS_ID}/clients/${clientId}/files/${fileId}`),
    fileDoc,
  );

  // Magic link tokens
  batch.set(db.doc(`businesses/${BUSINESS_ID}/magic_link_tokens/${magicLinkId}`), {
    id: magicLinkId,
    businessId: BUSINESS_ID,
    appointmentId,
    clientId,
    clientEmail: 'client@example.com',
    token: 'demo-token-string',
    createdAt: now(),
    expiresAt: new Date(Date.now() + 48 * 60 * 60 * 1000),
    hasBeenUsed: false,
    accessCount: 0,
    status: 'active',
  });

  // Modification requests
  batch.set(db.doc(`businesses/${BUSINESS_ID}/modification_requests/${modificationRequestId}`), {
    id: modificationRequestId,
    businessId: BUSINESS_ID,
    appointmentId,
    clientId,
    providerId,
    type: 'reschedule',
    status: 'pending',
    requestedStartTime: new Date(start.getTime() + 2 * 24 * 60 * 60 * 1000),
    requestedDurationMinutes: 60,
    reason: 'Schedule conflict',
    policyWindowBreached: false,
    feeRequired: false,
    feeCollected: false,
    requestedByName: 'Demo Client',
    requestedByEmail: 'client@example.com',
    createdAt: now(),
    updatedAt: now(),
  });

  // Integrations + tokens + staff preferences
  batch.set(db.doc(`businesses/${BUSINESS_ID}/integrations/${integrationId}`), {
    id: integrationId,
    businessId: BUSINESS_ID,
    provider: 'googleCalendar',
    status: 'connected',
    scopes: ['calendar.read', 'calendar.write'],
    displayName: ADMIN_NAME,
    email: ADMIN_EMAIL,
    connectedAt: now(),
    lastSyncAt: now(),
  });

  batch.set(db.doc(`businesses/${BUSINESS_ID}/integrations/${integrationId}/tokens/oauth`), {
    integrationId,
    accessToken: 'encrypted-access-token',
    refreshToken: 'encrypted-refresh-token',
    expiresAt: new Date(Date.now() + 60 * 60 * 1000),
  });

  batch.set(db.doc(`businesses/${BUSINESS_ID}/staff_integrations/${staffId}`), {
    staffId,
    calendarProvider: 'googleCalendar',
    telehealthProvider: 'zoom',
  });

  // Message templates, automation, history
  batch.set(db.doc(`businesses/${BUSINESS_ID}/message_templates/${messageTemplateId}`), {
    id: messageTemplateId,
    businessId: BUSINESS_ID,
    channel: 'email',
    type: 'booking_confirmation',
    subject: 'Your appointment is booked',
    body: 'Thanks for booking. See you soon!',
  });

  batch.set(db.doc(`businesses/${BUSINESS_ID}/automation_rules/${automationRuleId}`), {
    id: automationRuleId,
    businessId: BUSINESS_ID,
    type: 'booking_confirmation',
    enabled: true,
    emailEnabled: true,
    smsEnabled: false,
    timingMinutes: 60,
    templateId: messageTemplateId,
  });

  batch.set(db.doc(`businesses/${BUSINESS_ID}/message_history/${messageHistoryId}`), {
    id: messageHistoryId,
    businessId: BUSINESS_ID,
    clientId,
    appointmentId,
    channel: 'email',
    type: 'booking_confirmation',
    recipient: ADMIN_EMAIL,
    status: 'sent',
    sentAt: now(),
    subject: 'Your appointment is booked',
    body: 'Confirmation message body',
  });

  // Subscription
  batch.set(db.doc(`businesses/${BUSINESS_ID}/subscriptions/current`), {
    id: 'current',
    businessId: BUSINESS_ID,
    status: 'active',
    planId: 'pro',
    currentPeriodStart: now(),
    currentPeriodEnd: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    cancelAtPeriodEnd: false,
    usage: {
      providers: 1,
      locations: 1,
      clients: 1,
      appointmentsThisMonth: 1,
      smsThisMonth: 0,
    },
    createdAt: now(),
    updatedAt: now(),
  });

  // Feature flags
  batch.set(
    db.doc(`businesses/${BUSINESS_ID}/settings/feature_flags`),
    {
      enableCalendarSync: true,
      enableTelehealth: true,
      enableAutomatedReminders: true,
      enablePayments: true,
      enableReporting: true,
      enableWaitlist: true,
      enableLocations: true,
      enableResources: true,
      enableResourceConflicts: true,
      enableClientPortal: true,
      enableSessionNotes: true,
      enableMarketing: false,
      waitlistNotifyChannels: ['sms', 'email'],
    },
    { merge: true },
  );

  await batch.commit();
  console.log('Seed complete.');
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
