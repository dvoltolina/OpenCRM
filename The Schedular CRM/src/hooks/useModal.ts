/**
 * useModal Hook
 * State management hook for modal dialogs
 *
 * Agent CRM-15 Implementation
 */

import { useState, useCallback } from 'react';

// ============================================
// Types
// ============================================

export interface UseModalResult<T = undefined> {
  /** Whether the modal is open */
  isOpen: boolean;
  /** Data passed to the modal */
  data: T | null;
  /** Open the modal with optional data */
  open: (data?: T) => void;
  /** Close the modal */
  close: () => void;
  /** Toggle the modal state */
  toggle: () => void;
}

// ============================================
// Hook Implementation
// ============================================

/**
 * Hook for managing modal state
 *
 * @returns Modal state and control functions
 *
 * @example
 * ```tsx
 * // Simple modal without data
 * const createModal = useModal();
 *
 * // Modal with data (e.g., for edit mode)
 * const editModal = useModal<Lead>();
 *
 * // Usage
 * <button onClick={() => createModal.open()}>Create</button>
 * <button onClick={() => editModal.open(lead)}>Edit</button>
 *
 * <CreateLeadModal
 *   isOpen={createModal.isOpen}
 *   onClose={createModal.close}
 * />
 *
 * <CreateLeadModal
 *   isOpen={editModal.isOpen}
 *   onClose={editModal.close}
 *   initialData={editModal.data}
 * />
 * ```
 */
export function useModal<T = undefined>(): UseModalResult<T> {
  const [isOpen, setIsOpen] = useState(false);
  const [data, setData] = useState<T | null>(null);

  const open = useCallback((newData?: T) => {
    setData(newData ?? null);
    setIsOpen(true);
  }, []);

  const close = useCallback(() => {
    setIsOpen(false);
    // Delay clearing data to allow for exit animations
    setTimeout(() => setData(null), 200);
  }, []);

  const toggle = useCallback(() => {
    setIsOpen((prev) => !prev);
  }, []);

  return {
    isOpen,
    data,
    open,
    close,
    toggle,
  };
}

export default useModal;
