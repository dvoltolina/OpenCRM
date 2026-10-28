/**
 * PayNowButton Component
 * Button that opens the payment modal
 *
 * Agent CRM-29 Implementation
 * Dependencies: PaymentModal
 */

import { useState } from 'react';
import { PaymentModal } from './PaymentModal';
import './payments.css';

// ============================================
// Types
// ============================================

export interface PayNowButtonProps {
  /** Client to charge */
  clientId: string;
  clientName: string;
  /** Optional deal to associate with payment */
  dealId?: string;
  dealTitle?: string;
  /** Pre-filled amount in cents (optional) */
  amount?: number;
  /** Currency code */
  currency?: string;
  /** Called after successful payment */
  onSuccess?: (paymentId: string) => void;
  /** Button variant */
  variant?: 'primary' | 'secondary' | 'outline';
  /** Button size */
  size?: 'sm' | 'md' | 'lg';
  /** Button text */
  label?: string;
  /** Additional CSS class */
  className?: string;
  /** Disabled state */
  disabled?: boolean;
}

// ============================================
// Component
// ============================================

/**
 * PayNowButton - Opens payment modal to charge a client
 *
 * @example
 * ```tsx
 * <PayNowButton
 *   clientId="client-123"
 *   clientName="John Doe"
 *   dealId="deal-456"
 *   amount={10000}
 *   onSuccess={(paymentId) => {
 *     console.log('Payment succeeded:', paymentId);
 *   }}
 * />
 * ```
 */
export function PayNowButton({
  clientId,
  clientName,
  dealId,
  dealTitle,
  amount,
  currency = 'USD',
  onSuccess,
  variant = 'primary',
  size = 'md',
  label = 'Pay Now',
  className = '',
  disabled = false,
}: PayNowButtonProps) {
  const [isModalOpen, setIsModalOpen] = useState(false);

  const handleOpenModal = () => {
    if (!disabled) {
      setIsModalOpen(true);
    }
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
  };

  const handleSuccess = (paymentId: string) => {
    setIsModalOpen(false);
    onSuccess?.(paymentId);
  };

  return (
    <>
      <button
        type="button"
        onClick={handleOpenModal}
        disabled={disabled}
        className={`pay-now-button pay-now-button--${variant} pay-now-button--${size} ${className}`}
      >
        <svg
          width="16"
          height="16"
          viewBox="0 0 16 16"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          className="pay-now-button__icon"
        >
          <path
            d="M2 4H14C14.5523 4 15 4.44772 15 5V11C15 11.5523 14.5523 12 14 12H2C1.44772 12 1 11.5523 1 11V5C1 4.44772 1.44772 4 2 4Z"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M1 7H15"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
        <span>{label}</span>
      </button>

      <PaymentModal
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        clientId={clientId}
        clientName={clientName}
        dealId={dealId}
        dealTitle={dealTitle}
        defaultAmount={amount}
        currency={currency}
        onSuccess={handleSuccess}
      />
    </>
  );
}

export default PayNowButton;
