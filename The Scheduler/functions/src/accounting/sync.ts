/**
 * Generic Sync Dispatcher Functions
 *
 * These functions dispatch sync operations to the appropriate
 * provider (QuickBooks or Xero) based on the provider parameter.
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import type {CallableRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {db} from "../firebaseAdmin";
import {isAdminRole, normalizeUserRole} from "../roleUtils";

// QuickBooks API
const QBO_API_BASE = "https://quickbooks.api.intuit.com/v3/company";
const QBO_SANDBOX_API_BASE = "https://sandbox-quickbooks.api.intuit.com/v3/company";

// Xero API
const XERO_API_BASE = "https://api.xero.com/api.xro/2.0";

const getQboApiBase = () =>
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

/**
 * Sync a client to the accounting system as a customer/contact.
 *
 * Dispatches to QuickBooks or Xero based on provider parameter.
 */
export const syncClientToAccounting = onCall(async (request) => {
  const {provider, accessToken, companyId, client, businessId} = request.data;

  if (!provider || !accessToken || !companyId || !client || !businessId) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required parameters: provider, accessToken, companyId, businessId, client"
    );
  }

  try {
    await requireAuthForBusiness(request, businessId);
    if (provider === "quickbooks") {
      return await syncClientToQuickBooks(accessToken, companyId, client);
    } else if (provider === "xero") {
      return await syncClientToXero(accessToken, companyId, client);
    } else {
      throw new HttpsError("invalid-argument", `Unknown provider: ${provider}`);
    }
  } catch (error) {
    logger.error("syncClientToAccounting error:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    return {
      error: error instanceof Error ? error.message : "Unknown error",
      errorCode: "sync_failed",
    };
  }
});

/**
 * Sync a payment to the accounting system.
 *
 * Creates an invoice/sales receipt and records the payment.
 */
export const syncPaymentToAccounting = onCall(async (request) => {
  const {
    provider,
    accessToken,
    companyId,
    incomeAccountId,
    depositAccountId,
    taxCodeId,
    payment,
    businessId,
  } = request.data;

  if (!provider || !accessToken || !companyId || !payment || !businessId) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required parameters: provider, accessToken, companyId, businessId, payment"
    );
  }

  try {
    await requireAuthForBusiness(request, businessId);
    if (provider === "quickbooks") {
      return await syncPaymentToQuickBooks(
        accessToken,
        companyId,
        payment,
        incomeAccountId,
        depositAccountId,
        taxCodeId
      );
    } else if (provider === "xero") {
      return await syncPaymentToXero(
        accessToken,
        companyId,
        payment,
        incomeAccountId,
        depositAccountId,
        taxCodeId
      );
    } else {
      throw new HttpsError("invalid-argument", `Unknown provider: ${provider}`);
    }
  } catch (error) {
    logger.error("syncPaymentToAccounting error:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    return {
      error: error instanceof Error ? error.message : "Unknown error",
      errorCode: "sync_failed",
    };
  }
});

// ============================================================
// QuickBooks Sync Helpers
// ============================================================

interface ClientData {
  id: string;
  displayName: string;
  email?: string;
  phone?: string;
  firstName?: string;
  lastName?: string;
}

interface PaymentData {
  id: string;
  amountCents: number;
  description: string;
  appointmentId?: string;
  date: string;
  type: string;
  customerId?: string;
}

async function syncClientToQuickBooks(
  accessToken: string,
  realmId: string,
  client: ClientData
): Promise<{customerId?: string; error?: string}> {
  const qboCustomer = {
    DisplayName: client.displayName,
    PrimaryEmailAddr: client.email ? {Address: client.email} : undefined,
    PrimaryPhone: client.phone ? {FreeFormNumber: client.phone} : undefined,
    GivenName: client.firstName,
    FamilyName: client.lastName,
  };

  const response = await fetch(
    `${getQboApiBase()}/${realmId}/customer`,
    {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: JSON.stringify(qboCustomer),
    }
  );

  if (!response.ok) {
    const errorBody = await response.text();
    logger.error("QuickBooks customer creation failed:", errorBody);
    return {error: `QuickBooks API error: ${response.status}`};
  }

  const data = await response.json();
  const createdCustomer = data.Customer;

  if (!createdCustomer?.Id) {
    return {error: "Failed to create customer - no ID returned"};
  }

  logger.info("Created QuickBooks customer", {
    customerId: createdCustomer.Id,
    displayName: client.displayName,
  });

  return {customerId: createdCustomer.Id};
}

async function syncPaymentToQuickBooks(
  accessToken: string,
  realmId: string,
  payment: PaymentData,
  incomeAccountId?: string,
  depositAccountId?: string,
  _taxCodeId?: string
): Promise<{paymentId?: string; invoiceId?: string; error?: string}> {
  // Create a sales receipt (combined invoice + payment)
  const qboSalesReceipt: Record<string, unknown> = {
    Line: [
      {
        LineNum: 1,
        Amount: payment.amountCents / 100,
        DetailType: "SalesItemLineDetail",
        Description: payment.description,
        SalesItemLineDetail: {
          ItemRef: {value: "1"}, // Default Services item
          UnitPrice: payment.amountCents / 100,
          Qty: 1,
          ...(incomeAccountId && {
            ItemAccountRef: {value: incomeAccountId},
          }),
        },
      },
    ],
    PrivateNote: `Appointment: ${payment.appointmentId || "N/A"}`,
    TxnDate: payment.date.split("T")[0], // YYYY-MM-DD
  };

  // Link to customer if provided
  if (payment.customerId) {
    qboSalesReceipt.CustomerRef = {value: payment.customerId};
  }

  // Set deposit account if provided
  if (depositAccountId) {
    qboSalesReceipt.DepositToAccountRef = {value: depositAccountId};
  }

  const response = await fetch(
    `${getQboApiBase()}/${realmId}/salesreceipt`,
    {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: JSON.stringify(qboSalesReceipt),
    }
  );

  if (!response.ok) {
    const errorBody = await response.text();
    logger.error("QuickBooks sales receipt creation failed:", errorBody);
    return {error: `QuickBooks API error: ${response.status}`};
  }

  const data = await response.json();
  const createdReceipt = data.SalesReceipt;

  if (!createdReceipt?.Id) {
    return {error: "Failed to create sales receipt - no ID returned"};
  }

  logger.info("Created QuickBooks sales receipt", {
    receiptId: createdReceipt.Id,
    amount: payment.amountCents / 100,
  });

  return {paymentId: createdReceipt.Id};
}

// ============================================================
// Xero Sync Helpers
// ============================================================

async function syncClientToXero(
  accessToken: string,
  tenantId: string,
  client: ClientData
): Promise<{customerId?: string; error?: string}> {
  const xeroContact = {
    Contacts: [
      {
        Name: client.displayName,
        FirstName: client.firstName,
        LastName: client.lastName,
        EmailAddress: client.email,
        Phones: client.phone ?
          [{PhoneType: "DEFAULT", PhoneNumber: client.phone}] :
          undefined,
      },
    ],
  };

  const response = await fetch(`${XERO_API_BASE}/Contacts`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Xero-tenant-id": tenantId,
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
    body: JSON.stringify(xeroContact),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    logger.error("Xero contact creation failed:", errorBody);
    return {error: `Xero API error: ${response.status}`};
  }

  const data = await response.json();
  const createdContact = data.Contacts?.[0];

  if (!createdContact?.ContactID) {
    return {error: "Failed to create contact - no ID returned"};
  }

  logger.info("Created Xero contact", {
    contactId: createdContact.ContactID,
    name: client.displayName,
  });

  return {customerId: createdContact.ContactID};
}

async function syncPaymentToXero(
  accessToken: string,
  tenantId: string,
  payment: PaymentData,
  accountCode?: string,
  bankAccountId?: string,
  _taxType?: string
): Promise<{paymentId?: string; invoiceId?: string; error?: string}> {
  // First create an invoice
  const xeroInvoice = {
    Invoices: [
      {
        Type: "ACCREC",
        Contact: payment.customerId ?
          {ContactID: payment.customerId} :
          {Name: "Walk-in Customer"},
        LineItems: [
          {
            Description: payment.description,
            Quantity: 1,
            UnitAmount: payment.amountCents / 100,
            AccountCode: accountCode || "200", // Default revenue
          },
        ],
        Date: payment.date.split("T")[0],
        DueDate: payment.date.split("T")[0],
        Reference: payment.appointmentId,
        Status: "AUTHORISED",
      },
    ],
  };

  const invoiceResponse = await fetch(`${XERO_API_BASE}/Invoices`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Xero-tenant-id": tenantId,
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
    body: JSON.stringify(xeroInvoice),
  });

  if (!invoiceResponse.ok) {
    const errorBody = await invoiceResponse.text();
    logger.error("Xero invoice creation failed:", errorBody);
    return {error: `Xero API error: ${invoiceResponse.status}`};
  }

  const invoiceData = await invoiceResponse.json();
  const createdInvoice = invoiceData.Invoices?.[0];

  if (!createdInvoice?.InvoiceID) {
    return {error: "Failed to create invoice - no ID returned"};
  }

  // Now create a payment for the invoice
  const xeroPayment = {
    Payments: [
      {
        Invoice: {InvoiceID: createdInvoice.InvoiceID},
        Account: bankAccountId ?
          {AccountID: bankAccountId} :
          {Code: "090"}, // Default bank account
        Amount: payment.amountCents / 100,
        Date: payment.date.split("T")[0],
      },
    ],
  };

  const paymentResponse = await fetch(`${XERO_API_BASE}/Payments`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Xero-tenant-id": tenantId,
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
    body: JSON.stringify(xeroPayment),
  });

  if (!paymentResponse.ok) {
    const errorBody = await paymentResponse.text();
    logger.error("Xero payment creation failed:", errorBody);
    // Return invoice ID even if payment fails
    return {
      invoiceId: createdInvoice.InvoiceID,
      error: `Payment failed: ${paymentResponse.status}`,
    };
  }

  const paymentData = await paymentResponse.json();
  const createdPayment = paymentData.Payments?.[0];

  logger.info("Created Xero invoice and payment", {
    invoiceId: createdInvoice.InvoiceID,
    paymentId: createdPayment?.PaymentID,
    amount: payment.amountCents / 100,
  });

  return {
    invoiceId: createdInvoice.InvoiceID,
    paymentId: createdPayment?.PaymentID || createdInvoice.InvoiceID,
  };
}
