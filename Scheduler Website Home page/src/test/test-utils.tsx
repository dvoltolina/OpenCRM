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

// Simple container style for chart tests to avoid zero-width warnings
export const chartContainerStyle: React.CSSProperties = {
  width: 400,
  height: 240,
};
