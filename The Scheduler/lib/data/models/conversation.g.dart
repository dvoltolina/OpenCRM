// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConversationParticipant _$ConversationParticipantFromJson(
  Map<String, dynamic> json,
) => _ConversationParticipant(
  id: json['id'] as String,
  name: json['name'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  isStaff: json['isStaff'] as bool? ?? false,
  lastReadAt: const NullableTimestampConverter().fromJson(json['lastReadAt']),
);

Map<String, dynamic> _$ConversationParticipantToJson(
  _ConversationParticipant instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'avatarUrl': instance.avatarUrl,
  'isStaff': instance.isStaff,
  'lastReadAt': const NullableTimestampConverter().toJson(instance.lastReadAt),
};

_Conversation _$ConversationFromJson(Map<String, dynamic> json) =>
    _Conversation(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      participants: (json['participants'] as List<dynamic>)
          .map(
            (e) => ConversationParticipant.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      participantIds: (json['participantIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      subject: json['subject'] as String?,
      appointmentId: json['appointmentId'] as String?,
      lastMessageText: json['lastMessageText'] as String?,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      lastMessageAt: const NullableTimestampConverter().fromJson(
        json['lastMessageAt'],
      ),
      unreadCounts:
          (json['unreadCounts'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
      staffInitiatedOnly: json['staffInitiatedOnly'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
    );

Map<String, dynamic> _$ConversationToJson(
  _Conversation instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'participants': instance.participants.map((e) => e.toJson()).toList(),
  'participantIds': instance.participantIds,
  'subject': instance.subject,
  'appointmentId': instance.appointmentId,
  'lastMessageText': instance.lastMessageText,
  'lastMessageSenderId': instance.lastMessageSenderId,
  'lastMessageAt': const NullableTimestampConverter().toJson(
    instance.lastMessageAt,
  ),
  'unreadCounts': instance.unreadCounts,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
  'staffInitiatedOnly': instance.staffInitiatedOnly,
  'isArchived': instance.isArchived,
};

_MessageAttachment _$MessageAttachmentFromJson(Map<String, dynamic> json) =>
    _MessageAttachment(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      url: json['url'] as String,
      mimeType: json['mimeType'] as String,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MessageAttachmentToJson(_MessageAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'url': instance.url,
      'mimeType': instance.mimeType,
      'sizeBytes': instance.sizeBytes,
    };

_Message _$MessageFromJson(Map<String, dynamic> json) => _Message(
  id: json['id'] as String,
  conversationId: json['conversationId'] as String,
  senderId: json['senderId'] as String,
  senderName: json['senderName'] as String,
  content: json['content'] as String,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  editedAt: const NullableTimestampConverter().fromJson(json['editedAt']),
  isEdited: json['isEdited'] as bool? ?? false,
  isDeleted: json['isDeleted'] as bool? ?? false,
  deletedByUserId: json['deletedByUserId'] as String?,
  attachments:
      (json['attachments'] as List<dynamic>?)
          ?.map((e) => MessageAttachment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  readBy: json['readBy'] == null
      ? const {}
      : const TimestampMapConverter().fromJson(
          json['readBy'] as Map<String, dynamic>,
        ),
  isSystemMessage: json['isSystemMessage'] as bool? ?? false,
);

Map<String, dynamic> _$MessageToJson(_Message instance) => <String, dynamic>{
  'id': instance.id,
  'conversationId': instance.conversationId,
  'senderId': instance.senderId,
  'senderName': instance.senderName,
  'content': instance.content,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'editedAt': const NullableTimestampConverter().toJson(instance.editedAt),
  'isEdited': instance.isEdited,
  'isDeleted': instance.isDeleted,
  'deletedByUserId': instance.deletedByUserId,
  'attachments': instance.attachments.map((e) => e.toJson()).toList(),
  'readBy': const TimestampMapConverter().toJson(instance.readBy),
  'isSystemMessage': instance.isSystemMessage,
};
