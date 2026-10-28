/**
 * Exponential backoff helper with jitter.
 * Shared by integration/webhook services to avoid duplicating retry logic.
 */

export interface BackoffOptions<T> {
  maxAttempts?: number;
  baseDelayMs?: number;
  jitterMs?: number;
  shouldRetry?: (error: unknown) => boolean;
  sleepFn?: (ms: number) => Promise<void>;
  onRetry?: (attempt: number, delayMs: number, error: unknown) => void;
  operation: () => Promise<T>;
}

const defaultSleep = (ms: number) =>
  new Promise<void>((resolve) => setTimeout(resolve, ms));

export async function withExponentialBackoff<T>(
  options: BackoffOptions<T>
): Promise<{ result?: T; attempts: number; backoffMs?: number; error?: unknown }> {
  const {
    operation,
    maxAttempts = 3,
    baseDelayMs = 200,
    jitterMs = 50,
    shouldRetry = () => true,
    sleepFn = defaultSleep,
    onRetry,
  } = options;

  let attempt = 0;
  let lastError: unknown;
  let lastBackoffMs: number | undefined;

  while (attempt < maxAttempts) {
    try {
      const result = await operation();
      return { result, attempts: attempt + 1 };
    } catch (error) {
      lastError = error;
      attempt += 1;

      if (attempt >= maxAttempts || !shouldRetry(error)) {
        break;
      }

      const backoffMs = Math.min(
        baseDelayMs * Math.pow(2, attempt - 1) + Math.floor(Math.random() * jitterMs),
        10_000
      );
      lastBackoffMs = backoffMs;

      if (onRetry) {
        onRetry(attempt, backoffMs, error);
      }

      await sleepFn(backoffMs);
    }
  }

  return { attempts: attempt, backoffMs: lastBackoffMs, error: lastError };
}
