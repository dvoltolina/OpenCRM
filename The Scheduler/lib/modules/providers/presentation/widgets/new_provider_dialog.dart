import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/user_messages.dart';
import '../../../../data/models/location.dart';
import '../../../../data/models/provider.dart';
import '../../../../data/models/service.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/providers_repository.dart';

/// Dialog for creating a new provider.
class NewProviderDialog extends StatefulWidget {
  final SecurityContext securityContext;
  final ProvidersRepository providersRepository;
  final List<Service> services;
  final List<Location> locations;

  const NewProviderDialog({
    super.key,
    required this.securityContext,
    required this.providersRepository,
    required this.services,
    required this.locations,
  });

  @override
  State<NewProviderDialog> createState() => _NewProviderDialogState();
}

class _NewProviderDialogState extends State<NewProviderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _specializationsController = TextEditingController();
  final _stripeAccountController = TextEditingController();
  final Set<String> _selectedServiceIds = {};
  final Set<String> _selectedLocationIds = {};

  // Predefined colors for providers
  final List<String> _availableColors = [
    '4285F4', // Blue
    'EA4335', // Red
    '34A853', // Green
    'FBBC04', // Yellow
    'FF6D00', // Orange
    '9C27B0', // Purple
    '00ACC1', // Cyan
    '8BC34A', // Light Green
  ];

  String _selectedColor = '4285F4'; // Blue default
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _specializationsController.dispose();
    _stripeAccountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = Provider(
        id: const Uuid().v4(),
        businessId: widget.securityContext.businessId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        stripeAccountId: _stripeAccountController.text.trim().isEmpty
            ? null
            : _stripeAccountController.text.trim(),
        specializations: _specializationsController.text.isEmpty
            ? []
            : _specializationsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        serviceIds: _selectedServiceIds.toList(),
        locationIds: _selectedLocationIds.toList(),
        colorHex: _selectedColor,
        createdAt: DateTime.now(),
      );

      await widget.providersRepository.upsertProvider(
        context: widget.securityContext,
        provider: provider,
      );

      if (mounted) {
        Navigator.pop(context, provider);
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
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add New Provider'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Stripe Account ID (optional)
              TextFormField(
                controller: _stripeAccountController,
                decoration: const InputDecoration(
                  labelText: 'Stripe Account ID (optional)',
                  prefixIcon: Icon(Icons.account_balance),
                  helperText: 'Connect payouts to a provider account (acct_...)',
                ),
              ),
              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Brief description of provider',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Specializations
              TextFormField(
                controller: _specializationsController,
                decoration: const InputDecoration(
                  labelText: 'Specializations',
                  prefixIcon: Icon(Icons.star),
                  hintText: 'Comma-separated (e.g., Therapy, Massage)',
                ),
              ),
              const SizedBox(height: 16),

              // Locations
              Text('Locations', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (widget.locations.isEmpty)
                Text(
                  'No locations yet. Add a location first.',
                  style: theme.textTheme.bodySmall,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.locations.map((location) {
                    final isSelected = _selectedLocationIds.contains(location.id);
                    final label = location.name?.isNotEmpty == true
                        ? location.name!
                        : location.city;
                    return FilterChip(
                      selected: isSelected,
                      label: Text(label),
                      onSelected: (_) {
                        setState(() {
                          if (isSelected) {
                            _selectedLocationIds.remove(location.id);
                          } else {
                            _selectedLocationIds.add(location.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),

              // Services
              Text('Services Offered', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (widget.services.isEmpty)
                Text(
                  'No services yet. Add a service first.',
                  style: theme.textTheme.bodySmall,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.services.map((service) {
                    final isSelected = _selectedServiceIds.contains(service.id);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(service.name),
                      onSelected: (_) {
                        setState(() {
                          if (isSelected) {
                            _selectedServiceIds.remove(service.id);
                          } else {
                            _selectedServiceIds.add(service.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // Color Picker
              Text('Provider Color', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((colorHex) {
                  final color = Color(0xFF000000 | int.parse(colorHex, radix: 16));
                  final isSelected = _selectedColor == colorHex;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = colorHex),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: theme.colorScheme.primary, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
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
              : const Text('Add Provider'),
        ),
      ],
    );
  }
}
