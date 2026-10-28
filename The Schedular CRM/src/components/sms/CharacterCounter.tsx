/**
 * SMS Character Counter Component
 * Displays character count, segment count, and estimated cost
 *
 * Features:
 * - Real-time character counting
 * - GSM-7 vs UCS-2 encoding detection
 * - Segment calculation
 * - Cost estimation
 * - Visual warnings for limits
 */

import {
  calculateCharacterCount,
  calculateSegmentCount,
  getRemainingChars,
  requiresUcs2,
  estimateCost,
  formatCost,
  SMS_CHAR_LIMITS,
} from '../../types/sms';

interface CharacterCounterProps {
  /** The SMS message text */
  text: string;
  /** Show cost estimate */
  showCost?: boolean;
  /** Show encoding type */
  showEncoding?: boolean;
  /** Custom class name */
  className?: string;
}

export function CharacterCounter({
  text,
  showCost = false,
  showEncoding = false,
  className = '',
}: CharacterCounterProps) {
  const isUcs2 = requiresUcs2(text);
  const charCount = isUcs2 ? text.length : calculateCharacterCount(text);
  const segmentCount = calculateSegmentCount(text);
  const remainingChars = getRemainingChars(text);
  const cost = estimateCost(text);

  // Determine warning states
  const maxSegments = SMS_CHAR_LIMITS.MAX_SEGMENTS;
  const isWarning = segmentCount >= maxSegments - 1;
  const isError = segmentCount >= maxSegments;

  // Determine color based on state
  const getStatusColor = () => {
    if (isError) return 'text-red-600';
    if (isWarning) return 'text-amber-600';
    return 'text-gray-600';
  };

  return (
    <div className={`flex flex-wrap items-center gap-3 text-sm ${className}`}>
      {/* Character count */}
      <span className={getStatusColor()}>
        {charCount} chars
      </span>

      {/* Remaining in current segment */}
      <span className="text-gray-500">
        ({remainingChars} remaining)
      </span>

      {/* Segment count */}
      <span className={`font-medium ${getStatusColor()}`}>
        {segmentCount} {segmentCount === 1 ? 'segment' : 'segments'}
      </span>

      {/* Encoding type */}
      {showEncoding && (
        <span className={`text-xs px-2 py-0.5 rounded-full ${
          isUcs2 ? 'bg-amber-100 text-amber-700' : 'bg-green-100 text-green-700'
        }`}>
          {isUcs2 ? 'UCS-2' : 'GSM-7'}
        </span>
      )}

      {/* Cost estimate */}
      {showCost && segmentCount > 0 && (
        <span className="text-gray-500">
          ~{formatCost(cost)}
        </span>
      )}

      {/* Warning messages */}
      {isError && (
        <span className="text-red-600 text-xs">
          Exceeds maximum segments
        </span>
      )}
      {isUcs2 && !isError && (
        <span className="text-amber-600 text-xs">
          Unicode characters reduce capacity
        </span>
      )}
    </div>
  );
}

/**
 * Compact version for inline use
 */
export function CharacterCounterCompact({
  text,
  className = '',
}: Pick<CharacterCounterProps, 'text' | 'className'>) {
  const charCount = requiresUcs2(text) ? text.length : calculateCharacterCount(text);
  const segmentCount = calculateSegmentCount(text);

  return (
    <span className={`text-xs text-gray-500 ${className}`}>
      {charCount}/{segmentCount === 1 ? '160' : '153×' + segmentCount}
    </span>
  );
}

export default CharacterCounter;
