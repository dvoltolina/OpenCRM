import 'package:freezed_annotation/freezed_annotation.dart';

/// Industry types for businesses.
/// Used to determine HIPAA compliance requirements and MFA enforcement.
@JsonEnum(valueField: 'value')
enum BusinessIndustry {
  /// Healthcare, medical practices, clinics
  healthcareMedical('healthcare_medical', 'Healthcare / Medical', true),

  /// Behavioral health, therapy, counseling
  behavioralHealth('behavioral_health', 'Behavioral Health / Therapy', true),

  /// Dental, optometry, specialized medical
  dentalOptometry('dental_optometry', 'Dental / Optometry', true),

  /// Wellness, alternative medicine (may handle PHI)
  wellness('wellness', 'Wellness / Alternative Medicine', false),

  /// Beauty salons, spas, aesthetics
  beautySalon('beauty_salon', 'Beauty / Salon / Spa', false),

  /// Fitness, personal training, gyms
  fitness('fitness', 'Fitness / Personal Training', false),

  /// Real estate, property management
  realEstate('real_estate', 'Real Estate', false),

  /// Life coaching, business coaching
  coaching('coaching', 'Coaching / Consulting', false),

  /// Legal, accounting, professional services
  professionalServices('professional_services', 'Professional Services', false),

  /// Education, tutoring
  education('education', 'Education / Tutoring', false),

  /// Other business types
  other('other', 'Other', false);

  const BusinessIndustry(this.value, this.displayName, this.defaultRequiresHipaa);

  /// Value stored in database
  final String value;

  /// Human-readable display name
  final String displayName;

  /// Whether this industry typically requires HIPAA compliance
  final bool defaultRequiresHipaa;

  /// Get industry from string value
  static BusinessIndustry fromValue(String value) {
    return BusinessIndustry.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BusinessIndustry.other,
    );
  }

  /// Industries that handle PHI and require HIPAA compliance by default
  static List<BusinessIndustry> get hipaaIndustries => BusinessIndustry.values
      .where((e) => e.defaultRequiresHipaa)
      .toList();

  /// Industries that don't typically require HIPAA compliance
  static List<BusinessIndustry> get nonHipaaIndustries => BusinessIndustry.values
      .where((e) => !e.defaultRequiresHipaa)
      .toList();
}
