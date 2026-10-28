import 'file_attachment.dart';

class IntakeFormDraft {
  IntakeFormDraft({
    required this.id,
    required this.businessId,
    required this.templateId,
    required this.clientId,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    this.templateName,
    this.appointmentId,
    this.responses = const {},
    this.attachments = const [],
    this.status = 'draft',
  });

  final String id;
  final String businessId;
  final String templateId;
  final String clientId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;
  final String? templateName;
  final String? appointmentId;
  final Map<String, dynamic> responses;
  final List<FileAttachment> attachments;
  final String status; // draft | submitted | expired

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Alias for templateName for UI consistency
  String get formTitle => templateName ?? 'Untitled Form';

  /// Days until the draft expires (negative if expired)
  int get daysUntilExpiration {
    final now = DateTime.now();
    return expiresAt.difference(now).inDays;
  }

  IntakeFormDraft copyWith({
    String? id,
    String? businessId,
    String? templateId,
    String? clientId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    String? templateName,
    String? appointmentId,
    Map<String, dynamic>? responses,
    List<FileAttachment>? attachments,
    String? status,
  }) {
    return IntakeFormDraft(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      templateId: templateId ?? this.templateId,
      clientId: clientId ?? this.clientId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      templateName: templateName ?? this.templateName,
      appointmentId: appointmentId ?? this.appointmentId,
      responses: responses ?? this.responses,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'templateId': templateId,
      'clientId': clientId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'templateName': templateName,
      'appointmentId': appointmentId,
      'responses': responses,
      'attachments': attachments.map((file) => file.toJson()).toList(),
      'status': status,
    };
  }

  factory IntakeFormDraft.fromJson(Map<String, dynamic> json) {
    return IntakeFormDraft(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      templateId: json['templateId'] as String,
      clientId: json['clientId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      templateName: json['templateName'] as String?,
      appointmentId: json['appointmentId'] as String?,
      responses: Map<String, dynamic>.from(
        json['responses'] as Map<String, dynamic>? ?? {},
      ),
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            map.putIfAbsent('businessId', () => json['businessId'] as String);
            map.putIfAbsent(
              'id',
              () =>
                  map['name'] ??
                  'legacy_${DateTime.now().millisecondsSinceEpoch}',
            );
            map.putIfAbsent(
              'storagePath',
              () => 'legacy/${map['id']}',
            );
            map.putIfAbsent(
              'uploadedAt',
              () => DateTime.now().toIso8601String(),
            );
            return FileAttachment.fromJson(map);
          })
          .toList(),
      status: json['status'] as String? ?? 'draft',
    );
  }
}
