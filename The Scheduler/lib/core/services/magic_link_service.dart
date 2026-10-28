import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/magic_link_token.dart';
import '../../data/models/security_context.dart';

/// Service for managing magic link tokens for secure, login-free appointment access
///
/// Provides:
/// - Token generation with secure random strings
/// - Token validation and expiration checking
/// - Firestore persistence with multi-tenant isolation
/// - Magic link URL generation
/// - Token revocation
///
/// Security features:
/// - Tokens expire after configurable duration (default: 48 hours)
/// - Random secure token strings (64 characters)
/// - Multi-tenant isolation via businessId
/// - Access logging for audit trail
/// - Rate limiting support via access count
class MagicLinkService {
  MagicLinkService({
    FirebaseFirestore? firestore,
    this.tokenExpirationHours = 48,
    this.baseUrl = 'https://book.example.com',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final int tokenExpirationHours;
  final String baseUrl;

  static const _tokenLength = 64;
  static const _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  static final _random = Random.secure();

  /// Generate a new magic link token for an appointment
  ///
  /// Creates a secure token that allows the client to access their appointment
  /// details without logging in. Token is valid for [tokenExpirationHours].
  ///
  /// Example:
  /// ```dart
  /// final token = await service.generateToken(
  ///   context: securityContext,
  ///   appointmentId: 'appt-123',
  ///   clientId: 'client-456',
  ///   clientEmail: 'client@example.com',
  /// );
  /// ```
  Future<MagicLinkToken> generateToken({
    required SecurityContext context,
    required String appointmentId,
    required String clientId,
    required String clientEmail,
  }) async {
    final tokenId = Uuid().v4();
    final tokenString = _generateSecureToken();
    final now = DateTime.now();
    final expiresAt = now.add(Duration(hours: tokenExpirationHours));

    final token = MagicLinkToken(
      id: tokenId,
      businessId: context.businessId,
      appointmentId: appointmentId,
      clientId: clientId,
      clientEmail: clientEmail,
      token: tokenString,
      createdAt: now,
      expiresAt: expiresAt,
      status: MagicLinkTokenStatus.active,
    );

    await _firestore
        .collection('businesses')
        .doc(context.businessId)
        .collection('magic_link_tokens')
        .doc(tokenId)
        .set(token.toJson());

    return token;
  }

  /// Validate a magic link token
  ///
  /// Checks if the token is valid, not expired, and belongs to the correct business.
  /// Records access for audit trail.
  ///
  /// Returns the token if valid, null otherwise.
  ///
  /// Example:
  /// ```dart
  /// final token = await service.validateToken(
  ///   tokenString: 'abc123...',
  ///   businessId: 'biz-789',
  /// );
  /// if (token != null) {
  ///   // Token is valid, proceed
  /// }
  /// ```
  Future<MagicLinkToken?> validateToken({
    required String tokenString,
    required String businessId,
  }) async {
    try {
      // Query for token by token string
      final snapshot = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('magic_link_tokens')
          .where('token', isEqualTo: tokenString)
          .where('businessId', isEqualTo: businessId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final token = MagicLinkToken.fromJson(doc.data());

      // Check if token is valid
      if (!token.isValid) {
        // If expired but status is still active, update status
        if (token.isExpired && token.status == MagicLinkTokenStatus.active) {
          await _updateTokenStatus(
            businessId: businessId,
            tokenId: token.id,
            status: MagicLinkTokenStatus.expired,
          );
        }
        return null;
      }

      // Record access
      await _recordAccess(businessId: businessId, tokenId: token.id);

      return token;
    } catch (e) {
      // Log error but don't expose internals
      return null;
    }
  }

  /// Get token by ID (for admin/internal use)
  ///
  /// Retrieves a token without recording access. Used for administrative
  /// purposes like viewing token details.
  Future<MagicLinkToken?> getToken({
    required String businessId,
    required String tokenId,
  }) async {
    try {
      final doc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('magic_link_tokens')
          .doc(tokenId)
          .get();

      if (!doc.exists) return null;

      return MagicLinkToken.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  /// Get all tokens for an appointment
  ///
  /// Returns all magic link tokens associated with an appointment.
  /// Useful for admin dashboards or debugging.
  Stream<List<MagicLinkToken>> watchTokensForAppointment({
    required String businessId,
    required String appointmentId,
  }) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('magic_link_tokens')
        .where('appointmentId', isEqualTo: appointmentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MagicLinkToken.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Revoke a magic link token
  ///
  /// Immediately invalidates a token, typically called when an appointment
  /// is cancelled or the token is compromised.
  Future<void> revokeToken({
    required String businessId,
    required String tokenId,
  }) async {
    await _updateTokenStatus(
      businessId: businessId,
      tokenId: tokenId,
      status: MagicLinkTokenStatus.revoked,
    );
  }

  /// Revoke all tokens for an appointment
  ///
  /// Invalidates all magic link tokens associated with an appointment.
  /// Called when appointment is cancelled or rescheduled.
  Future<void> revokeTokensForAppointment({
    required String businessId,
    required String appointmentId,
  }) async {
    final snapshot = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('magic_link_tokens')
        .where('appointmentId', isEqualTo: appointmentId)
        .where('status', isEqualTo: MagicLinkTokenStatus.active.name)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'status': MagicLinkTokenStatus.revoked.name,
      });
    }
    await batch.commit();
  }

  /// Generate a magic link URL from a token
  ///
  /// Creates the full URL that can be sent to the client via email/SMS.
  ///
  /// Example:
  /// ```dart
  /// final url = service.generateMagicLinkUrl(
  ///   token: token,
  /// );
  /// // Returns: "https://book.example.com/appointment/abc123..."
  /// ```
  String generateMagicLinkUrl({required MagicLinkToken token}) {
    return '$baseUrl/appointment/${token.token}';
  }

  /// Clean up expired tokens
  ///
  /// Removes tokens that have been expired for more than [daysOld].
  /// Should be called periodically via Cloud Function or scheduled task.
  ///
  /// Returns the number of tokens deleted.
  Future<int> cleanupExpiredTokens({
    required String businessId,
    int daysOld = 7,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

    final snapshot = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('magic_link_tokens')
        .where('expiresAt', isLessThan: cutoffTimestamp)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    return snapshot.docs.length;
  }

  // Private helper methods

  /// Generate a secure random token string
  String _generateSecureToken() {
    return List.generate(
      _tokenLength,
      (_) => _chars[_random.nextInt(_chars.length)],
    ).join();
  }

  /// Record token access for audit trail
  Future<void> _recordAccess({
    required String businessId,
    required String tokenId,
  }) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('magic_link_tokens')
        .doc(tokenId)
        .update({
          'hasBeenUsed': true,
          'lastAccessedAt': FieldValue.serverTimestamp(),
          'accessCount': FieldValue.increment(1),
        });
  }

  /// Update token status
  Future<void> _updateTokenStatus({
    required String businessId,
    required String tokenId,
    required MagicLinkTokenStatus status,
  }) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('magic_link_tokens')
        .doc(tokenId)
        .update({'status': status.name});
  }
}

/// Mock implementation for testing
class MockMagicLinkService extends MagicLinkService {
  MockMagicLinkService({
    super.tokenExpirationHours = 48,
    super.baseUrl = 'https://book.example.com',
  });

  final Map<String, MagicLinkToken> _tokens = {};

  @override
  Future<MagicLinkToken> generateToken({
    required SecurityContext context,
    required String appointmentId,
    required String clientId,
    required String clientEmail,
  }) async {
    final tokenId = Uuid().v4();
    final tokenString = _generateSecureToken();
    final now = DateTime.now();
    final expiresAt = now.add(Duration(hours: tokenExpirationHours));

    final token = MagicLinkToken(
      id: tokenId,
      businessId: context.businessId,
      appointmentId: appointmentId,
      clientId: clientId,
      clientEmail: clientEmail,
      token: tokenString,
      createdAt: now,
      expiresAt: expiresAt,
      status: MagicLinkTokenStatus.active,
    );

    _tokens[tokenString] = token;
    return token;
  }

  @override
  Future<MagicLinkToken?> validateToken({
    required String tokenString,
    required String businessId,
  }) async {
    final token = _tokens[tokenString];
    if (token == null || token.businessId != businessId) {
      return null;
    }

    if (!token.isValid) {
      return null;
    }

    // Update access count
    _tokens[tokenString] = token.copyWith(
      hasBeenUsed: true,
      lastAccessedAt: DateTime.now(),
      accessCount: token.accessCount + 1,
    );

    return _tokens[tokenString];
  }

  @override
  Future<void> revokeToken({
    required String businessId,
    required String tokenId,
  }) async {
    final entry = _tokens.entries.firstWhere(
      (e) => e.value.id == tokenId && e.value.businessId == businessId,
      orElse: () => MapEntry(
        '',
        MagicLinkToken(
          id: '',
          businessId: '',
          appointmentId: '',
          clientId: '',
          clientEmail: '',
          token: '',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now(),
        ),
      ),
    );

    if (entry.key.isNotEmpty) {
      _tokens[entry.key] = entry.value.copyWith(
        status: MagicLinkTokenStatus.revoked,
      );
    }
  }

  @override
  String _generateSecureToken() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(64, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
