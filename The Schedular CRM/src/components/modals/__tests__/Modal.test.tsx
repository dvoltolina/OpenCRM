/**
 * Modal Component Tests
 *
 * Agent CRM-15 Implementation
 *
 * Test Scenarios:
 * 1. Renders when isOpen true
 * 2. Hidden when isOpen false
 * 3. Closes on overlay click (when enabled)
 * 4. Closes on Escape key (when enabled)
 * 5. Renders custom footer
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Modal } from '../Modal';

// ============================================
// Setup
// ============================================

// Mock createPortal to render in the same container
vi.mock('react-dom', async () => {
  const actual = await vi.importActual('react-dom');
  return {
    ...actual,
    createPortal: (node: React.ReactNode) => node,
  };
});

describe('Modal', () => {
  const mockOnClose = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    // Clean up body styles
    document.body.style.overflow = '';
  });

  // ============================================
  // Test 1: Renders when isOpen true
  // ============================================
  it('renders when isOpen true', () => {
    render(
      <Modal isOpen={true} onClose={mockOnClose} title="Test Modal">
        <p>Modal content</p>
      </Modal>
    );

    expect(screen.getByRole('dialog')).toBeInTheDocument();
    expect(screen.getByText('Test Modal')).toBeInTheDocument();
    expect(screen.getByText('Modal content')).toBeInTheDocument();
  });

  // ============================================
  // Test 2: Hidden when isOpen false
  // ============================================
  it('is hidden when isOpen false', () => {
    render(
      <Modal isOpen={false} onClose={mockOnClose} title="Test Modal">
        <p>Modal content</p>
      </Modal>
    );

    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    expect(screen.queryByText('Modal content')).not.toBeInTheDocument();
  });

  // ============================================
  // Test 3: Closes on overlay click (when enabled)
  // ============================================
  it('closes on overlay click when closeOnOverlayClick is true', () => {
    render(
      <Modal
        isOpen={true}
        onClose={mockOnClose}
        title="Test Modal"
        closeOnOverlayClick={true}
      >
        <p>Modal content</p>
      </Modal>
    );

    // Click on overlay (the presentation element)
    const overlay = screen.getByRole('presentation');
    fireEvent.click(overlay);

    expect(mockOnClose).toHaveBeenCalledTimes(1);
  });

  it('does not close on overlay click when closeOnOverlayClick is false', () => {
    render(
      <Modal
        isOpen={true}
        onClose={mockOnClose}
        title="Test Modal"
        closeOnOverlayClick={false}
      >
        <p>Modal content</p>
      </Modal>
    );

    // Click on overlay
    const overlay = screen.getByRole('presentation');
    fireEvent.click(overlay);

    expect(mockOnClose).not.toHaveBeenCalled();
  });

  // ============================================
  // Test 4: Closes on Escape key (when enabled)
  // ============================================
  it('closes on Escape key when closeOnEscape is true', () => {
    render(
      <Modal
        isOpen={true}
        onClose={mockOnClose}
        title="Test Modal"
        closeOnEscape={true}
      >
        <p>Modal content</p>
      </Modal>
    );

    // Press Escape key
    fireEvent.keyDown(document, { key: 'Escape' });

    expect(mockOnClose).toHaveBeenCalledTimes(1);
  });

  it('does not close on Escape key when closeOnEscape is false', () => {
    render(
      <Modal
        isOpen={true}
        onClose={mockOnClose}
        title="Test Modal"
        closeOnEscape={false}
      >
        <p>Modal content</p>
      </Modal>
    );

    // Press Escape key
    fireEvent.keyDown(document, { key: 'Escape' });

    expect(mockOnClose).not.toHaveBeenCalled();
  });

  // ============================================
  // Test 5: Renders custom footer
  // ============================================
  it('renders custom footer', () => {
    render(
      <Modal
        isOpen={true}
        onClose={mockOnClose}
        title="Test Modal"
        footer={<button>Custom Footer Button</button>}
      >
        <p>Modal content</p>
      </Modal>
    );

    expect(screen.getByText('Custom Footer Button')).toBeInTheDocument();
  });

  // ============================================
  // Additional Tests
  // ============================================
  it('calls onClose when close button is clicked', () => {
    render(
      <Modal isOpen={true} onClose={mockOnClose} title="Test Modal">
        <p>Modal content</p>
      </Modal>
    );

    const closeButton = screen.getByLabelText('Close modal');
    fireEvent.click(closeButton);

    expect(mockOnClose).toHaveBeenCalledTimes(1);
  });

  it('applies size class correctly', () => {
    render(
      <Modal isOpen={true} onClose={mockOnClose} title="Test Modal" size="lg">
        <p>Modal content</p>
      </Modal>
    );

    const modal = screen.getByRole('dialog');
    expect(modal).toHaveClass('modal--lg');
  });

  it('locks body scroll when open', () => {
    render(
      <Modal isOpen={true} onClose={mockOnClose} title="Test Modal">
        <p>Modal content</p>
      </Modal>
    );

    expect(document.body.style.overflow).toBe('hidden');
  });
});
