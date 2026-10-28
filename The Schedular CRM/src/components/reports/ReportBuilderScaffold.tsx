import type { ReportDimension, ReportFilter, ReportMetric } from '../../types/reporting';
import { Card } from '../ui';
import type { ReportBuilderStepDefinition } from './report-builder-config';

interface StepRailProps {
  steps: ReportBuilderStepDefinition[];
  currentStep: number;
  onSelectStep: (step: number) => void;
  isStepComplete: (step: number) => boolean;
}

export function StepRail({
  steps,
  currentStep,
  onSelectStep,
  isStepComplete,
}: StepRailProps) {
  return (
    <Card className="report-builder__rail" padding="md" tone="subtle">
      <div className="report-builder__rail-header">
        <p className="ui-empty-state__eyebrow">Workflow</p>
        <h2>Build path</h2>
      </div>
      <div className="report-builder__rail-list">
        {steps.map((step, index) => {
          const isActive = currentStep === index;
          const isComplete = isStepComplete(index);

          return (
            <button
              key={step.label}
              type="button"
              className={`report-builder__step-card ${isActive ? 'is-active' : ''} ${
                isComplete ? 'is-complete' : ''
              }`}
              onClick={() => onSelectStep(index)}
              data-testid={`report-builder-step-${index}`}
            >
              <span className="report-builder__step-index">{index + 1}</span>
              <span className="report-builder__step-copy">
                <span className="report-builder__step-label">{step.label}</span>
                <span className="report-builder__step-description">{step.description}</span>
              </span>
            </button>
          );
        })}
      </div>
    </Card>
  );
}

interface BuilderSummaryPanelProps {
  reportName: string;
  reportTypeLabel: string;
  dataSourceLabel: string;
  stepLabel: string;
  dimensions: ReportDimension[];
  metrics: ReportMetric[];
  filters: ReportFilter[];
  dateRangeLabel: string;
  chartTypeLabel: string;
  issueCount: number;
  narrative: string;
}

export function BuilderSummaryPanel({
  reportName,
  reportTypeLabel,
  dataSourceLabel,
  stepLabel,
  dimensions,
  metrics,
  filters,
  dateRangeLabel,
  chartTypeLabel,
  issueCount,
  narrative,
}: BuilderSummaryPanelProps) {
  const statusLabel = issueCount === 0 ? 'Ready to save' : `${issueCount} item${issueCount === 1 ? '' : 's'} missing`;

  return (
    <Card className="report-builder__summary" padding="lg">
      <div className="report-builder__summary-header">
        <p className="ui-empty-state__eyebrow">Summary</p>
        <h2>{reportName || 'Untitled report'}</h2>
        <p>{narrative}</p>
      </div>

      <div className="report-builder__summary-status">
        <span className={`report-builder__status-badge ${issueCount === 0 ? 'is-complete' : 'is-pending'}`}>
          {statusLabel}
        </span>
        <span className="report-builder__status-step">{stepLabel}</span>
      </div>

      <dl className="report-builder__summary-list">
        <div>
          <dt>Type</dt>
          <dd>{reportTypeLabel}</dd>
        </div>
        <div>
          <dt>Data source</dt>
          <dd>{dataSourceLabel}</dd>
        </div>
        <div>
          <dt>Dimensions</dt>
          <dd>{dimensions.length || 'None'}</dd>
        </div>
        <div>
          <dt>Metrics</dt>
          <dd>{metrics.length || 'None'}</dd>
        </div>
        <div>
          <dt>Filters</dt>
          <dd>{filters.length || 'None'}</dd>
        </div>
        <div>
          <dt>Date range</dt>
          <dd>{dateRangeLabel}</dd>
        </div>
        <div>
          <dt>Display</dt>
          <dd>{chartTypeLabel}</dd>
        </div>
      </dl>
    </Card>
  );
}
