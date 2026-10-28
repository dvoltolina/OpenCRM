/**
 * SMS History Component
 * Displays SMS message history for a contact
 *
 * Features:
 * - Message list with status indicators
 * - Direction indicators (inbound/outbound)
 * - Delivery status tracking
 * - Relative timestamps
 * - Segment count display
 */

import type { SmsMessage, SmsStatus } from '../../types/sms';

interface SmsHistoryProps {
  /** List of SMS messages */
  messages: SmsMessage[];
  /** Loading state */
  isLoading?: boolean;
  /** Error message */
  error?: string | null;
  /** Whether to mask phone numbers (HIPAA) */
  maskPhones?: boolean;
  /** Custom class name */
  className?: string;
}

/**
 * Format relative time
 */
function formatRelativeTime(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;

  return date.toLocaleDateString();
}

/**
 * Get status badge props
 */
function getStatusBadge(status: SmsStatus): {
  label: string;
  bgColor: string;
  textColor: string;
} {
  switch (status) {
    case 'queued':
      return { label: 'Queued', bgColor: 'bg-gray-100', textColor: 'text-gray-600' };
    case 'sent':
      return { label: 'Sent', bgColor: 'bg-blue-100', textColor: 'text-blue-600' };
    case 'delivered':
      return { label: 'Delivered', bgColor: 'bg-green-100', textColor: 'text-green-600' };
    case 'failed':
      return { label: 'Failed', bgColor: 'bg-red-100', textColor: 'text-red-600' };
    case 'undelivered':
      return { label: 'Undelivered', bgColor: 'bg-amber-100', textColor: 'text-amber-600' };
    default:
      return { label: 'Unknown', bgColor: 'bg-gray-100', textColor: 'text-gray-600' };
  }
}

/**
 * Individual message item
 */
function SmsMessageItem({
  message,
  maskPhones: _maskPhones = true,
}: {
  message: SmsMessage;
  maskPhones?: boolean;
}) {
  const isOutbound = message.direction === 'outbound';
  const status = getStatusBadge(message.status);
  const timestamp = message.sentAt || message.createdAt;

  return (
    <div
      className={`flex ${isOutbound ? 'justify-end' : 'justify-start'}`}
    >
      <div
        className={`max-w-[80%] rounded-lg px-4 py-2 ${
          isOutbound
            ? 'bg-blue-600 text-white'
            : 'bg-gray-100 text-gray-900'
        }`}
      >
        {/* Message body */}
        <p className="text-sm whitespace-pre-wrap break-words">
          {message.body}
        </p>

        {/* Metadata row */}
        <div className={`mt-1 flex items-center gap-2 text-xs ${
          isOutbound ? 'text-blue-200' : 'text-gray-500'
        }`}>
          {/* Timestamp */}
          <span>{formatRelativeTime(timestamp instanceof Date ? timestamp : new Date(timestamp))}</span>

          {/* Segment count */}
          {message.segmentCount > 1 && (
            <span>({message.segmentCount} segments)</span>
          )}

          {/* Status badge for outbound */}
          {isOutbound && (
            <span className={`px-1.5 py-0.5 rounded text-xs ${status.bgColor} ${status.textColor}`}>
              {status.label}
            </span>
          )}
        </div>

        {/* Error message if failed */}
        {message.status === 'failed' && message.errorMessage && (
          <p className={`mt-1 text-xs ${isOutbound ? 'text-red-200' : 'text-red-500'}`}>
            Error: {message.errorMessage}
          </p>
        )}
      </div>
    </div>
  );
}

export function SmsHistory({
  messages,
  isLoading = false,
  error = null,
  maskPhones = true,
  className = '',
}: SmsHistoryProps) {
  // Loading state
  if (isLoading) {
    return (
      <div className={`bg-white rounded-lg shadow p-4 ${className}`}>
        <div className="animate-pulse space-y-3">
          <div className="h-4 bg-gray-200 rounded w-1/4"></div>
          <div className="h-16 bg-gray-200 rounded w-3/4 ml-auto"></div>
          <div className="h-16 bg-gray-200 rounded w-3/4"></div>
          <div className="h-16 bg-gray-200 rounded w-1/2 ml-auto"></div>
        </div>
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className={`bg-white rounded-lg shadow p-4 ${className}`}>
        <div className="text-center py-8">
          <p className="text-red-600">{error}</p>
        </div>
      </div>
    );
  }

  // Empty state
  if (messages.length === 0) {
    return (
      <div className={`bg-white rounded-lg shadow p-4 ${className}`}>
        <div className="text-center py-8">
          <svg
            className="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
            />
          </svg>
          <h3 className="mt-2 text-sm font-medium text-gray-900">No messages</h3>
          <p className="mt-1 text-sm text-gray-500">
            No SMS messages have been sent to this contact yet.
          </p>
        </div>
      </div>
    );
  }

  // Message list
  return (
    <div className={`bg-white rounded-lg shadow ${className}`}>
      {/* Header */}
      <div className="px-4 py-3 border-b">
        <h3 className="text-lg font-medium">SMS History</h3>
        <p className="text-sm text-gray-500">{messages.length} message{messages.length !== 1 ? 's' : ''}</p>
      </div>

      {/* Messages */}
      <div className="p-4 space-y-3 max-h-96 overflow-y-auto">
        {messages.map((message) => (
          <SmsMessageItem
            key={message.id}
            message={message}
            maskPhones={maskPhones}
          />
        ))}
      </div>
    </div>
  );
}

/**
 * Stats summary for SMS history
 */
export function SmsHistoryStats({
  messages,
  className = '',
}: {
  messages: SmsMessage[];
  className?: string;
}) {
  const outbound = messages.filter((m) => m.direction === 'outbound');
  const inbound = messages.filter((m) => m.direction === 'inbound');
  const delivered = outbound.filter((m) => m.status === 'delivered').length;
  const failed = outbound.filter((m) => m.status === 'failed' || m.status === 'undelivered').length;

  return (
    <div className={`grid grid-cols-4 gap-4 ${className}`}>
      <div className="text-center">
        <p className="text-2xl font-semibold text-gray-900">{outbound.length}</p>
        <p className="text-xs text-gray-500">Sent</p>
      </div>
      <div className="text-center">
        <p className="text-2xl font-semibold text-green-600">{delivered}</p>
        <p className="text-xs text-gray-500">Delivered</p>
      </div>
      <div className="text-center">
        <p className="text-2xl font-semibold text-red-600">{failed}</p>
        <p className="text-xs text-gray-500">Failed</p>
      </div>
      <div className="text-center">
        <p className="text-2xl font-semibold text-blue-600">{inbound.length}</p>
        <p className="text-xs text-gray-500">Received</p>
      </div>
    </div>
  );
}

export default SmsHistory;
