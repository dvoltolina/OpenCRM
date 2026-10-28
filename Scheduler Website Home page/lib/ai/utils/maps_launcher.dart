import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

/// Opens the platform maps app with the given destination.
/// Prefer coordinates to avoid leaking sensitive address details in the URL.
Future<void> openInMaps({
  double? latitude,
  double? longitude,
  String? addressLabel,
}) async {
  final hasCoords = latitude != null && longitude != null;
  if (!hasCoords && (addressLabel == null || addressLabel.isEmpty)) {
    throw ArgumentError('A destination (coords or addressLabel) is required.');
  }

  final destination = hasCoords
      ? '${latitude!.toStringAsFixed(6)},${longitude!.toStringAsFixed(6)}'
      : Uri.encodeComponent(addressLabel!);

  final url = hasCoords
      ? (Platform.isIOS
          ? 'https://maps.apple.com/?daddr=$destination'
          : 'https://maps.google.com/?daddr=$destination')
      : (Platform.isIOS
          ? 'https://maps.apple.com/?q=$destination'
          : 'https://maps.google.com/?q=$destination');

  final uri = Uri.parse(url);
  if (!await canLaunchUrl(uri)) {
    throw Exception('Could not launch maps for destination: $destination');
  }

  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
