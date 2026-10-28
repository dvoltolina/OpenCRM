import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {applyCors} from "./httpUtils";

function getSafeWebhookMetadata(req: import("express").Request) {
  return {
    method: req.method,
    contentType: req.headers["content-type"] ?? null,
    hasBody: req.body != null,
  };
}

export const sendSms = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }
  // Stub SMS sender for tests; integrate provider before prod deploy.
  logger.info("sendSms stub called", getSafeWebhookMetadata(req));
  res.json({success: true, sid: "stub"});
});

export const smsWebhookStatus = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }
  logger.info("smsWebhookStatus stub", getSafeWebhookMetadata(req));
  res.status(200).send("OK");
});

export const smsWebhookInbound = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }
  logger.info("smsWebhookInbound stub", getSafeWebhookMetadata(req));
  res.status(200).send("OK");
});
