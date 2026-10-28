import { fireEvent, render, screen } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { WebFormsPage } from '../WebFormsPage';

const {
  featureFlagsState,
  useWebFormsMock,
  modalState,
  useModalMock,
} = vi.hoisted(() => ({
  featureFlagsState: { enabled: true },
  useWebFormsMock: vi.fn(),
  modalState: {
    counter: 0,
    formBuilder: { isOpen: false, data: null, open: vi.fn(), close: vi.fn() },
    embedCode: { isOpen: false, data: null, open: vi.fn(), close: vi.fn() },
  },
  useModalMock: vi.fn(),
}));

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser: {
      id: 'user-1',
      businessId: 'biz-1',
      displayName: 'Owner User',
      email: 'owner@example.com',
      role: 'owner',
      teamIds: [],
      managedTeamIds: [],
      managerId: undefined,
    },
  }),
}));

vi.mock('../../hooks/useFeatureFlags', () => ({
  useFeatureFlags: () => ({
    isEnabled: () => featureFlagsState.enabled,
  }),
}));

vi.mock('../../hooks/useWebForms', () => ({
  useWebForms: (...args: unknown[]) => useWebFormsMock(...args),
}));

vi.mock('../../hooks', () => ({
  useModal: (...args: unknown[]) => useModalMock(...args),
}));

vi.mock('../../lib/security-context', () => ({
  createSecurityContextFromParams: () => ({
    businessId: 'biz-1',
    userId: 'user-1',
  }),
}));

vi.mock('../../components/web-forms/FormBuilder', () => ({
  FormBuilder: () => <div>Form Builder</div>,
}));

vi.mock('../../components/web-forms/EmbedCodeModal', () => ({
  EmbedCodeModal: () => <div>Embed Code Modal</div>,
}));

describe('WebFormsPage', () => {
  beforeEach(() => {
    featureFlagsState.enabled = true;
    modalState.counter = 0;
    modalState.formBuilder = { isOpen: false, data: null, open: vi.fn(), close: vi.fn() };
    modalState.embedCode = { isOpen: false, data: null, open: vi.fn(), close: vi.fn() };
    useModalMock.mockImplementation(() => {
      modalState.counter += 1;
      return modalState.counter === 1 ? modalState.formBuilder : modalState.embedCode;
    });
    useWebFormsMock.mockReturnValue({
      forms: [
        {
          id: 'form-1',
          name: 'Homepage Demo',
          description: 'Primary capture form',
          status: 'active',
          fields: [{ id: 'field-1' }],
          stats: { totalSubmissions: 15, submissionsThisMonth: 4 },
          createdAt: new Date('2026-03-01T00:00:00Z'),
          settings: {},
        },
        {
          id: 'form-2',
          name: 'Events Signup',
          description: 'Tradeshow intake',
          status: 'inactive',
          fields: [{ id: 'field-2' }],
          stats: { totalSubmissions: 7, submissionsThisMonth: 1 },
          createdAt: new Date('2026-03-05T00:00:00Z'),
          settings: {},
        },
      ],
      isLoading: false,
      error: null,
      refetch: vi.fn(),
      updateForm: vi.fn(),
      deleteForm: vi.fn(),
    });
  });

  it('renders the feature-locked state when web forms are disabled', () => {
    featureFlagsState.enabled = false;

    render(<WebFormsPage />);

    expect(screen.getByText('Web forms are disabled')).toBeInTheDocument();
  });

  it('renders the web forms workspace and filters the visible list', () => {
    render(<WebFormsPage />);

    expect(screen.getByText('Web Forms')).toBeInTheDocument();
    expect(screen.getByText('Homepage Demo')).toBeInTheDocument();
    expect(screen.getByText('Events Signup')).toBeInTheDocument();

    fireEvent.change(screen.getByLabelText('Search'), { target: { value: 'Homepage' } });

    expect(screen.getByText('Homepage Demo')).toBeInTheDocument();
    expect(screen.queryByText('Events Signup')).not.toBeInTheDocument();
  });
});
