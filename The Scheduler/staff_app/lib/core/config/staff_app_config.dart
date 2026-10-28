/// Configuration constants for the Staff App.
///
/// These values can be overridden via environment variables or
/// remote config for different deployment environments.
class StaffAppConfig {
  const StaffAppConfig._();

  // ─────────────────────────────────────────────────────────────────────────
  // Sync Configuration
  // ─────────────────────────────────────────────────────────────────────────

  /// How often to perform incremental sync when online (in minutes).
  static const int syncIntervalMinutes = 5;

  /// How many days of appointments to cache locally.
  static const int appointmentCacheDays = 7;

  /// Maximum number of items to queue before forcing sync.
  static const int maxSyncQueueSize = 1000;

  /// Number of retry attempts for failed sync items.
  static const int maxSyncRetries = 5;

  /// Delay between sync retries (in seconds).
  static const int syncRetryDelaySeconds = 30;

  // ─────────────────────────────────────────────────────────────────────────
  // GPS/Location Configuration
  // ─────────────────────────────────────────────────────────────────────────

  /// Timeout for GPS location acquisition (in seconds).
  static const int gpsTimeoutSeconds = 10;

  /// Desired GPS accuracy in meters.
  static const int gpsDesiredAccuracyMeters = 50;

  /// Radius in meters for geo-fence validation.
  static const int geofenceRadiusMeters = 100;

  /// Whether to require location for clock-in/out.
  static const bool requireLocationForTimeClock = true;

  // ─────────────────────────────────────────────────────────────────────────
  // Session/Security Configuration
  // ─────────────────────────────────────────────────────────────────────────

  /// Inactivity timeout before session lock (in minutes).
  /// Set to 0 to disable.
  static const int sessionTimeoutMinutes = 15;

  /// Whether to enable biometric authentication for session unlock.
  static const bool enableBiometricAuth = true;

  /// Days to retain local data before cleanup.
  static const int dataRetentionDays = 30;

  // ─────────────────────────────────────────────────────────────────────────
  // UI Configuration
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether to show clock-in reminder banner on schedule page.
  static const bool showClockInReminder = true;

  /// Whether to enable dark mode support.
  static const bool enableDarkMode = true;

  /// Default appointment card height in pixels.
  static const double appointmentCardHeight = 80.0;

  // ─────────────────────────────────────────────────────────────────────────
  // Feature Flags
  // ─────────────────────────────────────────────────────────────────────────

  /// Enable time clock feature.
  static const bool featureTimeClock = true;

  /// Enable offline mode.
  static const bool featureOfflineMode = true;

  /// Enable push notifications.
  static const bool featurePushNotifications = true;

  /// Enable appointment notes editing.
  static const bool featureAppointmentNotes = true;

  // ─────────────────────────────────────────────────────────────────────────
  // Computed Values
  // ─────────────────────────────────────────────────────────────────────────

  /// Sync interval as Duration.
  static Duration get syncInterval =>
      const Duration(minutes: syncIntervalMinutes);

  /// GPS timeout as Duration.
  static Duration get gpsTimeout => const Duration(seconds: gpsTimeoutSeconds);

  /// Session timeout as Duration.
  static Duration get sessionTimeout =>
      const Duration(minutes: sessionTimeoutMinutes);

  /// Sync retry delay as Duration.
  static Duration get syncRetryDelay =>
      const Duration(seconds: syncRetryDelaySeconds);
}
