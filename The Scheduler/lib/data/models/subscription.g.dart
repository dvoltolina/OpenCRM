// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Subscription _$SubscriptionFromJson(Map<String, dynamic> json) =>
    _Subscription(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      tier: $enumDecode(_$SubscriptionTierEnumMap, json['tier']),
      status: $enumDecode(_$SubscriptionStatusEnumMap, json['status']),
      stripeCustomerId: json['stripeCustomerId'] as String,
      stripeSubscriptionId: json['stripeSubscriptionId'] as String?,
      stripePriceId: json['stripePriceId'] as String?,
      currentPeriodStart: const TimestampConverter().fromJson(
        json['currentPeriodStart'],
      ),
      currentPeriodEnd: const TimestampConverter().fromJson(
        json['currentPeriodEnd'],
      ),
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] as bool? ?? false,
      trialEnd: const NullableTimestampConverter().fromJson(json['trialEnd']),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
      canceledAt: const NullableTimestampConverter().fromJson(
        json['canceledAt'],
      ),
      addOns: json['addOns'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$SubscriptionToJson(
  _Subscription instance,
) => <String, dynamic>{
  'id': instance.id,
  'businessId': instance.businessId,
  'tier': _$SubscriptionTierEnumMap[instance.tier]!,
  'status': _$SubscriptionStatusEnumMap[instance.status]!,
  'stripeCustomerId': instance.stripeCustomerId,
  'stripeSubscriptionId': instance.stripeSubscriptionId,
  'stripePriceId': instance.stripePriceId,
  'currentPeriodStart': const TimestampConverter().toJson(
    instance.currentPeriodStart,
  ),
  'currentPeriodEnd': const TimestampConverter().toJson(
    instance.currentPeriodEnd,
  ),
  'cancelAtPeriodEnd': instance.cancelAtPeriodEnd,
  'trialEnd': const NullableTimestampConverter().toJson(instance.trialEnd),
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
  'canceledAt': const NullableTimestampConverter().toJson(instance.canceledAt),
  'addOns': instance.addOns,
};

const _$SubscriptionTierEnumMap = {
  SubscriptionTier.free: 'free',
  SubscriptionTier.starter: 'starter',
  SubscriptionTier.professional: 'professional',
  SubscriptionTier.enterprise: 'enterprise',
};

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.active: 'active',
  SubscriptionStatus.trialing: 'trialing',
  SubscriptionStatus.pastDue: 'past_due',
  SubscriptionStatus.canceled: 'canceled',
  SubscriptionStatus.incomplete: 'incomplete',
  SubscriptionStatus.incompleteExpired: 'incomplete_expired',
  SubscriptionStatus.unpaid: 'unpaid',
};
