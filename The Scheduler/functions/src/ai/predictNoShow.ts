/**
 * AI-Powered No-Show Prediction using Claude API
 *
 * This function receives extracted features from the Flutter app and uses
 * Claude to predict the probability of a no-show.
 *
 * Environment Variables Required:
 * - ANTHROPIC_API_KEY: Your Anthropic API key
 */

import {HttpsError, onCall} from "firebase-functions/v2/https";
import type {CallableRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import Anthropic from "@anthropic-ai/sdk";

// ============ Types ============

interface PredictionFeatures {
  appointmentId: string;
  businessId: string;
  extractedAt: string;
  featureSchemaVersion: number;

  // Client behavioral
  clientHistoricalNoshowRate: number;
  clientHistoricalCancelRate: number;
  clientTotalAppointments: number;
  clientDaysSinceLastVisit: number;
  clientLifetimeValueCents: number;
  clientLifecycleStage: string;
  clientHasPaymentMethod: boolean;

  // Appointment context
  bookingLeadDays: number;
  dayOfWeek: number;
  hourOfDay: number;
  isRecurring: boolean;
  isGroupSession: boolean;
  serviceDurationMinutes: number;
  servicePriceCents: number;
  requiresPayment: boolean;
  paymentCollected: boolean;
  hasIntakeForm: boolean;

  // Provider features
  providerHistoricalNoshowRate: number;
  providerTotalAppointments: number;

  // Time slot features
  slotHistoricalNoshowRate: number;
  isFirstAppointmentOfDay: boolean;
  isLastAppointmentOfDay: boolean;
}

type RiskLevel = "high" | "medium" | "low" | "unknown";
type ActionPriority = "critical" | "high" | "medium" | "low";

interface RecommendedAction {
  actionId: string;
  title: string;
  description: string;
  priority: ActionPriority;
  automatable: boolean;
  iconName?: string;
  estimatedImpact?: number;
}

interface FeatureImportance {
  featureName: string;
  featureDisplayName: string;
  importance: number;
  featureValue: number;
  impact: "increases_risk" | "decreases_risk";
  explanation?: string;
}

interface NoshowPrediction {
  appointmentId: string;
  probability: number;
  riskLevel: RiskLevel;
  confidence: number;
  recommendedActions: RecommendedAction[];
  topFeatures: FeatureImportance[];
  modelVersion: string;
  predictedAt: string;
  expiresAt: string;
  requestId?: string;
}

interface ClaudePredictionResponse {
  probability: number;
  confidence: number;
  reasoning: string;
  topFactors: Array<{
    featureName: string;
    impact: "increases_risk" | "decreases_risk";
    importance: number;
    explanation: string;
  }>;
  recommendedActions: string[];
}

// ============ Feature Display Names ============

const featureDisplayNames: Record<string, string> = {
  clientHistoricalNoshowRate: "Past No-Show Rate",
  clientHistoricalCancelRate: "Past Cancellation Rate",
  clientTotalAppointments: "Appointment History",
  clientDaysSinceLastVisit: "Days Since Last Visit",
  clientLifetimeValueCents: "Lifetime Value",
  clientLifecycleStage: "Client Status",
  clientHasPaymentMethod: "Payment Method on File",
  bookingLeadDays: "Days Until Appointment",
  dayOfWeek: "Day of Week",
  hourOfDay: "Time of Day",
  isRecurring: "Recurring Appointment",
  isGroupSession: "Group Session",
  serviceDurationMinutes: "Service Duration",
  servicePriceCents: "Service Price",
  requiresPayment: "Payment Required",
  paymentCollected: "Payment Collected",
  hasIntakeForm: "Intake Form Completed",
  providerHistoricalNoshowRate: "Provider's No-Show Rate",
  providerTotalAppointments: "Provider Experience",
  slotHistoricalNoshowRate: "Time Slot Risk",
  isFirstAppointmentOfDay: "First Appointment",
  isLastAppointmentOfDay: "Last Appointment",
};

// ============ Standard Actions ============

const standardActions: Record<string, RecommendedAction> = {
  send_reminder: {
    actionId: "send_reminder",
    title: "Send Reminder",
    description: "Send an SMS or email reminder 24-48 hours before appointment",
    priority: "high",
    automatable: true,
    iconName: "notifications",
    estimatedImpact: 0.15,
  },
  collect_deposit: {
    actionId: "collect_deposit",
    title: "Collect Deposit",
    description: "Request a deposit or pre-payment to increase commitment",
    priority: "high",
    automatable: false,
    iconName: "payment",
    estimatedImpact: 0.25,
  },
  confirm_appointment: {
    actionId: "confirm_appointment",
    title: "Request Confirmation",
    description: "Ask client to confirm attendance via text or email",
    priority: "medium",
    automatable: true,
    iconName: "check_circle",
    estimatedImpact: 0.10,
  },
  add_waitlist_backup: {
    actionId: "add_waitlist_backup",
    title: "Prepare Waitlist",
    description: "Have waitlist clients ready to fill this slot if cancelled",
    priority: "medium",
    automatable: false,
    iconName: "list",
    estimatedImpact: 0.0,
  },
  call_client: {
    actionId: "call_client",
    title: "Call Client",
    description: "Personal phone call to confirm and build rapport",
    priority: "high",
    automatable: false,
    iconName: "phone",
    estimatedImpact: 0.20,
  },
  consider_overbooking: {
    actionId: "consider_overbooking",
    title: "Consider Overbooking",
    description: "Accept another booking in the same slot to account for expected no-show",
    priority: "low",
    automatable: false,
    iconName: "event_repeat",
    estimatedImpact: 0.0,
  },
};

// ============ Helper Functions ============

function getRiskLevel(probability: number): RiskLevel {
  if (probability >= 0.6) return "high";
  if (probability >= 0.3) return "medium";
  return "low";
}

function getDayName(dayOfWeek: number): string {
  const days = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  return days[dayOfWeek] || `Day ${dayOfWeek}`;
}

function formatHour(hour: number): string {
  if (hour === 0) return "12:00 AM";
  if (hour === 12) return "12:00 PM";
  if (hour < 12) return `${hour}:00 AM`;
  return `${hour - 12}:00 PM`;
}

function formatCents(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`;
}

function buildPrompt(features: PredictionFeatures): string {
  return `You are an AI assistant analyzing appointment data to predict no-show probability.

Analyze the following appointment data and predict the probability (0.0 to 1.0) that the client will NOT show up.

## Client History
- Historical no-show rate: ${(features.clientHistoricalNoshowRate * 100).toFixed(1)}%
- Historical cancellation rate: ${(features.clientHistoricalCancelRate * 100).toFixed(1)}%
- Total past appointments: ${features.clientTotalAppointments}
- Days since last visit: ${features.clientDaysSinceLastVisit === 9999 ? "First-time client" : features.clientDaysSinceLastVisit + " days"}
- Lifetime value: ${formatCents(features.clientLifetimeValueCents)}
- Client status: ${features.clientLifecycleStage}
- Has payment method on file: ${features.clientHasPaymentMethod ? "Yes" : "No"}

## Appointment Details
- Booked ${features.bookingLeadDays} days in advance
- Scheduled for: ${getDayName(features.dayOfWeek)} at ${formatHour(features.hourOfDay)}
- Recurring appointment: ${features.isRecurring ? "Yes" : "No"}
- Group session: ${features.isGroupSession ? "Yes" : "No"}
- Service duration: ${features.serviceDurationMinutes} minutes
- Service price: ${formatCents(features.servicePriceCents)}
- Payment required: ${features.requiresPayment ? "Yes" : "No"}
- Payment collected: ${features.paymentCollected ? "Yes" : "No"}
- Intake form completed: ${features.hasIntakeForm ? "Yes" : "No"}

## Provider & Slot Statistics
- Provider's historical no-show rate: ${(features.providerHistoricalNoshowRate * 100).toFixed(1)}%
- Provider's total appointments: ${features.providerTotalAppointments}
- This time slot's historical no-show rate: ${(features.slotHistoricalNoshowRate * 100).toFixed(1)}%
- First appointment of day: ${features.isFirstAppointmentOfDay ? "Yes" : "No"}
- Last appointment of day: ${features.isLastAppointmentOfDay ? "Yes" : "No"}

## Key Research Insights for Your Analysis
- Longer booking lead times correlate with higher no-show rates
- Payment collection reduces no-shows by ~25%
- First-time clients have higher no-show rates than returning clients
- Early morning and late afternoon appointments have higher no-show rates
- Monday mornings and Friday afternoons tend to have higher no-shows
- Recurring appointments have lower no-show rates due to commitment
- Higher lifetime value clients tend to be more reliable

Respond with ONLY valid JSON in this exact format (no markdown, no explanation outside the JSON):
{
  "probability": 0.XX,
  "confidence": 0.XX,
  "reasoning": "Brief explanation of the prediction",
  "topFactors": [
    {
      "featureName": "exact_feature_name_from_list",
      "impact": "increases_risk" or "decreases_risk",
      "importance": 0.XX,
      "explanation": "Why this factor matters"
    }
  ],
  "recommendedActions": ["send_reminder", "collect_deposit", "confirm_appointment", "add_waitlist_backup", "call_client", "consider_overbooking"]
}

Valid feature names: clientHistoricalNoshowRate, clientHistoricalCancelRate, clientTotalAppointments, clientDaysSinceLastVisit, clientLifetimeValueCents, clientLifecycleStage, clientHasPaymentMethod, bookingLeadDays, dayOfWeek, hourOfDay, isRecurring, isGroupSession, serviceDurationMinutes, servicePriceCents, requiresPayment, paymentCollected, hasIntakeForm, providerHistoricalNoshowRate, providerTotalAppointments, slotHistoricalNoshowRate, isFirstAppointmentOfDay, isLastAppointmentOfDay

Include 3-5 top factors, ordered by importance. Only include actions that make sense for this risk level.`;
}

function parseClaudeResponse(text: string): ClaudePredictionResponse {
  // Remove any markdown code blocks if present
  let cleanText = text.trim();
  if (cleanText.startsWith("```json")) {
    cleanText = cleanText.slice(7);
  } else if (cleanText.startsWith("```")) {
    cleanText = cleanText.slice(3);
  }
  if (cleanText.endsWith("```")) {
    cleanText = cleanText.slice(0, -3);
  }
  cleanText = cleanText.trim();

  const parsed = JSON.parse(cleanText);

  // Validate and sanitize
  return {
    probability: Math.max(0, Math.min(1, Number(parsed.probability) || 0)),
    confidence: Math.max(0, Math.min(1, Number(parsed.confidence) || 0.7)),
    reasoning: String(parsed.reasoning || ""),
    topFactors: Array.isArray(parsed.topFactors) ? parsed.topFactors.map((f: Record<string, unknown>) => ({
      featureName: String(f.featureName || ""),
      impact: f.impact === "decreases_risk" ? "decreases_risk" : "increases_risk",
      importance: Math.max(0, Math.min(1, Number(f.importance) || 0)),
      explanation: String(f.explanation || ""),
    })) : [],
    recommendedActions: Array.isArray(parsed.recommendedActions)
      ? parsed.recommendedActions.filter((a: unknown) => typeof a === "string")
      : [],
  };
}

function getFeatureValue(features: PredictionFeatures, featureName: string): number {
  const featureMap: Record<string, number | boolean | string> = {
    clientHistoricalNoshowRate: features.clientHistoricalNoshowRate,
    clientHistoricalCancelRate: features.clientHistoricalCancelRate,
    clientTotalAppointments: features.clientTotalAppointments,
    clientDaysSinceLastVisit: features.clientDaysSinceLastVisit,
    clientLifetimeValueCents: features.clientLifetimeValueCents,
    clientLifecycleStage: features.clientLifecycleStage,
    clientHasPaymentMethod: features.clientHasPaymentMethod,
    bookingLeadDays: features.bookingLeadDays,
    dayOfWeek: features.dayOfWeek,
    hourOfDay: features.hourOfDay,
    isRecurring: features.isRecurring,
    isGroupSession: features.isGroupSession,
    serviceDurationMinutes: features.serviceDurationMinutes,
    servicePriceCents: features.servicePriceCents,
    requiresPayment: features.requiresPayment,
    paymentCollected: features.paymentCollected,
    hasIntakeForm: features.hasIntakeForm,
    providerHistoricalNoshowRate: features.providerHistoricalNoshowRate,
    providerTotalAppointments: features.providerTotalAppointments,
    slotHistoricalNoshowRate: features.slotHistoricalNoshowRate,
    isFirstAppointmentOfDay: features.isFirstAppointmentOfDay,
    isLastAppointmentOfDay: features.isLastAppointmentOfDay,
  };

  const value = featureMap[featureName];
  if (typeof value === "boolean") return value ? 1 : 0;
  if (typeof value === "number") return value;
  return 0;
}

// ============ Main Function ============

export const predictNoShow = onCall(
  {
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 30,
    secrets: ["ANTHROPIC_API_KEY"],
  },
  async (request: CallableRequest<{features: PredictionFeatures}>): Promise<NoshowPrediction> => {
    const startTime = Date.now();
    const requestId = `pred_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

    // Validate auth
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const {features} = request.data;

    if (!features || !features.appointmentId) {
      throw new HttpsError("invalid-argument", "Features with appointmentId required");
    }

    logger.info("predictNoShow called", {
      requestId,
      appointmentId: features.appointmentId,
      businessId: features.businessId,
      uid: request.auth.uid,
    });

    try {
      // Initialize Anthropic client
      const anthropic = new Anthropic({
        apiKey: process.env.ANTHROPIC_API_KEY,
      });

      // Build prompt and call Claude
      const prompt = buildPrompt(features);

      const message = await anthropic.messages.create({
        model: "claude-3-5-haiku-latest",
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: prompt,
          },
        ],
      });

      // Extract text response
      const textContent = message.content.find((c) => c.type === "text");
      if (!textContent || textContent.type !== "text") {
        throw new Error("No text response from Claude");
      }

      // Parse response
      const claudeResponse = parseClaudeResponse(textContent.text);

      // Build feature importance list
      const topFeatures: FeatureImportance[] = claudeResponse.topFactors.map((factor) => ({
        featureName: factor.featureName,
        featureDisplayName: featureDisplayNames[factor.featureName] || factor.featureName,
        importance: factor.importance,
        featureValue: getFeatureValue(features, factor.featureName),
        impact: factor.impact,
        explanation: factor.explanation,
      }));

      // Build recommended actions list
      const recommendedActions: RecommendedAction[] = claudeResponse.recommendedActions
        .filter((actionId) => actionId in standardActions)
        .map((actionId) => standardActions[actionId]);

      // Calculate expiration (cache for 1 hour)
      const now = new Date();
      const expiresAt = new Date(now.getTime() + 60 * 60 * 1000);

      const prediction: NoshowPrediction = {
        appointmentId: features.appointmentId,
        probability: claudeResponse.probability,
        riskLevel: getRiskLevel(claudeResponse.probability),
        confidence: claudeResponse.confidence,
        recommendedActions,
        topFeatures,
        modelVersion: "claude-3-5-haiku-v1",
        predictedAt: now.toISOString(),
        expiresAt: expiresAt.toISOString(),
        requestId,
      };

      const duration = Date.now() - startTime;
      logger.info("predictNoShow success", {
        requestId,
        appointmentId: features.appointmentId,
        probability: prediction.probability,
        riskLevel: prediction.riskLevel,
        durationMs: duration,
      });

      return prediction;
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error("predictNoShow error", {
        requestId,
        appointmentId: features.appointmentId,
        error: error instanceof Error ? error.message : "Unknown error",
        durationMs: duration,
      });

      // Return unavailable prediction instead of throwing
      // This allows graceful degradation in the app
      const now = new Date();
      return {
        appointmentId: features.appointmentId,
        probability: 0,
        riskLevel: "unknown",
        confidence: 0,
        recommendedActions: [],
        topFeatures: [],
        modelVersion: "unavailable",
        predictedAt: now.toISOString(),
        expiresAt: now.toISOString(),
        requestId,
      };
    }
  }
);

// ============ Batch Prediction Function ============

export const predictNoShowBatch = onCall(
  {
    region: "us-central1",
    memory: "512MiB",
    timeoutSeconds: 120,
    secrets: ["ANTHROPIC_API_KEY"],
  },
  async (
    request: CallableRequest<{featuresList: PredictionFeatures[]}>
  ): Promise<NoshowPrediction[]> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const {featuresList} = request.data;

    if (!Array.isArray(featuresList) || featuresList.length === 0) {
      throw new HttpsError("invalid-argument", "featuresList array required");
    }

    // Limit batch size
    const maxBatchSize = 20;
    if (featuresList.length > maxBatchSize) {
      throw new HttpsError(
        "invalid-argument",
        `Batch size exceeds maximum of ${maxBatchSize}`
      );
    }

    logger.info("predictNoShowBatch called", {
      batchSize: featuresList.length,
      businessId: featuresList[0]?.businessId,
      uid: request.auth.uid,
    });

    // Process predictions in parallel (with concurrency limit)
    const concurrencyLimit = 5;
    const results: NoshowPrediction[] = [];

    for (let i = 0; i < featuresList.length; i += concurrencyLimit) {
      const batch = featuresList.slice(i, i + concurrencyLimit);
      const batchPromises = batch.map((features) =>
        predictSingle(features, request.auth!.uid)
      );
      const batchResults = await Promise.all(batchPromises);
      results.push(...batchResults);
    }

    logger.info("predictNoShowBatch complete", {
      batchSize: featuresList.length,
      successCount: results.filter((r) => r.riskLevel !== "unknown").length,
    });

    return results;
  }
);

// Helper for batch processing
async function predictSingle(
  features: PredictionFeatures,
  _uid: string
): Promise<NoshowPrediction> {
  const requestId = `pred_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

  try {
    const anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });

    const prompt = buildPrompt(features);

    const message = await anthropic.messages.create({
      model: "claude-3-5-haiku-latest",
      max_tokens: 1024,
      messages: [{role: "user", content: prompt}],
    });

    const textContent = message.content.find((c) => c.type === "text");
    if (!textContent || textContent.type !== "text") {
      throw new Error("No text response from Claude");
    }

    const claudeResponse = parseClaudeResponse(textContent.text);

    const topFeatures: FeatureImportance[] = claudeResponse.topFactors.map((factor) => ({
      featureName: factor.featureName,
      featureDisplayName: featureDisplayNames[factor.featureName] || factor.featureName,
      importance: factor.importance,
      featureValue: getFeatureValue(features, factor.featureName),
      impact: factor.impact,
      explanation: factor.explanation,
    }));

    const recommendedActions: RecommendedAction[] = claudeResponse.recommendedActions
      .filter((actionId) => actionId in standardActions)
      .map((actionId) => standardActions[actionId]);

    const now = new Date();
    const expiresAt = new Date(now.getTime() + 60 * 60 * 1000);

    return {
      appointmentId: features.appointmentId,
      probability: claudeResponse.probability,
      riskLevel: getRiskLevel(claudeResponse.probability),
      confidence: claudeResponse.confidence,
      recommendedActions,
      topFeatures,
      modelVersion: "claude-3-5-haiku-v1",
      predictedAt: now.toISOString(),
      expiresAt: expiresAt.toISOString(),
      requestId,
    };
  } catch (error) {
    logger.error("predictSingle error", {
      requestId,
      appointmentId: features.appointmentId,
      error: error instanceof Error ? error.message : "Unknown error",
    });

    const now = new Date();
    return {
      appointmentId: features.appointmentId,
      probability: 0,
      riskLevel: "unknown",
      confidence: 0,
      recommendedActions: [],
      topFeatures: [],
      modelVersion: "unavailable",
      predictedAt: now.toISOString(),
      expiresAt: now.toISOString(),
      requestId,
    };
  }
}
