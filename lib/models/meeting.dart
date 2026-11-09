import 'dart:convert';

/// Models of the Alzheimer "Reports" page and of the virtual meeting room.
class MeetingTranscription {
  const MeetingTranscription({
    required this.id,
    required this.filename,
    required this.createdAt,
    required this.language,
    required this.text,
  });

  /// meeting-insights-service `TranscriptionResponse`.
  factory MeetingTranscription.fromJson(Map<String, dynamic> json) => MeetingTranscription(
        id: '${json['id'] ?? ''}',
        filename: (json['filename'] as String?) ?? '',
        createdAt: _date(json['created_at']),
        language: (json['language'] as String?) ?? 'n/a',
        text: (json['transcription'] as String?) ?? '',
      );

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

  /// meeting-insights-service `GeneratedReport`.
  factory MeetingReport.fromJson(Map<String, dynamic> json) {
    final sentiment = json['sentiment_analysis'];
    final title = (json['meeting_title'] as String?)?.trim() ?? '';
    return MeetingReport(
      id: '${json['id'] ?? ''}',
      meetingTitle: title.isEmpty ? 'Rapport de reunion' : title,
      createdAt: _date(json['created_at']),
      summary: (json['summary'] as String?) ?? '',
      sentimentLabel: (sentiment is Map ? sentiment['label'] as String? : null) ?? '',
      sentimentScore: (sentiment is Map ? sentiment['score'] as num? : null)?.toDouble() ?? 0,
      keyPoints: _strings(json['key_points']),
      actionItems: _strings(json['action_items']),
    );
  }

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
    required this.senderId,
    required this.text,
    required this.time,
    required this.isSelf,
  });

  /// session-service `VideoChatMessageDTO`.
  factory MeetingChatMessage.fromJson(Map<String, dynamic> json, {required String currentUserId}) {
    final sender = '${json['fromUserId'] ?? ''}';
    return MeetingChatMessage(
      senderId: sender,
      text: (json['text'] as String?) ?? '',
      time: _date(json['sentAt']),
      isSelf: sender == currentUserId,
    );
  }

  final String senderId;
  final String text;
  final DateTime time;
  final bool isSelf;
}

/// session-service `ParticipantRole`.
enum ParticipantRole {
  host('Hote'),
  organizer('Organisateur'),
  participant('Participant');

  const ParticipantRole(this.label);
  final String label;

  String get backendValue => name.toUpperCase();

  static ParticipantRole fromApi(String? value) => ParticipantRole.values.firstWhere(
        (r) => r.backendValue == (value ?? '').toUpperCase(),
        orElse: () => ParticipantRole.participant,
      );
}

/// session-service `JoinStatus`.
enum JoinStatus {
  invited('Invite'),
  confirmed('Confirme'),
  attended('Present');

  const JoinStatus(this.label);
  final String label;

  static JoinStatus fromApi(String? value) => JoinStatus.values.firstWhere(
        (s) => s.name.toUpperCase() == (value ?? '').toUpperCase(),
        orElse: () => JoinStatus.invited,
      );
}

class MeetingParticipant {
  const MeetingParticipant({
    required this.userId,
    required this.role,
    required this.joinStatus,
    this.displayName = '',
    this.isOnline = false,
  });

  /// session-service `SessionParticipant`, or the `participant-added` payload.
  factory MeetingParticipant.fromJson(Map<String, dynamic> json) => MeetingParticipant(
        userId: '${json['userId'] ?? ''}',
        role: ParticipantRole.fromApi(json['role'] as String?),
        joinStatus: JoinStatus.fromApi(json['joinStatus'] as String?),
      );

  final String userId;
  final String displayName;
  final ParticipantRole role;
  final JoinStatus joinStatus;
  final bool isOnline;

  MeetingParticipant copyWith({String? displayName, bool? isOnline}) => MeetingParticipant(
        userId: userId,
        role: role,
        joinStatus: joinStatus,
        displayName: displayName ?? this.displayName,
        isOnline: isOnline ?? this.isOnline,
      );
}

/// session-service `VideoSessionDTO`.
class VideoRoom {
  const VideoRoom({required this.id, required this.roomId, required this.hostUserId});

  factory VideoRoom.fromJson(Map<String, dynamic> json) => VideoRoom(
        id: (json['id'] as num?)?.toInt() ?? 0,
        roomId: '${json['roomId'] ?? ''}',
        hostUserId: '${json['hostUserId'] ?? ''}',
      );

  final int id;
  final String roomId;
  final String hostUserId;
}

/// Types of [SignalMessage] (web `SignalMessageDTO`).
abstract final class SignalType {
  static const String offer = 'offer';
  static const String answer = 'answer';
  static const String iceCandidate = 'ice-candidate';
  static const String join = 'join';
  static const String leave = 'leave';
  static const String chat = 'chat';
  static const String participantAdded = 'participant-added';
}

/// Frame exchanged on `/topic/room/{roomId}` (session-service `SignalMessageDTO`).
class SignalMessage {
  const SignalMessage({
    required this.type,
    required this.fromUserId,
    required this.roomId,
    required this.payload,
    this.toUserId,
  });

  factory SignalMessage.fromJson(Map<String, dynamic> json) => SignalMessage(
        type: '${json['type'] ?? ''}',
        fromUserId: '${json['fromUserId'] ?? ''}',
        toUserId: json['toUserId'] as String?,
        roomId: '${json['roomId'] ?? ''}',
        payload: (json['payload'] as String?) ?? '',
      );

  final String type;
  final String fromUserId;
  final String? toUserId;
  final String roomId;

  /// JSON text whose format depends on [type]; the server requires it non-null.
  final String payload;

  Map<String, dynamic> toJson() => {
        'type': type,
        'fromUserId': fromUserId,
        if (toUserId != null) 'toUserId': toUserId,
        'roomId': roomId,
        'payload': payload,
      };

  /// [payload] decoded, or an empty map when it is not a JSON object.
  Map<String, dynamic> get payloadMap {
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}

DateTime _date(dynamic value) => DateTime.tryParse('${value ?? ''}')?.toLocal() ?? DateTime.now();

List<String> _strings(dynamic value) => value is List ? [for (final v in value) '$v'] : const [];
