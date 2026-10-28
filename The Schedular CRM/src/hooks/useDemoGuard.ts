import { useEffect, useState } from 'react';
import {
  DEMO_ACTION_BLOCKED_EVENT,
  DEMO_DISABLED_ACTION_MESSAGE,
  type DemoActionBlockedDetail,
  isDemoMode,
  notifyDemoActionBlocked,
} from '../config/demo';

interface DemoGuardOptions {
  action?: string;
  message?: string;
}

function createHandledRejection<T>(message?: string, action?: string): Promise<T> {
  const rejected = Promise.reject(
    notifyDemoActionBlocked({
      action,
      message,
    })
  );
  void rejected.catch(() => undefined);
  return rejected;
}

export function useDemoGuard() {
  // This helper is intentionally hook-free so it can be safely used
  // from any render path without depending on React dispatcher state.
  const notifyBlocked = (options?: DemoGuardOptions) =>
    notifyDemoActionBlocked({
      action: options?.action,
      message: options?.message,
    });

  const guardMutation = <T extends (...args: any[]) => Promise<any>>(
    fn: T,
    options?: DemoGuardOptions
  ): T => {
    if (!isDemoMode) {
      return fn;
    }

    return ((..._args: Parameters<T>) =>
      createHandledRejection<Awaited<ReturnType<T>>>(options?.message, options?.action)) as T;
  };

  const guardAction = <T extends (...args: any[]) => void>(
    fn: T,
    options?: DemoGuardOptions
  ): T => {
    if (!isDemoMode) {
      return fn;
    }

    return ((..._args: Parameters<T>) => {
      notifyBlocked(options);
    }) as T;
  };

  return {
    isDemo: isDemoMode,
    guardAction,
    guardMutation,
    notifyBlocked,
    disabledMessage: DEMO_DISABLED_ACTION_MESSAGE,
  };
}

export function useDemoBlockedMessage(timeoutMs = 3200) {
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    if (typeof window === 'undefined') {
      return undefined;
    }

    let timeoutId: number | null = null;

    const handleBlocked = (event: Event) => {
      const detail = (event as CustomEvent<DemoActionBlockedDetail>).detail;
      setMessage(detail?.message || DEMO_DISABLED_ACTION_MESSAGE);

      if (timeoutId) {
        window.clearTimeout(timeoutId);
      }
      timeoutId = window.setTimeout(() => {
        setMessage(null);
        timeoutId = null;
      }, timeoutMs);
    };

    window.addEventListener(DEMO_ACTION_BLOCKED_EVENT, handleBlocked as EventListener);

    return () => {
      window.removeEventListener(DEMO_ACTION_BLOCKED_EVENT, handleBlocked as EventListener);
      if (timeoutId) {
        window.clearTimeout(timeoutId);
      }
    };
  }, [timeoutMs]);

  return {
    clearMessage: () => setMessage(null),
    message,
  };
}
