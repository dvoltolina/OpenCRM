import {Timestamp} from "../firebaseAdmin";
import {
  isAdminRole,
  isCrmOperatorRole,
  normalizeUserRole,
} from "../roleUtils";

export type {CanonicalUserRole, UserRole} from "../roleUtils";

export class HttpError extends Error {
  status: number;
  code?: string;

  constructor(status: number, message: string, code?: string) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

export {isAdminRole, normalizeUserRole};

export const isStaffLikeRole = (role: unknown): boolean =>
  isCrmOperatorRole(role);

export const requireString = (value: unknown, field: string): string => {
  if (typeof value !== "string") {
    throw new HttpError(400, `${field} must be a string`);
  }
  const trimmed = value.trim();
  if (!trimmed) {
    throw new HttpError(400, `${field} is required`);
  }
  return trimmed;
};

export const optionalString = (value: unknown): string | undefined => {
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  return trimmed || undefined;
};

const idRegex = /^[a-zA-Z0-9_-]{3,128}$/;
const businessIdRegex = /^[a-zA-Z0-9_-]{6,128}$/;

export const requireBusinessId = (value: unknown): string => {
  const businessId = requireString(value, "businessId");
  if (!businessIdRegex.test(businessId)) {
    throw new HttpError(400, "Invalid businessId");
  }
  return businessId;
};

export const requireId = (value: unknown, field: string): string => {
  const id = requireString(value, field);
  if (!idRegex.test(id)) {
    throw new HttpError(400, `Invalid ${field}`);
  }
  return id;
};

export const stringArray = (
  value: unknown,
  field: string,
  max = 50
): string[] => {
  if (!Array.isArray(value)) return [];
  const cleaned = value
    .filter((entry) => typeof entry === "string")
    .map((entry) => entry.trim())
    .filter(Boolean)
    .slice(0, max);
  if (cleaned.length !== value.length) {
    throw new HttpError(400, `${field} must be an array of strings`);
  }
  return cleaned;
};

export const parseOptionalNumber = (
  value: unknown,
  field: string,
  options?: {min?: number; max?: number; integer?: boolean}
): number | undefined => {
  if (value === undefined || value === null || value === "") return undefined;
  const num = typeof value === "string" ? Number(value) : value;
  if (typeof num !== "number" || !Number.isFinite(num)) {
    throw new HttpError(400, `${field} must be a number`);
  }
  if (options?.integer && !Number.isInteger(num)) {
    throw new HttpError(400, `${field} must be an integer`);
  }
  if (options?.min !== undefined && num < options.min) {
    throw new HttpError(400, `${field} must be >= ${options.min}`);
  }
  if (options?.max !== undefined && num > options.max) {
    throw new HttpError(400, `${field} must be <= ${options.max}`);
  }
  return num;
};

export const normalizeCurrency = (value?: unknown): string => {
  const currency = typeof value === "string" ? value.trim().toUpperCase() : "USD";
  if (!/^[A-Z]{3}$/.test(currency)) {
    throw new HttpError(400, "currency must be a 3-letter code");
  }
  return currency;
};

export const optionalDateTimestamp = (
  value: unknown,
  field: string
): Timestamp | undefined => {
  if (value === undefined || value === null || value === "") return undefined;
  if (value instanceof Timestamp) return value;
  if (value instanceof Date) return Timestamp.fromDate(value);
  if (typeof value !== "string") {
    throw new HttpError(400, `${field} must be an ISO date string`);
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new HttpError(400, `${field} must be an ISO date string`);
  }
  return Timestamp.fromDate(date);
};

export const startOfMonthTimestamp = (now: Date = new Date()): Timestamp => {
  return Timestamp.fromDate(new Date(now.getUTCFullYear(), now.getUTCMonth(), 1));
};

export const clampLimit = (value: number, min: number, max: number): number =>
  Math.min(Math.max(value, min), max);
