/**
 * Backfill helper for pipeline ownership/team fields.
 *
 * Usage:
 *   npx tsx scripts/backfill-pipeline-ownership.ts --businessId=<biz> --ownerId=<user> --ownerName="<name>" [--dryRun]
 *
 * Requirements:
 * - Firebase config/env must be loaded (see README/DEPLOYMENT_QUICK_START)
 * - Caller must have permissions to update pipelines
 */

import { collection, getDocs, updateDoc } from 'firebase/firestore';
import { getFirebaseDb } from '../src/lib/firebase';
import { pipelinesCollection } from '../src/lib/collections';

interface Args {
  businessId: string | null;
  ownerId: string | null;
  ownerName: string;
  dryRun: boolean;
}

function parseArgs(): Args {
  const args = process.argv.slice(2);
  const getArg = (flag: string): string | null => {
    const match = args.find((arg) => arg.startsWith(`${flag}=`));
    return match ? match.split('=')[1] : null;
  };

  return {
    businessId: getArg('--businessId'),
    ownerId: getArg('--ownerId') || process.env.DEFAULT_OWNER_ID || null,
    ownerName: getArg('--ownerName') || process.env.DEFAULT_OWNER_NAME || 'Unknown Owner',
    dryRun: args.includes('--dryRun'),
  };
}

async function main() {
  const { businessId, ownerId, ownerName, dryRun } = parseArgs();
  if (!businessId) {
    console.error('Missing required --businessId');
    process.exit(1);
  }

  if (!ownerId) {
    console.error('Missing required --ownerId (or DEFAULT_OWNER_ID env var)');
    process.exit(1);
  }

  const db = getFirebaseDb();
  if (!db) {
    console.error('Firebase not configured. Ensure env vars are set.');
    process.exit(1);
  }

  const pipelinePath = pipelinesCollection(businessId);
  const snapshot = await getDocs(collection(db, pipelinePath));

  if (snapshot.empty) {
    console.log(`No pipelines found for business ${businessId}`);
    return;
  }

  for (const docSnap of snapshot.docs) {
    const data = docSnap.data();
    const updates: Record<string, unknown> = {};

    if (!data.ownerId) {
      updates.ownerId = ownerId;
    }

    if (!data.ownerName) {
      updates.ownerName = ownerName;
    }

    if (!Array.isArray(data.teamIds)) {
      updates.teamIds = [];
    }

    if (Object.keys(updates).length === 0) {
      console.log(`[skip] ${docSnap.id} already has ownership fields`);
      continue;
    }

    if (dryRun) {
      console.log(`[dry-run] Would update pipeline ${docSnap.id}:`, updates);
    } else {
      await updateDoc(docSnap.ref, updates);
      console.log(`[update] Pipeline ${docSnap.id} updated with`, updates);
    }
  }
}

main().catch((err) => {
  console.error('Backfill failed', err);
  process.exit(1);
});
