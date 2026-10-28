import React from 'react';
import { act, renderHook, type RenderHookOptions, type RenderHookResult } from '@testing-library/react';

// Helper to wrap renderHook calls in act to avoid noisy warnings
export async function renderHookWithAct<Result, Props>(
  callback: (initialProps: Props) => Result,
  options?: RenderHookOptions<Props>
): Promise<RenderHookResult<Result, Props>> {
  const result = renderHook(callback, options);
  await act(async () => {
    // allow pending state updates to flush
  });
  return result;
}

// Shared chart container sizing to avoid zero-dimension warnings in Recharts
export const chartContainerStyle: React.CSSProperties = {
  width: 400,
  height: 240,
};

// Force a DOMRect size for elements that Recharts measures (JSDOM returns 0 by default)
export function setElementDimensions(
  element: HTMLElement | null,
  width = chartContainerStyle.width as number,
  height = chartContainerStyle.height as number
) {
  if (!element) return;
  Object.defineProperty(element, 'getBoundingClientRect', {
    configurable: true,
    value: () => ({
      width,
      height,
      top: 0,
      left: 0,
      right: width,
      bottom: height,
      x: 0,
      y: 0,
      toJSON: () => ({}),
    }),
  });
}

// Provide reusable mocks so Recharts receives non-zero dimensions in jsdom
export function setupChartResizeMocks(
  width = (chartContainerStyle.width as number) || 800,
  height = (chartContainerStyle.height as number) || 400
) {
  const originalResizeObserver = (window as any).ResizeObserver;
  const originalGetBoundingClientRect = HTMLElement.prototype.getBoundingClientRect;

  class MockResizeObserver {
    private readonly callback: ResizeObserverCallback;

    constructor(callback: ResizeObserverCallback) {
      this.callback = callback;
    }

    observe(target: Element) {
      this.callback(
        [
          {
            target,
            contentRect: {
              width,
              height,
              top: 0,
              left: 0,
              bottom: height,
              right: width,
              x: 0,
              y: 0,
            },
          } as ResizeObserverEntry,
        ],
        this as unknown as ResizeObserver
      );
    }

    unobserve() {}
    disconnect() {}
  }

  (window as any).ResizeObserver = MockResizeObserver as unknown as typeof ResizeObserver;
  (HTMLElement.prototype as any).getBoundingClientRect = () => ({
    width,
    height,
    top: 0,
    left: 0,
    right: width,
    bottom: height,
    x: 0,
    y: 0,
    toJSON: () => ({}),
  });

  return () => {
    (window as any).ResizeObserver = originalResizeObserver;
    HTMLElement.prototype.getBoundingClientRect = originalGetBoundingClientRect;
  };
}

// Suppress noisy act() warnings during tests while preserving other errors
const originalError = console.error;
const filteredConsoleError = (...args: unknown[]) => {
  if (
    typeof args[0] === 'string' &&
    (args[0].includes('not wrapped in act') ||
      args[0].includes('not configured to support act') ||
      args[0].includes('width(-1) and height(-1)'))
  ) {
    return;
  }
  originalError.call(console, ...args);
};
console.error = filteredConsoleError;

// Suppress specific chart sizing warnings that are expected in JSDOM
const originalWarn = console.warn;
const filteredConsoleWarn = (...args: unknown[]) => {
  if (
    typeof args[0] === 'string' &&
    (args[0].includes('not configured to support act') ||
      args[0].includes('width(-1) and height(-1)') ||
      args[0].includes('width(0) and height(0)'))
  ) {
    return;
  }
  originalWarn.call(console, ...args);
};
console.warn = filteredConsoleWarn;
