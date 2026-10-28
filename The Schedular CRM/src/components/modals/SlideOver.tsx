/**
 * SlideOver Component
 * Slide-over panel for quick actions and detail views
 *
 * Agent CRM-15 Implementation
 */

import React, { useEffect, useCallback, useRef } from 'react';
import { createPortal } from 'react-dom';
import './modals.css';

// ============================================
// Types
// ============================================

export interface SlideOverProps {
  /** Whether the slide-over is open */
  isOpen: boolean;
  /** Called when the slide-over should close */
  onClose: () => void;
  /** Panel title */
  title: string;
  /** Slide direction */
  position?: 'right' | 'left';
  /** Panel width */
  width?: 'sm' | 'md' | 'lg';
  /** Panel content */
  children: React.ReactNode;
  /** Additional CSS class */
  className?: string;
}

// ============================================
// Component
// ============================================

/**
 * SlideOver - Slide-over panel component
 *
 * @example
 * ```tsx
 * <SlideOver
 *   isOpen={isOpen}
 *   onClose={handleClose}
 *   title="Quick Edit"
 *   position="right"
 *   width="md"
 * >
 *   <LeadForm onSubmit={handleSubmit} onCancel={handleClose} />
 * </SlideOver>
 * ```
 */
export function SlideOver({
  isOpen,
  onClose,
  title,
  position = 'right',
  width = 'md',
  children,
  className = '',
}: SlideOverProps) {
  const panelRef = useRef<HTMLDivElement>(null);

  // Handle escape key
  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    },
    [onClose]
  );

  // Handle overlay click
  const handleOverlayClick = useCallback(
    (e: React.MouseEvent) => {
      if (e.target === e.currentTarget) {
        onClose();
      }
    },
    [onClose]
  );

  // Add/remove event listeners and body scroll lock
  useEffect(() => {
    if (isOpen) {
      document.addEventListener('keydown', handleKeyDown);
      document.body.style.overflow = 'hidden';

      // Focus the panel for accessibility
      panelRef.current?.focus();
    }

    return () => {
      document.removeEventListener('keydown', handleKeyDown);
      document.body.style.overflow = '';
    };
  }, [isOpen, handleKeyDown]);

  // Don't render if not open
  if (!isOpen) {
    return null;
  }

  const slideOverContent = (
    <>
      {/* Overlay */}
      <div
        className="slide-over-overlay"
        onClick={handleOverlayClick}
        role="presentation"
      />

      {/* Panel */}
      <div
        ref={panelRef}
        className={`slide-over slide-over--${position} slide-over--${width} ${className}`}
        role="dialog"
        aria-modal="true"
        aria-labelledby="slide-over-title"
        tabIndex={-1}
      >
        {/* Header */}
        <div className="slide-over__header">
          <h2 id="slide-over-title" className="slide-over__title">
            {title}
          </h2>
          <button
            type="button"
            className="slide-over__close"
            onClick={onClose}
            aria-label="Close panel"
          >
            <svg
              width="20"
              height="20"
              viewBox="0 0 20 20"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M15 5L5 15M5 5L15 15"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </button>
        </div>

        {/* Content */}
        <div className="slide-over__content">{children}</div>
      </div>
    </>
  );

  // Render to portal
  return createPortal(slideOverContent, document.body);
}

export default SlideOver;
