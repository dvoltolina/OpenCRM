import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/payment.dart';
import 'widgets/payment_widgets.dart';

/// My Payments page for providers - read-only ledger of payments
/// linked to the provider's appointments.
///
/// HIPAA Compliance:
/// - Audit logging handled by PaymentRepository for phiRead/phiReadList
/// - Provider can only see payments for their own appointments
/// - No edit capability (admin-only in web dashboard)
///
/// Under 600 lines by extracting widgets to payment_widgets.dart helper.
class MyPaymentsPage extends ConsumerStatefulWidget {
  const MyPaymentsPage({super.key});

  @override
  ConsumerState<MyPaymentsPage> createState() => _MyPaymentsPageState();
}

class _MyPaymentsPageState extends ConsumerState<MyPaymentsPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  PaymentStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityContext = ref.watch(currentSecurityContextProvider);

    if (securityContext == null) {
      return const Scaffold(
        body: Center(child: Text('Authentication required')),
      );
    }

    // Filter payments by provider's appointments
    final paymentsAsync = ref.watch(_providerPaymentsProvider(securityContext.businessId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: paymentsAsync.when(
        data: (payments) {
          final filtered = _applyFilters(payments);

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  VSpace.md,
                  Text(
                    'No payments found',
                    style: theme.textTheme.titleMedium,
                  ),
                  VSpace.xs,
                  Text(
                    'Payments will appear here when clients pay for your appointments',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Group by date
          final grouped = _groupByDate(filtered);

          return ListView.builder(
            padding: AppSpacing.cardPadding,
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final entry = grouped.entries.elementAt(index);
              final date = entry.key;
              final datePayments = entry.value;

              return PaymentDateGroupCard(
                date: date,
                payments: datePayments,
                onTap: (payment) => _showPaymentDetail(context, payment),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              VSpace.md,
              Text(
                'Error loading payments',
                style: theme.textTheme.titleMedium,
              ),
              VSpace.xs,
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Payment> _applyFilters(List<Payment> payments) {
    var filtered = payments;

    if (_startDate != null) {
      filtered = filtered.where((p) => !p.createdAt.isBefore(_startDate!)).toList();
    }

    if (_endDate != null) {
      final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      filtered = filtered.where((p) => !p.createdAt.isAfter(endOfDay)).toList();
    }

    if (_statusFilter != null) {
      filtered = filtered.where((p) => p.status == _statusFilter).toList();
    }

    return filtered;
  }

  Map<DateTime, List<Payment>> _groupByDate(List<Payment> payments) {
    final Map<DateTime, List<Payment>> grouped = {};

    for (final payment in payments) {
      final date = DateTime(
        payment.createdAt.year,
        payment.createdAt.month,
        payment.createdAt.day,
      );

      grouped.putIfAbsent(date, () => []).add(payment);
    }

    // Sort by date descending
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Map.fromEntries(sortedEntries);
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PaymentFilterDialog(
        startDate: _startDate,
        endDate: _endDate,
        statusFilter: _statusFilter,
        onApply: (start, end, status) {
          setState(() {
            _startDate = start;
            _endDate = end;
            _statusFilter = status;
          });
        },
      ),
    );
  }

  void _showPaymentDetail(BuildContext context, Payment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PaymentDetailSheet(payment: payment),
    );
  }
}

/// Provider to fetch provider-scoped payments by loading appointments first.
/// Scopes payment list to only appointments where the current user is the provider.
final _providerPaymentsProvider = FutureProvider.family<List<Payment>, String>((ref, businessId) async {
  final securityContext = ref.watch(currentSecurityContextProvider);
  if (securityContext == null) return [];

  final appointmentsRepo = ref.read(appointmentsRepositoryProvider);
  final paymentRepo = ref.read(paymentRepositoryProvider);

  // Fetch provider's appointments in the last 90 days
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 90));
  final appointments = await appointmentsRepo.loadAppointmentsInRange(
    context: securityContext,
    start: start,
    end: now.add(const Duration(days: 30)), // Include upcoming
  );

  // Filter to this provider's appointments only
  final providerAppointments = appointments.where((apt) {
    return apt.providerId == securityContext.providerId;
  }).toList();

  if (providerAppointments.isEmpty) return [];

  // Fetch payments for these appointments (audit logged by repository)
  final appointmentIds = providerAppointments.map((a) => a.id).toList();
  final payments = await paymentRepo.fetchPaymentsForAppointments(
    context: securityContext,
    appointmentIds: appointmentIds,
  );

  return payments;
});
