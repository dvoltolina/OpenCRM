import '../../data/models/client.dart';
import '../../data/models/location.dart';
import '../../data/models/provider.dart';
import '../../data/models/service.dart';

class BookingContextSnapshot {
  const BookingContextSnapshot({
    required this.client,
    required this.provider,
    required this.service,
    required this.location,
    required this.startTime,
    required this.endTime,
  });

  final Client client;
  final Provider provider;
  final Service service;
  final Location location;
  final DateTime startTime;
  final DateTime endTime;
}

