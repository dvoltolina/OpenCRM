import type {Request} from "express";
import {getAppCheck} from "firebase-admin/app-check";
import {auth, db} from "../firebaseAdmin";
import {CRM_ALLOWED_ROLES, CanonicalUserRole, normalizeUserRole} from "../roleUtils";
import {HttpError, requireBusinessId} from "./utils";

export interface AuthContext {
  uid: string;
  businessId: string;
  role: CanonicalUserRole;
  email?: string;
  displayName?: string;
}

const shouldBypassAppCheck = (): boolean =>
  process.env.FUNCTIONS_EMULATOR === "true" ||
  Boolean(process.env.FIRESTORE_EMULATOR_HOST);

export const verifyAppCheck = async (req: Request): Promise<void> => {
  if (shouldBypassAppCheck()) return;

  const tokenHeader = req.headers["x-firebase-appcheck"];
  const token =
    Array.isArray(tokenHeader) ? tokenHeader[0] : tokenHeader;

  if (!token || typeof token !== "string") {
    throw new HttpError(401, "Missing App Check token");
  }

  try {
    await getAppCheck().verifyToken(token);
  } catch {
    throw new HttpError(401, "Invalid App Check token");
  }
};

export const requireAuthContext = async (
  req: Request,
  expectedBusinessId?: string,
  restrictToRoles: readonly CanonicalUserRole[] = CRM_ALLOWED_ROLES
): Promise<AuthContext> => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    throw new HttpError(401, "Missing Authorization header");
  }

  const tokenString = authHeader.split(" ")[1];
  let decoded: Awaited<ReturnType<typeof auth.verifyIdToken>>;
  try {
    decoded = await auth.verifyIdToken(tokenString);
  } catch {
    throw new HttpError(401, "Invalid auth token");
  }

  const tokenBusinessId =
    typeof decoded.businessId === "string" ? decoded.businessId : undefined;
  const uid = decoded.uid;

  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) {
    throw new HttpError(403, "User profile not found");
  }

  const profile = userDoc.data() ?? {};
  const profileBusinessId =
    typeof profile.businessId === "string" ? profile.businessId : undefined;
  const profileRole = normalizeUserRole(profile.role ?? decoded.role);
  const businessId = requireBusinessId(
    expectedBusinessId ?? tokenBusinessId ?? profileBusinessId
  );

  if (tokenBusinessId && tokenBusinessId !== businessId) {
    throw new HttpError(403, "Forbidden");
  }
  if (profileBusinessId && profileBusinessId !== businessId) {
    throw new HttpError(403, "Forbidden");
  }
  if (!profileRole || !restrictToRoles.includes(profileRole)) {
    throw new HttpError(403, "Insufficient permissions");
  }

  return {
    uid,
    businessId,
    role: profileRole,
    email: profile.email ?? decoded.email,
    displayName: profile.displayName ?? decoded.name,
  };
};
