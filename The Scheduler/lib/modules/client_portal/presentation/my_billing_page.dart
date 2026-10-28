import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/ui/components/components.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/safe_error_handler.dart';
import '../../../data/models/payment.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/service.dart';
import '../../../data/models/security_context.dart';
import 'widgets/payment_card_widget.dart';
import 'widgets/payment_details_sheet.dart';

/// My Billing Page - Customer portal view of payment history and receipts
///
/// Features:
/// - List all payments chronologically
/// - Show payment status (completed, pending, refunded)
/// - Display payment method and amount
/// - Download receipts (PDF generation placeholder)
/// - View refund status
/// - Filter by date range
/// - Total spent calculation
///
/// Requires authenticated customer with SecurityContext
class MyBillingPage extends ConsumerStatefulWidget {
  const MyBillingPage({
    required this.securityContext,
    super.key,
  });

  final SecurityContext securityContext;

  @override
  ConsumerState<MyBillingPage> createState() => _MyBillingPageState();
}

class _MyBillingPageState extends ConsumerState<MyBillingPage> {

  // Cache for appointments and services
  final Map<String, Appointment> _appointmentsCache = {};
  final Map<String, Service> _servicesCache = {};
  List<Payment> _latestPayments = const [];

  @override
  void initState() {
    super.initState();
    _preloadData();
  }

  Future<void> _preloadData() async {
    // Preload services for faster rendering
    try {
      final servicesRepository = ref.read(servicesRepositoryProvider);
      final services = await servicesRepository.getServices(
        context: widget.securityContext,
      );

      setState(() {
        for (final service in services) {
          _servicesCache[service.id] = service;
        }
      });
    } catch (e) {
      // Continue without cache
    }
  }

  Future<void> _loadAppointment(String appointmentId) async {
    if (_appointmentsCache.containsKey(appointmentId)) return;

    try {
      final appointmentsRepository = ref.read(appointmentsRepositoryProvider);
      final appointment = await appointmentsRepository.getAppointment(
        context: widget.securityContext,
        appointmentId: appointmentId,
      );

      if (appointment != null) {
        setState(() {
          _appointmentsCache[appointmentId] = appointment;
        });
      }
    } catch (e) {
      // Continue without appointment data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: _showAllReceipts,
            tooltip: 'Download All Receipts',
          ),
        ],
      ),
      body: StreamBuilder<List<Payment>>(
        stream: ref.read(paymentRepositoryProvider).watchClientPayments(
          context: widget.securityContext,
          clientId: widget.securityContext.clientId!,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(SafeErrorHandler.handle(snapshot.error!));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final payments = snapshot.data!;
          _latestPayments = payments;

          if (payments.isEmpty) {
            return _buildEmptyState();
          }

          // Calculate total spent
          final totalCents = payments
              .where((p) => p.isCompleted && !p.isRefund)
              .fold<int>(0, (sum, p) => sum + p.netAmountCents);

          return Column(
            children: [
              _buildSummaryCard(totalCents, payments.length),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Stream will automatically refresh
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: AppSpacing.pagePadding,
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      _loadAppointment(payment.appointmentId);

                      final appointment = _appointmentsCache[payment.appointmentId];
                      final service = appointment != null
                          ? _servicesCache[appointment.serviceId]
                          : null;

                      return PaymentCardWidget(
                        payment: payment,
                        appointment: appointment,
                        service: service,
                        onTap: () => _viewPaymentDetails(payment),
                        onDownloadReceipt: () => _downloadReceipt(payment),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(int totalCents, int paymentCount) {
    final theme = Theme.of(context);
    final totalDollars = totalCents / 100.0;

    return AppCard(
      margin: AppSpacing.pagePadding,
      color: theme.colorScheme.primaryContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Spent',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              VSpace.xxs,
              Text(
                '\$${totalDollars.toStringAsFixed(2)}',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Transactions',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              VSpace.xxs,
              Text(
                '$paymentCount',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.receipt_long_outlined,
      title: 'No Payment History',
      subtitle: 'Your payment transactions will appear here',
    );
  }

  Widget _buildErrorState(String error) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: 'Failed to Load Payments',
      subtitle: error,
    );
  }

  void _viewPaymentDetails(Payment payment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => PaymentDetailsSheet(payment: payment),
    );
  }

  Future<void> _downloadReceipt(Payment payment) async {
    final appointment = _appointmentsCache[payment.appointmentId];
    final service =
        appointment != null ? _servicesCache[appointment.serviceId] : null;
    final doc = pw.Document();
    doc.addPage(
      _buildReceiptPage(
        payment: payment,
        appointment: appointment,
        service: service,
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'receipt_${payment.id}.pdf',
    );
  }

  Future<void> _showAllReceipts() async {
    if (_latestPayments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No receipts available to download')),
      );
      return;
    }

    final pdf = pw.Document();
    for (final payment in _latestPayments) {
      final appointment = _appointmentsCache[payment.appointmentId];
      final service =
          appointment != null ? _servicesCache[appointment.serviceId] : null;
      pdf.addPage(
        _buildReceiptPage(
          payment: payment,
          appointment: appointment,
          service: service,
        ),
      );
    }

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'receipts_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  pw.Page _buildReceiptPage({
    required Payment payment,
    Appointment? appointment,
    Service? service,
  }) {
    final createdAt = payment.createdAt.toLocal();
    final amount =
        _formatCurrency(payment.amountCents, payment.currency);
    final refund = payment.refundAmountCents != null
        ? _formatCurrency(payment.refundAmountCents!, payment.currency)
        : null;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Payment Receipt',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  )),
              pw.SizedBox(height: 8),
              pw.Text('Receipt ID: ${payment.id}'),
              pw.Text('Date: ${createdAt.toIso8601String()}'),
              pw.SizedBox(height: 12),
              pw.Text('Business ID: ${payment.businessId}'),
              pw.Text('Client ID: ${payment.clientId}'),
              if (appointment != null)
                pw.Text(
                  'Appointment: ${appointment.id} — ${appointment.startTime.toLocal()}',
                ),
              if (service != null) pw.Text('Service: ${service.name}'),
              pw.SizedBox(height: 16),
              pw.Text('Amount: $amount',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  )),
              pw.Text('Status: ${payment.status.name}'),
              pw.Text('Type: ${payment.type.name}'),
              if (payment.cardBrand != null || payment.cardLast4 != null)
                pw.Text(
                  'Payment Method: ${payment.cardBrand ?? 'Card'} •••• ${payment.cardLast4 ?? ''}',
                ),
              if (payment.paymentMethodDescription != null)
                pw.Text('Method: ${payment.paymentMethodDescription}'),
              if (payment.completedAt != null)
                pw.Text('Completed: ${payment.completedAt!.toLocal()}'),
              if (refund != null) pw.Text('Refund Amount: $refund'),
              if (payment.refundedAt != null)
                pw.Text('Refunded: ${payment.refundedAt!.toLocal()}'),
              if (payment.reason != null) pw.Text('Reason: ${payment.reason}'),
              if (payment.notes != null) pw.Text('Notes: ${payment.notes}'),
            ],
          ),
        );
      },
    );
  }

  String _formatCurrency(int cents, String currency) {
    final amount = cents / 100;
    return '$currency ${amount.toStringAsFixed(2)}';
  }
}
