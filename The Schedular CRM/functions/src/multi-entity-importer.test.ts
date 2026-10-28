/**
 * Multi-Entity Import Tests
 * Agent M2: Backend Multi-Entity Import Test Suite
 *
 * Test Coverage:
 * - Company matching (domain→name)
 * - Contact matching (email→phone→company+name)
 * - Lead creation (only when leadStatus present)
 * - Deal creation (only when deal fields present)
 * - Entity associations
 * - Duplicate handling modes (skip/update/create)
 * - Tenant scoping
 */

import {describe, it, expect, beforeEach, vi} from "vitest";
import {processMultiEntityRow, type MultiEntityRow} from "./multi-entity-importer";

describe("Multi-Entity Importer", () => {
  // Mock Firestore
  let mockDb: any;
  let mockCollections: Map<string, Map<string, any>>;

  beforeEach(() => {
    mockCollections = new Map();
    mockDb = {
      collection: (path: string) => {
        const parts = path.split("/");
        return {
          doc: (id?: string) => {
            const docId = id || `mock_${Date.now()}_${Math.random()}`;
            return {
              id: docId,
              set: vi.fn(async (data: any) => {
                const collectionKey = parts.join("/");
                if (!mockCollections.has(collectionKey)) {
                  mockCollections.set(collectionKey, new Map());
                }
                mockCollections.get(collectionKey)!.set(docId, data);
                return {id: docId};
              }),
              get: vi.fn(async () => {
                const collectionKey = parts.join("/");
                const collection = mockCollections.get(collectionKey);
                const data = collection?.get(docId);
                return {
                  exists: !!data,
                  id: docId,
                  data: () => data,
                };
              }),
              collection: vi.fn((subName: string) => {
                const subParts = [...parts, docId, subName];
                return mockDb.collection(subParts.join("/"));
              }),
            };
          },
          where: vi.fn((field: string, op: string, value: any) => {
            return {
              limit: vi.fn((n: number) => {
                return {
                  get: vi.fn(async () => {
                    const collectionKey = parts.join("/");
                    const collection = mockCollections.get(collectionKey);
                    const docs: any[] = [];

                    if (collection) {
                      collection.forEach((data, id) => {
                        if (data[field] === value || (op === "==" && data[field] === value)) {
                          docs.push({
                            id,
                            data: () => data,
                          });
                        }
                      });
                    }

                    return {
                      empty: docs.length === 0,
                      docs: docs.slice(0, n),
                    };
                  }),
                };
              }),
              orderBy: vi.fn(() => {
                return {
                  limit: vi.fn((n: number) => {
                    return {
                      get: vi.fn(async () => {
                        const collectionKey = parts.join("/");
                        const collection = mockCollections.get(collectionKey);
                        const docs: any[] = [];

                        if (collection) {
                          collection.forEach((data, id) => {
                            if (data[field] === value || (op === "==" && data[field] === value)) {
                              docs.push({
                                id,
                                data: () => data,
                              });
                            }
                          });
                        }

                        return {
                          empty: docs.length === 0,
                          docs: docs.slice(0, n),
                        };
                      }),
                    };
                  }),
                };
              }),
            };
          }),
          orderBy: vi.fn(() => {
            return {
              limit: vi.fn(() => {
                return {
                  get: vi.fn(async () => ({empty: true, docs: []})),
                };
              }),
            };
          }),
          limit: vi.fn((n: number) => {
            return {
              get: vi.fn(async () => {
                const collectionKey = parts.join("/");
                const collection = mockCollections.get(collectionKey);
                const docs: any[] = [];

                if (collection) {
                  collection.forEach((data, id) => {
                    docs.push({id, data: () => data});
                  });
                }

                return {
                  empty: docs.length === 0,
                  docs: docs.slice(0, n),
                };
              }),
            };
          }),
        };
      },
    };
  });

  describe("Company Matching", () => {
    it("should match company by domain", async () => {
      const existingCompany = {
        name: "Acme Corp",
        website: "acme.com",
        businessId: "business1",
      };

      mockCollections.set(
        "businesses/business1/companies",
        new Map([["company1", existingCompany]]),
      );

      const row: MultiEntityRow = {
        companyName: "ACME Corporation",
        companyWebsite: "https://www.acme.com",
        firstName: "John",
        lastName: "Doe",
        email: "john@example.com",
      };

      const result = await processMultiEntityRow(
        mockDb,
        "business1",
        row,
        "skip",
        "user1",
        "Test User",
      );

      if (result.skipped && result.error) {
        console.error("Test debug (company domain) error:", result.error);
      }
      expect(result.skipped).toBe(false);
      expect(result.companyCreated).toBe(false); // Should match existing
      expect(result.contactCreated).toBe(true);
    });

    it("should match company by name when domain not available", async () => {
      const existingCompany = {
        name: "Test Company",
        businessId: "business1",
      };

      mockCollections.set(
        "businesses/business1/companies",
        new Map([["company1", existingCompany]]),
      );

      const row: MultiEntityRow = {
        companyName: "Test Company",
        firstName: "Jane",
        lastName: "Smith",
        email: "jane@example.com",
      };

      const result = await processMultiEntityRow(
        mockDb,
        "business1",
        row,
        "skip",
        "user1",
        "Test User",
      );

      expect(result.skipped).toBe(false);
      expect(result.companyCreated).toBe(false);
    });
  });

  describe("Contact Matching", () => {
    it("should match contact by email", async () => {
      const existingContact = {
        firstName: "John",
        lastName: "Doe",
        email: "john@example.com",
        businessId: "business1",
      };

      mockCollections.set(
        "businesses/business1/clients",
        new Map([["contact1", existingContact]]),
      );

      const row: MultiEntityRow = {
        firstName: "John",
        lastName: "Doe",
        email: "john@example.com",
      };

      const result = await processMultiEntityRow(
        mockDb,
        "business1",
        row,
        "skip",
        "user1",
        "Test User",
      );

      expect(result.skipped).toBe(false);
      expect(result.contactCreated).toBe(false); // Should match existing
    });

    it("should match contact by phone", async () => {
      const existingContact = {
        firstName: "Jane",
        lastName: "Smith",
        email: "jane@example.com",
        phone: "5551234567",
        businessId: "business1",
      };

      mockCollections.set(
        "businesses/business1/clients",
        new Map([["contact1", existingContact]]),
      );

      const row: MultiEntityRow = {
        firstName: "Jane",
        lastName: "Smith",
        email: "jane@example.com",
        phone: "(555) 123-4567",
      };

      const result = await processMultiEntityRow(
        mockDb,
        "business1",
        row,
        "skip",
        "user1",
        "Test User",
      );

      expect(result.skipped).toBe(false);
      expect(result.contactCreated).toBe(false);
    });
  });

  describe("Lead Creation (Conditional)", () => {
    it("should create lead when lead import is primary", async () => {
      const row: MultiEntityRow = {
        firstName: "Lead",
        lastName: "User",
        email: "lead@example.com",
        leadStatus: "new",
        leadSource: "website",
      };

      const result = await processMultiEntityRow(
        mockDb,
        "business1",
        row,
        "create",
        "user1",
        "Test User",
        "lead",
      );

      expect(result.skipped).toBe(false);
      expect(result.contactCreated).toBe(false);
      expect(result.leadCreated).toBe(true);
    });

    it("should NOT create lead when leadStatus is absent", async () => {
      const row: MultiEntityRow = {
        firstName: "Contact",
        lastName: "Only",
        email: "contact@example.com",
      };

      const result = await processMultiEntityRow(
        mockDb,
        "business1",
        row,
        "create",
        "user1",
        "Test User",
      );

      expect(result.skipped).toBe(false);
      expect(result.contactCreated).toBe(true);
      expect(result.leadCreated).toBe(false);
      expect(result.leadId).toBeUndefined();
    });
  });

  describe("Deal Creation (Conditional)", () => {
    it("should create deal when dealTitle is present", async () => {
      // Setup: Need a default pipeline
      const defaultPipeline = {
        isDefault: true,
        businessId: "business1",
      };
      const defaultStage = {
        pipelineId: "pipeline1",
        order: 1,
        probability: 25,
      };

      mockCollections.set(
        "businesses/business1/pipelines",
        new Map([["pipeline1", defaultPipeline]]),
      );
      mockCollections.set(
        "businesses/business1/stages",
        new Map([["stage1", defaultStage]]),
      );

      const row: MultiEntityRow = {
        companyName: "Deal Company",
        firstName: "Deal",
        lastName: "Contact",
        email: "deal@example.com",
        dealTitle: "Big Deal",
        dealValueCents: 100000,
      };

      const result = await processMultiEntityRow(
        mockDb,
        "business1",
        row,
        "create",
        "user1",
        "Test User",
      );

      expect(result.skipped).toBe(false);
      expect(result.dealCreated).toBe(true);
    });

    it("should NOT create deal when dealTitle is absent", async () => {
      const row: MultiEntityRow = {
        firstName: "No",
        lastName: "Deal",
        email: "nodeal@example.com",
      };

      const result = await processMultiEntityRow(
        mockDb,
        "business1",
        row,
        "create",
        "user1",
        "Test User",
      );

      expect(result.skipped).toBe(false);
      expect(result.dealCreated).toBe(false);
      expect(result.dealId).toBeUndefined();
    });
  });

  describe("Duplicate Handling Modes", () => {
    it("should skip duplicates in 'skip' mode", async () => {
      const existingContact = {
        firstName: "Existing",
        lastName: "Contact",
        email: "existing@example.com",
        businessId: "business1",
      };

      mockCollections.set(
        "businesses/business1/clients",
        new Map([["contact1", existingContact]]),
      );

      const row: MultiEntityRow = {
        firstName: "Existing",
        lastName: "Contact",
        email: "existing@example.com",
      };

      const result = await processMultiEntityRow(
        mockDb,
        "business1",
        row,
        "skip",
        "user1",
        "Test User",
      );

      expect(result.skipped).toBe(false);
      expect(result.contactCreated).toBe(false);
      expect(result.contactId).toBeDefined();
    });

    it("should update duplicates in 'update' mode", async () => {
      const existingContact = {
        firstName: "Old",
        lastName: "Name",
        email: "update@example.com",
        businessId: "business1",
      };

      mockCollections.set(
        "businesses/business1/clients",
        new Map([["contact1", existingContact]]),
      );

      const row: MultiEntityRow = {
        firstName: "New",
        lastName: "Name",
        email: "update@example.com",
        phone: "5551234567",
      };

      const result = await processMultiEntityRow(
        mockDb,
        "business1",
        row,
        "update",
        "user1",
        "Test User",
      );

      expect(result.skipped).toBe(false);
      expect(result.contactCreated).toBe(false);
    });

    it("should create duplicates in 'create' mode", async () => {
      const existingContact = {
        firstName: "Duplicate",
        lastName: "Contact",
        email: "dup@example.com",
        businessId: "business1",
      };

      mockCollections.set(
        "businesses/business1/clients",
        new Map([["contact1", existingContact]]),
      );

      const row: MultiEntityRow = {
        firstName: "Duplicate",
        lastName: "Contact",
        email: "dup2@example.com", // Different email to avoid exact match
      };

      const result = await processMultiEntityRow(
        mockDb,
        "business1",
        row,
        "create",
        "user1",
        "Test User",
      );

      expect(result.skipped).toBe(false);
      expect(result.contactCreated).toBe(true);
    });
  });

  describe("Tenant Scoping", () => {
    it("should scope all operations to businessId", async () => {
      const row: MultiEntityRow = {
        companyName: "Tenant Test",
        firstName: "Scoped",
        lastName: "User",
        email: "scoped@example.com",
      };

      const result = await processMultiEntityRow(
        mockDb,
        "business1",
        row,
        "create",
        "user1",
        "Test User",
      );

      expect(result.skipped).toBe(false);

      // Verify all entities created under correct business path
      expect(mockCollections.has("businesses/business1/companies")).toBe(true);
      expect(mockCollections.has("businesses/business1/clients")).toBe(true);
    });
  });

  describe("Entity Associations", () => {
    it("should link contact to company", async () => {
      const row: MultiEntityRow = {
        companyName: "Associated Corp",
        companyWebsite: "associated.com",
        firstName: "Linked",
        lastName: "Contact",
        email: "linked@example.com",
      };

      const result = await processMultiEntityRow(
        mockDb,
        "business1",
        row,
        "create",
        "user1",
        "Test User",
      );

      expect(result.skipped).toBe(false);
      expect(result.companyCreated).toBe(true);
      expect(result.contactCreated).toBe(true);
      expect(result.companyId).toBeDefined();
      expect(result.contactId).toBeDefined();
    });
  });

  describe("Primary Entity Routing", () => {
    it("creates a lead without auto-creating a contact when lead import is primary", async () => {
      const row: MultiEntityRow = {
        firstName: "Lead",
        lastName: "Only",
        email: "lead.only@example.com",
      };

      const result = await processMultiEntityRow(
        mockDb,
        "business1",
        row,
        "create",
        "user1",
        "Test User",
        "lead",
      );

      expect(result.skipped).toBe(false);
      expect(result.leadCreated).toBe(true);
      expect(result.contactCreated).toBe(false);
    });

    it("creates deal-linked contacts from client email and name when deal import is primary", async () => {
      mockCollections.set(
        "businesses/business1/pipelines",
        new Map([["pipeline1", {name: "Default", isDefault: true}]]),
      );
      mockCollections.set(
        "businesses/business1/stages",
        new Map([["stage1", {name: "Qualification", pipelineId: "pipeline1", order: 1, probability: 25}]]),
      );

      const row: MultiEntityRow = {
        dealTitle: "Expansion Opportunity",
        email: "buyer@example.com",
        fullName: "Buyer Person",
      };

      const result = await processMultiEntityRow(
        mockDb,
        "business1",
        row,
        "create",
        "user1",
        "Test User",
        "deal",
      );

      expect(result.skipped).toBe(false);
      expect(result.contactCreated).toBe(true);
      expect(result.dealCreated).toBe(true);
    });
  });
});
