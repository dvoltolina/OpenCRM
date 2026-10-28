import test from "node:test";
import assert from "node:assert/strict";
import {parseLeadConversionRequest} from "../src/crm/leadsConvert";
import {parseMetricsRequest} from "../src/crm/metrics";
import {buildStageChangeActivityPayload} from "../src/crm/stageChange";
import {HttpError} from "../src/crm/utils";
import {runImport} from "../src/importer";

class FakeCollection {
  private readonly records = new Map<string, Record<string, unknown>>();

  seed(docs: Array<Record<string, unknown> & {id?: string}>) {
    docs.forEach((doc) => {
      const id = typeof doc.id === "string" ? doc.id : `doc_${Math.random().toString(36).slice(2, 8)}`;
      this.records.set(id, {...doc, id});
    });
  }

  limit(n: number) {
    return {
      get: async () => ({
        docs: Array.from(this.records.entries()).slice(0, n).map(([id, data]) => ({
          id,
          data: () => data,
        })),
      }),
    };
  }

  doc(id?: string) {
    const docId = id || `doc_${Math.random().toString(36).slice(2, 8)}`;
    return {
      id: docId,
      set: async (data: Record<string, unknown>, options?: {merge?: boolean}) => {
        const existing = this.records.get(docId) || {id: docId};
        this.records.set(docId, options?.merge ? {...existing, ...data} : {...data, id: docId});
      },
    };
  }

  getAll() {
    return Array.from(this.records.values());
  }
}

class FakeBusinessDocument {
  constructor(private readonly businessId: string, private readonly collections: Map<string, FakeCollection>) {}

  collection(name: string) {
    const key = `${this.businessId}/${name}`;
    if (!this.collections.has(key)) {
      this.collections.set(key, new FakeCollection());
    }
    return this.collections.get(key)!;
  }
}

class FakeFirestore {
  private readonly businesses = new Map<string, Map<string, FakeCollection>>();

  collection(name: string) {
    if (name !== "businesses") {
      throw new Error(`Unsupported collection ${name}`);
    }

    return {
      doc: (businessId: string) => {
        if (!this.businesses.has(businessId)) {
          this.businesses.set(businessId, new Map());
        }
        return new FakeBusinessDocument(businessId, this.businesses.get(businessId)!);
      },
    };
  }

  seed(name: string, businessId: string, docs: Array<Record<string, unknown> & {id?: string}>) {
    const businessDoc = this.collection("businesses").doc(businessId);
    businessDoc.collection(name).seed(docs);
  }

  getCollectionData(name: string, businessId: string) {
    const businessCollections = this.businesses.get(businessId);
    return businessCollections?.get(`${businessId}/${name}`)?.getAll() || [];
  }
}

test("parseLeadConversionRequest requires ids", () => {
  assert.throws(
    () => parseLeadConversionRequest({businessId: "abc123"}),
    (error) => error instanceof HttpError && error.status === 400
  );
});

test("parseLeadConversionRequest validates deal payload", () => {
  const payload = parseLeadConversionRequest({
    businessId: "business-123",
    leadId: "lead-123",
    createDeal: true,
    pipelineId: "pipeline-1",
    stageId: "stage-1",
    valueCents: 5000,
  });

  assert.equal(payload.createDeal, true);
  assert.equal(payload.deal?.pipelineId, "pipeline-1");
  assert.equal(payload.deal?.stageId, "stage-1");
  assert.equal(payload.deal?.valueCents, 5000);
});

test("parseMetricsRequest clamps defaults safely", () => {
  const payload = parseMetricsRequest({businessId: "business-123"});
  assert.equal(payload.rangeDays, 30);
  assert.equal(payload.activityLimit, 10);
});

test("buildStageChangeActivityPayload captures stage delta", () => {
  const payload = buildStageChangeActivityPayload(
    {stageId: "stage-old"},
    {stageId: "stage-new", clientId: "client-1"},
    "deal-1"
  );

  assert.equal(payload.dealId, "deal-1");
  assert.equal(
    (payload.metadata as Record<string, unknown>).fromStage,
    "stage-old"
  );
  assert.equal(
    (payload.metadata as Record<string, unknown>).toStage,
    "stage-new"
  );
  assert.equal(payload.type, "note");
});

test("runImport skips invalid rows but still imports valid rows", async () => {
  const db = new FakeFirestore();

  const result = await runImport(db as any, {
    entityType: "lead",
    headers: ["name", "email"],
    rows: [["Alice Example", "alice@example.com"], ["", "broken@example.com"]],
    fieldMapping: {name: "fullName", email: "email"},
    businessId: "business-1",
    duplicateHandling: "skip",
    ownerId: "owner-1",
    ownerName: "Owner One",
    teamIds: ["team-a", "team-a", " "],
  });

  assert.equal(result.imported, 1);
  assert.equal(result.skipped, 1);
  assert.equal(result.validationErrors.length, 1);
  assert.equal(result.errors, undefined);

  const stored = db.getCollectionData("leads", "business-1");
  assert.equal(stored.length, 1);
  assert.equal(stored[0].ownerId, "owner-1");
  assert.equal(stored[0].ownerName, "Owner One");
  assert.deepEqual(stored[0].teamIds, ["team-a"]);
  assert.equal(stored[0].visibility, "team");
});

test("runImport honors update duplicate handling even when identifiers are preloaded", async () => {
  const db = new FakeFirestore();
  db.seed("leads", "business-1", [
    {id: "lead-1", email: "dup@example.com", phone: "1111111", firstName: "Old"},
  ]);

  const result = await runImport(db as any, {
    entityType: "lead",
    headers: ["name", "email", "phone"],
    rows: [["Updated Lead", "dup@example.com", "(222) 222-2222"]],
    fieldMapping: {name: "fullName", email: "email", phone: "phone"},
    businessId: "business-1",
    duplicateHandling: "update",
    existingIdentifiers: {
      emails: ["dup@example.com"],
      phones: ["1111111"],
    },
    ownerId: "owner-1",
    teamIds: ["team-a"],
  });

  assert.equal(result.imported, 1);
  assert.equal(result.skipped, 0);
  assert.equal(result.validationErrors.length, 0);

  const stored = db.getCollectionData("leads", "business-1");
  assert.equal(stored.length, 1);
  assert.equal(stored[0].firstName, "Updated");
  assert.equal(stored[0].lastName, "Lead");
  assert.equal(stored[0].phone, "2222222222");
});

test("runImport defaults client lifecycle for contract-aligned imports", async () => {
  const db = new FakeFirestore();

  const result = await runImport(db as any, {
    entityType: "client",
    headers: ["first", "last", "email"],
    rows: [["Jamie", "Client", "jamie@example.com"]],
    fieldMapping: {first: "firstName", last: "lastName", email: "email"},
    businessId: "business-1",
    duplicateHandling: "skip",
    ownerId: "owner-1",
    teamIds: ["team-a"],
  });

  assert.equal(result.imported, 1);
  const stored = db.getCollectionData("clients", "business-1");
  assert.equal(stored[0].lifecycle, "active");
  assert.equal(stored[0].ownerId, "owner-1");
});

test("runImport stores contact imports in clients with shared ownership metadata", async () => {
  const db = new FakeFirestore();

  const result = await runImport(db as any, {
    entityType: "contact",
    headers: ["name", "email"],
    rows: [["Morgan Lee", "morgan@example.com"]],
    fieldMapping: {name: "firstName", email: "email"},
    businessId: "business-1",
    duplicateHandling: "skip",
    ownerId: "owner-1",
    ownerName: "Owner One",
    teamIds: ["team-a"],
  });

  assert.equal(result.imported, 1);
  assert.equal(result.skipped, 0);
  assert.equal(result.validationErrors.length, 0);

  const stored = db.getCollectionData("clients", "business-1");
  assert.equal(stored[0].firstName, "Morgan");
  assert.equal(stored[0].lastName, "Lee");
  assert.equal(stored[0].lifecycle, "prospect");
  assert.equal(stored[0].ownerId, "owner-1");
  assert.equal(stored[0].ownerName, "Owner One");
  assert.deepEqual(stored[0].teamIds, ["team-a"]);
  assert.equal(stored[0].visibility, "team");
});

test("runImport mirrors imported leads into clients for shared contact visibility", async () => {
  const db = new FakeFirestore();

  const result = await runImport(db as any, {
    entityType: "lead",
    headers: ["first", "last", "email", "phone", "company"],
    rows: [["Avery", "Stone", "avery@example.com", "(303) 555-1212", "Northwind"]],
    fieldMapping: {
      first: "firstName",
      last: "lastName",
      email: "email",
      phone: "phone",
      company: "companyName",
    },
    businessId: "business-1",
    duplicateHandling: "skip",
    ownerId: "owner-1",
    ownerName: "Owner One",
    teamIds: ["team-a"],
  });

  assert.equal(result.imported, 1);
  assert.equal(result.skipped, 0);

  const leads = db.getCollectionData("leads", "business-1");
  assert.equal(leads.length, 1);
  assert.equal(leads[0].email, "avery@example.com");

  const clients = db.getCollectionData("clients", "business-1");
  assert.equal(clients.length, 1);
  assert.equal(clients[0].firstName, "Avery");
  assert.equal(clients[0].lastName, "Stone");
  assert.equal(clients[0].email, "avery@example.com");
  assert.equal(clients[0].phone, "3035551212");
  assert.equal(clients[0].companyName, "Northwind");
  assert.equal(clients[0].lifecycle, "lead");
  assert.equal(clients[0].leadStatus, "New");
  assert.equal(clients[0].leadSource, "other");
  assert.equal(clients[0].ownerId, "owner-1");
  assert.deepEqual(clients[0].teamIds, ["team-a"]);
});
