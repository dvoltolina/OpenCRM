// ignore_for_file: use_build_context_synchronously

part of 'fill_intake_form_page.dart';

extension _FillIntakeFormPageLogic on _FillIntakeFormPageState {
  Future<void> _initialize() async {
    _updateState(() {
      _loading = true;
      _error = null;
      _draftSaveError = null;
    });

    _hasPendingChanges = false;
    _pendingSave = false;
    _lastSavedAt = null;
    _responses.clear();
    _controllers.clear();
    _fieldAttachments.clear();
    _attachments = [];

    try {
      final context = await _resolveSecurityContext();
      if (context == null) {
        _updateState(() {
          _loading = false;
          _error = 'Sign in or use a valid access link to continue.';
        });
        return;
      }
      _securityContext = context;

      final template = await _repository.getTemplate(
        context: context,
        templateId: widget.templateId,
      );
      if (template == null) {
        _updateState(() {
          _loading = false;
          _error = 'Intake form not found.';
        });
        return;
      }
      _template = template;

      IntakeFormDraft? draft;
      if (widget.draftId != null) {
        draft = await _repository.getDraft(
          context: context,
          draftId: widget.draftId!,
        );
      } else if (widget.clientId != null) {
        draft = await _repository.getActiveDraftForClient(
          context: context,
          clientId: widget.clientId!,
          templateId: template.id,
        );
      }

      if (draft != null && draft.isExpired) {
        await _repository.deleteDraft(
          context: context,
          draftId: draft.id,
        );
        draft = null;
      }

      if (draft != null) {
        _loadDraft(draft);
      }

      _startAutoSave();
      _pageController.jumpToPage(0);
      _currentPage = 0;

      _updateState(() {
        _loading = false;
      });
    } catch (e) {
      _updateState(() {
        _loading = false;
        _error = 'Unable to load intake form. Please try again.';
      });
    }
  }

  Future<SecurityContext?> _resolveSecurityContext() async {
    if (widget.accessToken != null) {
      final token = await _magicLinkService.validateToken(
        tokenString: widget.accessToken!,
        businessId: widget.businessId,
      );
      if (token == null) return null;
      _token = token;
      return SecurityContext(
        userId: token.clientId,
        businessId: token.businessId,
        role: UserRole.client,
        clientId: token.clientId,
      );
    }
    return _authService.getCurrentSecurityContext();
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(
      _FillIntakeFormPageState._autoSaveInterval,
      (_) => _autoSaveDraft(),
    );
  }

  Future<void> _autoSaveDraft({bool force = false}) async {
    if (_securityContext == null || _template == null) return;
    if (_savingDraft) {
      _pendingSave = true;
      return;
    }
    if (!_hasPendingChanges && !force) return;

    _updateState(() {
      _savingDraft = true;
      _draftSaveError = null;
    });

    try {
      final now = DateTime.now();
      final createdAt = _draft?.createdAt ?? now;
      final expiresAt =
          createdAt.add(_FillIntakeFormPageState._draftTtl);
      final allAttachments = <FileAttachment>[
        ..._attachments,
        for (final files in _fieldAttachments.values) ...files,
      ];
      final responses = Map<String, dynamic>.from(_responses);
      final fieldJson = _fieldAttachments.map(
        (key, value) => MapEntry(
          key,
          value.map((file) => file.toJson()).toList(),
        ),
      );
      if (fieldJson.isNotEmpty) {
        responses['_fieldAttachments'] = fieldJson;
      }

      final draft = IntakeFormDraft(
        id: _draft?.id ?? _FillIntakeFormPageState._uuid.v4(),
        businessId: _securityContext!.businessId,
        templateId: _template!.id,
        templateName: _template!.name,
        clientId: widget.clientId ?? _securityContext!.clientId ?? '',
        appointmentId: widget.appointmentId,
        responses: responses,
        attachments: allAttachments,
        createdAt: createdAt,
        updatedAt: now,
        expiresAt: expiresAt,
        status: 'draft',
      );
      await _repository.saveDraft(context: _securityContext!, draft: draft);
      _updateState(() {
        _draft = draft;
        _lastSavedAt = now;
        _hasPendingChanges = false;
      });
    } catch (e) {
      _updateState(() {
        _draftSaveError =
            'Auto-save failed. Please check your connection and retry.';
      });
    } finally {
      _updateState(() => _savingDraft = false);
      if (_pendingSave) {
        _pendingSave = false;
        await _autoSaveDraft(force: true);
      }
    }
  }

  void _loadDraft(IntakeFormDraft draft) {
    _draft = draft;
    _responses.addAll(draft.responses);
    _responses.remove('_fieldAttachments');
    _responses.remove('_attachments');
    _controllers.addAll(_buildControllersFromResponses(draft.responses));

    final fieldFiles = _extractFieldAttachments(draft);
    _fieldAttachments.addAll(fieldFiles);
    _attachments = _extractGeneralAttachments(draft.attachments, fieldFiles);
    _lastSavedAt = draft.updatedAt;
  }

  Map<String, List<FileAttachment>> _extractFieldAttachments(
    IntakeFormDraft draft,
  ) {
    final fieldFiles = <String, List<FileAttachment>>{};
    final raw = draft.responses['_fieldAttachments'];

    if (raw is Map) {
      raw.forEach((key, value) {
        final list = (value as List?) ?? [];
        final attachments = list
            .whereType<Map>()
            .map(
              (data) => FileAttachment.fromJson({
                'businessId': draft.businessId,
                ...data.cast<String, dynamic>(),
              }),
            )
            .toList();
        if (attachments.isNotEmpty) {
          fieldFiles[key.toString()] = attachments;
        }
      });
    }

    for (final attachment in draft.attachments) {
      final fieldId = attachment.metadata['fieldId'] as String?;
      if (fieldId != null && fieldId.isNotEmpty) {
        fieldFiles.putIfAbsent(fieldId, () => []).add(attachment);
      }
    }

    return fieldFiles;
  }

  List<FileAttachment> _extractGeneralAttachments(
    List<FileAttachment> attachments,
    Map<String, List<FileAttachment>> fieldAttachments,
  ) {
    if (fieldAttachments.isEmpty) return List<FileAttachment>.from(attachments);
    final fieldIds = fieldAttachments.keys.toSet();
    return attachments
        .where((file) {
          final fieldId = file.metadata['fieldId'] as String?;
          return fieldId == null || fieldId.isEmpty || !fieldIds.contains(fieldId);
        })
        .toList();
  }

  void _onFieldChanged(String fieldId, dynamic value) {
    _updateState(() {
      _responses[fieldId] = value;
      _hasPendingChanges = true;
      _validationErrors.remove(fieldId);
    });
  }

  void _onFieldAttachmentsChanged(
    String fieldId,
    List<FileAttachment> files,
  ) {
    _updateState(() {
      _fieldAttachments[fieldId] = files;
      _responses[fieldId] = files.map((file) => file.toJson()).toList();
      _hasPendingChanges = true;
      _validationErrors.remove(fieldId);
    });
    _autoSaveDraft();
  }

  void _changePage(int delta) {
    final target = (_currentPage + delta).clamp(0, _fieldPages().length - 1);
    _updateState(() => _currentPage = target);
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleNext() async {
    final pages = _fieldPages();
    final currentFields =
        pages.isEmpty ? <intake_models.FormField>[] : pages[_currentPage];
    final pageValid = _validateFields(currentFields);
    if (!pageValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields.')),
      );
      return;
    }

    final isLastPage = _currentPage >= pages.length - 1;
    if (!isLastPage) {
      _changePage(1);
      return;
    }

    final allValid =
        _validateFields(_template?.fields ?? [], validateAll: true);
    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    await _submit();
  }

  bool _validateFields(
    List<intake_models.FormField> fields, {
    bool validateAll = false,
  }) {
    final targets = validateAll ? (_template?.fields ?? []) : fields;
    final errors = Map<String, String>.from(_validationErrors);
    for (final field in targets) {
      final error = IntakeFieldValidator.validate(
        field: field,
        responses: _responses,
        fieldAttachments: _fieldAttachments,
      );
      if (error != null) {
        errors[field.id] = error;
      } else {
        errors.remove(field.id);
      }
    }
    _updateState(() {
      _validationErrors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  Future<void> _submit() async {
    if (_securityContext == null || _template == null) return;
    _updateState(() => _submitting = true);
    try {
      final allAttachments = <FileAttachment>[
        ..._attachments,
        for (final files in _fieldAttachments.values) ...files,
      ];

      final responses = {
        ..._responses,
        if (_fieldAttachments.isNotEmpty)
          '_fieldAttachments': _fieldAttachments.map(
            (key, value) => MapEntry(
              key,
              value.map((file) => file.toJson()).toList(),
            ),
          ),
        if (_attachments.isNotEmpty)
          '_attachments': _attachments.map((file) => file.toJson()).toList(),
        if (widget.appointmentId != null)
          '_appointmentId': widget.appointmentId,
      };

      final submission = intake_models.IntakeFormSubmission(
        id: _FillIntakeFormPageState._uuid.v4(),
        businessId: _securityContext!.businessId,
        clientId: widget.clientId ?? _securityContext!.clientId ?? '',
        templateId: _template!.id,
        templateName: _template!.name,
        templateVersion: _template!.version,
        responses: responses,
        submittedAt: DateTime.now(),
        submittedBy: _securityContext!.userId,
      );

      await _repository.submitForm(
        context: _securityContext!,
        submission: submission,
      );

      for (final attachment in allAttachments) {
        final updated = attachment.copyWith(
          intakeFormId: _template!.id,
          intakeSubmissionId: submission.id,
          appointmentId: attachment.appointmentId ?? widget.appointmentId,
        );
        await _fileAttachmentRepository?.saveAttachment(
          context: _securityContext!,
          attachment: updated,
        );
      }

      if (_draft != null) {
        await _repository.deleteDraft(
          context: _securityContext!,
          draftId: _draft!.id,
        );
      }

      _updateState(() {
        _submitting = false;
        _submission = submission;
        _draft = null;
        _hasPendingChanges = false;
      });

      _autoSaveTimer?.cancel();
      if (context.mounted) {
        unawaited(_sendIntakeConfirmation(submission));
      }
    } catch (e) {
      if (!context.mounted) return;
      _updateState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submission failed. Please try again.'),
        ),
      );
    }
  }

  Future<void> _sendIntakeConfirmation(
    intake_models.IntakeFormSubmission submission,
  ) async {
    final email = _token?.clientEmail ?? _extractEmailFromResponses();
    if (email == null || email.isEmpty) return;

    final clientName = _extractClientName() ?? 'there';
    final config = ref.read(appConfigProvider);
    _automationService ??= _createAutomationService(config);

    await _automationService!.emailService.sendPlainEmail(
      recipientEmail: email,
      recipientName: clientName,
      subject: '${config.branding.productName} intake received',
      body: 'Hi $clientName,\n\n'
          'Thanks for completing ${_template?.name ?? 'your intake form'}. '
          'Your submission ID is ${submission.id}. We will review your details and follow up if needed.\n\n'
          '- ${config.branding.productName}',
    );
  }

  AutomationService _createAutomationService(AppConfig config) {
    return AutomationService(
      emailService: MockEmailService(),
      smsService: MockSmsService(),
      communicationRepository: InMemoryCommunicationRepository(
        config.communicationConfig,
      ),
      communicationConfig: config.communicationConfig,
      automationFunctionUrl: config.communicationConfig.sendAutomationMessageUrl,
    );
  }

  String? _extractEmailFromResponses() {
    for (final field in _template?.fields ?? []) {
      if (field.type == intake_models.FormFieldType.email) {
        final value = _responses[field.id];
        if (value is String && value.isNotEmpty) return value;
      }
    }
    return null;
  }

  String? _extractClientName() {
    final nameFieldIds = ['full_name', 'name'];
    for (final id in nameFieldIds) {
      final value = _responses[id];
      if (value is String && value.isNotEmpty) return value;
    }
    for (final field in _template?.fields ?? []) {
      if (field.label.toLowerCase().contains('name')) {
        final value = _responses[field.id];
        if (value is String && value.isNotEmpty) return value;
      }
    }
    return _securityContext?.userFullName;
  }
}
