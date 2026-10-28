/**
 * useTemplates Hook
 * React hooks for managing form templates and template instances
 *
 * Agent CRM-30 Implementation
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import {
  getTemplateRepository,
  getTemplateInstanceRepository,
} from '../data/repositories/templates-repository';
import type {
  FormTemplate,
  TemplateInstance,
  TemplateCategory,
  TemplateFilter,
  SEED_TEMPLATES,
} from '../types/templates';
import type { SecurityContext } from '../data/repositories/repository-types';

// ============================================
// useTemplates - Get all templates with filtering
// ============================================

export function useTemplates(filter?: TemplateFilter) {
  const { crmUser, businessId } = useAuth();
  const [templates, setTemplates] = useState<FormTemplate[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const loadTemplates = useCallback(async () => {
    if (!crmUser || !businessId) {
      setIsLoading(false);
      return;
    }

    try {
      setIsLoading(true);
      setError(null);

      const context: SecurityContext = {
        businessId,
        userId: crmUser.id,
        userName: crmUser.displayName,
        userRole: crmUser.role,
      };

      const templateRepo = getTemplateRepository();
      const result = await templateRepo.getFiltered(context, filter || {});

      if (result.success) {
        setTemplates(result.data);
      } else {
        setError(new Error(result.error.message));
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to load templates'));
    } finally {
      setIsLoading(false);
    }
  }, [crmUser, businessId, filter]);

  useEffect(() => {
    loadTemplates();
  }, [loadTemplates]);

  return {
    templates,
    isLoading,
    error,
    refresh: loadTemplates,
  };
}

// ============================================
// useTemplate - Get a single template by ID
// ============================================

export function useTemplate(templateId: string | null) {
  const { crmUser, businessId } = useAuth();
  const [template, setTemplate] = useState<FormTemplate | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!crmUser || !businessId || !templateId) {
      setIsLoading(false);
      setTemplate(null);
      return;
    }

    const loadTemplate = async () => {
      try {
        setIsLoading(true);
        setError(null);

        const context: SecurityContext = {
          businessId,
          userId: crmUser.id,
          userName: crmUser.displayName,
          userRole: crmUser.role,
        };

        const templateRepo = getTemplateRepository();
        const result = await templateRepo.getById(context, templateId);

        if (result.success) {
          setTemplate(result.data);
        } else {
          setError(new Error(result.error.message));
        }
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to load template'));
      } finally {
        setIsLoading(false);
      }
    };

    loadTemplate();
  }, [crmUser, businessId, templateId]);

  return {
    template,
    isLoading,
    error,
  };
}

// ============================================
// useTemplateMutations - CRUD operations for templates
// ============================================

export function useTemplateMutations() {
  const { crmUser, businessId } = useAuth();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const getContext = useCallback((): SecurityContext | null => {
    if (!crmUser || !businessId) return null;
    return {
      businessId,
      userId: crmUser.id,
      userName: crmUser.displayName,
      userRole: crmUser.role,
    };
  }, [crmUser, businessId]);

  const createTemplate = useCallback(
    async (templateData: Omit<FormTemplate, 'id' | 'createdAt' | 'updatedAt' | 'businessId'>) => {
      const context = getContext();
      if (!context) {
        throw new Error('Not authenticated');
      }

      try {
        setIsLoading(true);
        setError(null);

        const templateRepo = getTemplateRepository();
        const result = await templateRepo.create(context, {
          ...templateData,
          businessId: context.businessId,
          createdBy: context.userId,
          createdByName: context.userName,
        });

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to create template');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const updateTemplate = useCallback(
    async (templateId: string, updates: Partial<FormTemplate>) => {
      const context = getContext();
      if (!context) {
        throw new Error('Not authenticated');
      }

      try {
        setIsLoading(true);
        setError(null);

        const templateRepo = getTemplateRepository();
        const result = await templateRepo.update(context, templateId, updates);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update template');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const deleteTemplate = useCallback(
    async (templateId: string) => {
      const context = getContext();
      if (!context) {
        throw new Error('Not authenticated');
      }

      try {
        setIsLoading(true);
        setError(null);

        const templateRepo = getTemplateRepository();
        const result = await templateRepo.delete(context, templateId);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return true;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to delete template');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const cloneTemplate = useCallback(
    async (templateId: string, newName: string) => {
      const context = getContext();
      if (!context) {
        throw new Error('Not authenticated');
      }

      try {
        setIsLoading(true);
        setError(null);

        const templateRepo = getTemplateRepository();
        const result = await templateRepo.cloneTemplate(context, templateId, newName);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to clone template');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const seedSystemTemplates = useCallback(
    async (seedTemplates: typeof SEED_TEMPLATES) => {
      const context = getContext();
      if (!context) {
        throw new Error('Not authenticated');
      }

      try {
        setIsLoading(true);
        setError(null);

        const templateRepo = getTemplateRepository();
        const result = await templateRepo.seedSystemTemplates(context, seedTemplates);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to seed templates');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  return {
    createTemplate,
    updateTemplate,
    deleteTemplate,
    cloneTemplate,
    seedSystemTemplates,
    isLoading,
    error,
  };
}

// ============================================
// useTemplateInstances - Get template instances
// ============================================

export function useTemplateInstances(params: {
  templateId?: string;
  clientId?: string;
  dealId?: string;
}) {
  const { crmUser, businessId } = useAuth();
  const [instances, setInstances] = useState<TemplateInstance[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!crmUser || !businessId) {
      setIsLoading(false);
      return;
    }

    const loadInstances = async () => {
      try {
        setIsLoading(true);
        setError(null);

        const context: SecurityContext = {
          businessId,
          userId: crmUser.id,
          userName: crmUser.displayName,
          userRole: crmUser.role,
        };

        const instanceRepo = getTemplateInstanceRepository();
        let result;

        if (params.templateId) {
          result = await instanceRepo.getByTemplate(context, params.templateId);
        } else if (params.clientId) {
          result = await instanceRepo.getByClient(context, params.clientId);
        } else if (params.dealId) {
          result = await instanceRepo.getByDeal(context, params.dealId);
        } else {
          result = await instanceRepo.getAll(context);
        }

        if (result.success) {
          setInstances(Array.isArray(result.data) ? result.data : result.data.data);
        } else {
          setError(new Error(result.error.message));
        }
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to load template instances'));
      } finally {
        setIsLoading(false);
      }
    };

    loadInstances();
  }, [crmUser, businessId, params.templateId, params.clientId, params.dealId]);

  return {
    instances,
    isLoading,
    error,
  };
}

// ============================================
// useTemplateInstanceMutations - CRUD for instances
// ============================================

export function useTemplateInstanceMutations() {
  const { crmUser, businessId } = useAuth();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const getContext = useCallback((): SecurityContext | null => {
    if (!crmUser || !businessId) return null;
    return {
      businessId,
      userId: crmUser.id,
      userName: crmUser.displayName,
      userRole: crmUser.role,
    };
  }, [crmUser, businessId]);

  const createInstance = useCallback(
    async (
      instanceData: Omit<TemplateInstance, 'id' | 'createdAt' | 'updatedAt' | 'businessId'>
    ) => {
      const context = getContext();
      if (!context) {
        throw new Error('Not authenticated');
      }

      try {
        setIsLoading(true);
        setError(null);

        const instanceRepo = getTemplateInstanceRepository();
        const result = await instanceRepo.create(context, {
          ...instanceData,
          businessId: context.businessId,
          createdBy: context.userId,
          createdByName: context.userName,
        });

        if (!result.success) {
          throw new Error(result.error.message);
        }

        // Increment template usage count
        const templateRepo = getTemplateRepository();
        await templateRepo.incrementUsage(context, instanceData.templateId);

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to create template instance');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const updateInstance = useCallback(
    async (instanceId: string, updates: Partial<TemplateInstance>) => {
      const context = getContext();
      if (!context) {
        throw new Error('Not authenticated');
      }

      try {
        setIsLoading(true);
        setError(null);

        const instanceRepo = getTemplateInstanceRepository();
        const result = await instanceRepo.update(context, instanceId, updates);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to update template instance');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  const markCompleted = useCallback(
    async (instanceId: string) => {
      const context = getContext();
      if (!context) {
        throw new Error('Not authenticated');
      }

      try {
        setIsLoading(true);
        setError(null);

        const instanceRepo = getTemplateInstanceRepository();
        const result = await instanceRepo.markCompleted(context, instanceId);

        if (!result.success) {
          throw new Error(result.error.message);
        }

        return result.data;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to mark instance as completed');
        setError(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [getContext]
  );

  return {
    createInstance,
    updateInstance,
    markCompleted,
    isLoading,
    error,
  };
}

// ============================================
// useTemplatesByCategory - Get templates by category
// ============================================

export function useTemplatesByCategory(category: TemplateCategory | null) {
  const filter: TemplateFilter = category ? { category, isActive: true } : { isActive: true };
  return useTemplates(filter);
}

// ============================================
// usePendingInstances - Get pending template instances
// ============================================

export function usePendingInstances() {
  const { crmUser, businessId } = useAuth();
  const [instances, setInstances] = useState<TemplateInstance[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!crmUser || !businessId) {
      setIsLoading(false);
      return;
    }

    const loadPending = async () => {
      try {
        setIsLoading(true);
        setError(null);

        const context: SecurityContext = {
          businessId,
          userId: crmUser.id,
          userName: crmUser.displayName,
          userRole: crmUser.role,
        };

        const instanceRepo = getTemplateInstanceRepository();
        const result = await instanceRepo.getPending(context);

        if (result.success) {
          setInstances(result.data);
        } else {
          setError(new Error(result.error.message));
        }
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to load pending instances'));
      } finally {
        setIsLoading(false);
      }
    };

    loadPending();
  }, [crmUser, businessId]);

  return {
    instances,
    isLoading,
    error,
  };
}
