import type { ImportResult } from '../../services/csv-import-service';
import './import.css';

export interface MultiEntitySummary {
  companies?: { created: number; updated: number; skipped: number };
  contacts?: { created: number; updated: number; skipped: number };
  leads?: { created: number; updated: number; skipped: number };
  deals?: { created: number; updated: number; skipped: number };
}

interface ImportProgressProps {
  progress: { current: number; total: number } | null;
  result: ImportResult | null;
  isComplete: boolean;
  error: string | null;
  multiEntitySummary?: MultiEntitySummary | null;
}

export function ImportProgress({
  progress,
  result,
  isComplete,
  error,
  multiEntitySummary
}: ImportProgressProps) {
  const errorList = result?.errors || [];
  const errorCount = errorList.length;
  const formatRowLabel = (row?: number) => {
    if (typeof row === 'number' && !Number.isNaN(row)) {
      return `Row ${row}`;
    }
    return 'Error';
  };

  const getProgressPercentage = () => {
    if (!progress || progress.total === 0) return 0;
    return Math.round((progress.current / progress.total) * 100);
  };

  const percentage = getProgressPercentage();

  if (error) {
    return (
      <div className="import-progress">
        <div className="progress-header">
          <h3>Import Failed</h3>
        </div>

        <div className="alert alert-error">
          <strong>Error:</strong> {error}
        </div>

        {errorList.length > 0 && (
          <div className="error-log">
            <h4>Error Details</h4>
            <div className="error-log-list">
              {errorList.map((err, index) => (
                <div key={index} className="error-log-item">
                  <span className="error-row">{formatRowLabel(err.row)}:</span>
                  <span className="error-message">{err.error}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="progress-actions">
          <button className="btn btn-secondary" onClick={() => window.location.reload()}>
            Try Again
          </button>
        </div>
      </div>
    );
  }

  if (isComplete && result) {
    const hasMultiEntitySummary = multiEntitySummary && Object.keys(multiEntitySummary).length > 0;

    return (
      <div className="import-progress">
        <div className="progress-header">
          <h3>Import Complete</h3>
        </div>

        <div className="import-results">
          <div className="result-summary">
            <div className="result-stat result-stat-total">
              <div className="stat-value">{result.totalRows}</div>
              <div className="stat-label">Total Rows</div>
            </div>
            <div className="result-stat result-stat-success">
              <div className="stat-value">{result.imported}</div>
              <div className="stat-label">Imported</div>
            </div>
            <div className="result-stat result-stat-skipped">
              <div className="stat-value">{result.skipped}</div>
              <div className="stat-label">Skipped</div>
            </div>
            <div className="result-stat result-stat-error">
              <div className="stat-value">{errorCount}</div>
              <div className="stat-label">Errors</div>
            </div>
          </div>

          {hasMultiEntitySummary && (
            <div className="multi-entity-summary">
              <h4>Entities Created/Updated</h4>
              <div className="entity-summary-grid">
                {multiEntitySummary.companies && (
                  <div className="entity-summary-card">
                    <div className="entity-summary-header">Companies</div>
                    <div className="entity-summary-stats">
                      <div className="entity-stat">
                        <span className="stat-label">Created:</span>
                        <span className="stat-value stat-success">{multiEntitySummary.companies.created}</span>
                      </div>
                      <div className="entity-stat">
                        <span className="stat-label">Updated:</span>
                        <span className="stat-value stat-info">{multiEntitySummary.companies.updated}</span>
                      </div>
                      <div className="entity-stat">
                        <span className="stat-label">Skipped:</span>
                        <span className="stat-value stat-muted">{multiEntitySummary.companies.skipped}</span>
                      </div>
                    </div>
                  </div>
                )}
                {multiEntitySummary.contacts && (
                  <div className="entity-summary-card">
                    <div className="entity-summary-header">Contacts</div>
                    <div className="entity-summary-stats">
                      <div className="entity-stat">
                        <span className="stat-label">Created:</span>
                        <span className="stat-value stat-success">{multiEntitySummary.contacts.created}</span>
                      </div>
                      <div className="entity-stat">
                        <span className="stat-label">Updated:</span>
                        <span className="stat-value stat-info">{multiEntitySummary.contacts.updated}</span>
                      </div>
                      <div className="entity-stat">
                        <span className="stat-label">Skipped:</span>
                        <span className="stat-value stat-muted">{multiEntitySummary.contacts.skipped}</span>
                      </div>
                    </div>
                  </div>
                )}
                {multiEntitySummary.leads && (
                  <div className="entity-summary-card">
                    <div className="entity-summary-header">Leads</div>
                    <div className="entity-summary-stats">
                      <div className="entity-stat">
                        <span className="stat-label">Created:</span>
                        <span className="stat-value stat-success">{multiEntitySummary.leads.created}</span>
                      </div>
                      <div className="entity-stat">
                        <span className="stat-label">Updated:</span>
                        <span className="stat-value stat-info">{multiEntitySummary.leads.updated}</span>
                      </div>
                      <div className="entity-stat">
                        <span className="stat-label">Skipped:</span>
                        <span className="stat-value stat-muted">{multiEntitySummary.leads.skipped}</span>
                      </div>
                    </div>
                  </div>
                )}
                {multiEntitySummary.deals && (
                  <div className="entity-summary-card">
                    <div className="entity-summary-header">Deals</div>
                    <div className="entity-summary-stats">
                      <div className="entity-stat">
                        <span className="stat-label">Created:</span>
                        <span className="stat-value stat-success">{multiEntitySummary.deals.created}</span>
                      </div>
                      <div className="entity-stat">
                        <span className="stat-label">Updated:</span>
                        <span className="stat-value stat-info">{multiEntitySummary.deals.updated}</span>
                      </div>
                      <div className="entity-stat">
                        <span className="stat-label">Skipped:</span>
                        <span className="stat-value stat-muted">{multiEntitySummary.deals.skipped}</span>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}

          {result.dryRun && (
            <div className="alert alert-info">
              Dry run completed. No records were imported.
            </div>
          )}

          {result.imported > 0 && (
            <div className="alert alert-success">
              Successfully imported {result.imported} record(s)!
            </div>
          )}

          {errorCount > 0 && (
            <div className="error-log">
              <h4>Error Log</h4>
              <div className="error-log-list">
                {errorList.map((err, index) => (
                  <div key={index} className="error-log-item">
                        <span className="error-row">{formatRowLabel(err.row)}:</span>
                        <span className="error-message">{err.error}</span>
                      </div>
                    ))}
                  </div>
            </div>
          )}

          {result.skipped > 0 && errorCount === 0 && (
            <div className="alert alert-info">
              {result.skipped} row(s) were skipped (duplicates or empty rows)
            </div>
          )}
        </div>
      </div>
    );
  }

  // In progress
  return (
    <div className="import-progress">
      <div className="progress-header">
        <h3>Importing Data...</h3>
        <div className="progress-stats">
          {progress && (
            <span>
              Processing row {progress.current} of {progress.total}
            </span>
          )}
        </div>
      </div>

      <div className="progress-bar-container">
        <div className="progress-bar-bg">
          <div
            className="progress-bar-fill"
            style={{ width: `${percentage}%` }}
          />
        </div>
        <div className="progress-percentage">{percentage}%</div>
      </div>

      <div className="progress-info">
        <p>Please wait while we import your data. This may take a few moments...</p>
        <p className="text-muted">Do not close this window.</p>
      </div>

      <div className="progress-animation">
        <div className="spinner" />
      </div>
    </div>
  );
}
