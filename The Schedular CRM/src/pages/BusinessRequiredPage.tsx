import { useAuth } from '../context/AuthContext';
import { Button, Card, EmptyState, PageLayout } from '../components/ui';

/**
 * BusinessRequiredPage
 *
 * Displayed when a user is authenticated but missing required businessId.
 * This enforces strict tenant isolation per HIPAA compliance requirements.
 *
 * SECURITY: No default/demo businessId fallbacks are permitted.
 */
export function BusinessRequiredPage() {
  const { signOut, user, crmUser } = useAuth();

  const handleSignOut = async () => {
    await signOut();
  };

  return (
    <PageLayout width="wide">
      <div className="ui-auth">
        <Card className="ui-auth__panel ui-auth__panel--wide" padding="lg">
          <EmptyState
            eyebrow="Workspace access"
            title="Workspace required"
            description="Your account is authenticated, but it is not assigned to an active CRM workspace yet."
            tone="warning"
            actions={<Button onClick={handleSignOut}>Sign out</Button>}
          >
            <div className="ui-meta-grid" aria-label="Workspace assignment details">
              <div className="ui-meta-row">
                <span className="ui-meta-row__label">Account email</span>
                <span className="ui-meta-row__value">{user?.email || 'Unknown'}</span>
              </div>
              <div className="ui-meta-row">
                <span className="ui-meta-row__label">Workspace ID</span>
                <span className="ui-meta-row__value">{crmUser?.businessId || 'Not set'}</span>
              </div>
            </div>
            <ul className="ui-list-note">
              <li>Confirm your account is assigned to the correct workspace.</li>
              <li>Verify your user profile includes a valid `businessId`.</li>
              <li>Check that the workspace is active and available to your role.</li>
            </ul>
            <p className="ui-auth__footer">
              Access stays blocked until a valid workspace assignment is present. This protects tenant isolation and HIPAA requirements.
            </p>
          </EmptyState>
        </Card>
      </div>
    </PageLayout>
  );
}
