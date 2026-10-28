import 'package:flutter/material.dart';

import '../../../../data/models/appointment.dart';

/// Displays a status banner for an appointment
class AppointmentStatusBanner extends StatelessWidget {
  const AppointmentStatusBanner({
    required this.status,
    super.key,
  });

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bannerData = _getBannerData(theme);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerData.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(bannerData.icon, color: bannerData.textColor),
          const SizedBox(width: 12),
          Text(
            'Status: ${bannerData.statusText}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: bannerData.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  _BannerData _getBannerData(ThemeData theme) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return _BannerData(
          icon: Icons.check_circle_outline,
          backgroundColor: theme.colorScheme.primaryContainer,
          textColor: theme.colorScheme.onPrimaryContainer,
          statusText: 'Confirmed',
        );
      case AppointmentStatus.pending:
        return _BannerData(
          icon: Icons.schedule_outlined,
          backgroundColor: theme.colorScheme.secondaryContainer,
          textColor: theme.colorScheme.onSecondaryContainer,
          statusText: 'Pending Confirmation',
        );
      case AppointmentStatus.cancelled:
        return _BannerData(
          icon: Icons.cancel_outlined,
          backgroundColor: theme.colorScheme.errorContainer,
          textColor: theme.colorScheme.onErrorContainer,
          statusText: 'Cancelled',
        );
      case AppointmentStatus.completed:
        return _BannerData(
          icon: Icons.check_circle,
          backgroundColor: theme.colorScheme.tertiaryContainer,
          textColor: theme.colorScheme.onTertiaryContainer,
          statusText: 'Completed',
        );
      case AppointmentStatus.noShow:
        return _BannerData(
          icon: Icons.event_busy_outlined,
          backgroundColor: theme.colorScheme.errorContainer,
          textColor: theme.colorScheme.onErrorContainer,
          statusText: 'No Show',
        );
    }
  }
}

class _BannerData {
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final String statusText;

  _BannerData({
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.statusText,
  });
}
