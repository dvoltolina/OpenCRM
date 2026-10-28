import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/user_messages.dart';
import '../../../../data/models/intake_form.dart';
import '../../../../data/models/provider.dart';
import '../../../../data/models/resource.dart';
import '../../../../data/models/service.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/services_repository.dart';

/// Dialog for editing an existing service.
class EditServiceDialog extends StatefulWidget {
  final Service service;
  final SecurityContext securityContext;
  final ServicesRepository servicesRepository;
  final List<Provider> providers;
  final List<Resource> resources;
  final List<IntakeFormTemplate> intakeForms;

  const EditServiceDialog({
    super.key,
    required this.service,
    required this.securityContext,
    required this.servicesRepository,
    required this.providers,
    required this.resources,
    required this.intakeForms,
  });

  @override
  State<EditServiceDialog> createState() => _EditServiceDialogState();
}

class _EditServiceDialogState extends State<EditServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;
  late final TextEditingController _bufferController;
  final Set<String> _selectedProviderIds = {};
  final Set<String> _selectedResourceIds = {};
  String? _selectedIntakeFormId;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service.name);
    _descriptionController = TextEditingController(text: widget.service.description ?? '');
    _categoryController = TextEditingController(text: widget.service.category ?? '');
    _durationController = TextEditingController(text: widget.service.durationMinutes.toString());
    _priceController = TextEditingController(text: widget.service.price.toStringAsFixed(2));
    _bufferController = TextEditingController(text: widget.service.bufferMinutes?.toString() ?? '0');
    _selectedProviderIds.addAll(widget.service.providerIds);
    _selectedResourceIds.addAll(widget.service.requiredResources);
    _selectedIntakeFormId = widget.service.intakeFormTemplateId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _bufferController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final updatedService = widget.service.copyWith(
        name: _nameController.text.trim(),
        durationMinutes: int.parse(_durationController.text),
        price: double.parse(_priceController.text),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        providerIds: _selectedProviderIds.toList(),
        requiredResources: _selectedResourceIds.toList(),
        intakeFormTemplateId: _selectedIntakeFormId,
        bufferMinutes: _bufferController.text.trim().isEmpty ? null : int.tryParse(_bufferController.text),
        updatedAt: DateTime.now(),
      );

      await widget.servicesRepository.upsertService(
        context: widget.securityContext,
        service: updatedService,
      );

      if (mounted) {
        Navigator.pop(context, updatedService);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserMessages.saveError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Service'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Service Name *',
                  prefixIcon: Icon(Icons.design_services),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Service name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Category
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  hintText: 'e.g., Therapy, Dental, Massage',
                ),
              ),
              const SizedBox(height: 16),

              // Providers
              Text('Providers', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (widget.providers.isEmpty)
                Text(
                  'No providers added yet.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.providers.map((provider) {
                    final isSelected = _selectedProviderIds.contains(provider.id);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(provider.fullName),
                      onSelected: (_) {
                        setState(() {
                          if (isSelected) {
                            _selectedProviderIds.remove(provider.id);
                          } else {
                            _selectedProviderIds.add(provider.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),

              // Resources
              Text('Required Resources', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (widget.resources.isEmpty)
                Text(
                  'No resources added yet.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.resources.map((resource) {
                    final isSelected = _selectedResourceIds.contains(resource.id);
                    final label = '${resource.name} (${resource.type.displayName})';
                    return FilterChip(
                      selected: isSelected,
                      label: Text(label),
                      onSelected: (_) {
                        setState(() {
                          if (isSelected) {
                            _selectedResourceIds.remove(resource.id);
                          } else {
                            _selectedResourceIds.add(resource.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),

              // Intake form
              DropdownButtonFormField<String>(
                initialValue: _selectedIntakeFormId ?? '',
                decoration: const InputDecoration(
                  labelText: 'Intake Form (optional)',
                  prefixIcon: Icon(Icons.assignment_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('No intake form'),
                  ),
                  ...widget.intakeForms.map(
                    (form) => DropdownMenuItem(
                      value: form.id,
                      child: Text(form.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedIntakeFormId = value?.isEmpty ?? true ? null : value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Duration (minutes)
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes) *',
                  prefixIcon: Icon(Icons.schedule),
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Duration is required';
                  }
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0) {
                    return 'Duration must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price *',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price is required';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price < 0) {
                    return 'Price must be 0 or greater';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Buffer time
              TextFormField(
                controller: _bufferController,
                decoration: const InputDecoration(
                  labelText: 'Buffer Time',
                  prefixIcon: Icon(Icons.timer_outlined),
                  suffixText: 'min',
                  hintText: 'Time between appointments',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
