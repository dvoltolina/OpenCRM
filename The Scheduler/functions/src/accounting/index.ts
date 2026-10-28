/**
 * Accounting Integration Functions
 *
 * Re-exports all accounting-related Cloud Functions for
 * QuickBooks Online and Xero integrations.
 */

// OAuth token management
export {
  exchangeAccountingOAuthCode,
  refreshAccountingOAuthToken,
  revokeAccountingOAuthToken,
} from "./oauth";

// QuickBooks functions
export {
  createQuickBooksCustomer,
  createQuickBooksInvoice,
  createQuickBooksPayment,
  createQuickBooksSalesReceipt,
  getQuickBooksAccounts,
  getQuickBooksTaxCodes,
  syncToQuickBooks,
} from "./quickbooks";

// Xero functions
export {
  createXeroContact,
  createXeroInvoice,
  createXeroPayment,
  getXeroAccounts,
  getXeroTaxRates,
  syncToXero,
} from "./xero";

// Generic sync dispatchers (used by Flutter sync service)
export {
  syncClientToAccounting,
  syncPaymentToAccounting,
} from "./sync";
