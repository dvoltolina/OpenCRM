import type { ValidationError } from '../../services/csv-import-service';
import './import.css';

interface ValidationErrorsProps {
  errors: ValidationError[];
  maxDisplay?: number;
}

export function ValidationErrors({ errors, maxDisplay = 50 }: ValidationErrorsProps) {
  if (errors.length === 0) {
    return null;
  }

  const hasMore = errors.length > maxDisplay;

  // Group errors by row
  const errorsByRow = new Map<number, ValidationError[]>();
  errors.forEach(error => {
    if (!errorsByRow.has(error.row)) {
      errorsByRow.set(error.row, []);
    }
    errorsByRow.get(error.row)!.push(error);
  });

  return (
    <div className="validation-errors">
      <div className="validation-errors-header">
        <h4>Validation Errors ({errors.length})</h4>
        <p className="text-muted">
          The following rows have validation errors and will be skipped during import:
        </p>
      </div>

      <div className="validation-errors-list">
        {Array.from(errorsByRow.entries())
          .slice(0, maxDisplay)
          .map(([row, rowErrors]) => (
            <div key={row} className="validation-error-item">
              <div className="error-row-number">
                Row {row}
              </div>
              <div className="error-messages">
                <ul>
                  {rowErrors.map((error, index) => (
                    <li key={index}>
                      <strong>{error.field}:</strong> {error.error}
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          ))}
      </div>

      {hasMore && (
        <div className="validation-errors-footer">
          Showing first {maxDisplay} of {errors.length} errors.
          Fix the errors in your CSV file and re-upload to see all issues.
        </div>
      )}
    </div>
  );
}
