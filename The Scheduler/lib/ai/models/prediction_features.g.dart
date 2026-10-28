// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prediction_features.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PredictionFeatures _$PredictionFeaturesFromJson(
  Map<String, dynamic> json,
) => _PredictionFeatures(
  appointmentId: json['appointmentId'] as String,
  businessId: json['businessId'] as String,
  extractedAt: DateTime.parse(json['extractedAt'] as String),
  featureSchemaVersion: (json['featureSchemaVersion'] as num).toInt(),
  clientHistoricalNoshowRate: (json['clientHistoricalNoshowRate'] as num)
      .toDouble(),
  clientHistoricalCancelRate: (json['clientHistoricalCancelRate'] as num)
      .toDouble(),
  clientTotalAppointments: (json['clientTotalAppointments'] as num).toInt(),
  clientDaysSinceLastVisit: (json['clientDaysSinceLastVisit'] as num).toInt(),
  clientLifetimeValueCents: (json['clientLifetimeValueCents'] as num).toInt(),
  clientLifecycleStage: json['clientLifecycleStage'] as String,
  clientHasPaymentMethod: json['clientHasPaymentMethod'] as bool,
  bookingLeadDays: (json['bookingLeadDays'] as num).toInt(),
  dayOfWeek: (json['dayOfWeek'] as num).toInt(),
  hourOfDay: (json['hourOfDay'] as num).toInt(),
  isRecurring: json['isRecurring'] as bool,
  isGroupSession: json['isGroupSession'] as bool,
  serviceDurationMinutes: (json['serviceDurationMinutes'] as num).toInt(),
  servicePriceCents: (json['servicePriceCents'] as num).toInt(),
  requiresPayment: json['requiresPayment'] as bool,
  paymentCollected: json['paymentCollected'] as bool,
  hasIntakeForm: json['hasIntakeForm'] as bool,
  providerHistoricalNoshowRate: (json['providerHistoricalNoshowRate'] as num)
      .toDouble(),
  providerTotalAppointments: (json['providerTotalAppointments'] as num).toInt(),
  slotHistoricalNoshowRate: (json['slotHistoricalNoshowRate'] as num)
      .toDouble(),
  isFirstAppointmentOfDay: json['isFirstAppointmentOfDay'] as bool,
  isLastAppointmentOfDay: json['isLastAppointmentOfDay'] as bool,
);

Map<String, dynamic> _$PredictionFeaturesToJson(_PredictionFeatures instance) =>
    <String, dynamic>{
      'appointmentId': instance.appointmentId,
      'businessId': instance.businessId,
      'extractedAt': instance.extractedAt.toIso8601String(),
      'featureSchemaVersion': instance.featureSchemaVersion,
      'clientHistoricalNoshowRate': instance.clientHistoricalNoshowRate,
      'clientHistoricalCancelRate': instance.clientHistoricalCancelRate,
      'clientTotalAppointments': instance.clientTotalAppointments,
      'clientDaysSinceLastVisit': instance.clientDaysSinceLastVisit,
      'clientLifetimeValueCents': instance.clientLifetimeValueCents,
      'clientLifecycleStage': instance.clientLifecycleStage,
      'clientHasPaymentMethod': instance.clientHasPaymentMethod,
      'bookingLeadDays': instance.bookingLeadDays,
      'dayOfWeek': instance.dayOfWeek,
      'hourOfDay': instance.hourOfDay,
      'isRecurring': instance.isRecurring,
      'isGroupSession': instance.isGroupSession,
      'serviceDurationMinutes': instance.serviceDurationMinutes,
      'servicePriceCents': instance.servicePriceCents,
      'requiresPayment': instance.requiresPayment,
      'paymentCollected': instance.paymentCollected,
      'hasIntakeForm': instance.hasIntakeForm,
      'providerHistoricalNoshowRate': instance.providerHistoricalNoshowRate,
      'providerTotalAppointments': instance.providerTotalAppointments,
      'slotHistoricalNoshowRate': instance.slotHistoricalNoshowRate,
      'isFirstAppointmentOfDay': instance.isFirstAppointmentOfDay,
      'isLastAppointmentOfDay': instance.isLastAppointmentOfDay,
    };
