/// User-safe error messages that don't expose sensitive information or technical details.
///
/// These messages are HIPAA-compliant and safe to display to end users as they
/// contain no Protected Health Information (PHI) or system implementation details.
class UserMessages {
  // Private constructor to prevent instantiation
  UserMessages._();

  // Generic errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String unexpectedError = 'An unexpected error occurred. Please contact support if this persists.';

  // Network errors
  static const String networkError = 'Unable to connect. Please check your internet connection.';
  static const String timeoutError = 'Request timed out. Please try again.';
  static const String serviceUnavailable = 'Service temporarily unavailable. Please try again later.';

  // Authentication errors
  static const String authError = 'Authentication failed. Please sign in again.';
  static const String sessionExpired = 'Your session has expired. Please sign in again.';
  static const String invalidCredentials = 'Invalid credentials. Please try again.';
  static const String accountLocked = 'Your account has been locked. Please contact support.';

  // Permission errors
  static const String permissionDenied = 'You don\'t have permission to perform this action.';
  static const String accessDenied = 'Access denied. Please contact your administrator.';

  // Data errors
  static const String notFound = 'The requested item could not be found.';
  static const String loadError = 'Unable to load data. Please try again.';
  static const String saveError = 'Unable to save changes. Please try again.';
  static const String deleteError = 'Unable to delete. Please try again.';
  static const String updateError = 'Unable to update. Please try again.';

  // File operations
  static const String uploadError = 'Upload failed. Please try again.';
  static const String downloadError = 'Download failed. Please try again.';
  static const String fileReadError = 'Unable to read file. Please try again.';
  static const String fileWriteError = 'Unable to write file. Please try again.';
  static const String fileSizeError = 'File size exceeds the maximum limit.';
  static const String fileTypeError = 'Invalid file type. Please check your file and try again.';

  // Import/Export
  static const String exportError = 'Export failed. Please try again.';
  static const String importError = 'Import failed. Please check your file and try again.';

  // Validation errors
  static const String validationError = 'Please check your input and try again.';
  static const String invalidInput = 'Invalid input. Please correct the errors and try again.';
  static const String missingRequiredFields = 'Please fill in all required fields.';

  // Database errors
  static const String databaseError = 'Database error occurred. Please try again.';
  static const String queryError = 'Unable to retrieve data. Please try again.';

  // Booking/Appointment errors
  static const String bookingError = 'Unable to complete booking. Please try again.';
  static const String appointmentNotFound = 'Appointment not found.';
  static const String scheduleConflict = 'Schedule conflict detected. Please choose a different time.';
  static const String slotUnavailable = 'This time slot is no longer available.';

  // Payment errors
  static const String paymentError = 'Payment processing failed. Please try again.';
  static const String paymentDeclined = 'Payment was declined. Please check your payment method.';

  // Sync errors
  static const String syncError = 'Synchronization failed. Please try again.';
  static const String offlineModeError = 'This action requires an internet connection.';

  // Cache errors
  static const String cacheError = 'Unable to cache data. Please try again.';
  static const String cacheReadError = 'Unable to read cached data.';

  // Configuration errors
  static const String configError = 'Configuration error. Please contact support.';

  // Provider mode errors
  static const String providerModeError = 'Unable to access provider mode. Please try again.';
  static const String clientDataError = 'Unable to load client data. Please try again.';
  static const String scheduleLoadError = 'Unable to load schedule. Please try again.';
  static const String taskLoadError = 'Unable to load tasks. Please try again.';
  static const String notesSaveError = 'Unable to save notes. Please try again.';

  // Offline mode messages
  static const String offlineMessage = 'You are currently offline. Some features may be limited.';
  static const String offlineSyncPending = 'Changes will sync when connection is restored.';

  // Success messages (for consistency)
  static const String saveSuccess = 'Changes saved successfully.';
  static const String deleteSuccess = 'Deleted successfully.';
  static const String uploadSuccess = 'Upload completed successfully.';
  static const String syncSuccess = 'Data synchronized successfully.';
}
