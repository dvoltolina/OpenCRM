import { SYSTEM_REPORTS, createReportDefinitionFromSystem } from '../../src/data/system-reports';
import {
  BUSINESS_ID,
  OWNER_NAME,
  OWNER_UID,
  addDocument,
  clientNames,
  companySeeds,
  fullName,
  pipelineIds,
  reportIdAt,
  shareable,
  shiftDate,
  stages,
  staffMembers,
  templateIds,
  type DocEntry,
} from './common';

export function buildCrmAndAdminDocuments(docs: DocEntry[]): void {
  companySeeds.forEach((company, index) => {
    const companyId = 'company-demo-' + String(index + 1).padStart(2, '0');
    addDocument(docs, 'companies', 'businesses/' + BUSINESS_ID + '/companies/' + companyId, {
      id: companyId,
      name: company[0],
      industry: company[1],
      size: company[2],
      website: 'https://' + company[0].toLowerCase().replace(/[^a-z0-9]+/g, '-') + '.demo.example.com',
      phone: '555-02' + String(index).padStart(2, '0'),
      email: 'hello+' + String(index + 1).padStart(2, '0') + '@demo.example.com',
      address: {
        street: String(400 + index) + ' Demo Commerce Way',
        city: 'Sample City',
        state: 'CO',
        zipCode: '801' + String(index).padStart(2, '0'),
        country: 'USA',
      },
      notes: 'Demo company profile for sales pipeline previews.',
      tags: index % 2 === 0 ? ['demo', 'priority'] : ['demo'],
      customFields: { tier: index % 3 === 0 ? 'enterprise' : 'growth' },
      createdAt: shiftDate(-75 + index, 11),
      updatedAt: new Date(),
      ...shareable(index, index % 3 === 0 ? 'org' : 'team'),
    });
  });

  addDocument(docs, 'pipelines', 'businesses/' + BUSINESS_ID + '/pipelines/' + pipelineIds[0], {
    id: pipelineIds[0],
    name: 'New Business Pipeline',
    isDefault: true,
    isActive: true,
    createdAt: shiftDate(-90, 8),
    updatedAt: new Date(),
    ...shareable(0, 'org'),
  });
  addDocument(docs, 'pipelines', 'businesses/' + BUSINESS_ID + '/pipelines/' + pipelineIds[1], {
    id: pipelineIds[1],
    name: 'Partnership Expansion',
    isDefault: false,
    isActive: true,
    createdAt: shiftDate(-70, 8),
    updatedAt: new Date(),
    ...shareable(5, 'team'),
  });

  stages.forEach((stage, index) => {
    addDocument(docs, 'stages', 'businesses/' + BUSINESS_ID + '/stages/' + stage.id, {
      id: stage.id,
      pipelineId: stage.pipelineId,
      name: stage.name,
      order: stage.order,
      colorHex: stage.colorHex,
      probability: stage.probability,
      isActive: true,
      createdAt: shiftDate(-88 + index, 9),
      updatedAt: new Date(),
      ...shareable(index),
    });
  });

  for (let index = 0; index < 18; index += 1) {
    const leadId = 'lead-demo-' + String(index + 1).padStart(2, '0');
    const converted = index < 4;
    const assignee = staffMembers[index % staffMembers.length];
    addDocument(docs, 'leads', 'businesses/' + BUSINESS_ID + '/leads/' + leadId, {
      id: leadId,
      firstName: 'Lead',
      lastName: 'Demo ' + String(index + 1).padStart(2, '0'),
      email: 'lead' + String(index + 1).padStart(2, '0') + '@demo.example.com',
      phone: '555-06' + String(index).padStart(2, '0'),
      companyName: companySeeds[index % companySeeds.length][0],
      title: index % 2 === 0 ? 'Operations Director' : 'Revenue Lead',
      status: converted ? 'converted' : ['new', 'contacted', 'qualified', 'unqualified'][index % 4],
      source: ['website', 'referral', 'coldCall', 'social', 'event', 'scheduler'][index % 6],
      score: 52 + (index % 6) * 7,
      assigneeId: assignee.id,
      assigneeName: fullName(assignee.firstName, assignee.lastName),
      tags: index % 3 === 0 ? ['demo', 'high-fit'] : ['demo'],
      notes: 'Fake lead record for public demo evaluation.',
      customFields: { demoTier: index % 2 === 0 ? 'inbound' : 'outbound' },
      convertedToClientId: converted ? 'client-demo-' + String((index % clientNames.length) + 1).padStart(2, '0') : undefined,
      convertedToDealId: converted ? 'deal-demo-' + String(index + 1).padStart(2, '0') : undefined,
      convertedAt: converted ? shiftDate(-20 + index, 13) : undefined,
      createdAt: shiftDate(-45 + index, 10),
      updatedAt: new Date(),
      ...shareable(index),
    });
  }

  for (let index = 0; index < 14; index += 1) {
    const dealId = 'deal-demo-' + String(index + 1).padStart(2, '0');
    const pipelineId = index < 10 ? pipelineIds[0] : pipelineIds[1];
    const stageId =
      pipelineId === pipelineIds[0]
        ? ['stage-sales-01', 'stage-sales-02', 'stage-sales-03', 'stage-sales-04', 'stage-sales-05', 'stage-sales-06'][index % 6]
        : ['stage-partner-01', 'stage-partner-02', 'stage-partner-03', 'stage-partner-04'][index % 4];
    const matchedStage = stages.find((stage) => stage.id === stageId);
    const status =
      stageId === 'stage-sales-05' || stageId === 'stage-partner-04'
        ? 'won'
        : stageId === 'stage-sales-06'
          ? 'lost'
          : 'open';
    const assignee = staffMembers[(index + 1) % staffMembers.length];
    addDocument(docs, 'deals', 'businesses/' + BUSINESS_ID + '/deals/' + dealId, {
      id: dealId,
      pipelineId,
      stageId,
      title: companySeeds[index % companySeeds.length][0] + ' Demo Expansion',
      valueCents: 450000 + index * 85000,
      currency: 'USD',
      probability: matchedStage ? matchedStage.probability : 25,
      expectedCloseDate: shiftDate(index - 3, 12),
      status,
      wonLostReason: status === 'lost' ? 'Demo competitor pricing scenario.' : status === 'won' ? 'Demo proposal accepted.' : undefined,
      closedAt: status === 'open' ? undefined : shiftDate(-8 + index, 16),
      clientId: 'client-demo-' + String(index + 1).padStart(2, '0'),
      clientName: clientNames[index][0] + ' ' + clientNames[index][1],
      companyId: 'company-demo-' + String((index % companySeeds.length) + 1).padStart(2, '0'),
      companyName: companySeeds[index % companySeeds.length][0],
      assigneeId: assignee.id,
      assigneeName: fullName(assignee.firstName, assignee.lastName),
      tags: status === 'won' ? ['demo', 'won'] : ['demo'],
      notes: 'Demo opportunity for reporting and pipeline previews.',
      customFields: { package: index % 2 === 0 ? 'retainer' : 'pilot' },
      createdAt: shiftDate(-35 + index, 11),
      updatedAt: new Date(),
      ...shareable(index, index % 4 === 0 ? 'org' : 'team'),
    });
  }

  for (let index = 0; index < 40; index += 1) {
    const activityId = 'activity-demo-' + String(index + 1).padStart(2, '0');
    const type = ['call', 'email', 'meeting', 'note', 'task'][index % 5];
    const assignee = staffMembers[index % staffMembers.length];
    addDocument(docs, 'sales_activities', 'businesses/' + BUSINESS_ID + '/sales_activities/' + activityId, {
      id: activityId,
      type,
      title: ['Follow-up touchpoint', 'Proposal check-in', 'Discovery recap', 'Pipeline note', 'Next-step task'][index % 5],
      description: 'Demo activity seeded for timeline and productivity views.',
      dealId: 'deal-demo-' + String((index % 14) + 1).padStart(2, '0'),
      clientId: 'client-demo-' + String((index % clientNames.length) + 1).padStart(2, '0'),
      leadId: 'lead-demo-' + String((index % 18) + 1).padStart(2, '0'),
      companyId: 'company-demo-' + String((index % companySeeds.length) + 1).padStart(2, '0'),
      dueDate: type === 'task' || type === 'meeting' ? shiftDate((index % 9) - 4, 13) : undefined,
      isCompleted: index % 3 !== 0,
      completedAt: index % 3 !== 0 ? shiftDate(-1 * ((index % 12) + 1), 15) : undefined,
      assigneeId: assignee.id,
      assigneeName: fullName(assignee.firstName, assignee.lastName),
      createdById: OWNER_UID,
      createdByName: OWNER_NAME,
      createdAt: shiftDate(-30 + (index % 20), 9 + (index % 6)),
      updatedAt: new Date(),
      ...shareable(index),
    });
  }

  const intakeTemplates = [
    { id: 'intake-demo-001', name: 'New Client Demo Intake', description: 'Baseline profile capture for the public demo.', applicableIndustries: ['wellness', 'consulting'] },
    { id: 'intake-demo-002', name: 'Demo Strategy Prep Form', description: 'Pre-session form for planning engagements.', applicableIndustries: ['consulting', 'agency'] },
    { id: 'intake-demo-003', name: 'Demo Membership Check-In', description: 'Recurring customer success check-in template.', applicableIndustries: ['wellness', 'fitness'] },
  ];
  intakeTemplates.forEach((template, index) => {
    addDocument(docs, 'intakeFormTemplates', 'businesses/' + BUSINESS_ID + '/intakeFormTemplates/' + template.id, {
      id: template.id,
      businessId: BUSINESS_ID,
      name: template.name,
      description: template.description,
      fields: [
        { id: 'field-name', type: 'text', label: 'Full name', required: true },
        { id: 'field-email', type: 'text', label: 'Email address', required: true },
        { id: 'field-goal', type: 'textarea', label: 'Primary goal', required: true },
        { id: 'field-consent', type: 'checkbox', label: 'Agree to demo terms', required: true, options: ['Yes'] },
      ],
      applicableIndustries: template.applicableIndustries,
      isActive: true,
      version: 1,
      createdAt: shiftDate(-40 + index, 9),
      updatedAt: new Date(),
    });
  });

  [
    { id: templateIds[0], channel: 'email', type: 'follow_up', subject: 'Demo follow-up', body: 'Thanks for exploring the demo. Your placeholder next step is ready.' },
    { id: templateIds[1], channel: 'email', type: 'proposal', subject: 'Demo proposal ready', body: 'Your fake proposal preview is ready for review.' },
    { id: templateIds[2], channel: 'sms', type: 'reminder', body: 'Demo reminder: your placeholder session starts soon.' },
    { id: templateIds[3], channel: 'email', type: 'reengagement', subject: 'Demo reactivation note', body: 'We saved a demo follow-up slot for you this week.' },
  ].forEach((template, index) => {
    addDocument(docs, 'message_templates', 'businesses/' + BUSINESS_ID + '/message_templates/' + template.id, {
      id: template.id,
      businessId: BUSINESS_ID,
      channel: template.channel,
      type: template.type,
      subject: template.subject,
      body: template.body,
      createdAt: shiftDate(-25 + index, 11),
      updatedAt: new Date(),
    });
  });

  [
    {
      id: 'automation-rule-demo-001',
      name: 'Lead Welcome Demo',
      trigger: { type: 'leadCreated' },
      action: { type: 'sendEmailTemplate', target: 'lead', emailTemplate: { templateId: templateIds[0], recipient: 'lead' } },
    },
    {
      id: 'automation-rule-demo-002',
      name: 'Proposal Stage Task Demo',
      trigger: { type: 'dealStageChanged', toStageId: 'stage-sales-03' },
      action: { type: 'createTask', target: 'deal', taskTemplate: { title: 'Review demo proposal', dueInDays: 2, assigneeId: 'demo-user-002', assigneeName: 'Jordan Sample', activityType: 'task' } },
    },
    {
      id: 'automation-rule-demo-003',
      name: 'Overdue Task Follow-Up Demo',
      trigger: { type: 'taskOverdue', overdueDays: 2 },
      action: { type: 'addTag', target: 'activity', tag: 'needs-demo-review' },
    },
    {
      id: 'automation-rule-demo-004',
      name: 'Won Deal Reengagement Demo',
      trigger: { type: 'dealStageChanged', toStageId: 'stage-sales-05' },
      action: { type: 'sendEmailTemplate', target: 'deal', emailTemplate: { templateId: templateIds[3], recipient: 'client' } },
    },
  ].forEach((rule, index) => {
    addDocument(docs, 'automation_rules', 'businesses/' + BUSINESS_ID + '/automation_rules/' + rule.id, {
      id: rule.id,
      name: rule.name,
      description: 'Read-only demo automation rule.',
      trigger: rule.trigger,
      action: rule.action,
      status: 'enabled',
      ownerId: OWNER_UID,
      ownerName: OWNER_NAME,
      teamIds: ['team-sales'],
      visibility: 'org',
      createdById: OWNER_UID,
      createdByName: OWNER_NAME,
      businessId: BUSINESS_ID,
      lastRunAt: shiftDate(-6 + index, 8),
      createdAt: shiftDate(-18 + index, 10),
      updatedAt: new Date(),
    });
  });

  addDocument(docs, 'settings', 'businesses/' + BUSINESS_ID + '/settings/feature_flags', {
    enableCalendarSync: false,
    enableTelehealth: false,
    enableAutomatedReminders: true,
    enablePayments: true,
    enableReporting: true,
    enableImportExport: false,
    enableAutomation: true,
    enableWaitlist: true,
    enableLocations: true,
    enableResources: true,
    enableResourceConflicts: true,
    enableClientPortal: false,
    enableSessionNotes: false,
    enableMarketing: false,
    enableIntakeBuilder: true,
    waitlistNotifyChannels: ['email'],
    updatedAt: new Date(),
  });

  addDocument(docs, 'settings', 'businesses/' + BUSINESS_ID + '/settings/crm', {
    defaultPipelineId: pipelineIds[0],
    defaultCurrency: 'USD',
    leadScoringEnabled: true,
    leadScoringRules: [{ field: 'source', value: 'referral', boost: 10 }],
    dealRotting: { enabled: true, thresholdDays: 14 },
    updatedAt: new Date(),
  });

  [
    {
      id: 'sequence-demo-001',
      name: 'Inbound Demo Welcome',
      description: 'Three-step fake sequence for inbound leads.',
      status: 'active',
      steps: [
        { id: 'seq-1-step-1', order: 0, type: 'email', delayDays: 0, isActive: true, emailConfig: { templateId: templateIds[0] } },
        { id: 'seq-1-step-2', order: 1, type: 'task', delayDays: 2, isActive: true, taskConfig: { title: 'Demo follow-up call', assignToOwner: true, dueDays: 1 } },
        { id: 'seq-1-step-3', order: 2, type: 'wait', delayDays: 4, isActive: true },
      ],
      stats: { totalEnrolled: 18, activeEnrollments: 9, completedCount: 6, exitedCount: 3, replyRate: 22, openRate: 57 },
      ownerId: 'demo-user-002',
      ownerName: 'Jordan Sample',
      teamIds: ['team-sales'],
      visibility: 'team',
    },
    {
      id: 'sequence-demo-002',
      name: 'Demo Proposal Nudges',
      description: 'Proposal-stage outreach with email and call reminders.',
      status: 'active',
      steps: [
        { id: 'seq-2-step-1', order: 0, type: 'email', delayDays: 0, isActive: true, emailConfig: { templateId: templateIds[1] } },
        { id: 'seq-2-step-2', order: 1, type: 'call_reminder', delayDays: 3, isActive: true, callConfig: { title: 'Demo proposal check-in' } },
        { id: 'seq-2-step-3', order: 2, type: 'sms', delayDays: 5, isActive: true, smsConfig: { templateId: templateIds[2] } },
      ],
      stats: { totalEnrolled: 11, activeEnrollments: 4, completedCount: 5, exitedCount: 2, replyRate: 18, openRate: 49 },
      ownerId: 'demo-user-003',
      ownerName: 'Quinn Preview',
      teamIds: ['team-sales'],
      visibility: 'team',
    },
    {
      id: 'sequence-demo-003',
      name: 'Partnership Demo Reactivation',
      description: 'Paused partnership outreach sample for the demo workspace.',
      status: 'paused',
      steps: [
        { id: 'seq-3-step-1', order: 0, type: 'email', delayDays: 0, isActive: true, emailConfig: { templateId: templateIds[3] } },
        { id: 'seq-3-step-2', order: 1, type: 'wait', delayDays: 7, isActive: true },
        { id: 'seq-3-step-3', order: 2, type: 'task', delayDays: 8, isActive: true, taskConfig: { title: 'Review demo reactivation account', assignToOwner: false, dueDays: 2 } },
      ],
      stats: { totalEnrolled: 7, activeEnrollments: 2, completedCount: 3, exitedCount: 2, replyRate: 14, openRate: 41 },
      ownerId: 'demo-user-006',
      ownerName: 'Parker Mock',
      teamIds: ['team-partnerships'],
      visibility: 'team',
    },
  ].forEach((sequence, index) => {
    addDocument(docs, 'sequences', 'businesses/' + BUSINESS_ID + '/sequences/' + sequence.id, {
      id: sequence.id,
      name: sequence.name,
      description: sequence.description,
      status: sequence.status,
      steps: sequence.steps,
      settings: {
        sendingSchedule: { timezone: 'America/Denver', businessHoursOnly: true, startHour: 9, endHour: 17, excludeDays: [0, 6] },
        dailyEmailLimit: 25,
        maxEnrollmentsPerDay: 10,
        pauseOnReply: true,
        pauseOnOpen: false,
        trackOpens: true,
        trackClicks: true,
        pauseOnMeetingBooked: true,
        removeOnUnsubscribe: true,
        threadEmails: true,
      },
      enrollmentCriteria: { entityType: 'lead', conditions: [{ field: 'status', operator: 'equals', value: 'qualified' }], autoEnroll: index !== 2 },
      exitCriteria: { onReply: true, onMeetingBooked: true, onDealWon: true, onDealLost: true, onLeadConverted: true, onManualRemoval: true },
      stats: sequence.stats,
      ownerId: sequence.ownerId,
      ownerName: sequence.ownerName,
      teamIds: sequence.teamIds,
      visibility: sequence.visibility,
      createdAt: shiftDate(-20 + index, 9),
      updatedAt: new Date(),
    });
  });

  [
    { id: 'goal-demo-001', metric: 'revenue', targetValue: 3500000, currentValue: 2240000, progressPercent: 64, assigneeType: 'business', assigneeId: BUSINESS_ID, assigneeName: 'OpenCRM Demo Workspace', period: 'monthly' },
    { id: 'goal-demo-002', metric: 'deals_won', targetValue: 12, currentValue: 8, progressPercent: 67, assigneeType: 'user', assigneeId: 'demo-user-002', assigneeName: 'Jordan Sample', period: 'monthly' },
    { id: 'goal-demo-003', metric: 'activities_completed', targetValue: 90, currentValue: 74, progressPercent: 82, assigneeType: 'team', assigneeId: 'team-sales', assigneeName: 'Sales Team', period: 'quarterly' },
    { id: 'goal-demo-004', metric: 'emails_sent', targetValue: 120, currentValue: 38, progressPercent: 32, assigneeType: 'user', assigneeId: 'demo-user-006', assigneeName: 'Parker Mock', period: 'monthly' },
  ].forEach((goal, index) => {
    addDocument(docs, 'goals', 'businesses/' + BUSINESS_ID + '/goals/' + goal.id, {
      id: goal.id,
      metric: goal.metric,
      targetValue: goal.targetValue,
      period: goal.period,
      startDate: shiftDate(-15, 0),
      endDate: shiftDate(15 + index * 7, 23),
      assigneeType: goal.assigneeType,
      assigneeId: goal.assigneeId,
      assigneeName: goal.assigneeName,
      currentValue: goal.currentValue,
      progressPercent: goal.progressPercent,
      lastCalculatedAt: shiftDate(-1, 6),
      status: goal.progressPercent >= 100 ? 'achieved' : 'active',
      ownerId: OWNER_UID,
      ownerName: OWNER_NAME,
      teamIds: index === 2 ? ['team-sales'] : ['team-sales', 'team-success'],
      visibility: 'org',
      createdById: OWNER_UID,
      createdByName: OWNER_NAME,
      createdAt: shiftDate(-20 + index, 10),
      updatedAt: new Date(),
    });
  });

  SYSTEM_REPORTS.forEach((systemReport, index) => {
    const report = createReportDefinitionFromSystem(systemReport, BUSINESS_ID, OWNER_UID, OWNER_NAME);
    addDocument(docs, 'report_definitions', 'businesses/' + BUSINESS_ID + '/report_definitions/' + reportIdAt(index), {
      id: reportIdAt(index),
      ...report,
      createdAt: shiftDate(-10 + index, 7),
      updatedAt: new Date(),
    });
  });

  [
    { id: 'notification-demo-001', type: 'task_due', priority: 'high', title: 'Task due today', body: 'A demo follow-up task is due today.', entityType: 'task', entityId: 'activity-demo-005', actionUrl: '/activities' },
    { id: 'notification-demo-002', type: 'deal_stage_changed', priority: 'normal', title: 'Deal moved forward', body: 'A demo opportunity changed stages.', entityType: 'deal', entityId: 'deal-demo-003', actionUrl: '/deals' },
    { id: 'notification-demo-003', type: 'lead_converted', priority: 'normal', title: 'Lead converted', body: 'A demo lead converted into an open opportunity.', entityType: 'lead', entityId: 'lead-demo-002', actionUrl: '/leads' },
    { id: 'notification-demo-004', type: 'sequence_completed', priority: 'low', title: 'Sequence completed', body: 'A demo sequence run finished successfully.', entityType: 'sequence', entityId: 'sequence-demo-001', actionUrl: '/sequences' },
    { id: 'notification-demo-005', type: 'goal_at_risk', priority: 'urgent', title: 'Goal pacing is behind', body: 'A demo monthly goal is behind plan.', entityType: 'goal', entityId: 'goal-demo-004', actionUrl: '/goals' },
    { id: 'notification-demo-006', type: 'email_opened', priority: 'low', title: 'Email opened', body: 'A demo email engagement event was recorded.', entityType: 'email', entityId: 'message-template-demo-001', actionUrl: '/reports' },
    { id: 'notification-demo-007', type: 'meeting_scheduled', priority: 'normal', title: 'Meeting scheduled', body: 'A demo meeting was added to the schedule.', entityType: 'activity', entityId: 'activity-demo-008', actionUrl: '/activities' },
    { id: 'notification-demo-008', type: 'system_announcement', priority: 'normal', title: 'Demo workspace notice', body: 'This workspace is read-only and uses fake data only.', actionUrl: '/' },
  ].forEach((notification, index) => {
    addDocument(docs, 'notifications', 'businesses/' + BUSINESS_ID + '/notifications/' + notification.id, {
      id: notification.id,
      businessId: BUSINESS_ID,
      userId: OWNER_UID,
      type: notification.type,
      priority: notification.priority,
      title: notification.title,
      body: notification.body,
      iconType: notification.type,
      entityType: notification.entityType,
      entityId: notification.entityId,
      actionUrl: notification.actionUrl,
      actorId: staffMembers[index % staffMembers.length].id,
      actorName: fullName(staffMembers[index % staffMembers.length].firstName, staffMembers[index % staffMembers.length].lastName),
      isRead: index % 3 === 0,
      readAt: index % 3 === 0 ? shiftDate(-1, 8) : undefined,
      isArchived: false,
      channels: ['in_app'],
      deliveredVia: ['in_app'],
      createdAt: shiftDate(-7 + index, 9),
      expiresAt: shiftDate(30 + index, 0),
    });
  });
}
