/**
 * QuickBooks Online Sync Functions
 *
 * Handles synchronization of customers, invoices, and payments
 * to QuickBooks Online via their REST API.
 *
 * Environment Variables Required:
 * - QUICKBOOKS_CLIENT_ID, QUICKBOOKS_CLIENT_SECRET (via oauth.ts)
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import type {CallableRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {db} from "../firebaseAdmin";
import {getDecryptedTokens} from "./oauth";
import {isAdminRole, normalizeUserRole} from "../roleUtils";

// QuickBooks API configuration
const QBO_API_BASE = "https://quickbooks.api.intuit.com/v3/company";
const QBO_SANDBOX_API_BASE = "https://sandbox-quickbooks.api.intuit.com/v3/company";

// Use sandbox in development
const getApiBase = () =>
  process.env.NODE_ENV === "production" ? QBO_API_BASE : QBO_SANDBOX_API_BASE;
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

interface CustomerData {
  displayName: string;
  email?: string;
  phone?: string;
  firstName?: string;
  lastName?: string;
  address?: {
    line1?: string;
    city?: string;
    state?: string;
    postalCode?: string;
    country?: string;
  };
}

interface InvoiceLineItem {
  description: string;
  amount: number;
  serviceId?: string;
  serviceName?: string;
}

interface InvoiceData {
  customerId: string;
  lineItems: InvoiceLineItem[];
  dueDate?: string;
  memo?: string;
}

interface PaymentData {
  customerId: string;
  invoiceId?: string;
  amount: number;
  paymentMethod?: string;
  depositAccountId?: string;
  referenceNumber?: string;
  memo?: string;
}

// QuickBooks API response types
interface QBOEntity {
  Id: string;
  SyncToken: string;
}

interface QBOCustomer extends QBOEntity {
  DisplayName: string;
}

interface QBOInvoice extends QBOEntity {
  DocNumber: string;
}

interface QBOPayment extends QBOEntity {
  TotalAmt: number;
}

interface QBOSalesReceipt extends QBOEntity {
  DocNumber: string;
}

interface QBOAccount {
  Id: string;
  Name: string;
  AccountType: string;
  AccountSubType?: string;
  FullyQualifiedName: string;
}

interface QBOTaxCode {
  Id: string;
  Name: string;
  Description?: string;
  Active: boolean;
}

interface QBOResponse {
  Customer?: QBOCustomer;
  Invoice?: QBOInvoice;
  Payment?: QBOPayment;
  SalesReceipt?: QBOSalesReceipt;
  QueryResponse?: {
    Account?: QBOAccount[];
    TaxCode?: QBOTaxCode[];
  };
}

// Cache for accounts list (1 hour TTL)
const accountsCache: Map<string, {data: unknown; timestamp: number}> = new Map();
const CACHE_TTL = 60 * 60 * 1000; // 1 hour

/**
 * Create a customer in QuickBooks.
 */
export const createQuickBooksCustomer = onCall(async (request) => {
  const {businessId, connectionId, realmId, customer} = request.data;

  validateRequired({businessId, connectionId, realmId, customer});
  await requireAuthForBusiness(request, businessId);

  try {
    const tokens = await getDecryptedTokens(businessId, connectionId);
    if (!tokens) {
      throw new HttpsError("not-found", "Connection not found");
    }

    const customerData = customer as CustomerData;

    // Build QuickBooks Customer object
    const qboCustomer = {
      DisplayName: customerData.displayName,
      PrimaryEmailAddr: customerData.email ? {Address: customerData.email} : undefined,
      PrimaryPhone: customerData.phone ? {FreeFormNumber: customerData.phone} : undefined,
      GivenName: customerData.firstName,
      FamilyName: customerData.lastName,
      BillAddr: customerData.address ?
        {
          Line1: customerData.address.line1,
          City: customerData.address.city,
          CountrySubDivisionCode: customerData.address.state,
          PostalCode: customerData.address.postalCode,
          Country: customerData.address.country,
        } :
        undefined,
    };

    const response = await qboApiCall(
      tokens.accessToken,
      realmId,
      "POST",
      "/customer",
      qboCustomer
    );

    const createdCustomer = response.Customer;
    if (!createdCustomer) {
      throw new HttpsError("internal", "Failed to create customer in QuickBooks");
    }

    logger.info("Created QuickBooks customer", {
      businessId,
      customerId: createdCustomer.Id,
      displayName: createdCustomer.DisplayName,
    });

    return {
      success: true,
      customerId: createdCustomer.Id,
      syncToken: createdCustomer.SyncToken,
    };
  } catch (error) {
    return handleQboError(error, "createCustomer", businessId);
  }
});

/**
 * Create an invoice in QuickBooks.
 */
export const createQuickBooksInvoice = onCall(async (request) => {
  const {businessId, connectionId, realmId, invoice, incomeAccountId} = request.data;

  validateRequired({businessId, connectionId, realmId, invoice});
  await requireAuthForBusiness(request, businessId);

  try {
    const tokens = await getDecryptedTokens(businessId, connectionId);
    if (!tokens) {
      throw new HttpsError("not-found", "Connection not found");
    }

    const invoiceData = invoice as InvoiceData;

    // Build QuickBooks Invoice object
    const qboInvoice = {
      CustomerRef: {value: invoiceData.customerId},
      Line: invoiceData.lineItems.map((item, index) => ({
        LineNum: index + 1,
        Amount: item.amount / 100, // Convert cents to dollars
        DetailType: "SalesItemLineDetail",
        Description: item.description,
        SalesItemLineDetail: {
          ItemRef: {value: "1"}, // Default to Services item
          UnitPrice: item.amount / 100,
          Qty: 1,
          ...(incomeAccountId && {
            ItemAccountRef: {value: incomeAccountId},
          }),
        },
      })),
      DueDate: invoiceData.dueDate,
      CustomerMemo: invoiceData.memo ? {value: invoiceData.memo} : undefined,
    };

    const response = await qboApiCall(
      tokens.accessToken,
      realmId,
      "POST",
      "/invoice",
      qboInvoice
    );

    const createdInvoice = response.Invoice;
    if (!createdInvoice) {
      throw new HttpsError("internal", "Failed to create invoice in QuickBooks");
    }

    logger.info("Created QuickBooks invoice", {
      businessId,
      invoiceId: createdInvoice.Id,
      docNumber: createdInvoice.DocNumber,
    });

    return {
      success: true,
      invoiceId: createdInvoice.Id,
      docNumber: createdInvoice.DocNumber,
      syncToken: createdInvoice.SyncToken,
    };
  } catch (error) {
    return handleQboError(error, "createInvoice", businessId);
  }
});

/**
 * Create a payment in QuickBooks.
 */
export const createQuickBooksPayment = onCall(async (request) => {
  const {businessId, connectionId, realmId, payment, depositAccountId} = request.data;

  validateRequired({businessId, connectionId, realmId, payment});
  await requireAuthForBusiness(request, businessId);

  try {
    const tokens = await getDecryptedTokens(businessId, connectionId);
    if (!tokens) {
      throw new HttpsError("not-found", "Connection not found");
    }

    const paymentData = payment as PaymentData;

    // Build QuickBooks Payment object
    const qboPayment: Record<string, unknown> = {
      CustomerRef: {value: paymentData.customerId},
      TotalAmt: paymentData.amount / 100, // Convert cents to dollars
      PaymentRefNum: paymentData.referenceNumber,
      PrivateNote: paymentData.memo,
    };

    // Link to invoice if provided
    if (paymentData.invoiceId) {
      qboPayment.Line = [
        {
          Amount: paymentData.amount / 100,
          LinkedTxn: [
            {
              TxnId: paymentData.invoiceId,
              TxnType: "Invoice",
            },
          ],
        },
      ];
    }

    // Set deposit account if provided
    if (depositAccountId || paymentData.depositAccountId) {
      qboPayment.DepositToAccountRef = {
        value: depositAccountId || paymentData.depositAccountId,
      };
    }

    const response = await qboApiCall(
      tokens.accessToken,
      realmId,
      "POST",
      "/payment",
      qboPayment
    );

    const createdPayment = response.Payment;
    if (!createdPayment) {
      throw new HttpsError("internal", "Failed to create payment in QuickBooks");
    }

    logger.info("Created QuickBooks payment", {
      businessId,
      paymentId: createdPayment.Id,
      amount: paymentData.amount,
    });

    return {
      success: true,
      paymentId: createdPayment.Id,
      syncToken: createdPayment.SyncToken,
    };
  } catch (error) {
    return handleQboError(error, "createPayment", businessId);
  }
});

/**
 * Create a sales receipt (payment without invoice) in QuickBooks.
 */
export const createQuickBooksSalesReceipt = onCall(async (request) => {
  const {
    businessId,
    connectionId,
    realmId,
    customerId,
    lineItems,
    depositAccountId,
    memo,
  } = request.data;

  validateRequired({businessId, connectionId, realmId, lineItems});
  await requireAuthForBusiness(request, businessId);

  try {
    const tokens = await getDecryptedTokens(businessId, connectionId);
    if (!tokens) {
      throw new HttpsError("not-found", "Connection not found");
    }

    // Build QuickBooks SalesReceipt object
    const qboSalesReceipt: Record<string, unknown> = {
      Line: (lineItems as InvoiceLineItem[]).map((item, index) => ({
        LineNum: index + 1,
        Amount: item.amount / 100,
        DetailType: "SalesItemLineDetail",
        Description: item.description,
        SalesItemLineDetail: {
          ItemRef: {value: "1"},
          UnitPrice: item.amount / 100,
          Qty: 1,
        },
      })),
      PrivateNote: memo,
    };

    if (customerId) {
      qboSalesReceipt.CustomerRef = {value: customerId};
    }

    if (depositAccountId) {
      qboSalesReceipt.DepositToAccountRef = {value: depositAccountId};
    }

    const response = await qboApiCall(
      tokens.accessToken,
      realmId,
      "POST",
      "/salesreceipt",
      qboSalesReceipt
    );

    const createdReceipt = response.SalesReceipt;
    if (!createdReceipt) {
      throw new HttpsError("internal", "Failed to create sales receipt in QuickBooks");
    }

    logger.info("Created QuickBooks sales receipt", {
      businessId,
      receiptId: createdReceipt.Id,
      docNumber: createdReceipt.DocNumber,
    });

    return {
      success: true,
      salesReceiptId: createdReceipt.Id,
      docNumber: createdReceipt.DocNumber,
      syncToken: createdReceipt.SyncToken,
    };
  } catch (error) {
    return handleQboError(error, "createSalesReceipt", businessId);
  }
});

/**
 * Get list of accounts for mapping dropdowns.
 */
export const getQuickBooksAccounts = onCall(async (request) => {
  const {businessId, connectionId, realmId, accountTypes} = request.data;

  validateRequired({businessId, connectionId, realmId});
  await requireAuthForBusiness(request, businessId);

  // Check cache
  const cacheKey = `qbo-accounts-${realmId}`;
  const cached = accountsCache.get(cacheKey);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return {success: true, accounts: cached.data};
  }

  try {
    const tokens = await getDecryptedTokens(businessId, connectionId);
    if (!tokens) {
      throw new HttpsError("not-found", "Connection not found");
    }

    // Query accounts
    let query = "SELECT * FROM Account";
    if (accountTypes && accountTypes.length > 0) {
      const types = accountTypes.map((t: string) => `'${t}'`).join(",");
      query += ` WHERE AccountType IN (${types})`;
    }
    query += " MAXRESULTS 1000";

    const response = await qboApiCall(
      tokens.accessToken,
      realmId,
      "GET",
      `/query?query=${encodeURIComponent(query)}`
    );

    const accounts = (response.QueryResponse?.Account || []).map(
      (acc) => ({
        id: acc.Id,
        name: acc.Name,
        type: acc.AccountType,
        subType: acc.AccountSubType,
        fullyQualifiedName: acc.FullyQualifiedName,
      })
    );

    // Update cache
    accountsCache.set(cacheKey, {data: accounts, timestamp: Date.now()});

    return {success: true, accounts};
  } catch (error) {
    return handleQboError(error, "getAccounts", businessId);
  }
});

/**
 * Get list of tax codes for mapping dropdown.
 */
export const getQuickBooksTaxCodes = onCall(async (request) => {
  const {businessId, connectionId, realmId} = request.data;

  validateRequired({businessId, connectionId, realmId});
  await requireAuthForBusiness(request, businessId);

  // Check cache
  const cacheKey = `qbo-taxcodes-${realmId}`;
  const cached = accountsCache.get(cacheKey);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return {success: true, taxCodes: cached.data};
  }

  try {
    const tokens = await getDecryptedTokens(businessId, connectionId);
    if (!tokens) {
      throw new HttpsError("not-found", "Connection not found");
    }

    const query = "SELECT * FROM TaxCode MAXRESULTS 100";
    const response = await qboApiCall(
      tokens.accessToken,
      realmId,
      "GET",
      `/query?query=${encodeURIComponent(query)}`
    );

    const taxCodes = (response.QueryResponse?.TaxCode || []).map(
      (tc) => ({
        id: tc.Id,
        name: tc.Name,
        description: tc.Description,
        active: tc.Active,
      })
    );

    // Update cache
    accountsCache.set(cacheKey, {data: taxCodes, timestamp: Date.now()});

    return {success: true, taxCodes};
  } catch (error) {
    return handleQboError(error, "getTaxCodes", businessId);
  }
});

/**
 * Main sync dispatcher for QuickBooks.
 */
export const syncToQuickBooks = onCall(async (request) => {
  const {businessId, connectionId, realmId, syncType, data} = request.data;

  validateRequired({businessId, connectionId, realmId, syncType, data});
  await requireAuthForBusiness(request, businessId);

  try {
    const tokens = await getDecryptedTokens(businessId, connectionId);
    if (!tokens) {
      throw new HttpsError("not-found", "Connection not found");
    }

    switch (syncType) {
    case "customer":
      return createQuickBooksCustomer.run(request);
    case "invoice":
      return createQuickBooksInvoice.run(request);
    case "payment":
      return createQuickBooksPayment.run(request);
    case "salesReceipt":
      return createQuickBooksSalesReceipt.run(request);
    default:
      throw new HttpsError("invalid-argument", `Unknown sync type: ${syncType}`);
    }
  } catch (error) {
    return handleQboError(error, `sync-${syncType}`, businessId);
  }
});

// Helper function to make QuickBooks API calls
async function qboApiCall(
  accessToken: string,
  realmId: string,
  method: string,
  endpoint: string,
  body?: unknown
): Promise<QBOResponse> {
  const url = `${getApiBase()}/${realmId}${endpoint}`;

  const response = await fetch(url, {
    method,
    headers: {
      "Authorization": `Bearer ${accessToken}`,
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

// Helper to handle QuickBooks errors
function handleQboError(
  error: unknown,
  operation: string,
  businessId: string
): {success: false; error: string; errorCode?: string; retryable: boolean} {
  logger.error(`QuickBooks ${operation} error for business ${businessId}:`, error);

  const typedError = error as {
    status?: number;
    statusText?: string;
    detail?: {Fault?: {Error?: Array<{code?: string; Message?: string}>}};
  };

  // Check for specific error types
  if (typedError.status === 401) {
    return {
      success: false,
      error: "Authentication failed. Please reconnect to QuickBooks.",
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

  // Extract QuickBooks error message
  const qboError = typedError.detail?.Fault?.Error?.[0];
  if (qboError) {
    return {
      success: false,
      error: qboError.Message || "QuickBooks error",
      errorCode: qboError.code,
      retryable: false,
    };
  }

  return {
    success: false,
    error: error instanceof Error ? error.message : "Unknown error",
    retryable: true,
  };
}
