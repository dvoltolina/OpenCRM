import type {
  IntakeForm,
  IntakeFormDraft,
  IntakeFormField,
  IntakeFormInput,
  IntakeFormSubmission,
} from '../types/models';
import { assertDemoMutationAllowed, isDemoMode } from '../config/demo';
import { getDb } from '../lib/firebase';
import { logAuditEvent } from './auditLog';
import { callTenantFunction, fetchCollection, fetchDoc, scopedCollection } from './firestoreBase';
import {
  doc,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const randomId = (prefix: string) => `${prefix}_${Math.random().toString(36).slice(2, 8)}`;

const deepClone = <T>(value: T): T => JSON.parse(JSON.stringify(value));

const defaultFieldSet: IntakeFormField[] = [
  {
    id: 'first-name',
    type: 'text',
    label: 'First name',
    required: true,
    width: 'half',
    placeholder: 'Alex',
  },
  {
    id: 'last-name',
    type: 'text',
    label: 'Last name',
    required: true,
    width: 'half',
    placeholder: 'Rivera',
  },
  {
    id: 'email',
    type: 'text',
    label: 'Email address',
    required: true,
    placeholder: 'patient@example.com',
  },
  {
    id: 'phone',
    type: 'text',
    label: 'Mobile phone',
    required: false,
    placeholder: '(555) 123-4567',
    helperText: 'We’ll send reminders to this number.',
  },
];

const intakeFormSeeds: IntakeForm[] = [
  {
    id: 'intake-health-history',
    businessId: 'demo-business',
    name: 'New Patient Intake',
    description: 'Baseline client demographics, consent, and health history.',
    fields: [
      ...defaultFieldSet,
      {
        id: 'visit-reason',
        type: 'textarea',
        label: 'What brings you in today?',
        required: true,
        helperText: 'Share symptoms, goals, or recent changes.',
      },
      {
        id: 'preferred-provider',
        type: 'dropdown',
        label: 'Preferred provider',
        required: false,
        options: ['No preference', 'Any therapist', 'Existing provider'],
      },
      {
        id: 'past-treatments',
        type: 'checkbox',
        label: 'Previous treatments',
        required: false,
        options: ['Physical therapy', 'Chiropractic', 'Massage', 'Acupuncture'],
      },
    ],
    serviceIds: ['svc_physical_therapy', 'svc_follow_up'],
    isActive: true,
    createdAt: '2025-01-01T10:00:00.000Z',
    updatedAt: '2025-01-05T08:00:00.000Z',
  },
  {
    id: 'intake-telehealth',
    businessId: 'demo-business',
    name: 'Telehealth Consent',
    description: 'Short consent form for recurring telehealth clients.',
    fields: [
      {
        id: 'consent-confirm',
        type: 'radio',
        label: 'Do you consent to telehealth sessions?',
        required: true,
        options: ['Yes, I consent', 'No, I need more info'],
      },
      {
        id: 'consent-details',
        type: 'textarea',
        label: 'Questions about telehealth',
        required: false,
        helperText: 'Optional: let us know what concerns you have.',
        conditionalLogic: {
          id: 'logic-consent-details',
          action: 'show',
          matchType: 'all',
          conditions: [
            {
              id: 'cond-consent-details',
              fieldId: 'consent-confirm',
              operator: 'equals',
              value: 'No, I need more info',
            },
          ],
        },
      },
      {
        id: 'signature',
        type: 'signature',
        label: 'Client signature',
        required: true,
        helperText: 'Use mouse or finger to sign.',
      },
      {
        id: 'date',
        type: 'date',
        label: 'Date signed',
        required: true,
        defaultValue: new Date().toISOString().slice(0, 10),
      },
    ],
    serviceIds: ['svc_telehealth'],
    isActive: true,
    createdAt: '2025-01-10T12:00:00.000Z',
    updatedAt: '2025-01-11T09:30:00.000Z',
  },
];

function cloneWithNewFieldIds(fields: IntakeFormField[]): IntakeFormField[] {
  const idMap = new Map<string, string>();
  const cloned = deepClone(fields).map((field) => {
    const newId = randomId('field');
    idMap.set(field.id, newId);
    return {
      ...field,
      id: newId,
    };
  });
  return cloned.map((field) => {
    if (!field.conditionalLogic) {
      return field;
    }
    return {
      ...field,
      conditionalLogic: {
        ...field.conditionalLogic,
        id: randomId('logic'),
        conditions: field.conditionalLogic.conditions.map((condition) => ({
          ...condition,
          id: randomId('condition'),
          fieldId: idMap.get(condition.fieldId) ?? condition.fieldId,
        })),
      },
    };
  });
}

function buildDefaultFields(): IntakeFormField[] {
  return cloneWithNewFieldIds(defaultFieldSet);
}

function normalizeIsoTimestamp(value: unknown): string {
  if (typeof value === 'string') return value;
  if (value instanceof Date) return value.toISOString();
  if (
    value &&
    typeof value === 'object' &&
    'toDate' in value &&
    typeof (value as { toDate?: unknown }).toDate === 'function'
  ) {
    return ((value as { toDate: () => Date }).toDate()).toISOString();
  }
  return new Date().toISOString();
}

function normalizeIntakeForm(form: IntakeForm): IntakeForm {
  return {
    ...form,
    createdAt: normalizeIsoTimestamp(form.createdAt),
    updatedAt: normalizeIsoTimestamp(form.updatedAt),
  };
}

export function getSeedIntakeForms(businessId?: string): IntakeForm[] {
  return deepClone(intakeFormSeeds).map((form) => ({
    ...form,
    businessId: businessId ?? form.businessId,
  }));
}

export async function listIntakeForms(businessId: string): Promise<IntakeForm[]> {
  const scoped = scopedCollection<IntakeForm>(businessId, ['intakeFormTemplates']);
  try {
    const results = await fetchCollection(scoped);
    if (!results.length && isDemoMode) {
      return getSeedIntakeForms(businessId);
    }
    return results.map(normalizeIntakeForm);
  } catch {
    if (!isDemoMode) {
      throw new Error('Failed to load intake forms.');
    }
    return getSeedIntakeForms(businessId);
  }
}

export async function createIntakeForm(
  businessId: string,
  input?: Partial<IntakeFormInput>,
): Promise<IntakeForm> {
  assertDemoMutationAllowed('create intake form');
  if (!businessId) {
    throw new Error('businessId is required to create intake forms.');
  }

  const now = new Date().toISOString();
  const draft: IntakeForm = {
    id: randomId('form'),
    businessId,
    name: input?.name ?? 'Untitled intake form',
    description: input?.description ?? '',
    fields: input?.fields ? cloneWithNewFieldIds(input.fields) : buildDefaultFields(),
    serviceIds: input?.serviceIds ?? [],
    isActive: input?.isActive ?? true,
    createdAt: now,
    updatedAt: now,
  };

  const response = await callTenantFunction<
    { input: Omit<IntakeForm, 'id' | 'createdAt' | 'updatedAt'> },
    { id?: string }
  >('intakeForms-create', businessId, {
    input: {
      businessId,
      name: draft.name,
      description: draft.description,
      fields: draft.fields,
      serviceIds: draft.serviceIds,
      isActive: draft.isActive,
    },
  });

  if (response?.id) {
    const persisted = await fetchDoc<IntakeForm>(businessId, ['intakeFormTemplates'], response.id);
    if (persisted) {
      return normalizeIntakeForm(persisted);
    }
    return { ...draft, id: response.id };
  }

  return draft;
}

export async function updateIntakeForm(
  businessId: string,
  formId: string,
  form: IntakeForm,
): Promise<IntakeForm> {
  assertDemoMutationAllowed('save intake form');
  if (!businessId) {
    throw new Error('businessId is required to update intake forms.');
  }
  const payload: IntakeForm = {
    ...form,
    id: formId,
    businessId,
    updatedAt: new Date().toISOString(),
  };

  await callTenantFunction('intakeForms-update', businessId, {
    formId,
    form: {
      name: payload.name,
      description: payload.description,
      fields: payload.fields,
      serviceIds: payload.serviceIds,
      isActive: payload.isActive,
    },
  });

  return payload;
}

export async function duplicateIntakeForm(
  businessId: string,
  source: IntakeForm,
): Promise<IntakeForm> {
  assertDemoMutationAllowed('duplicate intake form');
  if (!businessId) {
    throw new Error('businessId is required to duplicate intake forms.');
  }

  const response = await callTenantFunction<{ formId: string }, { id?: string }>(
    'intakeForms-duplicate',
    businessId,
    { formId: source.id },
  );

  if (response?.id) {
    const persisted = await fetchDoc<IntakeForm>(businessId, ['intakeFormTemplates'], response.id);
    if (persisted) {
      return normalizeIntakeForm(persisted);
    }
  }

  const now = new Date().toISOString();
  const duplicate: IntakeForm = {
    ...source,
    id: response?.id ?? randomId('form'),
    businessId,
    name: `${source.name} copy`,
    isActive: false,
    createdAt: now,
    updatedAt: now,
    fields: cloneWithNewFieldIds(source.fields),
  };
  return duplicate;
}

export async function archiveIntakeForm(businessId: string, formId: string) {
  assertDemoMutationAllowed('archive intake form');
  if (!businessId) {
    throw new Error('businessId is required to archive intake forms.');
  }

  await callTenantFunction('intakeForms-archive', businessId, { formId });
  return { id: formId, archived: true };
}

export async function getIntakeForm(businessId: string, formId: string): Promise<IntakeForm | null> {
  const result = await fetchDoc<IntakeForm>(businessId, ['intakeFormTemplates'], formId);
  return result ? normalizeIntakeForm(result) : null;
}

type ContractIntakeSubmissionFields = {
  templateId?: string;
  templateName?: string;
  templateVersion?: number;
};

type IntakeDraftWriteInput = Partial<IntakeFormDraft> &
  ContractIntakeSubmissionFields & {
    formId?: string;
    attachments?: Array<Record<string, unknown>>;
  };

function normalizeIntakeSubmission(
  submission: IntakeFormSubmission & ContractIntakeSubmissionFields,
): IntakeFormSubmission {
  const templateId = submission.templateId ?? submission.formId;
  return {
    ...submission,
    formId: templateId ?? submission.formId,
    createdAt: normalizeIsoTimestamp(submission.createdAt),
    updatedAt: normalizeIsoTimestamp(submission.updatedAt),
    submittedAt: submission.submittedAt ? normalizeIsoTimestamp(submission.submittedAt) : undefined,
  };
}

function normalizeIntakeDraft(
  draft: IntakeFormDraft & ContractIntakeSubmissionFields,
): IntakeFormDraft {
  const normalized = normalizeIntakeSubmission(draft as IntakeFormSubmission & ContractIntakeSubmissionFields);
  return {
    ...(normalized as IntakeFormDraft),
    status: 'draft',
  };
}

function resolveTemplateId(input: {
  templateId?: string;
  formId?: string;
}): string {
  const templateId = input.templateId?.trim() || input.formId?.trim();
  if (!templateId) {
    throw new Error('templateId is required for intake drafts/submissions.');
  }
  return templateId;
}

export async function listIntakeSubmissions(
  businessId: string,
  clientId: string,
  userId?: string,
): Promise<IntakeFormSubmission[]> {
  const scoped = scopedCollection<IntakeFormSubmission & ContractIntakeSubmissionFields>(
    businessId,
    ['intakeFormSubmissions'],
  );
  const filtered = await fetchCollection(scoped, [where('clientId', '==', clientId)]);
  const normalized = filtered
    .map(normalizeIntakeSubmission)
    .sort((a, b) => new Date(b.updatedAt ?? b.createdAt).getTime() - new Date(a.updatedAt ?? a.createdAt).getTime());
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiReadList',
    entityType: 'IntakeFormSubmission',
    entityId: clientId,
    metadata: { source: 'listIntakeSubmissions', count: normalized.length },
  });
  return normalized;
}

export async function getIntakeSubmission(
  businessId: string,
  submissionId: string,
  userId?: string,
): Promise<IntakeFormSubmission | null> {
  const result = await fetchDoc<IntakeFormSubmission & ContractIntakeSubmissionFields>(
    businessId,
    ['intakeFormSubmissions'],
    submissionId,
  );
  if (result) {
    await logAuditEvent({
      businessId,
      userId,
      actionType: 'phiRead',
      entityType: 'IntakeFormSubmission',
      entityId: submissionId,
      metadata: { source: 'getIntakeSubmission' },
    });
  }
  return result ? normalizeIntakeSubmission(result) : null;
}

export async function listIntakeDrafts(
  businessId: string,
  clientId: string,
  userId?: string,
): Promise<IntakeFormDraft[]> {
  const scoped = scopedCollection<IntakeFormDraft & ContractIntakeSubmissionFields>(
    businessId,
    ['intakeFormDrafts'],
  );
  const all = await fetchCollection(scoped, [where('clientId', '==', clientId)]);
  const normalized = all
    .map(normalizeIntakeDraft)
    .sort((a, b) => new Date(b.updatedAt ?? b.createdAt).getTime() - new Date(a.updatedAt ?? a.createdAt).getTime());
  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiReadList',
    entityType: 'IntakeFormDraft',
    entityId: clientId,
    metadata: { source: 'listIntakeDrafts', count: normalized.length },
  });
  return normalized;
}

export async function saveIntakeDraft(
  businessId: string,
  draft: IntakeDraftWriteInput,
  userId?: string,
) {
  assertDemoMutationAllowed('save intake draft');
  if (!businessId) {
    throw new Error('businessId is required to save intake drafts.');
  }
  if (!draft.clientId) {
    throw new Error('clientId is required to save intake drafts.');
  }

  const templateId = resolveTemplateId(draft);
  const now = new Date().toISOString();
  const draftId = draft.id ?? randomId('draft');
  const payload: IntakeFormDraft & ContractIntakeSubmissionFields & { attachments?: Array<Record<string, unknown>> } = {
    ...(draft as IntakeFormDraft),
    id: draftId,
    businessId,
    clientId: draft.clientId,
    formId: templateId,
    templateId,
    templateName: draft.templateName,
    templateVersion: draft.templateVersion,
    responses: draft.responses ?? {},
    status: 'draft',
    submittedAt: undefined,
    createdAt: draft.createdAt ?? now,
    updatedAt: now,
    attachments: draft.attachments ?? [],
  };

  const db = getDb();
  await setDoc(doc(db, 'businesses', businessId, 'intakeFormDrafts', draftId), payload, { merge: true });

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'IntakeFormDraft',
    entityId: draftId,
    metadata: { source: 'saveIntakeDraft', hasAttachments: Boolean(payload.attachments?.length) },
  });

  return normalizeIntakeDraft(payload);
}

export async function submitIntakeForm(
  businessId: string,
  submissionId: string,
  userId?: string,
) {
  assertDemoMutationAllowed('submit intake form');
  if (!businessId) {
    throw new Error('businessId is required to submit intake forms.');
  }

  const now = new Date().toISOString();
  const db = getDb();
  await updateDoc(doc(db, 'businesses', businessId, 'intakeFormSubmissions', submissionId), {
    status: 'submitted',
    submittedAt: now,
    updatedAt: now,
  });

  await logAuditEvent({
    businessId,
    userId,
    actionType: 'phiWrite',
    entityType: 'IntakeFormSubmission',
    entityId: submissionId,
    metadata: { source: 'submitIntakeForm' },
  });
}
