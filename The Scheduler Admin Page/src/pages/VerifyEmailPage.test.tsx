import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { describe, expect, it, beforeEach, vi } from 'vitest';
import { MemoryRouter } from 'react-router-dom';

import { VerifyEmailPage } from './VerifyEmailPage';
import type { AuthState } from '../types/auth';

const mocks = vi.hoisted(() => ({
  mockApplyActionCode: vi.fn(),
  mockNavigate: vi.fn(),
  mockRefreshUser: vi.fn(),
  mockSendVerification: vi.fn(),
  mockSignOut: vi.fn(),
  mockAuth: { app: 'auth' },
}));

const {
  mockApplyActionCode,
  mockNavigate,
  mockRefreshUser,
  mockSendVerification,
  mockSignOut,
  mockAuth,
} = mocks;

let authState: AuthState;

vi.mock('firebase/auth', () => ({
  applyActionCode: mocks.mockApplyActionCode,
}));

vi.mock('../lib/firebase', () => ({
  getFirebaseAuth: vi.fn(() => mocks.mockAuth),
}));

vi.mock('../context/AuthContext', () => ({
  useAuth: () => ({
    state: authState,
    sendVerification: mocks.mockSendVerification,
    refreshUser: mocks.mockRefreshUser,
    signOut: mocks.mockSignOut,
  }),
}));

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom');
  return {
    ...actual,
    useNavigate: () => mocks.mockNavigate,
  };
});

describe('VerifyEmailPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockApplyActionCode.mockResolvedValue(undefined);
    mockRefreshUser.mockResolvedValue(undefined);
    mockSendVerification.mockResolvedValue(undefined);
    mockSignOut.mockResolvedValue(undefined);
    mockNavigate.mockReset();

    authState = {
      status: 'pending_verification',
      user: {
        uid: 'user-1',
        email: 'owner@example.com',
        displayName: 'Owner',
        emailVerified: false,
      },
    };
  });

  it('applies the verification code and refreshes status when a verification link is opened', async () => {
    render(
      <MemoryRouter initialEntries={['/verify-email?mode=verifyEmail&oobCode=test-code']}>
        <VerifyEmailPage />
      </MemoryRouter>,
    );

    await waitFor(() => expect(mockApplyActionCode).toHaveBeenCalledWith(mockAuth, 'test-code'));
    expect(mockRefreshUser).toHaveBeenCalledTimes(1);
    expect(mockSendVerification).not.toHaveBeenCalled();
  });

  it('automatically checks verification status on load when no link is present', async () => {
    render(
      <MemoryRouter initialEntries={['/verify-email']}>
        <VerifyEmailPage />
      </MemoryRouter>,
    );

    await waitFor(() => expect(mockRefreshUser).toHaveBeenCalledTimes(1));
    await waitFor(() => expect(mockSendVerification).toHaveBeenCalledTimes(1));
    expect(mockApplyActionCode).not.toHaveBeenCalled();
  });

  it('signs out before navigating back to login', async () => {
    let resolveSignOut: (() => void) | null = null;
    mockSignOut.mockImplementation(
      () =>
        new Promise<void>((resolve) => {
          resolveSignOut = resolve;
        }),
    );

    render(
      <MemoryRouter initialEntries={['/verify-email']}>
        <VerifyEmailPage />
      </MemoryRouter>,
    );

    await waitFor(() => expect(mockRefreshUser).toHaveBeenCalledTimes(1));
    await waitFor(() => expect(mockSendVerification).toHaveBeenCalledTimes(1));
    const backButton = screen.getByRole('button', { name: /back to login/i });
    await waitFor(() => expect(backButton).not.toBeDisabled());

    fireEvent.click(backButton);
    expect(mockNavigate).not.toHaveBeenCalled();

    resolveSignOut?.();

    await waitFor(() =>
      expect(mockNavigate).toHaveBeenCalledWith('/login', { replace: true }),
    );
    expect(mockSignOut).toHaveBeenCalledTimes(1);
  });
});
