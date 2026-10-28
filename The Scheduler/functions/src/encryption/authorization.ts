import {normalizeUserRole} from "../roleUtils";

export type EncryptionUserRecord = {
  businessId?: unknown;
  role?: unknown;
};

export type AuthorizedEncryptionUser = {
  role?: ReturnType<typeof normalizeUserRole>;
  source: "topLevel" | "legacy";
};

export function resolveAuthorizedEncryptionUser(
  businessId: string,
  topLevelUser?: EncryptionUserRecord | null,
  legacyBusinessUser?: EncryptionUserRecord | null
): AuthorizedEncryptionUser {
  const topLevelBusinessId =
    typeof topLevelUser?.businessId === "string" ?
      topLevelUser.businessId.trim() :
      "";

  if (topLevelBusinessId) {
    if (topLevelBusinessId !== businessId) {
      throw new Error("User not authorized for this business");
    }

    return {
      role: normalizeUserRole(topLevelUser?.role),
      source: "topLevel",
    };
  }

  if (legacyBusinessUser) {
    return {
      role: normalizeUserRole(legacyBusinessUser.role),
      source: "legacy",
    };
  }

  throw new Error("User not authorized for this business");
}
