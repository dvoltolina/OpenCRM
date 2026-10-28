import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { BusinessRequiredPage } from '../BusinessRequiredPage';
import { LoginPage } from '../LoginPage';

const { authState, signInMock, signOutMock, navigateMock } = vi.hoisted(() => ({
  authState: {
    status: 'unauthenticated',
    error: null as string | null,
  },
  signInMock: vi.fn(),
  signOutMock: vi.fn(),
  navigateMock: vi.fn(),
}));

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom');
  return {
    ...actual,
    useNavigate: () => navigateMock,
  };
});

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    signIn: signInMock,
    signOut: signOutMock,
    error: authState.error,
    status: authState.status,
    user: { email: 'owner@example.com' },
    crmUser: {
      businessId: undefined,
    },
  }),
}));

describe('Auth shell pages', () => {
  beforeEach(() => {
    authState.status = 'unauthenticated';
    authState.error = null;
    signInMock.mockReset();
    signOutMock.mockReset();
    navigateMock.mockReset();
  });

  it('renders the login page and submits credentials through auth', async () => {
    render(
      <MemoryRouter initialEntries={['/login']}>
        <LoginPage />
      </MemoryRouter>
    );

    fireEvent.change(screen.getByLabelText('Email'), { target: { value: 'owner@example.com' } });
    fireEvent.change(screen.getByLabelText('Password'), { target: { value: 'secret123' } });
    fireEvent.click(screen.getByRole('button', { name: 'Sign In' }));

    await waitFor(() => {
      expect(signInMock).toHaveBeenCalledWith('owner@example.com', 'secret123');
    });
  });

  it('renders the workspace-required page and signs the user out', async () => {
    render(<BusinessRequiredPage />);

    expect(screen.getByText('Workspace required')).toBeInTheDocument();
    expect(screen.getByText('owner@example.com')).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: 'Sign out' }));

    await waitFor(() => {
      expect(signOutMock).toHaveBeenCalled();
    });
  });
});
