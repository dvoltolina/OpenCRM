/**
 * Boundary Editor Component
 * Edit territory boundaries (zip codes or radius)
 */

import { useState, useCallback } from 'react';
import type { TerritoryBoundary } from '../../types/models';

interface BoundaryEditorProps {
  boundary: TerritoryBoundary;
  onChange: (boundary: TerritoryBoundary) => void;
  disabled?: boolean;
}

export function BoundaryEditor({ boundary, onChange, disabled = false }: BoundaryEditorProps) {
  const [newZipCode, setNewZipCode] = useState('');
  const [zipError, setZipError] = useState<string | null>(null);

  const handleTypeChange = useCallback(
    (type: TerritoryBoundary['type']) => {
      if (type === 'zip_codes') {
        onChange({ type: 'zip_codes', zipCodes: boundary.zipCodes ?? [] });
      } else if (type === 'radius') {
        onChange({
          type: 'radius',
          centerLatitude: boundary.centerLatitude ?? 0,
          centerLongitude: boundary.centerLongitude ?? 0,
          radiusKm: boundary.radiusKm ?? 10,
        });
      } else if (type === 'polygon') {
        onChange({
          type: 'polygon',
          polygonCoordinates: boundary.polygonCoordinates ?? [],
        });
      }
    },
    [boundary, onChange]
  );

  const validateZipCode = (zip: string): boolean => {
    // US zip code: 5 digits or 5+4 format
    return /^\d{5}(-\d{4})?$/.test(zip);
  };

  const addZipCode = useCallback(() => {
    const zip = newZipCode.trim();
    if (!zip) return;

    if (!validateZipCode(zip)) {
      setZipError('Enter a valid 5-digit zip code');
      return;
    }

    if (boundary.zipCodes?.includes(zip)) {
      setZipError('Zip code already added');
      return;
    }

    setZipError(null);
    onChange({
      ...boundary,
      type: 'zip_codes',
      zipCodes: [...(boundary.zipCodes ?? []), zip],
    });
    setNewZipCode('');
  }, [newZipCode, boundary, onChange]);

  const removeZipCode = useCallback(
    (zip: string) => {
      onChange({
        ...boundary,
        type: 'zip_codes',
        zipCodes: (boundary.zipCodes ?? []).filter((z) => z !== zip),
      });
    },
    [boundary, onChange]
  );

  const handleZipKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        addZipCode();
      }
    },
    [addZipCode]
  );

  const handleBulkZipAdd = useCallback(() => {
    const input = prompt(
      'Enter zip codes separated by commas, spaces, or new lines:'
    );
    if (!input) return;

    const zips = input
      .split(/[\s,\n]+/)
      .map((z) => z.trim())
      .filter((z) => validateZipCode(z));

    const existingZips = new Set(boundary.zipCodes ?? []);
    const newZips = zips.filter((z) => !existingZips.has(z));

    if (newZips.length > 0) {
      onChange({
        ...boundary,
        type: 'zip_codes',
        zipCodes: [...(boundary.zipCodes ?? []), ...newZips],
      });
    }
  }, [boundary, onChange]);

  return (
    <div className="boundary-editor">
      <div className="boundary-editor__type-selector">
        <label>Boundary Type</label>
        <div className="boundary-type-buttons">
          <button
            type="button"
            className={`boundary-type-btn ${boundary.type === 'zip_codes' ? 'boundary-type-btn--active' : ''}`}
            onClick={() => handleTypeChange('zip_codes')}
            disabled={disabled}
          >
            Zip Codes
          </button>
          <button
            type="button"
            className={`boundary-type-btn ${boundary.type === 'radius' ? 'boundary-type-btn--active' : ''}`}
            onClick={() => handleTypeChange('radius')}
            disabled={disabled}
          >
            Radius
          </button>
          <button
            type="button"
            className={`boundary-type-btn ${boundary.type === 'polygon' ? 'boundary-type-btn--active' : ''}`}
            onClick={() => handleTypeChange('polygon')}
            disabled={disabled}
            title="Draw polygon on map (coming soon)"
          >
            Polygon
          </button>
        </div>
      </div>

      {boundary.type === 'zip_codes' && (
        <div className="boundary-zip-editor">
          <div className="zip-input-row">
            <input
              type="text"
              value={newZipCode}
              onChange={(e) => {
                setNewZipCode(e.target.value);
                setZipError(null);
              }}
              onKeyDown={handleZipKeyDown}
              placeholder="Enter zip code"
              maxLength={10}
              disabled={disabled}
              className="zip-input"
            />
            <button
              type="button"
              className="btn btn-sm btn-primary"
              onClick={addZipCode}
              disabled={disabled || !newZipCode.trim()}
            >
              Add
            </button>
            <button
              type="button"
              className="btn btn-sm btn-ghost"
              onClick={handleBulkZipAdd}
              disabled={disabled}
              title="Add multiple zip codes at once"
            >
              Bulk Add
            </button>
          </div>

          {zipError && <div className="zip-error">{zipError}</div>}

          <div className="zip-codes-list">
            {(boundary.zipCodes ?? []).length === 0 ? (
              <div className="zip-codes-empty">No zip codes added yet</div>
            ) : (
              (boundary.zipCodes ?? []).map((zip) => (
                <span key={zip} className="zip-code-tag">
                  {zip}
                  <button
                    type="button"
                    className="zip-code-remove"
                    onClick={() => removeZipCode(zip)}
                    disabled={disabled}
                  >
                    &times;
                  </button>
                </span>
              ))
            )}
          </div>

          {(boundary.zipCodes ?? []).length > 0 && (
            <div className="zip-count">
              {boundary.zipCodes?.length} zip code{boundary.zipCodes?.length !== 1 ? 's' : ''}
            </div>
          )}
        </div>
      )}

      {boundary.type === 'radius' && (
        <div className="boundary-radius-editor">
          <div className="radius-fields">
            <div className="form-group">
              <label>Center Latitude</label>
              <input
                type="number"
                step="0.0001"
                value={boundary.centerLatitude ?? ''}
                onChange={(e) =>
                  onChange({
                    ...boundary,
                    centerLatitude: parseFloat(e.target.value) || 0,
                  })
                }
                placeholder="e.g., 40.7128"
                disabled={disabled}
              />
            </div>
            <div className="form-group">
              <label>Center Longitude</label>
              <input
                type="number"
                step="0.0001"
                value={boundary.centerLongitude ?? ''}
                onChange={(e) =>
                  onChange({
                    ...boundary,
                    centerLongitude: parseFloat(e.target.value) || 0,
                  })
                }
                placeholder="e.g., -74.0060"
                disabled={disabled}
              />
            </div>
            <div className="form-group">
              <label>Radius (km)</label>
              <input
                type="number"
                min="1"
                max="500"
                value={boundary.radiusKm ?? ''}
                onChange={(e) =>
                  onChange({
                    ...boundary,
                    radiusKm: parseFloat(e.target.value) || 10,
                  })
                }
                placeholder="e.g., 25"
                disabled={disabled}
              />
            </div>
          </div>
          <p className="boundary-hint">
            Tip: You can get coordinates from Google Maps by right-clicking a location.
          </p>
        </div>
      )}

      {boundary.type === 'polygon' && (
        <div className="boundary-polygon-editor">
          <p className="boundary-hint">
            Polygon drawing coming soon. For now, use zip codes or radius boundaries.
          </p>
          {boundary.polygonCoordinates && boundary.polygonCoordinates.length > 0 && (
            <div className="polygon-info">
              {boundary.polygonCoordinates.length} points defined
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export default BoundaryEditor;
