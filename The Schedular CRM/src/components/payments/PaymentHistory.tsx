/**
 * PaymentHistory Component
 * Displays payment history for a client or deal with pagination
 *
 * Agent CRM-29 Implementation
 * Dependencies: usePaymentHistory
 */

import React, { useState } from 'react';
import { usePaymentHistory } from '../../hooks/usePayments';
import type { Payment } from '../../types/models';
import './payments.css';

// ============================================
// Types
// ============================================

export interface PaymentHistoryProps {
  /** Filter by client ID */
  clientId?: string;
  /** Filter by deal ID */
  dealId?: string;
  /** Maximum number of payments to show per page */
  pageSize?: number;
  /** Show empty state when no payments */
  showEmptyState?: boolean;
  /** Additional CSS class */
  className?: string;
}

// ============================================
// Component
// ============================================

/**
 * PaymentHistory - Displays payment history
 *
 * @example
 * ```tsx
 * <PaymentHistory
 *   clientId="client-123"
 *   pageSize={10}
 * />
 * ```
 */
export function PaymentHistory({
  clientId,
  dealId,
  pageSize = 10,
  showEmptyState = true,
  className = '',
}: PaymentHistoryProps) {
  const { payments, isLoading, error, refresh } = usePaymentHistory({
    clientId,
    dealId,
    limit: pageSize,
  });

  const [expandedPayment, setExpandedPayment] = useState<string | null>(null);

  const toggleExpand = (paymentId: string) => {
    setExpandedPayment(expandedPayment === paymentId ? null : paymentId);
  };

  const formatAmount = (cents: number, currency: string): string => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency || 'USD',
    }).format(cents / 100);
  };

  const formatDate = (date: Date): string => {
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    }).format(date);
  };

  const getStatusBadgeClass = (status: Payment['status']): string => {
    switch (status) {
      case 'succeeded':
        return 'payment-history__badge--success';
      case 'pending':
        return 'payment-history__badge--warning';
      case 'failed':
        return 'payment-history__badge--error';
      case 'refunded':
        return 'payment-history__badge--neutral';
      case 'disputed':
        return 'payment-history__badge--danger';
      default:
        return 'payment-history__badge--neutral';
    }
  };

  const getDisputeIcon = (payment: Payment): React.ReactNode => {
    if (!payment.disputeStatus || payment.disputeStatus === 'none') {
      return null;
    }

    return (
      <span className="payment-history__dispute-flag" title={payment.disputeReason}>
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
          <path
            d="M8 1L8 15M8 1L2 5L8 15M8 1L14 5L8 15"
            stroke="#EF4444"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
        Dispute
      </span>
    );
  };

  if (isLoading) {
    return (
      <div className={`payment-history ${className}`}>
        <div className="payment-history__loading">
          <div className="payment-history__spinner" />
          <span>Loading payments...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className={`payment-history ${className}`}>
        <div className="payment-history__error">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2" />
            <path
              d="M12 8V12M12 16H12.01"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            />
          </svg>
          <span>Failed to load payment history</span>
          <button
            type="button"
            onClick={refresh}
            className="payment-history__retry"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  if (payments.length === 0 && showEmptyState) {
    return (
      <div className={`payment-history ${className}`}>
        <div className="payment-history__empty">
          <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
            <path
              d="M8 16H40C41.1046 16 42 16.8954 42 18V34C42 35.1046 41.1046 36 40 36H8C6.89543 36 6 35.1046 6 34V18C6 16.8954 6.89543 16 8 16Z"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <path
              d="M6 22H42"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
          <h3>No payments yet</h3>
          <p>Payment history will appear here once payments are processed.</p>
        </div>
      </div>
    );
  }

  return (
    <div className={`payment-history ${className}`}>
      <div className="payment-history__header">
        <h3 className="payment-history__title">Payment History</h3>
        <button
          type="button"
          onClick={refresh}
          className="payment-history__refresh"
          title="Refresh"
        >
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
            <path
              d="M14 8C14 11.3137 11.3137 14 8 14C4.68629 14 2 11.3137 2 8C2 4.68629 4.68629 2 8 2C9.84871 2 11.5051 2.83532 12.6 4.15"
              stroke="currentColor"
              strokeWidth="1.5"
              strokeLinecap="round"
            />
            <path
              d="M12 2V4.5H9.5"
              stroke="currentColor"
              strokeWidth="1.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </button>
      </div>

      <div className="payment-history__list">
        {payments.map((payment) => (
          <div
            key={payment.id}
            className={`payment-history__item ${
              expandedPayment === payment.id ? 'expanded' : ''
            }`}
          >
            <div
              className="payment-history__item-header"
              onClick={() => toggleExpand(payment.id)}
            >
              <div className="payment-history__item-main">
                <div className="payment-history__item-amount">
                  {formatAmount(payment.amountCents, payment.currency)}
                </div>
                <div className="payment-history__item-meta">
                  <span className={`payment-history__badge ${getStatusBadgeClass(payment.status)}`}>
                    {payment.status}
                  </span>
                  {payment.method && (
                    <span className="payment-history__method">
                      {payment.method === 'card' && payment.cardBrand && payment.last4
                        ? `${payment.cardBrand.toUpperCase()} •••• ${payment.last4}`
                        : payment.method}
                    </span>
                  )}
                  {getDisputeIcon(payment)}
                </div>
              </div>
              <div className="payment-history__item-date">
                {formatDate(payment.createdAt)}
              </div>
              <button
                type="button"
                className="payment-history__expand-icon"
                aria-label={expandedPayment === payment.id ? 'Collapse' : 'Expand'}
              >
                <svg
                  width="16"
                  height="16"
                  viewBox="0 0 16 16"
                  fill="none"
                  style={{
                    transform: expandedPayment === payment.id ? 'rotate(180deg)' : 'none',
                  }}
                >
                  <path
                    d="M4 6L8 10L12 6"
                    stroke="currentColor"
                    strokeWidth="1.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </button>
            </div>

            {expandedPayment === payment.id && (
              <div className="payment-history__item-details">
                <div className="payment-history__detail-row">
                  <span className="payment-history__detail-label">Client:</span>
                  <span className="payment-history__detail-value">{payment.clientName}</span>
                </div>

                {payment.dealTitle && (
                  <div className="payment-history__detail-row">
                    <span className="payment-history__detail-label">Opportunity:</span>
                    <span className="payment-history__detail-value">{payment.dealTitle}</span>
                  </div>
                )}

                {payment.description && (
                  <div className="payment-history__detail-row">
                    <span className="payment-history__detail-label">Description:</span>
                    <span className="payment-history__detail-value">{payment.description}</span>
                  </div>
                )}

                <div className="payment-history__detail-row">
                  <span className="payment-history__detail-label">Processed by:</span>
                  <span className="payment-history__detail-value">{payment.processedByName}</span>
                </div>

                {payment.providerId && (
                  <div className="payment-history__detail-row">
                    <span className="payment-history__detail-label">Transaction ID:</span>
                    <span className="payment-history__detail-value payment-history__detail-value--mono">
                      {payment.providerId}
                    </span>
                  </div>
                )}

                {payment.notes && (
                  <div className="payment-history__detail-row">
                    <span className="payment-history__detail-label">Notes:</span>
                    <span className="payment-history__detail-value">{payment.notes}</span>
                  </div>
                )}

                {payment.receiptUrl && (
                  <div className="payment-history__detail-row">
                    <a
                      href={payment.receiptUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="payment-history__receipt-link"
                    >
                      View Receipt →
                    </a>
                  </div>
                )}

                {payment.disputeStatus && payment.disputeStatus !== 'none' && (
                  <div className="payment-history__dispute-info">
                    <div className="payment-history__dispute-status">
                      Dispute Status: {payment.disputeStatus}
                    </div>
                    {payment.disputeReason && (
                      <div className="payment-history__dispute-reason">
                        Reason: {payment.disputeReason}
                      </div>
                    )}
                  </div>
                )}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

export default PaymentHistory;
