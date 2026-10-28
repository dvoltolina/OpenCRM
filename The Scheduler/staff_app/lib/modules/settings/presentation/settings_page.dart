import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/profile_section.dart';
import 'widgets/sync_section.dart';
import 'widgets/about_section.dart';

/// Settings page for the staff app.
///
/// Displays account info, sync settings, and app information.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account section
            ProfileSection(),

            // Sync section
            SyncSection(),

            // About section
            AboutSection(),

            // Bottom padding
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
