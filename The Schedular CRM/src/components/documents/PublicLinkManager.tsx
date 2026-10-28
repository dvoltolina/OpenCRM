import { useState } from 'react';

interface PublicLinkManagerProps {
  publicLinkToken?: string;
  expiresAt?: Date;
  onGenerate: (expiresInDays?: number) => Promise<void> | void;
  onRevoke: () => Promise<void> | void;
  isLoading?: boolean;
}

export function PublicLinkManager({
  publicLinkToken,
  expiresAt,
  onGenerate,
  onRevoke,
  isLoading,
}: PublicLinkManagerProps) {
  const [expiresInDays, setExpiresInDays] = useState(7);
  const urlDisplay = publicLinkToken ? `Public link token: ${publicLinkToken}` : 'No public link';

  const handleGenerate = async () => {
    await onGenerate(expiresInDays);
  };

  return (
    <div className="public-link-manager">
      <h4>Public Link</h4>
      <p>{urlDisplay}</p>
      {expiresAt && <p>Expires: {new Date(expiresAt).toLocaleString()}</p>}

      <div className="public-link-actions">
        <label>
          Expires in (days)
          <input
            type="number"
            min={1}
            value={expiresInDays}
            onChange={(e) => setExpiresInDays(Number(e.target.value) || 1)}
          />
        </label>
        <button type="button" onClick={handleGenerate} disabled={isLoading}>
          {isLoading ? 'Generating...' : 'Generate link'}
        </button>
        {publicLinkToken && (
          <button type="button" onClick={() => onRevoke()} disabled={isLoading}>
            Revoke link
          </button>
        )}
      </div>
    </div>
  );
}
