import '../../../../data/repositories/auth_repository.dart';

/// Best-effort persistence configuration that respects HIPAA rules.
/// HIPAA tenants use session persistence (logout on browser close),
/// non-HIPAA tenants use local persistence (stay logged in).
Future<void> applyBusinessPersistence({
  required AuthRepository authRepository,
  required bool requiresHipaa,
}) async {
  try {
    await authRepository.configurePersistence(requiresHipaa: requiresHipaa);
  } catch (_) {
    // Best effort: persistence setup must never block auth flows.
  }
}

/// MFA enrollment is only required when the business has MFA enabled
/// and the user role is admin/owner. Staff should not be forced through MFA.
bool shouldRouteToMfa({
  required bool mfaEnabled,
  required bool isAdmin,
}) {
  return mfaEnabled && isAdmin;
}
