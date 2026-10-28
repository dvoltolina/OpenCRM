import { useState, useEffect } from 'react';
import { type StaffMember, type AppAccess, type ModuleAccess, type UserRole } from '../types/models';
import { SPACING, THEME } from '../pages/dashboard/DashboardComponents';
import { isStaffWriteBackendGapError } from '../data/staff';

type StaffDrawerProps = {
  staff?: StaffMember | null; // If null, creating new
  isOpen: boolean;
  onClose: () => void;
  onSave: (staff: Partial<StaffMember>) => Promise<void>;
};

const DEFAULT_APP_ACCESS: AppAccess = {
  scheduler: true,
  crm: false,
  admin: false,
};

const DEFAULT_MODULE_ACCESS: ModuleAccess = {
  calendar: 'view_own',
  clients: 'view_own',
  leads: 'none',
  deals: 'none',
  marketing: 'none',
  billing: 'none',
  settings: 'none',
  staff: 'none',
};

export function StaffDrawer({ staff, isOpen, onClose, onSave }: StaffDrawerProps) {
  const [formData, setFormData] = useState<Partial<StaffMember>>({
    role: 'staff',
    appAccess: DEFAULT_APP_ACCESS,
    moduleAccess: DEFAULT_MODULE_ACCESS,
  });
  const [saving, setLoading] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'profile' | 'access'>('profile');

  useEffect(() => {
    setSaveError(null);
    if (staff) {
      setFormData({
        ...staff,
        appAccess: staff.appAccess || DEFAULT_APP_ACCESS,
        moduleAccess: staff.moduleAccess || DEFAULT_MODULE_ACCESS,
      });
    } else {
      setFormData({
        role: 'staff',
        status: 'active',
        appAccess: DEFAULT_APP_ACCESS,
        moduleAccess: DEFAULT_MODULE_ACCESS,
      });
    }
  }, [staff, isOpen]);

  // Add keyboard navigation (Escape key to close)
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && !saving) {
        onClose();
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, saving, onClose]);

  if (!isOpen) return null;

  const handleSave = async () => {
    setLoading(true);
    setSaveError(null);
    try {
      await onSave(formData);
      onClose();
    } catch (error) {
      if (isStaffWriteBackendGapError(error)) {
        setSaveError(error.message);
      } else {
        setSaveError(error instanceof Error ? error.message : 'Failed to save staff member.');
      }
    } finally {
      setLoading(false);
    }
  };

  const updateAppAccess = (app: keyof AppAccess, value: boolean) => {
    setFormData(prev => ({
      ...prev,
      appAccess: { ...prev.appAccess!, [app]: value }
    }));
  };

  const updateModuleAccess = (module: keyof ModuleAccess, value: string) => {
    setFormData(prev => ({
      ...prev,
      moduleAccess: { ...prev.moduleAccess!, [module]: value }
    }));
  };

  return (
    <>
      <div
        className="drawer-overlay"
        onClick={onClose}
        role="presentation"
        aria-hidden="true"
      />
      <div className="drawer" role="dialog" aria-modal="true" aria-labelledby="drawer-title">
        <header className="drawer__header">
          <h2 id="drawer-title">{staff ? 'Edit Team Member' : 'Invite Team Member'}</h2>
          <button
            className="drawer__close"
            onClick={onClose}
            aria-label="Close drawer"
            type="button"
          >
            x
          </button>
        </header>

        <div className="drawer__tabs" role="tablist" aria-label="Staff member settings tabs">
          <button
            className={`tab ${activeTab === 'profile' ? 'active' : ''}`}
            onClick={() => setActiveTab('profile')}
            role="tab"
            aria-selected={activeTab === 'profile'}
            aria-controls="profile-panel"
            id="profile-tab"
            type="button"
          >
            Profile & Role
          </button>
          <button
            className={`tab ${activeTab === 'access' ? 'active' : ''}`}
            onClick={() => setActiveTab('access')}
            role="tab"
            aria-selected={activeTab === 'access'}
            aria-controls="access-panel"
            id="access-tab"
            type="button"
          >
            App Access & Permissions
          </button>
        </div>

        <div className="drawer__content">
          {activeTab === 'profile' ? (
            <div
              className="form-stack"
              role="tabpanel"
              id="profile-panel"
              aria-labelledby="profile-tab"
            >
              <div className="form-row">
                <div className="form-group">
                  <label htmlFor="firstName">First Name</label>
                  <input
                    id="firstName"
                    type="text"
                    value={formData.firstName || ''}
                    onChange={e => setFormData({ ...formData, firstName: e.target.value })}
                    placeholder="Jane"
                    aria-required="false"
                  />
                </div>
                <div className="form-group">
                  <label htmlFor="lastName">Last Name</label>
                  <input
                    id="lastName"
                    type="text"
                    value={formData.lastName || ''}
                    onChange={e => setFormData({ ...formData, lastName: e.target.value })}
                    placeholder="Doe"
                    aria-required="false"
                  />
                </div>
              </div>

              <div className="form-group">
                <label htmlFor="email">Email Address</label>
                <input
                  id="email"
                  type="email"
                  value={formData.email || ''}
                  onChange={e => setFormData({ ...formData, email: e.target.value })}
                  placeholder="jane@example.com"
                  disabled={!!staff}
                  aria-required="true"
                  aria-describedby={staff ? "email-help" : undefined}
                />
                {staff && (
                  <p className="helper-text" id="email-help">
                    Email cannot be changed for existing users
                  </p>
                )}
              </div>

              <div className="form-group">
                <label htmlFor="role">Primary Role</label>
                <select
                  id="role"
                  value={formData.role}
                  onChange={e => setFormData({ ...formData, role: e.target.value as UserRole })}
                  aria-describedby="role-help"
                >
                  <option value="staff">Staff (Standard)</option>
                  <option value="provider">Provider</option>
                  <option value="frontDesk">Front Desk</option>
                  <option value="sales">Sales</option>
                  <option value="manager">Manager</option>
                  <option value="admin">Administrator</option>
                </select>
                <p className="helper-text" id="role-help">
                  Defines hierarchy and fallback permissions. Use "App Access" tab for granular control.
                </p>
              </div>
            </div>
          ) : (
            <div
              className="permissions-stack"
              role="tabpanel"
              id="access-panel"
              aria-labelledby="access-tab"
            >
              <div className="app-toggles">
                <h3>App Access</h3>
                <p className="section-desc">Which apps can this user log into?</p>

                <label className="toggle-row" htmlFor="app-scheduler">
                  <div>
                    <span className="app-name">Scheduler App</span>
                    <span className="app-desc">Provider tools, calendar, time clock.</span>
                  </div>
                  <input
                    id="app-scheduler"
                    type="checkbox"
                    checked={formData.appAccess?.scheduler}
                    onChange={e => updateAppAccess('scheduler', e.target.checked)}
                    aria-label="Grant Scheduler App access"
                  />
                </label>

                <label className="toggle-row" htmlFor="app-crm">
                  <div>
                    <span className="app-name">CRM Suite</span>
                    <span className="app-desc">Sales pipelines, marketing, leads.</span>
                  </div>
                  <input
                    id="app-crm"
                    type="checkbox"
                    checked={formData.appAccess?.crm}
                    onChange={e => updateAppAccess('crm', e.target.checked)}
                    aria-label="Grant CRM Suite access"
                  />
                </label>

                <label className="toggle-row" htmlFor="app-admin">
                  <div>
                    <span className="app-name">Admin Portal</span>
                    <span className="app-desc">Billing, settings, staff management.</span>
                  </div>
                  <input
                    id="app-admin"
                    type="checkbox"
                    checked={formData.appAccess?.admin}
                    onChange={e => updateAppAccess('admin', e.target.checked)}
                    aria-label="Grant Admin Portal access"
                  />
                </label>
              </div>

              {formData.appAccess?.scheduler && (
                <div className="module-section" role="group" aria-labelledby="scheduler-perms-title">
                  <h4 id="scheduler-perms-title">Scheduler Permissions</h4>
                  <div className="permission-grid">
                    <label htmlFor="perm-calendar">
                      <span>Calendar</span>
                      <select
                        id="perm-calendar"
                        value={formData.moduleAccess?.calendar}
                        onChange={e => updateModuleAccess('calendar', e.target.value)}
                        aria-label="Calendar access level"
                      >
                        <option value="none">No Access</option>
                        <option value="view_own">View Own</option>
                        <option value="view_all">View All</option>
                        <option value="manage_all">Manage All</option>
                      </select>
                    </label>
                    <label htmlFor="perm-clients">
                      <span>Clients (PHI)</span>
                      <select
                        id="perm-clients"
                        value={formData.moduleAccess?.clients}
                        onChange={e => updateModuleAccess('clients', e.target.value)}
                        aria-label="Client data access level"
                      >
                        <option value="none">No Access</option>
                        <option value="view_own">Assigned Only</option>
                        <option value="view_all">View All</option>
                        <option value="manage_all">Manage All</option>
                      </select>
                    </label>
                  </div>
                </div>
              )}

              {formData.appAccess?.crm && (
                <div className="module-section" role="group" aria-labelledby="crm-perms-title">
                  <h4 id="crm-perms-title">CRM Permissions</h4>
                  <div className="permission-grid">
                    <label htmlFor="perm-leads">
                      <span>Leads & Pipelines</span>
                      <select
                        id="perm-leads"
                        value={formData.moduleAccess?.leads}
                        onChange={e => updateModuleAccess('leads', e.target.value)}
                        aria-label="Leads and pipelines access level"
                      >
                        <option value="none">No Access</option>
                        <option value="view_own">Own Leads</option>
                        <option value="view_all">View Team</option>
                        <option value="manage_all">Manage All</option>
                      </select>
                    </label>
                    <label htmlFor="perm-marketing">
                      <span>Marketing</span>
                      <select
                        id="perm-marketing"
                        value={formData.moduleAccess?.marketing}
                        onChange={e => updateModuleAccess('marketing', e.target.value)}
                        aria-label="Marketing access level"
                      >
                        <option value="none">No Access</option>
                        <option value="view">View Campaigns</option>
                        <option value="manage">Create/Send</option>
                      </select>
                    </label>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {saveError && (
          <div
            role="alert"
            style={{
              margin: `0 ${SPACING.lg}px`,
              padding: `${SPACING.sm}px ${SPACING.md}px`,
              borderRadius: 8,
              border: `1px solid #f59e0b`,
              background: '#fffbeb',
              color: '#92400e',
              fontSize: 13,
            }}
          >
            {saveError}
          </div>
        )}

        <footer className="drawer__footer">
          <button
            className="button button--secondary"
            onClick={onClose}
            disabled={saving}
            type="button"
            aria-label="Cancel and close drawer"
          >
            Cancel
          </button>
          <button
            className="button button--primary"
            onClick={handleSave}
            disabled={saving}
            type="button"
            aria-label={saving ? 'Saving staff member' : (staff ? 'Update team member' : 'Send staff invite')}
          >
            {saving ? 'Saving...' : (staff ? 'Update Member' : 'Send Invite')}
          </button>
        </footer>
      </div>

      <style>{`
        .drawer-overlay {
          position: fixed;
          top: 0; left: 0; right: 0; bottom: 0;
          background: rgba(0,0,0,0.4);
          z-index: 99;
        }
        .drawer {
          position: fixed;
          top: 0; right: 0; bottom: 0;
          width: 500px;
          background: white;
          z-index: 100;
          box-shadow: -4px 0 12px rgba(0,0,0,0.1);
          display: flex;
          flex-direction: column;
        }
        .drawer__header {
          padding: ${SPACING.lg}px;
          border-bottom: 1px solid ${THEME.colorBorder};
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        .drawer__close {
          background: none; border: none; font-size: 20px; cursor: pointer;
          padding: 4px 8px; border-radius: 4px; transition: background 0.15s;
        }
        .drawer__close:hover {
          background: ${THEME.colorBg};
        }
        .drawer__close:focus {
          outline: 2px solid ${THEME.colorAccent};
          outline-offset: 2px;
        }
        .drawer__tabs {
          display: flex;
          border-bottom: 1px solid ${THEME.colorBorder};
        }
        .tab {
          flex: 1;
          padding: 12px;
          background: none;
          border: none;
          border-bottom: 2px solid transparent;
          cursor: pointer;
          font-weight: 500;
          color: ${THEME.colorTextMuted};
          transition: color 0.15s, border-color 0.15s;
        }
        .tab:hover {
          color: ${THEME.colorAccent};
        }
        .tab:focus {
          outline: 2px solid ${THEME.colorAccent};
          outline-offset: -2px;
        }
        .tab.active {
          color: ${THEME.colorAccent};
          border-bottom-color: ${THEME.colorAccent};
        }
        .drawer__content {
          flex: 1;
          overflow-y: auto;
          padding: ${SPACING.lg}px;
        }
        .form-stack { display: flex; flex-direction: column; gap: 16px; }
        .form-row { display: flex; gap: 16px; }
        .form-group { flex: 1; display: flex; flex-direction: column; gap: 6px; }
        .form-group label { font-weight: 500; font-size: 14px; }
        .form-group input, .form-group select {
          padding: 8px 12px;
          border: 1px solid ${THEME.colorBorder};
          border-radius: 4px;
          font-size: 14px;
          transition: border-color 0.15s;
        }
        .form-group input:focus, .form-group select:focus {
          outline: none;
          border-color: ${THEME.colorAccent};
          box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
        }
        .form-group input:disabled {
          background: ${THEME.colorBg};
          cursor: not-allowed;
          opacity: 0.6;
        }
        .helper-text { font-size: 12px; color: ${THEME.colorTextMuted}; margin: 0; }
        
        .app-toggles { display: flex; flex-direction: column; gap: 12px; margin-bottom: 24px; }
        .toggle-row {
          display: flex; justify-content: space-between; align-items: center;
          padding: 12px;
          background: ${THEME.colorBg};
          border-radius: 6px;
          border: 1px solid ${THEME.colorBorder};
          cursor: pointer;
          transition: border-color 0.15s, background 0.15s;
        }
        .toggle-row:hover {
          background: ${THEME.colorBg};
          border-color: ${THEME.colorAccent};
        }
        .toggle-row:focus-within {
          border-color: ${THEME.colorAccent};
          box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
        }
        .app-name { display: block; font-weight: 600; font-size: 15px; }
        .app-desc { display: block; font-size: 12px; color: ${THEME.colorTextMuted}; }
        
        .module-section { margin-top: 24px; border-top: 1px solid ${THEME.colorBorder}; paddingTop: 16px; }
        .module-section h4 { margin: 0 0 12px; font-size: 14px; color: ${THEME.colorTextMuted}; text-transform: uppercase; letter-spacing: 0.5px; }
        .permission-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .permission-grid label { display: flex; flex-direction: column; gap: 4px; font-size: 13px; font-weight: 500; }
        .permission-grid select {
          padding: 6px;
          border: 1px solid ${THEME.colorBorder};
          border-radius: 4px;
          transition: border-color 0.15s;
        }
        .permission-grid select:focus {
          outline: none;
          border-color: ${THEME.colorAccent};
          box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
        }

        .drawer__footer {
          padding: ${SPACING.lg}px;
          border-top: 1px solid ${THEME.colorBorder};
          display: flex;
          justify-content: flex-end;
          gap: 12px;
        }
      `}</style>
    </>
  );
}
