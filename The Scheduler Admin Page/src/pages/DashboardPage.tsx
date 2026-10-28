import { useState, type CSSProperties } from 'react';
import { useNavigate } from 'react-router-dom';

import { useBusinessContext } from '../hooks/useBusinessContext';
import { useAuth } from '../context/AuthContext';
import {
  InfoBanner,
  PageHeader,
  Grid,
  SPACING,
  THEME,
  MetricCard,
  DynamicGreeting,
  SkeletonCard,
  SectionDivider,
} from './dashboard/DashboardComponents';

export function DashboardPage() {
  const navigate = useNavigate();
  const { businessId, status } = useBusinessContext();
  const { state } = useAuth();
  const [showBanner, setShowBanner] = useState(true);

  // Get user's first name for greeting
  const userName = state.status === 'signed_in'
    ? (state.user.displayName?.split(' ')[0] ?? 'there')
    : 'there';

  if (status !== 'signed_in') {
    return (
      <div style={containerStyle}>
        <DynamicGreeting userName={userName} />
        <PageHeader
          eyebrow="OpenCRM"
          title="Admin Dashboard"
          subtitle="Loading your workspace..."
        />
        <Grid columns={2} gap={SPACING.lg}>
          <SkeletonCard height={100} />
          <SkeletonCard height={100} />
        </Grid>
        <SectionDivider label="Quick Actions" />
        <Grid columns={4} gap={SPACING.lg}>
          <SkeletonCard height={80} />
          <SkeletonCard height={80} />
          <SkeletonCard height={80} />
          <SkeletonCard height={80} />
        </Grid>
      </div>
    );
  }

  if (!businessId) {
    return (
      <div style={containerStyle}>
        <div style={emptyStateStyle}>
          <span style={{ fontSize: 16, marginBottom: SPACING.md, fontWeight: 700 }}>Workspace</span>
          <p style={{ color: THEME.colorTextMuted, fontSize: 16 }}>
            No business selected for this user.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div style={containerStyle}>
      <DynamicGreeting userName={userName} />

      <PageHeader
        eyebrow="OpenCRM"
        title="Admin Dashboard"
        subtitle="Manage your business configuration, team, and billing."
      />

      <InfoBanner
        title="Welcome to OpenCRM"
        subtitle="This portal is for configuration. Use the CRM for sales and the mobile app for daily operations."
        onDismiss={() => setShowBanner(false)}
        visible={showBanner}
      />

      {/* Workspaces Section - Hero cards */}
      <section style={sectionStyle}>
        <h3 style={sectionTitleStyle}>Your Workspaces</h3>
        <Grid columns={2} gap={SPACING.lg}>
          <WorkspaceCard
            title="Launch CRM Suite"
            description="Manage leads, marketing campaigns, and sales pipelines."
            onClick={() => window.open('https://app.example.com', '_blank')}
            hasArrow
          />
          <WorkspaceCard
            title="Scheduler Mobile App"
            description="For daily operations, calendar, and provider tools."
            badges={['iOS', 'Android']}
          />
        </Grid>
      </section>

      <SectionDivider label="Quick Actions" />

      {/* Quick Actions - Horizontal tile bar */}
      <section style={quickActionsSectionStyle}>
        <div style={quickActionsBarStyle}>
          <QuickActionTile label="Staff" onClick={() => navigate('/staff')} />
          <QuickActionTile label="Services" onClick={() => navigate('/services')} />
          <QuickActionTile label="Locations" onClick={() => navigate('/locations')} />
          <QuickActionTile label="Intake Forms" onClick={() => navigate('/intake-builder')} />
        </div>
      </section>

      <SectionDivider label="Account Management" />

      {/* Account Management Section */}
      <section style={sectionStyle}>
        <Grid columns={3} gap={SPACING.lg}>
          <MetricCard
            title="Team"
            value="Staff"
            subtitle="Invite & configure roles"
            loading={false}
            onClick={() => navigate('/staff')}
          />
          <MetricCard
            title="Billing"
            value="Subscription"
            subtitle="Invoices & payment methods"
            loading={false}
            onClick={() => navigate('/billing')}
          />
          <MetricCard
            title="Settings"
            value="Config"
            subtitle="Business profile & compliance"
            loading={false}
            onClick={() => navigate('/settings')}
          />
        </Grid>
      </section>
    </div>
  );
}

// Workspace Card Component - Premium styling
function WorkspaceCard({
  title,
  description,
  onClick,
  hasArrow,
  badges,
}: {
  title: string;
  description: string;
  onClick?: () => void;
  hasArrow?: boolean;
  badges?: string[];
}) {
  const [isHovered, setIsHovered] = useState(false);
  const isClickable = Boolean(onClick);

  const cardStyle: CSSProperties = {
    display: 'flex',
    alignItems: 'center',
    gap: SPACING.md,
    padding: SPACING.lg,
    background: THEME.colorBgPanelGradient,
    borderRadius: THEME.radiusLg,
    boxShadow: isHovered ? THEME.shadowHover : THEME.shadow,
    border: `1px solid ${THEME.colorBorder}`,
    cursor: isClickable ? 'pointer' : 'default',
    transition: `all ${THEME.transitionBase} ease-out`,
    transform: isHovered && isClickable ? 'translateY(-3px)' : 'translateY(0)',
  };

  return (
    <div
      style={cardStyle}
      onClick={onClick}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      role={isClickable ? 'button' : undefined}
      tabIndex={isClickable ? 0 : undefined}
      onKeyDown={(e) => {
        if (isClickable && (e.key === 'Enter' || e.key === ' ')) {
          e.preventDefault();
          onClick?.();
        }
      }}
    >
      <div style={{ flex: 1 }}>
        <h4 style={workspaceTitleStyle}>{title}</h4>
        <p style={workspaceDescStyle}>{description}</p>
        {badges && badges.length > 0 && (
          <div style={{ marginTop: 8, display: 'flex', gap: 8 }}>
            {badges.map((badge) => (
              <span key={badge} style={badgeStyle}>{badge}</span>
            ))}
          </div>
        )}
      </div>
      {hasArrow && (
        <div style={{
          ...arrowStyle,
          transform: isHovered ? 'translateX(4px)' : 'translateX(0)',
          transition: `transform ${THEME.transitionSpeed} ease-out`,
        }}>
          →
        </div>
      )}
    </div>
  );
}

// Quick Action Tile Component - Compact horizontal style
function QuickActionTile({
  label,
  onClick,
}: {
  label: string;
  onClick: () => void;
}) {
  const [isHovered, setIsHovered] = useState(false);

  const tileStyle: CSSProperties = {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    padding: `${SPACING.md}px ${SPACING.lg}px`,
    background: isHovered ? THEME.colorAccentSubtle : THEME.colorBgPanel,
    borderRadius: THEME.radius,
    border: `1px solid ${isHovered ? THEME.colorAccent : THEME.colorBorder}`,
    cursor: 'pointer',
    transition: `all ${THEME.transitionSpeed} ease-out`,
    transform: isHovered ? 'translateY(-2px) scale(1.02)' : 'translateY(0) scale(1)',
    flex: 1,
    minWidth: 100,
  };

  const labelStyle: CSSProperties = {
    fontSize: 13,
    fontWeight: 500,
    color: isHovered ? THEME.colorAccentStrong : THEME.colorText,
    transition: `color ${THEME.transitionSpeed} ease-out`,
  };

  return (
    <div
      style={tileStyle}
      onClick={onClick}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      role="button"
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          onClick();
        }
      }}
    >
      <span style={labelStyle}>{label}</span>
    </div>
  );
}

// Styles
const containerStyle: CSSProperties = {
  padding: SPACING.xl,
  maxWidth: 1000,
  margin: '0 auto',
  background: `linear-gradient(180deg, ${THEME.colorBgGradientStart} 0%, ${THEME.colorBgGradientEnd} 100%)`,
  minHeight: '100vh',
};

const emptyStateStyle: CSSProperties = {
  display: 'flex',
  flexDirection: 'column',
  alignItems: 'center',
  justifyContent: 'center',
  minHeight: 400,
  textAlign: 'center',
};

const sectionStyle: CSSProperties = {
  marginBottom: SPACING.lg,
};

const quickActionsSectionStyle: CSSProperties = {
  marginBottom: SPACING.lg,
};

const quickActionsBarStyle: CSSProperties = {
  display: 'flex',
  gap: SPACING.md,
};

const sectionTitleStyle: CSSProperties = {
  fontSize: 16,
  fontWeight: 600,
  color: THEME.colorText,
  marginBottom: SPACING.md,
  display: 'flex',
  alignItems: 'center',
  gap: SPACING.sm,
};

const workspaceTitleStyle: CSSProperties = {
  margin: '0 0 4px',
  fontSize: 16,
  fontWeight: 600,
  color: THEME.colorText,
};

const workspaceDescStyle: CSSProperties = {
  margin: 0,
  color: THEME.colorTextMuted,
  fontSize: 14,
  lineHeight: 1.4,
};

const arrowStyle: CSSProperties = {
  marginLeft: 'auto',
  color: THEME.colorAccent,
  fontSize: 20,
  fontWeight: 500,
};

const badgeStyle: CSSProperties = {
  fontSize: 10,
  fontWeight: 600,
  backgroundColor: '#f3f4f6',
  padding: '3px 8px',
  borderRadius: 4,
  color: '#374151',
  textTransform: 'uppercase',
  letterSpacing: '0.025em',
};
