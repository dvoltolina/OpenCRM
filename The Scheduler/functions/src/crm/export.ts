/**
 * crm-export
 * HTTP endpoint for CRM exports. Currently supports CSV for basic entities.
 * This implementation is conservative: limited fields, business scoping, and small limits.
 * Enhance with PDF/advanced filtering as needed.
 */

import {onRequest} from "firebase-functions/v2/https";
import {auth, db} from "../firebaseAdmin";
import {applyCors} from "../httpUtils";

type ExportEntity = "leads" | "deals" | "activities" | "companies";

const ENTITY_COLLECTIONS: Record<ExportEntity, string> = {
  leads: "leads",
  deals: "deals",
  activities: "sales_activities",
  companies: "companies",
};

const SAFE_FIELDS: Record<ExportEntity, string[]> = {
  leads: ["id", "firstName", "lastName", "email", "status", "source", "createdAt"],
  deals: ["id", "title", "valueCents", "status", "stageId", "clientName", "createdAt"],
  activities: ["id", "type", "title", "isCompleted", "createdAt"],
  companies: ["id", "name", "industry", "size", "website", "createdAt"],
};

function toCsv(rows: Record<string, unknown>[]) {
  if (!rows.length) return "";
  const headers = Object.keys(rows[0]);
  const lines = rows.map((row) =>
    headers.map((h) => JSON.stringify(row[h] ?? "")).join(","),
  );
  return [headers.join(","), ...lines].join("\n");
}

export const crmExport = onRequest(async (req, res) => {
  applyCors(req, res);

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
  const entity = (req.query.entity as ExportEntity) || "leads";
  const limit = Math.min(Number(req.query.limit) || 1000, 2000);

  if (!businessId) {
    res.status(400).json({error: "businessId required"});
    return;
  }

  if (!Object.keys(ENTITY_COLLECTIONS).includes(entity)) {
    res.status(400).json({error: "Unsupported entity"});
    return;
  }

  try {
    const collectionPath = `businesses/${businessId}/${ENTITY_COLLECTIONS[entity]}`;
    const snap = await db.collection(collectionPath).limit(limit).get();
    const rows = snap.docs.map((d) => {
      const data = d.data();
      const safe = SAFE_FIELDS[entity];
      const out: Record<string, unknown> = {};
      safe.forEach((field) => {
        const value = data[field];
        if (value && typeof value.toDate === "function") {
          out[field] = value.toDate().toISOString();
        } else {
          out[field] = value ?? "";
        }
      });
      out.id = d.id;
      return out;
    });

    const csv = toCsv(rows);
    res.setHeader("Content-Type", "text/csv");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="${entity}-export-${businessId}.csv"`,
    );
    res.status(200).send(csv);
  } catch (err) {
    res.status(500).json({error: "Export failed", message: (err as Error).message});
  }
});
