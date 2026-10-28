import { useEffect, useState } from 'react';
import type {
  AggregationType,
  ChartType,
  DateRange,
  ReportDataSource,
  ReportDimension,
  ReportFilter,
  ReportMetric,
  ReportType,
} from '../../types/reporting';
import { Button, Card } from '../ui';
import {
  BasicsStep,
  DataSelectionStep,
  DisplayStep,
  FiltersStep,
} from './ReportBuilderSections';
import { BuilderSummaryPanel, StepRail } from './ReportBuilderScaffold';
import {
  CHART_TYPES,
  DATA_SOURCES,
  DATE_RANGES,
  DEFAULT_FIELDS,
  REPORT_BUILDER_STEPS,
  REPORT_TYPES,
  type DataSourceField,
} from './report-builder-config';
import './report-builder.css';

export interface ReportBuilderProps {
  initialData?: Partial<ReportBuilderData>;
  onSave: (data: ReportBuilderData) => Promise<void>;
  onCancel: () => void;
  isSaving?: boolean;
  isEditing?: boolean;
  availableFields?: DataSourceField[];
}

export interface ReportBuilderData {
  name: string;
  description?: string;
  reportType: ReportType;
  chartType: ChartType;
  dataSource: ReportDataSource;
  dimensions: ReportDimension[];
  metrics: ReportMetric[];
  filters: ReportFilter[];
  defaultDateRange: DateRange;
  dateField: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
  limit?: number;
  isPublic: boolean;
  sharedWithTeamIds?: string[];
}

function findLabel(
  options: Array<{ value: string; label: string }>,
  value: string,
  fallback: string
) {
  return options.find((option) => option.value === value)?.label || fallback;
}

function getDefaultMetricFormat(fieldName: string): 'number' | 'currency' | 'percent' {
  const normalized = fieldName.toLowerCase();

  if (
    normalized.includes('value') ||
    normalized.includes('amount') ||
    normalized.includes('revenue') ||
    normalized.includes('cents')
  ) {
    return 'currency';
  }

  if (
    normalized.includes('rate') ||
    normalized.includes('probability') ||
    normalized.includes('percent')
  ) {
    return 'percent';
  }

  return 'number';
}

function getDefaultAggregation(fieldName: string): AggregationType {
  const normalized = fieldName.toLowerCase();
  return normalized.includes('rate') || normalized.includes('probability') ? 'avg' : 'sum';
}

function buildNarrative(
  name: string,
  dimensions: ReportDimension[],
  metrics: ReportMetric[],
  filters: ReportFilter[],
  chartTypeLabel: string
) {
  if (!name.trim() && dimensions.length === 0 && metrics.length === 0) {
    return 'Start with a clear name, then add dimensions and metrics to shape the report.';
  }

  const parts: string[] = [];

  if (dimensions.length > 0) {
    parts.push(`Grouped by ${dimensions.map((dimension) => dimension.label).join(', ')}`);
  }

  if (metrics.length > 0) {
    parts.push(`measuring ${metrics.map((metric) => metric.label).join(', ')}`);
  }

  if (filters.length > 0) {
    parts.push(`${filters.length} additional filter${filters.length === 1 ? '' : 's'} applied`);
  }

  if (parts.length === 0) {
    parts.push('The report foundation is ready for metrics and filters');
  }

  return `${parts.join(' · ')} · Displayed as ${chartTypeLabel.toLowerCase()}.`;
}

function isPositiveInteger(value: number) {
  return Number.isFinite(value) && value > 0;
}

export function ReportBuilder({
  initialData,
  onSave,
  onCancel,
  isSaving = false,
  isEditing = false,
  availableFields,
}: ReportBuilderProps) {
  const [name, setName] = useState(initialData?.name || '');
  const [description, setDescription] = useState(initialData?.description || '');
  const [reportType, setReportType] = useState<ReportType>(initialData?.reportType || 'deals');
  const [chartType, setChartType] = useState<ChartType>(initialData?.chartType || 'bar');
  const [dataSource, setDataSource] = useState<ReportDataSource>(initialData?.dataSource || 'deals');
  const [dimensions, setDimensions] = useState<ReportDimension[]>(initialData?.dimensions || []);
  const [metrics, setMetrics] = useState<ReportMetric[]>(initialData?.metrics || []);
  const [filters, setFilters] = useState<ReportFilter[]>(initialData?.filters || []);
  const [defaultDateRange, setDefaultDateRange] = useState<DateRange>(
    initialData?.defaultDateRange || 'this_month'
  );
  const [dateField, setDateField] = useState(initialData?.dateField || 'createdAt');
  const [sortBy, setSortBy] = useState(initialData?.sortBy || '');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>(initialData?.sortOrder || 'desc');
  const [limit, setLimit] = useState(initialData?.limit || 100);
  const [isPublic, setIsPublic] = useState(initialData?.isPublic || false);
  const [currentStep, setCurrentStep] = useState(0);
  const [errors, setErrors] = useState<Record<string, string>>({});

  const fields = availableFields || DEFAULT_FIELDS[dataSource] || [];
  const dimensionFields = fields.filter((field) => field.type !== 'number');
  const metricFields = fields.filter((field) => field.aggregatable !== false && field.type === 'number');
  const filterableFields = fields.filter((field) => field.filterable !== false);
  const dateFields = fields.filter((field) => field.type === 'date');
  const sortableFields = [...dimensions, ...metrics];

  useEffect(() => {
    if (dateFields.length === 0) {
      if (dateField) {
        setDateField('');
      }
      return;
    }

    if (!dateFields.some((field) => field.field === dateField)) {
      setDateField(dateFields[0].field);
    }
  }, [dateField, dateFields]);

  useEffect(() => {
    if (sortBy && !sortableFields.some((field) => field.field === sortBy)) {
      setSortBy('');
    }
  }, [dimensions, metrics, sortBy, sortableFields]);

  const validateStep = (step: number) => {
    const nextErrors = { ...errors };

    delete nextErrors.name;
    delete nextErrors.dimensions;

    if ((step === 0 || step === REPORT_BUILDER_STEPS.length - 1) && !name.trim()) {
      nextErrors.name = 'Report name is required';
    }

    if (
      (step === 1 || step === REPORT_BUILDER_STEPS.length - 1) &&
      dimensions.length === 0 &&
      metrics.length === 0
    ) {
      nextErrors.dimensions = 'Add at least one dimension or metric';
    }

    setErrors(nextErrors);
    return Object.keys(nextErrors).length === 0;
  };

  const handleSelectStep = (step: number) => {
    if (step > currentStep && !validateStep(currentStep)) {
      return;
    }

    setCurrentStep(step);
  };

  const handleNextStep = () => {
    if (!validateStep(currentStep)) {
      return;
    }

    setCurrentStep((previous) => Math.min(previous + 1, REPORT_BUILDER_STEPS.length - 1));
  };

  const handleDimensionChange = (selectedFields: string[]) => {
    const dimensionMap = new Map(dimensions.map((dimension) => [dimension.field, dimension]));

    setDimensions(
      selectedFields.map((fieldName) => {
        const fieldDefinition = fields.find((field) => field.field === fieldName);
        const existing = dimensionMap.get(fieldName);

        return {
          field: fieldName,
          label: fieldDefinition?.label || fieldName,
          type:
            fieldDefinition?.type === 'date'
              ? 'date'
              : fieldDefinition?.type === 'boolean'
                ? 'boolean'
                : 'string',
          dateGranularity:
            fieldDefinition?.type === 'date'
              ? existing?.dateGranularity || 'month'
              : undefined,
        };
      })
    );
  };

  const handleMetricChange = (selectedFields: string[]) => {
    const metricMap = new Map(metrics.map((metric) => [metric.field, metric]));

    setMetrics(
      selectedFields.map((fieldName) => {
        const fieldDefinition = fields.find((field) => field.field === fieldName);
        const existing = metricMap.get(fieldName);

        return (
          existing || {
            field: fieldName,
            label: fieldDefinition?.label || fieldName,
            aggregation: getDefaultAggregation(fieldName),
            format: getDefaultMetricFormat(fieldName),
          }
        );
      })
    );
  };

  const handleMetricUpdate = (
    index: number,
    updates: Partial<{
      aggregation: AggregationType;
      format: 'number' | 'currency' | 'percent';
    }>
  ) => {
    setMetrics((previous) =>
      previous.map((metric, metricIndex) =>
        metricIndex === index ? { ...metric, ...updates } : metric
      )
    );
  };

  const handleDateGranularityChange = (
    granularity: 'day' | 'week' | 'month' | 'quarter' | 'year'
  ) => {
    setDimensions((previous) =>
      previous.map((dimension) =>
        dimension.type === 'date' ? { ...dimension, dateGranularity: granularity } : dimension
      )
    );
  };

  const handleDataSourceChange = (nextDataSource: string) => {
    setDataSource(nextDataSource as ReportDataSource);
    setDimensions([]);
    setMetrics([]);
    setFilters([]);
    setSortBy('');
  };

  const handleAddFilter = () => {
    const firstFilterableField = filterableFields[0]?.field || '';

    setFilters((previous) => [
      ...previous,
      { field: firstFilterableField, operator: 'eq', value: '' },
    ]);
  };

  const handleUpdateFilter = (index: number, updates: Partial<ReportFilter>) => {
    setFilters((previous) =>
      previous.map((filter, filterIndex) =>
        filterIndex === index ? { ...filter, ...updates } : filter
      )
    );
  };

  const handleRemoveFilter = (index: number) => {
    setFilters((previous) => previous.filter((_, filterIndex) => filterIndex !== index));
  };

  const handleSave = async () => {
    if (!validateStep(REPORT_BUILDER_STEPS.length - 1)) {
      return;
    }

    const data: ReportBuilderData = {
      name: name.trim(),
      description: description.trim() || undefined,
      reportType,
      chartType,
      dataSource,
      dimensions,
      metrics,
      filters,
      defaultDateRange,
      dateField,
      sortBy: sortBy || undefined,
      sortOrder,
      limit: isPositiveInteger(limit) ? limit : 100,
      isPublic,
    };

    await onSave(data);
  };

  const currentStepMeta = REPORT_BUILDER_STEPS[currentStep];
  const issueCount = [!name.trim(), dimensions.length === 0 && metrics.length === 0].filter(Boolean).length;
  const reportTypeLabel = findLabel(REPORT_TYPES, reportType, reportType);
  const dataSourceLabel = findLabel(DATA_SOURCES, dataSource, dataSource);
  const chartTypeLabel = findLabel(CHART_TYPES, chartType, chartType);
  const dateRangeLabel = findLabel(DATE_RANGES, defaultDateRange, defaultDateRange);
  const narrative = buildNarrative(name, dimensions, metrics, filters, chartTypeLabel);

  return (
    <section className="report-builder" data-testid="report-builder">
      <Card className="report-builder__hero" padding="lg" tone="accent">
        <div className="report-builder__hero-copy">
          <p className="ui-empty-state__eyebrow">Advanced Reporting</p>
          <h1>{isEditing ? 'Refine custom report' : 'Build a custom report'}</h1>
          <p>
            Create aggregate-only report definitions for scheduled delivery, ad hoc exports, and
            reusable dashboard views.
          </p>
        </div>

        <div className="report-builder__hero-metrics">
          <div>
            <span>Current step</span>
            <strong>
              {currentStep + 1} / {REPORT_BUILDER_STEPS.length}
            </strong>
          </div>
          <div>
            <span>Selections</span>
            <strong>{dimensions.length + metrics.length + filters.length}</strong>
          </div>
          <div>
            <span>Status</span>
            <strong>{issueCount === 0 ? 'Ready' : 'In progress'}</strong>
          </div>
        </div>
      </Card>

      <div className="report-builder__workspace">
        <StepRail
          steps={REPORT_BUILDER_STEPS}
          currentStep={currentStep}
          onSelectStep={handleSelectStep}
          isStepComplete={(step) => {
            if (step === 0) return Boolean(name.trim());
            if (step === 1) return dimensions.length > 0 || metrics.length > 0;
            return step < currentStep;
          }}
        />

        <div className="report-builder__canvas-column">
          <Card className="report-builder__canvas" padding="lg">
            <div className="report-builder__canvas-header">
              <div>
                <p className="ui-empty-state__eyebrow">Step {currentStep + 1}</p>
                <h2>{currentStepMeta.title}</h2>
                <p>{currentStepMeta.description}</p>
              </div>
              <div className="report-builder__canvas-tags">
                <span>{reportTypeLabel}</span>
                <span>{dataSourceLabel}</span>
                <span>{chartTypeLabel}</span>
              </div>
            </div>

            {currentStep === 0 ? (
              <BasicsStep
                name={name}
                description={description}
                reportType={reportType}
                dataSource={dataSource}
                nameError={errors.name}
                onNameChange={setName}
                onDescriptionChange={setDescription}
                onReportTypeChange={setReportType}
                onDataSourceChange={handleDataSourceChange}
              />
            ) : null}

            {currentStep === 1 ? (
              <DataSelectionStep
                dimensionFields={dimensionFields}
                metricFields={metricFields}
                dimensions={dimensions}
                metrics={metrics}
                dimensionError={errors.dimensions}
                onDimensionChange={handleDimensionChange}
                onMetricChange={handleMetricChange}
                onMetricUpdate={handleMetricUpdate}
                onDateGranularityChange={handleDateGranularityChange}
              />
            ) : null}

            {currentStep === 2 ? (
              <FiltersStep
                defaultDateRange={defaultDateRange}
                dateField={dateField}
                dateFields={dateFields}
                filterableFields={filterableFields}
                filters={filters}
                onDateRangeChange={setDefaultDateRange}
                onDateFieldChange={setDateField}
                onAddFilter={handleAddFilter}
                onUpdateFilter={handleUpdateFilter}
                onRemoveFilter={handleRemoveFilter}
              />
            ) : null}

            {currentStep === 3 ? (
              <DisplayStep
                chartType={chartType}
                sortBy={sortBy}
                sortOrder={sortOrder}
                limit={limit}
                isPublic={isPublic}
                availableSortFields={sortableFields}
                onChartTypeChange={setChartType}
                onSortByChange={setSortBy}
                onSortOrderChange={setSortOrder}
                onLimitChange={setLimit}
                onIsPublicChange={setIsPublic}
              />
            ) : null}
          </Card>

          <Card className="report-builder__footer-card" padding="md">
            <div className="report-builder__footer-copy">
              <strong>{isEditing ? 'Editing existing report' : 'New report definition'}</strong>
              <span>{narrative}</span>
            </div>

            <div className="report-builder__footer-actions">
              {currentStep > 0 ? (
                <Button variant="ghost" onClick={() => setCurrentStep((previous) => previous - 1)}>
                  Previous
                </Button>
              ) : null}
              <Button variant="ghost" onClick={onCancel}>
                Cancel
              </Button>
              {currentStep < REPORT_BUILDER_STEPS.length - 1 ? (
                <Button variant="primary" onClick={handleNextStep}>
                  Continue
                </Button>
              ) : (
                <Button
                  variant="primary"
                  onClick={handleSave}
                  disabled={isSaving}
                  data-testid="report-builder-save"
                >
                  {isSaving ? 'Saving...' : isEditing ? 'Update report' : 'Create report'}
                </Button>
              )}
            </div>
          </Card>
        </div>

        <BuilderSummaryPanel
          reportName={name}
          reportTypeLabel={reportTypeLabel}
          dataSourceLabel={dataSourceLabel}
          stepLabel={currentStepMeta.label}
          dimensions={dimensions}
          metrics={metrics}
          filters={filters}
          dateRangeLabel={dateRangeLabel}
          chartTypeLabel={chartTypeLabel}
          issueCount={issueCount}
          narrative={narrative}
        />
      </div>
    </section>
  );
}

export default ReportBuilder;
