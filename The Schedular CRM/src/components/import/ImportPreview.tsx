import React, { useMemo } from 'react';
import type { ValidationError } from '../../services/csv-import-service';
import './import.css';

interface ImportPreviewProps {
  headers: string[];
  rows: string[][];
  fieldMapping: Record<string, string>;
  validationErrors: ValidationError[];
  maxRows?: number;
}

export function ImportPreview({
  headers,
  rows,
  fieldMapping,
  validationErrors,
  maxRows = 10
}: ImportPreviewProps) {
  // Create error lookup map for quick access
  const errorsByRow = useMemo(() => {
    const map = new Map<number, ValidationError[]>();
    validationErrors.forEach(error => {
      if (!map.has(error.row)) {
        map.set(error.row, []);
      }
      map.get(error.row)!.push(error);
    });
    return map;
  }, [validationErrors]);

  // Filter to mapped columns only
  const mappedHeaders = headers.filter(h => fieldMapping[h]);
  const previewRows = rows.slice(0, maxRows);

  // Count valid and invalid rows
  const validRowsCount = rows.length - errorsByRow.size;
  const invalidRowsCount = errorsByRow.size;

  const getRowErrors = (rowIndex: number) => {
    return errorsByRow.get(rowIndex + 1) || []; // +1 because row numbers are 1-based
  };

  const hasRowError = (rowIndex: number) => {
    return errorsByRow.has(rowIndex + 1);
  };

  const getCellValue = (row: string[], headerIndex: number) => {
    const value = row[headerIndex] || '';
    return value.trim() === '' ? <em className="empty-cell">empty</em> : value;
  };

  return (
    <div className="import-preview">
      <div className="import-preview-header">
        <h3>Preview Data</h3>
        <div className="preview-stats">
          <div className="stat stat-success">
            <strong>{validRowsCount}</strong> valid rows
          </div>
          {invalidRowsCount > 0 && (
            <div className="stat stat-error">
              <strong>{invalidRowsCount}</strong> invalid rows
            </div>
          )}
          <div className="stat">
            <strong>{rows.length}</strong> total rows
          </div>
        </div>
      </div>

      {invalidRowsCount > 0 && (
        <div className="alert alert-error">
          <strong>Validation errors found!</strong> {invalidRowsCount} row(s) have errors and will be skipped during import.
          <br />
          You can choose to import only valid rows or fix the errors in your CSV and re-upload.
        </div>
      )}

      <div className="preview-table-wrapper">
        <table className="preview-table">
          <thead>
            <tr>
              <th className="row-number-header">Row</th>
              {mappedHeaders.map((header, index) => (
                <th key={index}>
                  <div className="header-cell">
                    <div className="csv-header">{header}</div>
                    <div className="mapped-field">{fieldMapping[header]}</div>
                  </div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {previewRows.map((row, rowIndex) => {
              const errors = getRowErrors(rowIndex);
              const hasError = hasRowError(rowIndex);

              return (
                <React.Fragment key={rowIndex}>
                  <tr className={hasError ? 'row-error' : ''}>
                    <td className="row-number">
                      {rowIndex + 1}
                      {hasError && (
                        <span className="error-indicator" title="This row has errors">!</span>
                      )}
                    </td>
                    {mappedHeaders.map((header, colIndex) => {
                      const headerIndex = headers.indexOf(header);
                      const field = fieldMapping[header];
                      const fieldHasError = errors.some(e => e.field === field);

                      return (
                        <td
                          key={colIndex}
                          className={fieldHasError ? 'cell-error' : ''}
                        >
                          {getCellValue(row, headerIndex)}
                        </td>
                      );
                    })}
                  </tr>
                  {hasError && (
                    <tr className="error-details-row">
                      <td colSpan={mappedHeaders.length + 1}>
                        <div className="error-details">
                          <strong>Errors:</strong>
                          <ul>
                            {errors.map((error, i) => (
                              <li key={i}>
                                <strong>{error.field}:</strong> {error.error}
                              </li>
                            ))}
                          </ul>
                        </div>
                      </td>
                    </tr>
                  )}
                </React.Fragment>
              );
            })}
          </tbody>
        </table>
      </div>

      {rows.length > maxRows && (
        <div className="preview-footer">
          Showing first {maxRows} of {rows.length} rows
        </div>
      )}

      <div className="preview-actions-info">
        <div className="info-box">
          <h4>Import Options</h4>
          <ul>
            <li><strong>Import All:</strong> Attempt to import all rows (invalid rows will be skipped)</li>
            <li><strong>Import Valid Only:</strong> Import only rows without validation errors</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
