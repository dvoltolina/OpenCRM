import { resolveTeamIds, sanitizeTeamIds } from './security-context';

export type ApprovalDecision = 'approved' | 'denied' | 'pending';

export interface ApprovalMetadataInput {
  approvalType?: string;
  requestType?: string;
  status?: string;
  decision?: ApprovalDecision;
  sourceAuditId?: string;
  teamIds?: string[];
  managedTeamIds?: string[];
  contextTeamIds?: string[];
  contextManagedTeamIds?: string[];
}

export function buildApprovalMetadata(input: ApprovalMetadataInput) {
  const approvalType = input.approvalType || input.requestType || 'approval';
  const decision = input.decision;
  const status = input.status || decision || 'pending';

  const teamIds = resolveTeamIds([
    ...(sanitizeTeamIds(input.teamIds || [])),
    ...(sanitizeTeamIds(input.contextTeamIds || [])),
  ]);

  const managedTeamIds = resolveTeamIds([
    ...(sanitizeTeamIds(input.managedTeamIds || [])),
    ...(sanitizeTeamIds(input.contextManagedTeamIds || [])),
  ]);

  return {
    category: 'managerApproval',
    approvalType,
    requestType: input.requestType || approvalType,
    status,
    decision,
    sourceAuditId: input.sourceAuditId,
    teamIds,
    managedTeamIds,
  };
}
