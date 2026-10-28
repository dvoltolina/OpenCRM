/**
 * AIInsightsCard Component
 * Displays AI-powered insights from The Scheduler
 *
 * Agent CRM-43 Implementation
 */

import { useClientAIInsights } from '../../hooks/useSchedulerData';
import type { AIInsights } from '../../hooks/useSchedulerData';
import './scheduler.css';

// ============================================
// Types
// ============================================

export interface AIInsightsCardProps {
  /** Client ID to fetch insights for */
  clientId: string;
}

// ============================================
// Helpers
// ============================================

function getRiskScoreColor(score: number): string {
  if (score <= 30) return 'risk-score--low';
  if (score <= 60) return 'risk-score--medium';
  return 'risk-score--high';
}

function getRiskScoreLabel(score: number): string {
  if (score <= 30) return 'Low Risk';
  if (score <= 60) return 'Medium Risk';
  return 'High Risk';
}

function getSentimentEmoji(sentiment: AIInsights['sentiment']): string {
  const emojis: Record<AIInsights['sentiment'], string> = {
    positive: '😊',
    neutral: '😐',
    negative: '😟',
  };
  return emojis[sentiment] || '😐';
}

function getSentimentLabel(sentiment: AIInsights['sentiment']): string {
  const labels: Record<AIInsights['sentiment'], string> = {
    positive: 'Positive',
    neutral: 'Neutral',
    negative: 'Negative',
  };
  return labels[sentiment] || 'Unknown';
}

function formatRelativeTime(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins} min${diffMins > 1 ? 's' : ''} ago`;
  if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
  if (diffDays < 7) return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;
  return date.toLocaleDateString();
}

// ============================================
// Component
// ============================================

/**
 * AIInsightsCard - Display AI insights for a client
 *
 * @example
 * ```tsx
 * <AIInsightsCard clientId="client-123" />
 * ```
 */
export function AIInsightsCard({ clientId }: AIInsightsCardProps) {
  const { insights, isLoading } = useClientAIInsights(clientId);

  if (isLoading) {
    return (
      <div className="ai-insights-card">
        <div className="ai-insights-card__loading">Loading AI insights...</div>
      </div>
    );
  }

  if (!insights) {
    return (
      <div className="ai-insights-card">
        <div className="ai-insights-card__empty">
          <div className="ai-insights-card__empty-icon">🤖</div>
          <div className="ai-insights-card__empty-text">AI insights not available</div>
          <div className="ai-insights-card__empty-subtext">
            Insights will appear once client data is analyzed
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="ai-insights-card">
      <div className="ai-insights-card__header">
        <h3 className="ai-insights-card__title">AI Insights</h3>
        <div className="ai-insights-card__updated">
          Updated {formatRelativeTime(insights.lastUpdated)}
        </div>
      </div>

      {/* Risk Score Gauge */}
      <div className="risk-score-section">
        <div className="risk-score-label">Risk Score</div>
        <div className={`risk-score-gauge ${getRiskScoreColor(insights.riskScore)}`}>
          <div className="risk-score-value">{Math.round(insights.riskScore)}</div>
          <div className="risk-score-max">/100</div>
        </div>
        <div className={`risk-score-status ${getRiskScoreColor(insights.riskScore)}`}>
          {getRiskScoreLabel(insights.riskScore)}
        </div>
        <div className="risk-score-bar">
          <div
            className={`risk-score-bar-fill ${getRiskScoreColor(insights.riskScore)}`}
            style={{ width: `${insights.riskScore}%` }}
          />
        </div>
      </div>

      {/* Sentiment Indicator */}
      <div className="sentiment-section">
        <div className="sentiment-label">Sentiment</div>
        <div className="sentiment-indicator">
          <span className="sentiment-emoji">{getSentimentEmoji(insights.sentiment)}</span>
          <span className="sentiment-text">{getSentimentLabel(insights.sentiment)}</span>
        </div>
      </div>

      {/* Risk Factors */}
      {insights.factors && insights.factors.length > 0 && (
        <div className="risk-factors-section">
          <div className="risk-factors-label">Risk Factors</div>
          <ul className="risk-factors-list">
            {insights.factors.map((factor, index) => (
              <li key={index} className="risk-factor-item">
                {factor}
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* Footer Attribution */}
      <div className="ai-insights-card__footer">
        AI insights powered by The Scheduler
      </div>
    </div>
  );
}

export default AIInsightsCard;
