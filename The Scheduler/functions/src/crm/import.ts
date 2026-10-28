/**
 * crm-import
 * Minimal, guarded CSV import for leads only. Disabled unless CRM_IMPORT_ENABLED=true.
 * Validates auth and businessId; enforces small batch size; ignores PHI fields.
 */

import {onRequest} from "firebase-functions/v2/https";
import {auth, db, FieldValue} from "../firebaseAdmin";
import {applyCors} from "../httpUtils";

const IMPORT_ENABLED = process.env.CRM_IMPORT_ENABLED === "true";
const MAX_ROWS = 200;

function parseCsv(body: string): string[][] {
  return body
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => line.split(",").map((cell) => cell.replace(/^"|"$/g, "")));
}

export const crmImport = onRequest(async (req, res) => {
  applyCors(req, res);

  if (!IMPORT_ENABLED) {
    res.status(503).json({error: "Import disabled", message: "Set CRM_IMPORT_ENABLED=true to enable"});
    return;
  }

  const authHeader = req.headers.authorization || "";
  const token = authHeader.startsWith("Bearer ") ?
    authHeader.replace("Bearer ", "") :
    null;

  if (!token) {
    res.status(401).json({error: "Unauthorized"});
    return;
  }

  let decoded;
  try {
    decoded = await auth.verifyIdToken(token);
  } catch {
    res.status(401).json({error: "Unauthorized"});
    return;
  }

  const businessIdClaim = (decoded as {businessId?: string}).businessId;
  const businessId = (req.query.businessId as string) || businessIdClaim;
  if (!businessId) {
    res.status(400).json({error: "businessId required"});
    return;
  }

  const entity = (req.query.entity as string) || "leads";
  if (entity !== "leads") {
    res.status(400).json({error: "Only leads import supported"});
    return;
  }

  const raw = req.rawBody?.toString("utf8") || "";
  if (!raw) {
    res.status(400).json({error: "CSV body required"});
    return;
  }

  const rows = parseCsv(raw);
  if (rows.length < 2) {
    res.status(400).json({error: "No data rows"});
    return;
  }

  const [header, ...dataRows] = rows;
  const allowedFields = ["firstName", "lastName", "email", "status", "source"];
  const fieldIndexes = allowedFields.map((f) => header.indexOf(f));
  const invalidHeader = fieldIndexes.some((idx) => idx === -1);
  if (invalidHeader) {
    res.status(400).json({error: "Missing required headers: firstName,lastName,email,status,source"});
    return;
  }

  const limitedRows = dataRows.slice(0, MAX_ROWS);
  const batch = db.batch();
  const col = db.collection(`businesses/${businessId}/leads`);

  limitedRows.forEach((row) => {
    const doc = col.doc();
    const lead = {
      firstName: row[fieldIndexes[0]] || "",
      lastName: row[fieldIndexes[1]] || "",
      email: row[fieldIndexes[2]] || "",
      status: row[fieldIndexes[3]] || "new",
      source: row[fieldIndexes[4]] || "other",
      tags: [],
      createdAt: FieldValue.serverTimestamp(),
    };
    batch.set(doc, lead);
  });

  await batch.commit();

  res.status(200).json({
    success: true,
    imported: limitedRows.length,
    skipped: Math.max(dataRows.length - limitedRows.length, 0),
    message: "Import completed (leads only, PHI-safe fields).",
  });
});
