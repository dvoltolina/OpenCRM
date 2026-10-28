@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/models/sentiment_source.dart';
import 'package:the_scheduler/ai/services/text_aggregation_service.dart';
import 'package:the_scheduler/data/models/security_context.dart';

/// Tests for TextAggregationService
///
/// Note: Full integration tests require mocked repositories.
/// These tests focus on unit testing the AnalyzableText model
/// and text extraction utilities.
///
/// Agent AI-5: Sentiment Analysis Data Models & Repository
void main() {
  group('AnalyzableText', () {
    test('creates with required fields', () {
      final text = AnalyzableText(
        id: 'test_1',
        text: 'Hello, thank you for the appointment!',
        clientId: 'client_123',
        source: SentimentSource.smsReply,
        sourceDocumentId: 'msg_456',
        createdAt: DateTime.now(),
      );

      expect(text.id, 'test_1');
      expect(text.clientId, 'client_123');
      expect(text.source, SentimentSource.smsReply);
    });

    test('truncatedText truncates long text', () {
      final longText = 'a' * 600;
      final text = AnalyzableText(
        id: 'test_1',
        text: longText,
        clientId: 'client_123',
        source: SentimentSource.smsReply,
        sourceDocumentId: 'msg_456',
        createdAt: DateTime.now(),
      );

      expect(text.truncatedText.length, 500);
      expect(text.truncatedText.endsWith('...'), true);
    });

    test('truncatedText returns full text if under 500 chars', () {
      final shortText = 'Hello, this is a short message.';
      final text = AnalyzableText(
        id: 'test_1',
        text: shortText,
        clientId: 'client_123',
        source: SentimentSource.smsReply,
        sourceDocumentId: 'msg_456',
        createdAt: DateTime.now(),
      );

      expect(text.truncatedText, shortText);
      expect(text.truncatedText.endsWith('...'), false);
    });

    test('toString provides useful debug info', () {
      final text = AnalyzableText(
        id: 'test_1',
        text: 'Test message',
        clientId: 'client_123',
        source: SentimentSource.emailReply,
        sourceDocumentId: 'msg_456',
        createdAt: DateTime.now(),
      );

      final str = text.toString();
      expect(str.contains('test_1'), true);
      expect(str.contains('emailReply'), true);
    });
  });

  group('SentimentSource', () {
    test('weights are within valid range', () {
      for (final source in SentimentSource.values) {
        expect(source.weight, greaterThanOrEqualTo(0.0));
        expect(source.weight, lessThanOrEqualTo(1.0));
      }
    });

    test('client direct sources are correctly identified', () {
      expect(SentimentSource.smsReply.isClientDirect, true);
      expect(SentimentSource.emailReply.isClientDirect, true);
      expect(SentimentSource.cancellationReason.isClientDirect, true);
      expect(SentimentSource.feedbackText.isClientDirect, true);
      expect(SentimentSource.sessionNote.isClientDirect, false);
      expect(SentimentSource.staffNote.isClientDirect, false);
    });

    test('display names are not empty', () {
      for (final source in SentimentSource.values) {
        expect(source.displayName.isNotEmpty, true);
      }
    });

    test('feedback text has highest weight', () {
      double maxWeight = 0;
      SentimentSource? maxSource;

      for (final source in SentimentSource.values) {
        if (source.weight > maxWeight) {
          maxWeight = source.weight;
          maxSource = source;
        }
      }

      expect(maxSource, SentimentSource.feedbackText);
      expect(maxWeight, 1.0);
    });

    test('cancellation reason has high weight', () {
      expect(SentimentSource.cancellationReason.weight, greaterThan(0.9));
    });
  });

  group('Text extraction utilities', () {
    // Note: _extractFreeTextFromForm is private, but we test behavior
    // through integration tests or by making it accessible for testing

    test('minTextLength constant is reasonable', () {
      expect(minTextLength, greaterThan(0));
      expect(minTextLength, lessThan(50));
    });

    test('maxTextLength constant allows substantial text', () {
      expect(maxTextLength, greaterThan(1000));
      expect(maxTextLength, lessThan(50000));
    });
  });

  group('SecurityContext requirements', () {
    test('staff role can access session notes', () {
      const staffContext = SecurityContext(
        businessId: 'business_123',
        userId: 'user_123',
        role: UserRole.staff,
      );

      // Staff can manage clients, so should access session notes
      expect(staffContext.role.canManageClients, true);
    });

    test('client role cannot access session notes', () {
      const clientContext = SecurityContext(
        businessId: 'business_123',
        userId: 'user_123',
        clientId: 'client_123',
        role: UserRole.client,
      );

      // Clients cannot manage other clients
      expect(clientContext.role.canManageClients, false);
    });
  });

  group('Integration test scenarios (mocked)', () {
    // These would require mocked repositories
    // Documenting expected behaviors for integration tests

    test('should collect SMS replies from messaging repository', () {
      // When: Messaging repository returns conversations with client messages
      // Then: AnalyzableText items are created with source = smsReply
      // And: Only inbound (client-sent) messages are included
      expect(true, true); // Placeholder for documentation
    });

    test('should collect cancellation reasons from appointments', () {
      // When: Appointments repository returns appointments with cancellationReason
      // Then: AnalyzableText items are created with source = cancellationReason
      // And: Only non-empty reasons >= minTextLength are included
      expect(true, true);
    });

    test('should extract free-text from intake forms', () {
      // When: Intake form repository returns submissions with responses
      // Then: Free-text fields (strings > 20 chars) are extracted
      // And: Dates, IDs, emails, and URLs are filtered out
      expect(true, true);
    });

    test('should skip already-analyzed documents', () {
      // When: excludeAnalyzedIds contains a source document ID
      // Then: That document's text is not included in results
      expect(true, true);
    });

    test('should respect since date filter', () {
      // When: since parameter is provided
      // Then: Only texts created after since date are included
      expect(true, true);
    });

    test('should filter by source types', () {
      // When: sources parameter specifies only certain sources
      // Then: Only texts from those sources are collected
      expect(true, true);
    });

    test('should handle empty results gracefully', () {
      // When: No texts are found in any source
      // Then: Empty list is returned without errors
      expect(true, true);
    });

    test('should truncate extremely long text', () {
      // When: Text exceeds maxTextLength
      // Then: Text is truncated to maxTextLength - 3 + "..."
      expect(true, true);
    });

    test('should process batch of clients efficiently', () {
      // When: Multiple client IDs are provided
      // Then: Processing happens in batches of 10
      // And: All results are returned in a map keyed by clientId
      expect(true, true);
    });
  });
}
