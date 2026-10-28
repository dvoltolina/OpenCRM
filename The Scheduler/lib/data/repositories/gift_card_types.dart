// Helper types for gift card operations.
// These classes are used by GiftCardRepository and GiftCardTemplateRepository.

/// Exception for gift card-specific errors
class GiftCardException implements Exception {
  GiftCardException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() =>
      'GiftCardException: $message${code != null ? ' ($code)' : ''}';
}

/// Result of checking gift card balance
class GiftCardBalance {
  GiftCardBalance({
    required this.valid,
    required this.balanceCents,
    this.expiresAt,
    this.code,
  });

  final bool valid;
  final int balanceCents;
  final DateTime? expiresAt;
  final String? code;

  double get balanceDollars => balanceCents / 100.0;
}

/// Aggregated gift card statistics for a business
class GiftCardStats {
  GiftCardStats({
    required this.totalSoldCents,
    required this.totalSoldCount,
    required this.outstandingBalanceCents,
    required this.totalRedeemedCents,
    required this.redemptionCount,
  });

  /// Creates empty stats (all zeros)
  factory GiftCardStats.empty() => GiftCardStats(
        totalSoldCents: 0,
        totalSoldCount: 0,
        outstandingBalanceCents: 0,
        totalRedeemedCents: 0,
        redemptionCount: 0,
      );

  final int totalSoldCents;
  final int totalSoldCount;
  final int outstandingBalanceCents;
  final int totalRedeemedCents;
  final int redemptionCount;

  double get totalSoldDollars => totalSoldCents / 100.0;
  double get outstandingBalanceDollars => outstandingBalanceCents / 100.0;
  double get totalRedeemedDollars => totalRedeemedCents / 100.0;
}
