/**
 * PaymentModal Component
 * Modal for collecting payment details and processing charges
 *
 * Agent CRM-29 Implementation
 * Dependencies: Modal, usePayments
 */

import React, { useCallback, useEffect, useState } from 'react';
import { Modal } from '../modals/Modal';
import { usePayments } from '../../hooks/usePayments';
import type { PaymentMethodCard } from '../../types/models';
import './payments.css';

// ============================================
// Types
// ============================================

export interface PaymentModalProps {
  /** Whether the modal is open */
  isOpen: boolean;
  /** Called when the modal should close */
  onClose: () => void;
  /** Client to charge */
  clientId: string;
  clientName: string;
  /** Optional deal to associate with payment */
  dealId?: string;
  dealTitle?: string;
  /** Default amount in cents */
  defaultAmount?: number;
  /** Currency code */
  currency?: string;
  /** Called after successful payment */
  onSuccess?: (paymentId: string) => void;
}

type PaymentStep = 'input' | 'confirm' | 'processing' | 'success' | 'error';

// ============================================
// Component
// ============================================

/**
 * PaymentModal - Modal for processing payments
 *
 * Flow:
 * 1. Input: Enter amount and select payment method
 * 2. Confirm: Review and confirm payment
 * 3. Processing: Processing the charge
 * 4. Success/Error: Show result
 */
export function PaymentModal({
  isOpen,
  onClose,
  clientId,
  clientName,
  dealId,
  dealTitle,
  defaultAmount,
  currency = 'USD',
  onSuccess,
}: PaymentModalProps) {
  const { chargeClient, getPaymentMethods, isLoading, error: paymentError } = usePayments();

  // Form state
  const [step, setStep] = useState<PaymentStep>('input');
  const [amountCents, setAmountCents] = useState(defaultAmount || 0);
  const [description, setDescription] = useState('');
  const [paymentMethod, setPaymentMethod] = useState<'saved' | 'new' | 'cash' | 'check'>('saved');
  const [selectedCard, setSelectedCard] = useState<string>('');
  const [saveCard, setSaveCard] = useState(false);

  // Saved cards
  const [savedCards, setSavedCards] = useState<PaymentMethodCard[]>([]);

  // Result state
  const [_resultPaymentId, setResultPaymentId] = useState<string>('');
  const [resultReceiptUrl, setResultReceiptUrl] = useState<string>('');
  const [errorMessage, setErrorMessage] = useState<string>('');

  const loadSavedCards = useCallback(async () => {
    if (!clientId) {
      setSavedCards([]);
      setSelectedCard('');
      return;
    }

    const cards = await getPaymentMethods(clientId);
    setSavedCards(cards);

    // Auto-select default card if available
    const defaultCard = cards.find((card) => card.isDefault);
    if (defaultCard) {
      setSelectedCard(defaultCard.id);
    } else if (cards.length > 0) {
      setSelectedCard(cards[0].id);
    } else {
      // No saved cards - default to new card
      setPaymentMethod('new');
    }
  }, [clientId, getPaymentMethods]);

  // Load saved cards when modal opens
  useEffect(() => {
    if (isOpen && clientId) {
      void loadSavedCards();
    }
  }, [clientId, isOpen, loadSavedCards]);

  // Reset form when modal opens
  useEffect(() => {
    if (isOpen) {
      setStep('input');
      setAmountCents(defaultAmount || 0);
      setDescription('');
      setPaymentMethod('saved');
      setSelectedCard('');
      setSaveCard(false);
      setErrorMessage('');
    }
  }, [isOpen, defaultAmount]);

  const handleAmountChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const dollars = parseFloat(e.target.value) || 0;
    setAmountCents(Math.round(dollars * 100));
  };

  const handleNext = () => {
    // Validate amount
    if (amountCents <= 0) {
      setErrorMessage('Please enter a valid amount');
      return;
    }

    // Validate payment method
    if (paymentMethod === 'saved' && !selectedCard) {
      setErrorMessage('Please select a payment method');
      return;
    }

    setErrorMessage('');
    setStep('confirm');
  };

  const handleBack = () => {
    setStep('input');
    setErrorMessage('');
  };

  const handleConfirm = async () => {
    setStep('processing');
    setErrorMessage('');

    try {
      // Determine payment method type
      let method: 'card' | 'new_card' | 'cash' | 'check' | 'other' = 'cash';
      let paymentMethodId: string | undefined;
      let newCardToken: string | undefined;

      if (paymentMethod === 'saved') {
        method = 'card';
        paymentMethodId = selectedCard;
      } else if (paymentMethod === 'new') {
        method = 'new_card';
        // In production, this would be a Stripe token from Stripe Elements
        newCardToken = 'tok_mock_new_card';
      } else if (paymentMethod === 'cash') {
        method = 'cash';
      } else if (paymentMethod === 'check') {
        method = 'check';
      }

      const result = await chargeClient({
        amountCents,
        currency,
        clientId,
        clientName,
        dealId,
        dealTitle,
        method,
        paymentMethodId,
        newCardToken,
        description: description || undefined,
        saveCard,
      });

      if (result.success && result.payment) {
        setResultPaymentId(result.payment.id);
        setResultReceiptUrl(result.payment.receiptUrl || '');
        setStep('success');

        // Notify parent after a brief delay
        setTimeout(() => {
          onSuccess?.(result.payment!.id);
        }, 1500);
      } else {
        setErrorMessage(formatErrorMessage(result.error || 'Payment failed'));
        setStep('error');
      }
    } catch (error) {
      setErrorMessage(
        formatErrorMessage(error instanceof Error ? error.message : 'Payment failed')
      );
      setStep('error');
    }
  };

  const handleClose = () => {
    if (step !== 'processing') {
      onClose();
    }
  };

  const formatAmount = (cents: number): string => {
    return (cents / 100).toFixed(2);
  };

  const getPaymentMethodLabel = (): string => {
    if (paymentMethod === 'saved' && selectedCard) {
      const card = savedCards.find((c) => c.id === selectedCard);
      if (card) {
        return `${card.brand.toUpperCase()} •••• ${card.last4}`;
      }
      return 'saved card';
    }

    if (paymentMethod === 'new') return 'new card';
    if (paymentMethod === 'cash') return 'cash';
    if (paymentMethod === 'check') return 'check';
    return 'payment method';
  };

  const formatErrorMessage = (message: string): string => {
    const normalized = message.endsWith('.') ? message.slice(0, -1) : message;
    const amountLabel = `${currency} ${formatAmount(amountCents)}`;
    const methodLabel = getPaymentMethodLabel();
    const extraDetail =
      paymentError && !normalized.toLowerCase().includes(paymentError.toLowerCase())
        ? ` Details: ${paymentError}.`
        : '';
    return `${normalized}. Attempted ${amountLabel} via ${methodLabel}.${extraDetail}`.trim();
  };

  const getModalTitle = (): string => {
    switch (step) {
      case 'input':
        return 'Process Payment';
      case 'confirm':
        return 'Confirm Payment';
      case 'processing':
        return 'Processing...';
      case 'success':
        return 'Payment Successful';
      case 'error':
        return 'Payment Failed';
      default:
        return 'Process Payment';
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={handleClose}
      title={getModalTitle()}
      size="md"
      closeOnOverlayClick={step !== 'processing'}
      closeOnEscape={step !== 'processing'}
    >
      <div className="payment-modal">
        {/* Input Step */}
        {step === 'input' && (
          <div className="payment-modal__step">
            <div className="payment-modal__client-info">
              <div className="payment-modal__label">Charging</div>
              <div className="payment-modal__client-name">{clientName}</div>
              {dealTitle && (
                <div className="payment-modal__deal-title">For: {dealTitle}</div>
              )}
            </div>

            <div className="payment-modal__form">
              {/* Amount */}
              <div className="payment-modal__field">
                <label htmlFor="amount" className="payment-modal__label">
                  Amount ({currency})
                </label>
                <div className="payment-modal__amount-input">
                  <span className="payment-modal__currency-symbol">$</span>
                  <input
                    id="amount"
                    type="number"
                    min="0"
                    step="0.01"
                    value={formatAmount(amountCents)}
                    onChange={handleAmountChange}
                    className="payment-modal__input"
                    placeholder="0.00"
                  />
                </div>
              </div>

              {/* Description */}
              <div className="payment-modal__field">
                <label htmlFor="description" className="payment-modal__label">
                  Description (optional)
                </label>
                <input
                  id="description"
                  type="text"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="payment-modal__input"
                  placeholder="Payment for..."
                />
              </div>

              {/* Payment Method */}
              <div className="payment-modal__field">
                <label className="payment-modal__label">Payment Method</label>
                <div className="payment-modal__method-tabs">
                  {savedCards.length > 0 && (
                    <button
                      type="button"
                      className={`payment-modal__method-tab ${
                        paymentMethod === 'saved' ? 'active' : ''
                      }`}
                      onClick={() => setPaymentMethod('saved')}
                    >
                      Saved Card
                    </button>
                  )}
                  <button
                    type="button"
                    className={`payment-modal__method-tab ${
                      paymentMethod === 'new' ? 'active' : ''
                    }`}
                    onClick={() => setPaymentMethod('new')}
                  >
                    New Card
                  </button>
                  <button
                    type="button"
                    className={`payment-modal__method-tab ${
                      paymentMethod === 'cash' ? 'active' : ''
                    }`}
                    onClick={() => setPaymentMethod('cash')}
                  >
                    Cash
                  </button>
                  <button
                    type="button"
                    className={`payment-modal__method-tab ${
                      paymentMethod === 'check' ? 'active' : ''
                    }`}
                    onClick={() => setPaymentMethod('check')}
                  >
                    Check
                  </button>
                </div>

                {/* Saved Card Selection */}
                {paymentMethod === 'saved' && savedCards.length > 0 && (
                  <div className="payment-modal__cards">
                    {savedCards.map((card) => (
                      <label key={card.id} className="payment-modal__card">
                        <input
                          type="radio"
                          name="savedCard"
                          value={card.id}
                          checked={selectedCard === card.id}
                          onChange={(e) => setSelectedCard(e.target.value)}
                        />
                        <div className="payment-modal__card-info">
                          <div className="payment-modal__card-brand">
                            {card.brand.toUpperCase()} •••• {card.last4}
                          </div>
                          <div className="payment-modal__card-expiry">
                            Expires {card.expMonth}/{card.expYear}
                          </div>
                        </div>
                      </label>
                    ))}
                  </div>
                )}

                {/* New Card (Placeholder for Stripe Elements) */}
                {paymentMethod === 'new' && (
                  <div className="payment-modal__new-card">
                    <div className="payment-modal__placeholder">
                      [Stripe Elements would be integrated here]
                      <br />
                      Card entry form with PCI-compliant tokenization
                    </div>
                    <label className="payment-modal__checkbox">
                      <input
                        type="checkbox"
                        checked={saveCard}
                        onChange={(e) => setSaveCard(e.target.checked)}
                      />
                      <span>Save card for future use</span>
                    </label>
                  </div>
                )}

                {/* Cash/Check Info */}
                {(paymentMethod === 'cash' || paymentMethod === 'check') && (
                  <div className="payment-modal__info">
                    Recording {paymentMethod} payment. No card processing required.
                  </div>
                )}
              </div>

              {errorMessage && (
                <div className="payment-modal__error" role="alert">{errorMessage}</div>
              )}

              {!errorMessage && paymentError && (
                <div className="payment-modal__error" role="alert">{paymentError}</div>
              )}
            </div>

            <div className="payment-modal__actions">
              <button
                type="button"
                onClick={handleClose}
                className="payment-modal__button payment-modal__button--secondary"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleNext}
                className="payment-modal__button payment-modal__button--primary"
                disabled={isLoading}
              >
                Next
              </button>
            </div>
          </div>
        )}

        {/* Confirm Step */}
        {step === 'confirm' && (
          <div className="payment-modal__step">
            <div className="payment-modal__confirm">
              <div className="payment-modal__confirm-section">
                <div className="payment-modal__label">Amount</div>
                <div className="payment-modal__confirm-value">
                  ${formatAmount(amountCents)} {currency}
                </div>
              </div>

              <div className="payment-modal__confirm-section">
                <div className="payment-modal__label">Client</div>
                <div className="payment-modal__confirm-value">{clientName}</div>
              </div>

              {dealTitle && (
                <div className="payment-modal__confirm-section">
                  <div className="payment-modal__label">Opportunity</div>
                  <div className="payment-modal__confirm-value">{dealTitle}</div>
                </div>
              )}

              {description && (
                <div className="payment-modal__confirm-section">
                  <div className="payment-modal__label">Description</div>
                  <div className="payment-modal__confirm-value">{description}</div>
                </div>
              )}

              <div className="payment-modal__confirm-section">
                <div className="payment-modal__label">Payment Method</div>
                <div className="payment-modal__confirm-value">
                  {paymentMethod === 'saved' && selectedCard && (
                    <>
                      {savedCards.find(c => c.id === selectedCard)?.brand.toUpperCase()} ••••{' '}
                      {savedCards.find(c => c.id === selectedCard)?.last4}
                    </>
                  )}
                  {paymentMethod === 'new' && 'New Card'}
                  {paymentMethod === 'cash' && 'Cash'}
                  {paymentMethod === 'check' && 'Check'}
                </div>
              </div>
            </div>

            <div className="payment-modal__actions">
              <button
                type="button"
                onClick={handleBack}
                className="payment-modal__button payment-modal__button--secondary"
              >
                Back
              </button>
              <button
                type="button"
                onClick={handleConfirm}
                className="payment-modal__button payment-modal__button--primary"
                disabled={isLoading}
              >
                Confirm & Charge
              </button>
            </div>
          </div>
        )}

        {/* Processing Step */}
        {step === 'processing' && (
          <div className="payment-modal__step payment-modal__step--center">
            <div className="payment-modal__spinner" />
            <div className="payment-modal__processing-text">Processing payment...</div>
          </div>
        )}

        {/* Success Step */}
        {step === 'success' && (
          <div className="payment-modal__step payment-modal__step--center">
            <div className="payment-modal__success-icon">
              <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
                <circle cx="32" cy="32" r="32" fill="#10B981" />
                <path
                  d="M20 32L28 40L44 24"
                  stroke="white"
                  strokeWidth="4"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            </div>
            <h3 className="payment-modal__success-title">Payment Successful!</h3>
            <div className="payment-modal__success-amount">
              ${formatAmount(amountCents)} {currency}
            </div>
            {resultReceiptUrl && (
              <a
                href={resultReceiptUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="payment-modal__receipt-link"
              >
                View Receipt
              </a>
            )}
          </div>
        )}

        {/* Error Step */}
        {step === 'error' && (
          <div className="payment-modal__step payment-modal__step--center">
            <div className="payment-modal__error-icon">
              <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
                <circle cx="32" cy="32" r="32" fill="#EF4444" />
                <path
                  d="M32 20V36M32 44V44.01"
                  stroke="white"
                  strokeWidth="4"
                  strokeLinecap="round"
                />
              </svg>
            </div>
            <h3 className="payment-modal__error-title">Payment Failed</h3>
            <div className="payment-modal__error-message" role="alert">
              {errorMessage || 'Payment could not be completed.'}
            </div>
            <div className="payment-modal__actions">
              <button
                type="button"
                onClick={() => setStep('input')}
                className="payment-modal__button payment-modal__button--primary"
              >
                Try Again
              </button>
            </div>
          </div>
        )}
      </div>
    </Modal>
  );
}

export default PaymentModal;
