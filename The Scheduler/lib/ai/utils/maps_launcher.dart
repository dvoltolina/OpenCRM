import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

/// Open native maps for provided coordinates with an optional label.
Future<void> openInMaps({
  required double latitude,
  required double longitude,
  String? addressLabel,
}) async {
  final lat = latitude.toStringAsFixed(6);
  final lng = longitude.toStringAsFixed(6);
  final encodedLabel =
      (addressLabel?.trim().isNotEmpty ?? false) ? Uri.encodeComponent(addressLabel!.trim()) : null;

  final uri = Platform.isIOS
      ? Uri.parse('http://maps.apple.com/?ll=$lat,$lng${encodedLabel != null ? '&q=$encodedLabel' : ''}')
      : Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng${encodedLabel != null ? '%20($encodedLabel)' : ''}',
        );

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    throw Exception('Could not launch maps for $lat,$lng');
  }
}
