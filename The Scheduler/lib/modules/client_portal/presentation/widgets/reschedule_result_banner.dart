import 'package:flutter/material.dart';

import '../../../../core/services/appointment_modification_service.dart';

/// Banner displaying the result of a reschedule request
class RescheduleResultBanner extends StatelessWidget {
  const RescheduleResultBanner({
    required this.result,
    super.key,
  });

  final AppointmentModificationResult? result;

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox.shrink();

    final isSuccess = result!.status == AppointmentModificationStatus.success;
    final color = isSuccess
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.secondaryContainer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result!.message ?? '',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (result!.request != null) ...[
            const SizedBox(height: 8),
            const Text(
              'We will notify you once the office reviews this request.',
            ),
          ],
        ],
      ),
    );
  }
}
