/**
 * API Middleware Index
 * Re-exports all middleware for convenient importing
 *
 * Task 5: Cloud Functions - API Layer
 */

export { validateApiKey, validateApiKeyForBusiness } from './auth';
export { checkScope, checkAnyScope, checkAllScopes } from './scope';
export {
  checkRateLimit,
  recordUsageMiddleware,
  recordApiUsage,
  clearRateLimitCache,
  clearAllRateLimitCaches,
} from './rate-limit';
