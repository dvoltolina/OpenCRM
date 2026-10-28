/**
 * QuickActions Component
 * Quick action buttons for common tasks
 *
 * Agent CRM-18 Implementation
 */

import { useModal } from '../../hooks';
import {
  CreateLeadModal,
  CreateDealModal,
  LogActivityModal,
} from '../modals';
import './dashboard.css';

// ============================================
// Types
// ============================================

export interface QuickActionsProps {
  /** Additional CSS class */
  className?: string;
}

// ============================================
// Component
// ============================================

/**
 * QuickActions - Quick action buttons for dashboard
 *
 * @example
 * ```tsx
 * function Dashboard() {
 *   return (
 *     <div>
 *       <QuickActions />
 *       <KPIGrid kpis={kpis} />
 *     </div>
 *   );
 * }
 * ```
 */
export function QuickActions({ className = '' }: QuickActionsProps) {
  const {
    isOpen: isLeadModalOpen,
    open: openLeadModal,
    close: closeLeadModal,
  } = useModal();

  const {
    isOpen: isDealModalOpen,
    open: openDealModal,
    close: closeDealModal,
  } = useModal();

  const {
    isOpen: isActivityModalOpen,
    open: openActivityModal,
    close: closeActivityModal,
  } = useModal();

  return (
    <>
      <div className={`quick-actions ${className}`}>
        <button
          className="quick-action-btn quick-action-btn--lead"
          onClick={() => openLeadModal()}
        >
          <span className="quick-action-btn__icon">👤</span>
          <span className="quick-action-btn__label">Add Lead</span>
        </button>

        <button
          className="quick-action-btn quick-action-btn--deal"
          onClick={() => openDealModal()}
        >
          <span className="quick-action-btn__icon">💼</span>
          <span className="quick-action-btn__label">Add Opportunity</span>
        </button>

        <button
          className="quick-action-btn quick-action-btn--activity"
          onClick={() => openActivityModal()}
        >
          <span className="quick-action-btn__icon">📝</span>
          <span className="quick-action-btn__label">Log Activity</span>
        </button>
      </div>

      {/* Modals */}
      {isLeadModalOpen && (
        <CreateLeadModal isOpen={isLeadModalOpen} onClose={closeLeadModal} />
      )}

      {isDealModalOpen && (
        <CreateDealModal isOpen={isDealModalOpen} onClose={closeDealModal} />
      )}

      {isActivityModalOpen && (
        <LogActivityModal
          isOpen={isActivityModalOpen}
          onClose={closeActivityModal}
          entityType="deal"
          entityId=""
        />
      )}
    </>
  );
}

export default QuickActions;
