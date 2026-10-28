import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/communication_config.dart';
import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';
import '../models/security_context.dart';

/// Repository for managing communication templates and automation rules.
/// In production, this would sync with Firestore to allow runtime customization.
abstract class CommunicationRepository {
  /// Get all email templates
  Future<Map<MessageType, MessageTemplate>> getEmailTemplates();

  /// Get all SMS templates
  Future<Map<MessageType, MessageTemplate>> getSmsTemplates();

  /// Update a specific template
  Future<void> updateTemplate(MessageTemplate template);

  /// Get all automation rules
  Future<List<AutomationRule>> getAutomationRules();

  /// Update an automation rule
  Future<void> updateAutomationRule(AutomationRule rule);

  /// Get communication configuration
  Future<CommunicationConfig> getCommunicationConfig();

  /// Update communication configuration
  Future<void> updateCommunicationConfig(CommunicationConfig config);

  /// Get message history for a client
  Future<List<MessageHistory>> getMessageHistory({
    String? clientId,
    MessageChannel? channel,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  });

  /// Log a sent message
  Future<void> logMessage(MessageHistory message);
}

/// In-memory implementation for development
/// Production version would use Firestore collections
class InMemoryCommunicationRepository implements CommunicationRepository {
  InMemoryCommunicationRepository(this._config);

  CommunicationConfig _config;
  final List<MessageHistory> _messageHistory = [];

  @override
  Future<Map<MessageType, MessageTemplate>> getEmailTemplates() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return Map.from(_config.emailTemplates);
  }

  @override
  Future<Map<MessageType, MessageTemplate>> getSmsTemplates() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Map.from(_config.smsTemplates);
  }

  @override
  Future<void> updateTemplate(MessageTemplate template) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update message template');
    }
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (template.channel == MessageChannel.email) {
      _config = _config.copyWith(
        emailTemplates: {
          ..._config.emailTemplates,
          template.type: template,
        },
      );
    } else if (template.channel == MessageChannel.sms) {
      _config = _config.copyWith(
        smsTemplates: {
          ..._config.smsTemplates,
          template.type: template,
        },
      );
    }

    developer.log(
      '✅ Template updated: ${template.type.name} (${template.channel.name})',
      name: 'CommunicationRepository',
    );
  }

  @override
  Future<List<AutomationRule>> getAutomationRules() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_config.automationRules);
  }

  @override
  Future<void> updateAutomationRule(AutomationRule rule) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update automation rule');
    }
    await Future.delayed(const Duration(milliseconds: 200));
    
    final rules = List<AutomationRule>.from(_config.automationRules);
    final index = rules.indexWhere((r) => r.id == rule.id);
    
    if (index != -1) {
      rules[index] = rule;
      _config = _config.copyWith(automationRules: rules);
      developer.log(
        '✅ Automation rule updated: ${rule.name}',
        name: 'CommunicationRepository',
      );
    }
  }

  @override
  Future<CommunicationConfig> getCommunicationConfig() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _config;
  }

  @override
  Future<void> updateCommunicationConfig(CommunicationConfig config) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update communication settings');
    }
    await Future.delayed(const Duration(milliseconds: 200));
    _config = config;
    developer.log(
      '✅ Communication config updated',
      name: 'CommunicationRepository',
    );
  }

  @override
  Future<List<MessageHistory>> getMessageHistory({
    String? clientId,
    MessageChannel? channel,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    var filtered = _messageHistory.where((msg) {
      if (clientId != null && msg.clientId != clientId) return false;
      if (channel != null && msg.channel != channel) return false;
      if (startDate != null && msg.timestamp.isBefore(startDate)) return false;
      if (endDate != null && msg.timestamp.isAfter(endDate)) return false;
      return true;
    }).toList();

    // Sort by most recent first
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filtered.take(limit).toList();
  }

  @override
  Future<void> logMessage(MessageHistory message) async {
    if (DemoConfig.isDemoMode) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 50));
    _messageHistory.add(message);
  }

  /// Clear history (for testing)
  void clearHistory() {
    _messageHistory.clear();
  }
}

/// Firestore-backed implementation stub
/// Production version integrating with Firebase
class FirestoreCommunicationRepository implements CommunicationRepository {
  FirestoreCommunicationRepository({
    required this.context,
    required this.defaultConfig,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final SecurityContext context;
  final CommunicationConfig defaultConfig;
  final FirebaseFirestore _firestore;

  bool get _canManage =>
      context.role.canManageClients || context.role.canManageAllAppointments;

  CollectionReference<Map<String, dynamic>> get _templatesCollection =>
      _firestore.collection('businesses').doc(context.businessId).collection(
            'message_templates',
          );

  CollectionReference<Map<String, dynamic>> get _rulesCollection => _firestore
      .collection('businesses')
      .doc(context.businessId)
      .collection('automation_rules');

  CollectionReference<Map<String, dynamic>> get _historyCollection =>
      _firestore.collection('businesses').doc(context.businessId).collection(
            'message_history',
          );

  DocumentReference<Map<String, dynamic>> get _configDoc => _firestore
      .collection('businesses')
      .doc(context.businessId)
      .collection('communications')
      .doc('config');

  @override
  Future<Map<MessageType, MessageTemplate>> getEmailTemplates() async {
    _requireManage();
    final snapshot = await _templatesCollection
        .where('channel', isEqualTo: MessageChannel.email.name)
        .get();

    if (snapshot.docs.isEmpty) {
      return Map.from(defaultConfig.emailTemplates);
    }

    return Map.fromEntries(
      snapshot.docs.map(
        (doc) => MapEntry(
          MessageType.values.byName(doc.data()['type'] as String),
          _templateFromDoc(doc),
        ),
      ),
    );
  }

  @override
  Future<Map<MessageType, MessageTemplate>> getSmsTemplates() async {
    _requireManage();
    final snapshot = await _templatesCollection
        .where('channel', isEqualTo: MessageChannel.sms.name)
        .get();

    if (snapshot.docs.isEmpty) {
      return Map.from(defaultConfig.smsTemplates);
    }

    return Map.fromEntries(
      snapshot.docs.map(
        (doc) => MapEntry(
          MessageType.values.byName(doc.data()['type'] as String),
          _templateFromDoc(doc),
        ),
      ),
    );
  }

  @override
  Future<void> updateTemplate(MessageTemplate template) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update message template');
    }
    _requireManage();
    final docId = '${template.channel.name}_${template.type.name}';
    await _templatesCollection.doc(docId).set(_templateToMap(template));
  }

  @override
  Future<List<AutomationRule>> getAutomationRules() async {
    _requireManage();
    final snapshot = await _rulesCollection.get();

    if (snapshot.docs.isEmpty) {
      return List<AutomationRule>.from(defaultConfig.automationRules);
    }

    return snapshot.docs
        .map((doc) => _ruleFromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> updateAutomationRule(AutomationRule rule) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update automation rule');
    }
    _requireManage();
    await _rulesCollection.doc(rule.id).set(_ruleToMap(rule));
  }

  @override
  Future<CommunicationConfig> getCommunicationConfig() async {
    _requireManage();
    final snapshot = await _configDoc.get();
    if (!snapshot.exists) return defaultConfig;
    return _configFromMap(snapshot.data() ?? {});
  }

  @override
  Future<void> updateCommunicationConfig(CommunicationConfig config) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update communication settings');
    }
    _requireManage();
    await _configDoc.set(_configToMap(config), SetOptions(merge: true));
  }

  @override
  Future<List<MessageHistory>> getMessageHistory({
    String? clientId,
    MessageChannel? channel,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query = _historyCollection;

    if (!_canManage && context.clientId == null) {
      throw SecurityException('Access denied: insufficient permissions');
    }

    // If client user, force filter to their own record
    final resolvedClientId = clientId ?? context.clientId;
    if (resolvedClientId != null) {
      query = query.where('clientId', isEqualTo: resolvedClientId);
    }
    if (channel != null) {
      query = query.where('channel', isEqualTo: channel.name);
    }
    if (startDate != null) {
      query =
          query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where(
        'timestamp',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    query = query.orderBy('timestamp', descending: true).limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => _messageFromDoc(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> logMessage(MessageHistory message) async {
    if (DemoConfig.isDemoMode) {
      return;
    }
    if (!_canManage &&
        !(context.clientId != null && context.clientId == message.clientId)) {
      throw SecurityException('Access denied: insufficient permissions');
    }

    await _historyCollection.doc(message.id).set(_messageToMap(message));
  }

  void _requireManage() {
    context.verifyBusinessAccess();
    if (!_canManage) {
      throw SecurityException(
        'Access denied: communications require admin/staff permissions',
      );
    }
  }

  MessageTemplate _templateFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MessageTemplate(
      type: MessageType.values.byName(data['type'] as String),
      channel: MessageChannel.values.byName(data['channel'] as String),
      subject: data['subject'] as String? ?? '',
      body: data['body'] as String? ?? '',
      variables: List<String>.from(data['variables'] as List? ?? const []),
    );
  }

  Map<String, dynamic> _templateToMap(MessageTemplate template) {
    return {
      'type': template.type.name,
      'channel': template.channel.name,
      'subject': template.subject,
      'body': template.body,
      'variables': template.variables,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _ruleToMap(AutomationRule rule) {
    return {
      'name': rule.name,
      'trigger': rule.trigger.name,
      'messageType': rule.messageType.name,
      'channels': rule.channels.map((c) => c.name).toList(),
      'delaySeconds': rule.delayDuration.inSeconds,
      'enabled': rule.enabled,
      'conditions': rule.conditions,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AutomationRule _ruleFromMap(Map<String, dynamic> data, String id) {
    return AutomationRule(
      id: id,
      name: data['name'] as String? ?? 'Automation',
      trigger: AutomationTrigger.values.byName(data['trigger'] as String),
      messageType: MessageType.values.byName(data['messageType'] as String),
      channels: ((data['channels'] as List?) ?? const [])
          .map((c) => MessageChannel.values.byName(c as String))
          .toSet(),
      delayDuration:
          Duration(seconds: (data['delaySeconds'] as int?) ?? (60 * 60 * 24)),
      enabled: data['enabled'] as bool? ?? true,
      conditions: data['conditions'] as Map<String, dynamic>?,
    );
  }

  CommunicationConfig _configFromMap(Map<String, dynamic> data) {
    return CommunicationConfig(
      senderEmail:
          (data['senderEmail'] as String?) ?? defaultConfig.senderEmail,
      senderName: (data['senderName'] as String?) ?? defaultConfig.senderName,
      replyToEmail: data['replyToEmail'] as String? ?? defaultConfig.replyToEmail,
      supportPhone:
          (data['supportPhone'] as String?) ?? defaultConfig.supportPhone,
      emailTemplates: defaultConfig.emailTemplates,
      smsTemplates: defaultConfig.smsTemplates,
      automationRules: defaultConfig.automationRules,
    );
  }

  Map<String, dynamic> _configToMap(CommunicationConfig config) {
    return {
      'senderEmail': config.senderEmail,
      'senderName': config.senderName,
      'replyToEmail': config.replyToEmail,
      'supportPhone': config.supportPhone,
      'emailEnabled': config.emailEnabled,
      'smsEnabled': config.smsEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _messageToMap(MessageHistory message) {
    return {
      'clientId': message.clientId,
      'clientName': message.clientName,
      'recipient': message.recipient,
      'channel': message.channel.name,
      'messageType': message.messageType.name,
      'subject': message.subject,
      'body': message.body,
      'timestamp': Timestamp.fromDate(message.timestamp),
      'status': message.status.name,
      'errorMessage': message.errorMessage,
      'appointmentId': message.appointmentId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  MessageHistory _messageFromDoc(
    String id,
    Map<String, dynamic> data,
  ) {
    return MessageHistory(
      id: id,
      clientId: data['clientId'] as String? ?? '',
      clientName: data['clientName'] as String? ?? '',
      recipient: data['recipient'] as String? ?? '',
      channel: MessageChannel.values.byName(data['channel'] as String),
      messageType: MessageType.values.byName(data['messageType'] as String),
      subject: data['subject'] as String? ?? '',
      body: data['body'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MessageStatus.values.byName(data['status'] as String),
      errorMessage: data['errorMessage'] as String?,
      appointmentId: data['appointmentId'] as String?,
    );
  }
}

/// Record of a sent message
class MessageHistory {
  const MessageHistory({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.recipient,
    required this.channel,
    required this.messageType,
    required this.subject,
    required this.body,
    required this.timestamp,
    required this.status,
    this.errorMessage,
    this.appointmentId,
  });

  final String id;
  final String clientId;
  final String clientName;
  final String recipient; // email or phone
  final MessageChannel channel;
  final MessageType messageType;
  final String subject;
  final String body;
  final DateTime timestamp;
  final MessageStatus status;
  final String? errorMessage;
  final String? appointmentId;

  factory MessageHistory.fromEmailLog({
    required String clientId,
    required String clientName,
    required String recipientEmail,
    required String subject,
    required String body,
    required MessageType messageType,
    required bool success,
    String? errorMessage,
    String? appointmentId,
  }) {
    return MessageHistory(
      id: 'email_${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      clientName: clientName,
      recipient: recipientEmail,
      channel: MessageChannel.email,
      messageType: messageType,
      subject: subject,
      body: body,
      timestamp: DateTime.now(),
      status: success ? MessageStatus.sent : MessageStatus.failed,
      errorMessage: errorMessage,
      appointmentId: appointmentId,
    );
  }

  factory MessageHistory.fromSmsLog({
    required String clientId,
    required String clientName,
    required String recipientPhone,
    required String message,
    required MessageType messageType,
    required bool success,
    String? errorMessage,
    String? appointmentId,
  }) {
    return MessageHistory(
      id: 'sms_${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      clientName: clientName,
      recipient: recipientPhone,
      channel: MessageChannel.sms,
      messageType: messageType,
      subject: '',
      body: message,
      timestamp: DateTime.now(),
      status: success ? MessageStatus.sent : MessageStatus.failed,
      errorMessage: errorMessage,
      appointmentId: appointmentId,
    );
  }
}

/// Status of a sent message
enum MessageStatus {
  sent,
  failed,
  pending,
  bounced,
}
