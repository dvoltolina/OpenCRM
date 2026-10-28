/// Represents an authenticated staff user in the app.
///
/// Contains user identity and business association information
/// needed for data access and sync operations.
class StaffUser {
  const StaffUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.businessId,
    required this.providerId,
    required this.role,
    this.permissions = const [],
    this.photoUrl,
  });

  /// Firebase Auth UID.
  final String uid;

  /// User's email address.
  final String email;

  /// Display name.
  final String displayName;

  /// Business ID this staff member belongs to.
  final String businessId;

  /// Provider record ID (staff's provider document ID).
  final String providerId;

  /// User's role (staff, provider, admin).
  final String role;

  /// List of allowed actions/permissions.
  final List<String> permissions;

  /// URL to user's profile photo.
  final String? photoUrl;

  /// Creates a StaffUser from Firestore user document data.
  factory StaffUser.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    return StaffUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      businessId: data['businessId'] as String? ?? '',
      providerId: data['providerId'] as String? ?? '',
      role: data['role'] as String? ?? 'staff',
      permissions: List<String>.from(data['permissions'] ?? []),
      photoUrl: data['photoUrl'] as String?,
    );
  }

  /// Converts to a map for storage.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'businessId': businessId,
      'providerId': providerId,
      'role': role,
      'permissions': permissions,
      'photoUrl': photoUrl,
    };
  }

  /// Whether this user has a specific permission.
  bool hasPermission(String permission) {
    // Admins have all permissions
    if (role == 'admin') return true;
    return permissions.contains(permission);
  }

  /// Whether this user is an admin.
  bool get isAdmin => role == 'admin';

  /// Whether this user is a provider/staff member.
  bool get isProvider => role == 'provider' || role == 'staff';

  @override
  String toString() {
    return 'StaffUser(uid: $uid, email: $email, businessId: $businessId, '
        'providerId: $providerId, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StaffUser &&
        other.uid == uid &&
        other.businessId == businessId &&
        other.providerId == providerId;
  }

  @override
  int get hashCode => Object.hash(uid, businessId, providerId);
}
