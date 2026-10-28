import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/user_messages.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../data/models/resource.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/resources_repository.dart';

/// Dialog for creating a new resource.
class NewResourceDialog extends StatefulWidget {
  final String locationId;
  final SecurityContext securityContext;
  final ResourcesRepository resourcesRepository;

  const NewResourceDialog({
    super.key,
    required this.locationId,
    required this.securityContext,
    required this.resourcesRepository,
  });

  @override
  State<NewResourceDialog> createState() => _NewResourceDialogState();
}

class _NewResourceDialogState extends State<NewResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController(text: '1');
  final _maintenanceController = TextEditingController();

  ResourceType _selectedType = ResourceType.room;
  bool _isActive = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _maintenanceController.dispose();
    super.dispose();
  }

  List<String> _parseMaintenance() {
    return _maintenanceController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final resource = Resource(
        id: const Uuid().v4(),
        businessId: widget.securityContext.businessId,
        name: _nameController.text.trim(),
        type: _selectedType,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        locationId: widget.locationId,
        capacity: int.parse(_capacityController.text),
        maintenanceSchedule: _parseMaintenance(),
        isActive: _isActive,
        createdAt: DateTime.now(),
      );

      await widget.resourcesRepository.upsertResource(
        context: widget.securityContext,
        resource: resource,
      );

      if (mounted) {
        Navigator.pop(context, resource);
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
      title: const Text('Add New Resource'),
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
                  labelText: 'Resource Name *',
                  prefixIcon: Icon(Icons.inventory_2),
                  hintText: 'e.g., Exam Room 1, X-Ray Machine',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              VSpace.md,

              // Type
              DropdownButtonFormField<ResourceType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: ResourceType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              VSpace.md,

              // Capacity
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity *',
                  prefixIcon: Icon(Icons.groups),
                  hintText: 'Number of people',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Capacity is required';
                  }
                  final capacity = int.tryParse(value);
                  if (capacity == null || capacity < 1) {
                    return 'Capacity must be at least 1';
                  }
                  return null;
                },
              ),
              VSpace.md,

              SwitchListTile.adaptive(
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('Resource active'),
                subtitle: const Text('Disable when the room/equipment is down for maintenance'),
              ),
              VSpace.xs,

              TextFormField(
                controller: _maintenanceController,
                decoration: const InputDecoration(
                  labelText: 'Maintenance Schedule',
                  prefixIcon: Icon(Icons.build),
                  hintText: 'e.g., Fridays 5pm - deep clean',
                ),
                maxLines: 2,
              ),
              VSpace.md,

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
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
              : const Text('Add Resource'),
        ),
      ],
    );
  }
}
