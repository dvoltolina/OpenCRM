import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/utils/safe_error_handler.dart';
import '../../../data/models/intake_form.dart';
import '../../../data/models/intake_form_draft.dart';
import '../../../data/models/security_context.dart';
import 'widgets/intake_form_submission_card.dart';
import 'widgets/intake_form_draft_card.dart';
import 'widgets/intake_form_submission_viewer.dart';

/// My Intake Forms Page - Customer portal view of intake form submissions and drafts
///
/// Features:
/// - List all submitted intake forms
/// - List draft (incomplete) intake forms
/// - Resume draft forms
/// - View submitted form responses
/// - Update intake information (if allowed by business)
/// - Tab interface for Completed vs Drafts
///
/// Requires authenticated customer with SecurityContext
class MyIntakeFormsPage extends ConsumerStatefulWidget {
  const MyIntakeFormsPage({
    required this.securityContext,
    super.key,
  });

  final SecurityContext securityContext;

  @override
  ConsumerState<MyIntakeFormsPage> createState() => _MyIntakeFormsPageState();
}

class _MyIntakeFormsPageState extends ConsumerState<MyIntakeFormsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Intake Forms'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Completed', icon: Icon(Icons.check_circle_outline)),
            Tab(text: 'Drafts', icon: Icon(Icons.edit_note_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCompletedFormsList(),
          _buildDraftFormsList(),
        ],
      ),
    );
  }

  Widget _buildCompletedFormsList() {
    return StreamBuilder<List<IntakeFormSubmission>>(
      stream: ref.read(intakeFormRepositoryProvider).watchClientSubmissions(
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

        final submissions = snapshot.data!;

        if (submissions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment_outlined,
            title: 'No Completed Forms',
            subtitle: 'Your submitted intake forms will appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Stream will automatically refresh
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final submission = submissions[index];
              return IntakeFormSubmissionCard(
                submission: submission,
                onTap: () => _viewSubmission(submission),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDraftFormsList() {
    return StreamBuilder<List<IntakeFormDraft>>(
      stream: ref.read(intakeFormRepositoryProvider).watchDraftsForClient(
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

        final drafts = snapshot.data!;

        if (drafts.isEmpty) {
          return _buildEmptyState(
            icon: Icons.edit_note_outlined,
            title: 'No Draft Forms',
            subtitle: 'Forms you save as draft will appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Stream will automatically refresh
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return IntakeFormDraftCard(
                draft: draft,
                onResume: () => _resumeDraft(draft),
                onDelete: () => _deleteDraft(draft),
              );
            },
          ),
        );
      },
    );
  }


  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            VSpace.md,
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            VSpace.xs,
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            VSpace.md,
            Text(
              'Failed to Load Forms',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            VSpace.xs,
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _viewSubmission(IntakeFormSubmission submission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => IntakeFormSubmissionViewer(submission: submission),
    );
  }

  void _resumeDraft(IntakeFormDraft draft) async {
    // Navigate to fill intake form page with draft context
    // TODO: Implement navigation with draft loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resume draft feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteDraft(IntakeFormDraft draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Draft?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(intakeFormRepositoryProvider).deleteDraft(
          context: widget.securityContext,
          draftId: draft.id,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Draft deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(SafeErrorHandler.handle(e))),
          );
        }
      }
    }
  }
}
