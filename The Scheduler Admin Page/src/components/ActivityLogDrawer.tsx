import { useState } from 'react';
import { ActivityLogPanel } from './ActivityLogPanel';

interface ActivityLogDrawerProps {
  userId: string;
  userName?: string;
  onClose: () => void;
}

/**
 * Activity Log Drawer Component
 *
 * Slide-out drawer showing activity for a specific user
 * - Displays user-specific activity logs
 * - Provides filtering and refresh capabilities
 * - HIPAA-compliant (no PHI in display)
 */
export function ActivityLogDrawer({ userId, userName, onClose }: ActivityLogDrawerProps) {
  const [isOpen, setIsOpen] = useState(true);

  const handleClose = () => {
    setIsOpen(false);
    setTimeout(onClose, 300); // Wait for animation to complete
  };

  return (
    <>
      {/* Backdrop */}
      <div
        style={{
          position: 'fixed',
          inset: 0,
          backgroundColor: 'rgba(0, 0, 0, 0.5)',
          zIndex: 999,
          opacity: isOpen ? 1 : 0,
          transition: 'opacity 0.3s ease-in-out',
        }}
        onClick={handleClose}
      />

      {/* Drawer */}
      <div
        style={{
          position: 'fixed',
          top: 0,
          right: 0,
          bottom: 0,
          width: '600px',
          maxWidth: '90vw',
          backgroundColor: 'var(--color-bg-panel)',
          boxShadow: 'var(--shadow-lg)',
          zIndex: 1000,
          transform: isOpen ? 'translateX(0)' : 'translateX(100%)',
          transition: 'transform 0.3s ease-in-out',
          display: 'flex',
          flexDirection: 'column',
          overflow: 'hidden',
        }}
      >
        {/* Header */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            padding: '16px 20px',
            borderBottom: '1px solid var(--color-border)',
            backgroundColor: 'var(--color-bg-secondary)',
          }}
        >
          <div>
            <h2 style={{ margin: 0, fontSize: '18px' }}>Activity Log</h2>
            {userName && <p className="muted" style={{ margin: '4px 0 0 0', fontSize: '14px' }}>{userName}</p>}
          </div>
          <button
            onClick={handleClose}
            style={{
              background: 'transparent',
              border: 'none',
              fontSize: '24px',
              cursor: 'pointer',
              padding: '4px 8px',
              color: 'var(--color-text-muted)',
            }}
            aria-label="Close"
          >
            ×
          </button>
        </div>

        {/* Content */}
        <div
          style={{
            flex: 1,
            overflowY: 'auto',
            padding: '20px',
          }}
        >
          <ActivityLogPanel
            userId={userId}
            limit={100}
            showFilters={true}
            title=""
          />
        </div>
      </div>
    </>
  );
}

/**
 * Alternative: Modal version of Activity Log
 * Can be used instead of drawer if preferred
 */
export function ActivityLogModal({ userId, userName, onClose }: ActivityLogDrawerProps) {
  const [isOpen, setIsOpen] = useState(true);

  const handleClose = () => {
    setIsOpen(false);
    setTimeout(onClose, 300);
  };

  return (
    <>
      {/* Backdrop */}
      <div
        style={{
          position: 'fixed',
          inset: 0,
          backgroundColor: 'rgba(0, 0, 0, 0.5)',
          zIndex: 999,
          opacity: isOpen ? 1 : 0,
          transition: 'opacity 0.3s ease-in-out',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
        onClick={handleClose}
      >
        {/* Modal */}
        <div
          style={{
            width: '90%',
            maxWidth: '800px',
            maxHeight: '90vh',
            backgroundColor: 'var(--color-bg-panel)',
            borderRadius: 'var(--radius-xl)',
            boxShadow: 'var(--shadow-lg)',
            transform: isOpen ? 'scale(1)' : 'scale(0.95)',
            transition: 'transform 0.3s ease-in-out',
            display: 'flex',
            flexDirection: 'column',
            overflow: 'hidden',
          }}
          onClick={(e) => e.stopPropagation()}
        >
          {/* Header */}
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              padding: '16px 20px',
              borderBottom: '1px solid var(--color-border)',
            }}
          >
            <div>
              <h2 style={{ margin: 0, fontSize: '18px' }}>Activity Log</h2>
              {userName && <p className="muted" style={{ margin: '4px 0 0 0', fontSize: '14px' }}>{userName}</p>}
            </div>
            <button
              onClick={handleClose}
              style={{
                background: 'transparent',
                border: 'none',
                fontSize: '24px',
                cursor: 'pointer',
                padding: '4px 8px',
                color: 'var(--color-text-muted)',
              }}
              aria-label="Close"
            >
              ×
            </button>
          </div>

          {/* Content */}
          <div
            style={{
              flex: 1,
              overflowY: 'auto',
              padding: '20px',
            }}
          >
            <ActivityLogPanel
              userId={userId}
              limit={100}
              showFilters={true}
              title=""
            />
          </div>
        </div>
      </div>
    </>
  );
}
