import 'package:flutter/material.dart';

/// Form for entering gift card recipient details.
class GiftCardRecipientForm extends StatelessWidget {
  const GiftCardRecipientForm({
    required this.recipientNameController,
    required this.recipientEmailController,
    required this.messageController,
    super.key,
  });

  final TextEditingController recipientNameController;
  final TextEditingController recipientEmailController;
  final TextEditingController messageController;

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: recipientNameController,
          decoration: const InputDecoration(
            labelText: 'Recipient Name',
            hintText: 'Enter recipient\'s name',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter recipient\'s name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: recipientEmailController,
          decoration: const InputDecoration(
            labelText: 'Recipient Email',
            hintText: 'recipient@example.com',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter recipient\'s email';
            }
            if (!_isValidEmail(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: messageController,
          decoration: const InputDecoration(
            labelText: 'Personal Message (optional)',
            hintText: 'Add a personal message...',
            prefixIcon: Icon(Icons.message_outlined),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          maxLength: 200,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
