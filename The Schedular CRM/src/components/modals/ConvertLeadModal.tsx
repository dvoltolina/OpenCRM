/**
 * ConvertLeadModal Component
 * Modal for lead conversion workflow with duplicate detection
 *
 * Agent CRM-15 Implementation
 */

import { useState, useEffect, useCallback } from 'react';
import { Modal } from './Modal';
import { FormButton, FormField, FormSection } from '../forms/FormField';
import { FormInput } from '../forms/FormField';
import { FormSelect, type SelectOption } from '../forms/FormSelect';
import { useLeadConversion } from '../../hooks/useLeadConversion';
import type { Lead, Client, Deal, Pipeline, Stage } from '../../types/models';
import './modals.css';

// ============================================
// Types
// ============================================

export interface ConvertLeadModalProps {
  /** Whether the modal is open */
  isOpen: boolean;
  /** Called when modal should close */
  onClose: () => void;
  /** The lead to convert */
  lead: Lead | null;
  /** Available pipelines for deal creation */
  pipelines?: Pipeline[];
  /** Available stages (for selected pipeline) */
  stages?: Stage[];
  /** Called when pipeline selection changes */
  onPipelineChange?: (pipelineId: string) => void;
  /** Called after successful conversion */
  onSuccess?: (result: { client: Client; deal?: Deal }) => void;
}

type ConversionStep = 'checking' | 'duplicates' | 'options' | 'converting';

// ============================================
// Component
// ============================================

/**
 * ConvertLeadModal - Lead conversion workflow modal
 *
 * @example
 * ```tsx
 * const convertModal = useModal<Lead>();
 *
 * <button onClick={() => convertModal.open(lead)}>Convert Lead</button>
 *
 * <ConvertLeadModal
 *   isOpen={convertModal.isOpen}
 *   onClose={convertModal.close}
 *   lead={convertModal.data}
 *   pipelines={pipelines}
 *   stages={stages}
 *   onPipelineChange={setSelectedPipeline}
 *   onSuccess={(result) => {
 *     console.log('Converted:', result.client.id, result.deal?.id);
 *   }}
 * />
 * ```
 */
export function ConvertLeadModal({
  isOpen,
  onClose,
  lead,
  pipelines = [],
  stages = [],
  onPipelineChange,
  onSuccess,
}: ConvertLeadModalProps) {
  const {
    convert,
    checkDuplicates,
    duplicates,
    isConverting,
    isCheckingDuplicates,
    error,
    clearError,
  } = useLeadConversion();

  // State
  const [step, setStep] = useState<ConversionStep>('checking');
  const [selectedClient, setSelectedClient] = useState<Client | null>(null);
  const [createDeal, setCreateDeal] = useState(true);
  const [dealTitle, setDealTitle] = useState('');
  const [dealValue, setDealValue] = useState('');
  const [selectedPipeline, setSelectedPipeline] = useState('');
  const [selectedStage, setSelectedStage] = useState('');

  // Reset state when modal opens
  useEffect(() => {
    if (isOpen && lead) {
      setStep('checking');
      setSelectedClient(null);
      setCreateDeal(true);
      setDealTitle(`Deal for ${lead.firstName} ${lead.lastName}`);
      setDealValue('');
      setSelectedPipeline(pipelines[0]?.id || '');
      setSelectedStage('');
      clearError();

      // Check for duplicates
      checkDuplicates(lead).then((matches) => {
        if (matches.length > 0) {
          setStep('duplicates');
        } else {
          setStep('options');
        }
      });
    }
  }, [isOpen, lead, pipelines, checkDuplicates, clearError]);

  // Update stages when pipeline changes
  useEffect(() => {
    if (selectedPipeline) {
      onPipelineChange?.(selectedPipeline);
      // Set first stage as default
      const pipelineStages = stages.filter((s) => s.pipelineId === selectedPipeline);
      if (pipelineStages.length > 0 && !selectedStage) {
        setSelectedStage(pipelineStages[0].id);
      }
    }
  }, [selectedPipeline, stages, onPipelineChange, selectedStage]);

  // Handle conversion
  const handleConvert = useCallback(async () => {
    if (!lead) return;

    setStep('converting');

    try {
      const result = await convert({
        leadId: lead.id,
        existingClientId: selectedClient?.id,
        createDeal,
        dealData: createDeal
          ? {
              title: dealTitle,
              valueCents: Math.round(parseFloat(dealValue || '0') * 100),
              pipelineId: selectedPipeline,
              stageId: selectedStage,
            }
          : undefined,
      });

      onSuccess?.({ client: result.client, deal: result.deal });
      onClose();
    } catch {
      setStep('options');
    }
  }, [
    lead,
    selectedClient,
    createDeal,
    dealTitle,
    dealValue,
    selectedPipeline,
    selectedStage,
    convert,
    onSuccess,
    onClose,
  ]);

  // Handle duplicate selection
  const handleSelectDuplicate = useCallback((client: Client) => {
    setSelectedClient(client);
    setStep('options');
  }, []);

  // Handle create new
  const handleCreateNew = useCallback(() => {
    setSelectedClient(null);
    setStep('options');
  }, []);

  // Handle back to duplicates
  const handleBackToDuplicates = useCallback(() => {
    if (duplicates.length > 0) {
      setStep('duplicates');
    }
  }, [duplicates]);

  // Build pipeline options
  const pipelineOptions: SelectOption[] = pipelines.map((p) => ({
    value: p.id,
    label: p.name,
  }));

  // Build stage options for selected pipeline
  const stageOptions: SelectOption[] = stages
    .filter((s) => s.pipelineId === selectedPipeline)
    .sort((a, b) => a.order - b.order)
    .map((s) => ({
      value: s.id,
      label: s.name,
    }));

  // Don't render if no lead
  if (!lead) {
    return null;
  }

  // Dynamic title based on step
  const modalTitle = step === 'duplicates'
    ? 'Existing Contact Found'
    : 'Convert Lead';

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={modalTitle}
      size="md"
      closeOnOverlayClick={!isConverting && !isCheckingDuplicates}
      closeOnEscape={!isConverting && !isCheckingDuplicates}
    >
      {/* Checking for duplicates */}
      {step === 'checking' && (
        <div className="modal-loading">
          <div className="modal-loading__spinner" />
          <p className="modal-loading__text">Checking for existing contacts...</p>
        </div>
      )}

      {/* Duplicate selection */}
      {step === 'duplicates' && (
        <div>
          <div className="duplicate-matches">
            <p className="duplicate-matches__title">
              This lead may already exist as a contact. Select a match to merge, or create a new contact.
            </p>
            <ul className="duplicate-matches__list">
              {duplicates.map((match) => (
                <li
                  key={match.client.id}
                  className={`duplicate-match ${
                    selectedClient?.id === match.client.id ? 'duplicate-match--selected' : ''
                  }`}
                  onClick={() => handleSelectDuplicate(match.client)}
                >
                  <div className="duplicate-match__info">
                    <div className="duplicate-match__name">
                      {match.client.firstName} {match.client.lastName}
                    </div>
                    <div className="duplicate-match__detail">
                      {match.client.email}
                      {match.client.companyName && ` - ${match.client.companyName}`}
                    </div>
                    <div className="duplicate-match__detail">
                      Match: {match.matchType}
                    </div>
                  </div>
                  <span
                    className={`duplicate-match__confidence duplicate-match__confidence--${
                      match.confidence >= 90
                        ? 'high'
                        : match.confidence >= 70
                        ? 'medium'
                        : 'low'
                    }`}
                  >
                    {match.confidence}%
                  </span>
                </li>
              ))}
            </ul>
          </div>

          <div className="form-actions">
            <FormButton type="button" variant="secondary" onClick={handleCreateNew}>
              Create New Contact Instead
            </FormButton>
          </div>
        </div>
      )}

      {/* Conversion options */}
      {step === 'options' && (
        <div>
          {/* Show selected client or new contact info */}
          <FormSection
            title={selectedClient ? 'Link to Existing Contact' : 'Create New Contact'}
          >
            {selectedClient ? (
              <div className="duplicate-match duplicate-match--selected">
                <div className="duplicate-match__info">
                  <div className="duplicate-match__name">
                    {selectedClient.firstName} {selectedClient.lastName}
                  </div>
                  <div className="duplicate-match__detail">
                    {selectedClient.email}
                  </div>
                </div>
                {duplicates.length > 0 && (
                  <FormButton
                    type="button"
                    variant="secondary"
                    onClick={handleBackToDuplicates}
                  >
                    Change
                  </FormButton>
                )}
              </div>
            ) : (
              <div className="duplicate-match">
                <div className="duplicate-match__info">
                  <div className="duplicate-match__name">
                    {lead.firstName} {lead.lastName}
                  </div>
                  <div className="duplicate-match__detail">
                    {lead.email}
                    {lead.companyName && ` - ${lead.companyName}`}
                  </div>
                </div>
                {duplicates.length > 0 && (
                  <FormButton
                    type="button"
                    variant="secondary"
                    onClick={handleBackToDuplicates}
                  >
                    Link Existing
                  </FormButton>
                )}
              </div>
            )}
          </FormSection>

          {/* Deal creation options */}
          <FormSection title="Deal Options">
            <FormField label="" name="createDeal">
              <label className="form-checkbox">
                <input
                  type="checkbox"
                  checked={createDeal}
                  onChange={(e) => setCreateDeal(e.target.checked)}
                />
                <span>Create a deal for this conversion</span>
              </label>
            </FormField>

            {createDeal && (
              <>
                <FormField label="Deal Title" name="dealTitle">
                  <FormInput
                    id="dealTitle"
                    name="dealTitle"
                    value={dealTitle}
                    onChange={(e) => setDealTitle(e.target.value)}
                    placeholder="Enter deal title"
                  />
                </FormField>

                <FormField label="Deal Value ($)" name="dealValue">
                  <FormInput
                    id="dealValue"
                    name="dealValue"
                    type="number"
                    min="0"
                    step="0.01"
                    value={dealValue}
                    onChange={(e) => setDealValue(e.target.value)}
                    placeholder="Enter deal value"
                  />
                </FormField>

                {pipelineOptions.length > 0 && (
                  <FormField label="Pipeline" name="pipeline">
                    <FormSelect
                      id="pipeline"
                      name="pipeline"
                      options={pipelineOptions}
                      value={selectedPipeline}
                      onChange={setSelectedPipeline}
                      placeholder="Select pipeline"
                    />
                  </FormField>
                )}

                {stageOptions.length > 0 && (
                  <FormField label="Stage" name="stage">
                    <FormSelect
                      id="stage"
                      name="stage"
                      options={stageOptions}
                      value={selectedStage}
                      onChange={setSelectedStage}
                      placeholder="Select stage"
                    />
                  </FormField>
                )}
              </>
            )}
          </FormSection>

          {/* Error display */}
          {error && (
            <p className="form-field__error" style={{ marginBottom: 16 }}>
              {error.message}
            </p>
          )}

          <div className="form-actions">
            <FormButton type="button" variant="secondary" onClick={onClose}>
              Cancel
            </FormButton>
            <FormButton
              type="button"
              variant="primary"
              onClick={handleConvert}
              disabled={createDeal && (!selectedPipeline || !selectedStage)}
            >
              Convert Lead
            </FormButton>
          </div>
        </div>
      )}

      {/* Converting */}
      {step === 'converting' && (
        <div className="modal-loading">
          <div className="modal-loading__spinner" />
          <p className="modal-loading__text">Converting lead...</p>
        </div>
      )}
    </Modal>
  );
}

export default ConvertLeadModal;
