import test from "node:test";
import assert from "node:assert/strict";
import {
  buildCanonicalCustomClaims,
} from "../src/authClaims";
import {
  normalizeInvitableUserRole,
  normalizeUserRole,
} from "../src/roleUtils";

test("normalizeUserRole maps legacy aliases to canonical roles", () => {
  assert.equal(normalizeUserRole("assistant"), "frontDesk");
  assert.equal(normalizeUserRole("sales_rep"), "sales");
  assert.equal(normalizeUserRole("marketing"), "sales");
  assert.equal(normalizeUserRole("user"), "staff");
  assert.equal(normalizeUserRole("provider"), "provider");
});

test("normalizeInvitableUserRole only returns canonical invitable roles", () => {
  assert.equal(normalizeInvitableUserRole("assistant"), "frontDesk");
  assert.equal(normalizeInvitableUserRole("manager"), "manager");
  assert.equal(normalizeInvitableUserRole("client"), undefined);
});

test("buildCanonicalCustomClaims overwrites role and strips empty team arrays", () => {
  const claims = buildCanonicalCustomClaims({
    businessId: "biz_123",
    role: "frontDesk",
    existingClaims: {
      role: "assistant",
      teamIds: ["legacy-team"],
      managedTeamIds: ["legacy-managed"],
      mfaVerified: true,
    },
    teamIds: [],
    managedTeamIds: undefined,
  });

  assert.equal(claims.businessId, "biz_123");
  assert.equal(claims.role, "frontDesk");
  assert.equal(claims.mfaVerified, true);
  assert.equal("teamIds" in claims, false);
  assert.equal("managedTeamIds" in claims, false);
});

test("buildCanonicalCustomClaims keeps sanitized unique team claims", () => {
  const claims = buildCanonicalCustomClaims({
    businessId: "biz_123",
    role: "manager",
    teamIds: ["alpha", "alpha", "beta", ""],
    managedTeamIds: ["gamma", "gamma"],
  });

  assert.deepEqual(claims.teamIds, ["alpha", "beta"]);
  assert.deepEqual(claims.managedTeamIds, ["gamma"]);
});
