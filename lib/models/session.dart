/// Alzheimer care sessions (web `alzheimer.service.ts` `Session`).
enum SessionType {
  therapy('Therapy'),
  cognitive('Cognitive'),
  physical('Physical'),
  creative('Creative'),
  general('General');

  const SessionType(this.label);
  final String label;
}

enum SessionMode {
  online('En ligne'),
  inPerson('Presentielle');

  const SessionMode(this.label);
  final String label;
}

/// Backend statuses. A "reservation" is a session request in [draft] until
/// the doctor accepts ([scheduled]) or refuses ([cancelled]) it.
enum SessionStatus {
  draft('En attente'),
  scheduled('Acceptée'),
  cancelled('Refusée'),
  done('Terminée');

  const SessionStatus(this.label);
  final String label;

  bool get isPlanned => this == SessionStatus.scheduled || this == SessionStatus.done;
}

enum SessionVisibility {
  public('Publique'),
  private('Privee');

  const SessionVisibility(this.label);
  final String label;
}

/// `sessionType` on the web: PRIVATE (patient + doctor) or GROUP.
enum SessionAudience {
  private('Privée'),
  group('Groupe');

  const SessionAudience(this.label);
  final String label;
}

class Session {
  const Session({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.type,
    required this.mode,
    required this.status,
    this.description = '',
    this.visibility = SessionVisibility.private,
    this.audience = SessionAudience.private,
    this.participants = 0,
    this.isFavorite = false,
    this.meetingUrl,
    this.locationAddress,
  });

  final int id;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final SessionType type;
  final SessionMode mode;
  final SessionStatus status;
  final SessionVisibility visibility;
  final SessionAudience audience;
  final int participants;
  final bool isFavorite;
  final String? meetingUrl;
  final String? locationAddress;

  bool get isOnline => mode == SessionMode.online;

  Session copyWith({bool? isFavorite, SessionStatus? status}) => Session(
        id: id,
        title: title,
        description: description,
        start: start,
        end: end,
        type: type,
        mode: mode,
        status: status ?? this.status,
        visibility: visibility,
        audience: audience,
        participants: participants,
        isFavorite: isFavorite ?? this.isFavorite,
        meetingUrl: meetingUrl,
        locationAddress: locationAddress,
      );
}

/// Data submitted by the reservation form.
class ReservationRequest {
  const ReservationRequest({
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    required this.mode,
    required this.audience,
    this.locationAddress,
    this.latitude,
    this.longitude,
  });

  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final SessionMode mode;
  final SessionAudience audience;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
}
