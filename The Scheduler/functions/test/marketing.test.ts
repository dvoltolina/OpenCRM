import test from "node:test";
import assert from "node:assert/strict";
import {
  normalizeCampaignChannel,
  resolveCampaignContent,
} from "../src/marketingHelpers";

test("normalizeCampaignChannel falls back for unknown values", () => {
  assert.equal(normalizeCampaignChannel("email"), "email");
  assert.equal(normalizeCampaignChannel("sms"), "sms");
  assert.equal(normalizeCampaignChannel("other", "sms"), "sms");
});

test("resolveCampaignContent prefers channel-specific email fields", () => {
  const content = resolveCampaignContent(
    {
      template: "Fallback body",
      subjectLine: "Fallback subject",
      emailSubjectTemplate: "Email subject",
      emailBodyTemplate: "Email body",
      smsBodyTemplate: "SMS body",
    },
    "email"
  );

  assert.deepEqual(content, {
    template: "Email body",
    subject: "Email subject",
  });
});

test("resolveCampaignContent falls back to legacy template for sms", () => {
  const content = resolveCampaignContent(
    {
      template: "Legacy shared body",
      subjectLine: "Legacy subject",
    },
    "sms"
  );

  assert.deepEqual(content, {
    template: "Legacy shared body",
  });
});
