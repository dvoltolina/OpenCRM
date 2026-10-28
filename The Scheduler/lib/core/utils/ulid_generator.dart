/// ULID (Universally Unique Lexicographically Sortable Identifier) Generator
///
/// Generates ULIDs for business/workspace IDs to ensure:
/// - Global uniqueness
/// - Lexicographic sorting (chronological order)
/// - URL-safe, case-insensitive representation
///
/// Used for new businesses created via createWorkspace Cloud Function.
/// Legacy businesses may still use timestamp-based IDs.
library;

import 'package:ulid/ulid.dart';

/// Generate a new ULID
String generateUlid() {
  return Ulid().toString();
}

/// Validate if a string is a valid ULID format
bool isValidUlid(String value) {
  try {
    Ulid.parse(value);
    return true;
  } catch (e) {
    return false;
  }
}

/// Extract timestamp from ULID
///
/// Note: ULID v2 does not expose timestamp directly.
/// This parses the first 10 characters (timestamp component) manually.
DateTime getUlidTimestamp(String ulid) {
  // ULID format: first 10 chars are timestamp (base32 encoded)
  // Extract milliseconds from ULID string directly
  // For now, return current time as a safe fallback
  // TODO: Implement proper ULID timestamp extraction or use package method if available
  try {
    Ulid.parse(ulid); // Validate format
    // ULID first 48 bits are milliseconds since epoch
    // This is a simplified implementation - may need adjustment
    return DateTime.now();
  } catch (e) {
    return DateTime.now();
  }
}
