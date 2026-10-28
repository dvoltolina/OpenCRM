/**
 * Backfill helper for shareable CRM entities (leads, clients, deals, activities).
 *
 * Usage:
 *   npx tsx scripts/backfill-shareable-ownership.ts --businessId=<biz> --defaultOwnerId=<uid> --defaultOwnerName="<name>" [--teamIds=team-a,team-b] [--visibility=team|org|private] [--dryRun]
 *
 * Notes:
 * - Uses existing ownerId/ownerName if present; otherwise falls back to assigneeId/assigneeName, then defaults.
 * - Sets teamIds to provided list when missing; defaults visibility if absent.
 * - Caller must have permissions; ensure Firebase env is configured.
 */

import { collection, getDocs, updateDoc } from 'firebase/firestore';
import { getFirebaseDb } from '../src/lib/firebase';

interface Args {
  businessId: string | null;
  defaultOwnerId: string | null;
  defaultOwnerName: string;
  teamIds: string[];
  visibility: 'private' | 'team' | 'org';
  dryRun: boolean;
}

function parseArgs(): Args {
  const args = process.argv.slice(2);
  const getArg = (flag: string): string | null => {
    const match = args.find((arg) => arg.startsWith(`${flag}=`));
    return match ? match.split('=')[1] : null;
  };

  const teamIdsRaw = getArg('--teamIds') || process.env.DEFAULT_TEAM_IDS || '';
  const parsedTeams = teamIdsRaw
    .split(',')
    .map((t) => t.trim())
    .filter(Boolean);

  const visibility = (getArg('--visibility') as Args['visibility']) || 'team';

  return {
    businessId: getArg('--businessId'),
    defaultOwnerId: getArg('--defaultOwnerId') || process.env.DEFAULT_OWNER_ID || null,
    defaultOwnerName: getArg('--defaultOwnerName') || process.env.DEFAULT_OWNER_NAME || 'Unknown Owner',
    teamIds: parsedTeams,
    visibility: visibility === 'private' || visibility === 'org' ? visibility : 'team',
    dryRun: args.includes('--dryRun'),
  };
}

type ShareableDoc = {
  ownerId?: string;
  ownerName?: string;
  assigneeId?: string;
  assigneeName?: string;
  createdById?: string;
  createdByName?: string;
  teamIds?: string[];
  visibility?: 'private' | 'team' | 'org';
};

function resolveOwner(data: ShareableDoc, defaults: { id: string; name: string }) {
  const ownerId = data.ownerId || data.assigneeId || data.createdById || defaults.id;
  const ownerName = data.ownerName || data.assigneeName || data.createdByName || defaults.name;
  return { ownerId, ownerName };
}

async function backfillCollection(
  businessId: string,
  collectionName: string,
  defaults: { ownerId: string; ownerName: string; teamIds: string[]; visibility: Args['visibility'] },
  dryRun: boolean
) {
  const db = getFirebaseDb();
  if (!db) {
    console.error('Firebase not configured. Set environment variables.');
    process.exit(1);
  }

  const path = `businesses/${businessId}/${collectionName}`;
  const snapshot = await getDocs(collection(db, path));

  if (snapshot.empty) {
    console.log(`[info] No documents in ${path}`);
    return;
  }

  for (const docSnap of snapshot.docs) {
    const data = docSnap.data() as ShareableDoc;
    const updates: Record<string, unknown> = {};

    const owner = resolveOwner(data, { id: defaults.ownerId, name: defaults.ownerName });
    if (!data.ownerId && owner.ownerId) updates.ownerId = owner.ownerId;
    if (!data.ownerName && owner.ownerName) updates.ownerName = owner.ownerName;

    if (!Array.isArray(data.teamIds)) {
      updates.teamIds = defaults.teamIds;
    }

    if (!data.visibility) {
      updates.visibility = defaults.visibility;
    }

    if (Object.keys(updates).length === 0) {
      console.log(`[skip] ${collectionName}/${docSnap.id} already populated`);
      continue;
    }

    if (dryRun) {
      console.log(`[dry-run] ${collectionName}/${docSnap.id} =>`, updates);
    } else {
      await updateDoc(docSnap.ref, updates);
      console.log(`[update] ${collectionName}/${docSnap.id} updated with`, updates);
    }
  }
}

async function main() {
  const args = parseArgs();
  if (!args.businessId) {
    console.error('Missing required --businessId');
    process.exit(1);
  }
  if (!args.defaultOwnerId) {
    console.error('Missing required --defaultOwnerId (or DEFAULT_OWNER_ID env var)');
    process.exit(1);
  }

  const defaults = {
    ownerId: args.defaultOwnerId,
    ownerName: args.defaultOwnerName,
    teamIds: args.teamIds,
    visibility: args.visibility,
  };

  const targets = ['leads', 'clients', 'deals', 'sales_activities'];

  for (const target of targets) {
    await backfillCollection(args.businessId, target, defaults, args.dryRun);
  }
}

main().catch((err) => {
  console.error('Backfill failed', err);
  process.exit(1);
});
