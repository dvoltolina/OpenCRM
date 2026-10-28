@Tags(['ai'])
/// Tests for SendSmsActionExecutor.
///
/// Agent AI-11: Risk Automation Engine
import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/ai/automation/automation_rule.dart';
import 'package:the_scheduler/ai/automation/actions/automation_actions.dart';
import 'package:the_scheduler/core/services/sms_service.dart';
import 'package:the_scheduler/data/models/client.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/user_role.dart';

void main() {
  late SendSmsActionExecutor executor;
  late MockSmsService mockSmsService;
  late SecurityContext testContext;

  setUp(() {
    mockSmsService = MockSmsService();
    executor = SendSmsActionExecutor(smsService: mockSmsService);
    testContext = const SecurityContext(
      businessId: 'test-business-123',
      userId: 'test-user-456',
      role: UserRole.admin,
    );
  });

  Client _createTestClient({String? phone}) {
    return Client(
      id: 'client-123',
      businessId: testContext.businessId,
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      phone: phone ?? '+15551234567',
      tags: [],
      createdAt: DateTime.now(),
    );
  }

  ActionExecutionContext _createContext({
    Client? client,
    bool dryRun = false,
  }) {
    return ActionExecutionContext(
      securityContext: testContext,
      entityType: 'appointment',
      entityId: 'appt-123',
      client: client ?? _createTestClient(),
      triggerContext: {
        'probability': '80%',
        'riskLevel': 'high',
      },
      dryRun: dryRun,
    );
  }

  group('SendSmsActionExecutor', () {
    // Scenario 1: Successfully send SMS
    test('should successfully send SMS to client', () async {
      const config = AutomationActionConfig(
        type: AutomationActionType.sendSms,
        messageTemplate: 'Hi {{clientFirstName}}, your appointment is coming up!',
      );

      final result = await executor.execute(
        config: config,
        context: _createContext(),
      );

      expect(result.success, isTrue);
      expect(result.actionType, equals(AutomationActionType.sendSms));
      expect(result.externalId, isNotNull);
      expect(mockSmsService.sentMessages.length, equals(1));
      expect(mockSmsService.sentMessages.first.message, contains('John'));
    });

    // Scenario 2: Fail when client has no phone
    test('should fail when client has no phone number', () async {
      const config = AutomationActionConfig(
        type: AutomationActionType.sendSms,
        messageTemplate: 'Test message',
      );

      final clientWithoutPhone = Client(
        id: 'client-123',
        businessId: testContext.businessId,
        firstName: 'Jane',
        lastName: 'Doe',
        tags: [],
        createdAt: DateTime.now(),
      );

      final result = await executor.execute(
        config: config,
        context: _createContext(client: clientWithoutPhone),
      );

      expect(result.success, isFalse);
      expect(result.error, equals('missing_phone'));
    });

    // Scenario 3: Dry run mode
    test('should not actually send in dry run mode', () async {
      const config = AutomationActionConfig(
        type: AutomationActionType.sendSms,
        messageTemplate: 'Test message',
      );

      final result = await executor.execute(
        config: config,
        context: _createContext(dryRun: true),
      );

      expect(result.success, isTrue);
      expect(result.metadata['dryRun'], isTrue);
      expect(mockSmsService.sentMessages, isEmpty);
    });

    test('should render template variables correctly', () async {
      const config = AutomationActionConfig(
        type: AutomationActionType.sendSms,
        messageTemplate: 'Hi {{clientFirstName}} {{clientLastName}}, risk is {{riskLevel}}.',
      );

      await executor.execute(
        config: config,
        context: _createContext(),
      );

      expect(mockSmsService.sentMessages.length, equals(1));
      expect(mockSmsService.sentMessages.first.message, equals('Hi John Doe, risk is high.'));
    });

    test('should fail on invalid phone number', () async {
      const config = AutomationActionConfig(
        type: AutomationActionType.sendSms,
        messageTemplate: 'Test message',
      );

      final clientWithInvalidPhone = Client(
        id: 'client-123',
        businessId: testContext.businessId,
        firstName: 'Test',
        lastName: 'User',
        phone: 'invalid',
        tags: [],
        createdAt: DateTime.now(),
      );

      final result = await executor.execute(
        config: config,
        context: _createContext(client: clientWithInvalidPhone),
      );

      expect(result.success, isFalse);
      expect(result.error, equals('invalid_phone'));
    });
  });
}
