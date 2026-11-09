/// Alzheimer care sessions (web `alzheimer.service.ts` `Session`).
enum SessionType {
  therapy('Therapy'),
  cognitive('Cognitive'),
  physical('Physical'),
  creative('Creative'),
  general('General');

  const SessionType(this.label);
  final String label;

  /// The API has no such field: the web infers it from the text
  /// (`AlzheimerService.inferType`).
  static SessionType infer(String title, String description) {
    final text = '$title $description'.toLowerCase();
    bool has(List<String> words) => words.any(text.contains);
    if (has(const ['music', 'thérap', 'therap', 'relaxa'])) return SessionType.therapy;
    if (has(const ['memory', 'mémoire', 'cogni', 'brain', 'puzzle'])) return SessionType.cognitive;
    if (has(const ['yoga', 'gym', 'exerci', 'stretch', 'physi'])) return SessionType.physical;
    if (has(const ['art', 'paint', 'draw', 'créat', 'creat'])) return SessionType.creative;
    return SessionType.general;
  }
}

enum SessionMode {
  online('En ligne', 'ONLINE'),
  inPerson('Presentielle', 'IN_PERSON');

  const SessionMode(this.label, this.backendValue);
  final String label;
  final String backendValue;
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

  /// A request or an accepted session keeps its time slot (reservation form
  /// conflict check).
  bool get holdsTimeSlot => this == SessionStatus.draft || this == SessionStatus.scheduled;

  static SessionStatus fromApi(String? value) => switch ((value ?? '').toUpperCase()) {
        'SCHEDULED' || 'ACCEPTED' || 'PLANNED' => SessionStatus.scheduled,
        'CANCELLED' => SessionStatus.cancelled,
        'DONE' => SessionStatus.done,
        _ => SessionStatus.draft,
      };
}

enum SessionVisibility {
  public('Publique', 'PUBLIC'),
  private('Privee', 'PRIVATE');

  const SessionVisibility(this.label, this.backendValue);
  final String label;
  final String backendValue;
}

/// `sessionType` on the web: PRIVATE (patient + doctor) or GROUP.
enum SessionAudience {
  private('Privée', 'PRIVATE'),
  group('Groupe', 'GROUP');

  const SessionAudience(this.label, this.backendValue);
  final String label;
  final String backendValue;
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
    this.createdBy,
    this.participantIds = const [],
  });

  /// session-service `VirtualSession`. [currentUserId] resolves the favorite
  /// flag, which is stored per participant.
  factory Session.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final title = (json['title'] as String?) ?? '';
    final description = (json['description'] as String?) ?? '';
    final meetingUrl = json['meetingUrl'] as String?;
    final participants = (json['participants'] is List ? json['participants'] as List : const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final start = _date(json['startTime']);
    final mode = switch ('${json['meetingMode'] ?? ''}'.toUpperCase()) {
      'ONLINE' => SessionMode.online,
      'IN_PERSON' => SessionMode.inPerson,
      _ => (meetingUrl ?? '').trim().isNotEmpty ? SessionMode.online : SessionMode.inPerson,
    };
    final visibility = '${json['visibility'] ?? ''}'.toUpperCase() == 'PUBLIC'
        ? SessionVisibility.public
        : SessionVisibility.private;
    return Session(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: title,
      description: description,
      start: start,
      end: json['endTime'] == null ? start : _date(json['endTime']),
      type: SessionType.infer(title, description),
      mode: mode,
      status: SessionStatus.fromApi(json['status'] as String?),
      visibility: visibility,
      audience: switch ('${json['sessionType'] ?? ''}'.toUpperCase()) {
        'GROUP' => SessionAudience.group,
        'PRIVATE' => SessionAudience.private,
        _ => visibility == SessionVisibility.public ? SessionAudience.group : SessionAudience.private,
      },
      participants: participants.length,
      // The entity's `boolean isFavorite` is serialized by Jackson as `favorite`.
      isFavorite: participants.any(
        (p) => p['userId'] == currentUserId && (p['favorite'] == true || p['isFavorite'] == true),
      ),
      meetingUrl: meetingUrl,
      locationAddress: json['locationAddress'] as String?,
      createdBy: json['createdBy'] as String?,
      participantIds: [for (final p in participants) '${p['userId'] ?? ''}'],
    );
  }

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
  final String? createdBy;
  final List<String> participantIds;

  bool get isOnline => mode == SessionMode.online;

  /// Web `AlzheimerService.isVisibleForCurrentUser`.
  bool isVisibleTo(String? userId) {
    if (visibility == SessionVisibility.public) return true;
    if (userId == null || userId.isEmpty) return false;
    return createdBy == userId || participantIds.contains(userId);
  }

  bool overlaps(DateTime from, DateTime to) => from.isBefore(end) && to.isAfter(start);

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
        createdBy: createdBy,
        participantIds: participantIds,
      );

  static DateTime _date(dynamic value) =>
      DateTime.tryParse('${value ?? ''}')?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
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

  SessionVisibility get visibility =>
      audience == SessionAudience.group ? SessionVisibility.public : SessionVisibility.private;

  /// session-service `CreateSessionRequest`. The server sets `createdBy` from
  /// the token and forces the DRAFT status for non-admins.
  Map<String, dynamic> toJson() {
    final inPerson = mode == SessionMode.inPerson;
    final address = locationAddress?.trim() ?? '';
    return {
      'title': title.trim(),
      'description': description.trim(),
      'startTime': start.toUtc().toIso8601String(),
      'endTime': end.toUtc().toIso8601String(),
      'status': 'DRAFT',
      'visibility': visibility.backendValue,
      'sessionType': audience.backendValue,
      'meetingMode': mode.backendValue,
      if (inPerson && address.isNotEmpty) 'locationAddress': address,
      if (inPerson) 'locationLatitude': latitude,
      if (inPerson) 'locationLongitude': longitude,
    };
  }
}
