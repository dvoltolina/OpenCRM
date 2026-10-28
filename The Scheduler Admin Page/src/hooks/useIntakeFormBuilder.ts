import { useCallback, useEffect, useState } from 'react';

import {
  archiveIntakeForm,
  createIntakeForm,
  duplicateIntakeForm,
  listIntakeForms,
  updateIntakeForm,
} from '../data/intakeForms';
import type { IntakeForm } from '../types/models';

type UseIntakeFormBuilderResult = {
  forms: IntakeForm[];
  loading: boolean;
  saving: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  createForm: (name?: string) => Promise<IntakeForm | null>;
  saveForm: (form: IntakeForm) => Promise<IntakeForm | null>;
  duplicateForm: (formId: string) => Promise<IntakeForm | null>;
  archiveForm: (formId: string) => Promise<void>;
};

export function useIntakeFormBuilder(businessId?: string): UseIntakeFormBuilderResult {
  const [forms, setForms] = useState<IntakeForm[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!businessId) {
      // No businessId - clear forms and set error
      setForms([]);
      setError('Business context required to load intake forms');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const data = await listIntakeForms(businessId);
      setForms(data);
    } catch (err) {
      console.error('Failed to load intake forms', err);
      setError(err instanceof Error ? err.message : 'Failed to load intake forms');
      // Clear forms on error
      setForms([]);
    } finally {
      setLoading(false);
    }
  }, [businessId]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const createForm = useCallback(
    async (name?: string) => {
      if (!businessId) {
        console.warn('Cannot create intake form without businessId');
        setError('Business context required to create intake form');
        return null;
      }
      setSaving(true);
      setError(null);
      try {
        const form = await createIntakeForm(businessId, { name });
        setForms((prev) => [form, ...prev]);
        return form;
      } catch (err) {
        console.error('Failed to create intake form', err);
        setError(err instanceof Error ? err.message : 'Failed to create intake form');
        return null;
      } finally {
        setSaving(false);
      }
    },
    [businessId],
  );

  const saveForm = useCallback(
    async (form: IntakeForm) => {
      if (!businessId) {
        console.warn('Cannot save intake form without businessId');
        setError('Business context required to save intake form');
        return null;
      }
      setSaving(true);
      setError(null);
      try {
        const updated = await updateIntakeForm(businessId, form.id, form);
        setForms((prev) => prev.map((existing) => (existing.id === updated.id ? updated : existing)));
        return updated;
      } catch (err) {
        console.error('Failed to save intake form', err);
        setError(err instanceof Error ? err.message : 'Failed to save intake form');
        return null;
      } finally {
        setSaving(false);
      }
    },
    [businessId],
  );

  const duplicateForm = useCallback(
    async (formId: string) => {
      if (!businessId) {
        console.warn('Cannot duplicate intake form without businessId');
        setError('Business context required to duplicate intake form');
        return null;
      }
      const source = forms.find((form) => form.id === formId);
      if (!source) return null;
      setSaving(true);
      setError(null);
      try {
        const duplicate = await duplicateIntakeForm(businessId, source);
        setForms((prev) => [duplicate, ...prev]);
        return duplicate;
      } catch (err) {
        console.error('Failed to duplicate intake form', err);
        setError(err instanceof Error ? err.message : 'Failed to duplicate intake form');
        return null;
      } finally {
        setSaving(false);
      }
    },
    [businessId, forms],
  );

  const archiveForm = useCallback(
    async (formId: string) => {
      if (!businessId) {
        console.warn('Cannot archive intake form without businessId');
        setError('Business context required to archive intake form');
        return;
      }
      setSaving(true);
      setError(null);
      try {
        await archiveIntakeForm(businessId, formId);
        setForms((prev) =>
          prev.map((form) => (form.id === formId ? { ...form, isActive: false } : form)),
        );
      } catch (err) {
        console.error('Failed to archive intake form', err);
        setError(err instanceof Error ? err.message : 'Failed to archive intake form');
      } finally {
        setSaving(false);
      }
    },
    [businessId],
  );

  return {
    forms,
    loading,
    saving,
    error,
    refresh,
    createForm,
    saveForm,
    duplicateForm,
    archiveForm,
  };
}


