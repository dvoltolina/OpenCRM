/**
 * Regression stub: gift cards must be tenant-scoped on create.
 *
 * TODO: Implement emulator-backed rule test to assert:
 * - User from business A cannot create pending gift cards under business B.
 * - createGiftCardPayment Cloud Function remains public but writes are server-side only.
 */
describe.skip("firestore.rules - giftCards", () => {
  it("rejects cross-tenant gift card create (pending)", () => {
    // Implement using @firebase/rules-unit-testing with a user bound to businessA.
    // Attempt to write /businesses/businessB/giftCards/{id} should fail.
  });
});
