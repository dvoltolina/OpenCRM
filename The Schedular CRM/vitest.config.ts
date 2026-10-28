import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

// Suppress noisy localstorage-file warnings emitted by Node when no path is provided
const originalEmitWarning = process.emitWarning;
process.emitWarning = ((warning: unknown, ...args: unknown[]) => {
  const message = typeof warning === 'string' ? warning : (warning as { message?: string })?.message;
  if (message && message.includes('localstorage-file was provided without a valid path')) {
    return;
  }
  return originalEmitWarning.call(process, warning as Error | string, ...(args as []));
}) as typeof process.emitWarning;

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    exclude: (() => {
      const baseExcludes = ['**/node_modules/**', '**/dist/**'];
      const shouldRunFirestore = process.env.RUN_FIRESTORE === 'true';
      if (shouldRunFirestore) {
        return baseExcludes;
      }
      return [
        ...baseExcludes,
        // Integration/rules suites are skipped by default; toggle RUN_FIRESTORE=true to include
        'test/integration/**',
        'tests/firestore-rules/**',
        'test/security/firestore_rules.test.ts',
      ];
    })(),
    include: [
      'src/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}',
      'test/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}',
      'tests/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}',
    ],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'src/test/',
        '**/*.d.ts',
        '**/*.config.*',
      ],
    },
  },
});
