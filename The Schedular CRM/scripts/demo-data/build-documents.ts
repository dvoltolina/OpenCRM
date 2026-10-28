import { buildCrmAndAdminDocuments } from './crm-admin-data';
import { type DocEntry } from './common';
import { buildSharedSchedulerDocuments } from './scheduler-data';

export function buildDemoDocuments(): DocEntry[] {
  const docs: DocEntry[] = [];
  buildSharedSchedulerDocuments(docs);
  buildCrmAndAdminDocuments(docs);
  return docs;
}
