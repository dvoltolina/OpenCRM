import test from "node:test";
import assert from "node:assert";

// Minimal smoke test for booking endpoints wiring.
// Does not hit live endpoints; validates that exports exist.
import * as index from "../src/index";

test("public booking exports exist", () => {
  assert.ok(index.publicCreateAppointment, "publicCreateAppointment missing");
  assert.ok(index.publicGetAvailableAppointments, "publicGetAvailableAppointments missing");
  assert.ok(index.publicListCatalog, "publicListCatalog missing");
  assert.ok(index.resolveBusinessSlug, "resolveBusinessSlug missing");
});
