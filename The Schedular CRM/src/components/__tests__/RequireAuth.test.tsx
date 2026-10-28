/**
 * RequireAuth Component Tests
 *
 * Tests for businessId validation and tenant isolation enforcement.
 * HIPAA/Security Compliance: Ensures no default businessId fallbacks.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { RequireAuth } from '../RequireAuth';
import type { User } from 'firebase/auth';
import type { CRMUser } from '../../types/models';

// Mock AuthContext
vi.mock('../../context/AuthContext', () => ({
  useAuth: vi.fn(),
}));

import { useAuth } from '../../context/AuthContext';
const mockUseAuth = vi.mocked(useAuth);

describe('RequireAuth - BusinessId Validation', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should redirect to /business-required when businessId is missing', () => {
    const mockUser: Partial<User> = {
      uid: 'test-uid',
      email: 'test@example.com',
    };

    const mockCrmUser: Partial<CRMUser> = {
      id: 'test-uid',
      email: 'test@example.com',
      displayName: 'Test User',
      role: 'staff',
      businessId: undefined, // Missing businessId
      createdAt: new Date(),
    };

    mockUseAuth.mockReturnValue({
      user: mockUser as User,
      crmUser: mockCrmUser as CRMUser,
      businessId: null, // No businessId
      isLoading: false,
      status: 'authenticated',
      requiresMfa: false,
      mfaResolver: null,
      mfaEnrollmentRequired: false,
      error: null,
      signIn: vi.fn(),
      signOut: vi.fn(),
      refreshAuthState: vi.fn(),
      hasRole: vi.fn(),
    });

    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <Routes>
          <Route element={<RequireAuth />}>
            <Route path="/dashboard" element={<div>Dashboard</div>} />
          </Route>
          <Route path="/business-required" element={<div>Business Required</div>} />
        </Routes>
      </MemoryRouter>
    );

    expect(screen.getByText('Business Required')).toBeInTheDocument();
  });

  it('should redirect to /business-required when crmUser.businessId is missing', () => {
    const mockUser: Partial<User> = {
      uid: 'test-uid',
      email: 'test@example.com',
    };

    const mockCrmUser: Partial<CRMUser> = {
      id: 'test-uid',
      email: 'test@example.com',
      displayName: 'Test User',
      role: 'staff',
      businessId: '', // Empty businessId
      createdAt: new Date(),
    };

    mockUseAuth.mockReturnValue({
      user: mockUser as User,
      crmUser: mockCrmUser as CRMUser,
      businessId: '', // Empty businessId
      isLoading: false,
      status: 'authenticated',
      requiresMfa: false,
      mfaResolver: null,
      mfaEnrollmentRequired: false,
      error: null,
      signIn: vi.fn(),
      signOut: vi.fn(),
      refreshAuthState: vi.fn(),
      hasRole: vi.fn(),
    });

    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <Routes>
          <Route element={<RequireAuth />}>
            <Route path="/dashboard" element={<div>Dashboard</div>} />
          </Route>
          <Route path="/business-required" element={<div>Business Required</div>} />
        </Routes>
      </MemoryRouter>
    );

    expect(screen.getByText('Business Required')).toBeInTheDocument();
  });

  it('should allow access when valid businessId is present', () => {
    const mockUser: Partial<User> = {
      uid: 'test-uid',
      email: 'test@example.com',
    };

    const mockCrmUser: Partial<CRMUser> = {
      id: 'test-uid',
      email: 'test@example.com',
      displayName: 'Test User',
      role: 'staff',
      businessId: 'valid-business-123', // Valid businessId
      createdAt: new Date(),
    };

    mockUseAuth.mockReturnValue({
      user: mockUser as User,
      crmUser: mockCrmUser as CRMUser,
      businessId: 'valid-business-123', // Valid businessId
      isLoading: false,
      status: 'authenticated',
      requiresMfa: false,
      mfaResolver: null,
      mfaEnrollmentRequired: false,
      error: null,
      signIn: vi.fn(),
      signOut: vi.fn(),
      refreshAuthState: vi.fn(),
      hasRole: vi.fn(),
    });

    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <Routes>
          <Route element={<RequireAuth />}>
            <Route path="/dashboard" element={<div>Dashboard Content</div>} />
          </Route>
          <Route path="/business-required" element={<div>Business Required</div>} />
        </Routes>
      </MemoryRouter>
    );

    expect(screen.getByText('Dashboard Content')).toBeInTheDocument();
  });

  it('should show loading screen when isLoading is true', () => {
    mockUseAuth.mockReturnValue({
      user: null,
      crmUser: null,
      businessId: null,
      isLoading: true,
      status: 'loading',
      requiresMfa: false,
      mfaResolver: null,
      mfaEnrollmentRequired: false,
      error: null,
      signIn: vi.fn(),
      signOut: vi.fn(),
      refreshAuthState: vi.fn(),
      hasRole: vi.fn(),
    });

    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <Routes>
          <Route element={<RequireAuth />}>
            <Route path="/dashboard" element={<div>Dashboard</div>} />
          </Route>
        </Routes>
      </MemoryRouter>
    );

    expect(screen.getByText('Loading session...')).toBeInTheDocument();
  });

  it('should redirect to login when user is not authenticated', () => {
    mockUseAuth.mockReturnValue({
      user: null,
      crmUser: null,
      businessId: null,
      isLoading: false,
      status: 'unauthenticated',
      requiresMfa: false,
      mfaResolver: null,
      mfaEnrollmentRequired: false,
      error: null,
      signIn: vi.fn(),
      signOut: vi.fn(),
      refreshAuthState: vi.fn(),
      hasRole: vi.fn(),
    });

    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <Routes>
          <Route element={<RequireAuth />}>
            <Route path="/dashboard" element={<div>Dashboard</div>} />
          </Route>
          <Route path="/login" element={<div>Login Page</div>} />
        </Routes>
      </MemoryRouter>
    );

    expect(screen.getByText('Login Page')).toBeInTheDocument();
  });
});
