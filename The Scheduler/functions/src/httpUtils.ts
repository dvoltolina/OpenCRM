import {Request, Response} from "express";

const defaultProdOrigins = [
  "https://admin.example.com",
  "https://app.example.com",
  "https://crm.example.com",
];

const defaultDevOrigins = [
  "http://localhost:3000",
  "http://localhost:4000",
  "http://localhost:5173",
  "http://localhost:5174",
  "http://localhost:5175",
  "http://127.0.0.1:4000",
  "http://127.0.0.1:5173",
  "http://127.0.0.1:5174",
  "http://127.0.0.1:5175",
];

const envAllowedOrigins =
  process.env.ALLOWED_ORIGINS
    ?.split(",")
    .map((origin) => origin.trim())
    .filter(Boolean) ?? [];

const isProduction = process.env.NODE_ENV === "production";
const allowedOrigins = envAllowedOrigins.length ?
  envAllowedOrigins :
  isProduction ?
    defaultProdOrigins :
    [...defaultProdOrigins, ...defaultDevOrigins];

export const isOriginAllowed = (origin?: string | null): boolean => {
  if (!origin) return true; // allow server-to-server calls without Origin header
  return allowedOrigins.includes(origin);
};

export const applyCors = (
  req: Request,
  res: Response,
  options?: {methods?: string; allowList?: string[]}
): boolean => {
  const origin = req.headers.origin as string | undefined;
  const allowList = options?.allowList ?? allowedOrigins;

  if (origin && allowList.includes(origin)) {
    res.set("Access-Control-Allow-Origin", origin);
  }

  res.set("Vary", "Origin");
  res.set("Access-Control-Allow-Methods", options?.methods ?? "POST,OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return true;
  }

  if (origin && !allowList.includes(origin)) {
    res.status(403).json({error: "Origin not allowed"});
    return true;
  }

  if (!origin && allowList.length === 0 && isProduction) {
    res.status(403).json({error: "Origin not allowed"});
    return true;
  }

  return false;
};

export const sanitizeMetadataMap = (
  metadata?: Record<string, unknown>,
  maxStringLength = 255
): Record<string, unknown> => {
  if (!metadata || typeof metadata !== "object") return {};

  const sanitized: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(metadata)) {
    if (!key) continue;
    if (typeof value === "string") {
      const trimmed = value.trim();
      if (!trimmed || trimmed.length > maxStringLength) continue;
      sanitized[key] = trimmed;
    } else if (typeof value === "number" || typeof value === "boolean") {
      sanitized[key] = value;
    }
    // Drop objects/arrays to avoid PHI or unexpected payloads.
  }
  return sanitized;
};
