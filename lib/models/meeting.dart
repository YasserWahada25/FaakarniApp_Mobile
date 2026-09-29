/// Models of the Alzheimer "Reports" page and of the virtual meeting room.
class MeetingTranscription {
  const MeetingTranscription({
    required this.id,
    required this.filename,
    required this.createdAt,
    required this.language,
    required this.text,
  });

  final String id;
  final String filename;
  final DateTime createdAt;
  final String language;
  final String text;
}

class MeetingReport {
  const MeetingReport({
    required this.id,
    required this.meetingTitle,
    required this.createdAt,
    required this.summary,
    required this.sentimentLabel,
    required this.sentimentScore,
    required this.keyPoints,
    required this.actionItems,
  });

  final String id;
  final String meetingTitle;
  final DateTime createdAt;
  final String summary;
  final String sentimentLabel;
  final double sentimentScore;
  final List<String> keyPoints;
  final List<String> actionItems;
}

enum PreferenceKind { toggle, select }

/// A row of the "Notifications & Reminders" settings.
class NotificationPreference {
  const NotificationPreference({
    required this.id,
    required this.label,
    required this.kind,
    required this.enabled,
    this.frequency,
  });

  final String id;
  final String label;
  final PreferenceKind kind;
  final bool enabled;
  final String? frequency;

  NotificationPreference copyWith({bool? enabled, String? frequency}) => NotificationPreference(
        id: id,
        label: label,
        kind: kind,
        enabled: enabled ?? this.enabled,
        frequency: frequency ?? this.frequency,
      );
}

class MeetingChatMessage {
  const MeetingChatMessage({
    required this.sender,
    required this.text,
    required this.time,
    required this.isSelf,
  });

  final String sender;
  final String text;
  final DateTime time;
  final bool isSelf;
}

enum ParticipantRole {
  host('Animateur'),
  doctor('Médecin'),
  patient('Patient'),
  caregiver('Aidant');

  const ParticipantRole(this.label);
  final String label;
}

class MeetingParticipant {
  const MeetingParticipant({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.isOnline,
    this.isMuted = false,
    this.isVideoOff = false,
  });

  final String userId;
  final String displayName;
  final ParticipantRole role;
  final bool isOnline;
  final bool isMuted;
  final bool isVideoOff;
}

enum AgendaState { completed, active, upcoming }

class AgendaItem {
  const AgendaItem(this.title, this.minutes, this.state);

  final String title;
  final int minutes;
  final AgendaState state;
}
