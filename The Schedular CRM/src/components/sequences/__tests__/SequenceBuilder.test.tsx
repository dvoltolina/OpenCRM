/**
 * SequenceBuilder Tests
 *
 * Test Scenarios:
 * 1. Renders empty builder for new sequence
 * 2. Loads existing sequence for edit
 * 3. Add step works for each type
 * 4. Remove step with confirmation
 * 5. Validation errors display correctly
 * 6. Save creates/updates sequence
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { SequenceBuilder } from '../SequenceBuilder';
import type { Sequence, SequenceStep } from '../../../types/sequences';

// ============================================
// Mocks
// ============================================

const mockNavigate = vi.fn();
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom');
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  };
});

// Mock useSequenceBuilder hook
const mockSave = vi.fn();
const mockAddStep = vi.fn();
const mockRemoveStep = vi.fn();
const mockUpdateStep = vi.fn();
const mockReorderSteps = vi.fn();
const mockSetName = vi.fn();
const mockSetDescription = vi.fn();
const mockUpdateSettings = vi.fn();

vi.mock('../../../hooks/useSequenceBuilder', () => ({
  useSequenceBuilder: vi.fn(),
}));

// Mock useSequenceMutations hook
vi.mock('../../../hooks/useSequences', () => ({
  useSequenceMutations: vi.fn(() => ({
    activateSequence: vi.fn(),
    pauseSequence: vi.fn(),
    isMutating: false,
  })),
}));

import { useSequenceBuilder } from '../../../hooks/useSequenceBuilder';
const mockedUseSequenceBuilder = vi.mocked(useSequenceBuilder);

// ============================================
// Test Data
// ============================================

const mockSequence: Sequence = {
  id: 'seq-1',
  name: 'Test Sequence',
  description: 'A test sequence',
  status: 'draft',
  steps: [],
  settings: {
    sendingSchedule: {
      timezone: 'America/New_York',
      businessHoursOnly: true,
      startHour: 9,
      endHour: 17,
      excludeDays: [0, 6],
    },
    pauseOnReply: true,
    pauseOnOpen: false,
    pauseOnMeetingBooked: true,
    removeOnUnsubscribe: true,
    threadEmails: false,
  },
  stats: {
    totalEnrolled: 0,
    activeEnrollments: 0,
    completedCount: 0,
    exitedCount: 0,
  },
  ownerId: 'user-1',
  ownerName: 'Test User',
  teamIds: [],
  visibility: 'team',
  createdAt: new Date(),
};

const mockSteps: SequenceStep[] = [
  {
    id: 'step-1',
    order: 0,
    type: 'email',
    delayDays: 0,
    isActive: true,
    emailConfig: {
      subject: 'Hello {{firstName}}',
      body: 'This is a test email.',
    },
  },
  {
    id: 'step-2',
    order: 1,
    type: 'wait',
    delayDays: 2,
    isActive: true,
  },
  {
    id: 'step-3',
    order: 2,
    type: 'task',
    delayDays: 0,
    isActive: true,
    taskConfig: {
      title: 'Follow up call',
      assignToOwner: true,
      dueDays: 0,
    },
  },
];

const defaultBuilderState = {
  sequence: null,
  steps: [],
  settings: mockSequence.settings,
  name: '',
  description: '',
  isLoading: false,
  isSaving: false,
  hasChanges: false,
  validation: { isValid: true, errors: [] },
  durationDays: 0,
  setName: mockSetName,
  setDescription: mockSetDescription,
  addStep: mockAddStep,
  updateStep: mockUpdateStep,
  removeStep: mockRemoveStep,
  reorderSteps: mockReorderSteps,
  duplicateStep: vi.fn(),
  updateSettings: mockUpdateSettings,
  validate: vi.fn(() => ({ isValid: true, errors: [] })),
  save: mockSave,
  reset: vi.fn(),
};

// ============================================
// Wrapper Component
// ============================================

function renderBuilder(sequenceId?: string) {
  const path = sequenceId ? `/sequences/${sequenceId}` : '/sequences/new';
  return render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="/sequences/new" element={<SequenceBuilder />} />
        <Route path="/sequences/:id" element={<SequenceBuilder />} />
      </Routes>
    </MemoryRouter>
  );
}

// ============================================
// Tests
// ============================================

describe('SequenceBuilder', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockNavigate.mockClear();
  });

  // ============================================
  // Test 1: Renders empty builder for new sequence
  // ============================================
  it('renders empty builder for new sequence', () => {
    mockedUseSequenceBuilder.mockReturnValue(defaultBuilderState);

    renderBuilder();

    expect(screen.getByTestId('sequence-builder')).toBeInTheDocument();
    expect(screen.getByTestId('sequence-name-input')).toHaveValue('');
    expect(screen.getByTestId('add-first-step-btn')).toBeInTheDocument();
    expect(screen.getByText('Add your first step')).toBeInTheDocument();
  });

  // ============================================
  // Test 2: Loads existing sequence for edit
  // ============================================
  it('loads existing sequence for edit', () => {
    mockedUseSequenceBuilder.mockReturnValue({
      ...defaultBuilderState,
      sequence: mockSequence,
      steps: mockSteps,
      name: 'Test Sequence',
      description: 'A test sequence',
      durationDays: 3,
    });

    renderBuilder('seq-1');

    expect(screen.getByTestId('sequence-name-input')).toHaveValue('Test Sequence');
    expect(screen.getByTestId('step-card-step-1')).toBeInTheDocument();
    expect(screen.getByTestId('step-card-step-2')).toBeInTheDocument();
    expect(screen.getByTestId('step-card-step-3')).toBeInTheDocument();
  });

  // ============================================
  // Test 3: Add step works
  // ============================================
  it('opens step type selector when add step clicked', async () => {
    mockedUseSequenceBuilder.mockReturnValue(defaultBuilderState);

    renderBuilder();

    // Click add step button
    fireEvent.click(screen.getByTestId('add-first-step-btn'));

    // Step type selector should appear
    await waitFor(() => {
      expect(screen.getByTestId('step-type-selector')).toBeInTheDocument();
    });

    expect(screen.getByText('Email')).toBeInTheDocument();
    expect(screen.getByText('Task')).toBeInTheDocument();
    expect(screen.getByText('Wait')).toBeInTheDocument();
    expect(screen.getByText('Call')).toBeInTheDocument();
  });

  // ============================================
  // Test 4: Validation errors display correctly
  // ============================================
  it('displays validation errors', () => {
    mockedUseSequenceBuilder.mockReturnValue({
      ...defaultBuilderState,
      validation: {
        isValid: false,
        errors: [
          { field: 'name', message: 'Sequence name is required' },
          { field: 'steps', message: 'Sequence must have at least one step' },
        ],
      },
    });

    renderBuilder();

    expect(screen.getByText('Please fix the following issues:')).toBeInTheDocument();
    expect(screen.getByText('Sequence name is required')).toBeInTheDocument();
    expect(screen.getByText('Sequence must have at least one step')).toBeInTheDocument();
  });

  // ============================================
  // Test 5: Save button state
  // ============================================
  it('save button is disabled when no changes', () => {
    mockedUseSequenceBuilder.mockReturnValue({
      ...defaultBuilderState,
      hasChanges: false,
    });

    renderBuilder();

    expect(screen.getByTestId('save-sequence-btn')).toBeDisabled();
  });

  it('save button is enabled when has changes', () => {
    mockedUseSequenceBuilder.mockReturnValue({
      ...defaultBuilderState,
      hasChanges: true,
    });

    renderBuilder();

    expect(screen.getByTestId('save-sequence-btn')).not.toBeDisabled();
  });

  // ============================================
  // Test 6: Save calls save function
  // ============================================
  it('calls save when save button clicked', async () => {
    mockSave.mockResolvedValue({ ...mockSequence, id: 'seq-1' });

    mockedUseSequenceBuilder.mockReturnValue({
      ...defaultBuilderState,
      hasChanges: true,
    });

    renderBuilder();

    fireEvent.click(screen.getByTestId('save-sequence-btn'));

    await waitFor(() => {
      expect(mockSave).toHaveBeenCalled();
    });
  });

  // ============================================
  // Test 7: Back button navigates to list
  // ============================================
  it('navigates back when back button clicked', () => {
    mockedUseSequenceBuilder.mockReturnValue(defaultBuilderState);

    renderBuilder();

    const backButton = screen.getByLabelText('Back to sequences');
    fireEvent.click(backButton);

    expect(mockNavigate).toHaveBeenCalledWith('/sequences');
  });

  // ============================================
  // Test 8: Shows loading state
  // ============================================
  it('shows loading state when loading sequence', () => {
    mockedUseSequenceBuilder.mockReturnValue({
      ...defaultBuilderState,
      isLoading: true,
    });

    renderBuilder('seq-1');

    expect(screen.getByTestId('sequence-builder-loading')).toBeInTheDocument();
  });

  // ============================================
  // Test 9: Name input updates state
  // ============================================
  it('updates name when input changes', () => {
    mockedUseSequenceBuilder.mockReturnValue(defaultBuilderState);

    renderBuilder();

    const nameInput = screen.getByTestId('sequence-name-input');
    fireEvent.change(nameInput, { target: { value: 'New Sequence Name' } });

    expect(mockSetName).toHaveBeenCalledWith('New Sequence Name');
  });

  // ============================================
  // Test 10: Activate button shows correct state
  // ============================================
  it('shows Pause button when sequence is active', () => {
    mockedUseSequenceBuilder.mockReturnValue({
      ...defaultBuilderState,
      sequence: { ...mockSequence, status: 'active' },
      steps: mockSteps,
      name: 'Test Sequence',
    });

    renderBuilder('seq-1');

    expect(screen.getByTestId('activate-sequence-btn')).toHaveTextContent('Pause');
  });

  it('shows Activate button when sequence is draft', () => {
    mockedUseSequenceBuilder.mockReturnValue({
      ...defaultBuilderState,
      sequence: mockSequence,
      steps: mockSteps,
      name: 'Test Sequence',
      validation: { isValid: true, errors: [] },
    });

    renderBuilder('seq-1');

    expect(screen.getByTestId('activate-sequence-btn')).toHaveTextContent('Activate');
  });
});
