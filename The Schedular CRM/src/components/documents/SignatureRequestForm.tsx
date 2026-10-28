import { useState, type FormEvent } from 'react';
import type { DocumentSigner } from '../../types/documents';

interface SignatureRequestFormProps {
  onSend: (signers: Array<Omit<DocumentSigner, 'id' | 'status'>>) => Promise<void> | void;
  isSubmitting?: boolean;
  defaultMessage?: string;
}

export function SignatureRequestForm({ onSend, isSubmitting, defaultMessage }: SignatureRequestFormProps) {
  const [signers, setSigners] = useState<Array<Omit<DocumentSigner, 'id' | 'status'>>>([
    { name: '', email: '', role: 'client', order: 1 },
  ]);
  const [message, setMessage] = useState(defaultMessage || '');
  const [error, setError] = useState<string | null>(null);

  const handleSignerChange = (index: number, field: keyof DocumentSigner, value: string | number) => {
    setSigners((prev) => {
      const updated = [...prev];
      updated[index] = { ...updated[index], [field]: value };
      return updated;
    });
  };

  const addSigner = () => {
    setSigners((prev) => [...prev, { name: '', email: '', role: 'client', order: prev.length + 1 }]);
  };

  const removeSigner = (index: number) => {
    setSigners((prev) => prev.filter((_, i) => i !== index));
  };

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setError(null);
    try {
      await onSend(signers);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to send for signature');
    }
  };

  return (
    <form className="signature-request-form" onSubmit={handleSubmit}>
      <h4>Send for Signature</h4>
      {signers.map((signer, index) => (
        <div className="signer-row" key={index}>
          <input
            placeholder="Name"
            value={signer.name}
            onChange={(e) => handleSignerChange(index, 'name', e.target.value)}
            required
          />
          <input
            placeholder="Email"
            type="email"
            value={signer.email}
            onChange={(e) => handleSignerChange(index, 'email', e.target.value)}
            required
          />
          <input
            placeholder="Role (e.g., client)"
            value={signer.role}
            onChange={(e) => handleSignerChange(index, 'role', e.target.value)}
          />
          {signers.length > 1 && (
            <button type="button" onClick={() => removeSigner(index)} aria-label="Remove signer">
              Remove
            </button>
          )}
        </div>
      ))}
      <div className="signature-controls">
        <button type="button" onClick={addSigner}>
          + Add signer
        </button>
      </div>
      <label>
        Message to signers
        <textarea value={message} onChange={(e) => setMessage(e.target.value)} />
      </label>
      {error && <p className="signature-error">{error}</p>}
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Sending...' : 'Send for signature'}
      </button>
    </form>
  );
}
