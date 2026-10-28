import { useState, useEffect, useCallback, type CSSProperties } from 'react';

import { isDemoMode } from '../config/demo';
import { useAuth } from '../context/AuthContext';
import { useDemoGuard } from '../hooks/useDemoGuard';
import { useBusinessContext } from '../hooks/useBusinessContext';
import { useStaffPermissions } from '../hooks/useStaffPermissions';
import { useWorkspaceInfo } from '../hooks/useWorkspaceInfo';
import { useOwnershipTransfer } from '../hooks/useOwnershipTransfer';
import { TransferOwnershipDialog } from '../components/TransferOwnershipDialog';
import { ActivityLogDrawer } from '../components/ActivityLogDrawer';
import { BulkInviteDialog } from '../components/BulkInviteDialog';
import { StaffDrawer } from '../components/StaffDrawer';
import { listStaff, saveStaff } from '../data/staff';
import { THEME, SPACING } from './dashboard/DashboardComponents';
import type { StaffMember } from '../types/models';

export function StaffPage() {
  const { state, refreshUser } = useAuth();
  const { businessId, userId, role } = useBusinessContext();
  const userEmail = state.status === 'signed_in' ? state.user.email : null;
  const { access, loading } = useStaffPermissions(businessId, userId, role, userEmail);
  const { workspace } = useWorkspaceInfo(businessId);
  const { executeTransfer } = useOwnershipTransfer();
  const { notifyBlocked, disabledMessage } = useDemoGuard();
  const canManageStaff = access.settings === 'manage' || access.settings === 'view';
  const checkingPermissions = loading && !canManageStaff;

  const [showTransferDialog, setShowTransferDialog] = useState(false);
  const [showBulkInvite, setShowBulkInvite] = useState(false);
  const [showStaffDrawer, setShowStaffDrawer] = useState(false);
  const [editingStaff, setEditingStaff] = useState<StaffMember | null>(null);
  
  const [staffList, setStaffList] = useState<StaffMember[]>([]);
  const [loadingStaff, setLoadingStaff] = useState(false);
  const [selectedUserForActivity, setSelectedUserForActivity] = useState<{
    id: string;
    name: string;
  } | null>(null);

  // Load staff list
  const loadStaff = useCallback(async () => {
    if (!businessId) return;
    setLoadingStaff(true);
    try {
      const staff = await listStaff(businessId, userId);
      setStaffList(staff);
    } catch (error) {
      console.error('Failed to load staff:', error);
    } finally {
      setLoadingStaff(false);
    }
  }, [businessId, userId]);

  useEffect(() => {
    void loadStaff();
  }, [loadStaff]);

  const handleInviteClick = () => {
    if (isDemoMode) {
      notifyBlocked({ action: 'invite staff' });
      return;
    }
    setEditingStaff(null);
    setShowStaffDrawer(true);
  };

  const handleEditClick = (staff: StaffMember) => {
    if (isDemoMode) {
      notifyBlocked({ action: `edit ${staff.displayName}` });
      return;
    }
    setEditingStaff(staff);
    setShowStaffDrawer(true);
  };

  const handleSaveStaff = async (data: Partial<StaffMember>) => {
    if (!businessId) return;

    try {
      await saveStaff(businessId, data, userId);
      await loadStaff();
    } catch (error) {
      // Log error without PHI - only metadata
      console.error('Failed to save staff member:', { businessId, hasData: !!data });
      throw error;
    }
  };

  const handleTransferOwnership = async (newOwnerId: string, password: string) => {
    if (!businessId || !userId) {
      throw new Error('Business context required');
    }

    const success = await executeTransfer({
      businessId,
      currentOwnerId: userId,
      newOwnerId,
      password,
    });

    if (success) {
      setShowTransferDialog(false);
      // Refresh user to pick up new role (admin)
      await refreshUser();
    }
  };

  // Get admin staff members for transfer dialog
  const adminStaff = staffList.filter((s) => s.role === 'admin');

  // Inline styles using design system
  const pageContainerStyle: CSSProperties = {
    background: `linear-gradient(180deg, ${THEME.colorBgGradientStart} 0%, ${THEME.colorBgGradientEnd} 100%)`,
    minHeight: '100vh',
    padding: SPACING.lg,
  };

  const headerStyle: CSSProperties = {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: SPACING.xl,
    gap: SPACING.lg,
  };

  const headerActionsStyle: CSSProperties = {
    display: 'flex',
    gap: SPACING.md,
  };

  const panelStyle: CSSProperties = {
    background: THEME.colorBgPanelGradient,
    borderRadius: THEME.radius,
    boxShadow: THEME.shadow,
    border: `1px solid ${THEME.colorBorder}`,
    marginBottom: SPACING.lg,
    transition: `all ${THEME.transitionBase} ease-out`,
  };

  const ownerPanelStyle: CSSProperties = {
    ...panelStyle,
    padding: SPACING.lg,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
  };

  const tablePanelStyle: CSSProperties = {
    ...panelStyle,
    overflow: 'hidden',
  };

  const tableHeaderStyle: CSSProperties = {
    display: 'grid',
    gridTemplateColumns: '1.5fr 1fr 1.5fr 1fr 1.5fr auto',
    gap: SPACING.md,
    padding: SPACING.lg,
    borderBottom: `1px solid ${THEME.colorBorder}`,
    fontSize: 11,
    fontWeight: 600,
    color: THEME.colorTextMuted,
    textTransform: 'uppercase',
    letterSpacing: '0.05em',
    background: THEME.colorBgPanel,
  };

  const tableRowStyle: CSSProperties = {
    display: 'grid',
    gridTemplateColumns: '1.5fr 1fr 1.5fr 1fr 1.5fr auto',
    gap: SPACING.md,
    padding: SPACING.lg,
    borderBottom: `1px solid ${THEME.colorBorder}`,
    alignItems: 'center',
    transition: `background-color ${THEME.transitionSpeed} ease-out`,
  };

  const emptyStateStyle: CSSProperties = {
    padding: SPACING.xl,
    textAlign: 'center',
    color: THEME.colorTextMuted,
  };

  const alertPanelStyle: CSSProperties = {
    ...panelStyle,
    padding: SPACING.lg,
    background: 'linear-gradient(135deg, #fef3c7 0%, #fde68a 100%)',
    borderColor: '#fbbf24',
  };

  if (!canManageStaff) {
    return (
      <section style={pageContainerStyle}>
        <header style={headerStyle}>
          <div>
            <p className="eyebrow" style={{ color: THEME.colorAccent }}>Team</p>
            <h1 style={{ fontSize: 26, fontWeight: 700, margin: `${SPACING.sm}px 0 0`, color: THEME.colorText }}>Staff Management</h1>
            <p className="muted" style={{ margin: `${SPACING.xs}px 0 0`, color: THEME.colorTextMuted }}>
              {checkingPermissions
                ? 'Checking your permissions...'
                : 'Your account does not have permission to manage staff. Ask an admin or owner to grant Settings access.'}
            </p>
          </div>
        </header>
        <div style={alertPanelStyle}>
          <p className="eyebrow" style={{ marginBottom: SPACING.xs }}>Access restricted</p>
          <p className="muted" style={{ margin: 0, color: '#78350f' }}>
            Staff management requires the Settings module. Navigation and actions are hidden until
            access is granted.
          </p>
        </div>
      </section>
    );
  }

  const buttonStyle: CSSProperties = {
    transition: `all ${THEME.transitionBase} ease-out`,
  };

  const actionButtonStyle: CSSProperties = {
    padding: '6px 12px',
    fontSize: '13px',
    borderRadius: 8,
    transition: `all ${THEME.transitionSpeed} ease-out`,
  };

  return (
    <section style={pageContainerStyle}>
      <header style={headerStyle}>
        <div>
          <p className="eyebrow" style={{ color: THEME.colorAccent, fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.1em', margin: 0 }}>Team</p>
          <h1 style={{ fontSize: 26, fontWeight: 700, margin: `${SPACING.sm}px 0 0`, color: THEME.colorText }}>Staff Management</h1>
          <p className="muted" style={{ margin: `${SPACING.xs}px 0 0`, color: THEME.colorTextMuted, fontSize: 14 }}>
            Invite staff, manage roles, and configure app access (CRM, Scheduler, Admin).
          </p>
        </div>
        <div style={headerActionsStyle}>
          <button
            className="button button--secondary"
            type="button"
            onClick={() => {
              if (isDemoMode) {
                notifyBlocked({ action: 'bulk invite staff' });
                return;
              }
              setShowBulkInvite(true);
            }}
            aria-label="Bulk invite staff from CSV file"
            style={buttonStyle}
            title={isDemoMode ? disabledMessage : undefined}
          >
            Bulk Invite (CSV)
          </button>
          <button
            className="button button--primary"
            type="button"
            onClick={handleInviteClick}
            aria-label="Invite new staff member"
            style={buttonStyle}
            title={isDemoMode ? disabledMessage : undefined}
          >
            + Invite Staff
          </button>
        </div>
      </header>

      {role === 'owner' && (
        <div style={ownerPanelStyle}>
          <div>
            <p className="eyebrow" style={{ marginBottom: SPACING.xs, fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase' }}>
              Owner Settings
            </p>
            <p className="muted" style={{ margin: 0, color: THEME.colorTextMuted, fontSize: 13 }}>
              Transfer business ownership to an existing admin user
            </p>
          </div>
          <button
            className="button button--danger"
            type="button"
            onClick={() => {
              if (isDemoMode) {
                notifyBlocked({ action: 'transfer ownership' });
                return;
              }
              setShowTransferDialog(true);
            }}
            disabled={loadingStaff}
            aria-label="Transfer business ownership to another admin"
            style={buttonStyle}
            title={isDemoMode ? disabledMessage : undefined}
          >
            Transfer Ownership
          </button>
        </div>
      )}

      <div style={tablePanelStyle} role="region" aria-label="Staff member list">
        <div style={tableHeaderStyle} role="row">
          <span role="columnheader">Name</span>
          <span role="columnheader">Role</span>
          <span role="columnheader">Email</span>
          <span role="columnheader">Apps</span>
          <span role="columnheader">Status</span>
          <span role="columnheader">Actions</span>
        </div>
        {staffList.map((row) => (
          <div
            key={row.id}
            style={tableRowStyle}
            role="row"
            aria-label={`Staff member: ${row.displayName}`}
            onMouseOver={(e) => (e.currentTarget.style.backgroundColor = THEME.colorBgGradientStart)}
            onMouseOut={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
          >
            <span style={{ fontWeight: 500, color: THEME.colorText }} role="cell">{row.displayName}</span>
            <span className={`badge badge--${row.role}`} role="cell">{row.role}</span>
            <span className="muted" style={{ color: THEME.colorTextMuted, fontSize: 14 }} role="cell">{row.email || 'No email'}</span>
            <span style={{ display: 'flex', gap: SPACING.xs }} role="cell" aria-label="App access">
              {row.appAccess?.scheduler && <span title="Scheduler App" aria-label="Has Scheduler App access">Scheduler</span>}
              {row.appAccess?.crm && <span title="CRM Suite" aria-label="Has CRM Suite access">CRM</span>}
              {row.appAccess?.admin && <span title="Admin Portal" aria-label="Has Admin Portal access">Admin</span>}
              {!row.appAccess && <span className="muted">-</span>}
            </span>
            <span role="cell" aria-label={`Status: ${row.status}`} style={{ fontSize: 14 }}>
              <span className={`status-dot status-dot--${row.status}`} aria-hidden="true" /> {row.status}
            </span>
            <span style={{ display: 'flex', gap: SPACING.sm }} role="cell">
              <button
                className="button button--ghost"
                style={actionButtonStyle}
                onClick={() => handleEditClick(row)}
                aria-label={`Edit ${row.displayName}`}
                type="button"
                title={isDemoMode ? disabledMessage : undefined}
              >
                Edit
              </button>
              <button
                className="button button--ghost"
                style={actionButtonStyle}
                onClick={(e) => {
                  e.stopPropagation();
                  setSelectedUserForActivity({ id: row.id, name: row.displayName });
                }}
                aria-label={`View activity log for ${row.displayName}`}
                type="button"
              >
                Log
              </button>
            </span>
          </div>
        ))}
        {staffList.length === 0 && !loadingStaff && (
          <div style={emptyStateStyle}>
            No staff members found. Invite your team to get started.
          </div>
        )}
      </div>

      {showTransferDialog && workspace && userId && (
        <TransferOwnershipDialog
          businessName={workspace.name}
          adminStaff={adminStaff}
          currentOwnerId={userId}
          onConfirm={handleTransferOwnership}
          onCancel={() => setShowTransferDialog(false)}
        />
      )}

      {selectedUserForActivity && (
        <ActivityLogDrawer
          userId={selectedUserForActivity.id}
          userName={selectedUserForActivity.name}
          onClose={() => setSelectedUserForActivity(null)}
        />
      )}

      {showBulkInvite && (
        <BulkInviteDialog onClose={() => setShowBulkInvite(false)} />
      )}

      <StaffDrawer 
        isOpen={showStaffDrawer}
        staff={editingStaff}
        onClose={() => setShowStaffDrawer(false)}
        onSave={handleSaveStaff}
      />
    </section>
  );
}
