/// Controls who can self-book appointments through the client portal.
enum SelfBookingAccess {
  /// Self-booking is disabled - staff must create all appointments.
  disabled('disabled', 'Disabled'),

  /// Only existing customers can self-book.
  existingOnly('existing_only', 'Existing customers only'),

  /// Anyone can self-book (new and existing customers).
  allCustomers('all_customers', 'All customers');

  const SelfBookingAccess(this.value, this.displayName);

  final String value;
  final String displayName;

  /// Whether self-booking is enabled at all.
  bool get isEnabled => this != disabled;

  /// Whether new customers can self-book.
  bool get allowsNewCustomers => this == allCustomers;

  /// Parse from string value, with backwards compatibility for bool values.
  static SelfBookingAccess fromValue(dynamic value) {
    if (value is bool) {
      // Backwards compatibility: true -> allCustomers, false -> disabled
      return value ? allCustomers : disabled;
    }
    if (value is String) {
      return SelfBookingAccess.values.firstWhere(
        (e) => e.value == value || e.name == value,
        orElse: () => disabled,
      );
    }
    return disabled;
  }
}
