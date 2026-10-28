/// Sources of text that can be analyzed for sentiment.
///
/// Each source has associated metadata:
/// - weight: Influence on overall score (0.0-1.0)
/// - displayName: Human-readable name for UI
/// - isClientDirect: Whether this is direct client communication
///
/// Agent AI-5: Sentiment Analysis Data Models & Repository
enum SentimentSource {
  /// Client's SMS reply messages
  smsReply,

  /// Client's email reply messages
  emailReply,

  /// Free-text fields in intake forms
  intakeFormText,

  /// Provider's session notes (for trend analysis)
  sessionNote,

  /// Reason given when cancelling appointment
  cancellationReason,

  /// Reason given when rescheduling
  rescheduleReason,

  /// Client feedback/review text
  feedbackText,

  /// Notes added by staff about client
  staffNote,
}

extension SentimentSourceExtension on SentimentSource {
  /// Weight applied to sentiment from this source (0.0-1.0).
  /// Higher weight = more influence on overall score.
  double get weight => switch (this) {
        SentimentSource.smsReply => 0.9,
        SentimentSource.emailReply => 0.85,
        SentimentSource.cancellationReason => 0.95,
        SentimentSource.rescheduleReason => 0.8,
        SentimentSource.feedbackText => 1.0,
        SentimentSource.intakeFormText => 0.6,
        SentimentSource.sessionNote => 0.5,
        SentimentSource.staffNote => 0.7,
      };

  /// Display name for UI
  String get displayName => switch (this) {
        SentimentSource.smsReply => 'SMS Reply',
        SentimentSource.emailReply => 'Email Reply',
        SentimentSource.cancellationReason => 'Cancellation Reason',
        SentimentSource.rescheduleReason => 'Reschedule Reason',
        SentimentSource.feedbackText => 'Feedback',
        SentimentSource.intakeFormText => 'Intake Form',
        SentimentSource.sessionNote => 'Session Note',
        SentimentSource.staffNote => 'Staff Note',
      };

  /// Whether this source represents direct client communication
  bool get isClientDirect => switch (this) {
        SentimentSource.smsReply => true,
        SentimentSource.emailReply => true,
        SentimentSource.cancellationReason => true,
        SentimentSource.rescheduleReason => true,
        SentimentSource.feedbackText => true,
        SentimentSource.intakeFormText => true,
        SentimentSource.sessionNote => false,
        SentimentSource.staffNote => false,
      };
}
