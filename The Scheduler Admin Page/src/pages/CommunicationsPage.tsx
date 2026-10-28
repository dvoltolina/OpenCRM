import { useEffect, useState, type CSSProperties } from 'react';
import { useBusinessContext } from '../hooks/useBusinessContext';
import {
  listTemplates,
  listAutomationRules,
  listMessageHistory,
  saveTemplate,
  deleteTemplate,
  updateAutomationRule,
  sendTestMessage,
} from '../data/templates';
import type { MessageTemplate, AutomationRule, MessageHistory } from '../types/models';
import { THEME, SPACING } from './dashboard/DashboardComponents';

type TabType = 'templates' | 'automation' | 'history';

export function CommunicationsPage() {
  const { businessId } = useBusinessContext();
  const [activeTab, setActiveTab] = useState<TabType>('templates');
  const [templates, setTemplates] = useState<MessageTemplate[]>([]);
  const [rules, setRules] = useState<AutomationRule[]>([]);
  const [history, setHistory] = useState<MessageHistory[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [testingTemplateId, setTestingTemplateId] = useState<string | null>(null);
  const [editingTemplate, setEditingTemplate] = useState<MessageTemplate | null>(null);
  const [showTemplateDialog, setShowTemplateDialog] = useState(false);

  // Load data
  useEffect(() => {
    if (!businessId) return;
    setLoading(true);
    Promise.all([
      listTemplates(businessId),
      listAutomationRules(businessId),
      listMessageHistory(businessId, 50),
    ])
      .then(([t, r, h]) => {
        setTemplates(t);
        setRules(r);
        setHistory(h);
        setErrorMessage(null);
      })
      .catch((err) => {
        console.error('Failed to load communications data:', err);
        setErrorMessage('Failed to load communications data from the shared backend.');
      })
      .finally(() => setLoading(false));
  }, [businessId]);

  // Handlers
  const handleCreateTemplate = () => {
    setEditingTemplate({
      id: '',
      businessId: businessId || '',
      channel: 'email',
      type: 'booking_confirmation',
      subject: '',
      body: '',
    });
    setShowTemplateDialog(true);
  };

  const handleEditTemplate = (template: MessageTemplate) => {
    setEditingTemplate(template);
    setShowTemplateDialog(true);
  };

  const handleSaveTemplate = async () => {
    if (!businessId || !editingTemplate) return;
    try {
      setErrorMessage(null);
      await saveTemplate(businessId, editingTemplate);
      setShowTemplateDialog(false);
      setEditingTemplate(null);
      // Reload templates
      const updated = await listTemplates(businessId);
      setTemplates(updated);
      setStatusMessage(
        editingTemplate.id ?
          'Template updated via shared communications callable.' :
          'Template created via shared communications callable.',
      );
    } catch (err) {
      console.error('Failed to save template:', err);
      setErrorMessage('Failed to save template.');
    }
  };

  const handleDeleteTemplate = async (templateId: string) => {
    if (!businessId) return;
    if (!confirm('Delete this template?')) return;
    try {
      setErrorMessage(null);
      await deleteTemplate(businessId, templateId);
      const updated = await listTemplates(businessId);
      setTemplates(updated);
      setStatusMessage('Template deleted via shared communications callable.');
    } catch (err) {
      console.error('Failed to delete template:', err);
      setErrorMessage('Failed to delete template.');
    }
  };

  const handleToggleRule = async (ruleId: string, field: keyof AutomationRule, value: boolean) => {
    if (!businessId) return;
    try {
      setErrorMessage(null);
      await updateAutomationRule(businessId, ruleId, { [field]: value });
      const updated = await listAutomationRules(businessId);
      setRules(updated);
      setStatusMessage('Automation rule updated via shared communications callable.');
    } catch (err) {
      console.error('Failed to update rule:', err);
      setErrorMessage('Failed to update automation rule.');
    }
  };

  const handleTestSend = async (templateId: string) => {
    if (!businessId) return;
    const recipient = prompt('Enter test email or phone number:');
    if (!recipient) return;
    const template = templates.find((t) => t.id === templateId);
    if (!template) return;
    try {
      setErrorMessage(null);
      setTestingTemplateId(templateId);
      const result = await sendTestMessage(businessId, templateId, recipient, template.channel);
      const previewSnippet = result.renderedPreview?.trim().slice(0, 120);
      setStatusMessage(
        `Sent test ${template.channel.toUpperCase()} for ${template.type} to ${recipient}.${result.messageId ? ` Message ID: ${result.messageId}.` : ''}${previewSnippet ? ` Preview: ${previewSnippet}${result.renderedPreview && result.renderedPreview.length > 120 ? '…' : ''}` : ''}`,
      );
    } catch (err) {
      console.error('Failed to send test:', err);
      setErrorMessage('Failed to send test message.');
    } finally {
      setTestingTemplateId(null);
    }
  };

  // Styles
  const pageContainerStyle: CSSProperties = {
    minHeight: '100vh',
    background: `linear-gradient(180deg, ${THEME.colorBgGradientStart} 0%, ${THEME.colorBgGradientEnd} 100%)`,
    padding: SPACING.lg,
  };

  const headerStyle: CSSProperties = {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: SPACING.xl,
    gap: SPACING.lg,
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

  const buttonStyle: CSSProperties = {
    padding: `${SPACING.md - 4}px ${SPACING.lg}px`,
    background: THEME.colorAccent,
    color: '#fff',
    border: 'none',
    borderRadius: THEME.radius,
    fontSize: 14,
    fontWeight: 600,
    cursor: 'pointer',
    transition: `all ${THEME.transitionBase} ease-out`,
    boxShadow: THEME.shadow,
  };

  const tabsContainerStyle: CSSProperties = {
    display: 'flex',
    gap: SPACING.sm,
    marginBottom: SPACING.lg,
    borderBottom: `2px solid ${THEME.colorBorder}`,
    paddingBottom: 2,
  };

  const tabButtonStyle = (isActive: boolean): CSSProperties => ({
    padding: `${SPACING.md - 2}px ${SPACING.lg}px`,
    background: 'none',
    border: 'none',
    borderBottom: isActive ? `2px solid ${THEME.colorAccent}` : '2px solid transparent',
    color: isActive ? THEME.colorAccent : THEME.colorTextMuted,
    fontSize: 14,
    fontWeight: isActive ? 600 : 500,
    cursor: 'pointer',
    transition: `all ${THEME.transitionSpeed} ease-out`,
    marginBottom: -4,
  });

  const panelStyle: CSSProperties = {
    background: THEME.colorBgPanelGradient,
    borderRadius: THEME.radiusLg,
    padding: SPACING.lg,
    boxShadow: THEME.shadow,
    border: `1px solid ${THEME.colorBorder}`,
  };

  if (loading) {
    return (
      <section style={pageContainerStyle}>
        <header style={headerStyle}>
          <div>
            <p style={eyebrowStyle}>Messaging</p>
            <h1 style={titleStyle}>Communications & Automation</h1>
          </div>
        </header>
        <p>Loading...</p>
      </section>
    );
  }

  return (
    <section style={pageContainerStyle}>
      <header style={headerStyle}>
        <div>
          <p style={eyebrowStyle}>Messaging</p>
          <h1 style={titleStyle}>Communications & Automation</h1>
          <p style={subtitleStyle}>
            Manage email/SMS templates, automation rules, and view message history.
          </p>
        </div>
        <button
          style={buttonStyle}
          onClick={handleCreateTemplate}
          onMouseOver={(e) => {
            e.currentTarget.style.background = THEME.colorAccentStrong;
            e.currentTarget.style.transform = 'translateY(-2px)';
            e.currentTarget.style.boxShadow = THEME.shadowHover;
          }}
          onMouseOut={(e) => {
            e.currentTarget.style.background = THEME.colorAccent;
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = THEME.shadow;
          }}
        >
          + New Template
        </button>
      </header>

      {statusMessage && (
        <div style={{ ...panelStyle, borderColor: THEME.colorAccent, marginBottom: SPACING.lg }}>
          <p style={{ margin: 0, fontSize: 14, color: THEME.colorText }}>{statusMessage}</p>
        </div>
      )}

      {errorMessage && (
        <div style={{ ...panelStyle, borderColor: THEME.colorDanger, marginBottom: SPACING.lg }}>
          <p style={{ margin: 0, fontSize: 14, color: THEME.colorDanger }}>{errorMessage}</p>
        </div>
      )}

      {/* Tabs */}
      <div style={tabsContainerStyle}>
        <button
          style={tabButtonStyle(activeTab === 'templates')}
          onClick={() => setActiveTab('templates')}
        >
          Templates
        </button>
        <button
          style={tabButtonStyle(activeTab === 'automation')}
          onClick={() => setActiveTab('automation')}
        >
          Automation Rules
        </button>
        <button
          style={tabButtonStyle(activeTab === 'history')}
          onClick={() => setActiveTab('history')}
        >
          Message History
        </button>
      </div>

      {/* Templates Tab */}
      {activeTab === 'templates' && (
        <div style={panelStyle}>
          <h2 style={{ margin: `0 0 ${SPACING.sm}px`, fontSize: 20, fontWeight: 600, color: THEME.colorText }}>
            Message Templates
          </h2>
          <p style={{ margin: `0 0 ${SPACING.lg}px`, fontSize: 13, color: THEME.colorTextMuted }}>
            Create reusable email and SMS templates. Use variables like {'{clientName}'}, {'{appointmentTime}'}, {'{businessName}'}.
          </p>
          {templates.length === 0 ? (
            <p style={{ textAlign: 'center', padding: SPACING.xl, color: THEME.colorTextMuted }}>
              No templates yet. Click "New Template" to create one.
            </p>
          ) : (
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: `2px solid ${THEME.colorBorder}` }}>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'left', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Type</th>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'left', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Channel</th>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'left', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Subject</th>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'left', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Body Preview</th>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'left', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {templates.map((t) => (
                    <tr key={t.id} style={{ borderBottom: `1px solid ${THEME.colorBorder}` }}>
                      <td style={{ padding: `${SPACING.md}px`, fontSize: 14, color: THEME.colorText }}>{t.type}</td>
                      <td style={{ padding: `${SPACING.md}px` }}>
                        <span style={{ display: 'inline-block', padding: `${SPACING.xs}px ${SPACING.md}px`, borderRadius: SPACING.sm, fontSize: 11, fontWeight: 600, backgroundColor: THEME.colorAccentSubtle, color: THEME.colorAccentStrong, textTransform: 'uppercase' }}>{t.channel}</span>
                      </td>
                      <td style={{ padding: `${SPACING.md}px`, fontSize: 14, color: THEME.colorText }}>{t.subject || '—'}</td>
                      <td style={{ padding: `${SPACING.md}px`, fontSize: 13, color: THEME.colorTextMuted, maxWidth: '300px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {t.body.substring(0, 60)}...
                      </td>
                      <td style={{ padding: `${SPACING.md}px` }}>
                        <div style={{ display: 'flex', gap: SPACING.sm }}>
                          <button onClick={() => handleEditTemplate(t)} style={{ padding: `${SPACING.xs}px ${SPACING.md}px`, fontSize: 13, fontWeight: 500, border: `1px solid ${THEME.colorBorder}`, borderRadius: SPACING.sm, background: '#fff', color: THEME.colorText, cursor: 'pointer', transition: `all ${THEME.transitionSpeed} ease-out` }}>Edit</button>
                          <button onClick={() => handleTestSend(t.id)} disabled={testingTemplateId === t.id} style={{ padding: `${SPACING.xs}px ${SPACING.md}px`, fontSize: 13, fontWeight: 500, border: `1px solid ${THEME.colorBorder}`, borderRadius: SPACING.sm, background: '#fff', color: THEME.colorText, cursor: 'pointer', transition: `all ${THEME.transitionSpeed} ease-out` }}>{testingTemplateId === t.id ? 'Sending…' : 'Test'}</button>
                          <button onClick={() => handleDeleteTemplate(t.id)} style={{ padding: `${SPACING.xs}px ${SPACING.md}px`, fontSize: 13, fontWeight: 500, border: `1px solid ${THEME.colorDanger}`, borderRadius: SPACING.sm, background: '#fff', color: THEME.colorDanger, cursor: 'pointer', transition: `all ${THEME.transitionSpeed} ease-out` }}>Delete</button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Automation Rules Tab */}
      {activeTab === 'automation' && (
        <div style={panelStyle}>
          <h2 style={{ margin: `0 0 ${SPACING.sm}px`, fontSize: 20, fontWeight: 600, color: THEME.colorText }}>
            Automation Rules
          </h2>
          <p style={{ margin: `0 0 ${SPACING.xs}px`, fontSize: 13, color: THEME.colorTextMuted }}>
            Enable or disable automated messages for reminders, confirmations, cancellations, and waitlist notifications.
          </p>
          <p style={{ margin: `0 0 ${SPACING.lg}px`, fontSize: 12, color: THEME.colorTextMuted, padding: `${SPACING.sm}px ${SPACING.md}px`, background: THEME.colorAccentSubtle, borderRadius: SPACING.sm }}>
            <strong>Feature Flag:</strong> enableAutomatedReminders must be enabled for automated sending.
          </p>
          {rules.length === 0 ? (
            <p style={{ textAlign: 'center', padding: SPACING.xl, color: THEME.colorTextMuted }}>
              No automation rules configured.
            </p>
          ) : (
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: `2px solid ${THEME.colorBorder}` }}>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'left', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Rule Type</th>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'center', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Enabled</th>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'center', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Email</th>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'center', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>SMS</th>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'left', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Timing</th>
                  </tr>
                </thead>
                <tbody>
                  {rules.map((r) => (
                    <tr key={r.id} style={{ borderBottom: `1px solid ${THEME.colorBorder}` }}>
                      <td style={{ padding: `${SPACING.md}px`, fontSize: 14, color: THEME.colorText, textTransform: 'capitalize' }}>{r.type.replace(/_/g, ' ')}</td>
                      <td style={{ padding: `${SPACING.md}px`, textAlign: 'center' }}>
                        <input
                          type="checkbox"
                          checked={r.enabled}
                          onChange={(e) => handleToggleRule(r.id, 'enabled', e.target.checked)}
                          style={{ cursor: 'pointer', width: 16, height: 16 }}
                        />
                      </td>
                      <td style={{ padding: `${SPACING.md}px`, textAlign: 'center' }}>
                        <input
                          type="checkbox"
                          checked={r.emailEnabled}
                          onChange={(e) => handleToggleRule(r.id, 'emailEnabled', e.target.checked)}
                          style={{ cursor: 'pointer', width: 16, height: 16 }}
                        />
                      </td>
                      <td style={{ padding: `${SPACING.md}px`, textAlign: 'center' }}>
                        <input
                          type="checkbox"
                          checked={r.smsEnabled}
                          onChange={(e) => handleToggleRule(r.id, 'smsEnabled', e.target.checked)}
                          style={{ cursor: 'pointer', width: 16, height: 16 }}
                        />
                      </td>
                      <td style={{ padding: `${SPACING.md}px`, fontSize: 13, color: THEME.colorTextMuted }}>
                        {r.timingMinutes ? `${r.timingMinutes} min before` : '—'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Message History Tab */}
      {activeTab === 'history' && (
        <div style={panelStyle}>
          <h2 style={{ margin: `0 0 ${SPACING.sm}px`, fontSize: 20, fontWeight: 600, color: THEME.colorText }}>
            Recent Messages
          </h2>
          <p style={{ margin: `0 0 ${SPACING.lg}px`, fontSize: 13, color: THEME.colorTextMuted }}>
            View recently sent emails and SMS messages (last 50).
          </p>
          {history.length === 0 ? (
            <p style={{ textAlign: 'center', padding: SPACING.xl, color: THEME.colorTextMuted }}>
              No message history yet.
            </p>
          ) : (
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: `2px solid ${THEME.colorBorder}` }}>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'left', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Sent At</th>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'left', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Type</th>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'left', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Channel</th>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'left', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Recipient</th>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'left', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Status</th>
                    <th style={{ padding: `${SPACING.md}px`, textAlign: 'left', fontSize: 11, fontWeight: 600, color: THEME.colorTextMuted, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Subject</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map((m) => (
                    <tr key={m.id} style={{ borderBottom: `1px solid ${THEME.colorBorder}` }}>
                      <td style={{ padding: `${SPACING.md}px`, fontSize: 13, color: THEME.colorTextMuted }}>{new Date(m.sentAt).toLocaleString()}</td>
                      <td style={{ padding: `${SPACING.md}px`, fontSize: 14, color: THEME.colorText, textTransform: 'capitalize' }}>{m.type.replace(/_/g, ' ')}</td>
                      <td style={{ padding: `${SPACING.md}px` }}>
                        <span style={{ display: 'inline-block', padding: `${SPACING.xs}px ${SPACING.md}px`, borderRadius: SPACING.sm, fontSize: 11, fontWeight: 600, backgroundColor: THEME.colorAccentSubtle, color: THEME.colorAccentStrong, textTransform: 'uppercase' }}>{m.channel}</span>
                      </td>
                      <td style={{ padding: `${SPACING.md}px`, fontSize: 14, color: THEME.colorText }}>{m.recipient}</td>
                      <td style={{ padding: `${SPACING.md}px` }}>
                        <span style={{
                          display: 'inline-block',
                          padding: `${SPACING.xs}px ${SPACING.md}px`,
                          borderRadius: SPACING.sm,
                          fontSize: 11,
                          fontWeight: 600,
                          backgroundColor: m.status === 'sent' ? '#d1fae5' : m.status === 'failed' ? '#fee2e2' : '#fef3c7',
                          color: m.status === 'sent' ? '#065f46' : m.status === 'failed' ? '#991b1b' : '#78350f',
                          textTransform: 'uppercase'
                        }}>
                          {m.status}
                        </span>
                      </td>
                      <td style={{ padding: `${SPACING.md}px`, fontSize: 14, color: THEME.colorText }}>{m.subject || '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Template Editor Dialog */}
      {showTemplateDialog && editingTemplate && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'rgba(0, 0, 0, 0.5)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
            padding: SPACING.lg,
          }}
          onClick={() => setShowTemplateDialog(false)}
        >
          <div
            style={{
              background: THEME.colorBgPanelGradient,
              borderRadius: THEME.radiusLg,
              padding: SPACING.xl,
              maxWidth: 600,
              width: '100%',
              maxHeight: '90vh',
              overflowY: 'auto',
              boxShadow: THEME.shadowLg,
              border: `1px solid ${THEME.colorBorder}`,
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <h2 style={{ margin: `0 0 ${SPACING.lg}px`, fontSize: 22, fontWeight: 700, color: THEME.colorText }}>
              {editingTemplate.id ? 'Edit Template' : 'New Template'}
            </h2>
            <form
              onSubmit={(e) => {
                e.preventDefault();
                handleSaveTemplate();
              }}
              style={{ display: 'flex', flexDirection: 'column', gap: SPACING.md }}
            >
              <label style={{ display: 'flex', flexDirection: 'column', gap: SPACING.xs }}>
                <span style={{ fontSize: 13, fontWeight: 600, color: THEME.colorText }}>Type</span>
                <input
                  type="text"
                  value={editingTemplate.type}
                  onChange={(e) =>
                    setEditingTemplate({ ...editingTemplate, type: e.target.value })
                  }
                  placeholder="e.g., booking_confirmation, reminder_24h"
                  required
                  style={{ padding: `${SPACING.md - 2}px ${SPACING.md}px`, fontSize: 14, border: `1px solid ${THEME.colorBorder}`, borderRadius: SPACING.sm, background: '#fff' }}
                />
              </label>
              <label style={{ display: 'flex', flexDirection: 'column', gap: SPACING.xs }}>
                <span style={{ fontSize: 13, fontWeight: 600, color: THEME.colorText }}>Channel</span>
                <select
                  value={editingTemplate.channel}
                  onChange={(e) =>
                    setEditingTemplate({
                      ...editingTemplate,
                      channel: e.target.value as 'email' | 'sms',
                    })
                  }
                  style={{ padding: `${SPACING.md - 2}px ${SPACING.md}px`, fontSize: 14, border: `1px solid ${THEME.colorBorder}`, borderRadius: SPACING.sm, background: '#fff' }}
                >
                  <option value="email">Email</option>
                  <option value="sms">SMS</option>
                </select>
              </label>
              {editingTemplate.channel === 'email' && (
                <label style={{ display: 'flex', flexDirection: 'column', gap: SPACING.xs }}>
                  <span style={{ fontSize: 13, fontWeight: 600, color: THEME.colorText }}>Subject</span>
                  <input
                    type="text"
                    value={editingTemplate.subject || ''}
                    onChange={(e) =>
                      setEditingTemplate({ ...editingTemplate, subject: e.target.value })
                    }
                    placeholder="e.g., Appointment Confirmation"
                    style={{ padding: `${SPACING.md - 2}px ${SPACING.md}px`, fontSize: 14, border: `1px solid ${THEME.colorBorder}`, borderRadius: SPACING.sm, background: '#fff' }}
                  />
                </label>
              )}
              <label style={{ display: 'flex', flexDirection: 'column', gap: SPACING.xs }}>
                <span style={{ fontSize: 13, fontWeight: 600, color: THEME.colorText }}>Body</span>
                <textarea
                  value={editingTemplate.body}
                  onChange={(e) =>
                    setEditingTemplate({ ...editingTemplate, body: e.target.value })
                  }
                  placeholder="Use variables: {clientName}, {appointmentTime}, {businessName}"
                  rows={6}
                  required
                  style={{ padding: `${SPACING.md - 2}px ${SPACING.md}px`, fontSize: 14, border: `1px solid ${THEME.colorBorder}`, borderRadius: SPACING.sm, background: '#fff', fontFamily: 'inherit', resize: 'vertical' }}
                />
              </label>
              <p style={{ margin: 0, fontSize: 12, color: THEME.colorTextMuted, padding: `${SPACING.sm}px ${SPACING.md}px`, background: THEME.colorAccentSubtle, borderRadius: SPACING.sm }}>
                Available variables: {'{clientName}'}, {'{appointmentTime}'}, {'{businessName}'}, {'{staffName}'}, {'{serviceName}'}
              </p>
              <div style={{ display: 'flex', gap: SPACING.sm, justifyContent: 'flex-end', marginTop: SPACING.md }}>
                <button
                  type="button"
                  onClick={() => setShowTemplateDialog(false)}
                  style={{ padding: `${SPACING.md - 2}px ${SPACING.lg}px`, fontSize: 14, fontWeight: 500, border: `1px solid ${THEME.colorBorder}`, borderRadius: SPACING.sm, background: '#fff', color: THEME.colorText, cursor: 'pointer', transition: `all ${THEME.transitionSpeed} ease-out` }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{ padding: `${SPACING.md - 2}px ${SPACING.lg}px`, fontSize: 14, fontWeight: 600, border: 'none', borderRadius: SPACING.sm, background: THEME.colorAccent, color: '#fff', cursor: 'pointer', transition: `all ${THEME.transitionBase} ease-out`, boxShadow: THEME.shadow }}
                  onMouseOver={(e) => {
                    e.currentTarget.style.background = THEME.colorAccentStrong;
                    e.currentTarget.style.boxShadow = THEME.shadowHover;
                  }}
                  onMouseOut={(e) => {
                    e.currentTarget.style.background = THEME.colorAccent;
                    e.currentTarget.style.boxShadow = THEME.shadow;
                  }}
                >
                  Save
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </section>
  );
}
