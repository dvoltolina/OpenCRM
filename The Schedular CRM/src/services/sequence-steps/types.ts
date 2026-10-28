/**
 * Shared Types for Step Executors
 *
 * Phase 4 Implementation - Sequences Execution Engine
 */

import type { SecurityContext } from '../../data/repositories/repository-types';
import type {
  SequenceEnrollment,
  SequenceStep,
  SequenceExecution,
  Sequence,
} from '../../types/sequences';

// ============================================
// Execution Result Types
// ============================================

export interface StepExecutionResult {
  success: boolean;
  messageId?: string;
  taskId?: string;
  errorCode?: string;
  errorMessage?: string;
  skipped?: boolean;
  skipReason?: string;
}

export interface ExecutorContext {
  securityContext: SecurityContext;
  enrollment: SequenceEnrollment;
  sequence: Sequence;
  step: SequenceStep;
  execution: SequenceExecution;
}

// ============================================
// Entity Data Types (for merge fields)
// ============================================

export interface EntityData {
  id: string;
  type: 'lead' | 'client' | 'deal';
  firstName?: string;
  lastName?: string;
  email: string;
  phone?: string;
  title?: string;
  companyName?: string;
  companyId?: string;
}

export interface SenderData {
  id: string;
  name: string;
  email: string;
  phone?: string;
}

export interface BusinessData {
  id: string;
  name: string;
  phone?: string;
  website?: string;
  address?: string;
}

// ============================================
// Step Executor Interface
// ============================================

export interface StepExecutor {
  execute(context: ExecutorContext): Promise<StepExecutionResult>;
}
