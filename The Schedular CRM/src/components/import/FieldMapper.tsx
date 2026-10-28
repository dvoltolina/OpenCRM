import { AVAILABLE_FIELDS, autoDetectMappingWithConfidence } from '../../services/csv-import-service';
import './import.css';

interface FieldMapperProps {
  csvHeaders: string[];
  entityType: 'lead' | 'contact' | 'deal' | 'company' | 'client' | 'appointment';
  fieldMapping: Record<string, string>;
  onMappingChange: (mapping: Record<string, string>) => void;
}

export function FieldMapper({
  csvHeaders,
  entityType,
  fieldMapping,
  onMappingChange
}: FieldMapperProps) {
  const availableFields = AVAILABLE_FIELDS[entityType] || [];

  const handleFieldChange = (csvColumn: string, field: string) => {
    const newMapping = { ...fieldMapping };

    if (field === '') {
      // Remove mapping if empty value selected
      delete newMapping[csvColumn];
    } else {
      // Check if this field is already mapped to another column
      const existingColumn = Object.keys(newMapping).find(
        key => newMapping[key] === field && key !== csvColumn
      );

      if (existingColumn) {
        // Remove the old mapping
        delete newMapping[existingColumn];
      }

      newMapping[csvColumn] = field;
    }

    onMappingChange(newMapping);
  };

  const getMappedFieldsSet = () => {
    return new Set(Object.values(fieldMapping));
  };

  // Check if fullName column is detected (will be split into firstName + lastName)
  const detection = autoDetectMappingWithConfidence(csvHeaders, entityType);
  const hasFullNameSplit = detection.hasFullName && fieldMapping[detection.fullNameColumn || ''] === 'firstName';

  const getUnmappedRequiredFields = () => {
    const mappedFields = getMappedFieldsSet();
    return availableFields
      .filter(f => f.required)
      .filter(f => {
        // If lastName is required but we have fullName split, consider it mapped
        if (f.label === 'lastName' && hasFullNameSplit) {
          return false;
        }
        return !mappedFields.has(f.label);
      });
  };

  const mappedFields = getMappedFieldsSet();
  const unmappedRequired = getUnmappedRequiredFields();

  return (
    <div className="field-mapper">
      <div className="field-mapper-header">
        <h3>Map CSV Columns to Fields</h3>
        <div className="field-mapper-stats">
          <span className="stat">
            {mappedFields.size} of {availableFields.length} fields mapped
          </span>
          {unmappedRequired.length > 0 && (
            <span className="stat stat-warning">
              {unmappedRequired.length} required field(s) not mapped
            </span>
          )}
        </div>
      </div>

      {unmappedRequired.length > 0 && (
        <div className="alert alert-warning">
          <strong>Missing required fields:</strong> {unmappedRequired.map(f => f.label).join(', ')}
        </div>
      )}

      {hasFullNameSplit && (
        <div className="alert alert-info">
          <strong>Smart Detection:</strong> We detected a "Full Name" column that will be automatically split into first and last name.
        </div>
      )}

      <div className="field-mapper-grid">
        <div className="field-mapper-grid-header">
          <div>CSV Column</div>
          <div>Maps To</div>
          <div>CRM Field</div>
        </div>

        {csvHeaders.map((header) => {
          const mappedField = fieldMapping[header] || '';
          const fieldInfo = availableFields.find(f => f.label === mappedField);
          const isRequired = fieldInfo?.required || false;

          return (
            <div key={header} className="field-mapper-row">
              <div className="csv-column">
                <span className="column-name">{header}</span>
              </div>

              <div className="mapping-arrow">→</div>

              <div className="crm-field">
                <select
                  value={mappedField}
                  onChange={(e) => handleFieldChange(header, e.target.value)}
                  className={isRequired ? 'required' : ''}
                >
                  <option value="">-- Skip this column --</option>
                  {availableFields.map((field) => {
                    const isAlreadyMapped = mappedFields.has(field.label) && mappedField !== field.label;

                    return (
                      <option
                        key={field.label}
                        value={field.label}
                        disabled={isAlreadyMapped}
                      >
                        {field.label}
                        {field.required ? ' *' : ''}
                        {isAlreadyMapped ? ' (already mapped)' : ''}
                      </option>
                    );
                  })}
                </select>
                {isRequired && (
                  <span className="required-badge">Required</span>
                )}
              </div>
            </div>
          );
        })}
      </div>

      <div className="field-mapper-legend">
        <div className="legend-item">
          <span className="required-badge">Required</span>
          <span>These fields must be mapped to proceed</span>
        </div>
        <div className="legend-item">
          <span>* indicates a required field</span>
        </div>
      </div>
    </div>
  );
}
