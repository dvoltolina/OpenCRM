/**
 * TenantsPage
 * Lists all tenants for ops management (super-admin only).
 */

import { useState, useMemo } from 'react';
import { useTenantList } from '../../hooks/useTenantList';
import { TenantDetailDrawer } from './TenantDetailDrawer';
import type { TenantSummary } from '../../types/ops';

function getStatusVariant(status: string): string {
  switch (status) {
    case 'active':
      return 'success';
    case 'trialing':
      return 'info';
    case 'past_due':
      return 'warn';
    case 'canceled':
      return 'danger';
    default:
      return 'neutral';
  }
}

export function TenantsPage() {
  const { tenants, loading, error, refresh } = useTenantList();
  const [selectedTenant, setSelectedTenant] = useState<TenantSummary | null>(null);
  const [searchQuery, setSearchQuery] = useState('');

  const filteredTenants = useMemo(() => {
    if (!searchQuery.trim()) return tenants;
    const q = searchQuery.toLowerCase();
    return tenants.filter(
      (t) =>
        t.name.toLowerCase().includes(q) ||
        t.email?.toLowerCase().includes(q) ||
        t.id.toLowerCase().includes(q),
    );
  }, [tenants, searchQuery]);

  return (
    <section>
      <header className="page-header">
        <div>
          <p className="eyebrow">Ops Portal</p>
          <h1>All Tenants</h1>
          <p className="muted">
            View and manage all business tenants across the platform.
          </p>
        </div>
        <div className="header-actions">
          <button
            className="button button--ghost"
            onClick={() => void refresh()}
            disabled={loading}
          >
            {loading ? 'Refreshing...' : 'Refresh'}
          </button>
        </div>
      </header>

      {error && (
        <div className="panel panel--alert" role="alert" style={{ marginBottom: 16 }}>
          <strong>Error:</strong> {error}
        </div>
      )}

      <div className="panel">
        <div style={{ marginBottom: 16 }}>
          <input
            type="search"
            className="topbar__search"
            placeholder="Search by name, email, or ID..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            style={{ width: '100%', maxWidth: 400 }}
          />
        </div>

        {loading && !tenants.length ? (
          <p className="muted">Loading tenants...</p>
        ) : filteredTenants.length === 0 ? (
          <p className="muted">No tenants found.</p>
        ) : (
          <>
            <div
              className="table__head"
              style={{
                display: 'grid',
                gridTemplateColumns: '2fr 1fr 100px 80px 100px 80px 80px',
                gap: 12,
              }}
            >
              <span>Business</span>
              <span>Plan</span>
              <span>Status</span>
              <span>Seats</span>
              <span>Add-ons</span>
              <span>Flags</span>
              <span></span>
            </div>
            {filteredTenants.map((tenant) => (
              <div
                key={tenant.id}
                className="table__row"
                style={{
                  display: 'grid',
                  gridTemplateColumns: '2fr 1fr 100px 80px 100px 80px 80px',
                  gap: 12,
                  cursor: 'pointer',
                }}
                onClick={() => setSelectedTenant(tenant)}
              >
                <span>
                  <strong>{tenant.name}</strong>
                  <br />
                  <span className="muted" style={{ fontSize: 12 }}>
                    {tenant.email || tenant.id}
                  </span>
                </span>
                <span>{tenant.planName || tenant.planId || '—'}</span>
                <span>
                  <span className={`badge badge--${getStatusVariant(tenant.status)}`}>
                    {tenant.status}
                  </span>
                </span>
                <span>{tenant.seats}</span>
                <span>
                  {tenant.hasCrm && (
                    <span className="badge badge--info" style={{ marginRight: 4 }}>
                      CRM
                    </span>
                  )}
                  {tenant.hasAi && <span className="badge badge--info">AI</span>}
                  {!tenant.hasCrm && !tenant.hasAi && '—'}
                </span>
                <span>
                  {tenant.flagsEnabled}/{tenant.flagsTotal}
                </span>
                <span>
                  <button
                    className="button button--ghost"
                    onClick={(e) => {
                      e.stopPropagation();
                      setSelectedTenant(tenant);
                    }}
                  >
                    View
                  </button>
                </span>
              </div>
            ))}
          </>
        )}

        <div className="muted" style={{ marginTop: 16, fontSize: 12 }}>
          Showing {filteredTenants.length} of {tenants.length} tenants
        </div>
      </div>

      {selectedTenant && (
        <TenantDetailDrawer
          businessId={selectedTenant.id}
          tenantName={selectedTenant.name}
          onClose={() => setSelectedTenant(null)}
          onUpdated={() => void refresh()}
        />
      )}
    </section>
  );
}
