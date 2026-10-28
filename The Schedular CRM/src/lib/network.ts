/**
 * Network Utilities
 * Retry logic, timeouts, and error detection for resilient network operations
 *
 * Agent CRM-34 Implementation
 */

// ============================================
// Types
// ============================================

export interface RetryOptions {
  /** Maximum number of retry attempts (default: 3) */
  maxRetries?: number;
  /** Base delay in ms before first retry (default: 1000) */
  baseDelay?: number;
  /** Maximum delay in ms between retries (default: 10000) */
  maxDelay?: number;
  /** Whether to use jitter (randomization) in backoff (default: true) */
  useJitter?: boolean;
  /** Function to determine if error should trigger retry */
  shouldRetry?: (error: unknown, attempt: number) => boolean;
  /** Callback called before each retry attempt */
  onRetry?: (error: unknown, attempt: number, delay: number) => void;
}

export interface NetworkError extends Error {
  isNetworkError: true;
  originalError?: unknown;
  attemptNumber?: number;
}

// ============================================
// Constants
// ============================================

const DEFAULT_RETRY_OPTIONS: Required<RetryOptions> = {
  maxRetries: 3,
  baseDelay: 1000,
  maxDelay: 10000,
  useJitter: true,
  shouldRetry: isNetworkError,
  onRetry: () => {},
};

// ============================================
// Error Detection
// ============================================

/**
 * Check if an error is network-related
 *
 * @param error - Error to check
 * @returns True if error is network-related
 *
 * @example
 * ```ts
 * try {
 *   await fetchData();
 * } catch (err) {
 *   if (isNetworkError(err)) {
 *     console.log('Network issue detected');
 *   }
 * }
 * ```
 */
export function isNetworkError(error: unknown): boolean {
  if (!error) return false;

  // Check for explicit network error flag
  if ((error as NetworkError).isNetworkError) {
    return true;
  }

  // Check error message patterns
  if (error instanceof Error) {
    const message = error.message.toLowerCase();
    const networkPatterns = [
      'network',
      'fetch',
      'timeout',
      'connection',
      'offline',
      'unreachable',
      'socket',
      'econnrefused',
      'enotfound',
      'etimedout',
      'cors',
      'failed to fetch',
    ];
    return networkPatterns.some((pattern) => message.includes(pattern));
  }

  // Check for specific error types
  if (error instanceof TypeError && error.message.includes('fetch')) {
    return true;
  }

  // Check for Firestore network errors
  if (typeof error === 'object' && error !== null) {
    const code = (error as { code?: string }).code;
    if (code) {
      const firestoreNetworkCodes = [
        'unavailable',
        'deadline-exceeded',
        'resource-exhausted',
        'cancelled',
      ];
      return firestoreNetworkCodes.includes(code);
    }
  }

  return false;
}

/**
 * Check if an error is an authentication error
 *
 * @param error - Error to check
 * @returns True if error is auth-related
 */
export function isAuthError(error: unknown): boolean {
  if (!error) return false;

  if (error instanceof Error) {
    const message = error.message.toLowerCase();
    if (message.includes('auth') || message.includes('unauthorized') || message.includes('permission')) {
      return true;
    }
  }

  if (typeof error === 'object' && error !== null) {
    const code = (error as { code?: string }).code;
    if (code) {
      const authCodes = [
        'permission-denied',
        'unauthenticated',
        'invalid-token',
        'token-expired',
      ];
      return authCodes.includes(code);
    }
  }

  return false;
}

// ============================================
// Retry Logic
// ============================================

/**
 * Calculate delay for exponential backoff with optional jitter
 *
 * @param attempt - Current attempt number (1-based)
 * @param baseDelay - Base delay in ms
 * @param maxDelay - Maximum delay in ms
 * @param useJitter - Whether to add randomization
 * @returns Delay in ms
 */
function calculateBackoff(
  attempt: number,
  baseDelay: number,
  maxDelay: number,
  useJitter: boolean
): number {
  // Exponential backoff: baseDelay * 2^(attempt - 1)
  const exponentialDelay = baseDelay * Math.pow(2, attempt - 1);

  // Cap at maxDelay
  const cappedDelay = Math.min(exponentialDelay, maxDelay);

  // Add jitter (randomize between 50% and 100% of calculated delay)
  if (useJitter) {
    const jitterFactor = 0.5 + Math.random() * 0.5;
    return Math.floor(cappedDelay * jitterFactor);
  }

  return cappedDelay;
}

/**
 * Sleep for specified duration
 *
 * @param ms - Duration in milliseconds
 * @returns Promise that resolves after delay
 */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Retry a function with exponential backoff and jitter
 *
 * @param fn - Async function to retry
 * @param options - Retry configuration
 * @returns Promise resolving to function result
 *
 * @example
 * ```ts
 * const data = await retry(
 *   async () => {
 *     const response = await fetch('/api/data');
 *     return response.json();
 *   },
 *   {
 *     maxRetries: 3,
 *     baseDelay: 1000,
 *     onRetry: (err, attempt, delay) => {
 *       console.log(`Retry ${attempt} after ${delay}ms:`, err);
 *     },
 *   }
 * );
 * ```
 */
export async function retry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {}
): Promise<T> {
  const opts = { ...DEFAULT_RETRY_OPTIONS, ...options };
  let lastError: unknown;

  for (let attempt = 1; attempt <= opts.maxRetries + 1; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      // Don't retry if we've exhausted attempts
      if (attempt > opts.maxRetries) {
        break;
      }

      // Check if we should retry this error
      if (!opts.shouldRetry(error, attempt)) {
        break;
      }

      // Calculate backoff delay
      const delay = calculateBackoff(
        attempt,
        opts.baseDelay,
        opts.maxDelay,
        opts.useJitter
      );

      // Call retry callback
      opts.onRetry(error, attempt, delay);

      // Wait before retrying
      await sleep(delay);
    }
  }

  // All retries exhausted or error not retryable
  const networkError = new Error(
    lastError instanceof Error
      ? lastError.message
      : 'Operation failed after retries'
  ) as NetworkError;
  networkError.isNetworkError = true;
  networkError.originalError = lastError;
  throw networkError;
}

// ============================================
// Timeout Utilities
// ============================================

/**
 * Add a timeout to a promise
 *
 * @param promise - Promise to add timeout to
 * @param ms - Timeout duration in milliseconds
 * @param timeoutError - Optional custom error message
 * @returns Promise that rejects on timeout
 *
 * @example
 * ```ts
 * try {
 *   const data = await withTimeout(
 *     fetch('/api/slow-endpoint'),
 *     5000,
 *     'Request took too long'
 *   );
 * } catch (err) {
 *   if (isNetworkError(err)) {
 *     console.log('Timeout or network error');
 *   }
 * }
 * ```
 */
export async function withTimeout<T>(
  promise: Promise<T>,
  ms: number,
  timeoutError?: string
): Promise<T> {
    let timeoutId: number | undefined;

  const timeoutPromise = new Promise<never>((_, reject) => {
    timeoutId = setTimeout(() => {
      const error = new Error(
        timeoutError || `Operation timed out after ${ms}ms`
      ) as NetworkError;
      error.isNetworkError = true;
      reject(error);
    }, ms) as unknown as number;
  });

  try {
    return await Promise.race([promise, timeoutPromise]);
  } finally {
    clearTimeout(timeoutId as number);
  }
}

// ============================================
// Composite Utilities
// ============================================

/**
 * Retry a function with timeout on each attempt
 *
 * @param fn - Async function to retry
 * @param timeoutMs - Timeout for each attempt
 * @param retryOptions - Retry configuration
 * @returns Promise resolving to function result
 *
 * @example
 * ```ts
 * const data = await retryWithTimeout(
 *   async () => {
 *     const response = await fetch('/api/data');
 *     return response.json();
 *   },
 *   5000, // 5 second timeout per attempt
 *   { maxRetries: 3 }
 * );
 * ```
 */
export async function retryWithTimeout<T>(
  fn: () => Promise<T>,
  timeoutMs: number,
  retryOptions: RetryOptions = {}
): Promise<T> {
  return retry(
    () => withTimeout(fn(), timeoutMs),
    retryOptions
  );
}

// ============================================
// Online/Offline Detection
// ============================================

/**
 * Check if the browser is currently online
 *
 * @returns True if online
 */
export function isOnline(): boolean {
  return typeof navigator !== 'undefined' && navigator.onLine;
}

/**
 * Check if the browser is currently offline
 *
 * @returns True if offline
 */
export function isOffline(): boolean {
  return !isOnline();
}

/**
 * Wait for network to come back online
 *
 * @param timeoutMs - Maximum time to wait (default: no timeout)
 * @returns Promise that resolves when online or rejects on timeout
 *
 * @example
 * ```ts
 * try {
 *   await waitForOnline(30000); // Wait up to 30 seconds
 *   console.log('Back online!');
 * } catch (err) {
 *   console.log('Still offline after timeout');
 * }
 * ```
 */
export function waitForOnline(timeoutMs?: number): Promise<void> {
  if (isOnline()) {
    return Promise.resolve();
  }

  const onlinePromise = new Promise<void>((resolve) => {
    const handler = () => {
      window.removeEventListener('online', handler);
      resolve();
    };
    window.addEventListener('online', handler);
  });

  if (timeoutMs) {
    return withTimeout(onlinePromise, timeoutMs, 'Timeout waiting for network');
  }

  return onlinePromise;
}
