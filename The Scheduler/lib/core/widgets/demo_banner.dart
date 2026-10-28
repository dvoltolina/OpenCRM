import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/demo_config.dart';

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!DemoConfig.isDemoMode) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final canLaunchSignup = DemoConfig.demoSignUpUrl.isNotEmpty;

    return Material(
      color: const Color(0xFFB45309),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.visibility_outlined, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DemoConfig.demoBannerText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canLaunchSignup)
                TextButton(
                  onPressed: _openSignUp,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sign Up'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSignUp() async {
    final uri = Uri.tryParse(DemoConfig.demoSignUpUrl);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
