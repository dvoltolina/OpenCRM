import type { Client, Company, Deal } from '../../types/models';
import type { Document } from '../../types/documents';
import { DetailSection } from './DetailSection';
import { DocumentUploader } from '../documents/DocumentUploader';
import { DocumentList } from '../documents/DocumentList';
import { ProposalFlow } from '../documents/ProposalFlow';

interface DealDocumentsTabProps {
  deal: Deal;
  documents: Document[];
  isLoading: boolean;
  onUpload: (file: File, options: { name: string; documentType: Document['documentType'] }) => Promise<void> | void;
  onRefresh: () => void;
  client?: Client | null;
  company?: Company | null;
  refreshDeal?: () => void;
}

export function DealDocumentsTab({
  deal,
  documents,
  isLoading,
  onUpload,
  onRefresh,
  client,
  company,
  refreshDeal,
}: DealDocumentsTabProps) {
  return (
    <DetailSection title="Documents">
      <div className="deal-documents-grid">
        <div className="deal-documents-column">
          <DocumentUploader
            associatedEntity={{ type: 'deal', id: deal.id }}
            onUpload={(file, { name, documentType }) =>
              onUpload(file, {
                name,
                documentType,
              })
            }
          />
          <DocumentList
            documents={documents}
            isLoading={isLoading}
            onRefresh={onRefresh}
            emptyMessage="Link deal files from the Documents hub or generate a proposal to see it here."
          />
        </div>
        <div className="deal-documents-column">
          <ProposalFlow
            deal={deal}
            client={client}
            company={company}
            documents={documents}
            onRefreshDocuments={onRefresh}
            refreshDeal={refreshDeal}
            isLoadingDocuments={isLoading}
          />
        </div>
      </div>
    </DetailSection>
  );
}
