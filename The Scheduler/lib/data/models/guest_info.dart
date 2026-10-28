/// Guest information for booking without an account.
/// Used in the guest booking flow to collect minimal required information.
///
/// HIPAA Note: This data becomes PHI when associated with healthcare appointments.
/// - Do not log this data to console or analytics
/// - Ensure secure transmission (HTTPS)
/// - Clear from memory when no longer needed
/// - When persisted, store in encrypted Firestore fields
class GuestInfo {
  const GuestInfo({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
      };

  factory GuestInfo.fromJson(Map<String, dynamic> json) => GuestInfo(
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
      );

  @override
  String toString() => 'GuestInfo($fullName, $email, $phone)';
}
