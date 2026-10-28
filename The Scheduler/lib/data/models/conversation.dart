import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

/// Participant in a conversation (client or staff member).
@freezed
abstract class ConversationParticipant with _$ConversationParticipant {
  const factory ConversationParticipant({
    required String id,
    required String name,
    String? avatarUrl,
    @Default(false) bool isStaff,
    /// Last time this participant read the conversation
    @NullableTimestampConverter() DateTime? lastReadAt,
  }) = _ConversationParticipant;

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) =>
      _$ConversationParticipantFromJson(json);
}

/// A conversation thread between participants.
/// Supports 1:1 (client-provider) or group conversations.
@freezed
abstract class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    required String businessId,
    required List<ConversationParticipant> participants,
    /// User IDs of all participants for querying
    required List<String> participantIds,
    String? subject,
    /// Optional link to related appointment
    String? appointmentId,
    /// Last message preview for list display
    String? lastMessageText,
    String? lastMessageSenderId,
    @NullableTimestampConverter() DateTime? lastMessageAt,
    /// Unread count per user: { oderId: count }
    @Default({}) Map<String, int> unreadCounts,
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
    /// If true, only staff can initiate messages (client can reply)
    @Default(false) bool staffInitiatedOnly,
    /// Archived conversations are hidden but not deleted
    @Default(false) bool isArchived,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}

/// Message attachment (file, image, etc.).
@freezed
abstract class MessageAttachment with _$MessageAttachment {
  const factory MessageAttachment({
    required String id,
    required String fileName,
    required String url,
    required String mimeType,
    int? sizeBytes,
  }) = _MessageAttachment;

  factory MessageAttachment.fromJson(Map<String, dynamic> json) =>
      _$MessageAttachmentFromJson(json);
}

/// A single message within a conversation.
@freezed
abstract class Message with _$Message {
  const factory Message({
    required String id,
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? editedAt,
    @Default(false) bool isEdited,
    @Default(false) bool isDeleted,
    /// For soft delete - show "This message was deleted"
    String? deletedByUserId,
    /// Attachments (images, files)
    @Default([]) List<MessageAttachment> attachments,
    /// Read receipts: { oderId: readAt }
    @TimestampMapConverter() @Default({}) Map<String, DateTime> readBy,
    /// System message (e.g., "X joined the conversation")
    @Default(false) bool isSystemMessage,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

extension ConversationExtensions on Conversation {
  /// Get unread count for a specific user.
  int unreadCountFor(String userId) => unreadCounts[userId] ?? 0;

  /// Get the other participant in a 1:1 conversation.
  ConversationParticipant? otherParticipant(String currentUserId) {
    if (participants.length != 2) return null;
    return participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
  }

  /// Check if user is a participant.
  bool hasParticipant(String userId) => participantIds.contains(userId);
}
