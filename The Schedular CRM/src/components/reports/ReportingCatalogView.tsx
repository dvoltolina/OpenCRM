import type { ReportDefinition, ReportType } from '../../types/reporting';
import { Button, Card, EmptyState, Toolbar } from '../ui';
import { REPORT_CATEGORIES, getReportCategory } from '../../pages/reporting-page-config';

interface ReportingCatalogViewProps {
  searchQuery: string;
  selectedCategory: ReportType | 'all';
  systemReports: ReportDefinition[];
  customReports: ReportDefinition[];
  totalReports: number;
  onSearchQueryChange: (value: string) => void;
  onSelectedCategoryChange: (value: ReportType | 'all') => void;
  onSelectReport: (report: ReportDefinition) => void;
  onDeleteReport: (report: ReportDefinition) => void;
  onCreateReport: () => void;
}

interface ReportCardProps {
  report: ReportDefinition;
  onOpen: (report: ReportDefinition) => void;
  onDelete?: (report: ReportDefinition) => void;
}

function ReportCard({ report, onOpen, onDelete }: ReportCardProps) {
  const category = getReportCategory(report.reportType);

  return (
    <article className="reporting-page__report-card">
      <div className="reporting-page__report-header">
        <div>
          <p className="reporting-page__report-overline">{category?.label || report.reportType}</p>
          <h3>{report.name}</h3>
        </div>
        <span className={`reporting-page__report-badge ${report.isSystemReport ? 'is-system' : 'is-custom'}`}>
          {report.isSystemReport ? 'System' : 'Custom'}
        </span>
      </div>

      <p className="reporting-page__report-description">
        {report.description || 'No description added yet.'}
      </p>

      <div className="reporting-page__report-meta">
        <span>{report.chartType}</span>
        <span>{report.dimensions.length} dimensions</span>
        <span>{report.metrics.length} metrics</span>
        {report.ownerName ? <span>{report.ownerName}</span> : null}
      </div>

      <div className="reporting-page__report-actions">
        <Button variant="primary" size="sm" onClick={() => onOpen(report)}>
          Open report
        </Button>
        {onDelete ? (
          <Button variant="ghost" size="sm" onClick={() => onDelete(report)}>
            Delete
          </Button>
        ) : null}
      </div>
    </article>
  );
}

export function ReportingCatalogView({
  searchQuery,
  selectedCategory,
  systemReports,
  customReports,
  totalReports,
  onSearchQueryChange,
  onSelectedCategoryChange,
  onSelectReport,
  onDeleteReport,
  onCreateReport,
}: ReportingCatalogViewProps) {
  const filteredCount = systemReports.length + customReports.length;
  const resultsLabel =
    filteredCount === totalReports
      ? `${totalReports} total reports`
      : `${filteredCount} of ${totalReports} reports`;

  return (
    <div className="reporting-page__catalog">
      <Card className="reporting-page__overview" padding="lg" tone="accent">
        <div className="reporting-page__overview-copy">
          <p className="ui-empty-state__eyebrow">Builder Workspace</p>
          <h2>Reusable report definitions for exports and schedules</h2>
          <p>
            Use this surface to maintain report definitions. The operational KPI dashboard stays
            on <code>/reports</code>; this route owns creation, editing, exports, and scheduling.
          </p>
        </div>
        <div className="reporting-page__overview-stats">
          <div>
            <span>System</span>
            <strong>{systemReports.length}</strong>
          </div>
          <div>
            <span>Custom</span>
            <strong>{customReports.length}</strong>
          </div>
          <div>
            <span>Visible now</span>
            <strong>{filteredCount}</strong>
          </div>
        </div>
      </Card>

      <Card className="reporting-page__filters-card" padding="md">
        <Toolbar
          start={(
            <>
              <input
                type="search"
                className="reporting-page__search"
                placeholder="Search report definitions"
                value={searchQuery}
                onChange={(event) => onSearchQueryChange(event.target.value)}
              />
              <span className="ui-results-count">{resultsLabel}</span>
            </>
          )}
        />

        <div className="reporting-page__category-row">
          <button
            type="button"
            className={`reporting-page__category-pill ${selectedCategory === 'all' ? 'is-active' : ''}`}
            onClick={() => onSelectedCategoryChange('all')}
          >
            All reports
          </button>
          {REPORT_CATEGORIES.map((category) => (
            <button
              key={category.type}
              type="button"
              className={`reporting-page__category-pill ${selectedCategory === category.type ? 'is-active' : ''}`}
              onClick={() => onSelectedCategoryChange(category.type)}
              title={category.description}
            >
              {category.label}
            </button>
          ))}
        </div>
      </Card>

      {systemReports.length > 0 ? (
        <section className="reporting-page__section">
          <div className="reporting-page__section-header">
            <div>
              <h2>System reports</h2>
              <p>Seeded definitions for common sales and service-business reporting patterns.</p>
            </div>
          </div>
          <div className="reporting-page__report-grid">
            {systemReports.map((report) => (
              <ReportCard key={report.id} report={report} onOpen={onSelectReport} />
            ))}
          </div>
        </section>
      ) : null}

      {customReports.length > 0 ? (
        <section className="reporting-page__section">
          <div className="reporting-page__section-header">
            <div>
              <h2>Custom reports</h2>
              <p>Editable definitions owned by users or shared across the workspace.</p>
            </div>
          </div>
          <div className="reporting-page__report-grid">
            {customReports.map((report) => (
              <ReportCard
                key={report.id}
                report={report}
                onOpen={onSelectReport}
                onDelete={onDeleteReport}
              />
            ))}
          </div>
        </section>
      ) : null}

      {filteredCount === 0 ? (
        <Card padding="lg">
          <EmptyState
            eyebrow="No Reports"
            title={searchQuery || selectedCategory !== 'all' ? 'No reports match the current filters' : 'No reports available yet'}
            description={
              searchQuery || selectedCategory !== 'all'
                ? 'Clear the search or category filters to see more report definitions.'
                : 'Create a report definition to start scheduling exports or opening custom chart views.'
            }
            actions={(
              <>
                {searchQuery || selectedCategory !== 'all' ? (
                  <Button
                    variant="secondary"
                    onClick={() => {
                      onSearchQueryChange('');
                      onSelectedCategoryChange('all');
                    }}
                  >
                    Clear filters
                  </Button>
                ) : null}
                <Button variant="primary" onClick={onCreateReport}>
                  Create report
                </Button>
              </>
            )}
          />
        </Card>
      ) : null}
    </div>
  );
}

export default ReportingCatalogView;
