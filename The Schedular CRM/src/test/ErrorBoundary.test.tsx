import { render, screen } from '@testing-library/react';
import { vi } from 'vitest';
import { ErrorBoundary } from '../components/ErrorBoundary';

// Mock Firebase
vi.mock('../lib/firebase', () => ({
  getFirebaseAnalytics: vi.fn(() => ({})),
}));

// Mock Firebase Analytics
vi.mock('firebase/analytics', () => ({
  logEvent: vi.fn(),
  getAnalytics: vi.fn(),
  isSupported: vi.fn(() => Promise.resolve(false)),
}));

// Component that throws
const Bomb = () => {
  throw new Error('Test Crash');
};

describe('ErrorBoundary', () => {
  const originalConsoleError = console.error;
  
  beforeAll(() => {
    // Suppress console.error for the test since we expect a crash
    console.error = vi.fn();
  });

  afterAll(() => {
    console.error = originalConsoleError;
  });

  it('renders children when no error occurs', () => {
    render(
      <ErrorBoundary>
        <div>Healthy Content</div>
      </ErrorBoundary>
    );
    expect(screen.getByText('Healthy Content')).toBeDefined();
  });

  it('renders fallback UI when a child crashes', () => {
    render(
      <ErrorBoundary>
        <Bomb />
      </ErrorBoundary>
    );
    
    expect(screen.getByText('Something went wrong')).toBeDefined();
    expect(screen.getByText("We've logged the error and notified our team.")).toBeDefined();
  });
});
