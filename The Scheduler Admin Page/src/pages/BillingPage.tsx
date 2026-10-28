import { useMemo, useState, type CSSProperties } from 'react';
import { Link } from 'react-router-dom';

import { isDemoMode } from '../config/demo';
import { getPaymentReceiptUrl } from '../data/payments';
import { useDemoGuard } from '../hooks/useDemoGuard';
import { useBillingProfile } from '../hooks/useBillingProfile';
import { useBusinessContext } from '../hooks/useBusinessContext';
import { useFeatureFlags } from '../hooks/useFeatureFlags';
import { usePaymentsLedger, type LedgerEntry } from '../hooks/usePaymentsLedger';
import type { BillingProfile, Payment } from '../types/models';
import { THEME, SPACING } from '../pages/dashboard/DashboardComponents';

type LedgerFilters = {
  type: Payment['type'] | 'all';
  status: Payment['status'] | 'all';
  from: string;
  to: string;
  query: string;
};

type LedgerSummary = {
  received: number;
  pending: number;
  refunded: number;
};

const PAYMENT_TYPES: Payment['type'][] = [
  'full',
  'deposit',
  'subscription',
  'reschedule_fee',
  'cancellation_fee',
  'refund',
];

const PAYMENT_STATUSES: Payment['status'][] = [
  'completed',
  'pending',
  'failed',
  'refunded',
  'partially_refunded',
];

const typeLabels: Record<Payment['type'], string> = {
  full: 'Full Payment',
  deposit: 'Deposit',
  subscription: 'Subscription',
  reschedule_fee: 'Reschedule Fee',
  cancellation_fee: 'Cancellation Fee',
  refund: 'Refund',
};

const statusLabels: Record<Payment['status'], string> = {
  completed: 'Completed',
  pending: 'Pending',
  failed: 'Failed',
  refunded: 'Refunded',
  partially_refunded: 'Partially Refunded',
  none: 'None',
};

export function BillingPage() {
  const { businessId, userId, role } = useBusinessContext();
  const { notifyBlocked } = useDemoGuard();
  const { flags } = useFeatureFlags(businessId);
  const {
    profile: billingProfile,
    loading: billingLoading,
    error: billingError,
    refresh: refreshBilling,
    openPortal,
    launchCheckout,
  } = useBillingProfile(businessId, userId);
  const { entries, loading, error, refresh } = usePaymentsLedger(businessId, userId);
  const [filters, setFilters] = useState<LedgerFilters>({
    type: 'all',
    status: 'all',
    from: '',
    to: '',
    query: '',
  });
  const [portalLoading, setPortalLoading] = useState(false);
  const isOwner = role === 'owner';

  const filteredEntries = useMemo(
    () => entries.filter((entry) => matchesFilters(entry, filters)),
    [entries, filters],
  );

  const summary = useMemo(() => computeLedgerSummary(entries), [entries]);
  const summaryCurrency = entries[0]?.currency ?? 'USD';

  const pageStyle: CSSProperties = {
    background: `linear-gradient(180deg, ${THEME.colorBgGradientStart} 0%, ${THEME.colorBgGradientEnd} 100%)`,
    minHeight: '100vh',
    padding: SPACING.lg,
  };

  if (!isOwner) {
    return (
      <section style={pageStyle}>
        <div
          style={{
            background: THEME.colorBgPanelGradient,
            borderRadius: THEME.radius,
            boxShadow: THEME.shadow,
            border: `1px solid ${THEME.colorBorder}`,
            padding: SPACING.lg,
          }}
        >
          <p className="eyebrow">Billing</p>
          <h1>Owner access required</h1>
          <p className="muted">
            Only owners can view and manage billing, plans, and payment methods. Contact an owner to make changes.
          </p>
        </div>
      </section>
    );
  }

  const handleOpenPortal = async () => {
    if (isDemoMode) {
      notifyBlocked({ action: 'open customer portal' });
      return;
    }
    if (!businessId) return;
    setPortalLoading(true);
    try {
      const url = await openPortal();
      if (url && typeof window !== 'undefined') {
        window.open(url, '_blank', 'noopener,noreferrer');
        return;
      }
      alert('Customer Portal URL is unavailable right now.');
    } catch (err) {
      console.error('Failed to open portal', err);
      alert('Unable to open the Stripe Customer Portal right now.');
    } finally {
      setPortalLoading(false);
    }
  };

  const handleReceiptClick = async (paymentId: string) => {
    if (!businessId) return;
    try {
      const url = await getPaymentReceiptUrl(businessId, paymentId, userId);
      if (!url) {
        alert('Receipt link is not available for this payment yet.');
        return;
      }
      if (typeof window !== 'undefined') {
        window.open(url, '_blank', 'noopener,noreferrer');
      }
    } catch (err) {
      console.error('Failed to fetch receipt URL', err);
      alert('Unable to load the receipt link right now.');
    }
  };

  const handleClearFilters = () => {
    setFilters({
      type: 'all',
      status: 'all',
      from: '',
      to: '',
      query: '',
    });
  };

  return (
    <section aria-label="Billing and payments" style={pageStyle}>
      <header className="page-header">
        <div>
          <p className="eyebrow">Subscription & Billing</p>
          <h1>Payments Ledger & Billing</h1>
          <p className="muted">
            Review deposits, fees, refunds, and invoice receipts. Launch the Stripe Customer Portal to manage
            plan, usage, and payment methods.
          </p>
        </div>
        <div className="header-actions">
          <button
            className="button button--ghost"
            type="button"
            onClick={() => {
              void refresh();
              void refreshBilling();
            }}
            disabled={loading || billingLoading}
            aria-label="Refresh billing data"
          >
            Refresh
          </button>
          <button
            className="button button--primary"
            type="button"
            onClick={handleOpenPortal}
            disabled={!businessId || portalLoading || isDemoMode}
            title={isDemoMode ? 'Billing actions are disabled in demo mode.' : undefined}
            aria-label="Open Stripe customer portal"
          >
            {portalLoading ? 'Opening…' : 'Open Customer Portal'}
          </button>
        </div>
      </header>

      {!flags.enablePayments && (
        <div
          style={{
            background: THEME.colorBgPanelGradient,
            borderRadius: THEME.radius,
            boxShadow: THEME.shadow,
            border: `1px solid ${THEME.colorBorder}`,
            padding: SPACING.lg,
            marginBottom: SPACING.lg,
          }}
        >
          <p className="eyebrow">Payments disabled</p>
          <p className="muted">
            Payments are disabled for this tenant. Billing and ledgers will be read-only until the feature flag is
            enabled.
          </p>
        </div>
      )}

      {billingError && (
        <div
          style={{
            background: THEME.colorBgPanelGradient,
            borderRadius: THEME.radius,
            boxShadow: THEME.shadow,
            border: `1px solid ${THEME.colorDanger}`,
            padding: SPACING.lg,
            marginBottom: SPACING.lg,
          }}
        >
          <p className="muted">{billingError}</p>
        </div>
      )}

      {billingProfile && (
        <PlanSummary
          profile={billingProfile}
          loading={billingLoading || portalLoading}
          readOnly={isDemoMode}
          onCheckout={async () => {
            if (isDemoMode) {
              notifyBlocked({ action: 'update billing plan' });
              return;
            }
            setPortalLoading(true);
            try {
              const url = await launchCheckout({
                planId: billingProfile.planId ?? 'pro',
                seats: billingProfile.seats ?? 1,
                addons: billingProfile.addonIds ?? [],
              });
              if (url && typeof window !== 'undefined') {
                window.open(url, '_blank', 'noopener,noreferrer');
              }
            } finally {
              setPortalLoading(false);
            }
          }}
          onPortal={handleOpenPortal}
          onRefresh={refreshBilling}
        />
      )}

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(3, 1fr)',
          gap: SPACING.lg,
          marginBottom: SPACING.lg,
        }}
      >
        <SummaryCard
          label="Total Collected"
          value={formatCurrency(summary.received, summaryCurrency)}
          hint="Succeeded payments"
        />
        <SummaryCard
          label="Pending"
          value={formatCurrency(summary.pending, summaryCurrency)}
          hint="Awaiting capture/collection"
        />
        <SummaryCard
          label="Refunded / Returned"
          value={formatCurrency(summary.refunded, summaryCurrency)}
          hint="Refund and reversal amounts"
        />
      </div>

      <div
        style={{
          background: THEME.colorBgPanelGradient,
          borderRadius: THEME.radius,
          boxShadow: THEME.shadow,
          border: `1px solid ${THEME.colorBorder}`,
          padding: SPACING.lg,
          marginBottom: SPACING.lg,
        }}
      >
        <h2>Filters</h2>
        <div className="filters-grid">
          <label htmlFor="filter-type">
            Type
            <select
              id="filter-type"
              value={filters.type}
              onChange={(event) =>
                setFilters((prev) => ({ ...prev, type: event.target.value as LedgerFilters['type'] }))
              }
              aria-label="Filter by payment type"
            >
              <option value="all">All types</option>
              {PAYMENT_TYPES.map((type) => (
                <option key={type} value={type}>
                  {typeLabels[type]}
                </option>
              ))}
            </select>
          </label>
          <label htmlFor="filter-status">
            Status
            <select
              id="filter-status"
              value={filters.status}
              onChange={(event) =>
                setFilters((prev) => ({
                  ...prev,
                  status: event.target.value as LedgerFilters['status'],
                }))
              }
              aria-label="Filter by payment status"
            >
              <option value="all">All statuses</option>
              {PAYMENT_STATUSES.map((status) => (
                <option key={status} value={status}>
                  {statusLabels[status]}
                </option>
              ))}
            </select>
          </label>
          <label htmlFor="filter-from">
            From
            <input
              id="filter-from"
              type="date"
              value={filters.from}
              onChange={(event) => setFilters((prev) => ({ ...prev, from: event.target.value }))}
              aria-label="Filter from date"
            />
          </label>
          <label htmlFor="filter-to">
            To
            <input
              id="filter-to"
              type="date"
              value={filters.to}
              onChange={(event) => setFilters((prev) => ({ ...prev, to: event.target.value }))}
              aria-label="Filter to date"
            />
          </label>
          <label htmlFor="filter-search">
            Search
            <input
              id="filter-search"
              type="search"
              placeholder="Client, email, payment ID"
              value={filters.query}
              onChange={(event) => setFilters((prev) => ({ ...prev, query: event.target.value }))}
              aria-label="Search payments"
            />
          </label>
        </div>
        <div className="filters-actions">
          <button
            className="button button--ghost"
            type="button"
            onClick={handleClearFilters}
            disabled={
              filters.type === 'all' &&
              filters.status === 'all' &&
              !filters.from &&
              !filters.to &&
              !filters.query
            }
            aria-label="Clear all filters"
          >
            Reset filters
          </button>
        </div>
      </div>

      {error && (
        <p className="muted" style={{ color: THEME.colorDanger, marginBottom: SPACING.lg }}>
          {error}
        </p>
      )}

      <div
        style={{
          background: THEME.colorBgPanelGradient,
          borderRadius: THEME.radius,
          boxShadow: THEME.shadow,
          border: `1px solid ${THEME.colorBorder}`,
          padding: SPACING.lg,
        }}
      >
        <header className="panel__header">
          <div>
            <h2>Payments Ledger</h2>
            <p className="muted">
              Multi-tenant scoped ledger of deposits, fees, refunds, and payments tied to appointments and clients.
            </p>
          </div>
          <span className="muted">{filteredEntries.length} records</span>
        </header>
        {loading ? (
          <p>Loading ledger…</p>
        ) : filteredEntries.length === 0 ? (
          <p className="muted">No payments match your filters.</p>
        ) : (
          <div className="table" role="table" aria-label="Payments ledger">
            <div className="table__head" role="row">
              <span role="columnheader">Date</span>
              <span role="columnheader">Client</span>
              <span role="columnheader">Appointment</span>
              <span role="columnheader">Type</span>
              <span role="columnheader">Status</span>
              <span role="columnheader">Amount</span>
              <span role="columnheader">Receipt</span>
            </div>
            {filteredEntries.map((entry) => (
              <div className="table__row" key={entry.id} role="row">
                <span role="cell">{formatDateTime(entry.createdAt)}</span>
                <span role="cell">
                  {entry.clientId ? (
                    <Link to={`/clients?selected=${entry.clientId}`} className="link">
                      {entry.clientName ?? entry.clientId}
                    </Link>
                  ) : (
                    '—'
                  )}
                  {entry.clientEmail && <p className="muted">{entry.clientEmail}</p>}
                </span>
                <span role="cell">
                  {entry.appointmentId ? (
                    <>
                      <Link to={`/appointments?selected=${entry.appointmentId}`} className="link">
                        {formatDate(entry.appointmentStart)}
                      </Link>
                      <p className="muted">{entry.appointmentStatus}</p>
                    </>
                  ) : (
                    '—'
                  )}
                </span>
                <span role="cell">{typeLabels[entry.type]}</span>
                <span role="cell">
                  <span className={`status status--${entry.status}`}>{statusLabels[entry.status]}</span>
                </span>
                <span role="cell">{formatCurrency(entry.amountCents / 100, entry.currency)}</span>
                <span role="cell">
                  <button
                    className="button button--ghost"
                    type="button"
                    onClick={() => handleReceiptClick(entry.id)}
                    disabled={!businessId}
                    aria-label={`View receipt for payment ${entry.id}`}
                  >
                    View receipt
                  </button>
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </section>
  );
}

type PlanSummaryProps = {
  profile: BillingProfile;
  loading: boolean;
  readOnly?: boolean;
  onCheckout: () => Promise<void> | void;
  onPortal: () => Promise<void> | void;
  onRefresh: () => void;
};

function PlanSummary({ profile, loading, readOnly = false, onCheckout, onPortal, onRefresh }: PlanSummaryProps) {
  const statusMessage = buildStatusMessage(profile);
  return (
    <div
      style={{
        background: THEME.colorBgPanelGradient,
        borderRadius: THEME.radius,
        boxShadow: THEME.shadow,
        border: `1px solid ${THEME.colorBorder}`,
        padding: SPACING.lg,
        marginBottom: SPACING.lg,
      }}
    >
      <header className="panel__header">
        <div>
          <p className="eyebrow">Plan summary</p>
          <div style={{ display: 'flex', gap: SPACING.xs, alignItems: 'center' }}>
            <h3 style={{ margin: 0 }}>{profile.planName ?? profile.planId ?? 'Plan'}</h3>
            <StatusBadge status={profile.status} />
          </div>
          {statusMessage && <p className="muted">{statusMessage}</p>}
        </div>
        <div className="header-actions">
          <button className="button button--ghost" type="button" onClick={onRefresh} disabled={loading} aria-label="Refresh plan information">
            Refresh plan
          </button>
          <button className="button button--ghost" type="button" onClick={onCheckout} disabled={loading || readOnly} aria-label="Update subscription plan" title={readOnly ? 'Billing actions are disabled in demo mode.' : undefined}>
            Update plan
          </button>
          <button className="button button--primary" type="button" onClick={onPortal} disabled={loading || readOnly} aria-label="Manage billing in customer portal" title={readOnly ? 'Billing actions are disabled in demo mode.' : undefined}>
            Manage billing
          </button>
        </div>
      </header>
      {profile.status !== 'active' && (
        <div
          style={{
            background: profile.status === 'past_due' ? '#fee2e2' : THEME.colorAccentSubtle,
            borderRadius: THEME.radius,
            padding: SPACING.md,
            marginBottom: SPACING.md,
          }}
        >
          <strong style={{ textTransform: 'capitalize' }}>{profile.status ?? 'unknown'}</strong>
          <p className="muted" style={{ margin: 0 }}>
            {statusMessage || 'Review billing status in the customer portal.'}
          </p>
        </div>
      )}
      <div className="grid grid--3">
        <div>
          <p className="eyebrow">Seats</p>
          <p style={{ margin: 0 }}>{profile.seats ?? 0}</p>
          {profile.addonIds?.length ? (
            <p className="muted">{profile.addonIds.length} add-on(s)</p>
          ) : (
            <p className="muted">No add-ons</p>
          )}
        </div>
        <div>
          <p className="eyebrow">Renewal</p>
          <p style={{ margin: 0 }}>
            {profile.renewalDate ? formatDateOnly(profile.renewalDate) : profile.trialEndsAt ? 'In trial' : 'N/A'}
          </p>
          {profile.trialEndsAt && <p className="muted">Trial ends {formatDateOnly(profile.trialEndsAt)}</p>}
        </div>
        <div>
          <p className="eyebrow">Invoices</p>
          <p style={{ margin: 0 }}>{profile.lastInvoiceStatus ?? 'Unknown'}</p>
          {profile.cancelAt && <p className="muted">Cancels {formatDateOnly(profile.cancelAt)}</p>}
        </div>
      </div>
      <div style={{ marginTop: SPACING.md }}>
        <p className="eyebrow">Entitlements</p>
        {profile.entitlements?.length ? (
          <div className="grid grid--2">
            {profile.entitlements.map((entitlement) => (
              <div key={entitlement.id} style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>{entitlement.label}</span>
                <span className={`status status--${entitlement.enabled ? 'confirmed' : 'pending'}`}>
                  {entitlement.enabled ? 'Enabled' : 'Pending'}
                </span>
              </div>
            ))}
          </div>
        ) : (
          <p className="muted">Entitlements will appear once the subscription is active.</p>
        )}
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status?: BillingProfile['status'] }) {
  const label = status ?? 'unknown';
  const tone =
    status === 'active' ? 'confirmed' : status === 'trialing' ? 'confirmed' : status === 'past_due' ? 'pending' : 'failed';
  return <span className={`status status--${tone}`}>{label}</span>;
}

function buildStatusMessage(profile: BillingProfile): string {
  switch (profile.status) {
    case 'trialing':
      return profile.trialEndsAt ? `Trial ends ${formatDateOnly(profile.trialEndsAt)}` : 'Trialing';
    case 'past_due':
      return 'Payment is past due. Update payment method in the portal.';
    case 'canceled':
      return 'Subscription is canceled. Restart checkout to regain access.';
    case 'active':
      return 'Subscription active.';
    default:
      return '';
  }
}

function formatDateOnly(dateString?: string) {
  if (!dateString) return '—';
  const date = new Date(dateString);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleDateString();
}

function matchesFilters(entry: LedgerEntry, filters: LedgerFilters) {
  if (filters.type !== 'all' && entry.type !== filters.type) return false;
  if (filters.status !== 'all' && entry.status !== filters.status) return false;

  if (filters.from) {
    const fromTime = new Date(filters.from).setHours(0, 0, 0, 0);
    if (new Date(entry.createdAt).getTime() < fromTime) return false;
  }

  if (filters.to) {
    const toTime = new Date(filters.to).setHours(23, 59, 59, 999);
    if (new Date(entry.createdAt).getTime() > toTime) return false;
  }

  if (filters.query) {
    const query = filters.query.toLowerCase();
    const matchesQuery =
      entry.clientName?.toLowerCase().includes(query) ||
      entry.clientEmail?.toLowerCase().includes(query) ||
      entry.id.toLowerCase().includes(query);
    if (!matchesQuery) return false;
  }

  return true;
}

function computeLedgerSummary(entries: LedgerEntry[]): LedgerSummary {
  return entries.reduce<LedgerSummary>(
    (acc, entry) => {
      const amountInDollars = entry.amountCents / 100;
      if (entry.status === 'completed') {
        acc.received += amountInDollars;
      }
      if (entry.status === 'pending') {
        acc.pending += amountInDollars;
      }
      if (entry.type === 'refund' || entry.status === 'refunded' || entry.status === 'partially_refunded') {
        acc.refunded += amountInDollars;
      }
      return acc;
    },
    { received: 0, pending: 0, refunded: 0 },
  );
}

type SummaryCardProps = {
  label: string;
  value: string;
  hint: string;
};

function SummaryCard({ label, value, hint }: SummaryCardProps) {
  const [isHovered, setIsHovered] = useState(false);

  const cardStyle: CSSProperties = {
    background: THEME.colorBgPanelGradient,
    borderRadius: THEME.radius,
    boxShadow: isHovered ? THEME.shadowHover : THEME.shadow,
    border: `1px solid ${THEME.colorBorder}`,
    padding: SPACING.lg,
    transform: isHovered ? 'translateY(-3px)' : 'translateY(0)',
    transition: `all ${THEME.transitionBase} ease-out`,
  };

  return (
    <div
      style={cardStyle}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <p className="eyebrow">{label}</p>
      <h3>{value}</h3>
      <p className="muted">{hint}</p>
    </div>
  );
}

function formatCurrency(amount: number, currency: string) {
  try {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency,
    }).format(amount);
  } catch {
    return `$${amount.toFixed(2)}`;
  }
}

function formatDateTime(dateString: string) {
  const date = new Date(dateString);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleString();
}

function formatDate(dateString?: string) {
  if (!dateString) return 'Appointment';
  const date = new Date(dateString);
  if (Number.isNaN(date.getTime())) return 'Appointment';
  return date.toLocaleString();
}
