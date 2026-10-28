import { useEffect, useState, type CSSProperties } from 'react';

import { ClientProfileDrawer } from '../components/ClientProfileDrawer';
import { listClients } from '../data/clients';
import { useBusinessContext } from '../hooks/useBusinessContext';
import type { Client } from '../types/models';
import { THEME, SPACING, PageHeader } from './dashboard/DashboardComponents';

function formatDate(value?: string): string {
  if (!value) return '—';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return '—';
  return parsed.toLocaleDateString();
}

export function ClientsPage() {
  const { businessId, userId } = useBusinessContext();
  const [selectedClient, setSelectedClient] = useState<Client | null>(null);
  const [clients, setClients] = useState<Client[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!businessId) {
      setClients([]);
      setLoading(false);
      setError('Business context is required to view clients.');
      return;
    }

    let cancelled = false;
    setLoading(true);
    setError(null);

    listClients(businessId, userId)
      .then((rows) => {
        if (cancelled) return;
        setClients(
          rows.sort(
            (a, b) =>
              new Date(b.createdAt ?? 0).getTime() - new Date(a.createdAt ?? 0).getTime(),
          ),
        );
      })
      .catch(() => {
        if (cancelled) return;
        setError('Failed to load clients.');
        setClients([]);
      })
      .finally(() => {
        if (!cancelled) {
          setLoading(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [businessId, userId]);

  const pageContainerStyle: CSSProperties = {
    minHeight: '100vh',
    background: `linear-gradient(180deg, ${THEME.colorBgGradientStart} 0%, ${THEME.colorBgGradientEnd} 100%)`,
    padding: SPACING.lg,
  };

  const tableContainerStyle: CSSProperties = {
    background: THEME.colorBgPanelGradient,
    borderRadius: THEME.radius,
    boxShadow: THEME.shadow,
    border: `1px solid ${THEME.colorBorder}`,
    overflow: 'hidden',
    transition: `box-shadow ${THEME.transitionBase} ease-out`,
  };

  const tableHeadStyle: CSSProperties = {
    display: 'grid',
    gridTemplateColumns: '1.4fr 1.6fr 1.1fr 0.9fr 0.8fr 0.8fr 0.8fr',
    gap: SPACING.md,
    padding: SPACING.lg,
    borderBottom: `1px solid ${THEME.colorBorder}`,
    fontSize: 11,
    fontWeight: 600,
    color: THEME.colorTextMuted,
    textTransform: 'uppercase',
    letterSpacing: '0.05em',
    backgroundColor: '#FAFBFC',
  };

  const tableRowStyle: CSSProperties = {
    display: 'grid',
    gridTemplateColumns: '1.4fr 1.6fr 1.1fr 0.9fr 0.8fr 0.8fr 0.8fr',
    gap: SPACING.md,
    padding: SPACING.lg,
    borderBottom: `1px solid ${THEME.colorBorderLight}`,
    fontSize: 14,
    color: THEME.colorText,
    alignItems: 'center',
    cursor: 'pointer',
    transition: `all ${THEME.transitionSpeed} ease-out`,
  };

  const buttonPrimaryStyle: CSSProperties = {
    padding: `${SPACING.sm + 2}px ${SPACING.lg}px`,
    fontSize: 14,
    fontWeight: 600,
    color: '#ffffff',
    backgroundColor: THEME.colorAccent,
    border: 'none',
    borderRadius: SPACING.sm,
    cursor: 'pointer',
    transition: `all ${THEME.transitionSpeed} ease-out`,
    boxShadow: '0 2px 8px rgba(14, 165, 233, 0.2)',
  };

  const buttonGhostStyle: CSSProperties = {
    padding: `${SPACING.sm + 2}px ${SPACING.lg}px`,
    fontSize: 14,
    fontWeight: 600,
    color: THEME.colorTextMuted,
    backgroundColor: 'transparent',
    border: `1px solid ${THEME.colorBorder}`,
    borderRadius: SPACING.sm,
    cursor: 'pointer',
    transition: `all ${THEME.transitionSpeed} ease-out`,
  };

  return (
    <section style={pageContainerStyle}>
      <PageHeader
        eyebrow="CRM"
        title="Clients"
        subtitle="Searchable client database with profile drawer (contact, notes, intake, history, payments, files)."
        actions={
          <>
            <button
              style={buttonGhostStyle}
              type="button"
              onMouseOver={(e) => {
                e.currentTarget.style.backgroundColor = THEME.colorBgPanel;
                e.currentTarget.style.borderColor = THEME.colorAccent;
                e.currentTarget.style.color = THEME.colorAccent;
              }}
              onMouseOut={(e) => {
                e.currentTarget.style.backgroundColor = 'transparent';
                e.currentTarget.style.borderColor = THEME.colorBorder;
                e.currentTarget.style.color = THEME.colorTextMuted;
              }}
            >
              Export CSV
            </button>
            <button
              style={buttonPrimaryStyle}
              type="button"
              onMouseOver={(e) => {
                e.currentTarget.style.backgroundColor = THEME.colorAccentStrong;
                e.currentTarget.style.transform = 'translateY(-1px)';
                e.currentTarget.style.boxShadow = '0 4px 12px rgba(14, 165, 233, 0.3)';
              }}
              onMouseOut={(e) => {
                e.currentTarget.style.backgroundColor = THEME.colorAccent;
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.boxShadow = '0 2px 8px rgba(14, 165, 233, 0.2)';
              }}
            >
              Add Client
            </button>
          </>
        }
      />

      <div style={tableContainerStyle}>
        <div style={tableHeadStyle}>
          <span>Name</span>
          <span>Email</span>
          <span>Phone</span>
          <span>Lifecycle</span>
          <span>Last Visit</span>
          <span>Next Visit</span>
          <span>Created</span>
        </div>

        {loading && (
          <div style={{ padding: SPACING.lg }}>
            <span style={{ color: THEME.colorTextMuted }}>Loading clients…</span>
          </div>
        )}

        {!loading && error && (
          <div style={{ padding: SPACING.lg }}>
            <span style={{ color: THEME.colorDanger }}>{error}</span>
          </div>
        )}

        {!loading && !error && clients.length === 0 && (
          <div style={{ padding: SPACING.lg }}>
            <span style={{ color: THEME.colorTextMuted }}>No clients found.</span>
          </div>
        )}

        {!loading &&
          !error &&
          clients.map((row) => (
            <div
              style={tableRowStyle}
              key={row.id}
              onClick={() =>
                setSelectedClient({
                  ...row,
                  businessId: row.businessId || businessId || '',
                })
              }
              onMouseOver={(e) => {
                e.currentTarget.style.backgroundColor = THEME.colorAccentSubtle;
                e.currentTarget.style.transform = 'translateY(-1px)';
              }}
              onMouseOut={(e) => {
                e.currentTarget.style.backgroundColor = 'transparent';
                e.currentTarget.style.transform = 'translateY(0)';
              }}
            >
              <span style={{ fontWeight: 600, color: THEME.colorText }}>{row.name ?? 'Unnamed Client'}</span>
              <span style={{ color: THEME.colorTextMuted }}>{row.email ?? '—'}</span>
              <span style={{ color: THEME.colorTextMuted }}>{row.phone ?? '—'}</span>
              <span style={{ fontWeight: 500 }}>{row.lifecycle ?? 'active'}</span>
              <span style={{ fontSize: 13, color: THEME.colorTextMuted }}>{formatDate(row.lastVisitAt)}</span>
              <span style={{ fontSize: 13, color: THEME.colorAccent, fontWeight: 500 }}>
                {formatDate(row.nextAppointmentAt)}
              </span>
              <span style={{ fontSize: 13, color: THEME.colorTextMuted }}>{formatDate(row.createdAt)}</span>
            </div>
          ))}
      </div>

      <ClientProfileDrawer client={selectedClient} onClose={() => setSelectedClient(null)} />
    </section>
  );
}
