import 'package:flutter/material.dart';

import '../../provider_mode/presentation/provider_mode_page.dart';

/// Legacy compatibility wrapper for the old provider shell.
///
/// Provider/staff users now route directly into Provider Mode. Keep this wrapper
/// fail-closed to the maintained runtime so stale imports do not reopen the
/// sample-data provider shell.
@Deprecated('Use ProviderModePage for the live provider/staff runtime.')
class ProviderHomeShell extends StatelessWidget {
  const ProviderHomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderModePage();
  }
}
