import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/file_storage_service.dart';
import '../../../../data/models/file_attachment.dart';
import '../../../../data/models/intake_form_draft.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/file_attachment_repository.dart';
import 'intake_attachment_picker.dart';

class IntakeProgressHeader extends StatelessWidget {
  const IntakeProgressHeader({
    super.key,
    required this.progress,
    required this.currentPage,
    required this.totalPages,
  });

  final double progress;
  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final displayTotal = totalPages == 0 ? 1 : totalPages;
    final displayCurrent =
        totalPages == 0 ? 1 : (currentPage + 1).clamp(1, displayTotal);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: LinearProgressIndicator(value: progress)),
          const SizedBox(width: 12),
          Text('Page $displayCurrent of $displayTotal'),
        ],
      ),
    );
  }
}

class DraftStatusBanner extends StatelessWidget {
  const DraftStatusBanner({
    super.key,
    required this.savingDraft,
    required this.lastSavedAt,
    required this.draft,
    this.error,
  });

  final bool savingDraft;
  final DateTime? lastSavedAt;
  final IntakeFormDraft? draft;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (draft == null && lastSavedAt == null && !savingDraft) {
      return const SizedBox.shrink();
    }
    final textTheme = Theme.of(context).textTheme;
    final lines = <Widget>[];

    if (savingDraft) {
      lines.add(Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text('Saving draft...', style: textTheme.bodySmall),
        ],
      ));
    } else if (lastSavedAt != null) {
      lines.add(
        Text(
          'Saved ${DateFormat.jm().format(lastSavedAt!.toLocal())}',
          style: textTheme.bodySmall,
        ),
      );
    }

    if (draft != null) {
      lines.add(
        Text(
          'Draft expires ${DateFormat('yMMMd h:mm a').format(draft!.expiresAt.toLocal())}',
          style: textTheme.bodySmall,
        ),
      );
    }

    if (error != null) {
      lines.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            error!,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines,
      ),
    );
  }
}

class ExpiryWarning extends StatelessWidget {
  const ExpiryWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This draft expires soon. Submit within 24 hours to avoid losing your progress.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AttachmentSection extends StatelessWidget {
  const AttachmentSection({
    super.key,
    required this.securityContext,
    required this.clientId,
    required this.templateId,
    required this.attachments,
    required this.storageService,
    required this.enabled,
    required this.onChanged,
    this.appointmentId,
    this.attachmentRepository,
  });

  final SecurityContext securityContext;
  final String clientId;
  final String templateId;
  final List<FileAttachment> attachments;
  final FileStorageService storageService;
  final bool enabled;
  final ValueChanged<List<FileAttachment>> onChanged;
  final String? appointmentId;
  final FileAttachmentRepository? attachmentRepository;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          IntakeAttachmentPicker(
            label: 'Additional attachments',
            securityContext: securityContext,
            clientId: clientId,
            templateId: templateId,
            appointmentId: appointmentId,
            attachments: attachments,
            storageService: storageService,
            attachmentRepository: attachmentRepository,
            enabled: enabled,
            onChanged: onChanged,
          ),
          if (!enabled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Sign in or provide your client link to upload documents.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class FormActionBar extends StatelessWidget {
  const FormActionBar({
    super.key,
    required this.onBack,
    required this.onNext,
    required this.isLastPage,
    required this.canGoBack,
    required this.submitting,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool isLastPage;
  final bool canGoBack;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: canGoBack ? onBack : null,
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: submitting ? null : onNext,
            child: Text(isLastPage ? 'Submit' : 'Next'),
          ),
        ],
      ),
    );
  }
}

class SubmissionConfirmation extends StatelessWidget {
  const SubmissionConfirmation({super.key, required this.submissionId});

  final String submissionId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Form submitted!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thank you for completing your intake. '
              'We\'ve saved your responses securely.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SelectableText(
              'Submission ID: $submissionId',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
