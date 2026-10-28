import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/demo_guard_service.dart';
import '../models/conversation.dart';
import '../models/security_context.dart';

/// Repository for managing conversations and messages.
/// Multi-tenant: conversations are scoped to businessId.
class MessagingRepository {
  MessagingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _conversations(String businessId) =>
      _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('conversations');

  CollectionReference<Map<String, dynamic>> _messages(
    String businessId,
    String conversationId,
  ) => _conversations(businessId).doc(conversationId).collection('messages');

  // ─────────────────────────────────────────────────────────────────────────
  // Conversations
  // ─────────────────────────────────────────────────────────────────────────

  /// Watch all conversations for a user within a business.
  Stream<List<Conversation>> watchConversations({
    required SecurityContext context,
    bool includeArchived = false,
  }) {
    Query<Map<String, dynamic>> query = _conversations(context.businessId)
        .where('participantIds', arrayContains: context.userId)
        .orderBy('lastMessageAt', descending: true);

    if (!includeArchived) {
      query = query.where('isArchived', isEqualTo: false);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Conversation.fromJson({'id': doc.id, ...doc.data()}))
          .toList(),
    );
  }

  /// Get total unread message count across all conversations.
  Stream<int> watchTotalUnreadCount({required SecurityContext context}) {
    return watchConversations(context: context).map(
      (conversations) => conversations.fold(
        0,
        (total, c) => total + c.unreadCountFor(context.userId),
      ),
    );
  }

  /// Get a single conversation by ID.
  Future<Conversation?> getConversation({
    required SecurityContext context,
    required String conversationId,
  }) async {
    final doc = await _conversations(
      context.businessId,
    ).doc(conversationId).get();
    if (!doc.exists) return null;

    final conversation = Conversation.fromJson({'id': doc.id, ...doc.data()!});

    // Verify user is a participant
    if (!conversation.hasParticipant(context.userId)) {
      throw SecurityException('Not a participant in this conversation');
    }

    return conversation;
  }

  /// Find or create a 1:1 conversation between two users.
  Future<Conversation> getOrCreateDirectConversation({
    required SecurityContext context,
    required ConversationParticipant otherParticipant,
    String? appointmentId,
  }) async {
    // Check for existing conversation
    final existing = await _conversations(
      context.businessId,
    ).where('participantIds', arrayContains: context.userId).get();

    for (final doc in existing.docs) {
      final conv = Conversation.fromJson({'id': doc.id, ...doc.data()});
      if (conv.participantIds.length == 2 &&
          conv.participantIds.contains(otherParticipant.id)) {
        return conv;
      }
    }

    // Create new conversation
    return _createConversation(
      context: context,
      participants: [
        ConversationParticipant(
          id: context.userId,
          name: context.userFullName ?? 'User',
          isStaff: context.role.canManageClients,
        ),
        otherParticipant,
      ],
      appointmentId: appointmentId,
    );
  }

  Future<Conversation> _createConversation({
    required SecurityContext context,
    required List<ConversationParticipant> participants,
    String? subject,
    String? appointmentId,
  }) async {
    DemoGuardService.assertReadOnly('start conversation');
    final id = _conversations(context.businessId).doc().id;
    final now = DateTime.now();

    final conversation = Conversation(
      id: id,
      businessId: context.businessId,
      participants: participants,
      participantIds: participants.map((p) => p.id).toList(),
      subject: subject,
      appointmentId: appointmentId,
      createdAt: now,
      updatedAt: now,
    );

    await _conversations(context.businessId).doc(id).set(conversation.toJson());
    return conversation;
  }

  /// Archive a conversation (hide from list but don't delete).
  Future<void> archiveConversation({
    required SecurityContext context,
    required String conversationId,
  }) async {
    DemoGuardService.assertReadOnly('archive conversation');
    await _conversations(
      context.businessId,
    ).doc(conversationId).update({'isArchived': true});
  }

  /// Unarchive a conversation.
  Future<void> unarchiveConversation({
    required SecurityContext context,
    required String conversationId,
  }) async {
    DemoGuardService.assertReadOnly('unarchive conversation');
    await _conversations(
      context.businessId,
    ).doc(conversationId).update({'isArchived': false});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Messages
  // ─────────────────────────────────────────────────────────────────────────

  /// Watch messages in a conversation.
  Stream<List<Message>> watchMessages({
    required SecurityContext context,
    required String conversationId,
    int limit = 50,
  }) {
    return _messages(context.businessId, conversationId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Message.fromJson({'id': doc.id, ...doc.data()}))
              .toList()
              .reversed
              .toList(),
        ); // Reverse for chronological order
  }

  /// Load older messages for pagination.
  Future<List<Message>> loadMoreMessages({
    required SecurityContext context,
    required String conversationId,
    required DateTime beforeTimestamp,
    int limit = 50,
  }) async {
    final snapshot = await _messages(context.businessId, conversationId)
        .orderBy('createdAt', descending: true)
        .startAfter([Timestamp.fromDate(beforeTimestamp)])
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => Message.fromJson({'id': doc.id, ...doc.data()}))
        .toList()
        .reversed
        .toList();
  }

  /// Send a new message.
  Future<Message> sendMessage({
    required SecurityContext context,
    required String conversationId,
    required String content,
    List<MessageAttachment>? attachments,
  }) async {
    DemoGuardService.assertReadOnly('send message');
    final id = _messages(context.businessId, conversationId).doc().id;
    final now = DateTime.now();

    final message = Message(
      id: id,
      conversationId: conversationId,
      senderId: context.userId,
      senderName: context.userFullName ?? 'User',
      content: content,
      createdAt: now,
      attachments: attachments ?? [],
    );

    final batch = _firestore.batch();

    // Add message
    batch.set(
      _messages(context.businessId, conversationId).doc(id),
      message.toJson(),
    );

    // Update conversation with last message info
    batch.update(_conversations(context.businessId).doc(conversationId), {
      'lastMessageText': content.length > 100
          ? '${content.substring(0, 100)}...'
          : content,
      'lastMessageSenderId': context.userId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Increment unread for other participants (async, non-blocking)
    _incrementUnreadForOthers(context, conversationId);

    return message;
  }

  Future<void> _incrementUnreadForOthers(
    SecurityContext context,
    String conversationId,
  ) async {
    final conv = await getConversation(
      context: context,
      conversationId: conversationId,
    );
    if (conv == null) return;

    final updates = <String, dynamic>{};
    for (final participantId in conv.participantIds) {
      if (participantId != context.userId) {
        updates['unreadCounts.$participantId'] = FieldValue.increment(1);
      }
    }

    if (updates.isNotEmpty) {
      await _conversations(
        context.businessId,
      ).doc(conversationId).update(updates);
    }
  }

  /// Mark conversation as read for current user.
  Future<void> markConversationAsRead({
    required SecurityContext context,
    required String conversationId,
  }) async {
    DemoGuardService.assertReadOnly('mark conversation read');
    await _conversations(
      context.businessId,
    ).doc(conversationId).update({'unreadCounts.${context.userId}': 0});
  }

  /// Edit a message (only sender can edit).
  Future<void> editMessage({
    required SecurityContext context,
    required String conversationId,
    required String messageId,
    required String newContent,
  }) async {
    DemoGuardService.assertReadOnly('edit message');
    final doc = await _messages(
      context.businessId,
      conversationId,
    ).doc(messageId).get();
    if (!doc.exists) return;

    final message = Message.fromJson({'id': doc.id, ...doc.data()!});
    if (message.senderId != context.userId) {
      throw SecurityException('Only the sender can edit a message');
    }

    await _messages(context.businessId, conversationId).doc(messageId).update({
      'content': newContent,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Soft-delete a message (only sender can delete).
  Future<void> deleteMessage({
    required SecurityContext context,
    required String conversationId,
    required String messageId,
  }) async {
    DemoGuardService.assertReadOnly('delete message');
    final doc = await _messages(
      context.businessId,
      conversationId,
    ).doc(messageId).get();
    if (!doc.exists) return;

    final message = Message.fromJson({'id': doc.id, ...doc.data()!});
    final canDelete =
        message.senderId == context.userId ||
        context.role == UserRole.admin ||
        context.role == UserRole.owner;
    if (!canDelete) {
      throw SecurityException('Cannot delete this message');
    }

    await _messages(context.businessId, conversationId).doc(messageId).update({
      'isDeleted': true,
      'deletedByUserId': context.userId,
      'content': '', // Clear content for privacy
    });
  }
}
