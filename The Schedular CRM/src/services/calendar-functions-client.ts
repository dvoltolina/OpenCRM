/**
 * Calendar Functions Client
 * Typed helpers for calling calendar-related Cloud Functions endpoints.
 *
 * HIPAA: Do not send PHI or token contents. Only IDs/metadata are forwarded.
 * All endpoints require Firebase ID token auth and business scoping via X-Business-Id.
 */

import { getAuth } from 'firebase/auth';
import type { CalendarProvider } from '../types/calendar-sync';
import type { SyncResult } from './integration-sync-service';
import { getFunctionsBaseUrl, hasFunctionsBaseUrl } from './functions-base-url';

interface PostResult<T> {
  ok: boolean;
  status: number;
  data?: T;
  error?: string;
}

export interface CalendarConnectRequest {
  provider: CalendarProvider;
  authCode: string;
  businessId: string;
  redirectUri?: string;
  state?: string;
}

export interface CalendarConnectResponse {
  success?: boolean;
  connectionId?: string;
  status?: string;
  lastSyncStatus?: string;
  error?: string;
}

export interface CalendarRefreshRequest {
  connectionId: string;
  businessId: string;
}

export interface CalendarSyncRequest {
  connectionId: string;
  businessId: string;
  provider: CalendarProvider;
  cursor?: string;
  calendarId?: string;
}

export interface CalendarDisconnectRequest {
  connectionId: string;
  businessId: string;
}

export function isCalendarFunctionsConfigured(): boolean {
  return hasFunctionsBaseUrl();
}

async function getIdToken(): Promise<string> {
  const auth = getAuth();
  const user = auth.currentUser;
  if (!user) {
    throw new Error('User not authenticated');
  }
  return user.getIdToken();
}

async function postJson<T>(path: string, body: unknown, businessId: string): Promise<PostResult<T>> {
  const baseUrl = getFunctionsBaseUrl();
  if (!baseUrl) {
    return { ok: false, status: 0, error: 'Functions base URL is not configured' };
  }

  const idToken = await getIdToken();
  const response = await fetch(`${baseUrl}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
      'X-Business-Id': businessId,
    },
    body: JSON.stringify(body),
  });

  const isJson = response.headers.get('content-type')?.includes('application/json');
  const payload = isJson ? await response.json() : await response.text();

  if (!response.ok) {
    return {
      ok: false,
      status: response.status,
      error: typeof payload === 'string' ? payload : (payload?.error as string) || 'Calendar request failed',
    };
  }

  return { ok: true, status: response.status, data: payload as T };
}

export async function connectCalendar(
  request: CalendarConnectRequest
): Promise<CalendarConnectResponse> {
  const result = await postJson<CalendarConnectResponse>('/connectCalendar', request, request.businessId);
  if (!result.ok || !result.data) {
    return { success: false, error: result.error };
  }
  return result.data;
}

export async function refreshCalendarTokens(
  request: CalendarRefreshRequest
): Promise<CalendarConnectResponse> {
  const result = await postJson<CalendarConnectResponse>(
    '/refreshCalendarTokens',
    request,
    request.businessId
  );
  if (!result.ok || !result.data) {
    return { success: false, error: result.error };
  }
  return result.data;
}

export async function syncCalendar(request: CalendarSyncRequest): Promise<SyncResult> {
  const result = await postJson<SyncResult>('/syncCalendar', request, request.businessId);
  if (!result.ok || !result.data) {
    return {
      success: false,
      created: 0,
      updated: 0,
      skipped: 0,
      conflicts: [],
      retried: 0,
      backoffMs: undefined,
      errors: [result.error || 'Calendar sync failed'],
    };
  }
  return result.data;
}

export async function disconnectCalendar(
  request: CalendarDisconnectRequest
): Promise<{ success: boolean; error?: string }> {
  const result = await postJson<{ success: boolean; error?: string }>(
    '/disconnectCalendar',
    request,
    request.businessId
  );
  if (!result.ok || !result.data?.success) {
    return { success: false, error: result.error || 'Failed to disconnect calendar' };
  }
  return result.data;
}
