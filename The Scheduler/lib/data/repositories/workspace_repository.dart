import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';

/// Repository for workspace/business creation and management.
/// Handles communication with createWorkspace Cloud Function.
class WorkspaceRepository {
  WorkspaceRepository({
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Create a new workspace/business
  ///
  /// Calls the createWorkspace Cloud Function which:
  /// - Generates ULID-based workspace ID
  /// - Creates business document with invite code
  /// - Generates public booking URL with slug
  /// - Creates owner user profile
  /// - Logs audit event
  ///
  /// Returns workspace details including inviteCode and publicBookingUrl
  Future<CreateWorkspaceResponse> createWorkspace({
    required String businessName,
    required String ownerEmail,
    required String ownerDisplayName,
    String? industry,
    String? slug,
    bool? requiresHipaaCompliance,
    bool? mfaEnabled,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('create workspace');
    }
    final callable = _functions.httpsCallable('createWorkspace');

    try {
      final result = await callable.call<Map<String, dynamic>>({
        'businessName': businessName,
        'ownerEmail': ownerEmail,
        'ownerDisplayName': ownerDisplayName,
        if (industry != null) 'industry': industry,
        if (slug != null) 'slug': slug,
        if (requiresHipaaCompliance != null) 'requiresHipaaCompliance': requiresHipaaCompliance,
        if (mfaEnabled != null) 'mfaEnabled': mfaEnabled,
      });

      return CreateWorkspaceResponse.fromMap(result.data);
    } on FirebaseFunctionsException catch (e) {
      // HIPAA: Log error code only, not message/details which may contain PII
      debugPrint('createWorkspace failed: ${e.code}');
      rethrow;
    }
  }

  /// Validate an invite code
  ///
  /// Checks if an invite code is valid and returns associated business info
  Future<ValidateInviteCodeResponse> validateInviteCode({
    required String inviteCode,
  }) async {
    if (DemoConfig.isDemoMode) {
      return ValidateInviteCodeResponse(
        valid: false,
        businessId: DemoConfig.demoBusinessId,
        businessName: DemoConfig.demoBusinessName,
      );
    }
    final callable = _functions.httpsCallable('validateInviteCode');

    final result = await callable.call<Map<String, dynamic>>({
      'inviteCode': inviteCode,
    });

    return ValidateInviteCodeResponse.fromMap(result.data);
  }

  /// Lookup a business by its public slug
  ///
  /// Used by the client portal to find the correct business to authenticate against.
  /// Returns businessId and businessName if found.
  Future<LookupBusinessBySlugResponse> lookupBusinessBySlug({
    required String slug,
  }) async {
    if (DemoConfig.isDemoMode) {
      return LookupBusinessBySlugResponse(
        found: true,
        businessId: DemoConfig.demoBusinessId,
        businessName: DemoConfig.demoBusinessName,
      );
    }
    final callable = _functions.httpsCallable('lookupBusinessBySlug');

    final result = await callable.call<Map<String, dynamic>>({
      'slug': slug,
    });

    return LookupBusinessBySlugResponse.fromMap(result.data);
  }
}

/// Response from createWorkspace Cloud Function
class CreateWorkspaceResponse {
  final String workspaceId;
  final String businessId;
  final String inviteCode;
  final String publicSlug;
  final String publicBookingUrl;
  final bool requiresHipaaCompliance;
  final bool mfaEnabled;

  CreateWorkspaceResponse({
    required this.workspaceId,
    required this.businessId,
    required this.inviteCode,
    required this.publicSlug,
    required this.publicBookingUrl,
    required this.requiresHipaaCompliance,
    required this.mfaEnabled,
  });

  factory CreateWorkspaceResponse.fromMap(Map<String, dynamic> map) {
    return CreateWorkspaceResponse(
      workspaceId: map['workspaceId'] as String,
      businessId: map['businessId'] as String,
      inviteCode: map['inviteCode'] as String,
      publicSlug: map['publicSlug'] as String,
      publicBookingUrl: map['publicBookingUrl'] as String,
      requiresHipaaCompliance: map['requiresHipaaCompliance'] as bool,
      mfaEnabled: map['mfaEnabled'] as bool,
    );
  }
}

/// Response from validateInviteCode Cloud Function
class ValidateInviteCodeResponse {
  final bool valid;
  final String? businessId;
  final String? businessName;
  final bool requiresHipaaCompliance;
  final bool mfaEnabled;

  ValidateInviteCodeResponse({
    required this.valid,
    this.businessId,
    this.businessName,
    this.requiresHipaaCompliance = false,
    this.mfaEnabled = false,
  });

  factory ValidateInviteCodeResponse.fromMap(Map<String, dynamic> map) {
    return ValidateInviteCodeResponse(
      valid: map['valid'] as bool,
      businessId: map['businessId'] as String?,
      businessName: map['businessName'] as String?,
      requiresHipaaCompliance: map['requiresHipaaCompliance'] as bool? ?? false,
      mfaEnabled: map['mfaEnabled'] as bool? ?? false,
    );
  }
}

/// Response from lookupBusinessBySlug Cloud Function
class LookupBusinessBySlugResponse {
  final bool found;
  final String? businessId;
  final String? businessName;

  LookupBusinessBySlugResponse({
    required this.found,
    this.businessId,
    this.businessName,
  });

  factory LookupBusinessBySlugResponse.fromMap(Map<String, dynamic> map) {
    return LookupBusinessBySlugResponse(
      found: map['found'] as bool,
      businessId: map['businessId'] as String?,
      businessName: map['businessName'] as String?,
    );
  }
}
