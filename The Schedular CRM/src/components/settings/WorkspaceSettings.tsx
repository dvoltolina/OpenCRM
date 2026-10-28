/**
 * WorkspaceSettings Component
 *
 * Displays workspace metadata including:
 * - Workspace ID (businessId)
 * - Workspace slug
 * - Public booking URL (if available)
 * - Invite code (read-only)
 *
 * HIPAA/Security Compliance:
 * - Read-only display of workspace metadata
 * - Maintains strict tenant isolation
 * - No cross-tenant data access
 */

import { useWorkspace } from '../../hooks/useWorkspace';
import { useAuth } from '../../context/AuthContext';
import './settings.css';

export function WorkspaceSettings() {
  const { businessId } = useAuth();
  const { workspace, isLoading, error } = useWorkspace();

  if (isLoading) {
    return (
      <div className="settings-section">
        <h2>Workspace Information</h2>
        <div className="loading-message">Loading workspace details...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="settings-section">
        <h2>Workspace Information</h2>
        <div className="error-message">
          <p>Failed to load workspace information</p>
          <p className="error-detail">{error.message}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="settings-section">
      <h2>Workspace Information</h2>
      <p className="section-description">
        Your workspace details and identifiers. These are read-only for security.
      </p>

      <div className="settings-form">
        {/* Workspace ID */}
        <div className="form-group">
          <label>Workspace ID</label>
          <input
            type="text"
            value={businessId || 'Not available'}
            readOnly
            className="input-readonly"
            title="Unique identifier for your workspace"
          />
          <p className="form-help">This is your unique workspace identifier used for tenant isolation.</p>
        </div>

        {/* Workspace Name */}
        <div className="form-group">
          <label>Workspace Name</label>
          <input
            type="text"
            value={workspace?.name || 'Not set'}
            readOnly
            className="input-readonly"
          />
        </div>

        {/* Workspace Slug */}
        {workspace?.slug && (
          <div className="form-group">
            <label>Workspace Slug</label>
            <input
              type="text"
              value={workspace.slug}
              readOnly
              className="input-readonly"
              title="URL-friendly workspace identifier"
            />
            <p className="form-help">This is your URL-friendly workspace identifier.</p>
          </div>
        )}

        {/* Public Booking URL */}
        {workspace?.publicBookingUrl && (
          <div className="form-group">
            <label>Public Booking URL</label>
            <div className="input-with-copy">
              <input
                type="text"
                value={workspace.publicBookingUrl}
                readOnly
                className="input-readonly"
              />
              <button
                type="button"
                className="btn btn-secondary btn-sm"
                onClick={() => navigator.clipboard.writeText(workspace.publicBookingUrl!)}
                title="Copy to clipboard"
              >
                Copy
              </button>
            </div>
            <p className="form-help">Share this URL with clients for online booking.</p>
          </div>
        )}

        {/* Invite Code */}
        {workspace?.inviteCode && (
          <div className="form-group">
            <label>Team Invite Code</label>
            <div className="input-with-copy">
              <input
                type="text"
                value={workspace.inviteCode}
                readOnly
                className="input-readonly"
              />
              <button
                type="button"
                className="btn btn-secondary btn-sm"
                onClick={() => navigator.clipboard.writeText(workspace.inviteCode!)}
                title="Copy to clipboard"
              >
                Copy
              </button>
            </div>
            <p className="form-help">Share this code with team members to join your workspace.</p>
          </div>
        )}

        {/* Security Settings (read-only) */}
        <div className="form-group">
          <label>Security Settings</label>
          <div className="security-badges">
            {workspace?.requiresHipaaCompliance && (
              <span className="badge badge-info">HIPAA Compliance Enabled</span>
            )}
            {workspace?.mfaEnabled && (
              <span className="badge badge-success">MFA Required</span>
            )}
            {!workspace?.requiresHipaaCompliance && !workspace?.mfaEnabled && (
              <span className="badge badge-secondary">Standard Security</span>
            )}
          </div>
          <p className="form-help">
            Contact your workspace administrator to modify security settings.
          </p>
        </div>
      </div>
    </div>
  );
}

export default WorkspaceSettings;
