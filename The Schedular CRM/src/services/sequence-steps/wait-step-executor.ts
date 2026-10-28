/**
 * Wait Step Executor
 * Handles wait/delay steps in sequences
 *
 * Wait steps are "executed" by simply marking them complete.
 * The actual delay is handled by the scheduler which sets
 * the scheduledAt time for the next step.
 *
 * HIPAA Compliance:
 * - No PHI processed in wait steps
 *
 * Phase 4 Implementation - Sequences Execution Engine
 */

import type { StepExecutionResult, ExecutorContext } from './types';

// ============================================
// Wait Step Executor
// ============================================

export class WaitStepExecutor {
  /**
   * Execute a wait step.
   * Wait steps are immediately completed since the delay
   * is already baked into the scheduledAt time.
   */
  async execute(_context: ExecutorContext): Promise<StepExecutionResult> {
    // Wait steps don't do anything - they're a placeholder for the delay
    // The delay was already applied when scheduling the execution
    return {
      success: true,
      skipped: false,
    };
  }
}

// ============================================
// Singleton Instance
// ============================================

let executorInstance: WaitStepExecutor | null = null;

export function getWaitStepExecutor(): WaitStepExecutor {
  if (!executorInstance) {
    executorInstance = new WaitStepExecutor();
  }
  return executorInstance;
}
