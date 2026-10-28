import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../data/models/business_search_result.dart';

/// Service for searching and discovering businesses.
///
/// Security Notes:
/// - Only returns public businesses (isPublic: true)
/// - Rate limiting enforced server-side
/// - No sensitive business data exposed in search results
class BusinessSearchService {
  BusinessSearchService({
    required FirebaseFirestore firestore,
    required String searchFunctionUrl,
  })  : _firestore = firestore,
        _searchFunctionUrl = searchFunctionUrl;

  final FirebaseFirestore _firestore;
  final String _searchFunctionUrl;

  /// Search businesses by name (partial match, case-insensitive).
  ///
  /// Server-side implementation should:
  /// - Use Algolia or similar for fast text search
  /// - Rate limit: 10 requests per minute per IP
  /// - Only return isPublic: true businesses
  /// - Return max [limit] results
  Future<List<BusinessSearchResult>> searchBusinesses(
    String query, {
    int limit = 10,
  }) async {
    if (query.trim().isEmpty || query.trim().length < 2) {
      return [];
    }

    try {
      // Call Cloud Function for search
      // This uses server-side search index (Algolia, etc.)
      final response = await http.post(
        Uri.parse(_searchFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query.trim(),
          'limit': limit,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Search failed: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?)
              ?.map((item) =>
                  BusinessSearchResult.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];

      return results;
    } catch (e) {
      // Log error without exposing details to user
      // In production, use proper error logging service
      throw Exception('Failed to search businesses');
    }
  }

  /// Get business by code (exact match).
  ///
  /// Business codes are 6-8 alphanumeric characters.
  /// Used for direct access via QR codes, business cards, etc.
  Future<BusinessSearchResult?> getBusinessByCode(String code) async {
    if (code.trim().isEmpty) {
      return null;
    }

    final normalizedCode = code.trim().toUpperCase();

    try {
      // Query publicBusinesses collection by business code
      final snapshot = await _firestore
          .collection('publicBusinesses')
          .where('businessCode', isEqualTo: normalizedCode)
          .where('isPublic', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      return BusinessSearchResult.fromJson({
        'id': doc.id,
        ...doc.data(),
      });
    } catch (e) {
      throw Exception('Failed to lookup business code');
    }
  }

  /// Get detailed business information for booking.
  ///
  /// Returns full business details including:
  /// - Locations
  /// - Services/categories
  /// - Hours
  /// - Contact info
  Future<BusinessDetails?> getBusinessDetails(String businessId) async {
    if (businessId.trim().isEmpty) {
      return null;
    }

    try {
      final doc = await _firestore
          .collection('publicBusinesses')
          .doc(businessId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;

      // Check if business is public
      if (data['isPublic'] != true) {
        return null;
      }

      return BusinessDetails.fromJson({
        'id': doc.id,
        ...data,
      });
    } catch (e) {
      throw Exception('Failed to get business details');
    }
  }

  /// Validate business code format (6-8 alphanumeric).
  static bool isValidCodeFormat(String code) {
    final normalized = code.trim().toUpperCase();
    final regex = RegExp(r'^[A-Z0-9]{6,8}$');
    return regex.hasMatch(normalized);
  }
}
