import { useEffect, useMemo, useRef, useState } from 'react';
import { getFeatureFlags } from '../../config/features';
import { useAuth } from '../../context/AuthContext';
import { useDealMutations } from '../../hooks/useDealMutations';
import { useDocumentTemplates } from '../../hooks/useDocumentTemplates';
import { createSecurityContext } from '../../lib/security-context';
import { DocumentService } from '../../services/document-service';
import type { Client, Company, Deal } from '../../types/models';
import type {
  Document,
  DocumentMergeField,
  DocumentSigner,
  DocumentTemplate,
  DocumentType,
} from '../../types/documents';
import { SignatureStatus } from './SignatureStatus';
import { DocumentPreview } from './DocumentPreview';

interface ProposalFlowProps {
  deal: Deal;
  documents: Document[];
  client?: Client | null;
  company?: Company | null;
  onRefreshDocuments: () => void;
  refreshDeal?: () => void;
  isLoadingDocuments?: boolean;
}

function normalizeKey(key: string): string {
  return key.replace(/[{}]/g, '').replace(/[^a-zA-Z0-9]+/g, '_').toLowerCase();
}

function formatCurrency(valueCents: number, currency: string): string {
  const dollars = Number.isFinite(valueCents) ? valueCents / 100 : 0;
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: currency || 'USD' }).format(dollars);
}

function formatDateValue(value?: Date | string | null): string {
  if (!value) return '';
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  return date.toISOString().slice(0, 10);
}

function toSafeString(value: unknown): string {
  if (value === null || value === undefined) return '';
  if (value instanceof Date) return formatDateValue(value);
  return String(value);
}

function getDefaultMergeValues(deal: Deal, client?: Client | null, company?: Company | null): Record<string, string> {
  const clientName =
    [client?.firstName, client?.lastName].filter(Boolean).join(' ') || deal.clientName || company?.name || '';

  return {
    deal_title: deal.title,
    deal_id: deal.id,
    deal_value: formatCurrency(deal.valueCents, deal.currency),
    deal_probability: deal.probability !== undefined ? `${deal.probability}%` : '',
    expected_close_date: formatDateValue(deal.expectedCloseDate),
    client_name: clientName,
    client_email: client?.email || '',
    client_phone: client?.phone || '',
    company_name: company?.name || deal.companyName || '',
    assignee_name: deal.assigneeName || '',
    proposal_date: formatDateValue(new Date()),
    quote_date: formatDateValue(new Date()),
  };
}

function getFieldKey(field: DocumentMergeField, index: number): string {
  if (field.key?.trim()) return field.key;
  if (field.sourceField?.trim()) return `{{${field.sourceField}}}`;
  return `field_${index + 1}`;
}

function buildMergeData(
  template: DocumentTemplate | null,
  defaults: Record<string, string>
): Record<string, string> {
  if (!template || !template.mergeFields || template.mergeFields.length === 0) {
    return {
      '{{deal_title}}': defaults.deal_title || '',
      '{{deal_value}}': defaults.deal_value || '',
      '{{client_name}}': defaults.client_name || '',
      '{{client_email}}': defaults.client_email || '',
      '{{proposal_date}}': defaults.proposal_date || defaults.quote_date || '',
      '{{expected_close_date}}': defaults.expected_close_date || '',
    };
  }

  const data: Record<string, string> = {};
  template.mergeFields.forEach((field, index) => {
    const key = getFieldKey(field, index);
    const normalizedKey = normalizeKey(field.sourceField || field.key || key);
    data[key] = defaults[normalizedKey] ?? '';
  });
  return data;
}

function getDocumentTimestamp(doc: Document): number {
  const updated = doc.updatedAt ? new Date(doc.updatedAt).getTime() : 0;
  const created = doc.createdAt ? new Date(doc.createdAt).getTime() : 0;
  return updated || created || 0;
}

export function ProposalFlow({
  deal,
  documents,
  client,
  company,
  onRefreshDocuments,
  refreshDeal,
  isLoadingDocuments,
}: ProposalFlowProps) {
  const features = getFeatureFlags();
  const { crmUser } = useAuth();
  const documentService = useMemo(() => new DocumentService(), []);
  const { markWon } = useDealMutations();
  const proposalTypes = useMemo<DocumentType[]>(() => ['proposal', 'quote'], []);
  const autoWinEnabled = features.enableAutoWinOnSignedProposal !== false;

  const { templates, isLoading: templatesLoading, error: templateError } = useDocumentTemplates({
    documentTypes: proposalTypes,
    autoLoad: features.enableDocuments,
  });

  const [selectedTemplateId, setSelectedTemplateId] = useState<string | null>(null);
  const [mergeData, setMergeData] = useState<Record<string, string>>({});
  const [sendForSignature, setSendForSignature] = useState<boolean>(features.enableESignature);
  const [signatureMessage, setSignatureMessage] = useState<string>('Please review and sign this document.');
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isGenerating, setIsGenerating] = useState<boolean>(false);
  const [previewDoc, setPreviewDoc] = useState<Document | null>(null);
  const [focusedDocId, setFocusedDocId] = useState<string | null>(null);
  const [isSendingSignature, setIsSendingSignature] = useState<boolean>(false);
  const [autoMarkError, setAutoMarkError] = useState<string | null>(null);
  const [isAutoMarking, setIsAutoMarking] = useState<boolean>(false);
  const lastAutoMarkAt = useRef<number | null>(null);

  const defaultSignerName = useMemo(() => {
    const name = [client?.firstName, client?.lastName].filter(Boolean).join(' ');
    return name || deal.clientName || company?.name || 'Client';
  }, [client?.firstName, client?.lastName, deal.clientName, company?.name]);
  const defaultSignerEmail = useMemo(() => client?.email || '', [client?.email]);
  const [signer, setSigner] = useState<{ name: string; email: string; role: string }>({
    name: defaultSignerName,
    email: defaultSignerEmail,
    role: 'client',
  });

  const defaults = useMemo(() => getDefaultMergeValues(deal, client, company), [deal, client, company]);
  const selectedTemplate = useMemo(
    () => templates.find((tpl) => tpl.id === selectedTemplateId) || null,
    [selectedTemplateId, templates]
  );
  const proposalDocuments = useMemo(
    () =>
      documents
        .filter(
          (doc) =>
            doc.associatedEntityType === 'deal' &&
            doc.associatedEntityId === deal.id &&
            (doc.documentType === 'proposal' || doc.documentType === 'quote')
        )
        .sort((a, b) => getDocumentTimestamp(b) - getDocumentTimestamp(a)),
    [deal.id, documents]
  );

  const focusedDoc = useMemo(
    () => proposalDocuments.find((doc) => doc.id === focusedDocId) || proposalDocuments[0] || null,
    [focusedDocId, proposalDocuments]
  );

  const autoMarkedDocs = useRef<Set<string>>(new Set());

  useEffect(() => {
    if (templates.length > 0 && !selectedTemplateId) {
      setSelectedTemplateId(templates[0].id);
    }
  }, [selectedTemplateId, templates]);

  useEffect(() => {
    if (selectedTemplate) {
      setMergeData(buildMergeData(selectedTemplate, defaults));
    } else if (templates.length === 0) {
      setMergeData(buildMergeData(null, defaults));
    }
  }, [defaults, selectedTemplate, templates.length]);

  useEffect(() => {
    setSigner((prev) => ({
      ...prev,
      name: prev.name || defaultSignerName,
      email: prev.email || defaultSignerEmail,
    }));
  }, [defaultSignerEmail, defaultSignerName]);

  useEffect(() => {
    if (proposalDocuments.length === 0) {
      setFocusedDocId(null);
      return;
    }
    if (!focusedDocId || !proposalDocuments.find((doc) => doc.id === focusedDocId)) {
      setFocusedDocId(proposalDocuments[0].id);
    }
  }, [focusedDocId, proposalDocuments]);

  useEffect(() => {
    const signedDoc = autoWinEnabled ? proposalDocuments.find((doc) => doc.status === 'signed') : null;
    if (!signedDoc || deal.status !== 'open' || autoMarkedDocs.current.has(signedDoc.id)) {
      return;
    }
    const now = Date.now();
    const throttled =
      lastAutoMarkAt.current && now - lastAutoMarkAt.current < 5 * 60 * 1000;
    if (throttled) {
      return;
    }

    lastAutoMarkAt.current = now;
    setIsAutoMarking(true);
    setAutoMarkError(null);
    markWon(deal.id, 'Signed proposal completed')
      .then(() => {
        autoMarkedDocs.current.add(signedDoc.id);
        refreshDeal?.();
      })
      .catch(() => {
        setAutoMarkError('Document signed, but marking the deal as won failed. Retry from the deal actions.');
      })
      .finally(() => {
        setIsAutoMarking(false);
      });
  }, [autoWinEnabled, deal.id, deal.status, markWon, proposalDocuments, refreshDeal]);

  const buildSigners = (): Array<Omit<DocumentSigner, 'id' | 'status'>> | null => {
    const email = signer.email.trim();
    if (!email) return null;
    return [
      {
        name: signer.name || defaultSignerName,
        email,
        role: signer.role || 'client',
        order: 1,
      },
    ];
  };

  const handleGenerate = async (sendNow: boolean) => {
    if (!crmUser) {
      setErrorMessage('Authentication is required to generate documents.');
      return;
    }
    if (!selectedTemplate) {
      setErrorMessage('Select a template to generate a proposal or quote.');
      return;
    }
    if (sendNow && !features.enableESignature) {
      setErrorMessage('E-signature is disabled. Save as draft or enable signatures first.');
      return;
    }
    const signers = sendNow ? buildSigners() : null;
    if (sendNow && !signers) {
      setErrorMessage('Provide a signer email before sending for signature.');
      return;
    }

    setIsGenerating(true);
    setErrorMessage(null);
    setStatusMessage(null);
    try {
      const context = createSecurityContext(crmUser);
      const created = await documentService.createFromTemplate(context, selectedTemplate.id, {
        name: `${selectedTemplate.name} - ${deal.title}`,
        mergeData,
        associatedEntity: { type: 'deal', id: deal.id },
        signers: signers || undefined,
      });

      setPreviewDoc(created);
      setFocusedDocId(created.id);
      setStatusMessage(sendNow ? 'Document generated. Sending for signature…' : 'Draft generated from template.');
      onRefreshDocuments();

      if (sendNow && signers) {
        await documentService.sendForSignature(context, created.id, signers, {
          message: signatureMessage,
        });
        setStatusMessage('Sent for signature.');
        onRefreshDocuments();
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unable to generate the document';
      setErrorMessage(message);
    } finally {
      setIsGenerating(false);
    }
  };

  const handleSendExisting = async () => {
    if (!crmUser || !focusedDoc) {
      setErrorMessage('Select a document before sending.');
      return;
    }
    const signers = buildSigners();
    if (!signers) {
      setErrorMessage('Provide a signer email before sending for signature.');
      return;
    }
    setIsSendingSignature(true);
    setErrorMessage(null);
    setStatusMessage(null);
    try {
      const context = createSecurityContext(crmUser);
      await documentService.sendForSignature(context, focusedDoc.id, signers, {
        message: signatureMessage,
      });
      setStatusMessage('Signature request sent.');
      onRefreshDocuments();
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unable to send for signature';
      setErrorMessage(message);
    } finally {
      setIsSendingSignature(false);
    }
  };

  const mergeFieldEntries = useMemo(() => Object.entries(mergeData), [mergeData]);

  return (
    <div className="proposal-flow-card">
      <div className="proposal-flow-header">
        <div>
          <p className="eyebrow">Proposal & Quote Flow</p>
          <h4>Create, preview, and send sales documents</h4>
        </div>
        <div className="proposal-flow-actions">
          {templatesLoading ? <span className="muted">Loading templates…</span> : null}
          {templateError && <span className="error-inline">Templates unavailable</span>}
          <button type="button" onClick={onRefreshDocuments} disabled={isLoadingDocuments}>
            Refresh
          </button>
        </div>
      </div>

      <div className="proposal-flow-section">
        <label>
          Template
          <div className="proposal-flow-template-select">
            <select
              value={selectedTemplateId || ''}
              onChange={(e) => setSelectedTemplateId(e.target.value || null)}
              disabled={templatesLoading || !templates.length}
            >
              {!templates.length && <option value="">No templates available</option>}
              {templates.map((tpl) => (
                <option key={tpl.id} value={tpl.id}>
                  {tpl.name} · {tpl.documentType}
                </option>
              ))}
            </select>
            <button type="button" onClick={handleSendExisting} disabled={!focusedDoc || isSendingSignature || !features.enableESignature}>
              Send latest for signature
            </button>
          </div>
        </label>
      </div>

      <div className="proposal-flow-section">
        <div className="proposal-flow-fields">
          {mergeFieldEntries.map(([key, value]) => (
            <label key={key}>
              {normalizeKey(key).replace(/_/g, ' ') || 'Field'}
              <input
                value={value}
                onChange={(e) =>
                  setMergeData((prev) => ({
                    ...prev,
                    [key]: toSafeString(e.target.value),
                  }))
                }
                placeholder="Merge value"
              />
            </label>
          ))}
          {mergeFieldEntries.length === 0 && <p className="muted">No merge fields configured for this template.</p>}
        </div>
      </div>

      <div className="proposal-flow-section">
        <div className="proposal-flow-signer">
          <div>
            <p className="eyebrow">Signer</p>
            <p>Add who should sign the proposal</p>
          </div>
          <div className="proposal-flow-signer-fields">
            <input
              value={signer.name}
              onChange={(e) => setSigner((prev) => ({ ...prev, name: e.target.value }))}
              placeholder="Signer name"
            />
            <input
              value={signer.email}
              onChange={(e) => setSigner((prev) => ({ ...prev, email: e.target.value }))}
              placeholder="Signer email"
              type="email"
            />
            <input
              value={signer.role}
              onChange={(e) => setSigner((prev) => ({ ...prev, role: e.target.value }))}
              placeholder="Role (e.g., client)"
            />
          </div>
        </div>
      </div>

      <div className="proposal-flow-section">
        <label>
          Signature message
          <textarea
            value={signatureMessage}
            onChange={(e) => setSignatureMessage(e.target.value)}
            rows={3}
            placeholder="Message to include with the signature request"
          />
        </label>
        <div className="proposal-flow-toggle">
          <label className="checkbox">
            <input
              type="checkbox"
              checked={sendForSignature}
              onChange={(e) => setSendForSignature(e.target.checked)}
              disabled={!features.enableESignature}
            />
            Send for signature after generation
          </label>
          {!features.enableESignature && <span className="muted">Enable e-signature to send requests.</span>}
        </div>
        <div className="proposal-flow-buttons">
          <button type="button" onClick={() => handleGenerate(false)} disabled={isGenerating || isLoadingDocuments}>
            Save as draft
          </button>
          <button
            type="button"
            onClick={() => handleGenerate(sendForSignature)}
            disabled={isGenerating || (sendForSignature && !features.enableESignature) || isLoadingDocuments}
          >
            {sendForSignature ? 'Generate & Send' : 'Generate'}
          </button>
        </div>
        {statusMessage && <p className="status-inline success">{statusMessage}</p>}
        {errorMessage && <p className="error-inline">{errorMessage}</p>}
        {autoMarkError && <p className="error-inline">{autoMarkError}</p>}
        {isAutoMarking && <p className="muted">Marking deal as won from signed document…</p>}
      </div>

      <div className="proposal-flow-section">
        <div className="proposal-flow-latest">
          <div>
            <p className="eyebrow">Latest proposal/quote</p>
            {focusedDoc ? (
              <>
                <h5>{focusedDoc.name}</h5>
                <p className="muted">
                  Status: {focusedDoc.status} · v{focusedDoc.version}
                </p>
              </>
            ) : (
              <p className="muted">No proposals generated yet.</p>
            )}
          </div>
          <div className="proposal-flow-buttons">
            <button type="button" onClick={() => focusedDoc && setPreviewDoc(focusedDoc)} disabled={!focusedDoc}>
              Preview
            </button>
            <button type="button" onClick={onRefreshDocuments} disabled={isLoadingDocuments}>
              Refresh status
            </button>
          </div>
        </div>
        {focusedDoc && <SignatureStatus document={focusedDoc} onRefresh={onRefreshDocuments} />}
      </div>

      {previewDoc && <DocumentPreview document={previewDoc} onClose={() => setPreviewDoc(null)} />}
    </div>
  );
}
