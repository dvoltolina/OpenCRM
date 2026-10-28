import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/auth_state_service.dart';
import '../../../core/services/automation_service.dart';
import '../../../core/services/file_storage_service.dart';
import '../../../core/services/magic_link_service.dart';
import '../../../core/services/email_service.dart';
import '../../../core/services/sms_service.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/file_attachment.dart';
import '../../../data/models/intake_form.dart' as intake_models;
import '../../../data/models/intake_form_draft.dart';
import '../../../data/models/magic_link_token.dart';
import '../../../data/models/security_context.dart';
import '../../../data/repositories/communication_repository.dart';
import '../../../data/repositories/file_attachment_repository.dart';
import '../../../data/repositories/intake_form_repository.dart';
import 'widgets/intake_field_renderer.dart';
import 'widgets/intake_form_sections.dart';
part 'fill_intake_form_page_helpers.dart';

/// Customer-facing intake form filler with draft auto-save and tokenized access.
class FillIntakeFormPage extends ConsumerStatefulWidget {
  const FillIntakeFormPage({
    super.key,
    required this.templateId,
    required this.businessId,
    this.clientId,
    this.appointmentId,
    this.draftId,
    this.accessToken,
    this.repository,
    this.authStateService,
    this.magicLinkService,
    this.fileStorageService,
    this.fileAttachmentRepository,
  });

  final String templateId;
  final String businessId;
  final String? clientId;
  final String? appointmentId;
  final String? draftId;
  final String? accessToken;
  final IntakeFormRepository? repository;
  final AuthStateService? authStateService;
  final MagicLinkService? magicLinkService;
  final FileStorageService? fileStorageService;
  final FileAttachmentRepository? fileAttachmentRepository;

  @override
  ConsumerState<FillIntakeFormPage> createState() => _FillIntakeFormPageState();
}

class _FillIntakeFormPageState extends ConsumerState<FillIntakeFormPage> {
  static const _uuid = Uuid();
  static const _autoSaveInterval = Duration(seconds: 30);
  static const _draftTtl = Duration(days: 7);

  /// Wrapper for setState to allow access from extensions in part files.
  void _updateState(VoidCallback fn) => setState(fn);

  late final IntakeFormRepository _repository;
  late final AuthStateService _authService;
  late final MagicLinkService _magicLinkService;
  late final FileStorageService _fileStorageService;
  late final PageController _pageController;
  FileAttachmentRepository? _fileAttachmentRepository;
  AutomationService? _automationService;

  intake_models.IntakeFormTemplate? _template;
  IntakeFormDraft? _draft;
  MagicLinkToken? _token;
  SecurityContext? _securityContext;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _responses = {};
  final Map<String, String> _validationErrors = {};
  final Map<String, List<FileAttachment>> _fieldAttachments = {};
  List<FileAttachment> _attachments = [];

  bool _loading = true;
  bool _savingDraft = false;
  bool _submitting = false;
  String? _error;
  String? _draftSaveError;
  int _currentPage = 0;
  bool _hasPendingChanges = false;
  bool _pendingSave = false;
  Timer? _autoSaveTimer;
  DateTime? _lastSavedAt;
  intake_models.IntakeFormSubmission? _submission;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ref.read(intakeFormRepositoryProvider);
    _authService = widget.authStateService ?? ref.read(authStateServiceProvider);
    _magicLinkService = widget.magicLinkService ?? ref.read(magicLinkServiceProvider);
    _fileStorageService = widget.fileStorageService ?? ref.read(fileStorageServiceProvider);
    _pageController = PageController(initialPage: _currentPage);
    _fileAttachmentRepository =
        widget.fileAttachmentRepository ?? ref.read(fileAttachmentRepositoryProvider);
    _initialize();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  Map<String, TextEditingController> _buildControllersFromResponses(
    Map<String, dynamic> existing,
  ) {
    final controllers = <String, TextEditingController>{};
    existing.forEach((key, value) {
      if (value is String) {
        controllers[key] = TextEditingController(text: value);
      }
    });
    return controllers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Intake Form'),
        actions: [
          if (_template != null)
            TextButton.icon(
              onPressed:
                  _savingDraft ? null : () => _autoSaveDraft(force: true),
              icon: _savingDraft
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_savingDraft ? 'Saving' : 'Save'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            VSpace.sm,
            FilledButton(
              onPressed: _initialize,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_submission != null) {
      return SubmissionConfirmation(submissionId: _submission!.id);
    }
    final pages = _fieldPages();
    final progress =
        pages.isEmpty ? 1.0 : (_currentPage + 1) / pages.length;
    final clientId = widget.clientId ?? _securityContext?.clientId ?? '';
    final attachmentsEnabled = clientId.isNotEmpty;

    return Column(
      children: [
        IntakeProgressHeader(
          progress: progress,
          currentPage: _currentPage,
          totalPages: pages.length,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _template!.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_template!.description != null) ...[
                const SizedBox(height: 4),
                Text(_template!.description!),
              ],
            ],
          ),
        ),
        DraftStatusBanner(
          savingDraft: _savingDraft,
          lastSavedAt: _lastSavedAt,
          draft: _draft,
          error: _draftSaveError,
        ),
        if (_draft?.daysUntilExpiration != null &&
            _draft!.daysUntilExpiration <= 1)
          const ExpiryWarning(),
        Expanded(
          child: PageView.builder(
            itemCount: pages.length,
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final fields = pages[index];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final field in fields) ...[
                    IntakeFieldRenderer(
                      field: field,
                      errorText: _validationErrors[field.id],
                      responses: _responses,
                      controllers: _controllers,
                      onChanged: (value) => _onFieldChanged(field.id, value),
                      onFileChanged: (files) =>
                          _onFieldAttachmentsChanged(field.id, files),
                      securityContext: _securityContext!,
                      templateId: _template!.id,
                      clientId: clientId,
                      appointmentId: widget.appointmentId,
                      storageService: _fileStorageService,
                      attachmentRepository: _fileAttachmentRepository,
                      attachments:
                          _fieldAttachments[field.id] ?? const <FileAttachment>[],
                      attachmentsEnabled: attachmentsEnabled,
                    ),
                    VSpace.sm,
                  ],
                ],
              );
            },
          ),
        ),
        if (_securityContext != null)
          AttachmentSection(
            securityContext: _securityContext!,
            clientId: clientId,
            templateId: _template!.id,
            appointmentId: widget.appointmentId,
            attachments: _attachments,
            storageService: _fileStorageService,
            attachmentRepository: _fileAttachmentRepository,
            enabled: attachmentsEnabled,
            onChanged: (files) {
              setState(() {
                _attachments = files;
                _hasPendingChanges = true;
              });
              _autoSaveDraft();
            },
          ),
        FormActionBar(
          onBack: () => _changePage(-1),
          onNext: _handleNext,
          isLastPage: _currentPage >= pages.length - 1,
          canGoBack: _currentPage > 0,
          submitting: _submitting,
        ),
      ],
    );
  }

  List<List<intake_models.FormField>> _fieldPages({int pageSize = 4}) {
    final fields = _template?.fields ?? [];
    final pages = <List<intake_models.FormField>>[];
    for (var i = 0; i < fields.length; i += pageSize) {
      pages.add(fields.sublist(
        i,
        i + pageSize > fields.length ? fields.length : i + pageSize,
      ));
    }
    return pages.isEmpty ? [fields] : pages;
  }
}
