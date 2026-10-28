// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LocalAppointmentImpl _$$LocalAppointmentImplFromJson(
        Map<String, dynamic> json) =>
    _$LocalAppointmentImpl(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      clientId: json['clientId'] as String,
      serviceId: json['serviceId'] as String,
      locationId: json['locationId'] as String,
      clientName: json['clientName'] as String?,
      clientPhone: json['clientPhone'] as String?,
      clientEmail: json['clientEmail'] as String?,
      clientAddress: json['clientAddress'] as String?,
      serviceName: json['serviceName'] as String?,
      locationName: json['locationName'] as String?,
      serviceDurationMinutes: (json['serviceDurationMinutes'] as num?)?.toInt(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      staffNotes: json['staffNotes'] as String?,
      requiresPayment: json['requiresPayment'] as bool? ?? false,
      paymentStatus: json['paymentStatus'] as String?,
      localUpdatedAt: json['localUpdatedAt'] == null
          ? null
          : DateTime.parse(json['localUpdatedAt'] as String),
      pendingSync: json['pendingSync'] as bool? ?? false,
      syncAction: json['syncAction'] as String?,
      checkedInAt: json['checkedInAt'] == null
          ? null
          : DateTime.parse(json['checkedInAt'] as String),
      checkedInByStaffId: json['checkedInByStaffId'] as String?,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      completedByStaffId: json['completedByStaffId'] as String?,
    );

Map<String, dynamic> _$$LocalAppointmentImplToJson(
        _$LocalAppointmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'clientId': instance.clientId,
      'serviceId': instance.serviceId,
      'locationId': instance.locationId,
      'clientName': instance.clientName,
      'clientPhone': instance.clientPhone,
      'clientEmail': instance.clientEmail,
      'clientAddress': instance.clientAddress,
      'serviceName': instance.serviceName,
      'locationName': instance.locationName,
      'serviceDurationMinutes': instance.serviceDurationMinutes,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'status': instance.status,
      'notes': instance.notes,
      'staffNotes': instance.staffNotes,
      'requiresPayment': instance.requiresPayment,
      'paymentStatus': instance.paymentStatus,
      'localUpdatedAt': instance.localUpdatedAt?.toIso8601String(),
      'pendingSync': instance.pendingSync,
      'syncAction': instance.syncAction,
      'checkedInAt': instance.checkedInAt?.toIso8601String(),
      'checkedInByStaffId': instance.checkedInByStaffId,
      'completedAt': instance.completedAt?.toIso8601String(),
      'completedByStaffId': instance.completedByStaffId,
    };
