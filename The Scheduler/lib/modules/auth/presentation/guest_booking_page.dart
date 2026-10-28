import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../data/models/guest_info.dart';
import 'client_register_page.dart';

/// Guest booking page for clients who want to book without creating an account.
/// Collects basic info (name, email, phone) and proceeds to booking.
/// After booking, offers the option to create a full account.
class GuestBookingPage extends ConsumerStatefulWidget {
  const GuestBookingPage({super.key, this.businessId});

  /// The business ID for the booking
  final String? businessId;

  @override
  ConsumerState<GuestBookingPage> createState() => _GuestBookingPageState();
}

class _GuestBookingPageState extends ConsumerState<GuestBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _showBookingFlow = false;
  GuestInfo? _guestInfo;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _proceedToBooking() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guestInfo = GuestInfo(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      _showBookingFlow = true;
    });
  }

  void _onBookingComplete() {
    // Show success dialog with option to create account
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Booking Confirmed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your appointment has been booked. You\'ll receive a confirmation email shortly.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Would you like to create an account to manage your appointments and access additional features?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to login
            },
            child: const Text('No Thanks'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to registration with pre-filled info
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ClientRegisterPage(
                    businessId: widget.businessId,
                    prefillEmail: _guestInfo?.email,
                    prefillFirstName: _guestInfo?.firstName,
                    prefillLastName: _guestInfo?.lastName,
                    prefillPhone: _guestInfo?.phone,
                  ),
                ),
              );
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;

    if (_showBookingFlow) {
      return _GuestBookingFlow(
        businessId: widget.businessId,
        guestInfo: _guestInfo!,
        onBookingComplete: _onBookingComplete,
        onBack: () => setState(() => _showBookingFlow = false),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book as Guest'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: branding.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        size: 48,
                        color: branding.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Quick Booking',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Enter your details to book an appointment',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // First Name
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Last Name
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Continue button
                    FilledButton(
                      onPressed: _proceedToBooking,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Continue to Booking'),
                    ),
                    const SizedBox(height: 16),

                    // Info text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can create a full account after booking to manage your appointments.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The booking flow widget for guests
class _GuestBookingFlow extends ConsumerWidget {
  const _GuestBookingFlow({
    required this.businessId,
    required this.guestInfo,
    required this.onBookingComplete,
    required this.onBack,
  });

  final String? businessId;
  final GuestInfo guestInfo;
  final VoidCallback onBookingComplete;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implement the actual booking flow using PortalBookingStepper
    // This is a placeholder that will be integrated with the existing booking system
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Booking for: ${guestInfo.firstName} ${guestInfo.lastName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              guestInfo.email,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            const Text('Service selection coming soon...'),
            const SizedBox(height: 32),
            // Temporary button to simulate booking completion
            FilledButton(
              onPressed: onBookingComplete,
              child: const Text('Complete Booking (Demo)'),
            ),
          ],
        ),
      ),
    );
  }
}
