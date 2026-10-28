import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import 'widgets/client_portal_experience.dart';

class ClientPortalPage extends ConsumerWidget {
  const ClientPortalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure the AppConfig override is available before building the portal.
    ref.watch(appConfigProvider);
    return const ClientPortalExperience();
  }
}
