/**
 * FormPreview Component
 * Live preview of web form appearance
 *
 * Agent Web Forms Implementation
 */

import type { WebForm } from '../../types/web-forms';

interface FormPreviewProps {
  form: WebForm;
}

/**
 * FormPreview - Renders a live preview of the form
 */
export function FormPreview({ form }: FormPreviewProps) {
  const { styling, fields, settings } = form;

  const isDark =
    styling.theme === 'dark' ||
    (styling.theme === 'auto' &&
      typeof window !== 'undefined' &&
      window.matchMedia('(prefers-color-scheme: dark)').matches);

  const bgColor = isDark ? '#1f2937' : '#ffffff';
  const textColor = isDark ? '#f9fafb' : '#111827';
  const borderColor = isDark ? '#374151' : '#d1d5db';
  const inputBg = isDark ? '#374151' : '#f9fafb';
  const primaryColor = styling.primaryColor || '#3B82F6';
  const fontFamily = styling.fontFamily || 'system-ui, sans-serif';

  const containerStyle: React.CSSProperties = {
    fontFamily,
    background: bgColor,
    color: textColor,
    padding: '24px',
    borderRadius: '8px',
    maxWidth: '500px',
    margin: '0 auto',
    border: `1px solid ${borderColor}`,
  };

  const fieldStyle: React.CSSProperties = {
    marginBottom: '16px',
  };

  const labelStyle: React.CSSProperties = {
    display: 'block',
    marginBottom: '4px',
    fontWeight: 500,
    fontSize: '14px',
    color: textColor,
  };

  const inputStyle: React.CSSProperties = {
    width: '100%',
    padding: '10px 12px',
    border: `1px solid ${borderColor}`,
    borderRadius: '6px',
    fontSize: '16px',
    background: inputBg,
    color: textColor,
    boxSizing: 'border-box',
  };

  const textareaStyle: React.CSSProperties = {
    ...inputStyle,
    minHeight: '100px',
    resize: 'vertical',
  };

  const checkboxWrapperStyle: React.CSSProperties = {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
  };

  const buttonStyle: React.CSSProperties = {
    width: '100%',
    padding: '12px 24px',
    background: primaryColor,
    color: 'white',
    border: 'none',
    borderRadius: '6px',
    fontSize: '16px',
    fontWeight: 600,
    cursor: 'pointer',
  };

  // Filter out hidden fields for preview
  const visibleFields = fields.filter((f) => f.type !== 'hidden');

  return (
    <div className="form-preview-container">
      <div className="form-preview-label">Preview</div>
      <div style={containerStyle}>
        {visibleFields.map((field) => (
          <div key={field.id} style={fieldStyle}>
            <label style={labelStyle}>
              {field.label}
              {field.required && (
                <span style={{ color: '#ef4444', marginLeft: '2px' }}>*</span>
              )}
            </label>

            {field.type === 'textarea' ? (
              <textarea
                style={textareaStyle}
                placeholder={field.placeholder}
                disabled
              />
            ) : field.type === 'select' ? (
              <select style={inputStyle} disabled>
                <option value="">Select...</option>
                {(field.options || []).map((opt) => (
                  <option key={opt} value={opt}>
                    {opt}
                  </option>
                ))}
              </select>
            ) : field.type === 'checkbox' ? (
              <div style={checkboxWrapperStyle}>
                <input
                  type="checkbox"
                  style={{
                    width: '18px',
                    height: '18px',
                    accentColor: primaryColor,
                  }}
                  disabled
                />
              </div>
            ) : (
              <input
                type={field.type}
                style={inputStyle}
                placeholder={field.placeholder}
                disabled
              />
            )}
          </div>
        ))}

        <button type="button" style={buttonStyle} disabled>
          {settings.submitButtonText || 'Submit'}
        </button>
      </div>

      <div className="form-preview-note">
        This is a preview. The actual form may look slightly different when embedded.
      </div>
    </div>
  );
}

export default FormPreview;
