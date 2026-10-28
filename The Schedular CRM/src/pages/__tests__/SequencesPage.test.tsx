import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { SequencesPage } from '../SequencesPage';

const { featureFlags, useSequencesMock } = vi.hoisted(() => ({
  featureFlags: {
    enableSequences: true,
  },
  useSequencesMock: vi.fn(),
}));

vi.mock('../../config/features', () => ({
  getFeatureFlags: () => featureFlags,
}));

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser: {
      id: 'user-1',
      displayName: 'Owner User',
    },
  }),
}));

vi.mock('../../hooks/useSequences', () => ({
  useSequences: (...args: unknown[]) => useSequencesMock(...args),
  useSequenceMutations: () => ({
    duplicateSequence: vi.fn(),
    archiveSequence: vi.fn(),
    activateSequence: vi.fn(),
    pauseSequence: vi.fn(),
    isMutating: false,
  }),
}));

vi.mock('../../components/sequences/SequenceList', () => ({
  SequenceList: ({ sequences }: { sequences: Array<{ id: string }> }) => (
    <div>Sequence List {sequences.length}</div>
  ),
}));

describe('SequencesPage', () => {
  beforeEach(() => {
    featureFlags.enableSequences = true;
    useSequencesMock.mockReturnValue({
      sequences: [
        {
          id: 'sequence-1',
          name: 'Reactivation',
          description: 'Bring older leads back into pipeline.',
          status: 'active',
          steps: [{ id: 'step-1' }],
          ownerName: 'Owner User',
          stats: {
            totalEnrolled: 12,
            activeEnrollments: 8,
            completedCount: 5,
          },
          createdAt: new Date('2026-03-10T10:00:00Z'),
          updatedAt: new Date('2026-03-18T10:00:00Z'),
        },
      ],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
      getAccessSummary: vi.fn(() => ({ canEdit: true, canDelete: true })),
    });
  });

  it('renders the feature-locked prompt when sequences are disabled', () => {
    featureFlags.enableSequences = false;

    render(
      <MemoryRouter>
        <SequencesPage />
      </MemoryRouter>
    );

    expect(screen.getByTestId('sequences-upgrade-prompt')).toBeInTheDocument();
    expect(screen.getByText(/Contact your administrator to enable this feature/)).toBeInTheDocument();
  });

  it('renders the sequence workspace when the feature is enabled', () => {
    render(
      <MemoryRouter>
        <SequencesPage />
      </MemoryRouter>
    );

    expect(screen.getByRole('button', { name: 'Create Sequence' })).toBeInTheDocument();
    expect(screen.getByText('Sequence List 1')).toBeInTheDocument();
    expect(screen.getByTestId('stat-active')).toHaveTextContent('1');
  });
});
