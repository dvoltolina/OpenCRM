import 'package:flutter/material.dart';

/// Converts common hex string formats to a [Color].
///
/// Accepts `#RRGGBB`, `RRGGBB`, or `AARRGGBB`. Returns [fallback] on
/// invalid input.
Color hexToColor(String? hexString, {Color fallback = Colors.blue}) {
  if (hexString == null || hexString.isEmpty) return fallback;
  try {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (_) {
    return fallback;
  }
}
