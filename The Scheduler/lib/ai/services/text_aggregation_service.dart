/// Service for collecting analyzable text from various client data sources.
///
/// Aggregates text from:
/// - SMS/Email replies (MessagingRepository)
/// - Cancellation reasons (AppointmentsRepository)
/// - Session notes (SessionNotesRepository)
///
/// Note: Some sources (intake forms, reschedule reasons) require additional
/// repository methods to be implemented. Those collection methods are
/// stubbed but will return empty lists until dependencies are available.
///
/// **HIPAA Compliance:** All PHI access is logged to AuditLogRepository.
///
/// Agent AI-5: Sentiment Analysis Data Models & Repository
import 'package:flutter/foundation.dart';

import '../../core/services/encryption_service.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/appointments_repository.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../data/repositories/messaging_repository.dart';
import '../../data/repositories/session_notes_repository.dart';
import '../models/sentiment_source.dart';

/// Maximum length of text to analyze (truncated for efficiency).
const int maxTextLength = 5000;

/// Minimum length of text to be worth analyzing.
const int minTextLength = 10;

/// Represents a piece of text ready for sentiment analysis.
class AnalyzableText {
  const AnalyzableText({
    required this.id,
    required this.text,
    required this.clientId,
    required this.source,
    required this.sourceDocumentId,
    required this.createdAt,
  });

  /// Unique identifier for this text piece
  final String id;

  /// The text content to analyze
  final String text;

  /// Client this text belongs to
  final String clientId;

  /// Source type of the text
  final SentimentSource source;

  /// Reference to the source document (message ID, appointment ID, etc.)
  final String sourceDocumentId;

  /// When the text was created/received
  final DateTime createdAt;

  /// Truncated text for storage (max 500 chars)
  String get truncatedText =>
      text.length > 500 ? '${text.substring(0, 497)}...' : text;

  @override
  String toString() =>
      'AnalyzableText(id: $id, source: ${source.name}, length: ${text.length})';
}

/// Service for collecting text from various sources for sentiment analysis.
class TextAggregationService {
  TextAggregationService({
    required AppointmentsRepository appointmentsRepository,
    required MessagingRepository messagingRepository,
    required SessionNotesRepository sessionNotesRepository,
    EncryptionService? encryptionService,
    AuditLogRepository? auditLogRepository,
  })  : _appointmentsRepo = appointmentsRepository,
        _messagingRepo = messagingRepository,
        _sessionNotesRepo = sessionNotesRepository,
        _encryptionService = encryptionService,
        _auditLogRepository = auditLogRepository;

  final AppointmentsRepository _appointmentsRepo;
  final MessagingRepository _messagingRepo;
  final SessionNotesRepository _sessionNotesRepo;
  final EncryptionService? _encryptionService;
  final AuditLogRepository? _auditLogRepository;

  /// Collect all analyzable text for a client.
  ///
  /// [since] - Only collect text created after this date
  /// [sources] - Filter to specific sources (default: all)
  /// [excludeAnalyzedIds] - Set of IDs already analyzed (to avoid duplicates)
  /// [limit] - Maximum number of texts to return
  ///
  /// **HIPAA:** Logs PHI access to audit trail.
  Future<List<AnalyzableText>> collectClientTexts({
    required SecurityContext context,
    required String clientId,
    DateTime? since,
    List<SentimentSource>? sources,
    Set<String>? excludeAnalyzedIds,
    int limit = 100,
  }) async {
    // **CRITICAL: Log PHI access for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'text_aggregation_read',
      entityType: 'client',
      entityId: clientId,
      details: {'operation': 'collect_texts'},
    );

    final activeSources = sources ?? SentimentSource.values;
    final analyzedIds = excludeAnalyzedIds ?? <String>{};
    final allTexts = <AnalyzableText>[];

    try {
      // Collect from each source in parallel
      final futures = <Future<List<AnalyzableText>>>[];

      // Messages (SMS/Email replies)
      if (activeSources.contains(SentimentSource.smsReply) ||
          activeSources.contains(SentimentSource.emailReply)) {
        futures.add(_collectMessageTexts(
          context,
          clientId,
          since,
          analyzedIds,
          activeSources,
        ));
      }

      // Appointment-related text (cancellation reasons)
      if (activeSources.contains(SentimentSource.cancellationReason)) {
        futures.add(_collectAppointmentTexts(
          context,
          clientId,
          since,
          analyzedIds,
          activeSources,
        ));
      }

      // Session notes (if staff is requesting and encryption service available)
      if (activeSources.contains(SentimentSource.sessionNote) &&
          context.role.canManageClients &&
          _encryptionService != null) {
        futures.add(_collectSessionNoteTexts(
          context,
          clientId,
          since,
          analyzedIds,
        ));
      }

      // Note: Intake form text collection is stubbed.
      // Would require IntakeFormRepository.getClientSubmissions() to be implemented.

      // Wait for all collections to complete
      final results = await Future.wait(futures);

      for (final texts in results) {
        allTexts.addAll(texts);
      }

      // Sort by date (newest first) and apply limit
      allTexts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allTexts.take(limit).toList();
    } catch (e) {
      debugPrint('TextAggregationService: Error collecting texts: $e');
      return allTexts;
    }
  }

  /// Collect text for batch of clients (more efficient for bulk analysis).
  Future<Map<String, List<AnalyzableText>>> collectClientTextsBatch({
    required SecurityContext context,
    required List<String> clientIds,
    DateTime? since,
    List<SentimentSource>? sources,
    int limitPerClient = 50,
  }) async {
    final results = <String, List<AnalyzableText>>{};

    // Process clients in parallel (but not too many at once)
    const batchSize = 10;

    for (var i = 0; i < clientIds.length; i += batchSize) {
      final batch = clientIds.skip(i).take(batchSize);

      final futures = batch.map((clientId) async {
        final texts = await collectClientTexts(
          context: context,
          clientId: clientId,
          since: since,
          sources: sources,
          limit: limitPerClient,
        );
        return MapEntry(clientId, texts);
      });

      final batchResults = await Future.wait(futures);

      for (final entry in batchResults) {
        results[entry.key] = entry.value;
      }
    }

    return results;
  }

  // ============ Private Collection Methods ============

  Future<List<AnalyzableText>> _collectMessageTexts(
    SecurityContext context,
    String clientId,
    DateTime? since,
    Set<String> analyzedIds,
    List<SentimentSource> sources,
  ) async {
    final texts = <AnalyzableText>[];

    try {
      // Get conversations involving this client
      // Note: This is a simplified implementation - in production,
      // you'd query messages directly by clientId
      final conversations = await _messagingRepo
          .watchConversations(context: context)
          .first;

      for (final conv in conversations) {
        // Check if client is a participant
        if (!conv.participantIds.contains(clientId)) continue;

        // Get messages from this conversation
        final messages = await _messagingRepo
            .watchMessages(context: context, conversationId: conv.id)
            .first;

        for (final message in messages) {
          // Only analyze inbound messages (from client, not from staff)
          if (message.senderId != clientId) continue;

          // Skip if already analyzed
          final messageKey = 'msg_${message.id}';
          if (analyzedIds.contains(messageKey)) continue;

          // Skip if before since date
          if (since != null && message.createdAt.isBefore(since)) continue;

          // Skip empty or too short messages
          final content = message.content.trim();
          if (content.length < minTextLength) continue;

          // Default to SMS for in-app messages
          // Note: In production, you might track channel separately
          const source = SentimentSource.smsReply;
          if (!sources.contains(source)) continue;

          texts.add(AnalyzableText(
            id: messageKey,
            text: _truncateText(content),
            clientId: clientId,
            source: source,
            sourceDocumentId: message.id,
            createdAt: message.createdAt,
          ));
        }
      }
    } catch (e) {
      debugPrint('TextAggregationService: Error collecting messages: $e');
    }

    return texts;
  }

  Future<List<AnalyzableText>> _collectAppointmentTexts(
    SecurityContext context,
    String clientId,
    DateTime? since,
    Set<String> analyzedIds,
    List<SentimentSource> sources,
  ) async {
    final texts = <AnalyzableText>[];

    try {
      // Get client's appointments
      final appointments = await _appointmentsRepo.getClientAppointments(
        context: context,
        clientId: clientId,
      );

      for (final appt in appointments) {
        // Cancellation reasons
        if (sources.contains(SentimentSource.cancellationReason)) {
          final reason = appt.cancellationReason?.trim();
          if (reason != null &&
              reason.length >= minTextLength &&
              !analyzedIds.contains('cancel_${appt.id}')) {
            // Use createdAt as the timestamp
            final timestamp = appt.createdAt;
            if (since == null || !timestamp.isBefore(since)) {
              texts.add(AnalyzableText(
                id: 'cancel_${appt.id}',
                text: _truncateText(reason),
                clientId: clientId,
                source: SentimentSource.cancellationReason,
                sourceDocumentId: appt.id,
                createdAt: timestamp,
              ));
            }
          }
        }

        // Note: Reschedule reasons would require the Appointment model
        // to have a rescheduleReason field. Stubbed for future implementation.
      }
    } catch (e) {
      debugPrint('TextAggregationService: Error collecting appointments: $e');
    }

    return texts;
  }

  // Note: Intake form collection is stubbed pending IntakeFormRepository
  // implementation of getClientSubmissions method.
  // Future<List<AnalyzableText>> _collectIntakeFormTexts(...)

  Future<List<AnalyzableText>> _collectSessionNoteTexts(
    SecurityContext context,
    String clientId,
    DateTime? since,
    Set<String> analyzedIds,
  ) async {
    final texts = <AnalyzableText>[];

    if (_encryptionService == null) {
      debugPrint(
          'TextAggregationService: Encryption service required for session notes');
      return texts;
    }

    try {
      // Get client's session notes
      final notes = await _sessionNotesRepo.getClientNotes(
        context: context,
        clientId: clientId,
      );

      for (final note in notes) {
        // Skip if already analyzed
        if (analyzedIds.contains('note_${note.id}')) continue;

        // Skip if before since date
        if (since != null && note.createdAt.isBefore(since)) continue;

        // Skip psychotherapy notes (extra protected under HIPAA)
        if (note.isPsychotherapyNote) continue;

        // Decrypt content
        try {
          final content =
              _encryptionService.decrypt(note.encryptedContent).trim();
          if (content.length < minTextLength) continue;

          texts.add(AnalyzableText(
            id: 'note_${note.id}',
            text: _truncateText(content),
            clientId: clientId,
            source: SentimentSource.sessionNote,
            sourceDocumentId: note.id,
            createdAt: note.createdAt,
          ));
        } catch (e) {
          // Skip notes that can't be decrypted
          debugPrint('TextAggregationService: Could not decrypt note ${note.id}');
        }
      }
    } catch (e) {
      debugPrint('TextAggregationService: Error collecting session notes: $e');
    }

    return texts;
  }

  /// Truncate text to maximum length.
  String _truncateText(String text) {
    if (text.length <= maxTextLength) return text;
    return '${text.substring(0, maxTextLength - 3)}...';
  }

  // ============ Audit Logging ============

  /// Log audit event for HIPAA compliance.
  Future<void> _logAudit({
    required SecurityContext context,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? details,
  }) async {
    if (_auditLogRepository == null) return;

    try {
      await _auditLogRepository.log(
        context: context,
        action: action,
        entityType: entityType,
        entityId: entityId,
        details: details,
        source: 'TextAggregationService',
      );
    } catch (e) {
      // Don't fail the operation if audit logging fails
      debugPrint('TextAggregationService: Failed to log audit: $e');
    }
  }
}
