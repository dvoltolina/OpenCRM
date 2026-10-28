import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

DateTime? _dateTimeFromJson(dynamic json) {
  if (json == null) return null;
  if (json is DateTime) return json;
  if (json is Timestamp) return json.toDate();
  if (json is String) return DateTime.tryParse(json);
  if (json is num) {
    // Accept milliseconds since epoch
    return DateTime.fromMillisecondsSinceEpoch(json.toInt());
  }
  return null;
}

dynamic _dateTimeToJson(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);

/// Firestore Timestamp / ISO8601 / millis -> DateTime
class TimestampConverter implements JsonConverter<DateTime, dynamic> {
  const TimestampConverter();

  @override
  DateTime fromJson(dynamic json) {
    final parsed = _dateTimeFromJson(json);
    if (parsed == null) {
      throw ArgumentError('Cannot convert $json to DateTime');
    }
    return parsed;
  }

  @override
  dynamic toJson(DateTime object) => _dateTimeToJson(object);
}

/// Firestore Timestamp / ISO8601 / millis -> DateTime?
class NullableTimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(dynamic json) => _dateTimeFromJson(json);

  @override
  dynamic toJson(DateTime? object) => _dateTimeToJson(object);
}

/// Converter for lists of DateTime.
class TimestampListConverter
    implements JsonConverter<List<DateTime>, List<dynamic>> {
  const TimestampListConverter();

  @override
  List<DateTime> fromJson(List<dynamic> json) =>
      json.map((value) => const TimestampConverter().fromJson(value)).toList();

  @override
  List<dynamic> toJson(List<DateTime> object) =>
      object.map(_dateTimeToJson).toList();
}

/// Converter for nullable lists of DateTime.
class NullableTimestampListConverter
    implements JsonConverter<List<DateTime>?, List<dynamic>?> {
  const NullableTimestampListConverter();

  @override
  List<DateTime>? fromJson(List<dynamic>? json) =>
      json?.map((value) => const TimestampConverter().fromJson(value)).toList();

  @override
  List<dynamic>? toJson(List<DateTime>? object) =>
      object?.map(_dateTimeToJson).toList();
}

/// Converter for maps of DateTime values keyed by String.
class TimestampMapConverter
    implements JsonConverter<Map<String, DateTime>, Map<String, dynamic>> {
  const TimestampMapConverter();

  @override
  Map<String, DateTime> fromJson(Map<String, dynamic> json) => json.map(
        (key, value) => MapEntry(
          key,
          const TimestampConverter().fromJson(value),
        ),
      );

  @override
  Map<String, dynamic> toJson(Map<String, DateTime> object) =>
      object.map((key, value) => MapEntry(key, _dateTimeToJson(value)));
}

/// Converter for nullable maps of DateTime values keyed by String.
class NullableTimestampMapConverter
    implements
        JsonConverter<Map<String, DateTime?>?, Map<String, dynamic>?> {
  const NullableTimestampMapConverter();

  @override
  Map<String, DateTime?>? fromJson(Map<String, dynamic>? json) => json?.map(
        (key, value) => MapEntry(
          key,
          const NullableTimestampConverter().fromJson(value),
        ),
      );

  @override
  Map<String, dynamic>? toJson(Map<String, DateTime?>? object) =>
      object?.map((key, value) => MapEntry(key, _dateTimeToJson(value)));
}

/// Default converter set for Firestore timestamps across models.
///
/// Nullable fields are handled by generated null checks before invoking these
/// converters, so we only include the non-nullable variants here to avoid
/// ambiguous matches.
const dateTimeJsonConverters = <JsonConverter<dynamic, dynamic>>[
  TimestampConverter(),
  TimestampListConverter(),
  TimestampMapConverter(),
];
