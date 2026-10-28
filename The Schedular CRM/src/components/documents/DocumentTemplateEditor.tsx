import { useEffect, useState, type FormEvent } from 'react';
import type { DocumentTemplate, DocumentType } from '../../types/documents';

interface DocumentTemplateEditorProps {
  template?: DocumentTemplate;
  onSave: (template: Partial<DocumentTemplate>) => void;
  onCancel?: () => void;
}

const DEFAULT_TYPE: DocumentType = 'contract';

export function DocumentTemplateEditor({ template, onSave, onCancel }: DocumentTemplateEditorProps) {
  const [name, setName] = useState(template?.name || '');
  const [description, setDescription] = useState(template?.description || '');
  const [documentType, setDocumentType] = useState<DocumentType>(template?.documentType || DEFAULT_TYPE);
  const [category, setCategory] = useState(template?.category || 'general');
  const [requiresSignature, setRequiresSignature] = useState(template?.requiresSignature ?? false);

  useEffect(() => {
    if (template) {
      setName(template.name);
      setDescription(template.description || '');
      setDocumentType(template.documentType);
      setCategory(template.category);
      setRequiresSignature(template.requiresSignature);
    }
  }, [template]);

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();
    onSave({
      ...template,
      name,
      description,
      documentType,
      category,
      requiresSignature,
    });
  };

  return (
    <form className="document-template-editor" onSubmit={handleSubmit}>
      <h3>{template ? 'Edit Template' : 'New Template'}</h3>
      <label>
        Name
        <input value={name} onChange={(e) => setName(e.target.value)} required />
      </label>
      <label>
        Description
        <textarea value={description} onChange={(e) => setDescription(e.target.value)} />
      </label>
      <label>
        Document Type
        <select value={documentType} onChange={(e) => setDocumentType(e.target.value as DocumentType)}>
          <option value="contract">Contract</option>
          <option value="proposal">Proposal</option>
          <option value="quote">Quote</option>
          <option value="invoice">Invoice</option>
          <option value="agreement">Agreement</option>
          <option value="attachment">Attachment</option>
          <option value="other">Other</option>
        </select>
      </label>
      <label>
        Category
        <input value={category} onChange={(e) => setCategory(e.target.value)} />
      </label>
      <label className="checkbox">
        <input
          type="checkbox"
          checked={requiresSignature}
          onChange={(e) => setRequiresSignature(e.target.checked)}
        />
        Requires signature
      </label>

      <div className="template-editor-actions">
        <button type="submit">Save Template</button>
        {onCancel && (
          <button type="button" onClick={onCancel}>
            Cancel
          </button>
        )}
      </div>
    </form>
  );
}
