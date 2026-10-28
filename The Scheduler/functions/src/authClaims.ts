import {auth} from "./firebaseAdmin";
import {CanonicalUserRole} from "./roleUtils";

type ClaimsRecord = Record<string, unknown>;

type CanonicalClaimOptions = {
  businessId: string;
  role: CanonicalUserRole;
  existingClaims?: ClaimsRecord;
  teamIds?: unknown;
  managedTeamIds?: unknown;
};

function sanitizeStringArray(value: unknown): string[] | undefined {
  if (!Array.isArray(value)) {
    return undefined;
  }

  const uniqueValues = Array.from(new Set(
    value
      .filter((entry): entry is string => typeof entry === "string")
      .map((entry) => entry.trim())
      .filter(Boolean)
  ));

  return uniqueValues.length > 0 ? uniqueValues : undefined;
}

export function buildCanonicalCustomClaims({
  businessId,
  role,
  existingClaims = {},
  teamIds,
  managedTeamIds,
}: CanonicalClaimOptions): ClaimsRecord {
  const claims: ClaimsRecord = {
    ...existingClaims,
    businessId,
    role,
  };

  const normalizedTeamIds = sanitizeStringArray(teamIds);
  const normalizedManagedTeamIds = sanitizeStringArray(managedTeamIds);

  if (normalizedTeamIds) {
    claims.teamIds = normalizedTeamIds;
  } else {
    delete claims.teamIds;
  }

  if (normalizedManagedTeamIds) {
    claims.managedTeamIds = normalizedManagedTeamIds;
  } else {
    delete claims.managedTeamIds;
  }

  return claims;
}

export async function setCanonicalCustomClaims(
  uid: string,
  options: Omit<CanonicalClaimOptions, "existingClaims">
): Promise<ClaimsRecord> {
  const userRecord = await auth.getUser(uid);
  const claims = buildCanonicalCustomClaims({
    ...options,
    existingClaims: userRecord.customClaims ?? {},
  });

  await auth.setCustomUserClaims(uid, claims);
  return claims;
}
