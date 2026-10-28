import { useCallback, useEffect, useMemo, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { createSecurityContext } from '../lib/security-context';
import { getAutomationRuleRepository } from '../data/repositories/automation-repository';
import type {
  AutomationAction,
  AutomationRule,
  AutomationRuleStatus,
  AutomationTrigger,
} from '../types/automation';
import { getAutomationEngine, type AutomationEvent } from '../services/automation-engine';
import { useDemoGuard } from './useDemoGuard';

export interface CreateAutomationInput {
  name: string;
  description?: string;
  trigger: AutomationTrigger;
  action: AutomationAction;
}

export interface UseAutomationRulesResult {
  rules: AutomationRule[];
  loading: boolean;
  error: string | null;
  createRule: (input: CreateAutomationInput) => Promise<void>;
  toggleRule: (id: string, status: AutomationRuleStatus) => Promise<void>;
  simulate: (rule: AutomationRule, event: AutomationEvent) => Promise<string | null>;
  refresh: () => Promise<void>;
}

function getEntityTypeForTrigger(triggerType: AutomationTrigger['type']): AutomationEvent['entityType'] {
  switch (triggerType) {
    case 'dealStageChanged':
      return 'deal';
    case 'taskOverdue':
    case 'taskSnoozed':
    case 'taskReminder':
      return 'activity';
    default:
      return 'lead';
  }
}

export function useAutomationRules(): UseAutomationRulesResult {
  const { crmUser, businessId } = useAuth();
  const { guardMutation } = useDemoGuard();
  const [rules, setRules] = useState<AutomationRule[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const canManageAutomation =
    crmUser?.role ? ['owner', 'admin', 'manager'].includes(crmUser.role) : false;

  const context = useMemo(() => {
    if (!crmUser || !businessId) return null;
    return createSecurityContext(crmUser);
  }, [crmUser, businessId]);

  const repo = useMemo(() => getAutomationRuleRepository(), []);
  const engine = useMemo(() => getAutomationEngine(), []);

  const loadRules = useCallback(async () => {
    if (!context || !canManageAutomation) {
      setRules([]);
      setLoading(false);
      if (!canManageAutomation) {
        setError('Insufficient permissions to manage automations');
      }
      return;
    }

    setLoading(true);
    setError(null);

    const result = await repo.getAll(context, {
      orderBy: { field: 'createdAt', direction: 'desc' },
    });

    if (!result.success) {
      setError(result.error?.message || 'Failed to load automation rules');
      setRules([]);
    } else {
      setRules(result.data.data);
    }
    setLoading(false);
  }, [context, repo, canManageAutomation]);

  useEffect(() => {
    void loadRules();
  }, [loadRules]);

  const createRule = useCallback(
    async (input: CreateAutomationInput) => {
      if (!context || !canManageAutomation) {
        const message = 'Insufficient permissions to manage automations';
        setError(message);
        throw new Error(message);
      }
      setError(null);
      const payload: Omit<AutomationRule, 'id' | 'createdAt' | 'updatedAt'> = {
        ...input,
        status: 'enabled',
        businessId: context.businessId,
        createdById: context.userId,
        createdByName: context.userName,
        ownerId: context.userId,
        ownerName: context.userName,
        teamIds: context.teamIds ?? [],
        visibility: 'team',
        lastRunAt: undefined,
      };

      const result = await repo.create(context, payload);
      if (!result.success) {
        setError(result.error?.message || 'Failed to create automation');
      } else {
        setRules((prev) => [result.data, ...prev]);
      }
    },
    [context, repo, canManageAutomation]
  );

  const toggleRule = useCallback(
    async (id: string, status: AutomationRuleStatus) => {
      if (!context || !canManageAutomation) {
        const message = 'Insufficient permissions to manage automations';
        setError(message);
        throw new Error(message);
      }
      const result = await repo.setStatus(context, id, status);
      if (!result.success) {
        setError(result.error?.message || 'Failed to update rule status');
        return;
      }
      setRules((prev) => prev.map((r) => (r.id === id ? { ...r, status } : r)));
    },
    [context, repo, canManageAutomation]
  );

  const simulate = useCallback(
    async (rule: AutomationRule, event: AutomationEvent) => {
      if (!context || !canManageAutomation) return 'Insufficient permissions to manage automations';
      const isActivityTrigger = getEntityTypeForTrigger(rule.trigger.type) === 'activity';
      const simResult = await engine.executeRule(context, rule, {
        ...event,
        entityType: event.entityType || getEntityTypeForTrigger(rule.trigger.type),
        relatedEntityId:
          event.relatedEntityId || (isActivityTrigger && rule.action.target !== 'activity' ? 'preview-target' : undefined),
        relatedEntityType:
          event.relatedEntityType ||
          (isActivityTrigger && rule.action.target !== 'activity'
            ? rule.action.target
            : undefined),
        dryRun: true,
      });
      return simResult.reason || null;
    },
    [context, engine, canManageAutomation]
  );

  const refresh = useCallback(async () => {
    await loadRules();
  }, [loadRules]);

  return {
    rules,
    loading,
    error,
    createRule: guardMutation(createRule, { action: 'automation-create' }),
    toggleRule: guardMutation(toggleRule, { action: 'automation-toggle' }),
    simulate,
    refresh,
  };
}
