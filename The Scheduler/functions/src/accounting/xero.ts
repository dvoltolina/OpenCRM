/**
 * Xero Sync Functions
 *
 * Handles synchronization of contacts, invoices, and payments
 * to Xero via their REST API.
 *
 * Environment Variables Required:
 * - XERO_CLIENT_ID, XERO_CLIENT_SECRET (via oauth.ts)
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import type {CallableRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {db} from "../firebaseAdmin";
import {getDecryptedTokens} from "./oauth";
import {isAdminRole, normalizeUserRole} from "../roleUtils";

// Xero API configuration
const XERO_API_BASE = "https://api.xero.com/api.xro/2.0";
async function requireAuthForBusiness(
  request: CallableRequest<unknown>,
  businessId: string
): Promise<void> {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const uid = request.auth.uid as string;
  const tokenBiz = typeof request.auth.token.businessId === "string" ?
    request.auth.token.businessId :
    undefined;

  if (tokenBiz && tokenBiz !== businessId) {
    throw new HttpsError("permission-denied", "Business mismatch");
  }

  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) {
    throw new HttpsError("permission-denied", "User not found");
  }
  const data = userDoc.data() ?? {};
  if (data.businessId && data.businessId !== businessId) {
    throw new HttpsError("permission-denied", "User not in this business");
  }
  const role = normalizeUserRole(request.auth.token.role) ?? normalizeUserRole(data.role);
  if (!isAdminRole(role)) {
    throw new HttpsError("permission-denied", "Insufficient permissions");
  }

  const businessDoc = await db.collection("businesses").doc(businessId).get();
  if (!businessDoc.exists) {
    throw new HttpsError("not-found", "Business not found");
  }
}

interface ContactData {
  name: string;
  email?: string;
  phone?: string;
  firstName?: string;
  lastName?: string;
  address?: {
    line1?: string;
    city?: string;
    region?: string;
    postalCode?: string;
    country?: string;
  };
}

interface InvoiceLineItem {
  description: string;
  amount: number;
  accountCode?: string;
  taxType?: string;
}

interface InvoiceData {
  contactId: string;
  lineItems: InvoiceLineItem[];
  dueDate?: string;
  reference?: string;
}

interface PaymentData {
  invoiceId: string;
  amount: number;
  accountId: string;
  date?: string;
  reference?: string;
}

// Xero API response types
interface XeroContact {
  ContactID: string;
  Name: string;
}

interface XeroInvoice {
  InvoiceID: string;
  InvoiceNumber: string;
}

interface XeroPayment {
  PaymentID: string;
  Amount: number;
}

interface XeroAccount {
  AccountID: string;
  Code: string;
  Name: string;
  Type: string;
  Class?: string;
  Status: string;
}

interface XeroTaxRate {
  Name: string;
  TaxType: string;
  DisplayTaxRate?: number;
  EffectiveRate?: number;
  Status: string;
}

interface XeroResponse {
  Contacts?: XeroContact[];
  Invoices?: XeroInvoice[];
  Payments?: XeroPayment[];
  Accounts?: XeroAccount[];
  TaxRates?: XeroTaxRate[];
}

// Cache for accounts list (1 hour TTL)
const accountsCache: Map<string, {data: unknown; timestamp: number}> = new Map();
const CACHE_TTL = 60 * 60 * 1000; // 1 hour

/**
 * Create a contact (customer) in Xero.
 */
export const createXeroContact = onCall(async (request) => {
  const {businessId, connectionId, tenantId, contact} = request.data;

  validateRequired({businessId, connectionId, tenantId, contact});
  await requireAuthForBusiness(request, businessId);

  try {
    const tokens = await getDecryptedTokens(businessId, connectionId);
    if (!tokens) {
      throw new HttpsError("not-found", "Connection not found");
    }

    const contactData = contact as ContactData;

    // Build Xero Contact object
    const xeroContact = {
      Name: contactData.name,
      FirstName: contactData.firstName,
      LastName: contactData.lastName,
      EmailAddress: contactData.email,
      Phones: contactData.phone ?
        [
          {
            PhoneType: "DEFAULT",
            PhoneNumber: contactData.phone,
          },
        ] :
        undefined,
      Addresses: contactData.address ?
        [
          {
            AddressType: "STREET",
            AddressLine1: contactData.address.line1,
            City: contactData.address.city,
            Region: contactData.address.region,
            PostalCode: contactData.address.postalCode,
            Country: contactData.address.country,
          },
        ] :
        undefined,
    };

    const response = await xeroApiCall(
      tokens.accessToken,
      tenantId,
      "POST",
      "/Contacts",
      {Contacts: [xeroContact]}
    );

    const createdContact = response.Contacts?.[0];
    if (!createdContact) {
      throw new HttpsError("internal", "Failed to create contact in Xero");
    }

    logger.info("Created Xero contact", {
      businessId,
      contactId: createdContact.ContactID,
      name: createdContact.Name,
    });

    return {
      success: true,
      contactId: createdContact.ContactID,
    };
  } catch (error) {
    return handleXeroError(error, "createContact", businessId);
  }
});

/**
 * Create an invoice in Xero.
 */
export const createXeroInvoice = onCall(async (request) => {
  const {businessId, connectionId, tenantId, invoice, accountCode} = request.data;

  validateRequired({businessId, connectionId, tenantId, invoice});
  await requireAuthForBusiness(request, businessId);

  try {
    const tokens = await getDecryptedTokens(businessId, connectionId);
    if (!tokens) {
      throw new HttpsError("not-found", "Connection not found");
    }

    const invoiceData = invoice as InvoiceData;

    // Build Xero Invoice object
    const xeroInvoice = {
      Type: "ACCREC", // Accounts Receivable Invoice
      Contact: {ContactID: invoiceData.contactId},
      LineItems: invoiceData.lineItems.map((item) => ({
        Description: item.description,
        Quantity: 1,
        UnitAmount: item.amount / 100, // Convert cents to dollars
        AccountCode: item.accountCode || accountCode || "200", // Default revenue account
        TaxType: item.taxType || "NONE",
      })),
      DueDate: invoiceData.dueDate ?
        formatXeroDate(new Date(invoiceData.dueDate)) :
        undefined,
      Reference: invoiceData.reference,
      Status: "AUTHORISED",
    };

    const response = await xeroApiCall(
      tokens.accessToken,
      tenantId,
      "POST",
      "/Invoices",
      {Invoices: [xeroInvoice]}
    );

    const createdInvoice = response.Invoices?.[0];
    if (!createdInvoice) {
      throw new HttpsError("internal", "Failed to create invoice in Xero");
    }

    logger.info("Created Xero invoice", {
      businessId,
      invoiceId: createdInvoice.InvoiceID,
      invoiceNumber: createdInvoice.InvoiceNumber,
    });

    return {
      success: true,
      invoiceId: createdInvoice.InvoiceID,
      invoiceNumber: createdInvoice.InvoiceNumber,
    };
  } catch (error) {
    return handleXeroError(error, "createInvoice", businessId);
  }
});

/**
 * Create a payment in Xero.
 */
export const createXeroPayment = onCall(async (request) => {
  const {businessId, connectionId, tenantId, payment} = request.data;

  validateRequired({businessId, connectionId, tenantId, payment});
  await requireAuthForBusiness(request, businessId);

  try {
    const tokens = await getDecryptedTokens(businessId, connectionId);
    if (!tokens) {
      throw new HttpsError("not-found", "Connection not found");
    }

    const paymentData = payment as PaymentData;

    // Build Xero Payment object
    const xeroPayment = {
      Invoice: {InvoiceID: paymentData.invoiceId},
      Account: {AccountID: paymentData.accountId},
      Amount: paymentData.amount / 100, // Convert cents to dollars
      Date: paymentData.date ?
        formatXeroDate(new Date(paymentData.date)) :
        formatXeroDate(new Date()),
      Reference: paymentData.reference,
    };

    const response = await xeroApiCall(
      tokens.accessToken,
      tenantId,
      "POST",
      "/Payments",
      {Payments: [xeroPayment]}
    );

    const createdPayment = response.Payments?.[0];
    if (!createdPayment) {
      throw new HttpsError("internal", "Failed to create payment in Xero");
    }

    logger.info("Created Xero payment", {
      businessId,
      paymentId: createdPayment.PaymentID,
      amount: paymentData.amount,
    });

    return {
      success: true,
      paymentId: createdPayment.PaymentID,
    };
  } catch (error) {
    return handleXeroError(error, "createPayment", businessId);
  }
});

/**
 * Get list of accounts for mapping dropdowns.
 */
export const getXeroAccounts = onCall(async (request) => {
  const {businessId, connectionId, tenantId, accountTypes} = request.data;

  validateRequired({businessId, connectionId, tenantId});
  await requireAuthForBusiness(request, businessId);

  // Check cache
  const cacheKey = `xero-accounts-${tenantId}`;
  const cached = accountsCache.get(cacheKey);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return {success: true, accounts: cached.data};
  }

  try {
    const tokens = await getDecryptedTokens(businessId, connectionId);
    if (!tokens) {
      throw new HttpsError("not-found", "Connection not found");
    }

    // Build query params
    let endpoint = "/Accounts";
    if (accountTypes && accountTypes.length > 0) {
      const typesFilter = accountTypes
        .map((t: string) => `Type=="${t}"`)
        .join(" OR ");
      endpoint += `?where=${encodeURIComponent(typesFilter)}`;
    }

    const response = await xeroApiCall(
      tokens.accessToken,
      tenantId,
      "GET",
      endpoint
    );

    const accounts = (response.Accounts || []).map(
      (acc) => ({
        id: acc.AccountID,
        code: acc.Code,
        name: acc.Name,
        type: acc.Type,
        class: acc.Class,
        status: acc.Status,
      })
    );

    // Update cache
    accountsCache.set(cacheKey, {data: accounts, timestamp: Date.now()});

    return {success: true, accounts};
  } catch (error) {
    return handleXeroError(error, "getAccounts", businessId);
  }
});

/**
 * Get list of tax rates for mapping dropdown.
 */
export const getXeroTaxRates = onCall(async (request) => {
  const {businessId, connectionId, tenantId} = request.data;

  validateRequired({businessId, connectionId, tenantId});
  await requireAuthForBusiness(request, businessId);

  // Check cache
  const cacheKey = `xero-taxrates-${tenantId}`;
  const cached = accountsCache.get(cacheKey);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return {success: true, taxRates: cached.data};
  }

  try {
    const tokens = await getDecryptedTokens(businessId, connectionId);
    if (!tokens) {
      throw new HttpsError("not-found", "Connection not found");
    }

    const response = await xeroApiCall(
      tokens.accessToken,
      tenantId,
      "GET",
      "/TaxRates"
    );

    const taxRates = (response.TaxRates || []).map(
      (tr) => ({
        name: tr.Name,
        taxType: tr.TaxType,
        displayTaxRate: tr.DisplayTaxRate,
        effectiveRate: tr.EffectiveRate,
        status: tr.Status,
      })
    );

    // Update cache
    accountsCache.set(cacheKey, {data: taxRates, timestamp: Date.now()});

    return {success: true, taxRates};
  } catch (error) {
    return handleXeroError(error, "getTaxRates", businessId);
  }
});

/**
 * Main sync dispatcher for Xero.
 */
export const syncToXero = onCall(async (request) => {
  const {businessId, connectionId, tenantId, syncType, data} = request.data;

  validateRequired({businessId, connectionId, tenantId, syncType, data});
  await requireAuthForBusiness(request, businessId);

  try {
    const tokens = await getDecryptedTokens(businessId, connectionId);
    if (!tokens) {
      throw new HttpsError("not-found", "Connection not found");
    }

    switch (syncType) {
    case "contact":
      return createXeroContact.run(request);
    case "invoice":
      return createXeroInvoice.run(request);
    case "payment":
      return createXeroPayment.run(request);
    default:
      throw new HttpsError("invalid-argument", `Unknown sync type: ${syncType}`);
    }
  } catch (error) {
    return handleXeroError(error, `sync-${syncType}`, businessId);
  }
});

// Helper function to make Xero API calls
async function xeroApiCall(
  accessToken: string,
  tenantId: string,
  method: string,
  endpoint: string,
  body?: unknown
): Promise<XeroResponse> {
  const url = `${XERO_API_BASE}${endpoint}`;

  const response = await fetch(url, {
    method,
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Xero-tenant-id": tenantId,
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  if (!response.ok) {
    const errorBody = await response.text();
    let errorDetail: Record<string, unknown>;
    try {
      errorDetail = JSON.parse(errorBody);
    } catch {
      errorDetail = {message: errorBody};
    }

    throw {
      status: response.status,
      statusText: response.statusText,
      detail: errorDetail,
    };
  }

  return response.json();
}

// Helper to format date for Xero (YYYY-MM-DD)
function formatXeroDate(date: Date): string {
  return date.toISOString().split("T")[0];
}

// Helper to validate required parameters
function validateRequired(params: Record<string, unknown>): void {
  const missing = Object.entries(params)
    .filter(([_, value]) => value === undefined || value === null)
    .map(([key]) => key);

  if (missing.length > 0) {
    throw new HttpsError(
      "invalid-argument",
      `Missing required parameters: ${missing.join(", ")}`
    );
  }
}

// Helper to handle Xero errors
function handleXeroError(
  error: unknown,
  operation: string,
  businessId: string
): {success: false; error: string; errorCode?: string; retryable: boolean} {
  logger.error(`Xero ${operation} error for business ${businessId}:`, error);

  const typedError = error as {
    status?: number;
    statusText?: string;
    detail?: {
      Message?: string;
      ErrorNumber?: number;
      Elements?: Array<{
        ValidationErrors?: Array<{Message?: string}>;
      }>;
    };
  };

  // Check for specific error types
  if (typedError.status === 401) {
    return {
      success: false,
      error: "Authentication failed. Please reconnect to Xero.",
      errorCode: "auth_failed",
      retryable: false,
    };
  }

  if (typedError.status === 429) {
    return {
      success: false,
      error: "Rate limit exceeded. Please try again later.",
      errorCode: "rate_limit",
      retryable: true,
    };
  }

  // Extract Xero error message
  const xeroError = typedError.detail;
  if (xeroError?.Message) {
    return {
      success: false,
      error: xeroError.Message,
      errorCode: xeroError.ErrorNumber?.toString(),
      retryable: false,
    };
  }

  // Check for validation errors
  const validationError =
    xeroError?.Elements?.[0]?.ValidationErrors?.[0]?.Message;
  if (validationError) {
    return {
      success: false,
      error: validationError,
      errorCode: "validation_error",
      retryable: false,
    };
  }

  return {
    success: false,
    error: error instanceof Error ? error.message : "Unknown error",
    retryable: true,
  };
}
