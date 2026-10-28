// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionNoteAudit _$SessionNoteAuditFromJson(Map<String, dynamic> json) =>
    _SessionNoteAudit(
      id: json['id'] as String,
      action: json['action'] as String,
      userId: json['userId'] as String,
      userFullName: json['userFullName'] as String,
      timestamp: const TimestampConverter().fromJson(json['timestamp']),
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      changesSummary: json['changesSummary'] as String?,
    );

Map<String, dynamic> _$SessionNoteAuditToJson(_SessionNoteAudit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'action': instance.action,
      'userId': instance.userId,
      'userFullName': instance.userFullName,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
      'ipAddress': instance.ipAddress,
      'userAgent': instance.userAgent,
      'changesSummary': instance.changesSummary,
    };

_SessionNote _$SessionNoteFromJson(Map<String, dynamic> json) => _SessionNote(
  id: json['id'] as String,
  businessId: json['businessId'] as String,
  appointmentId: json['appointmentId'] as String,
  clientId: json['clientId'] as String,
  providerId: json['providerId'] as String,
  noteType: $enumDecode(_$SessionNoteTypeEnumMap, json['noteType']),
  visibility:
      $enumDecodeNullable(_$SessionNoteVisibilityEnumMap, json['visibility']) ??
      SessionNoteVisibility.providerOnly,
  encryptedContent: json['encryptedContent'] as String,
  title: json['title'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isLocked: json['isLocked'] as bool? ?? false,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
  createdBy: json['createdBy'] as String,
  createdByName: json['createdByName'] as String,
  lastEditedBy: json['lastEditedBy'] as String?,
  lastEditedByName: json['lastEditedByName'] as String?,
  auditLog:
      (json['auditLog'] as List<dynamic>?)
          ?.map((e) => SessionNoteAudit.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  retainIndefinitely: json['retainIndefinitely'] as bool? ?? true,
  isPsychotherapyNote: json['isPsychotherapyNote'] as bool? ?? false,
);

Map<String, dynamic> _$SessionNoteToJson(
  _SessionNote instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'appointmentId': instance.appointmentId,
  'clientId': instance.clientId,
  'providerId': instance.providerId,
  'noteType': _$SessionNoteTypeEnumMap[instance.noteType]!,
  'visibility': _$SessionNoteVisibilityEnumMap[instance.visibility]!,
  'encryptedContent': instance.encryptedContent,
  'title': instance.title,
  'tags': instance.tags,
  'isLocked': instance.isLocked,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
  'createdBy': instance.createdBy,
  'createdByName': instance.createdByName,
  'lastEditedBy': instance.lastEditedBy,
  'lastEditedByName': instance.lastEditedByName,
  'auditLog': instance.auditLog.map((e) => e.toJson()).toList(),
  'retainIndefinitely': instance.retainIndefinitely,
  'isPsychotherapyNote': instance.isPsychotherapyNote,
};

const _$SessionNoteTypeEnumMap = {
  SessionNoteType.soap: 'soap',
  SessionNoteType.progressNote: 'progressNote',
  SessionNoteType.treatmentPlan: 'treatmentPlan',
  SessionNoteType.procedureLog: 'procedureLog',
  SessionNoteType.adjustmentNote: 'adjustmentNote',
  SessionNoteType.intakeAssessment: 'intakeAssessment',
  SessionNoteType.dischargeNote: 'dischargeNote',
  SessionNoteType.psychNote: 'psychNote',
  SessionNoteType.custom: 'custom',
};

const _$SessionNoteVisibilityEnumMap = {
  SessionNoteVisibility.providerOnly: 'providerOnly',
  SessionNoteVisibility.businessOnly: 'businessOnly',
  SessionNoteVisibility.shared: 'shared',
};
