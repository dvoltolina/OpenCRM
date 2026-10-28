import test from "node:test";
import assert from "node:assert/strict";
import {resolveAuthorizedEncryptionUser} from "../src/encryption/authorization";

test("resolveAuthorizedEncryptionUser prefers the canonical top-level user profile", () => {
  const result = resolveAuthorizedEncryptionUser(
    "biz-1",
    {businessId: "biz-1", role: "admin"},
    {role: "owner"}
  );

  assert.deepEqual(result, {
    role: "admin",
    source: "topLevel",
  });
});

test("resolveAuthorizedEncryptionUser falls back to legacy nested business users", () => {
  const result = resolveAuthorizedEncryptionUser(
    "biz-1",
    null,
    {role: "marketing"}
  );

  assert.deepEqual(result, {
    role: "sales",
    source: "legacy",
  });
});

test("resolveAuthorizedEncryptionUser rejects mismatched top-level business access", () => {
  assert.throws(
    () => resolveAuthorizedEncryptionUser("biz-1", {businessId: "biz-2", role: "admin"}, {role: "owner"}),
    /not authorized/
  );
});
