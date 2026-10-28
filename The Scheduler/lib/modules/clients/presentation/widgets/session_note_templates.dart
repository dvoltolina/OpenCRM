import '../../../../data/models/session_note.dart';

/// Simple template metadata powering the note composer quick inserts.
class SessionNoteTemplate {
  const SessionNoteTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.body,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String description;
  final SessionNoteType type;
  final String body;
  final List<String> tags;
}

const defaultSessionNoteTemplates = [
  SessionNoteTemplate(
    id: 'soap',
    title: 'SOAP (Therapy)',
    description: 'Subjective, Objective, Assessment, Plan sections.',
    type: SessionNoteType.soap,
    body: '''
Subjective:
- 

Objective:
- 

Assessment:
- 

Plan:
- 
''',
    tags: ['therapy'],
  ),
  SessionNoteTemplate(
    id: 'progress',
    title: 'Progress Check-In',
    description: 'Track progress, barriers, and next steps.',
    type: SessionNoteType.progressNote,
    body: '''
Presenting Concern:

Interventions Used:

Client Response:

Progress Since Last Session:

Barriers / Risks:

Next Session Focus:
''',
    tags: ['therapy', 'coaching'],
  ),
  SessionNoteTemplate(
    id: 'dental-procedure',
    title: 'Dental Procedure Log',
    description: 'Procedure summary with materials + anesthesia.',
    type: SessionNoteType.procedureLog,
    body: '''
Procedure Performed:

Tooth/Surface:

Anesthesia:

Materials / Lot Numbers:

Findings / Complications:

Post-Op Instructions:
''',
    tags: ['dental'],
  ),
  SessionNoteTemplate(
    id: 'chiro-adjustment',
    title: 'Chiropractic Adjustment',
    description: 'Pre/Post pain scale, adjustments, outcomes.',
    type: SessionNoteType.adjustmentNote,
    body: '''
Subjective Complaints:

Pain Scale (Pre):

Objective Findings:

Adjustments Performed:

Modalities Used:

Pain Scale (Post):

Plan / Home Care:
''',
    tags: ['chiropractic'],
  ),
  SessionNoteTemplate(
    id: 'treatment-plan',
    title: 'Treatment Plan Outline',
    description: 'Goals, interventions, frequency, and duration.',
    type: SessionNoteType.treatmentPlan,
    body: '''
Diagnosis / Primary Concern:

Long-Term Goals:

Short-Term Goals:

Interventions / Modalities:

Session Frequency & Duration:

Measurable Outcomes:

Next Review Date:
''',
    tags: ['therapy', 'dentist', 'chiropractic'],
  ),
];
