import '../../data/models/appointment.dart';
import '../../data/models/client.dart';
import '../../data/models/location.dart';
import '../../data/models/magic_link_token.dart';
import '../../data/models/provider.dart';
import '../../data/models/security_context.dart';
import '../../data/models/service.dart';
import '../../data/repositories/appointments_repository.dart';
import '../../data/repositories/clients_repository.dart';
import '../../data/repositories/locations_repository.dart';
import '../../data/repositories/providers_repository.dart';
import '../../data/repositories/services_repository.dart';
import 'magic_link_service.dart';

/// Loads appointment context from a magic link token for client-facing flows.
class MagicLinkAppointmentLoader {
  MagicLinkAppointmentLoader({
    MagicLinkService? magicLinkService,
    AppointmentsRepository? appointmentsRepository,
    ClientsRepository? clientsRepository,
    ProvidersRepository? providersRepository,
    ServicesRepository? servicesRepository,
    LocationsRepository? locationsRepository,
  }) : _magicLinkService = magicLinkService ?? MagicLinkService(),
       _appointmentsRepository =
           appointmentsRepository ?? AppointmentsRepository(),
       _clientsRepository = clientsRepository ?? ClientsRepository(),
       _providersRepository = providersRepository ?? ProvidersRepository(),
       _servicesRepository = servicesRepository ?? ServicesRepository(),
       _locationsRepository = locationsRepository ?? LocationsRepository();

  final MagicLinkService _magicLinkService;
  final AppointmentsRepository _appointmentsRepository;
  final ClientsRepository _clientsRepository;
  final ProvidersRepository _providersRepository;
  final ServicesRepository _servicesRepository;
  final LocationsRepository _locationsRepository;

  /// Loads appointment context based on the provided token string.
  Future<MagicLinkAppointmentData> load({
    required String tokenString,
    required String businessId,
  }) async {
    final token = await _magicLinkService.validateToken(
      tokenString: tokenString,
      businessId: businessId,
    );

    if (token == null) {
      throw MagicLinkLoadException('Invalid or expired link.');
    }

    final securityContext = SecurityContext(
      userId: token.clientId,
      businessId: token.businessId,
      role: UserRole.client,
      clientId: token.clientId,
    );

    final appointment = await _appointmentsRepository.getAppointment(
      context: securityContext,
      appointmentId: token.appointmentId,
    );

    if (appointment == null) {
      throw MagicLinkLoadException('Appointment no longer exists.');
    }

    final results = await Future.wait([
      _clientsRepository.getClient(
        context: securityContext,
        clientId: appointment.clientId,
      ),
      _providersRepository.getProvider(
        context: securityContext,
        providerId: appointment.providerId,
      ),
      _servicesRepository.getService(
        context: securityContext,
        serviceId: appointment.serviceId,
      ),
      _locationsRepository.getLocation(
        context: securityContext,
        locationId: appointment.locationId,
      ),
    ]);

    final client = results[0] as Client?;
    final provider = results[1] as Provider?;
    final service = results[2] as Service?;
    final location = results[3] as Location?;

    if (client == null ||
        provider == null ||
        service == null ||
        location == null) {
      throw MagicLinkLoadException(
        'Required appointment details are missing. Please contact support.',
      );
    }

    return MagicLinkAppointmentData(
      token: token,
      appointment: appointment,
      client: client,
      provider: provider,
      service: service,
      location: location,
      securityContext: securityContext,
    );
  }
}

/// Handy container with the entities needed for modification workflows.
class MagicLinkAppointmentData {
  MagicLinkAppointmentData({
    required this.token,
    required this.appointment,
    required this.client,
    required this.provider,
    required this.service,
    required this.location,
    required this.securityContext,
  });

  final MagicLinkToken token;
  final Appointment appointment;
  final Client client;
  final Provider provider;
  final Service service;
  final Location location;
  final SecurityContext securityContext;
}

/// Exception thrown when token validation or data loading fails.
class MagicLinkLoadException implements Exception {
  MagicLinkLoadException(this.message);

  final String message;

  @override
  String toString() => 'MagicLinkLoadException: $message';
}
