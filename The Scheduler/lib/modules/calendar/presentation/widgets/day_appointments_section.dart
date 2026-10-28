import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:the_scheduler/core/ui/ui_exports.dart';
import 'package:the_scheduler/core/ui/components/components.dart' hide EmptyStateWidget;
import 'package:the_scheduler/core/utils/color_utils.dart';
import 'package:the_scheduler/core/utils/secure_error_handler.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/location.dart';
import 'package:the_scheduler/data/models/provider.dart' as provider_model;
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/service.dart';

/// Day appointments section with premium card styling
/// Updated by Agent S1 (2025-11-30) - Modern Sophisticated Blue design system
class DayAppointmentsSection extends StatelessWidget {
  const DayAppointmentsSection({
    super.key,
    required this.selectedDay,
    required this.appointmentsAsync,
    required this.securityContext,
    required this.providersAsync,
    required this.services,
    required this.locations,
    required this.onCreateAppointment,
    required this.onAppointmentTap,
  });

  final DateTime? selectedDay;
  final AsyncValue<List<Appointment>> appointmentsAsync;
  final SecurityContext securityContext;
  final AsyncValue<List<provider_model.Provider>> providersAsync;
  final List<Service> services;
  final List<Location> locations;
  final VoidCallback onCreateAppointment;
  final void Function(Appointment appointment, provider_model.Provider provider) onAppointmentTap;

  @override
  Widget build(BuildContext context) {
    if (selectedDay == null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: AppIconSize.xl,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                VSpace.sm,
                Text(
                  'Tap a date to view appointments',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return appointmentsAsync.when(
      loading: () => SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xxxl,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: SkeletonCard(height: 100),
            ),
            childCount: 3,
          ),
        ),
      ),
      error: (error, stackTrace) => const SliverFillRemaining(
        child: Center(
          child: ErrorFeedback(message: SecureErrorHandler.loadingFailed),
        ),
      ),
      data: (allAppointments) {
        final dayAppointments = _eventsForDay(selectedDay!, allAppointments);

        if (dayAppointments.isEmpty) {
          final isTodaySelected = isSameDay(selectedDay!, DateTime.now());
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.event_available_outlined,
                        size: AppIconSize.xl,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    VSpace.lg,
                    Text(
                      'No appointments scheduled',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    VSpace.xs,
                    Text(
                      DateFormat('EEEE, MMMM d').format(selectedDay!),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    VSpace.md,
                    Text(
                      isTodaySelected
                          ? 'Your schedule is clear for today. Tap + to book an appointment.'
                          : 'This day is free. Great time to schedule something!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    VSpace.lg,
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onCreateAppointment,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Appointment'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        dayAppointments.sort((a, b) => a.startTime.compareTo(b.startTime));

        return providersAsync.when(
          loading: () => SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xxxl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: SkeletonCard(height: 100),
                ),
                childCount: 3,
              ),
            ),
          ),
          error: (error, stackTrace) => const SliverFillRemaining(
            child: Center(
              child: ErrorFeedback(message: SecureErrorHandler.loadingFailed),
            ),
          ),
          data: (providers) => SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xxxl + AppSpacing.xxxl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final appointment = dayAppointments[index];
                  final provider = providers.firstWhere(
                    (p) => p.id == appointment.providerId,
                    orElse: () {
                      developer.log(
                        'Provider not found for appointment',
                        name: 'CalendarPage',
                        level: 900,
                      );
                      return provider_model.Provider(
                        id: appointment.providerId,
                        businessId: securityContext.businessId,
                        firstName: 'Unknown',
                        lastName: 'Provider',
                        email: '',
                        createdAt: DateTime.now(),
                      );
                    },
                  );

                  return AnimatedListItem(
                    index: index,
                    child: _AppointmentCard(
                      appointment: appointment,
                      provider: provider,
                      services: services,
                      locations: locations,
                      onTap: () => onAppointmentTap(appointment, provider),
                    ),
                  );
                },
                childCount: dayAppointments.length,
              ),
            ),
          ),
        );
      },
    );
  }

  List<Appointment> _eventsForDay(DateTime day, List<Appointment> allAppointments) {
    return allAppointments.where((appointment) => isSameDay(appointment.startTime, day)).toList();
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.provider,
    required this.services,
    required this.locations,
    required this.onTap,
  });

  final Appointment appointment;
  final provider_model.Provider provider;
  final List<Service> services;
  final List<Location> locations;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final providerColor = hexToColor(provider.colorHex);
    final semanticLabel =
        'Appointment with ${provider.fullName} at ${DateFormat.jm().format(appointment.startTime)}';

    final service = services.cast<Service?>().firstWhere(
          (s) => s?.id == appointment.serviceId,
          orElse: () => null,
        );
    final location = locations.cast<Location?>().firstWhere(
          (l) => l?.id == appointment.locationId,
          orElse: () => null,
        );
    final serviceName = service?.name;
    final locationName = location?.name;

    return Semantics(
      label: semanticLabel,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainer
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
                : providerColor.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: providerColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: providerColor.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: providerColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: providerColor,
                      radius: 24,
                      child: Text(
                        provider.initials,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: ThemeData.estimateBrightnessForColor(providerColor) == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DateFormat('h:mm a').format(appointment.startTime)} - '
                          '${DateFormat('h:mm a').format(appointment.endTime)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.fullName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (serviceName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            serviceName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (locationName != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: AppIconSize.xs,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                locationName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (appointment.notes?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 4),
                          Text(
                            appointment.notes!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (appointment.isRecurring) ...[
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Tooltip(
                            message: 'Recurring series',
                            child: Icon(
                              Icons.repeat,
                              color: theme.colorScheme.primary,
                              size: AppIconSize.sm,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _StatusChip(status: appointment.status),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case AppointmentStatus.pending:
        return StatusPill.warning(label: 'Pending');
      case AppointmentStatus.confirmed:
        return StatusPill.success(label: 'Confirmed');
      case AppointmentStatus.cancelled:
        return StatusPill.error(label: 'Cancelled');
      case AppointmentStatus.completed:
        return StatusPill.info(label: 'Completed');
      case AppointmentStatus.noShow:
        return StatusPill.neutral(label: 'No Show');
    }
  }
}
