import 'dart:convert';

import 'self_booking_access.dart';

/// Captures the data collected via the onboarding wizard so it can be
/// persisted per business/tenant and replayed across sessions.
class OnboardingState {
  const OnboardingState({
    required this.businessId,
    required this.industry,
    required this.businessName,
    required this.tagline,
    required this.location,
    required this.operatingDays,
    required this.services,
    required this.selfBookingAccess,
    required this.requireDeposit,
    required this.emailReminders,
    required this.smsReminders,
    required this.reminderLeadTimeHours,
    required this.updatedAt,
    this.completedAt,
  });

  final String businessId;
  final String industry;
  final String businessName;
  final String tagline;
  final String location;
  final List<String> operatingDays;
  final List<String> services;
  final SelfBookingAccess selfBookingAccess;
  final bool requireDeposit;
  final bool emailReminders;
  final bool smsReminders;
  final int reminderLeadTimeHours;
  final DateTime updatedAt;
  final DateTime? completedAt;

  bool get isComplete => completedAt != null;

  OnboardingState copyWith({
    String? businessId,
    String? industry,
    String? businessName,
    String? tagline,
    String? location,
    List<String>? operatingDays,
    List<String>? services,
    SelfBookingAccess? selfBookingAccess,
    bool? requireDeposit,
    bool? emailReminders,
    bool? smsReminders,
    int? reminderLeadTimeHours,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return OnboardingState(
      businessId: businessId ?? this.businessId,
      industry: industry ?? this.industry,
      businessName: businessName ?? this.businessName,
      tagline: tagline ?? this.tagline,
      location: location ?? this.location,
      operatingDays: operatingDays ?? List.unmodifiable(this.operatingDays),
      services: services ?? List.unmodifiable(this.services),
      selfBookingAccess: selfBookingAccess ?? this.selfBookingAccess,
      requireDeposit: requireDeposit ?? this.requireDeposit,
      emailReminders: emailReminders ?? this.emailReminders,
      smsReminders: smsReminders ?? this.smsReminders,
      reminderLeadTimeHours:
          reminderLeadTimeHours ?? this.reminderLeadTimeHours,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'industry': industry,
      'businessName': businessName,
      'tagline': tagline,
      'location': location,
      'operatingDays': operatingDays,
      'services': services,
      'selfBookingAccess': selfBookingAccess.value,
      'requireDeposit': requireDeposit,
      'emailReminders': emailReminders,
      'smsReminders': smsReminders,
      'reminderLeadTimeHours': reminderLeadTimeHours,
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory OnboardingState.fromJson(Map<String, dynamic> json) {
    // Backwards compatibility: handle old allowClientPortal boolean
    final selfBookingValue = json['selfBookingAccess'] ?? json['allowClientPortal'];

    return OnboardingState(
      businessId: json['businessId'] as String,
      industry: json['industry'] as String,
      businessName: json['businessName'] as String,
      tagline: json['tagline'] as String? ?? '',
      location: json['location'] as String? ?? '',
      operatingDays: List<String>.from(json['operatingDays'] as List),
      services: List<String>.from(json['services'] as List),
      selfBookingAccess: SelfBookingAccess.fromValue(selfBookingValue ?? true),
      requireDeposit: json['requireDeposit'] as bool? ?? false,
      emailReminders: json['emailReminders'] as bool? ?? true,
      smsReminders: json['smsReminders'] as bool? ?? false,
      reminderLeadTimeHours: json['reminderLeadTimeHours'] as int? ?? 24,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  static OnboardingState fromRawJson(String jsonStr) =>
      OnboardingState.fromJson(json.decode(jsonStr) as Map<String, dynamic>);

  String toRawJson() => json.encode(toJson());

  static OnboardingState create({
    required String businessId,
    required String industry,
    required String businessName,
    required String tagline,
    required String location,
    required List<String> operatingDays,
    required List<String> services,
    required SelfBookingAccess selfBookingAccess,
    required bool requireDeposit,
    required bool emailReminders,
    required bool smsReminders,
    required int reminderLeadTimeHours,
    bool markComplete = true,
  }) {
    final now = DateTime.now();
    return OnboardingState(
      businessId: businessId,
      industry: industry,
      businessName: businessName,
      tagline: tagline,
      location: location,
      operatingDays: List.unmodifiable(operatingDays),
      services: List.unmodifiable(services),
      selfBookingAccess: selfBookingAccess,
      requireDeposit: requireDeposit,
      emailReminders: emailReminders,
      smsReminders: smsReminders,
      reminderLeadTimeHours: reminderLeadTimeHours,
      updatedAt: now,
      completedAt: markComplete ? now : null,
    );
  }
}

