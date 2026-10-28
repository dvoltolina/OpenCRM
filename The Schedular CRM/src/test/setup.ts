/**
 * Vitest Test Setup
 * Global test configuration and mocks
 */

import { vi, beforeAll, afterAll, afterEach } from 'vitest';
import '@testing-library/jest-dom/vitest';

// Enable React act environment to reduce warnings
(globalThis as any).IS_REACT_ACT_ENVIRONMENT = true;

// Mock console.error to suppress expected error logs in tests
const originalError = console.error;
const originalWarn = console.warn;
const originalEmitWarning = process.emitWarning;
const warningListeners: Array<(warning: any) => void> = [];
beforeAll(() => {
  console.error = (...args: unknown[]) => {
    const first = args[0];
    if (
      typeof first === 'string' &&
      (first.includes('Audit logging failed') ||
        first.includes('not wrapped in act') ||
        first.includes('not configured to support act') ||
        first.includes('width(-1) and height(-1)') ||
        first.includes('width(0) and height(0)'))
    ) {
      return;
    }
    originalError.call(console, ...args);
  };

  console.warn = (...args: unknown[]) => {
    const first = args[0];
    if (
      typeof first === 'string' &&
      (first.includes('not wrapped in act') ||
        first.includes('not configured to support act') ||
        first.includes('width(-1) and height(-1)') ||
        first.includes('width(0) and height(0)'))
    ) {
      return;
    }
    originalWarn.call(console, ...args);
  };

  process.emitWarning = ((warning: any, ...args: any[]) => {
    const message = typeof warning === 'string' ? warning : warning?.message;
    if (message && message.includes('localstorage-file was provided without a valid path')) {
      return;
    }
    return originalEmitWarning.call(process, warning as any, ...args);
  }) as typeof process.emitWarning;

  const warningListener = (warning: any) => {
    const message = typeof warning === 'string' ? warning : warning?.message;
    if (message && message.includes('localstorage-file was provided without a valid path')) {
      return;
    }
    originalEmitWarning.call(process, warning as any);
  };
  warningListeners.push(warningListener);
  process.on('warning', warningListener);
});

afterAll(() => {
  console.error = originalError;
  console.warn = originalWarn;
  process.emitWarning = originalEmitWarning;
  warningListeners.forEach((listener) => process.off('warning', listener));
});

// Reset all mocks between tests
afterEach(() => {
  vi.clearAllMocks();
});
