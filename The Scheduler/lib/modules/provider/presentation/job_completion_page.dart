import 'package:flutter/material.dart';

import 'provider_today_page.dart';

class JobCompletionPage extends StatefulWidget {
  const JobCompletionPage({super.key, required this.appointment});

  final SampleAppointment appointment;

  @override
  State<JobCompletionPage> createState() => _JobCompletionPageState();
}

class _JobCompletionPageState extends State<JobCompletionPage> {
  final _notesController = TextEditingController();
  final _checklist = <String, bool>{
    'Task 1': true,
    'Task 2': false,
    'Task 3': false,
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Job'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.appointment.service,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(widget.appointment.clientName),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Checklist'),
                  const SizedBox(height: 8),
                  ..._checklist.keys.map(
                    (item) => CheckboxListTile(
                      title: Text(item),
                      value: _checklist[item],
                      onChanged: (value) {
                        setState(() => _checklist[item] = value ?? false);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Job Notes'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Add completion notes',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Add photos'),
              subtitle: const Text('Before/after photos (coming soon)'),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Job'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
