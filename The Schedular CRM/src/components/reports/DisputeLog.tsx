/**
 * DisputeLog Component
 * List of disputes with filtering and management actions
 *
 * Agent CRM-31 Implementation
 */

import { useState } from 'react';
import type { DisputeData } from '../../hooks/useAdvancedAnalytics';
import './reports.css';

// ============================================
// Types
// ============================================

export interface DisputeLogProps {
  /** Dispute data */
  data: DisputeData[];
  /** Currency for formatting */
  currency?: string;
  /** Whether data is loading */
  isLoading?: boolean;
  /** Selected status filter */
  selectedStatus?: 'open' | 'resolved' | 'lost' | 'all';
  /** Status filter callback */
  onStatusChange?: (status: 'open' | 'resolved' | 'lost' | 'all') => void;
  /** Action callbacks */
  onViewPayment?: (paymentId: string) => void;
  onViewClient?: (clientId: string) => void;
  onResolveDispute?: (disputeId: string) => void;
  onEscalateDispute?: (disputeId: string) => void;
}

// ============================================
// Helper Functions
// ============================================

function formatCurrency(cents: number, currency: string): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(cents / 100);
}

function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
}

function getDaysSince(date: Date): number {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  return Math.floor(diffMs / (1000 * 60 * 60 * 24));
}

// ============================================
// Component
// ============================================

/**
 * DisputeLog - Shows list of payment disputes with management actions
 *
 * @example
 * ```tsx
 * const disputes = analytics.getDisputes(dateRange, selectedStatus);
 *
 * <DisputeLog
 *   data={disputes}
 *   currency="USD"
 *   selectedStatus="open"
 *   onStatusChange={setSelectedStatus}
 *   onViewPayment={(id) => navigate(`/payments/${id}`)}
 *   onResolveDispute={handleResolve}
 * />
 * ```
 */
export function DisputeLog({
  data,
  currency = 'USD',
  isLoading = false,
  selectedStatus = 'all',
  onStatusChange,
  onViewPayment,
  onViewClient,
  onResolveDispute,
  onEscalateDispute,
}: DisputeLogProps) {
  const [sortBy, setSortBy] = useState<'date' | 'amount' | 'status'>('date');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');

  // Calculate stats
  const openDisputes = data.filter(d => d.status === 'open').length;
  const resolvedDisputes = data.filter(d => d.status === 'resolved').length;
  const lostDisputes = data.filter(d => d.status === 'lost').length;
  const totalAmount = data.reduce((sum, d) => sum + d.amountCents, 0);
  const openAmount = data
    .filter(d => d.status === 'open')
    .reduce((sum, d) => sum + d.amountCents, 0);

  // Sort data
  const sortedData = [...data].sort((a, b) => {
    let comparison = 0;

    if (sortBy === 'date') {
      comparison = a.createdAt.getTime() - b.createdAt.getTime();
    } else if (sortBy === 'amount') {
      comparison = a.amountCents - b.amountCents;
    } else if (sortBy === 'status') {
      comparison = a.status.localeCompare(b.status);
    }

    return sortOrder === 'asc' ? comparison : -comparison;
  });

  const handleSort = (field: 'date' | 'amount' | 'status') => {
    if (sortBy === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortBy(field);
      setSortOrder('desc');
    }
  };

  const getStatusBadgeClass = (status: string): string => {
    switch (status) {
      case 'open':
        return 'dispute-log__status-badge--warning';
      case 'resolved':
        return 'dispute-log__status-badge--success';
      case 'lost':
        return 'dispute-log__status-badge--danger';
      default:
        return '';
    }
  };

  return (
    <div className="dispute-log">
      <div className="dispute-log__header">
        <h2 className="dispute-log__title">Payment Disputes</h2>
        <div className="dispute-log__filters">
          <label>Status:</label>
          <div className="dispute-log__button-group">
            <button
              className={`dispute-log__filter-btn ${selectedStatus === 'all' ? 'dispute-log__filter-btn--active' : ''}`}
              onClick={() => onStatusChange?.('all')}
            >
              All ({data.length})
            </button>
            <button
              className={`dispute-log__filter-btn ${selectedStatus === 'open' ? 'dispute-log__filter-btn--active' : ''}`}
              onClick={() => onStatusChange?.('open')}
            >
              Open ({openDisputes})
            </button>
            <button
              className={`dispute-log__filter-btn ${selectedStatus === 'resolved' ? 'dispute-log__filter-btn--active' : ''}`}
              onClick={() => onStatusChange?.('resolved')}
            >
              Resolved ({resolvedDisputes})
            </button>
            <button
              className={`dispute-log__filter-btn ${selectedStatus === 'lost' ? 'dispute-log__filter-btn--active' : ''}`}
              onClick={() => onStatusChange?.('lost')}
            >
              Lost ({lostDisputes})
            </button>
          </div>
        </div>
      </div>

      <div className="dispute-log__stats">
        <div className="dispute-log__stat">
          <span className="dispute-log__stat-label">Total Disputes</span>
          <span className="dispute-log__stat-value">{data.length}</span>
        </div>
        <div className="dispute-log__stat dispute-log__stat--warning">
          <span className="dispute-log__stat-label">Open</span>
          <span className="dispute-log__stat-value">{openDisputes}</span>
        </div>
        <div className="dispute-log__stat dispute-log__stat--success">
          <span className="dispute-log__stat-label">Resolved</span>
          <span className="dispute-log__stat-value">{resolvedDisputes}</span>
        </div>
        <div className="dispute-log__stat dispute-log__stat--danger">
          <span className="dispute-log__stat-label">Lost</span>
          <span className="dispute-log__stat-value">{lostDisputes}</span>
        </div>
        <div className="dispute-log__stat">
          <span className="dispute-log__stat-label">Total Amount</span>
          <span className="dispute-log__stat-value">{formatCurrency(totalAmount, currency)}</span>
        </div>
        <div className="dispute-log__stat dispute-log__stat--warning">
          <span className="dispute-log__stat-label">Open Amount</span>
          <span className="dispute-log__stat-value">{formatCurrency(openAmount, currency)}</span>
        </div>
      </div>

      {isLoading ? (
        <div className="dispute-log__loading">
          <div className="dispute-log__spinner" />
          <p>Loading disputes...</p>
        </div>
      ) : data.length === 0 ? (
        <div className="dispute-log__empty">
          <p>No disputes found for the selected period and filters</p>
        </div>
      ) : (
        <div className="dispute-log__table-container">
          <table className="dispute-log__table">
            <thead>
              <tr>
                <th
                  onClick={() => handleSort('date')}
                  className="dispute-log__sortable"
                >
                  Date {sortBy === 'date' && (sortOrder === 'asc' ? '↑' : '↓')}
                </th>
                <th
                  onClick={() => handleSort('status')}
                  className="dispute-log__sortable"
                >
                  Status {sortBy === 'status' && (sortOrder === 'asc' ? '↑' : '↓')}
                </th>
                <th
                  onClick={() => handleSort('amount')}
                  className="dispute-log__sortable"
                >
                  Amount {sortBy === 'amount' && (sortOrder === 'asc' ? '↑' : '↓')}
                </th>
                <th>Client</th>
                <th>Reason</th>
                <th>Age</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {sortedData.map((dispute) => (
                <tr key={dispute.id}>
                  <td>{formatDate(dispute.createdAt)}</td>
                  <td>
                    <span
                      className={`dispute-log__status-badge ${getStatusBadgeClass(dispute.status)}`}
                    >
                      {dispute.status}
                    </span>
                  </td>
                  <td>
                    <strong>{formatCurrency(dispute.amountCents, currency)}</strong>
                  </td>
                  <td>
                    {onViewClient ? (
                      <button
                        className="dispute-log__link-btn"
                        onClick={() => onViewClient(dispute.clientId)}
                      >
                        {dispute.clientName || dispute.clientId}
                      </button>
                    ) : (
                      <span>{dispute.clientName || dispute.clientId}</span>
                    )}
                  </td>
                  <td className="dispute-log__reason">
                    {dispute.reason || 'No reason provided'}
                  </td>
                  <td>
                    <span className={getDaysSince(dispute.createdAt) > 7 ? 'dispute-log__age--old' : ''}>
                      {getDaysSince(dispute.createdAt)} days
                    </span>
                  </td>
                  <td>
                    <div className="dispute-log__actions">
                      {onViewPayment && (
                        <button
                          className="dispute-log__action-btn dispute-log__action-btn--primary"
                          onClick={() => onViewPayment(dispute.paymentId)}
                          title="View payment"
                        >
                          View Payment
                        </button>
                      )}
                      {dispute.status === 'open' && onResolveDispute && (
                        <button
                          className="dispute-log__action-btn dispute-log__action-btn--success"
                          onClick={() => onResolveDispute(dispute.id)}
                          title="Mark as resolved"
                        >
                          Resolve
                        </button>
                      )}
                      {dispute.status === 'open' && onEscalateDispute && (
                        <button
                          className="dispute-log__action-btn dispute-log__action-btn--danger"
                          onClick={() => onEscalateDispute(dispute.id)}
                          title="Escalate dispute"
                        >
                          Escalate
                        </button>
                      )}
                      {dispute.status === 'resolved' && dispute.resolvedAt && (
                        <span className="dispute-log__resolved-date">
                          Resolved {formatDate(dispute.resolvedAt)}
                        </span>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="dispute-log__info">
        <p>
          <strong>Note:</strong> Click column headers to sort. Disputes older than 7 days are
          highlighted. Open disputes require action.
        </p>
      </div>
    </div>
  );
}

export default DisputeLog;
