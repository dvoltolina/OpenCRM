import * as crypto from "crypto";

// Simple AES-256-GCM helper for token encryption. Uses a shared secret key
// (hex-encoded 32 bytes) per token_encryption_setup.md.
const TOKEN_KEY_HEX = process.env.TOKEN_ENCRYPTION_KEY;

function getKey(): Buffer {
  if (!TOKEN_KEY_HEX || TOKEN_KEY_HEX.length !== 64) {
    throw new Error("TOKEN_ENCRYPTION_KEY (64 hex chars) is required for token encryption");
  }
  return Buffer.from(TOKEN_KEY_HEX, "hex");
}

export function encryptToken(plaintext: string): string {
  const key = getKey();
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv("aes-256-gcm", key, iv);
  const encrypted = Buffer.concat([cipher.update(plaintext, "utf8"), cipher.final()]);
  const tag = cipher.getAuthTag();
  // Store as base64(iv)|base64(tag)|base64(ciphertext)
  return [
    iv.toString("base64"),
    tag.toString("base64"),
    encrypted.toString("base64"),
  ].join(".");
}

export function decryptToken(payload: string): string {
  const [ivB64, tagB64, cipherB64] = payload.split(".");
  if (!ivB64 || !tagB64 || !cipherB64) {
    throw new Error("Invalid encrypted token payload");
  }
  const key = getKey();
  const iv = Buffer.from(ivB64, "base64");
  const tag = Buffer.from(tagB64, "base64");
  const ciphertext = Buffer.from(cipherB64, "base64");
  const decipher = crypto.createDecipheriv("aes-256-gcm", key, iv);
  decipher.setAuthTag(tag);
  const decrypted = Buffer.concat([decipher.update(ciphertext), decipher.final()]);
  return decrypted.toString("utf8");
}

