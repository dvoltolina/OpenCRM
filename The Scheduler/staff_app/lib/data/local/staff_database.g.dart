// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_database.dart';

// ignore_for_file: type=lint
class $AppointmentsTableTable extends AppointmentsTable
    with TableInfo<$AppointmentsTableTable, AppointmentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppointmentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _businessIdMeta =
      const VerificationMeta('businessId');
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
      'business_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _staffIdMeta =
      const VerificationMeta('staffId');
  @override
  late final GeneratedColumn<String> staffId = GeneratedColumn<String>(
      'staff_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _clientIdMeta =
      const VerificationMeta('clientId');
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
      'client_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serviceIdMeta =
      const VerificationMeta('serviceId');
  @override
  late final GeneratedColumn<String> serviceId = GeneratedColumn<String>(
      'service_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _locationIdMeta =
      const VerificationMeta('locationId');
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
      'location_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientNameMeta =
      const VerificationMeta('clientName');
  @override
  late final GeneratedColumn<String> clientName = GeneratedColumn<String>(
      'client_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clientPhoneMeta =
      const VerificationMeta('clientPhone');
  @override
  late final GeneratedColumn<String> clientPhone = GeneratedColumn<String>(
      'client_phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clientEmailMeta =
      const VerificationMeta('clientEmail');
  @override
  late final GeneratedColumn<String> clientEmail = GeneratedColumn<String>(
      'client_email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clientAddressMeta =
      const VerificationMeta('clientAddress');
  @override
  late final GeneratedColumn<String> clientAddress = GeneratedColumn<String>(
      'client_address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serviceNameMeta =
      const VerificationMeta('serviceName');
  @override
  late final GeneratedColumn<String> serviceName = GeneratedColumn<String>(
      'service_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _locationNameMeta =
      const VerificationMeta('locationName');
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
      'location_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serviceDurationMinutesMeta =
      const VerificationMeta('serviceDurationMinutes');
  @override
  late final GeneratedColumn<int> serviceDurationMinutes = GeneratedColumn<int>(
      'service_duration_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _staffNotesMeta =
      const VerificationMeta('staffNotes');
  @override
  late final GeneratedColumn<String> staffNotes = GeneratedColumn<String>(
      'staff_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _requiresPaymentMeta =
      const VerificationMeta('requiresPayment');
  @override
  late final GeneratedColumn<bool> requiresPayment = GeneratedColumn<bool>(
      'requires_payment', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("requires_payment" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _paymentStatusMeta =
      const VerificationMeta('paymentStatus');
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
      'payment_status', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _localUpdatedAtMeta =
      const VerificationMeta('localUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>('local_updated_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncActionMeta =
      const VerificationMeta('syncAction');
  @override
  late final GeneratedColumn<String> syncAction = GeneratedColumn<String>(
      'sync_action', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _checkedInAtMeta =
      const VerificationMeta('checkedInAt');
  @override
  late final GeneratedColumn<DateTime> checkedInAt = GeneratedColumn<DateTime>(
      'checked_in_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _checkedInByStaffIdMeta =
      const VerificationMeta('checkedInByStaffId');
  @override
  late final GeneratedColumn<String> checkedInByStaffId =
      GeneratedColumn<String>('checked_in_by_staff_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _completedByStaffIdMeta =
      const VerificationMeta('completedByStaffId');
  @override
  late final GeneratedColumn<String> completedByStaffId =
      GeneratedColumn<String>('completed_by_staff_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        businessId,
        staffId,
        clientId,
        serviceId,
        locationId,
        clientName,
        clientPhone,
        clientEmail,
        clientAddress,
        serviceName,
        locationName,
        serviceDurationMinutes,
        startTime,
        endTime,
        status,
        notes,
        staffNotes,
        requiresPayment,
        paymentStatus,
        localUpdatedAt,
        pendingSync,
        syncAction,
        checkedInAt,
        checkedInByStaffId,
        completedAt,
        completedByStaffId,
        lastSyncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'appointments_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<AppointmentsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
          _businessIdMeta,
          businessId.isAcceptableOrUnknown(
              data['business_id']!, _businessIdMeta));
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('staff_id')) {
      context.handle(_staffIdMeta,
          staffId.isAcceptableOrUnknown(data['staff_id']!, _staffIdMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(_clientIdMeta,
          clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta));
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('service_id')) {
      context.handle(_serviceIdMeta,
          serviceId.isAcceptableOrUnknown(data['service_id']!, _serviceIdMeta));
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    if (data.containsKey('location_id')) {
      context.handle(
          _locationIdMeta,
          locationId.isAcceptableOrUnknown(
              data['location_id']!, _locationIdMeta));
    } else if (isInserting) {
      context.missing(_locationIdMeta);
    }
    if (data.containsKey('client_name')) {
      context.handle(
          _clientNameMeta,
          clientName.isAcceptableOrUnknown(
              data['client_name']!, _clientNameMeta));
    }
    if (data.containsKey('client_phone')) {
      context.handle(
          _clientPhoneMeta,
          clientPhone.isAcceptableOrUnknown(
              data['client_phone']!, _clientPhoneMeta));
    }
    if (data.containsKey('client_email')) {
      context.handle(
          _clientEmailMeta,
          clientEmail.isAcceptableOrUnknown(
              data['client_email']!, _clientEmailMeta));
    }
    if (data.containsKey('client_address')) {
      context.handle(
          _clientAddressMeta,
          clientAddress.isAcceptableOrUnknown(
              data['client_address']!, _clientAddressMeta));
    }
    if (data.containsKey('service_name')) {
      context.handle(
          _serviceNameMeta,
          serviceName.isAcceptableOrUnknown(
              data['service_name']!, _serviceNameMeta));
    }
    if (data.containsKey('location_name')) {
      context.handle(
          _locationNameMeta,
          locationName.isAcceptableOrUnknown(
              data['location_name']!, _locationNameMeta));
    }
    if (data.containsKey('service_duration_minutes')) {
      context.handle(
          _serviceDurationMinutesMeta,
          serviceDurationMinutes.isAcceptableOrUnknown(
              data['service_duration_minutes']!, _serviceDurationMinutesMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('staff_notes')) {
      context.handle(
          _staffNotesMeta,
          staffNotes.isAcceptableOrUnknown(
              data['staff_notes']!, _staffNotesMeta));
    }
    if (data.containsKey('requires_payment')) {
      context.handle(
          _requiresPaymentMeta,
          requiresPayment.isAcceptableOrUnknown(
              data['requires_payment']!, _requiresPaymentMeta));
    }
    if (data.containsKey('payment_status')) {
      context.handle(
          _paymentStatusMeta,
          paymentStatus.isAcceptableOrUnknown(
              data['payment_status']!, _paymentStatusMeta));
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
          _localUpdatedAtMeta,
          localUpdatedAt.isAcceptableOrUnknown(
              data['local_updated_at']!, _localUpdatedAtMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    if (data.containsKey('sync_action')) {
      context.handle(
          _syncActionMeta,
          syncAction.isAcceptableOrUnknown(
              data['sync_action']!, _syncActionMeta));
    }
    if (data.containsKey('checked_in_at')) {
      context.handle(
          _checkedInAtMeta,
          checkedInAt.isAcceptableOrUnknown(
              data['checked_in_at']!, _checkedInAtMeta));
    }
    if (data.containsKey('checked_in_by_staff_id')) {
      context.handle(
          _checkedInByStaffIdMeta,
          checkedInByStaffId.isAcceptableOrUnknown(
              data['checked_in_by_staff_id']!, _checkedInByStaffIdMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('completed_by_staff_id')) {
      context.handle(
          _completedByStaffIdMeta,
          completedByStaffId.isAcceptableOrUnknown(
              data['completed_by_staff_id']!, _completedByStaffIdMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppointmentsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppointmentsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      businessId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}business_id'])!,
      staffId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}staff_id'])!,
      clientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_id'])!,
      serviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}service_id'])!,
      locationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location_id'])!,
      clientName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_name']),
      clientPhone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_phone']),
      clientEmail: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_email']),
      clientAddress: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_address']),
      serviceName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}service_name']),
      locationName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location_name']),
      serviceDurationMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}service_duration_minutes']),
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      staffNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}staff_notes']),
      requiresPayment: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}requires_payment'])!,
      paymentStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_status']),
      localUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}local_updated_at']),
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
      syncAction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_action']),
      checkedInAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}checked_in_at']),
      checkedInByStaffId: attachedDatabase.typeMapping.read(DriftSqlType.string,
          data['${effectivePrefix}checked_in_by_staff_id']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      completedByStaffId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}completed_by_staff_id']),
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
    );
  }

  @override
  $AppointmentsTableTable createAlias(String alias) {
    return $AppointmentsTableTable(attachedDatabase, alias);
  }
}

class AppointmentsTableData extends DataClass
    implements Insertable<AppointmentsTableData> {
  final String id;
  final String businessId;
  final String staffId;
  final String clientId;
  final String serviceId;
  final String locationId;
  final String? clientName;
  final String? clientPhone;
  final String? clientEmail;
  final String? clientAddress;
  final String? serviceName;
  final String? locationName;
  final int? serviceDurationMinutes;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? notes;
  final String? staffNotes;
  final bool requiresPayment;
  final String? paymentStatus;
  final DateTime? localUpdatedAt;
  final bool pendingSync;
  final String? syncAction;
  final DateTime? checkedInAt;
  final String? checkedInByStaffId;
  final DateTime? completedAt;
  final String? completedByStaffId;
  final DateTime? lastSyncedAt;
  const AppointmentsTableData(
      {required this.id,
      required this.businessId,
      required this.staffId,
      required this.clientId,
      required this.serviceId,
      required this.locationId,
      this.clientName,
      this.clientPhone,
      this.clientEmail,
      this.clientAddress,
      this.serviceName,
      this.locationName,
      this.serviceDurationMinutes,
      required this.startTime,
      required this.endTime,
      required this.status,
      this.notes,
      this.staffNotes,
      required this.requiresPayment,
      this.paymentStatus,
      this.localUpdatedAt,
      required this.pendingSync,
      this.syncAction,
      this.checkedInAt,
      this.checkedInByStaffId,
      this.completedAt,
      this.completedByStaffId,
      this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['staff_id'] = Variable<String>(staffId);
    map['client_id'] = Variable<String>(clientId);
    map['service_id'] = Variable<String>(serviceId);
    map['location_id'] = Variable<String>(locationId);
    if (!nullToAbsent || clientName != null) {
      map['client_name'] = Variable<String>(clientName);
    }
    if (!nullToAbsent || clientPhone != null) {
      map['client_phone'] = Variable<String>(clientPhone);
    }
    if (!nullToAbsent || clientEmail != null) {
      map['client_email'] = Variable<String>(clientEmail);
    }
    if (!nullToAbsent || clientAddress != null) {
      map['client_address'] = Variable<String>(clientAddress);
    }
    if (!nullToAbsent || serviceName != null) {
      map['service_name'] = Variable<String>(serviceName);
    }
    if (!nullToAbsent || locationName != null) {
      map['location_name'] = Variable<String>(locationName);
    }
    if (!nullToAbsent || serviceDurationMinutes != null) {
      map['service_duration_minutes'] = Variable<int>(serviceDurationMinutes);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    map['end_time'] = Variable<DateTime>(endTime);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || staffNotes != null) {
      map['staff_notes'] = Variable<String>(staffNotes);
    }
    map['requires_payment'] = Variable<bool>(requiresPayment);
    if (!nullToAbsent || paymentStatus != null) {
      map['payment_status'] = Variable<String>(paymentStatus);
    }
    if (!nullToAbsent || localUpdatedAt != null) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    }
    map['pending_sync'] = Variable<bool>(pendingSync);
    if (!nullToAbsent || syncAction != null) {
      map['sync_action'] = Variable<String>(syncAction);
    }
    if (!nullToAbsent || checkedInAt != null) {
      map['checked_in_at'] = Variable<DateTime>(checkedInAt);
    }
    if (!nullToAbsent || checkedInByStaffId != null) {
      map['checked_in_by_staff_id'] = Variable<String>(checkedInByStaffId);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || completedByStaffId != null) {
      map['completed_by_staff_id'] = Variable<String>(completedByStaffId);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  AppointmentsTableCompanion toCompanion(bool nullToAbsent) {
    return AppointmentsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      staffId: Value(staffId),
      clientId: Value(clientId),
      serviceId: Value(serviceId),
      locationId: Value(locationId),
      clientName: clientName == null && nullToAbsent
          ? const Value.absent()
          : Value(clientName),
      clientPhone: clientPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(clientPhone),
      clientEmail: clientEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(clientEmail),
      clientAddress: clientAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(clientAddress),
      serviceName: serviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceName),
      locationName: locationName == null && nullToAbsent
          ? const Value.absent()
          : Value(locationName),
      serviceDurationMinutes: serviceDurationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceDurationMinutes),
      startTime: Value(startTime),
      endTime: Value(endTime),
      status: Value(status),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      staffNotes: staffNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(staffNotes),
      requiresPayment: Value(requiresPayment),
      paymentStatus: paymentStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentStatus),
      localUpdatedAt: localUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(localUpdatedAt),
      pendingSync: Value(pendingSync),
      syncAction: syncAction == null && nullToAbsent
          ? const Value.absent()
          : Value(syncAction),
      checkedInAt: checkedInAt == null && nullToAbsent
          ? const Value.absent()
          : Value(checkedInAt),
      checkedInByStaffId: checkedInByStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(checkedInByStaffId),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      completedByStaffId: completedByStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(completedByStaffId),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory AppointmentsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppointmentsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      staffId: serializer.fromJson<String>(json['staffId']),
      clientId: serializer.fromJson<String>(json['clientId']),
      serviceId: serializer.fromJson<String>(json['serviceId']),
      locationId: serializer.fromJson<String>(json['locationId']),
      clientName: serializer.fromJson<String?>(json['clientName']),
      clientPhone: serializer.fromJson<String?>(json['clientPhone']),
      clientEmail: serializer.fromJson<String?>(json['clientEmail']),
      clientAddress: serializer.fromJson<String?>(json['clientAddress']),
      serviceName: serializer.fromJson<String?>(json['serviceName']),
      locationName: serializer.fromJson<String?>(json['locationName']),
      serviceDurationMinutes:
          serializer.fromJson<int?>(json['serviceDurationMinutes']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime>(json['endTime']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      staffNotes: serializer.fromJson<String?>(json['staffNotes']),
      requiresPayment: serializer.fromJson<bool>(json['requiresPayment']),
      paymentStatus: serializer.fromJson<String?>(json['paymentStatus']),
      localUpdatedAt: serializer.fromJson<DateTime?>(json['localUpdatedAt']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      syncAction: serializer.fromJson<String?>(json['syncAction']),
      checkedInAt: serializer.fromJson<DateTime?>(json['checkedInAt']),
      checkedInByStaffId:
          serializer.fromJson<String?>(json['checkedInByStaffId']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      completedByStaffId:
          serializer.fromJson<String?>(json['completedByStaffId']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'staffId': serializer.toJson<String>(staffId),
      'clientId': serializer.toJson<String>(clientId),
      'serviceId': serializer.toJson<String>(serviceId),
      'locationId': serializer.toJson<String>(locationId),
      'clientName': serializer.toJson<String?>(clientName),
      'clientPhone': serializer.toJson<String?>(clientPhone),
      'clientEmail': serializer.toJson<String?>(clientEmail),
      'clientAddress': serializer.toJson<String?>(clientAddress),
      'serviceName': serializer.toJson<String?>(serviceName),
      'locationName': serializer.toJson<String?>(locationName),
      'serviceDurationMinutes': serializer.toJson<int?>(serviceDurationMinutes),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime>(endTime),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'staffNotes': serializer.toJson<String?>(staffNotes),
      'requiresPayment': serializer.toJson<bool>(requiresPayment),
      'paymentStatus': serializer.toJson<String?>(paymentStatus),
      'localUpdatedAt': serializer.toJson<DateTime?>(localUpdatedAt),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'syncAction': serializer.toJson<String?>(syncAction),
      'checkedInAt': serializer.toJson<DateTime?>(checkedInAt),
      'checkedInByStaffId': serializer.toJson<String?>(checkedInByStaffId),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'completedByStaffId': serializer.toJson<String?>(completedByStaffId),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  AppointmentsTableData copyWith(
          {String? id,
          String? businessId,
          String? staffId,
          String? clientId,
          String? serviceId,
          String? locationId,
          Value<String?> clientName = const Value.absent(),
          Value<String?> clientPhone = const Value.absent(),
          Value<String?> clientEmail = const Value.absent(),
          Value<String?> clientAddress = const Value.absent(),
          Value<String?> serviceName = const Value.absent(),
          Value<String?> locationName = const Value.absent(),
          Value<int?> serviceDurationMinutes = const Value.absent(),
          DateTime? startTime,
          DateTime? endTime,
          String? status,
          Value<String?> notes = const Value.absent(),
          Value<String?> staffNotes = const Value.absent(),
          bool? requiresPayment,
          Value<String?> paymentStatus = const Value.absent(),
          Value<DateTime?> localUpdatedAt = const Value.absent(),
          bool? pendingSync,
          Value<String?> syncAction = const Value.absent(),
          Value<DateTime?> checkedInAt = const Value.absent(),
          Value<String?> checkedInByStaffId = const Value.absent(),
          Value<DateTime?> completedAt = const Value.absent(),
          Value<String?> completedByStaffId = const Value.absent(),
          Value<DateTime?> lastSyncedAt = const Value.absent()}) =>
      AppointmentsTableData(
        id: id ?? this.id,
        businessId: businessId ?? this.businessId,
        staffId: staffId ?? this.staffId,
        clientId: clientId ?? this.clientId,
        serviceId: serviceId ?? this.serviceId,
        locationId: locationId ?? this.locationId,
        clientName: clientName.present ? clientName.value : this.clientName,
        clientPhone: clientPhone.present ? clientPhone.value : this.clientPhone,
        clientEmail: clientEmail.present ? clientEmail.value : this.clientEmail,
        clientAddress:
            clientAddress.present ? clientAddress.value : this.clientAddress,
        serviceName: serviceName.present ? serviceName.value : this.serviceName,
        locationName:
            locationName.present ? locationName.value : this.locationName,
        serviceDurationMinutes: serviceDurationMinutes.present
            ? serviceDurationMinutes.value
            : this.serviceDurationMinutes,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        status: status ?? this.status,
        notes: notes.present ? notes.value : this.notes,
        staffNotes: staffNotes.present ? staffNotes.value : this.staffNotes,
        requiresPayment: requiresPayment ?? this.requiresPayment,
        paymentStatus:
            paymentStatus.present ? paymentStatus.value : this.paymentStatus,
        localUpdatedAt:
            localUpdatedAt.present ? localUpdatedAt.value : this.localUpdatedAt,
        pendingSync: pendingSync ?? this.pendingSync,
        syncAction: syncAction.present ? syncAction.value : this.syncAction,
        checkedInAt: checkedInAt.present ? checkedInAt.value : this.checkedInAt,
        checkedInByStaffId: checkedInByStaffId.present
            ? checkedInByStaffId.value
            : this.checkedInByStaffId,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        completedByStaffId: completedByStaffId.present
            ? completedByStaffId.value
            : this.completedByStaffId,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
      );
  AppointmentsTableData copyWithCompanion(AppointmentsTableCompanion data) {
    return AppointmentsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId:
          data.businessId.present ? data.businessId.value : this.businessId,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      locationId:
          data.locationId.present ? data.locationId.value : this.locationId,
      clientName:
          data.clientName.present ? data.clientName.value : this.clientName,
      clientPhone:
          data.clientPhone.present ? data.clientPhone.value : this.clientPhone,
      clientEmail:
          data.clientEmail.present ? data.clientEmail.value : this.clientEmail,
      clientAddress: data.clientAddress.present
          ? data.clientAddress.value
          : this.clientAddress,
      serviceName:
          data.serviceName.present ? data.serviceName.value : this.serviceName,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      serviceDurationMinutes: data.serviceDurationMinutes.present
          ? data.serviceDurationMinutes.value
          : this.serviceDurationMinutes,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      staffNotes:
          data.staffNotes.present ? data.staffNotes.value : this.staffNotes,
      requiresPayment: data.requiresPayment.present
          ? data.requiresPayment.value
          : this.requiresPayment,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
      syncAction:
          data.syncAction.present ? data.syncAction.value : this.syncAction,
      checkedInAt:
          data.checkedInAt.present ? data.checkedInAt.value : this.checkedInAt,
      checkedInByStaffId: data.checkedInByStaffId.present
          ? data.checkedInByStaffId.value
          : this.checkedInByStaffId,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      completedByStaffId: data.completedByStaffId.present
          ? data.completedByStaffId.value
          : this.completedByStaffId,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppointmentsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('staffId: $staffId, ')
          ..write('clientId: $clientId, ')
          ..write('serviceId: $serviceId, ')
          ..write('locationId: $locationId, ')
          ..write('clientName: $clientName, ')
          ..write('clientPhone: $clientPhone, ')
          ..write('clientEmail: $clientEmail, ')
          ..write('clientAddress: $clientAddress, ')
          ..write('serviceName: $serviceName, ')
          ..write('locationName: $locationName, ')
          ..write('serviceDurationMinutes: $serviceDurationMinutes, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('staffNotes: $staffNotes, ')
          ..write('requiresPayment: $requiresPayment, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('syncAction: $syncAction, ')
          ..write('checkedInAt: $checkedInAt, ')
          ..write('checkedInByStaffId: $checkedInByStaffId, ')
          ..write('completedAt: $completedAt, ')
          ..write('completedByStaffId: $completedByStaffId, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        businessId,
        staffId,
        clientId,
        serviceId,
        locationId,
        clientName,
        clientPhone,
        clientEmail,
        clientAddress,
        serviceName,
        locationName,
        serviceDurationMinutes,
        startTime,
        endTime,
        status,
        notes,
        staffNotes,
        requiresPayment,
        paymentStatus,
        localUpdatedAt,
        pendingSync,
        syncAction,
        checkedInAt,
        checkedInByStaffId,
        completedAt,
        completedByStaffId,
        lastSyncedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppointmentsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.staffId == this.staffId &&
          other.clientId == this.clientId &&
          other.serviceId == this.serviceId &&
          other.locationId == this.locationId &&
          other.clientName == this.clientName &&
          other.clientPhone == this.clientPhone &&
          other.clientEmail == this.clientEmail &&
          other.clientAddress == this.clientAddress &&
          other.serviceName == this.serviceName &&
          other.locationName == this.locationName &&
          other.serviceDurationMinutes == this.serviceDurationMinutes &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.staffNotes == this.staffNotes &&
          other.requiresPayment == this.requiresPayment &&
          other.paymentStatus == this.paymentStatus &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.pendingSync == this.pendingSync &&
          other.syncAction == this.syncAction &&
          other.checkedInAt == this.checkedInAt &&
          other.checkedInByStaffId == this.checkedInByStaffId &&
          other.completedAt == this.completedAt &&
          other.completedByStaffId == this.completedByStaffId &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class AppointmentsTableCompanion
    extends UpdateCompanion<AppointmentsTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> staffId;
  final Value<String> clientId;
  final Value<String> serviceId;
  final Value<String> locationId;
  final Value<String?> clientName;
  final Value<String?> clientPhone;
  final Value<String?> clientEmail;
  final Value<String?> clientAddress;
  final Value<String?> serviceName;
  final Value<String?> locationName;
  final Value<int?> serviceDurationMinutes;
  final Value<DateTime> startTime;
  final Value<DateTime> endTime;
  final Value<String> status;
  final Value<String?> notes;
  final Value<String?> staffNotes;
  final Value<bool> requiresPayment;
  final Value<String?> paymentStatus;
  final Value<DateTime?> localUpdatedAt;
  final Value<bool> pendingSync;
  final Value<String?> syncAction;
  final Value<DateTime?> checkedInAt;
  final Value<String?> checkedInByStaffId;
  final Value<DateTime?> completedAt;
  final Value<String?> completedByStaffId;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const AppointmentsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.staffId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.locationId = const Value.absent(),
    this.clientName = const Value.absent(),
    this.clientPhone = const Value.absent(),
    this.clientEmail = const Value.absent(),
    this.clientAddress = const Value.absent(),
    this.serviceName = const Value.absent(),
    this.locationName = const Value.absent(),
    this.serviceDurationMinutes = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.staffNotes = const Value.absent(),
    this.requiresPayment = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.syncAction = const Value.absent(),
    this.checkedInAt = const Value.absent(),
    this.checkedInByStaffId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completedByStaffId = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppointmentsTableCompanion.insert({
    required String id,
    required String businessId,
    this.staffId = const Value.absent(),
    required String clientId,
    required String serviceId,
    required String locationId,
    this.clientName = const Value.absent(),
    this.clientPhone = const Value.absent(),
    this.clientEmail = const Value.absent(),
    this.clientAddress = const Value.absent(),
    this.serviceName = const Value.absent(),
    this.locationName = const Value.absent(),
    this.serviceDurationMinutes = const Value.absent(),
    required DateTime startTime,
    required DateTime endTime,
    required String status,
    this.notes = const Value.absent(),
    this.staffNotes = const Value.absent(),
    this.requiresPayment = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.syncAction = const Value.absent(),
    this.checkedInAt = const Value.absent(),
    this.checkedInByStaffId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completedByStaffId = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        businessId = Value(businessId),
        clientId = Value(clientId),
        serviceId = Value(serviceId),
        locationId = Value(locationId),
        startTime = Value(startTime),
        endTime = Value(endTime),
        status = Value(status);
  static Insertable<AppointmentsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? staffId,
    Expression<String>? clientId,
    Expression<String>? serviceId,
    Expression<String>? locationId,
    Expression<String>? clientName,
    Expression<String>? clientPhone,
    Expression<String>? clientEmail,
    Expression<String>? clientAddress,
    Expression<String>? serviceName,
    Expression<String>? locationName,
    Expression<int>? serviceDurationMinutes,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<String>? staffNotes,
    Expression<bool>? requiresPayment,
    Expression<String>? paymentStatus,
    Expression<DateTime>? localUpdatedAt,
    Expression<bool>? pendingSync,
    Expression<String>? syncAction,
    Expression<DateTime>? checkedInAt,
    Expression<String>? checkedInByStaffId,
    Expression<DateTime>? completedAt,
    Expression<String>? completedByStaffId,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (staffId != null) 'staff_id': staffId,
      if (clientId != null) 'client_id': clientId,
      if (serviceId != null) 'service_id': serviceId,
      if (locationId != null) 'location_id': locationId,
      if (clientName != null) 'client_name': clientName,
      if (clientPhone != null) 'client_phone': clientPhone,
      if (clientEmail != null) 'client_email': clientEmail,
      if (clientAddress != null) 'client_address': clientAddress,
      if (serviceName != null) 'service_name': serviceName,
      if (locationName != null) 'location_name': locationName,
      if (serviceDurationMinutes != null)
        'service_duration_minutes': serviceDurationMinutes,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (staffNotes != null) 'staff_notes': staffNotes,
      if (requiresPayment != null) 'requires_payment': requiresPayment,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (syncAction != null) 'sync_action': syncAction,
      if (checkedInAt != null) 'checked_in_at': checkedInAt,
      if (checkedInByStaffId != null)
        'checked_in_by_staff_id': checkedInByStaffId,
      if (completedAt != null) 'completed_at': completedAt,
      if (completedByStaffId != null)
        'completed_by_staff_id': completedByStaffId,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppointmentsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? businessId,
      Value<String>? staffId,
      Value<String>? clientId,
      Value<String>? serviceId,
      Value<String>? locationId,
      Value<String?>? clientName,
      Value<String?>? clientPhone,
      Value<String?>? clientEmail,
      Value<String?>? clientAddress,
      Value<String?>? serviceName,
      Value<String?>? locationName,
      Value<int?>? serviceDurationMinutes,
      Value<DateTime>? startTime,
      Value<DateTime>? endTime,
      Value<String>? status,
      Value<String?>? notes,
      Value<String?>? staffNotes,
      Value<bool>? requiresPayment,
      Value<String?>? paymentStatus,
      Value<DateTime?>? localUpdatedAt,
      Value<bool>? pendingSync,
      Value<String?>? syncAction,
      Value<DateTime?>? checkedInAt,
      Value<String?>? checkedInByStaffId,
      Value<DateTime?>? completedAt,
      Value<String?>? completedByStaffId,
      Value<DateTime?>? lastSyncedAt,
      Value<int>? rowid}) {
    return AppointmentsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      staffId: staffId ?? this.staffId,
      clientId: clientId ?? this.clientId,
      serviceId: serviceId ?? this.serviceId,
      locationId: locationId ?? this.locationId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      clientAddress: clientAddress ?? this.clientAddress,
      serviceName: serviceName ?? this.serviceName,
      locationName: locationName ?? this.locationName,
      serviceDurationMinutes:
          serviceDurationMinutes ?? this.serviceDurationMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      staffNotes: staffNotes ?? this.staffNotes,
      requiresPayment: requiresPayment ?? this.requiresPayment,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      syncAction: syncAction ?? this.syncAction,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedInByStaffId: checkedInByStaffId ?? this.checkedInByStaffId,
      completedAt: completedAt ?? this.completedAt,
      completedByStaffId: completedByStaffId ?? this.completedByStaffId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (staffId.present) {
      map['staff_id'] = Variable<String>(staffId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (serviceId.present) {
      map['service_id'] = Variable<String>(serviceId.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (clientName.present) {
      map['client_name'] = Variable<String>(clientName.value);
    }
    if (clientPhone.present) {
      map['client_phone'] = Variable<String>(clientPhone.value);
    }
    if (clientEmail.present) {
      map['client_email'] = Variable<String>(clientEmail.value);
    }
    if (clientAddress.present) {
      map['client_address'] = Variable<String>(clientAddress.value);
    }
    if (serviceName.present) {
      map['service_name'] = Variable<String>(serviceName.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (serviceDurationMinutes.present) {
      map['service_duration_minutes'] =
          Variable<int>(serviceDurationMinutes.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (staffNotes.present) {
      map['staff_notes'] = Variable<String>(staffNotes.value);
    }
    if (requiresPayment.present) {
      map['requires_payment'] = Variable<bool>(requiresPayment.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (syncAction.present) {
      map['sync_action'] = Variable<String>(syncAction.value);
    }
    if (checkedInAt.present) {
      map['checked_in_at'] = Variable<DateTime>(checkedInAt.value);
    }
    if (checkedInByStaffId.present) {
      map['checked_in_by_staff_id'] =
          Variable<String>(checkedInByStaffId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (completedByStaffId.present) {
      map['completed_by_staff_id'] = Variable<String>(completedByStaffId.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppointmentsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('staffId: $staffId, ')
          ..write('clientId: $clientId, ')
          ..write('serviceId: $serviceId, ')
          ..write('locationId: $locationId, ')
          ..write('clientName: $clientName, ')
          ..write('clientPhone: $clientPhone, ')
          ..write('clientEmail: $clientEmail, ')
          ..write('clientAddress: $clientAddress, ')
          ..write('serviceName: $serviceName, ')
          ..write('locationName: $locationName, ')
          ..write('serviceDurationMinutes: $serviceDurationMinutes, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('staffNotes: $staffNotes, ')
          ..write('requiresPayment: $requiresPayment, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('syncAction: $syncAction, ')
          ..write('checkedInAt: $checkedInAt, ')
          ..write('checkedInByStaffId: $checkedInByStaffId, ')
          ..write('completedAt: $completedAt, ')
          ..write('completedByStaffId: $completedByStaffId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClientsTableTable extends ClientsTable
    with TableInfo<$ClientsTableTable, ClientsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _businessIdMeta =
      const VerificationMeta('businessId');
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
      'business_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, businessId, name, email, phone, address, notes, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clients_table';
  @override
  VerificationContext validateIntegrity(Insertable<ClientsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
          _businessIdMeta,
          businessId.isAcceptableOrUnknown(
              data['business_id']!, _businessIdMeta));
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClientsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClientsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      businessId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}business_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at'])!,
    );
  }

  @override
  $ClientsTableTable createAlias(String alias) {
    return $ClientsTableTable(attachedDatabase, alias);
  }
}

class ClientsTableData extends DataClass
    implements Insertable<ClientsTableData> {
  final String id;
  final String businessId;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? notes;
  final DateTime lastSyncedAt;
  const ClientsTableData(
      {required this.id,
      required this.businessId,
      required this.name,
      this.email,
      this.phone,
      this.address,
      this.notes,
      required this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    return map;
  }

  ClientsTableCompanion toCompanion(bool nullToAbsent) {
    return ClientsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      lastSyncedAt: Value(lastSyncedAt),
    );
  }

  factory ClientsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClientsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
      phone: serializer.fromJson<String?>(json['phone']),
      address: serializer.fromJson<String?>(json['address']),
      notes: serializer.fromJson<String?>(json['notes']),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String?>(email),
      'phone': serializer.toJson<String?>(phone),
      'address': serializer.toJson<String?>(address),
      'notes': serializer.toJson<String?>(notes),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
    };
  }

  ClientsTableData copyWith(
          {String? id,
          String? businessId,
          String? name,
          Value<String?> email = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? lastSyncedAt}) =>
      ClientsTableData(
        id: id ?? this.id,
        businessId: businessId ?? this.businessId,
        name: name ?? this.name,
        email: email.present ? email.value : this.email,
        phone: phone.present ? phone.value : this.phone,
        address: address.present ? address.value : this.address,
        notes: notes.present ? notes.value : this.notes,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );
  ClientsTableData copyWithCompanion(ClientsTableCompanion data) {
    return ClientsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId:
          data.businessId.present ? data.businessId.value : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      notes: data.notes.present ? data.notes.value : this.notes,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClientsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('notes: $notes, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, businessId, name, email, phone, address, notes, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.notes == this.notes &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class ClientsTableCompanion extends UpdateCompanion<ClientsTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String?> email;
  final Value<String?> phone;
  final Value<String?> address;
  final Value<String?> notes;
  final Value<DateTime> lastSyncedAt;
  final Value<int> rowid;
  const ClientsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.notes = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientsTableCompanion.insert({
    required String id,
    required String businessId,
    required String name,
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime lastSyncedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        businessId = Value(businessId),
        name = Value(name),
        lastSyncedAt = Value(lastSyncedAt);
  static Insertable<ClientsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<String>? notes,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? businessId,
      Value<String>? name,
      Value<String?>? email,
      Value<String?>? phone,
      Value<String?>? address,
      Value<String?>? notes,
      Value<DateTime>? lastSyncedAt,
      Value<int>? rowid}) {
    return ClientsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('notes: $notes, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimeEntriesTableTable extends TimeEntriesTable
    with TableInfo<$TimeEntriesTableTable, TimeEntriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimeEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _businessIdMeta =
      const VerificationMeta('businessId');
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
      'business_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _staffIdMeta =
      const VerificationMeta('staffId');
  @override
  late final GeneratedColumn<String> staffId = GeneratedColumn<String>(
      'staff_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clockInTimeMeta =
      const VerificationMeta('clockInTime');
  @override
  late final GeneratedColumn<DateTime> clockInTime = GeneratedColumn<DateTime>(
      'clock_in_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _clockOutTimeMeta =
      const VerificationMeta('clockOutTime');
  @override
  late final GeneratedColumn<DateTime> clockOutTime = GeneratedColumn<DateTime>(
      'clock_out_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _clockInLatitudeMeta =
      const VerificationMeta('clockInLatitude');
  @override
  late final GeneratedColumn<double> clockInLatitude = GeneratedColumn<double>(
      'clock_in_latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _clockInLongitudeMeta =
      const VerificationMeta('clockInLongitude');
  @override
  late final GeneratedColumn<double> clockInLongitude = GeneratedColumn<double>(
      'clock_in_longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _clockInAddressMeta =
      const VerificationMeta('clockInAddress');
  @override
  late final GeneratedColumn<String> clockInAddress = GeneratedColumn<String>(
      'clock_in_address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clockOutLatitudeMeta =
      const VerificationMeta('clockOutLatitude');
  @override
  late final GeneratedColumn<double> clockOutLatitude = GeneratedColumn<double>(
      'clock_out_latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _clockOutLongitudeMeta =
      const VerificationMeta('clockOutLongitude');
  @override
  late final GeneratedColumn<double> clockOutLongitude =
      GeneratedColumn<double>('clock_out_longitude', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _clockOutAddressMeta =
      const VerificationMeta('clockOutAddress');
  @override
  late final GeneratedColumn<String> clockOutAddress = GeneratedColumn<String>(
      'clock_out_address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clockInLocationIdMeta =
      const VerificationMeta('clockInLocationId');
  @override
  late final GeneratedColumn<String> clockInLocationId =
      GeneratedColumn<String>('clock_in_location_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clockOutLocationIdMeta =
      const VerificationMeta('clockOutLocationId');
  @override
  late final GeneratedColumn<String> clockOutLocationId =
      GeneratedColumn<String>('clock_out_location_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clockInOutsideGeofenceMeta =
      const VerificationMeta('clockInOutsideGeofence');
  @override
  late final GeneratedColumn<bool> clockInOutsideGeofence =
      GeneratedColumn<bool>('clock_in_outside_geofence', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("clock_in_outside_geofence" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _clockOutOutsideGeofenceMeta =
      const VerificationMeta('clockOutOutsideGeofence');
  @override
  late final GeneratedColumn<bool> clockOutOutsideGeofence =
      GeneratedColumn<bool>('clock_out_outside_geofence', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("clock_out_outside_geofence" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _breaksJsonMeta =
      const VerificationMeta('breaksJson');
  @override
  late final GeneratedColumn<String> breaksJson = GeneratedColumn<String>(
      'breaks_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _totalMinutesMeta =
      const VerificationMeta('totalMinutes');
  @override
  late final GeneratedColumn<int> totalMinutes = GeneratedColumn<int>(
      'total_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _breakMinutesMeta =
      const VerificationMeta('breakMinutes');
  @override
  late final GeneratedColumn<int> breakMinutes = GeneratedColumn<int>(
      'break_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _workedMinutesMeta =
      const VerificationMeta('workedMinutes');
  @override
  late final GeneratedColumn<int> workedMinutes = GeneratedColumn<int>(
      'worked_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _approvedByUserIdMeta =
      const VerificationMeta('approvedByUserId');
  @override
  late final GeneratedColumn<String> approvedByUserId = GeneratedColumn<String>(
      'approved_by_user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _approvedAtMeta =
      const VerificationMeta('approvedAt');
  @override
  late final GeneratedColumn<DateTime> approvedAt = GeneratedColumn<DateTime>(
      'approved_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _rejectionReasonMeta =
      const VerificationMeta('rejectionReason');
  @override
  late final GeneratedColumn<String> rejectionReason = GeneratedColumn<String>(
      'rejection_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _staffNotesMeta =
      const VerificationMeta('staffNotes');
  @override
  late final GeneratedColumn<String> staffNotes = GeneratedColumn<String>(
      'staff_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _managerNotesMeta =
      const VerificationMeta('managerNotes');
  @override
  late final GeneratedColumn<String> managerNotes = GeneratedColumn<String>(
      'manager_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncActionMeta =
      const VerificationMeta('syncAction');
  @override
  late final GeneratedColumn<String> syncAction = GeneratedColumn<String>(
      'sync_action', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        businessId,
        staffId,
        clockInTime,
        clockOutTime,
        clockInLatitude,
        clockInLongitude,
        clockInAddress,
        clockOutLatitude,
        clockOutLongitude,
        clockOutAddress,
        clockInLocationId,
        clockOutLocationId,
        clockInOutsideGeofence,
        clockOutOutsideGeofence,
        breaksJson,
        totalMinutes,
        breakMinutes,
        workedMinutes,
        status,
        approvedByUserId,
        approvedAt,
        rejectionReason,
        staffNotes,
        managerNotes,
        createdAt,
        updatedAt,
        pendingSync,
        syncAction,
        lastSyncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'time_entries_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<TimeEntriesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
          _businessIdMeta,
          businessId.isAcceptableOrUnknown(
              data['business_id']!, _businessIdMeta));
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('staff_id')) {
      context.handle(_staffIdMeta,
          staffId.isAcceptableOrUnknown(data['staff_id']!, _staffIdMeta));
    } else if (isInserting) {
      context.missing(_staffIdMeta);
    }
    if (data.containsKey('clock_in_time')) {
      context.handle(
          _clockInTimeMeta,
          clockInTime.isAcceptableOrUnknown(
              data['clock_in_time']!, _clockInTimeMeta));
    } else if (isInserting) {
      context.missing(_clockInTimeMeta);
    }
    if (data.containsKey('clock_out_time')) {
      context.handle(
          _clockOutTimeMeta,
          clockOutTime.isAcceptableOrUnknown(
              data['clock_out_time']!, _clockOutTimeMeta));
    }
    if (data.containsKey('clock_in_latitude')) {
      context.handle(
          _clockInLatitudeMeta,
          clockInLatitude.isAcceptableOrUnknown(
              data['clock_in_latitude']!, _clockInLatitudeMeta));
    }
    if (data.containsKey('clock_in_longitude')) {
      context.handle(
          _clockInLongitudeMeta,
          clockInLongitude.isAcceptableOrUnknown(
              data['clock_in_longitude']!, _clockInLongitudeMeta));
    }
    if (data.containsKey('clock_in_address')) {
      context.handle(
          _clockInAddressMeta,
          clockInAddress.isAcceptableOrUnknown(
              data['clock_in_address']!, _clockInAddressMeta));
    }
    if (data.containsKey('clock_out_latitude')) {
      context.handle(
          _clockOutLatitudeMeta,
          clockOutLatitude.isAcceptableOrUnknown(
              data['clock_out_latitude']!, _clockOutLatitudeMeta));
    }
    if (data.containsKey('clock_out_longitude')) {
      context.handle(
          _clockOutLongitudeMeta,
          clockOutLongitude.isAcceptableOrUnknown(
              data['clock_out_longitude']!, _clockOutLongitudeMeta));
    }
    if (data.containsKey('clock_out_address')) {
      context.handle(
          _clockOutAddressMeta,
          clockOutAddress.isAcceptableOrUnknown(
              data['clock_out_address']!, _clockOutAddressMeta));
    }
    if (data.containsKey('clock_in_location_id')) {
      context.handle(
          _clockInLocationIdMeta,
          clockInLocationId.isAcceptableOrUnknown(
              data['clock_in_location_id']!, _clockInLocationIdMeta));
    }
    if (data.containsKey('clock_out_location_id')) {
      context.handle(
          _clockOutLocationIdMeta,
          clockOutLocationId.isAcceptableOrUnknown(
              data['clock_out_location_id']!, _clockOutLocationIdMeta));
    }
    if (data.containsKey('clock_in_outside_geofence')) {
      context.handle(
          _clockInOutsideGeofenceMeta,
          clockInOutsideGeofence.isAcceptableOrUnknown(
              data['clock_in_outside_geofence']!, _clockInOutsideGeofenceMeta));
    }
    if (data.containsKey('clock_out_outside_geofence')) {
      context.handle(
          _clockOutOutsideGeofenceMeta,
          clockOutOutsideGeofence.isAcceptableOrUnknown(
              data['clock_out_outside_geofence']!,
              _clockOutOutsideGeofenceMeta));
    }
    if (data.containsKey('breaks_json')) {
      context.handle(
          _breaksJsonMeta,
          breaksJson.isAcceptableOrUnknown(
              data['breaks_json']!, _breaksJsonMeta));
    }
    if (data.containsKey('total_minutes')) {
      context.handle(
          _totalMinutesMeta,
          totalMinutes.isAcceptableOrUnknown(
              data['total_minutes']!, _totalMinutesMeta));
    }
    if (data.containsKey('break_minutes')) {
      context.handle(
          _breakMinutesMeta,
          breakMinutes.isAcceptableOrUnknown(
              data['break_minutes']!, _breakMinutesMeta));
    }
    if (data.containsKey('worked_minutes')) {
      context.handle(
          _workedMinutesMeta,
          workedMinutes.isAcceptableOrUnknown(
              data['worked_minutes']!, _workedMinutesMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('approved_by_user_id')) {
      context.handle(
          _approvedByUserIdMeta,
          approvedByUserId.isAcceptableOrUnknown(
              data['approved_by_user_id']!, _approvedByUserIdMeta));
    }
    if (data.containsKey('approved_at')) {
      context.handle(
          _approvedAtMeta,
          approvedAt.isAcceptableOrUnknown(
              data['approved_at']!, _approvedAtMeta));
    }
    if (data.containsKey('rejection_reason')) {
      context.handle(
          _rejectionReasonMeta,
          rejectionReason.isAcceptableOrUnknown(
              data['rejection_reason']!, _rejectionReasonMeta));
    }
    if (data.containsKey('staff_notes')) {
      context.handle(
          _staffNotesMeta,
          staffNotes.isAcceptableOrUnknown(
              data['staff_notes']!, _staffNotesMeta));
    }
    if (data.containsKey('manager_notes')) {
      context.handle(
          _managerNotesMeta,
          managerNotes.isAcceptableOrUnknown(
              data['manager_notes']!, _managerNotesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    if (data.containsKey('sync_action')) {
      context.handle(
          _syncActionMeta,
          syncAction.isAcceptableOrUnknown(
              data['sync_action']!, _syncActionMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimeEntriesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimeEntriesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      businessId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}business_id'])!,
      staffId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}staff_id'])!,
      clockInTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}clock_in_time'])!,
      clockOutTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}clock_out_time']),
      clockInLatitude: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}clock_in_latitude']),
      clockInLongitude: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}clock_in_longitude']),
      clockInAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}clock_in_address']),
      clockOutLatitude: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}clock_out_latitude']),
      clockOutLongitude: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}clock_out_longitude']),
      clockOutAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}clock_out_address']),
      clockInLocationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}clock_in_location_id']),
      clockOutLocationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}clock_out_location_id']),
      clockInOutsideGeofence: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}clock_in_outside_geofence'])!,
      clockOutOutsideGeofence: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}clock_out_outside_geofence'])!,
      breaksJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}breaks_json'])!,
      totalMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_minutes']),
      breakMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}break_minutes']),
      workedMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}worked_minutes']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      approvedByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}approved_by_user_id']),
      approvedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}approved_at']),
      rejectionReason: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}rejection_reason']),
      staffNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}staff_notes']),
      managerNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}manager_notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
      syncAction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_action']),
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
    );
  }

  @override
  $TimeEntriesTableTable createAlias(String alias) {
    return $TimeEntriesTableTable(attachedDatabase, alias);
  }
}

class TimeEntriesTableData extends DataClass
    implements Insertable<TimeEntriesTableData> {
  final String id;
  final String businessId;
  final String staffId;
  final DateTime clockInTime;
  final DateTime? clockOutTime;
  final double? clockInLatitude;
  final double? clockInLongitude;
  final String? clockInAddress;
  final double? clockOutLatitude;
  final double? clockOutLongitude;
  final String? clockOutAddress;
  final String? clockInLocationId;
  final String? clockOutLocationId;
  final bool clockInOutsideGeofence;
  final bool clockOutOutsideGeofence;
  final String breaksJson;
  final int? totalMinutes;
  final int? breakMinutes;
  final int? workedMinutes;
  final String status;
  final String? approvedByUserId;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? staffNotes;
  final String? managerNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool pendingSync;
  final String? syncAction;
  final DateTime? lastSyncedAt;
  const TimeEntriesTableData(
      {required this.id,
      required this.businessId,
      required this.staffId,
      required this.clockInTime,
      this.clockOutTime,
      this.clockInLatitude,
      this.clockInLongitude,
      this.clockInAddress,
      this.clockOutLatitude,
      this.clockOutLongitude,
      this.clockOutAddress,
      this.clockInLocationId,
      this.clockOutLocationId,
      required this.clockInOutsideGeofence,
      required this.clockOutOutsideGeofence,
      required this.breaksJson,
      this.totalMinutes,
      this.breakMinutes,
      this.workedMinutes,
      required this.status,
      this.approvedByUserId,
      this.approvedAt,
      this.rejectionReason,
      this.staffNotes,
      this.managerNotes,
      required this.createdAt,
      this.updatedAt,
      required this.pendingSync,
      this.syncAction,
      this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['staff_id'] = Variable<String>(staffId);
    map['clock_in_time'] = Variable<DateTime>(clockInTime);
    if (!nullToAbsent || clockOutTime != null) {
      map['clock_out_time'] = Variable<DateTime>(clockOutTime);
    }
    if (!nullToAbsent || clockInLatitude != null) {
      map['clock_in_latitude'] = Variable<double>(clockInLatitude);
    }
    if (!nullToAbsent || clockInLongitude != null) {
      map['clock_in_longitude'] = Variable<double>(clockInLongitude);
    }
    if (!nullToAbsent || clockInAddress != null) {
      map['clock_in_address'] = Variable<String>(clockInAddress);
    }
    if (!nullToAbsent || clockOutLatitude != null) {
      map['clock_out_latitude'] = Variable<double>(clockOutLatitude);
    }
    if (!nullToAbsent || clockOutLongitude != null) {
      map['clock_out_longitude'] = Variable<double>(clockOutLongitude);
    }
    if (!nullToAbsent || clockOutAddress != null) {
      map['clock_out_address'] = Variable<String>(clockOutAddress);
    }
    if (!nullToAbsent || clockInLocationId != null) {
      map['clock_in_location_id'] = Variable<String>(clockInLocationId);
    }
    if (!nullToAbsent || clockOutLocationId != null) {
      map['clock_out_location_id'] = Variable<String>(clockOutLocationId);
    }
    map['clock_in_outside_geofence'] = Variable<bool>(clockInOutsideGeofence);
    map['clock_out_outside_geofence'] = Variable<bool>(clockOutOutsideGeofence);
    map['breaks_json'] = Variable<String>(breaksJson);
    if (!nullToAbsent || totalMinutes != null) {
      map['total_minutes'] = Variable<int>(totalMinutes);
    }
    if (!nullToAbsent || breakMinutes != null) {
      map['break_minutes'] = Variable<int>(breakMinutes);
    }
    if (!nullToAbsent || workedMinutes != null) {
      map['worked_minutes'] = Variable<int>(workedMinutes);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || approvedByUserId != null) {
      map['approved_by_user_id'] = Variable<String>(approvedByUserId);
    }
    if (!nullToAbsent || approvedAt != null) {
      map['approved_at'] = Variable<DateTime>(approvedAt);
    }
    if (!nullToAbsent || rejectionReason != null) {
      map['rejection_reason'] = Variable<String>(rejectionReason);
    }
    if (!nullToAbsent || staffNotes != null) {
      map['staff_notes'] = Variable<String>(staffNotes);
    }
    if (!nullToAbsent || managerNotes != null) {
      map['manager_notes'] = Variable<String>(managerNotes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['pending_sync'] = Variable<bool>(pendingSync);
    if (!nullToAbsent || syncAction != null) {
      map['sync_action'] = Variable<String>(syncAction);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  TimeEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return TimeEntriesTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      staffId: Value(staffId),
      clockInTime: Value(clockInTime),
      clockOutTime: clockOutTime == null && nullToAbsent
          ? const Value.absent()
          : Value(clockOutTime),
      clockInLatitude: clockInLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(clockInLatitude),
      clockInLongitude: clockInLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(clockInLongitude),
      clockInAddress: clockInAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(clockInAddress),
      clockOutLatitude: clockOutLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(clockOutLatitude),
      clockOutLongitude: clockOutLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(clockOutLongitude),
      clockOutAddress: clockOutAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(clockOutAddress),
      clockInLocationId: clockInLocationId == null && nullToAbsent
          ? const Value.absent()
          : Value(clockInLocationId),
      clockOutLocationId: clockOutLocationId == null && nullToAbsent
          ? const Value.absent()
          : Value(clockOutLocationId),
      clockInOutsideGeofence: Value(clockInOutsideGeofence),
      clockOutOutsideGeofence: Value(clockOutOutsideGeofence),
      breaksJson: Value(breaksJson),
      totalMinutes: totalMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalMinutes),
      breakMinutes: breakMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(breakMinutes),
      workedMinutes: workedMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(workedMinutes),
      status: Value(status),
      approvedByUserId: approvedByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedByUserId),
      approvedAt: approvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedAt),
      rejectionReason: rejectionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectionReason),
      staffNotes: staffNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(staffNotes),
      managerNotes: managerNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(managerNotes),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      pendingSync: Value(pendingSync),
      syncAction: syncAction == null && nullToAbsent
          ? const Value.absent()
          : Value(syncAction),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory TimeEntriesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimeEntriesTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      staffId: serializer.fromJson<String>(json['staffId']),
      clockInTime: serializer.fromJson<DateTime>(json['clockInTime']),
      clockOutTime: serializer.fromJson<DateTime?>(json['clockOutTime']),
      clockInLatitude: serializer.fromJson<double?>(json['clockInLatitude']),
      clockInLongitude: serializer.fromJson<double?>(json['clockInLongitude']),
      clockInAddress: serializer.fromJson<String?>(json['clockInAddress']),
      clockOutLatitude: serializer.fromJson<double?>(json['clockOutLatitude']),
      clockOutLongitude:
          serializer.fromJson<double?>(json['clockOutLongitude']),
      clockOutAddress: serializer.fromJson<String?>(json['clockOutAddress']),
      clockInLocationId:
          serializer.fromJson<String?>(json['clockInLocationId']),
      clockOutLocationId:
          serializer.fromJson<String?>(json['clockOutLocationId']),
      clockInOutsideGeofence:
          serializer.fromJson<bool>(json['clockInOutsideGeofence']),
      clockOutOutsideGeofence:
          serializer.fromJson<bool>(json['clockOutOutsideGeofence']),
      breaksJson: serializer.fromJson<String>(json['breaksJson']),
      totalMinutes: serializer.fromJson<int?>(json['totalMinutes']),
      breakMinutes: serializer.fromJson<int?>(json['breakMinutes']),
      workedMinutes: serializer.fromJson<int?>(json['workedMinutes']),
      status: serializer.fromJson<String>(json['status']),
      approvedByUserId: serializer.fromJson<String?>(json['approvedByUserId']),
      approvedAt: serializer.fromJson<DateTime?>(json['approvedAt']),
      rejectionReason: serializer.fromJson<String?>(json['rejectionReason']),
      staffNotes: serializer.fromJson<String?>(json['staffNotes']),
      managerNotes: serializer.fromJson<String?>(json['managerNotes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      syncAction: serializer.fromJson<String?>(json['syncAction']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'staffId': serializer.toJson<String>(staffId),
      'clockInTime': serializer.toJson<DateTime>(clockInTime),
      'clockOutTime': serializer.toJson<DateTime?>(clockOutTime),
      'clockInLatitude': serializer.toJson<double?>(clockInLatitude),
      'clockInLongitude': serializer.toJson<double?>(clockInLongitude),
      'clockInAddress': serializer.toJson<String?>(clockInAddress),
      'clockOutLatitude': serializer.toJson<double?>(clockOutLatitude),
      'clockOutLongitude': serializer.toJson<double?>(clockOutLongitude),
      'clockOutAddress': serializer.toJson<String?>(clockOutAddress),
      'clockInLocationId': serializer.toJson<String?>(clockInLocationId),
      'clockOutLocationId': serializer.toJson<String?>(clockOutLocationId),
      'clockInOutsideGeofence': serializer.toJson<bool>(clockInOutsideGeofence),
      'clockOutOutsideGeofence':
          serializer.toJson<bool>(clockOutOutsideGeofence),
      'breaksJson': serializer.toJson<String>(breaksJson),
      'totalMinutes': serializer.toJson<int?>(totalMinutes),
      'breakMinutes': serializer.toJson<int?>(breakMinutes),
      'workedMinutes': serializer.toJson<int?>(workedMinutes),
      'status': serializer.toJson<String>(status),
      'approvedByUserId': serializer.toJson<String?>(approvedByUserId),
      'approvedAt': serializer.toJson<DateTime?>(approvedAt),
      'rejectionReason': serializer.toJson<String?>(rejectionReason),
      'staffNotes': serializer.toJson<String?>(staffNotes),
      'managerNotes': serializer.toJson<String?>(managerNotes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'syncAction': serializer.toJson<String?>(syncAction),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  TimeEntriesTableData copyWith(
          {String? id,
          String? businessId,
          String? staffId,
          DateTime? clockInTime,
          Value<DateTime?> clockOutTime = const Value.absent(),
          Value<double?> clockInLatitude = const Value.absent(),
          Value<double?> clockInLongitude = const Value.absent(),
          Value<String?> clockInAddress = const Value.absent(),
          Value<double?> clockOutLatitude = const Value.absent(),
          Value<double?> clockOutLongitude = const Value.absent(),
          Value<String?> clockOutAddress = const Value.absent(),
          Value<String?> clockInLocationId = const Value.absent(),
          Value<String?> clockOutLocationId = const Value.absent(),
          bool? clockInOutsideGeofence,
          bool? clockOutOutsideGeofence,
          String? breaksJson,
          Value<int?> totalMinutes = const Value.absent(),
          Value<int?> breakMinutes = const Value.absent(),
          Value<int?> workedMinutes = const Value.absent(),
          String? status,
          Value<String?> approvedByUserId = const Value.absent(),
          Value<DateTime?> approvedAt = const Value.absent(),
          Value<String?> rejectionReason = const Value.absent(),
          Value<String?> staffNotes = const Value.absent(),
          Value<String?> managerNotes = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent(),
          bool? pendingSync,
          Value<String?> syncAction = const Value.absent(),
          Value<DateTime?> lastSyncedAt = const Value.absent()}) =>
      TimeEntriesTableData(
        id: id ?? this.id,
        businessId: businessId ?? this.businessId,
        staffId: staffId ?? this.staffId,
        clockInTime: clockInTime ?? this.clockInTime,
        clockOutTime:
            clockOutTime.present ? clockOutTime.value : this.clockOutTime,
        clockInLatitude: clockInLatitude.present
            ? clockInLatitude.value
            : this.clockInLatitude,
        clockInLongitude: clockInLongitude.present
            ? clockInLongitude.value
            : this.clockInLongitude,
        clockInAddress:
            clockInAddress.present ? clockInAddress.value : this.clockInAddress,
        clockOutLatitude: clockOutLatitude.present
            ? clockOutLatitude.value
            : this.clockOutLatitude,
        clockOutLongitude: clockOutLongitude.present
            ? clockOutLongitude.value
            : this.clockOutLongitude,
        clockOutAddress: clockOutAddress.present
            ? clockOutAddress.value
            : this.clockOutAddress,
        clockInLocationId: clockInLocationId.present
            ? clockInLocationId.value
            : this.clockInLocationId,
        clockOutLocationId: clockOutLocationId.present
            ? clockOutLocationId.value
            : this.clockOutLocationId,
        clockInOutsideGeofence:
            clockInOutsideGeofence ?? this.clockInOutsideGeofence,
        clockOutOutsideGeofence:
            clockOutOutsideGeofence ?? this.clockOutOutsideGeofence,
        breaksJson: breaksJson ?? this.breaksJson,
        totalMinutes:
            totalMinutes.present ? totalMinutes.value : this.totalMinutes,
        breakMinutes:
            breakMinutes.present ? breakMinutes.value : this.breakMinutes,
        workedMinutes:
            workedMinutes.present ? workedMinutes.value : this.workedMinutes,
        status: status ?? this.status,
        approvedByUserId: approvedByUserId.present
            ? approvedByUserId.value
            : this.approvedByUserId,
        approvedAt: approvedAt.present ? approvedAt.value : this.approvedAt,
        rejectionReason: rejectionReason.present
            ? rejectionReason.value
            : this.rejectionReason,
        staffNotes: staffNotes.present ? staffNotes.value : this.staffNotes,
        managerNotes:
            managerNotes.present ? managerNotes.value : this.managerNotes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        pendingSync: pendingSync ?? this.pendingSync,
        syncAction: syncAction.present ? syncAction.value : this.syncAction,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
      );
  TimeEntriesTableData copyWithCompanion(TimeEntriesTableCompanion data) {
    return TimeEntriesTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId:
          data.businessId.present ? data.businessId.value : this.businessId,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      clockInTime:
          data.clockInTime.present ? data.clockInTime.value : this.clockInTime,
      clockOutTime: data.clockOutTime.present
          ? data.clockOutTime.value
          : this.clockOutTime,
      clockInLatitude: data.clockInLatitude.present
          ? data.clockInLatitude.value
          : this.clockInLatitude,
      clockInLongitude: data.clockInLongitude.present
          ? data.clockInLongitude.value
          : this.clockInLongitude,
      clockInAddress: data.clockInAddress.present
          ? data.clockInAddress.value
          : this.clockInAddress,
      clockOutLatitude: data.clockOutLatitude.present
          ? data.clockOutLatitude.value
          : this.clockOutLatitude,
      clockOutLongitude: data.clockOutLongitude.present
          ? data.clockOutLongitude.value
          : this.clockOutLongitude,
      clockOutAddress: data.clockOutAddress.present
          ? data.clockOutAddress.value
          : this.clockOutAddress,
      clockInLocationId: data.clockInLocationId.present
          ? data.clockInLocationId.value
          : this.clockInLocationId,
      clockOutLocationId: data.clockOutLocationId.present
          ? data.clockOutLocationId.value
          : this.clockOutLocationId,
      clockInOutsideGeofence: data.clockInOutsideGeofence.present
          ? data.clockInOutsideGeofence.value
          : this.clockInOutsideGeofence,
      clockOutOutsideGeofence: data.clockOutOutsideGeofence.present
          ? data.clockOutOutsideGeofence.value
          : this.clockOutOutsideGeofence,
      breaksJson:
          data.breaksJson.present ? data.breaksJson.value : this.breaksJson,
      totalMinutes: data.totalMinutes.present
          ? data.totalMinutes.value
          : this.totalMinutes,
      breakMinutes: data.breakMinutes.present
          ? data.breakMinutes.value
          : this.breakMinutes,
      workedMinutes: data.workedMinutes.present
          ? data.workedMinutes.value
          : this.workedMinutes,
      status: data.status.present ? data.status.value : this.status,
      approvedByUserId: data.approvedByUserId.present
          ? data.approvedByUserId.value
          : this.approvedByUserId,
      approvedAt:
          data.approvedAt.present ? data.approvedAt.value : this.approvedAt,
      rejectionReason: data.rejectionReason.present
          ? data.rejectionReason.value
          : this.rejectionReason,
      staffNotes:
          data.staffNotes.present ? data.staffNotes.value : this.staffNotes,
      managerNotes: data.managerNotes.present
          ? data.managerNotes.value
          : this.managerNotes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
      syncAction:
          data.syncAction.present ? data.syncAction.value : this.syncAction,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimeEntriesTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('staffId: $staffId, ')
          ..write('clockInTime: $clockInTime, ')
          ..write('clockOutTime: $clockOutTime, ')
          ..write('clockInLatitude: $clockInLatitude, ')
          ..write('clockInLongitude: $clockInLongitude, ')
          ..write('clockInAddress: $clockInAddress, ')
          ..write('clockOutLatitude: $clockOutLatitude, ')
          ..write('clockOutLongitude: $clockOutLongitude, ')
          ..write('clockOutAddress: $clockOutAddress, ')
          ..write('clockInLocationId: $clockInLocationId, ')
          ..write('clockOutLocationId: $clockOutLocationId, ')
          ..write('clockInOutsideGeofence: $clockInOutsideGeofence, ')
          ..write('clockOutOutsideGeofence: $clockOutOutsideGeofence, ')
          ..write('breaksJson: $breaksJson, ')
          ..write('totalMinutes: $totalMinutes, ')
          ..write('breakMinutes: $breakMinutes, ')
          ..write('workedMinutes: $workedMinutes, ')
          ..write('status: $status, ')
          ..write('approvedByUserId: $approvedByUserId, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('rejectionReason: $rejectionReason, ')
          ..write('staffNotes: $staffNotes, ')
          ..write('managerNotes: $managerNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('syncAction: $syncAction, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        businessId,
        staffId,
        clockInTime,
        clockOutTime,
        clockInLatitude,
        clockInLongitude,
        clockInAddress,
        clockOutLatitude,
        clockOutLongitude,
        clockOutAddress,
        clockInLocationId,
        clockOutLocationId,
        clockInOutsideGeofence,
        clockOutOutsideGeofence,
        breaksJson,
        totalMinutes,
        breakMinutes,
        workedMinutes,
        status,
        approvedByUserId,
        approvedAt,
        rejectionReason,
        staffNotes,
        managerNotes,
        createdAt,
        updatedAt,
        pendingSync,
        syncAction,
        lastSyncedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimeEntriesTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.staffId == this.staffId &&
          other.clockInTime == this.clockInTime &&
          other.clockOutTime == this.clockOutTime &&
          other.clockInLatitude == this.clockInLatitude &&
          other.clockInLongitude == this.clockInLongitude &&
          other.clockInAddress == this.clockInAddress &&
          other.clockOutLatitude == this.clockOutLatitude &&
          other.clockOutLongitude == this.clockOutLongitude &&
          other.clockOutAddress == this.clockOutAddress &&
          other.clockInLocationId == this.clockInLocationId &&
          other.clockOutLocationId == this.clockOutLocationId &&
          other.clockInOutsideGeofence == this.clockInOutsideGeofence &&
          other.clockOutOutsideGeofence == this.clockOutOutsideGeofence &&
          other.breaksJson == this.breaksJson &&
          other.totalMinutes == this.totalMinutes &&
          other.breakMinutes == this.breakMinutes &&
          other.workedMinutes == this.workedMinutes &&
          other.status == this.status &&
          other.approvedByUserId == this.approvedByUserId &&
          other.approvedAt == this.approvedAt &&
          other.rejectionReason == this.rejectionReason &&
          other.staffNotes == this.staffNotes &&
          other.managerNotes == this.managerNotes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.pendingSync == this.pendingSync &&
          other.syncAction == this.syncAction &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class TimeEntriesTableCompanion extends UpdateCompanion<TimeEntriesTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> staffId;
  final Value<DateTime> clockInTime;
  final Value<DateTime?> clockOutTime;
  final Value<double?> clockInLatitude;
  final Value<double?> clockInLongitude;
  final Value<String?> clockInAddress;
  final Value<double?> clockOutLatitude;
  final Value<double?> clockOutLongitude;
  final Value<String?> clockOutAddress;
  final Value<String?> clockInLocationId;
  final Value<String?> clockOutLocationId;
  final Value<bool> clockInOutsideGeofence;
  final Value<bool> clockOutOutsideGeofence;
  final Value<String> breaksJson;
  final Value<int?> totalMinutes;
  final Value<int?> breakMinutes;
  final Value<int?> workedMinutes;
  final Value<String> status;
  final Value<String?> approvedByUserId;
  final Value<DateTime?> approvedAt;
  final Value<String?> rejectionReason;
  final Value<String?> staffNotes;
  final Value<String?> managerNotes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<bool> pendingSync;
  final Value<String?> syncAction;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const TimeEntriesTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.staffId = const Value.absent(),
    this.clockInTime = const Value.absent(),
    this.clockOutTime = const Value.absent(),
    this.clockInLatitude = const Value.absent(),
    this.clockInLongitude = const Value.absent(),
    this.clockInAddress = const Value.absent(),
    this.clockOutLatitude = const Value.absent(),
    this.clockOutLongitude = const Value.absent(),
    this.clockOutAddress = const Value.absent(),
    this.clockInLocationId = const Value.absent(),
    this.clockOutLocationId = const Value.absent(),
    this.clockInOutsideGeofence = const Value.absent(),
    this.clockOutOutsideGeofence = const Value.absent(),
    this.breaksJson = const Value.absent(),
    this.totalMinutes = const Value.absent(),
    this.breakMinutes = const Value.absent(),
    this.workedMinutes = const Value.absent(),
    this.status = const Value.absent(),
    this.approvedByUserId = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.rejectionReason = const Value.absent(),
    this.staffNotes = const Value.absent(),
    this.managerNotes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.syncAction = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimeEntriesTableCompanion.insert({
    required String id,
    required String businessId,
    required String staffId,
    required DateTime clockInTime,
    this.clockOutTime = const Value.absent(),
    this.clockInLatitude = const Value.absent(),
    this.clockInLongitude = const Value.absent(),
    this.clockInAddress = const Value.absent(),
    this.clockOutLatitude = const Value.absent(),
    this.clockOutLongitude = const Value.absent(),
    this.clockOutAddress = const Value.absent(),
    this.clockInLocationId = const Value.absent(),
    this.clockOutLocationId = const Value.absent(),
    this.clockInOutsideGeofence = const Value.absent(),
    this.clockOutOutsideGeofence = const Value.absent(),
    this.breaksJson = const Value.absent(),
    this.totalMinutes = const Value.absent(),
    this.breakMinutes = const Value.absent(),
    this.workedMinutes = const Value.absent(),
    required String status,
    this.approvedByUserId = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.rejectionReason = const Value.absent(),
    this.staffNotes = const Value.absent(),
    this.managerNotes = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.syncAction = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        businessId = Value(businessId),
        staffId = Value(staffId),
        clockInTime = Value(clockInTime),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<TimeEntriesTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? staffId,
    Expression<DateTime>? clockInTime,
    Expression<DateTime>? clockOutTime,
    Expression<double>? clockInLatitude,
    Expression<double>? clockInLongitude,
    Expression<String>? clockInAddress,
    Expression<double>? clockOutLatitude,
    Expression<double>? clockOutLongitude,
    Expression<String>? clockOutAddress,
    Expression<String>? clockInLocationId,
    Expression<String>? clockOutLocationId,
    Expression<bool>? clockInOutsideGeofence,
    Expression<bool>? clockOutOutsideGeofence,
    Expression<String>? breaksJson,
    Expression<int>? totalMinutes,
    Expression<int>? breakMinutes,
    Expression<int>? workedMinutes,
    Expression<String>? status,
    Expression<String>? approvedByUserId,
    Expression<DateTime>? approvedAt,
    Expression<String>? rejectionReason,
    Expression<String>? staffNotes,
    Expression<String>? managerNotes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingSync,
    Expression<String>? syncAction,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (staffId != null) 'staff_id': staffId,
      if (clockInTime != null) 'clock_in_time': clockInTime,
      if (clockOutTime != null) 'clock_out_time': clockOutTime,
      if (clockInLatitude != null) 'clock_in_latitude': clockInLatitude,
      if (clockInLongitude != null) 'clock_in_longitude': clockInLongitude,
      if (clockInAddress != null) 'clock_in_address': clockInAddress,
      if (clockOutLatitude != null) 'clock_out_latitude': clockOutLatitude,
      if (clockOutLongitude != null) 'clock_out_longitude': clockOutLongitude,
      if (clockOutAddress != null) 'clock_out_address': clockOutAddress,
      if (clockInLocationId != null) 'clock_in_location_id': clockInLocationId,
      if (clockOutLocationId != null)
        'clock_out_location_id': clockOutLocationId,
      if (clockInOutsideGeofence != null)
        'clock_in_outside_geofence': clockInOutsideGeofence,
      if (clockOutOutsideGeofence != null)
        'clock_out_outside_geofence': clockOutOutsideGeofence,
      if (breaksJson != null) 'breaks_json': breaksJson,
      if (totalMinutes != null) 'total_minutes': totalMinutes,
      if (breakMinutes != null) 'break_minutes': breakMinutes,
      if (workedMinutes != null) 'worked_minutes': workedMinutes,
      if (status != null) 'status': status,
      if (approvedByUserId != null) 'approved_by_user_id': approvedByUserId,
      if (approvedAt != null) 'approved_at': approvedAt,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (staffNotes != null) 'staff_notes': staffNotes,
      if (managerNotes != null) 'manager_notes': managerNotes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (syncAction != null) 'sync_action': syncAction,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimeEntriesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? businessId,
      Value<String>? staffId,
      Value<DateTime>? clockInTime,
      Value<DateTime?>? clockOutTime,
      Value<double?>? clockInLatitude,
      Value<double?>? clockInLongitude,
      Value<String?>? clockInAddress,
      Value<double?>? clockOutLatitude,
      Value<double?>? clockOutLongitude,
      Value<String?>? clockOutAddress,
      Value<String?>? clockInLocationId,
      Value<String?>? clockOutLocationId,
      Value<bool>? clockInOutsideGeofence,
      Value<bool>? clockOutOutsideGeofence,
      Value<String>? breaksJson,
      Value<int?>? totalMinutes,
      Value<int?>? breakMinutes,
      Value<int?>? workedMinutes,
      Value<String>? status,
      Value<String?>? approvedByUserId,
      Value<DateTime?>? approvedAt,
      Value<String?>? rejectionReason,
      Value<String?>? staffNotes,
      Value<String?>? managerNotes,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<bool>? pendingSync,
      Value<String?>? syncAction,
      Value<DateTime?>? lastSyncedAt,
      Value<int>? rowid}) {
    return TimeEntriesTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      staffId: staffId ?? this.staffId,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      clockInLatitude: clockInLatitude ?? this.clockInLatitude,
      clockInLongitude: clockInLongitude ?? this.clockInLongitude,
      clockInAddress: clockInAddress ?? this.clockInAddress,
      clockOutLatitude: clockOutLatitude ?? this.clockOutLatitude,
      clockOutLongitude: clockOutLongitude ?? this.clockOutLongitude,
      clockOutAddress: clockOutAddress ?? this.clockOutAddress,
      clockInLocationId: clockInLocationId ?? this.clockInLocationId,
      clockOutLocationId: clockOutLocationId ?? this.clockOutLocationId,
      clockInOutsideGeofence:
          clockInOutsideGeofence ?? this.clockInOutsideGeofence,
      clockOutOutsideGeofence:
          clockOutOutsideGeofence ?? this.clockOutOutsideGeofence,
      breaksJson: breaksJson ?? this.breaksJson,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      workedMinutes: workedMinutes ?? this.workedMinutes,
      status: status ?? this.status,
      approvedByUserId: approvedByUserId ?? this.approvedByUserId,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      staffNotes: staffNotes ?? this.staffNotes,
      managerNotes: managerNotes ?? this.managerNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      syncAction: syncAction ?? this.syncAction,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (staffId.present) {
      map['staff_id'] = Variable<String>(staffId.value);
    }
    if (clockInTime.present) {
      map['clock_in_time'] = Variable<DateTime>(clockInTime.value);
    }
    if (clockOutTime.present) {
      map['clock_out_time'] = Variable<DateTime>(clockOutTime.value);
    }
    if (clockInLatitude.present) {
      map['clock_in_latitude'] = Variable<double>(clockInLatitude.value);
    }
    if (clockInLongitude.present) {
      map['clock_in_longitude'] = Variable<double>(clockInLongitude.value);
    }
    if (clockInAddress.present) {
      map['clock_in_address'] = Variable<String>(clockInAddress.value);
    }
    if (clockOutLatitude.present) {
      map['clock_out_latitude'] = Variable<double>(clockOutLatitude.value);
    }
    if (clockOutLongitude.present) {
      map['clock_out_longitude'] = Variable<double>(clockOutLongitude.value);
    }
    if (clockOutAddress.present) {
      map['clock_out_address'] = Variable<String>(clockOutAddress.value);
    }
    if (clockInLocationId.present) {
      map['clock_in_location_id'] = Variable<String>(clockInLocationId.value);
    }
    if (clockOutLocationId.present) {
      map['clock_out_location_id'] = Variable<String>(clockOutLocationId.value);
    }
    if (clockInOutsideGeofence.present) {
      map['clock_in_outside_geofence'] =
          Variable<bool>(clockInOutsideGeofence.value);
    }
    if (clockOutOutsideGeofence.present) {
      map['clock_out_outside_geofence'] =
          Variable<bool>(clockOutOutsideGeofence.value);
    }
    if (breaksJson.present) {
      map['breaks_json'] = Variable<String>(breaksJson.value);
    }
    if (totalMinutes.present) {
      map['total_minutes'] = Variable<int>(totalMinutes.value);
    }
    if (breakMinutes.present) {
      map['break_minutes'] = Variable<int>(breakMinutes.value);
    }
    if (workedMinutes.present) {
      map['worked_minutes'] = Variable<int>(workedMinutes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (approvedByUserId.present) {
      map['approved_by_user_id'] = Variable<String>(approvedByUserId.value);
    }
    if (approvedAt.present) {
      map['approved_at'] = Variable<DateTime>(approvedAt.value);
    }
    if (rejectionReason.present) {
      map['rejection_reason'] = Variable<String>(rejectionReason.value);
    }
    if (staffNotes.present) {
      map['staff_notes'] = Variable<String>(staffNotes.value);
    }
    if (managerNotes.present) {
      map['manager_notes'] = Variable<String>(managerNotes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (syncAction.present) {
      map['sync_action'] = Variable<String>(syncAction.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimeEntriesTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('staffId: $staffId, ')
          ..write('clockInTime: $clockInTime, ')
          ..write('clockOutTime: $clockOutTime, ')
          ..write('clockInLatitude: $clockInLatitude, ')
          ..write('clockInLongitude: $clockInLongitude, ')
          ..write('clockInAddress: $clockInAddress, ')
          ..write('clockOutLatitude: $clockOutLatitude, ')
          ..write('clockOutLongitude: $clockOutLongitude, ')
          ..write('clockOutAddress: $clockOutAddress, ')
          ..write('clockInLocationId: $clockInLocationId, ')
          ..write('clockOutLocationId: $clockOutLocationId, ')
          ..write('clockInOutsideGeofence: $clockInOutsideGeofence, ')
          ..write('clockOutOutsideGeofence: $clockOutOutsideGeofence, ')
          ..write('breaksJson: $breaksJson, ')
          ..write('totalMinutes: $totalMinutes, ')
          ..write('breakMinutes: $breakMinutes, ')
          ..write('workedMinutes: $workedMinutes, ')
          ..write('status: $status, ')
          ..write('approvedByUserId: $approvedByUserId, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('rejectionReason: $rejectionReason, ')
          ..write('staffNotes: $staffNotes, ')
          ..write('managerNotes: $managerNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('syncAction: $syncAction, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastAttemptAtMeta =
      const VerificationMeta('lastAttemptAt');
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>('last_attempt_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        entityType,
        entityId,
        action,
        payload,
        createdAt,
        retryCount,
        lastError,
        lastAttemptAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_table';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
          _lastAttemptAtMeta,
          lastAttemptAt.isAcceptableOrUnknown(
              data['last_attempt_at']!, _lastAttemptAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      lastAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_attempt_at']),
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueTableData extends DataClass
    implements Insertable<SyncQueueTableData> {
  final int id;
  final String entityType;
  final String entityId;
  final String action;
  final String payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;
  final DateTime? lastAttemptAt;
  const SyncQueueTableData(
      {required this.id,
      required this.entityType,
      required this.entityId,
      required this.action,
      required this.payload,
      required this.createdAt,
      required this.retryCount,
      this.lastError,
      this.lastAttemptAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      payload: Value(payload),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
    );
  }

  factory SyncQueueTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueTableData(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      action: serializer.fromJson<String>(json['action']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
    };
  }

  SyncQueueTableData copyWith(
          {int? id,
          String? entityType,
          String? entityId,
          String? action,
          String? payload,
          DateTime? createdAt,
          int? retryCount,
          Value<String?> lastError = const Value.absent(),
          Value<DateTime?> lastAttemptAt = const Value.absent()}) =>
      SyncQueueTableData(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        action: action ?? this.action,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        retryCount: retryCount ?? this.retryCount,
        lastError: lastError.present ? lastError.value : this.lastError,
        lastAttemptAt:
            lastAttemptAt.present ? lastAttemptAt.value : this.lastAttemptAt,
      );
  SyncQueueTableData copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('lastAttemptAt: $lastAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entityType, entityId, action, payload,
      createdAt, retryCount, lastError, lastAttemptAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueTableData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.lastAttemptAt == this.lastAttemptAt);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueTableData> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> action;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<DateTime?> lastAttemptAt;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required String action,
    required String payload,
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        action = Value(action),
        payload = Value(payload),
        createdAt = Value(createdAt);
  static Insertable<SyncQueueTableData> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<DateTime>? lastAttemptAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
    });
  }

  SyncQueueTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? action,
      Value<String>? payload,
      Value<DateTime>? createdAt,
      Value<int>? retryCount,
      Value<String?>? lastError,
      Value<DateTime?>? lastAttemptAt}) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('lastAttemptAt: $lastAttemptAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$StaffDatabase extends GeneratedDatabase {
  _$StaffDatabase(QueryExecutor e) : super(e);
  $StaffDatabaseManager get managers => $StaffDatabaseManager(this);
  late final $AppointmentsTableTable appointmentsTable =
      $AppointmentsTableTable(this);
  late final $ClientsTableTable clientsTable = $ClientsTableTable(this);
  late final $TimeEntriesTableTable timeEntriesTable =
      $TimeEntriesTableTable(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  late final AppointmentsDao appointmentsDao =
      AppointmentsDao(this as StaffDatabase);
  late final TimeEntriesDao timeEntriesDao =
      TimeEntriesDao(this as StaffDatabase);
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as StaffDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [appointmentsTable, clientsTable, timeEntriesTable, syncQueueTable];
}

typedef $$AppointmentsTableTableCreateCompanionBuilder
    = AppointmentsTableCompanion Function({
  required String id,
  required String businessId,
  Value<String> staffId,
  required String clientId,
  required String serviceId,
  required String locationId,
  Value<String?> clientName,
  Value<String?> clientPhone,
  Value<String?> clientEmail,
  Value<String?> clientAddress,
  Value<String?> serviceName,
  Value<String?> locationName,
  Value<int?> serviceDurationMinutes,
  required DateTime startTime,
  required DateTime endTime,
  required String status,
  Value<String?> notes,
  Value<String?> staffNotes,
  Value<bool> requiresPayment,
  Value<String?> paymentStatus,
  Value<DateTime?> localUpdatedAt,
  Value<bool> pendingSync,
  Value<String?> syncAction,
  Value<DateTime?> checkedInAt,
  Value<String?> checkedInByStaffId,
  Value<DateTime?> completedAt,
  Value<String?> completedByStaffId,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});
typedef $$AppointmentsTableTableUpdateCompanionBuilder
    = AppointmentsTableCompanion Function({
  Value<String> id,
  Value<String> businessId,
  Value<String> staffId,
  Value<String> clientId,
  Value<String> serviceId,
  Value<String> locationId,
  Value<String?> clientName,
  Value<String?> clientPhone,
  Value<String?> clientEmail,
  Value<String?> clientAddress,
  Value<String?> serviceName,
  Value<String?> locationName,
  Value<int?> serviceDurationMinutes,
  Value<DateTime> startTime,
  Value<DateTime> endTime,
  Value<String> status,
  Value<String?> notes,
  Value<String?> staffNotes,
  Value<bool> requiresPayment,
  Value<String?> paymentStatus,
  Value<DateTime?> localUpdatedAt,
  Value<bool> pendingSync,
  Value<String?> syncAction,
  Value<DateTime?> checkedInAt,
  Value<String?> checkedInByStaffId,
  Value<DateTime?> completedAt,
  Value<String?> completedByStaffId,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});

class $$AppointmentsTableTableFilterComposer
    extends Composer<_$StaffDatabase, $AppointmentsTableTable> {
  $$AppointmentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get businessId => $composableBuilder(
      column: $table.businessId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get staffId => $composableBuilder(
      column: $table.staffId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientId => $composableBuilder(
      column: $table.clientId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serviceId => $composableBuilder(
      column: $table.serviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get locationId => $composableBuilder(
      column: $table.locationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientPhone => $composableBuilder(
      column: $table.clientPhone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientEmail => $composableBuilder(
      column: $table.clientEmail, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientAddress => $composableBuilder(
      column: $table.clientAddress, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serviceName => $composableBuilder(
      column: $table.serviceName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get locationName => $composableBuilder(
      column: $table.locationName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serviceDurationMinutes => $composableBuilder(
      column: $table.serviceDurationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get staffNotes => $composableBuilder(
      column: $table.staffNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get requiresPayment => $composableBuilder(
      column: $table.requiresPayment,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncAction => $composableBuilder(
      column: $table.syncAction, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get checkedInAt => $composableBuilder(
      column: $table.checkedInAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkedInByStaffId => $composableBuilder(
      column: $table.checkedInByStaffId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get completedByStaffId => $composableBuilder(
      column: $table.completedByStaffId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));
}

class $$AppointmentsTableTableOrderingComposer
    extends Composer<_$StaffDatabase, $AppointmentsTableTable> {
  $$AppointmentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get businessId => $composableBuilder(
      column: $table.businessId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get staffId => $composableBuilder(
      column: $table.staffId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientId => $composableBuilder(
      column: $table.clientId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serviceId => $composableBuilder(
      column: $table.serviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get locationId => $composableBuilder(
      column: $table.locationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientPhone => $composableBuilder(
      column: $table.clientPhone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientEmail => $composableBuilder(
      column: $table.clientEmail, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientAddress => $composableBuilder(
      column: $table.clientAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serviceName => $composableBuilder(
      column: $table.serviceName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get locationName => $composableBuilder(
      column: $table.locationName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serviceDurationMinutes => $composableBuilder(
      column: $table.serviceDurationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get staffNotes => $composableBuilder(
      column: $table.staffNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get requiresPayment => $composableBuilder(
      column: $table.requiresPayment,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncAction => $composableBuilder(
      column: $table.syncAction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get checkedInAt => $composableBuilder(
      column: $table.checkedInAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkedInByStaffId => $composableBuilder(
      column: $table.checkedInByStaffId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get completedByStaffId => $composableBuilder(
      column: $table.completedByStaffId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$AppointmentsTableTableAnnotationComposer
    extends Composer<_$StaffDatabase, $AppointmentsTableTable> {
  $$AppointmentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
      column: $table.businessId, builder: (column) => column);

  GeneratedColumn<String> get staffId =>
      $composableBuilder(column: $table.staffId, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumn<String> get locationId => $composableBuilder(
      column: $table.locationId, builder: (column) => column);

  GeneratedColumn<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => column);

  GeneratedColumn<String> get clientPhone => $composableBuilder(
      column: $table.clientPhone, builder: (column) => column);

  GeneratedColumn<String> get clientEmail => $composableBuilder(
      column: $table.clientEmail, builder: (column) => column);

  GeneratedColumn<String> get clientAddress => $composableBuilder(
      column: $table.clientAddress, builder: (column) => column);

  GeneratedColumn<String> get serviceName => $composableBuilder(
      column: $table.serviceName, builder: (column) => column);

  GeneratedColumn<String> get locationName => $composableBuilder(
      column: $table.locationName, builder: (column) => column);

  GeneratedColumn<int> get serviceDurationMinutes => $composableBuilder(
      column: $table.serviceDurationMinutes, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get staffNotes => $composableBuilder(
      column: $table.staffNotes, builder: (column) => column);

  GeneratedColumn<bool> get requiresPayment => $composableBuilder(
      column: $table.requiresPayment, builder: (column) => column);

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  GeneratedColumn<String> get syncAction => $composableBuilder(
      column: $table.syncAction, builder: (column) => column);

  GeneratedColumn<DateTime> get checkedInAt => $composableBuilder(
      column: $table.checkedInAt, builder: (column) => column);

  GeneratedColumn<String> get checkedInByStaffId => $composableBuilder(
      column: $table.checkedInByStaffId, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<String> get completedByStaffId => $composableBuilder(
      column: $table.completedByStaffId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);
}

class $$AppointmentsTableTableTableManager extends RootTableManager<
    _$StaffDatabase,
    $AppointmentsTableTable,
    AppointmentsTableData,
    $$AppointmentsTableTableFilterComposer,
    $$AppointmentsTableTableOrderingComposer,
    $$AppointmentsTableTableAnnotationComposer,
    $$AppointmentsTableTableCreateCompanionBuilder,
    $$AppointmentsTableTableUpdateCompanionBuilder,
    (
      AppointmentsTableData,
      BaseReferences<_$StaffDatabase, $AppointmentsTableTable,
          AppointmentsTableData>
    ),
    AppointmentsTableData,
    PrefetchHooks Function()> {
  $$AppointmentsTableTableTableManager(
      _$StaffDatabase db, $AppointmentsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppointmentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppointmentsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppointmentsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> businessId = const Value.absent(),
            Value<String> staffId = const Value.absent(),
            Value<String> clientId = const Value.absent(),
            Value<String> serviceId = const Value.absent(),
            Value<String> locationId = const Value.absent(),
            Value<String?> clientName = const Value.absent(),
            Value<String?> clientPhone = const Value.absent(),
            Value<String?> clientEmail = const Value.absent(),
            Value<String?> clientAddress = const Value.absent(),
            Value<String?> serviceName = const Value.absent(),
            Value<String?> locationName = const Value.absent(),
            Value<int?> serviceDurationMinutes = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime> endTime = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> staffNotes = const Value.absent(),
            Value<bool> requiresPayment = const Value.absent(),
            Value<String?> paymentStatus = const Value.absent(),
            Value<DateTime?> localUpdatedAt = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<String?> syncAction = const Value.absent(),
            Value<DateTime?> checkedInAt = const Value.absent(),
            Value<String?> checkedInByStaffId = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> completedByStaffId = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppointmentsTableCompanion(
            id: id,
            businessId: businessId,
            staffId: staffId,
            clientId: clientId,
            serviceId: serviceId,
            locationId: locationId,
            clientName: clientName,
            clientPhone: clientPhone,
            clientEmail: clientEmail,
            clientAddress: clientAddress,
            serviceName: serviceName,
            locationName: locationName,
            serviceDurationMinutes: serviceDurationMinutes,
            startTime: startTime,
            endTime: endTime,
            status: status,
            notes: notes,
            staffNotes: staffNotes,
            requiresPayment: requiresPayment,
            paymentStatus: paymentStatus,
            localUpdatedAt: localUpdatedAt,
            pendingSync: pendingSync,
            syncAction: syncAction,
            checkedInAt: checkedInAt,
            checkedInByStaffId: checkedInByStaffId,
            completedAt: completedAt,
            completedByStaffId: completedByStaffId,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String businessId,
            Value<String> staffId = const Value.absent(),
            required String clientId,
            required String serviceId,
            required String locationId,
            Value<String?> clientName = const Value.absent(),
            Value<String?> clientPhone = const Value.absent(),
            Value<String?> clientEmail = const Value.absent(),
            Value<String?> clientAddress = const Value.absent(),
            Value<String?> serviceName = const Value.absent(),
            Value<String?> locationName = const Value.absent(),
            Value<int?> serviceDurationMinutes = const Value.absent(),
            required DateTime startTime,
            required DateTime endTime,
            required String status,
            Value<String?> notes = const Value.absent(),
            Value<String?> staffNotes = const Value.absent(),
            Value<bool> requiresPayment = const Value.absent(),
            Value<String?> paymentStatus = const Value.absent(),
            Value<DateTime?> localUpdatedAt = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<String?> syncAction = const Value.absent(),
            Value<DateTime?> checkedInAt = const Value.absent(),
            Value<String?> checkedInByStaffId = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> completedByStaffId = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppointmentsTableCompanion.insert(
            id: id,
            businessId: businessId,
            staffId: staffId,
            clientId: clientId,
            serviceId: serviceId,
            locationId: locationId,
            clientName: clientName,
            clientPhone: clientPhone,
            clientEmail: clientEmail,
            clientAddress: clientAddress,
            serviceName: serviceName,
            locationName: locationName,
            serviceDurationMinutes: serviceDurationMinutes,
            startTime: startTime,
            endTime: endTime,
            status: status,
            notes: notes,
            staffNotes: staffNotes,
            requiresPayment: requiresPayment,
            paymentStatus: paymentStatus,
            localUpdatedAt: localUpdatedAt,
            pendingSync: pendingSync,
            syncAction: syncAction,
            checkedInAt: checkedInAt,
            checkedInByStaffId: checkedInByStaffId,
            completedAt: completedAt,
            completedByStaffId: completedByStaffId,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppointmentsTableTableProcessedTableManager = ProcessedTableManager<
    _$StaffDatabase,
    $AppointmentsTableTable,
    AppointmentsTableData,
    $$AppointmentsTableTableFilterComposer,
    $$AppointmentsTableTableOrderingComposer,
    $$AppointmentsTableTableAnnotationComposer,
    $$AppointmentsTableTableCreateCompanionBuilder,
    $$AppointmentsTableTableUpdateCompanionBuilder,
    (
      AppointmentsTableData,
      BaseReferences<_$StaffDatabase, $AppointmentsTableTable,
          AppointmentsTableData>
    ),
    AppointmentsTableData,
    PrefetchHooks Function()>;
typedef $$ClientsTableTableCreateCompanionBuilder = ClientsTableCompanion
    Function({
  required String id,
  required String businessId,
  required String name,
  Value<String?> email,
  Value<String?> phone,
  Value<String?> address,
  Value<String?> notes,
  required DateTime lastSyncedAt,
  Value<int> rowid,
});
typedef $$ClientsTableTableUpdateCompanionBuilder = ClientsTableCompanion
    Function({
  Value<String> id,
  Value<String> businessId,
  Value<String> name,
  Value<String?> email,
  Value<String?> phone,
  Value<String?> address,
  Value<String?> notes,
  Value<DateTime> lastSyncedAt,
  Value<int> rowid,
});

class $$ClientsTableTableFilterComposer
    extends Composer<_$StaffDatabase, $ClientsTableTable> {
  $$ClientsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get businessId => $composableBuilder(
      column: $table.businessId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));
}

class $$ClientsTableTableOrderingComposer
    extends Composer<_$StaffDatabase, $ClientsTableTable> {
  $$ClientsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get businessId => $composableBuilder(
      column: $table.businessId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$ClientsTableTableAnnotationComposer
    extends Composer<_$StaffDatabase, $ClientsTableTable> {
  $$ClientsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
      column: $table.businessId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);
}

class $$ClientsTableTableTableManager extends RootTableManager<
    _$StaffDatabase,
    $ClientsTableTable,
    ClientsTableData,
    $$ClientsTableTableFilterComposer,
    $$ClientsTableTableOrderingComposer,
    $$ClientsTableTableAnnotationComposer,
    $$ClientsTableTableCreateCompanionBuilder,
    $$ClientsTableTableUpdateCompanionBuilder,
    (
      ClientsTableData,
      BaseReferences<_$StaffDatabase, $ClientsTableTable, ClientsTableData>
    ),
    ClientsTableData,
    PrefetchHooks Function()> {
  $$ClientsTableTableTableManager(_$StaffDatabase db, $ClientsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> businessId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClientsTableCompanion(
            id: id,
            businessId: businessId,
            name: name,
            email: email,
            phone: phone,
            address: address,
            notes: notes,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String businessId,
            required String name,
            Value<String?> email = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime lastSyncedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ClientsTableCompanion.insert(
            id: id,
            businessId: businessId,
            name: name,
            email: email,
            phone: phone,
            address: address,
            notes: notes,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ClientsTableTableProcessedTableManager = ProcessedTableManager<
    _$StaffDatabase,
    $ClientsTableTable,
    ClientsTableData,
    $$ClientsTableTableFilterComposer,
    $$ClientsTableTableOrderingComposer,
    $$ClientsTableTableAnnotationComposer,
    $$ClientsTableTableCreateCompanionBuilder,
    $$ClientsTableTableUpdateCompanionBuilder,
    (
      ClientsTableData,
      BaseReferences<_$StaffDatabase, $ClientsTableTable, ClientsTableData>
    ),
    ClientsTableData,
    PrefetchHooks Function()>;
typedef $$TimeEntriesTableTableCreateCompanionBuilder
    = TimeEntriesTableCompanion Function({
  required String id,
  required String businessId,
  required String staffId,
  required DateTime clockInTime,
  Value<DateTime?> clockOutTime,
  Value<double?> clockInLatitude,
  Value<double?> clockInLongitude,
  Value<String?> clockInAddress,
  Value<double?> clockOutLatitude,
  Value<double?> clockOutLongitude,
  Value<String?> clockOutAddress,
  Value<String?> clockInLocationId,
  Value<String?> clockOutLocationId,
  Value<bool> clockInOutsideGeofence,
  Value<bool> clockOutOutsideGeofence,
  Value<String> breaksJson,
  Value<int?> totalMinutes,
  Value<int?> breakMinutes,
  Value<int?> workedMinutes,
  required String status,
  Value<String?> approvedByUserId,
  Value<DateTime?> approvedAt,
  Value<String?> rejectionReason,
  Value<String?> staffNotes,
  Value<String?> managerNotes,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
  Value<bool> pendingSync,
  Value<String?> syncAction,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});
typedef $$TimeEntriesTableTableUpdateCompanionBuilder
    = TimeEntriesTableCompanion Function({
  Value<String> id,
  Value<String> businessId,
  Value<String> staffId,
  Value<DateTime> clockInTime,
  Value<DateTime?> clockOutTime,
  Value<double?> clockInLatitude,
  Value<double?> clockInLongitude,
  Value<String?> clockInAddress,
  Value<double?> clockOutLatitude,
  Value<double?> clockOutLongitude,
  Value<String?> clockOutAddress,
  Value<String?> clockInLocationId,
  Value<String?> clockOutLocationId,
  Value<bool> clockInOutsideGeofence,
  Value<bool> clockOutOutsideGeofence,
  Value<String> breaksJson,
  Value<int?> totalMinutes,
  Value<int?> breakMinutes,
  Value<int?> workedMinutes,
  Value<String> status,
  Value<String?> approvedByUserId,
  Value<DateTime?> approvedAt,
  Value<String?> rejectionReason,
  Value<String?> staffNotes,
  Value<String?> managerNotes,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<bool> pendingSync,
  Value<String?> syncAction,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});

class $$TimeEntriesTableTableFilterComposer
    extends Composer<_$StaffDatabase, $TimeEntriesTableTable> {
  $$TimeEntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get businessId => $composableBuilder(
      column: $table.businessId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get staffId => $composableBuilder(
      column: $table.staffId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get clockInTime => $composableBuilder(
      column: $table.clockInTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get clockOutTime => $composableBuilder(
      column: $table.clockOutTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get clockInLatitude => $composableBuilder(
      column: $table.clockInLatitude,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get clockInLongitude => $composableBuilder(
      column: $table.clockInLongitude,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clockInAddress => $composableBuilder(
      column: $table.clockInAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get clockOutLatitude => $composableBuilder(
      column: $table.clockOutLatitude,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get clockOutLongitude => $composableBuilder(
      column: $table.clockOutLongitude,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clockOutAddress => $composableBuilder(
      column: $table.clockOutAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clockInLocationId => $composableBuilder(
      column: $table.clockInLocationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clockOutLocationId => $composableBuilder(
      column: $table.clockOutLocationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get clockInOutsideGeofence => $composableBuilder(
      column: $table.clockInOutsideGeofence,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get clockOutOutsideGeofence => $composableBuilder(
      column: $table.clockOutOutsideGeofence,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get breaksJson => $composableBuilder(
      column: $table.breaksJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalMinutes => $composableBuilder(
      column: $table.totalMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get breakMinutes => $composableBuilder(
      column: $table.breakMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get workedMinutes => $composableBuilder(
      column: $table.workedMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get approvedByUserId => $composableBuilder(
      column: $table.approvedByUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get approvedAt => $composableBuilder(
      column: $table.approvedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rejectionReason => $composableBuilder(
      column: $table.rejectionReason,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get staffNotes => $composableBuilder(
      column: $table.staffNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get managerNotes => $composableBuilder(
      column: $table.managerNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncAction => $composableBuilder(
      column: $table.syncAction, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));
}

class $$TimeEntriesTableTableOrderingComposer
    extends Composer<_$StaffDatabase, $TimeEntriesTableTable> {
  $$TimeEntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get businessId => $composableBuilder(
      column: $table.businessId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get staffId => $composableBuilder(
      column: $table.staffId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get clockInTime => $composableBuilder(
      column: $table.clockInTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get clockOutTime => $composableBuilder(
      column: $table.clockOutTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get clockInLatitude => $composableBuilder(
      column: $table.clockInLatitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get clockInLongitude => $composableBuilder(
      column: $table.clockInLongitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clockInAddress => $composableBuilder(
      column: $table.clockInAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get clockOutLatitude => $composableBuilder(
      column: $table.clockOutLatitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get clockOutLongitude => $composableBuilder(
      column: $table.clockOutLongitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clockOutAddress => $composableBuilder(
      column: $table.clockOutAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clockInLocationId => $composableBuilder(
      column: $table.clockInLocationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clockOutLocationId => $composableBuilder(
      column: $table.clockOutLocationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get clockInOutsideGeofence => $composableBuilder(
      column: $table.clockInOutsideGeofence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get clockOutOutsideGeofence => $composableBuilder(
      column: $table.clockOutOutsideGeofence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get breaksJson => $composableBuilder(
      column: $table.breaksJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalMinutes => $composableBuilder(
      column: $table.totalMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get breakMinutes => $composableBuilder(
      column: $table.breakMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get workedMinutes => $composableBuilder(
      column: $table.workedMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get approvedByUserId => $composableBuilder(
      column: $table.approvedByUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get approvedAt => $composableBuilder(
      column: $table.approvedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rejectionReason => $composableBuilder(
      column: $table.rejectionReason,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get staffNotes => $composableBuilder(
      column: $table.staffNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get managerNotes => $composableBuilder(
      column: $table.managerNotes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncAction => $composableBuilder(
      column: $table.syncAction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$TimeEntriesTableTableAnnotationComposer
    extends Composer<_$StaffDatabase, $TimeEntriesTableTable> {
  $$TimeEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
      column: $table.businessId, builder: (column) => column);

  GeneratedColumn<String> get staffId =>
      $composableBuilder(column: $table.staffId, builder: (column) => column);

  GeneratedColumn<DateTime> get clockInTime => $composableBuilder(
      column: $table.clockInTime, builder: (column) => column);

  GeneratedColumn<DateTime> get clockOutTime => $composableBuilder(
      column: $table.clockOutTime, builder: (column) => column);

  GeneratedColumn<double> get clockInLatitude => $composableBuilder(
      column: $table.clockInLatitude, builder: (column) => column);

  GeneratedColumn<double> get clockInLongitude => $composableBuilder(
      column: $table.clockInLongitude, builder: (column) => column);

  GeneratedColumn<String> get clockInAddress => $composableBuilder(
      column: $table.clockInAddress, builder: (column) => column);

  GeneratedColumn<double> get clockOutLatitude => $composableBuilder(
      column: $table.clockOutLatitude, builder: (column) => column);

  GeneratedColumn<double> get clockOutLongitude => $composableBuilder(
      column: $table.clockOutLongitude, builder: (column) => column);

  GeneratedColumn<String> get clockOutAddress => $composableBuilder(
      column: $table.clockOutAddress, builder: (column) => column);

  GeneratedColumn<String> get clockInLocationId => $composableBuilder(
      column: $table.clockInLocationId, builder: (column) => column);

  GeneratedColumn<String> get clockOutLocationId => $composableBuilder(
      column: $table.clockOutLocationId, builder: (column) => column);

  GeneratedColumn<bool> get clockInOutsideGeofence => $composableBuilder(
      column: $table.clockInOutsideGeofence, builder: (column) => column);

  GeneratedColumn<bool> get clockOutOutsideGeofence => $composableBuilder(
      column: $table.clockOutOutsideGeofence, builder: (column) => column);

  GeneratedColumn<String> get breaksJson => $composableBuilder(
      column: $table.breaksJson, builder: (column) => column);

  GeneratedColumn<int> get totalMinutes => $composableBuilder(
      column: $table.totalMinutes, builder: (column) => column);

  GeneratedColumn<int> get breakMinutes => $composableBuilder(
      column: $table.breakMinutes, builder: (column) => column);

  GeneratedColumn<int> get workedMinutes => $composableBuilder(
      column: $table.workedMinutes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get approvedByUserId => $composableBuilder(
      column: $table.approvedByUserId, builder: (column) => column);

  GeneratedColumn<DateTime> get approvedAt => $composableBuilder(
      column: $table.approvedAt, builder: (column) => column);

  GeneratedColumn<String> get rejectionReason => $composableBuilder(
      column: $table.rejectionReason, builder: (column) => column);

  GeneratedColumn<String> get staffNotes => $composableBuilder(
      column: $table.staffNotes, builder: (column) => column);

  GeneratedColumn<String> get managerNotes => $composableBuilder(
      column: $table.managerNotes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  GeneratedColumn<String> get syncAction => $composableBuilder(
      column: $table.syncAction, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);
}

class $$TimeEntriesTableTableTableManager extends RootTableManager<
    _$StaffDatabase,
    $TimeEntriesTableTable,
    TimeEntriesTableData,
    $$TimeEntriesTableTableFilterComposer,
    $$TimeEntriesTableTableOrderingComposer,
    $$TimeEntriesTableTableAnnotationComposer,
    $$TimeEntriesTableTableCreateCompanionBuilder,
    $$TimeEntriesTableTableUpdateCompanionBuilder,
    (
      TimeEntriesTableData,
      BaseReferences<_$StaffDatabase, $TimeEntriesTableTable,
          TimeEntriesTableData>
    ),
    TimeEntriesTableData,
    PrefetchHooks Function()> {
  $$TimeEntriesTableTableTableManager(
      _$StaffDatabase db, $TimeEntriesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimeEntriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimeEntriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimeEntriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> businessId = const Value.absent(),
            Value<String> staffId = const Value.absent(),
            Value<DateTime> clockInTime = const Value.absent(),
            Value<DateTime?> clockOutTime = const Value.absent(),
            Value<double?> clockInLatitude = const Value.absent(),
            Value<double?> clockInLongitude = const Value.absent(),
            Value<String?> clockInAddress = const Value.absent(),
            Value<double?> clockOutLatitude = const Value.absent(),
            Value<double?> clockOutLongitude = const Value.absent(),
            Value<String?> clockOutAddress = const Value.absent(),
            Value<String?> clockInLocationId = const Value.absent(),
            Value<String?> clockOutLocationId = const Value.absent(),
            Value<bool> clockInOutsideGeofence = const Value.absent(),
            Value<bool> clockOutOutsideGeofence = const Value.absent(),
            Value<String> breaksJson = const Value.absent(),
            Value<int?> totalMinutes = const Value.absent(),
            Value<int?> breakMinutes = const Value.absent(),
            Value<int?> workedMinutes = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> approvedByUserId = const Value.absent(),
            Value<DateTime?> approvedAt = const Value.absent(),
            Value<String?> rejectionReason = const Value.absent(),
            Value<String?> staffNotes = const Value.absent(),
            Value<String?> managerNotes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<String?> syncAction = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TimeEntriesTableCompanion(
            id: id,
            businessId: businessId,
            staffId: staffId,
            clockInTime: clockInTime,
            clockOutTime: clockOutTime,
            clockInLatitude: clockInLatitude,
            clockInLongitude: clockInLongitude,
            clockInAddress: clockInAddress,
            clockOutLatitude: clockOutLatitude,
            clockOutLongitude: clockOutLongitude,
            clockOutAddress: clockOutAddress,
            clockInLocationId: clockInLocationId,
            clockOutLocationId: clockOutLocationId,
            clockInOutsideGeofence: clockInOutsideGeofence,
            clockOutOutsideGeofence: clockOutOutsideGeofence,
            breaksJson: breaksJson,
            totalMinutes: totalMinutes,
            breakMinutes: breakMinutes,
            workedMinutes: workedMinutes,
            status: status,
            approvedByUserId: approvedByUserId,
            approvedAt: approvedAt,
            rejectionReason: rejectionReason,
            staffNotes: staffNotes,
            managerNotes: managerNotes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            pendingSync: pendingSync,
            syncAction: syncAction,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String businessId,
            required String staffId,
            required DateTime clockInTime,
            Value<DateTime?> clockOutTime = const Value.absent(),
            Value<double?> clockInLatitude = const Value.absent(),
            Value<double?> clockInLongitude = const Value.absent(),
            Value<String?> clockInAddress = const Value.absent(),
            Value<double?> clockOutLatitude = const Value.absent(),
            Value<double?> clockOutLongitude = const Value.absent(),
            Value<String?> clockOutAddress = const Value.absent(),
            Value<String?> clockInLocationId = const Value.absent(),
            Value<String?> clockOutLocationId = const Value.absent(),
            Value<bool> clockInOutsideGeofence = const Value.absent(),
            Value<bool> clockOutOutsideGeofence = const Value.absent(),
            Value<String> breaksJson = const Value.absent(),
            Value<int?> totalMinutes = const Value.absent(),
            Value<int?> breakMinutes = const Value.absent(),
            Value<int?> workedMinutes = const Value.absent(),
            required String status,
            Value<String?> approvedByUserId = const Value.absent(),
            Value<DateTime?> approvedAt = const Value.absent(),
            Value<String?> rejectionReason = const Value.absent(),
            Value<String?> staffNotes = const Value.absent(),
            Value<String?> managerNotes = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<String?> syncAction = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TimeEntriesTableCompanion.insert(
            id: id,
            businessId: businessId,
            staffId: staffId,
            clockInTime: clockInTime,
            clockOutTime: clockOutTime,
            clockInLatitude: clockInLatitude,
            clockInLongitude: clockInLongitude,
            clockInAddress: clockInAddress,
            clockOutLatitude: clockOutLatitude,
            clockOutLongitude: clockOutLongitude,
            clockOutAddress: clockOutAddress,
            clockInLocationId: clockInLocationId,
            clockOutLocationId: clockOutLocationId,
            clockInOutsideGeofence: clockInOutsideGeofence,
            clockOutOutsideGeofence: clockOutOutsideGeofence,
            breaksJson: breaksJson,
            totalMinutes: totalMinutes,
            breakMinutes: breakMinutes,
            workedMinutes: workedMinutes,
            status: status,
            approvedByUserId: approvedByUserId,
            approvedAt: approvedAt,
            rejectionReason: rejectionReason,
            staffNotes: staffNotes,
            managerNotes: managerNotes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            pendingSync: pendingSync,
            syncAction: syncAction,
            lastSyncedAt: lastSyncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TimeEntriesTableTableProcessedTableManager = ProcessedTableManager<
    _$StaffDatabase,
    $TimeEntriesTableTable,
    TimeEntriesTableData,
    $$TimeEntriesTableTableFilterComposer,
    $$TimeEntriesTableTableOrderingComposer,
    $$TimeEntriesTableTableAnnotationComposer,
    $$TimeEntriesTableTableCreateCompanionBuilder,
    $$TimeEntriesTableTableUpdateCompanionBuilder,
    (
      TimeEntriesTableData,
      BaseReferences<_$StaffDatabase, $TimeEntriesTableTable,
          TimeEntriesTableData>
    ),
    TimeEntriesTableData,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableTableCreateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> id,
  required String entityType,
  required String entityId,
  required String action,
  required String payload,
  required DateTime createdAt,
  Value<int> retryCount,
  Value<String?> lastError,
  Value<DateTime?> lastAttemptAt,
});
typedef $$SyncQueueTableTableUpdateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> id,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> action,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<int> retryCount,
  Value<String?> lastError,
  Value<DateTime?> lastAttemptAt,
});

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$StaffDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$StaffDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt,
      builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$StaffDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => column);
}

class $$SyncQueueTableTableTableManager extends RootTableManager<
    _$StaffDatabase,
    $SyncQueueTableTable,
    SyncQueueTableData,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueTableData,
      BaseReferences<_$StaffDatabase, $SyncQueueTableTable, SyncQueueTableData>
    ),
    SyncQueueTableData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableTableManager(
      _$StaffDatabase db, $SyncQueueTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
          }) =>
              SyncQueueTableCompanion(
            id: id,
            entityType: entityType,
            entityId: entityId,
            action: action,
            payload: payload,
            createdAt: createdAt,
            retryCount: retryCount,
            lastError: lastError,
            lastAttemptAt: lastAttemptAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entityType,
            required String entityId,
            required String action,
            required String payload,
            required DateTime createdAt,
            Value<int> retryCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
          }) =>
              SyncQueueTableCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            action: action,
            payload: payload,
            createdAt: createdAt,
            retryCount: retryCount,
            lastError: lastError,
            lastAttemptAt: lastAttemptAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableTableProcessedTableManager = ProcessedTableManager<
    _$StaffDatabase,
    $SyncQueueTableTable,
    SyncQueueTableData,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueTableData,
      BaseReferences<_$StaffDatabase, $SyncQueueTableTable, SyncQueueTableData>
    ),
    SyncQueueTableData,
    PrefetchHooks Function()>;

class $StaffDatabaseManager {
  final _$StaffDatabase _db;
  $StaffDatabaseManager(this._db);
  $$AppointmentsTableTableTableManager get appointmentsTable =>
      $$AppointmentsTableTableTableManager(_db, _db.appointmentsTable);
  $$ClientsTableTableTableManager get clientsTable =>
      $$ClientsTableTableTableManager(_db, _db.clientsTable);
  $$TimeEntriesTableTableTableManager get timeEntriesTable =>
      $$TimeEntriesTableTableTableManager(_db, _db.timeEntriesTable);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
}
