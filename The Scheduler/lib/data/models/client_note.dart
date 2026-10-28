import '../converters/timestamp_converters.dart';

/// Simple client note model (non-freezed) to avoid generated parts.
class ClientNote {
  ClientNote({
    required this.id,
    required this.clientId,
    required this.content,
    required this.type,
    required this.createdByUserId,
    required this.createdByName,
    required this.createdAt,
  });

  final String id;
  final String clientId;
  final String content;
  final NoteType type;
  final String createdByUserId;
  final String createdByName;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'content': content,
      'type': type.name,
      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
      'createdAt': const TimestampConverter().toJson(createdAt),
    };
  }

  factory ClientNote.fromJson(Map<String, dynamic> json) {
    return ClientNote(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      content: json['content'] as String,
      type: NoteType.values.firstWhere(
        (n) => n.name == (json['type'] as String? ?? ''),
        orElse: () => NoteType.other,
      ),
      createdByUserId: json['createdByUserId'] as String,
      createdByName: json['createdByName'] as String? ?? '',
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
    );
  }
}

/// Note classification for sales follow-ups.
enum NoteType { call, meeting, email, followUp, other }
