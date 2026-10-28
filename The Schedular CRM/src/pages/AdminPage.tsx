/**
 * Admin Page
 *
 * Administration page for owner and admin roles.
 * Provides team management, user search, and org hierarchy view.
 *
 * Per AGENT_RULES:
 * - Pages must not exceed 600 lines
 * - All data access through repositories
 * - BusinessId scoping for multi-tenant isolation
 */

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Card, PageHeader, PageLayout } from '../components/ui';
import { useAuth } from '../context/AuthContext';
import {
  AdminTeamsPanel,
  AdminUsersPanel,
  AdminOrgTreePanel,
  UserDetailDrawer,
} from '../components/admin';
import { AuditLogViewer } from '../components/audit/AuditLogViewer';
import type { TeamMember } from '../hooks/useTeamMembers';
import '../components/admin/admin.css';

type AdminTab = 'teams' | 'users' | 'organization' | 'audit';

const TAB_CONFIG: Record<AdminTab, { label: string; description: string; icon: string }> = {
  teams: {
    label: 'Teams',
    description: 'Manage coverage, ownership, and active team structure.',
    icon: '👥',
  },
  users: {
    label: 'Users',
    description: 'Review roles, access, assignments, and status across staff.',
    icon: '🧑‍💼',
  },
  organization: {
    label: 'Organization',
    description: 'Inspect reporting lines, managers, and hierarchy gaps.',
    icon: '🧭',
  },
  audit: {
    label: 'Audit Log',
    description: 'Track workspace activity, changes, and compliance history.',
    icon: '🧾',
  },
};

const ADMIN_TAB_ALIASES: Record<string, AdminTab> = {
  teams: 'teams',
  users: 'users',
  organization: 'organization',
  org: 'organization',
  audit: 'audit',
  audits: 'audit',
  'audit-log': 'audit',
};

export function AdminPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const { crmUser } = useAuth();
  const role = crmUser?.role || 'staff';
  const canAccessAdmin = role === 'admin' || role === 'owner';

  const [selectedUser, setSelectedUser] = useState<TeamMember | null>(null);
  const availableTabs = useMemo(() => Object.keys(TAB_CONFIG) as AdminTab[], []);
  const rawTab = searchParams.get('tab');
  const activeTab = useMemo<AdminTab>(() => {
    if (!rawTab) return 'teams';
    const normalized = ADMIN_TAB_ALIASES[rawTab.toLowerCase()];
    return normalized && availableTabs.includes(normalized) ? normalized : 'teams';
  }, [availableTabs, rawTab]);

  useEffect(() => {
    if (!rawTab) return;
    if (rawTab !== activeTab) {
      const nextParams = new URLSearchParams(searchParams);
      nextParams.set('tab', activeTab);
      setSearchParams(nextParams, { replace: true });
    }
  }, [activeTab, rawTab, searchParams, setSearchParams]);

  const handleTabChange = useCallback(
    (tab: AdminTab) => {
      const nextParams = new URLSearchParams(searchParams);
      nextParams.set('tab', tab);
      setSearchParams(nextParams, { replace: true });
    },
    [searchParams, setSearchParams]
  );

  // RBAC: Only owner/admin can access this page
  if (!canAccessAdmin) {
    return (
      <PageLayout width="wide" className="admin-page">
        <Card padding="lg" className="admin-access-card">
          <div className="admin-empty-state">
            <div className="admin-empty-state-icon">🔒</div>
            <div className="admin-empty-state-title">Access Denied</div>
            <p>You do not have permission to access the Admin page.</p>
          </div>
        </Card>
      </PageLayout>
    );
  }

  const handleUserSelect = (user: TeamMember) => {
    setSelectedUser(user);
  };

  const handleCloseDrawer = () => {
    setSelectedUser(null);
  };

  return (
    <PageLayout width="wide" className="admin-page">
      <PageHeader
        eyebrow="Workspace"
        title="Admin"
        subtitle="Manage team structure, user access, reporting lines, and audit visibility from one surface."
      />

      <section className="admin-page__tabs" aria-label="Admin navigation">
        <div className="admin-page__tab-grid">
          {(Object.keys(TAB_CONFIG) as AdminTab[]).map((tab) => (
            <button
              key={tab}
              type="button"
              className={`admin-tab-card ${activeTab === tab ? 'active' : ''}`}
              onClick={() => handleTabChange(tab)}
              aria-pressed={activeTab === tab}
              aria-label={TAB_CONFIG[tab].label}
            >
              <span className="admin-tab-card__icon" aria-hidden="true">
                {TAB_CONFIG[tab].icon}
              </span>
              <span className="admin-tab-card__copy">
                <span className="admin-tab-card__label">{TAB_CONFIG[tab].label}</span>
                <span className="admin-tab-card__meta">{TAB_CONFIG[tab].description}</span>
              </span>
            </button>
          ))}
        </div>
      </section>

      <section className="admin-page__content">
        {activeTab === 'teams' && <AdminTeamsPanel />}

        {activeTab === 'users' && (
          <AdminUsersPanel onUserSelect={handleUserSelect} />
        )}

        {activeTab === 'organization' && (
          <AdminOrgTreePanel onUserSelect={handleUserSelect} />
        )}

        {activeTab === 'audit' && (
          <div className="admin-audit-panel">
            <AuditLogViewer maxHeight="720px" />
          </div>
        )}
      </section>

      <UserDetailDrawer user={selectedUser} onClose={handleCloseDrawer} />
    </PageLayout>
  );
}

export default AdminPage;
