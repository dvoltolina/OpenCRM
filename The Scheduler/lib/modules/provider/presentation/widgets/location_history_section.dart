import 'package:flutter/material.dart';

class LocationHistorySection extends StatefulWidget {
  const LocationHistorySection({super.key});

  @override
  State<LocationHistorySection> createState() => _LocationHistorySectionState();
}

class _LocationHistorySectionState extends State<LocationHistorySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visits = _sampleVisits;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.place),
            title: const Text('Previous visits to this address'),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(12),
              child: visits.isEmpty
                  ? const Text('No history at this location.')
                  : Column(
                      children: visits
                          .map(
                            (visit) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      visit.dateLabel,
                                      style:
                                          Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(visit.service),
                                  ],
                                ),
                                Text('By ${visit.providerName}'),
                                const SizedBox(height: 4),
                                Text(
                                  visit.notes,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (visit.photos > 0)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.photo_camera, size: 16),
                                        const SizedBox(width: 4),
                                        Text('${visit.photos} photos'),
                                      ],
                                    ),
                                  ),
                                const Divider(),
                              ],
                            ),
                          )
                          .toList(),
                    ),
            ),
        ],
      ),
    );
  }
}

class _Visit {
  const _Visit({
    required this.dateLabel,
    required this.service,
    required this.providerName,
    required this.notes,
    this.photos = 0,
  });

  final String dateLabel;
  final String service;
  final String providerName;
  final String notes;
  final int photos;
}

const _sampleVisits = [
  _Visit(
    dateLabel: 'Nov 15, 2025',
    service: 'Home Clean - Full',
    providerName: 'Sarah M.',
    notes:
        'Used hypoallergenic products. Client requested extra attention to kitchen floor.',
    photos: 2,
  ),
  _Visit(
    dateLabel: 'Oct 18, 2025',
    service: 'Standard Clean',
    providerName: 'Mike T.',
    notes: 'Normal clean. Noted scuff marks on hallway wall.',
  ),
];
