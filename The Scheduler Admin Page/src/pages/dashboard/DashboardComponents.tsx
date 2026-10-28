import { useEffect, useState, type ReactNode, type CSSProperties } from 'react';

// Theme Tokens
export const SPACING = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
} as const;

export const THEME = {
  // Colors
  colorBg: '#f7f9fc',
  colorBgGradientStart: '#F7F8FA',
  colorBgGradientEnd: '#FFFFFF',
  colorBgPanel: '#ffffff',
  colorBgPanelGradient: 'linear-gradient(180deg, #FFFFFF 0%, #F9FAFB 100%)',
  colorText: '#0f172a',
  colorTextMuted: '#475569',
  colorAccent: '#0ea5e9',
  colorAccentStrong: '#0284c7',
  colorAccentSubtle: '#e0f2fe',
  colorBorder: '#E5E7EB',
  colorBorderLight: '#F3F4F6',
  colorSuccess: '#22c55e',
  colorWarning: '#f59e0b',
  colorDanger: '#ef4444',
  // Radius
  radius: 12,
  radiusLg: 16,
  // Shadows - Premium shadows
  shadow: '0 6px 20px rgba(0, 0, 0, 0.04)',
  shadowMd: '0 8px 24px rgba(0, 0, 0, 0.06)',
  shadowLg: '0 12px 36px rgba(0, 0, 0, 0.08)',
  shadowHover: '0 10px 28px rgba(0, 0, 0, 0.08)',
  // Motion
  transitionSpeed: '150ms',
  transitionBase: '200ms',
} as const;

// Info Banner Component - Subtle, professional styling
type InfoBannerProps = {
  icon?: ReactNode;
  title: string;
  subtitle?: string;
  onDismiss?: () => void;
  visible?: boolean;
};

export function InfoBanner({ icon, title, subtitle, onDismiss, visible = true }: InfoBannerProps) {
  if (!visible) return null;

  // Reduced saturation - subtle blue-gray background
  const bannerStyle: CSSProperties = {
    display: 'flex',
    alignItems: 'center',
    gap: SPACING.md,
    padding: `${SPACING.md}px ${SPACING.lg}px`,
    minHeight: 56,
    maxHeight: 64,
    background: 'linear-gradient(135deg, #64748b 0%, #475569 100%)',
    borderRadius: THEME.radius,
    boxShadow: THEME.shadow,
    color: THEME.colorBgPanel,
    marginBottom: SPACING.lg,
    transition: `all ${THEME.transitionBase} ease-in-out`,
  };

  const iconContainerStyle: CSSProperties = {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    width: 32,
    height: 32,
    borderRadius: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    flexShrink: 0,
    fontSize: 16,
  };

  const contentStyle: CSSProperties = {
    flex: 1,
    minWidth: 0,
  };

  const titleStyle: CSSProperties = {
    fontSize: 14,
    fontWeight: 600,
    margin: 0,
    lineHeight: 1.3,
    color: 'inherit',
  };

  const subtitleStyle: CSSProperties = {
    fontSize: 12,
    opacity: 0.85,
    margin: `2px 0 0`,
    lineHeight: 1.4,
    color: 'inherit',
  };

  const dismissButtonStyle: CSSProperties = {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    width: 28,
    height: 28,
    borderRadius: 6,
    border: 'none',
    background: 'rgba(255, 255, 255, 0.12)',
    color: 'inherit',
    cursor: 'pointer',
    flexShrink: 0,
    fontSize: 16,
    transition: `all ${THEME.transitionSpeed} ease-in-out`,
  };

  return (
    <div style={bannerStyle}>
      {icon && <div style={iconContainerStyle}>{icon}</div>}
      <div style={contentStyle}>
        <p style={titleStyle}>{title}</p>
        {subtitle && <p style={subtitleStyle}>{subtitle}</p>}
      </div>
      {onDismiss && (
        <button
          type="button"
          style={dismissButtonStyle}
          onClick={onDismiss}
          onMouseOver={(e) => (e.currentTarget.style.background = 'rgba(255, 255, 255, 0.2)')}
          onMouseOut={(e) => (e.currentTarget.style.background = 'rgba(255, 255, 255, 0.12)')}
          aria-label="Dismiss"
        >
          ×
        </button>
      )}
    </div>
  );
}

// Section Header Component
type SectionHeaderProps = {
  title: string;
  subtitle?: string;
};

export function SectionHeader({ title, subtitle }: SectionHeaderProps) {
  const containerStyle: CSSProperties = {
    marginBottom: SPACING.lg,
  };

  const titleStyle: CSSProperties = {
    fontSize: 20,
    fontWeight: 600,
    margin: 0,
    color: THEME.colorText,
    lineHeight: 1.3,
  };

  const subtitleStyle: CSSProperties = {
    fontSize: 13,
    color: THEME.colorTextMuted,
    margin: `${SPACING.xs + 2}px 0 0`,
    lineHeight: 1.4,
  };

  return (
    <div style={containerStyle}>
      <h2 style={titleStyle}>{title}</h2>
      {subtitle && <p style={subtitleStyle}>{subtitle}</p>}
    </div>
  );
}

// Metric Card Component - Premium styling with hover lift
type MetricCardProps = {
  title: string;
  value: string | number;
  subtitle?: string;
  loading?: boolean;
  onClick?: () => void;
};

export function MetricCard({
  title,
  value,
  subtitle,
  loading = false,
  onClick,
}: MetricCardProps) {
  const isClickable = Boolean(onClick);

  const cardStyle: CSSProperties = {
    display: 'flex',
    flexDirection: 'column',
    gap: SPACING.md,
    padding: SPACING.lg,
    background: THEME.colorBgPanelGradient,
    borderRadius: THEME.radius,
    boxShadow: THEME.shadow,
    border: `1px solid ${THEME.colorBorder}`,
    minHeight: 120,
    transition: `transform ${THEME.transitionBase} ease-out, box-shadow ${THEME.transitionBase} ease-out`,
    cursor: isClickable ? 'pointer' : 'default',
  };

  const headerStyle: CSSProperties = {
    display: 'flex',
    alignItems: 'center',
    gap: SPACING.md,
  };

  const titleStyle: CSSProperties = {
    fontSize: 13,
    fontWeight: 500,
    color: THEME.colorTextMuted,
    margin: 0,
    lineHeight: 1.3,
    textTransform: 'uppercase',
    letterSpacing: '0.02em',
  };

  const valueStyle: CSSProperties = {
    fontSize: 26,
    fontWeight: 700,
    color: THEME.colorText,
    margin: 0,
    lineHeight: 1.1,
  };

  const subtitleStyle: CSSProperties = {
    fontSize: 13,
    color: THEME.colorTextMuted,
    margin: 0,
    lineHeight: 1.4,
  };

  return (
    <div
      style={cardStyle}
      onClick={onClick}
      onMouseOver={(e) => {
        if (isClickable) {
          e.currentTarget.style.transform = 'translateY(-3px)';
          e.currentTarget.style.boxShadow = THEME.shadowHover;
        }
      }}
      onMouseOut={(e) => {
        if (isClickable) {
          e.currentTarget.style.transform = 'translateY(0)';
          e.currentTarget.style.boxShadow = THEME.shadow;
        }
      }}
      role={isClickable ? 'button' : undefined}
      tabIndex={isClickable ? 0 : undefined}
      onKeyDown={(e) => {
        if (isClickable && (e.key === 'Enter' || e.key === ' ')) {
          e.preventDefault();
          onClick?.();
        }
      }}
    >
      <div style={headerStyle}>
        <p style={titleStyle}>{title}</p>
      </div>
      <p style={valueStyle}>{loading ? '…' : value}</p>
      {subtitle && <p style={subtitleStyle}>{subtitle}</p>}
    </div>
  );
}

// Snackbar Notification Component
type SnackbarProps = {
  message: string;
  type?: 'success' | 'error' | 'info';
  visible: boolean;
  onDismiss?: () => void;
  autoDismissMs?: number;
};

export function Snackbar({
  message,
  type = 'success',
  visible,
  onDismiss,
  autoDismissMs = 4000,
}: SnackbarProps) {
  useEffect(() => {
    if (!visible || !onDismiss || !autoDismissMs) return;
    const timer = setTimeout(onDismiss, autoDismissMs);
    return () => clearTimeout(timer);
  }, [visible, onDismiss, autoDismissMs]);

  if (!visible) return null;

  const bgColors = {
    success: THEME.colorSuccess,
    error: THEME.colorDanger,
    info: THEME.colorAccent,
  };

  const snackbarStyle: CSSProperties = {
    position: 'fixed',
    bottom: 80, // Above nav bar
    left: '50%',
    transform: 'translateX(-50%)',
    display: 'flex',
    alignItems: 'center',
    gap: SPACING.md,
    padding: `${SPACING.md}px ${SPACING.lg}px`,
    maxHeight: 48,
    backgroundColor: bgColors[type],
    color: THEME.colorBgPanel,
    borderRadius: THEME.radius,
    boxShadow: THEME.shadow,
    fontSize: 14,
    fontWeight: 500,
    zIndex: 1000,
    animation: `slideUp ${THEME.transitionSpeed} ease-out`,
  };

  const dismissStyle: CSSProperties = {
    marginLeft: SPACING.sm,
    background: 'none',
    border: 'none',
    color: 'rgba(255, 255, 255, 0.8)',
    cursor: 'pointer',
    fontSize: 18,
    padding: 0,
    lineHeight: 1,
  };

  return (
    <div style={snackbarStyle}>
      <span>{message}</span>
      {onDismiss && (
        <button type="button" style={dismissStyle} onClick={onDismiss} aria-label="Dismiss">
          ×
        </button>
      )}
    </div>
  );
}

// Chart Placeholder Component
type ChartPlaceholderProps = {
  title: string;
  height?: number;
};

export function ChartPlaceholder({ title, height = 180 }: ChartPlaceholderProps) {
  const containerStyle: CSSProperties = {
    padding: SPACING.lg,
    backgroundColor: THEME.colorBgPanel,
    borderRadius: THEME.radius,
    boxShadow: THEME.shadow,
    border: `1px solid ${THEME.colorBorder}`,
  };

  const titleStyle: CSSProperties = {
    fontSize: 15,
    fontWeight: 600,
    color: THEME.colorText,
    margin: `0 0 ${SPACING.md}px`,
  };

  const placeholderStyle: CSSProperties = {
    height,
    backgroundColor: THEME.colorBg,
    borderRadius: SPACING.md,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    color: THEME.colorTextMuted,
    fontSize: 13,
  };

  return (
    <div style={containerStyle}>
      <p style={titleStyle}>{title}</p>
      <div style={placeholderStyle}>Chart visualization coming soon</div>
    </div>
  );
}

// Appointments Table Component
type AppointmentRow = {
  id: string;
  client: string;
  staff: string;
  service: string;
  start: string;
  status: string;
};

type AppointmentsTableProps = {
  rows: AppointmentRow[];
  loading?: boolean;
};

export function AppointmentsTable({ rows, loading = false }: AppointmentsTableProps) {
  const containerStyle: CSSProperties = {
    padding: SPACING.lg,
    backgroundColor: THEME.colorBgPanel,
    borderRadius: THEME.radius,
    boxShadow: THEME.shadow,
    border: `1px solid ${THEME.colorBorder}`,
    overflow: 'hidden',
  };

  const headerStyle: CSSProperties = {
    display: 'grid',
    gridTemplateColumns: '1.5fr 1fr 1.2fr 1fr 0.8fr',
    gap: SPACING.md,
    padding: `0 0 ${SPACING.md}px`,
    borderBottom: `1px solid ${THEME.colorBorder}`,
    fontSize: 11,
    fontWeight: 600,
    color: THEME.colorTextMuted,
    textTransform: 'uppercase',
    letterSpacing: '0.05em',
  };

  const rowStyle: CSSProperties = {
    display: 'grid',
    gridTemplateColumns: '1.5fr 1fr 1.2fr 1fr 0.8fr',
    gap: SPACING.md,
    padding: `${SPACING.md + 2}px 0`,
    minHeight: 48,
    borderBottom: `1px solid ${THEME.colorBorder}`,
    fontSize: 14,
    color: THEME.colorText,
    alignItems: 'center',
    transition: `background-color ${THEME.transitionSpeed} ease-in-out`,
  };

  const statusBadgeStyle = (status: string): CSSProperties => {
    const statusColors: Record<string, { bg: string; text: string }> = {
      confirmed: { bg: '#d1fae5', text: '#065f46' },
      pending: { bg: '#fef3c7', text: '#78350f' },
      cancelled: { bg: '#fee2e2', text: '#991b1b' },
      completed: { bg: '#dbeafe', text: '#1e40af' },
    };
    const colors = statusColors[status.toLowerCase()] ?? { bg: THEME.colorBorder, text: THEME.colorTextMuted };
    return {
      display: 'inline-block',
      padding: `${SPACING.xs}px ${SPACING.md}px`,
      borderRadius: SPACING.sm,
      fontSize: 11,
      fontWeight: 600,
      backgroundColor: colors.bg,
      color: colors.text,
      textTransform: 'uppercase',
      letterSpacing: '0.025em',
    };
  };

  const emptyStyle: CSSProperties = {
    padding: `${SPACING.xl}px`,
    textAlign: 'center',
    color: THEME.colorTextMuted,
    fontSize: 14,
  };

  return (
    <div style={containerStyle}>
      <div style={headerStyle}>
        <span>Client</span>
        <span>Staff</span>
        <span>Service</span>
        <span>Time</span>
        <span>Status</span>
      </div>
      {loading ? (
        <div style={emptyStyle}>Loading appointments…</div>
      ) : rows.length === 0 ? (
        <div style={emptyStyle}>No upcoming appointments found.</div>
      ) : (
        rows.map((row) => (
          <div key={row.id} style={rowStyle}>
            <span style={{ fontWeight: 500 }}>{row.client}</span>
            <span>{row.staff}</span>
            <span>{row.service}</span>
            <span style={{ fontSize: 13, color: 'var(--color-text-muted, #6b7280)' }}>
              {row.start}
            </span>
            <span style={statusBadgeStyle(row.status)}>{row.status}</span>
          </div>
        ))
      )}
    </div>
  );
}

// Page Header Component - Enhanced with brand icon option
type PageHeaderProps = {
  eyebrow?: string;
  title: string;
  subtitle?: string;
  actions?: ReactNode;
  brandIcon?: ReactNode;
};

export function PageHeader({ eyebrow, title, subtitle, actions, brandIcon }: PageHeaderProps) {
  const containerStyle: CSSProperties = {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: SPACING.xl,
    gap: SPACING.lg,
  };

  const textContainerStyle: CSSProperties = {
    flex: 1,
  };

  const titleRowStyle: CSSProperties = {
    display: 'flex',
    alignItems: 'center',
    gap: SPACING.sm,
  };

  const eyebrowStyle: CSSProperties = {
    fontSize: 11,
    fontWeight: 600,
    color: THEME.colorAccent,
    textTransform: 'uppercase',
    letterSpacing: '0.1em',
    margin: 0,
  };

  const titleStyle: CSSProperties = {
    fontSize: 26,
    fontWeight: 700,
    color: THEME.colorText,
    margin: `${SPACING.sm}px 0 0`,
    lineHeight: 1.2,
  };

  const subtitleStyle: CSSProperties = {
    fontSize: 14,
    color: THEME.colorTextMuted,
    margin: `${SPACING.xs}px 0 0`,
    lineHeight: 1.5,
  };

  const actionsStyle: CSSProperties = {
    display: 'flex',
    gap: SPACING.sm,
    flexShrink: 0,
  };

  const brandIconStyle: CSSProperties = {
    fontSize: 24,
    display: 'flex',
    alignItems: 'center',
  };

  return (
    <div style={containerStyle}>
      <div style={textContainerStyle}>
        {eyebrow && <p style={eyebrowStyle}>{eyebrow}</p>}
        <div style={titleRowStyle}>
          {brandIcon && <span style={brandIconStyle}>{brandIcon}</span>}
          <h1 style={titleStyle}>{title}</h1>
        </div>
        {subtitle && <p style={subtitleStyle}>{subtitle}</p>}
      </div>
      {actions && <div style={actionsStyle}>{actions}</div>}
    </div>
  );
}

// Dynamic Greeting Component
type DynamicGreetingProps = {
  userName?: string;
};

export function DynamicGreeting({ userName = 'there' }: DynamicGreetingProps) {
  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  };

  const containerStyle: CSSProperties = {
    display: 'flex',
    alignItems: 'center',
    gap: SPACING.sm,
    padding: `${SPACING.sm}px ${SPACING.md}px`,
    background: THEME.colorAccentSubtle,
    borderRadius: THEME.radius,
    marginBottom: SPACING.lg,
  };

  const textStyle: CSSProperties = {
    fontSize: 14,
    fontWeight: 500,
    color: THEME.colorAccentStrong,
    margin: 0,
  };

  return (
    <div style={containerStyle}>
      <p style={textStyle}>{getGreeting()}, {userName}</p>
    </div>
  );
}

// Skeleton Loader Component
type SkeletonCardProps = {
  height?: number;
};

export function SkeletonCard({ height = 120 }: SkeletonCardProps) {
  const containerStyle: CSSProperties = {
    height,
    background: THEME.colorBgPanelGradient,
    borderRadius: THEME.radius,
    border: `1px solid ${THEME.colorBorder}`,
    overflow: 'hidden',
    position: 'relative',
  };

  const shimmerStyle: CSSProperties = {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    background: `linear-gradient(90deg, transparent 0%, ${THEME.colorBorderLight} 50%, transparent 100%)`,
    animation: 'shimmer 1.5s infinite',
  };

  return (
    <div style={containerStyle}>
      <div style={shimmerStyle} />
    </div>
  );
}

// Section Divider Component
type SectionDividerProps = {
  label?: string;
};

export function SectionDivider({ label }: SectionDividerProps) {
  const containerStyle: CSSProperties = {
    display: 'flex',
    alignItems: 'center',
    gap: SPACING.md,
    margin: `${SPACING.xl}px 0 ${SPACING.lg}px`,
  };

  const lineStyle: CSSProperties = {
    flex: 1,
    height: 1,
    background: THEME.colorBorder,
  };

  const labelStyle: CSSProperties = {
    fontSize: 11,
    fontWeight: 600,
    color: THEME.colorTextMuted,
    textTransform: 'uppercase',
    letterSpacing: '0.08em',
  };

  if (!label) {
    return <div style={{ ...lineStyle, margin: `${SPACING.xl}px 0` }} />;
  }

  return (
    <div style={containerStyle}>
      <div style={lineStyle} />
      <span style={labelStyle}>{label}</span>
      <div style={lineStyle} />
    </div>
  );
}

// Grid Layout Component
type GridProps = {
  columns?: 2 | 3 | 4;
  gap?: number;
  children: ReactNode;
};

export function Grid({ columns = 3, gap = SPACING.lg, children }: GridProps) {
  const style: CSSProperties = {
    display: 'grid',
    gridTemplateColumns: `repeat(${columns}, 1fr)`,
    gap,
    marginBottom: SPACING.xl,
  };

  return <div style={style}>{children}</div>;
}
