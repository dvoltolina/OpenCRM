#!/usr/bin/env node
/**
 * Backfills structured operatingHours for locations that only have a display string.
 * Requires GOOGLE_APPLICATION_CREDENTIALS or gcloud auth; run with:
 *   FIREBASE_PROJECT_ID=your-project-id node scripts/backfill-location-hours.mjs
 */
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const DAY_ORDER = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

const DEFAULT_OPERATING_HOURS = DAY_ORDER.map((day) => ({
  day,
  isOpen: !['saturday', 'sunday'].includes(day),
  blocks: !['saturday', 'sunday'].includes(day) ? [{ start: '09:00', end: '17:00' }] : [],
}));

const cloneHours = (hours) =>
  hours.map((day) => ({
    day: day.day,
    isOpen: Boolean(day.isOpen),
    blocks: (day.blocks || []).map((b) => ({ start: b.start, end: b.end })),
  }));

const formatHours = (hours) => {
  const openDays = hours.filter((d) => d.isOpen);
  if (!openDays.length) return 'Closed';
  return openDays
    .map((day) => {
      const blocks = (day.blocks || []).filter((b) => b.start && b.end);
      const label = day.day?.slice(0, 3) ?? 'Day';
      return blocks.length ? `${label} ${blocks.map((b) => `${b.start}-${b.end}`).join(', ')}` : label;
    })
    .join(' | ');
};

async function backfill() {
  const projectId = process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT;
  if (!projectId) {
    throw new Error('Set FIREBASE_PROJECT_ID so the script knows which project to target.');
  }

  initializeApp({
    credential: applicationDefault(),
    projectId,
  });

  const db = getFirestore();
  const snap = await db.collectionGroup('locations').get();

  let updated = 0;
  let skipped = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.operatingHours && Array.isArray(data.operatingHours) && data.operatingHours.length) {
      skipped += 1;
      continue;
    }
    const operatingHours = cloneHours(DEFAULT_OPERATING_HOURS);
    const hours = formatHours(operatingHours);
    await doc.ref.set(
      {
        operatingHours,
        hours,
        updatedAt: new Date().toISOString(),
      },
      { merge: true },
    );
    updated += 1;
  }

  console.log(
    `Backfill complete. Updated ${updated} location(s). Skipped ${skipped} already populated location(s).`,
  );
}

backfill().catch((err) => {
  console.error('Backfill failed:', err);
  process.exit(1);
});
