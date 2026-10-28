import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import 'widgets/booking_form_shell.dart';

/// Entry point for the staff booking experience.
class BookingPage extends ConsumerWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure security context is loaded so downstream widgets can rely on Riverpod state.
    ref.watch(securityContextProvider);

    return const ScrollablePageScaffold(
      title: 'New Booking',
      showAppBar: false,
      addPagePadding: false,
      body: BookingFormShell(),
    );
  }
}
