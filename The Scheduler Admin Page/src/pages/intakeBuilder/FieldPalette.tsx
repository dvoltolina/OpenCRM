import type { FieldPaletteItem } from './constants';
import type { IntakeFormFieldType } from '../../types/models';

type FieldPaletteProps = {
  palette: FieldPaletteItem[];
  onAddField: (type: IntakeFormFieldType) => void;
};

const styles = {
  container: {
    padding: '0 24px 24px',
  },
  header: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  title: {
    fontSize: 14,
    fontWeight: 600,
    color: '#1e293b',
    margin: 0,
  },
  subtitle: {
    fontSize: 12,
    color: '#94a3b8',
    margin: 0,
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(4, 1fr)',
    gap: 12,
  } as React.CSSProperties,
  fieldChip: {
    display: 'flex',
    flexDirection: 'column' as const,
    alignItems: 'center',
    justifyContent: 'center',
    padding: '16px 12px',
    background: '#f8fafc',
    border: '2px dashed #e2e8f0',
    borderRadius: 10,
    cursor: 'pointer',
    transition: 'all 0.2s ease',
    textAlign: 'center' as const,
  },
  fieldChipHover: {
    borderColor: '#4f46e5',
    background: '#f0f9ff',
  },
  iconWrapper: {
    width: 40,
    height: 40,
    borderRadius: 10,
    background: 'white',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 8,
    boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
  },
  label: {
    fontSize: 13,
    fontWeight: 600,
    color: '#1e293b',
    margin: '0 0 2px 0',
  },
  description: {
    fontSize: 11,
    color: '#94a3b8',
    margin: 0,
  },
};

// Icon components for cleaner rendering
const FieldIcon = ({ type }: { type: string }) => {
  const iconProps = { width: 18, height: 18, viewBox: '0 0 24 24', fill: 'none', stroke: '#4f46e5', strokeWidth: 2, strokeLinecap: 'round' as const, strokeLinejoin: 'round' as const };

  switch (type) {
    case 'text':
      return (
        <svg {...iconProps}>
          <line x1="4" y1="9" x2="20" y2="9"/>
          <line x1="4" y1="15" x2="14" y2="15"/>
        </svg>
      );
    case 'textarea':
      return (
        <svg {...iconProps}>
          <rect x="3" y="3" width="18" height="18" rx="2"/>
          <line x1="7" y1="8" x2="17" y2="8"/>
          <line x1="7" y1="12" x2="17" y2="12"/>
          <line x1="7" y1="16" x2="13" y2="16"/>
        </svg>
      );
    case 'dropdown':
      return (
        <svg {...iconProps}>
          <rect x="3" y="3" width="18" height="18" rx="2"/>
          <polyline points="8 10 12 14 16 10"/>
        </svg>
      );
    case 'radio':
      return (
        <svg {...iconProps}>
          <circle cx="12" cy="12" r="9"/>
          <circle cx="12" cy="12" r="4" fill="#4f46e5"/>
        </svg>
      );
    case 'checkbox':
      return (
        <svg {...iconProps}>
          <rect x="3" y="3" width="18" height="18" rx="2"/>
          <polyline points="9 11 12 14 16 10"/>
        </svg>
      );
    case 'date':
      return (
        <svg {...iconProps}>
          <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
          <line x1="16" y1="2" x2="16" y2="6"/>
          <line x1="8" y1="2" x2="8" y2="6"/>
          <line x1="3" y1="10" x2="21" y2="10"/>
        </svg>
      );
    case 'file':
      return (
        <svg {...iconProps}>
          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
          <polyline points="14 2 14 8 20 8"/>
          <line x1="12" y1="18" x2="12" y2="12"/>
          <line x1="9" y1="15" x2="15" y2="15"/>
        </svg>
      );
    case 'signature':
      return (
        <svg {...iconProps}>
          <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25z"/>
          <path d="M20.71 5.63l-2.34-2.34a1 1 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83a1 1 0 0 0 0-1.41z"/>
        </svg>
      );
    default:
      return (
        <svg {...iconProps}>
          <rect x="3" y="3" width="18" height="18" rx="2"/>
        </svg>
      );
  }
};

export function FieldPalette({ palette, onAddField }: FieldPaletteProps) {
  return (
    <div style={styles.container}>
      <div style={styles.header}>
        <div>
          <h3 style={styles.title}>Add Fields</h3>
          <p style={styles.subtitle}>Click to add to your form</p>
        </div>
      </div>
      <div style={styles.grid} role="toolbar" aria-label="Add form fields">
        {palette.map((item) => (
          <button
            type="button"
            key={item.type}
            style={styles.fieldChip}
            onClick={() => onAddField(item.type)}
            aria-label={`Add ${item.label} field`}
            onMouseEnter={(e) => {
              e.currentTarget.style.borderColor = '#4f46e5';
              e.currentTarget.style.background = '#f0f9ff';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.borderColor = '#e2e8f0';
              e.currentTarget.style.background = '#f8fafc';
            }}
          >
            <div style={styles.iconWrapper}>
              <FieldIcon type={item.type} />
            </div>
            <p style={styles.label}>{item.label}</p>
            <p style={styles.description}>{item.description}</p>
          </button>
        ))}
      </div>
    </div>
  );
}


