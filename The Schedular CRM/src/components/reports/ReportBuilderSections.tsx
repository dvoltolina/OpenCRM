import type {
  AggregationType,
  ChartType,
  DateRange,
  ReportDimension,
  ReportFilter,
  ReportFilterOperator,
  ReportMetric,
  ReportType,
} from '../../types/reporting';
import { Button, Card, EmptyState } from '../ui';
import type { DataSourceField } from './report-builder-config';
import {
  AGGREGATION_TYPES,
  CHART_TYPES,
  DATA_SOURCES,
  DATE_GRANULARITIES,
  DATE_RANGES,
  FILTER_OPERATORS,
  FORMAT_OPTIONS,
  REPORT_TYPES,
} from './report-builder-config';

function fieldTypeLabel(type: DataSourceField['type']) {
  switch (type) {
    case 'date':
      return 'Date';
    case 'number':
      return 'Metric';
    case 'boolean':
      return 'Flag';
    default:
      return 'Field';
  }
}

interface OptionGridProps<T extends string> {
  options: Array<{ value: T; label: string; description: string }>;
  selected: T;
  onSelect: (value: T) => void;
  className: string;
}

function OptionGrid<T extends string>({
  options,
  selected,
  onSelect,
  className,
}: OptionGridProps<T>) {
  return (
    <div className={className}>
      {options.map((option) => {
        const isSelected = option.value === selected;

        return (
          <button
            key={option.value}
            type="button"
            className={`report-builder__choice-card ${isSelected ? 'is-selected' : ''}`}
            onClick={() => onSelect(option.value)}
          >
            <span className="report-builder__choice-label">{option.label}</span>
            <span className="report-builder__choice-description">{option.description}</span>
          </button>
        );
      })}
    </div>
  );
}

interface FieldSelectorProps {
  label: string;
  description: string;
  selectedFields: string[];
  availableFields: DataSourceField[];
  onChange: (fields: string[]) => void;
}

function FieldSelector({
  label,
  description,
  selectedFields,
  availableFields,
  onChange,
}: FieldSelectorProps) {
  const handleToggle = (field: string) => {
    if (selectedFields.includes(field)) {
      onChange(selectedFields.filter((item) => item !== field));
      return;
    }

    onChange([...selectedFields, field]);
  };

  return (
    <div className="report-builder__section-block">
      <div className="report-builder__section-heading">
        <div>
          <h3>{label}</h3>
          <p>{description}</p>
        </div>
        <span className="report-builder__counter">
          {selectedFields.length} selected
        </span>
      </div>

      {availableFields.length === 0 ? (
        <EmptyState
          title={`No ${label.toLowerCase()} available`}
          description="Switch the data source or choose a dataset with fields that support this selection."
        />
      ) : (
        <div className="report-builder__field-grid">
          {availableFields.map((field) => {
            const isSelected = selectedFields.includes(field.field);

            return (
              <button
                key={field.field}
                type="button"
                className={`report-builder__field-card ${isSelected ? 'is-selected' : ''}`}
                onClick={() => handleToggle(field.field)}
              >
                <span className="report-builder__field-card-type">
                  {fieldTypeLabel(field.type)}
                </span>
                <span className="report-builder__field-card-label">{field.label}</span>
                <span className="report-builder__field-card-name">{field.field}</span>
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}

interface BasicsStepProps {
  name: string;
  description: string;
  reportType: ReportType;
  dataSource: string;
  nameError?: string;
  onNameChange: (value: string) => void;
  onDescriptionChange: (value: string) => void;
  onReportTypeChange: (value: ReportType) => void;
  onDataSourceChange: (value: string) => void;
}

export function BasicsStep({
  name,
  description,
  reportType,
  dataSource,
  nameError,
  onNameChange,
  onDescriptionChange,
  onReportTypeChange,
  onDataSourceChange,
}: BasicsStepProps) {
  return (
    <div className="report-builder__content-stack">
      <Card className="report-builder__panel" padding="lg">
        <div className="report-builder__form-grid report-builder__form-grid--wide">
          <label className="report-builder__input-group report-builder__input-group--full">
            <span>Report name</span>
            <input
              type="text"
              value={name}
              onChange={(event) => onNameChange(event.target.value)}
              placeholder="Monthly revenue by stage"
              className={nameError ? 'form-input--error' : ''}
            />
            {nameError ? <small className="form-error">{nameError}</small> : null}
          </label>

          <label className="report-builder__input-group report-builder__input-group--full">
            <span>Description</span>
            <textarea
              value={description}
              onChange={(event) => onDescriptionChange(event.target.value)}
              placeholder="Explain what this report measures and who should use it."
              rows={4}
            />
          </label>
        </div>
      </Card>

      <Card className="report-builder__panel" padding="lg">
        <div className="report-builder__section-heading">
          <div>
            <h3>Report intent</h3>
            <p>Choose the business lens this report should represent.</p>
          </div>
        </div>
        <OptionGrid
          className="report-builder__choice-grid"
          options={REPORT_TYPES}
          selected={reportType}
          onSelect={onReportTypeChange}
        />
      </Card>

      <Card className="report-builder__panel" padding="lg">
        <div className="report-builder__section-heading">
          <div>
            <h3>Data source</h3>
            <p>Pick the dataset that powers the report definition.</p>
          </div>
        </div>
        <OptionGrid
          className="report-builder__choice-grid report-builder__choice-grid--compact"
          options={DATA_SOURCES}
          selected={dataSource}
          onSelect={onDataSourceChange}
        />
      </Card>
    </div>
  );
}

interface DataSelectionStepProps {
  dimensionFields: DataSourceField[];
  metricFields: DataSourceField[];
  dimensions: ReportDimension[];
  metrics: ReportMetric[];
  dimensionError?: string;
  onDimensionChange: (fields: string[]) => void;
  onMetricChange: (fields: string[]) => void;
  onMetricUpdate: (
    index: number,
    updates: Partial<{
      aggregation: AggregationType;
      format: 'number' | 'currency' | 'percent';
    }>
  ) => void;
  onDateGranularityChange: (
    value: 'day' | 'week' | 'month' | 'quarter' | 'year'
  ) => void;
}

export function DataSelectionStep({
  dimensionFields,
  metricFields,
  dimensions,
  metrics,
  dimensionError,
  onDimensionChange,
  onMetricChange,
  onMetricUpdate,
  onDateGranularityChange,
}: DataSelectionStepProps) {
  const selectedDateDimension = dimensions.find((dimension) => dimension.type === 'date');

  return (
    <div className="report-builder__content-stack">
      <Card className="report-builder__panel" padding="lg">
        <FieldSelector
          label="Dimensions"
          description="Group results by names, dates, owners, or statuses."
          selectedFields={dimensions.map((dimension) => dimension.field)}
          availableFields={dimensionFields}
          onChange={onDimensionChange}
        />

        {selectedDateDimension ? (
          <div className="report-builder__pill-group">
            {DATE_GRANULARITIES.map((granularity) => (
              <button
                key={granularity.value}
                type="button"
                className={`report-builder__pill ${
                  selectedDateDimension.dateGranularity === granularity.value ? 'is-selected' : ''
                }`}
                onClick={() => onDateGranularityChange(granularity.value)}
              >
                {granularity.label}
              </button>
            ))}
          </div>
        ) : null}

        {dimensionError ? <p className="form-error">{dimensionError}</p> : null}
      </Card>

      <Card className="report-builder__panel" padding="lg">
        <FieldSelector
          label="Metrics"
          description="Choose the measurements that should be aggregated in the output."
          selectedFields={metrics.map((metric) => metric.field)}
          availableFields={metricFields}
          onChange={onMetricChange}
        />

        {metrics.length > 0 ? (
          <div className="report-builder__metric-list">
            {metrics.map((metric, index) => (
              <div key={metric.field} className="report-builder__metric-card">
                <div className="report-builder__metric-copy">
                  <strong>{metric.label}</strong>
                  <span>{metric.field}</span>
                </div>
                <div className="report-builder__metric-controls">
                  <select
                    value={metric.aggregation}
                    onChange={(event) =>
                      onMetricUpdate(index, {
                        aggregation: event.target.value as AggregationType,
                      })
                    }
                  >
                    {AGGREGATION_TYPES.map((option) => (
                      <option key={option.value} value={option.value}>
                        {option.label}
                      </option>
                    ))}
                  </select>
                  <select
                    value={metric.format || 'number'}
                    onChange={(event) =>
                      onMetricUpdate(index, {
                        format: event.target.value as 'number' | 'currency' | 'percent',
                      })
                    }
                  >
                    {FORMAT_OPTIONS.map((option) => (
                      <option key={option.value} value={option.value}>
                        {option.label}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            ))}
          </div>
        ) : null}
      </Card>
    </div>
  );
}

interface FiltersStepProps {
  defaultDateRange: DateRange;
  dateField: string;
  dateFields: DataSourceField[];
  filterableFields: DataSourceField[];
  filters: ReportFilter[];
  onDateRangeChange: (value: DateRange) => void;
  onDateFieldChange: (value: string) => void;
  onAddFilter: () => void;
  onUpdateFilter: (index: number, updates: Partial<ReportFilter>) => void;
  onRemoveFilter: (index: number) => void;
}

export function FiltersStep({
  defaultDateRange,
  dateField,
  dateFields,
  filterableFields,
  filters,
  onDateRangeChange,
  onDateFieldChange,
  onAddFilter,
  onUpdateFilter,
  onRemoveFilter,
}: FiltersStepProps) {
  return (
    <div className="report-builder__content-stack">
      <Card className="report-builder__panel" padding="lg">
        <div className="report-builder__form-grid">
          <label className="report-builder__input-group">
            <span>Default date range</span>
            <select
              value={defaultDateRange}
              onChange={(event) => onDateRangeChange(event.target.value as DateRange)}
            >
              {DATE_RANGES.map((range) => (
                <option key={range.value} value={range.value}>
                  {range.label}
                </option>
              ))}
            </select>
          </label>

          <label className="report-builder__input-group">
            <span>Date field</span>
            <select
              value={dateField}
              onChange={(event) => onDateFieldChange(event.target.value)}
              disabled={dateFields.length === 0}
            >
              {dateFields.length === 0 ? (
                <option value="">No date fields available</option>
              ) : (
                dateFields.map((field) => (
                  <option key={field.field} value={field.field}>
                    {field.label}
                  </option>
                ))
              )}
            </select>
          </label>
        </div>
      </Card>

      <Card className="report-builder__panel" padding="lg">
        <div className="report-builder__section-heading">
          <div>
            <h3>Additional filters</h3>
            <p>Apply sanitized field constraints to narrow aggregate output.</p>
          </div>
          <Button variant="secondary" size="sm" onClick={onAddFilter}>
            Add filter
          </Button>
        </div>

        {filters.length === 0 ? (
          <EmptyState
            title="No filters added"
            description="The report will use the default date range and all matching rows in scope."
          />
        ) : (
          <div className="report-builder__filter-list">
            {filters.map((filter, index) => (
              <div key={`${filter.field}-${index}`} className="report-builder__filter-card">
                <select
                  value={filter.field}
                  onChange={(event) => onUpdateFilter(index, { field: event.target.value })}
                >
                  {filterableFields.map((field) => (
                    <option key={field.field} value={field.field}>
                      {field.label}
                    </option>
                  ))}
                </select>

                <select
                  value={filter.operator}
                  onChange={(event) =>
                    onUpdateFilter(index, {
                      operator: event.target.value as ReportFilterOperator,
                    })
                  }
                >
                  {FILTER_OPERATORS.map((operator) => (
                    <option key={operator.value} value={operator.value}>
                      {operator.label}
                    </option>
                  ))}
                </select>

                <input
                  type="text"
                  value={String(filter.value)}
                  onChange={(event) => onUpdateFilter(index, { value: event.target.value })}
                  placeholder="Value"
                />

                <Button variant="ghost" size="sm" onClick={() => onRemoveFilter(index)}>
                  Remove
                </Button>
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}

interface DisplayStepProps {
  chartType: ChartType;
  sortBy: string;
  sortOrder: 'asc' | 'desc';
  limit: number;
  isPublic: boolean;
  availableSortFields: Array<{ field: string; label: string }>;
  onChartTypeChange: (value: ChartType) => void;
  onSortByChange: (value: string) => void;
  onSortOrderChange: (value: 'asc' | 'desc') => void;
  onLimitChange: (value: number) => void;
  onIsPublicChange: (value: boolean) => void;
}

export function DisplayStep({
  chartType,
  sortBy,
  sortOrder,
  limit,
  isPublic,
  availableSortFields,
  onChartTypeChange,
  onSortByChange,
  onSortOrderChange,
  onLimitChange,
  onIsPublicChange,
}: DisplayStepProps) {
  return (
    <div className="report-builder__content-stack">
      <Card className="report-builder__panel" padding="lg">
        <div className="report-builder__section-heading">
          <div>
            <h3>Chart treatment</h3>
            <p>Select the output format that best fits the structure of the report.</p>
          </div>
        </div>
        <div className="report-builder__chart-grid">
          {CHART_TYPES.map((chart) => (
            <button
              key={chart.value}
              type="button"
              className={`report-builder__chart-card ${chartType === chart.value ? 'is-selected' : ''}`}
              onClick={() => onChartTypeChange(chart.value)}
            >
              <span className={`report-builder__chart-glyph report-builder__chart-glyph--${chart.value}`} />
              <span className="report-builder__chart-copy">
                <strong>{chart.label}</strong>
                <span>{chart.description}</span>
              </span>
            </button>
          ))}
        </div>
      </Card>

      <Card className="report-builder__panel" padding="lg">
        <div className="report-builder__form-grid">
          <label className="report-builder__input-group">
            <span>Sort by</span>
            <select value={sortBy} onChange={(event) => onSortByChange(event.target.value)}>
              <option value="">Default order</option>
              {availableSortFields.map((field) => (
                <option key={field.field} value={field.field}>
                  {field.label}
                </option>
              ))}
            </select>
          </label>

          <label className="report-builder__input-group">
            <span>Sort direction</span>
            <select
              value={sortOrder}
              onChange={(event) => onSortOrderChange(event.target.value as 'asc' | 'desc')}
            >
              <option value="asc">Ascending</option>
              <option value="desc">Descending</option>
            </select>
          </label>

          <label className="report-builder__input-group">
            <span>Row limit</span>
            <input
              type="number"
              min={1}
              max={10000}
              value={limit}
              onChange={(event) => onLimitChange(Number(event.target.value) || 100)}
            />
          </label>
        </div>

        <label className="report-builder__checkbox-row">
          <input
            type="checkbox"
            checked={isPublic}
            onChange={(event) => onIsPublicChange(event.target.checked)}
          />
          <span>Visible to everyone in the workspace</span>
        </label>
      </Card>
    </div>
  );
}
