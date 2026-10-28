import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/intake_form.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/intake_form_repository.dart';

typedef ViewSubmissionCallback = void Function(
  IntakeFormSubmission submission,
);

class ClientIntakeFormsTab extends StatelessWidget {
  const ClientIntakeFormsTab({
    super.key,
    required this.intakeFormRepository,
    required this.securityContext,
    required this.clientId,
    required this.onViewSubmission,
  });

  final IntakeFormRepository intakeFormRepository;
  final SecurityContext securityContext;
  final String clientId;
  final ViewSubmissionCallback onViewSubmission;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<IntakeFormSubmission>>(
      stream: intakeFormRepository.watchClientSubmissions(
        context: securityContext,
        clientId: clientId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final submissions = snapshot.data!;

        if (submissions.isEmpty) {
          return _EmptyFormsState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: submissions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final submission = submissions[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.assignment)),
                title: Text(submission.templateName ?? 'Form Submission'),
                subtitle: Text(
                  'Submitted ${DateFormat.yMMMd().format(submission.submittedAt)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onViewSubmission(submission),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyFormsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          const Text('No intake forms submitted'),
        ],
      ),
    );
  }
}


