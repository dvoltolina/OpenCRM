export type CampaignChannel = "email" | "sms" | "both";

export type CampaignRecord = {
  template?: unknown;
  subjectLine?: unknown;
  emailSubjectTemplate?: unknown;
  emailBodyTemplate?: unknown;
  smsBodyTemplate?: unknown;
};

const asTrimmedString = (value: unknown): string | undefined => {
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  return trimmed.length ? trimmed : undefined;
};

export const normalizeCampaignChannel = (
  value: unknown,
  fallback: CampaignChannel = "email"
): CampaignChannel => {
  if (value === "email" || value === "sms" || value === "both") {
    return value;
  }
  return fallback;
};

export const resolveCampaignContent = (
  campaign: CampaignRecord | undefined,
  channel: "email" | "sms"
): {template: string; subject?: string} => {
  const fallbackTemplate = asTrimmedString(campaign?.template) ?? "";

  if (channel === "email") {
    return {
      template: asTrimmedString(campaign?.emailBodyTemplate) ?? fallbackTemplate,
      subject:
        asTrimmedString(campaign?.emailSubjectTemplate) ??
        asTrimmedString(campaign?.subjectLine),
    };
  }

  return {
    template: asTrimmedString(campaign?.smsBodyTemplate) ?? fallbackTemplate,
  };
};
