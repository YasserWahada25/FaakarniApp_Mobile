import '../core/config/api_endpoints.dart';
import '../models/meeting.dart';
import 'api_client.dart';

/// meeting-insights-service API, through the gateway (web `MeetingInsightsService`).
class MeetingInsightsService {
  MeetingInsightsService({ApiClient? client}) : _api = client ?? ApiClient.instance;

  static final MeetingInsightsService instance = MeetingInsightsService();

  /// Whisper can take minutes on a long recording.
  static const Duration _transcriptionTimeout = Duration(minutes: 5);

  final ApiClient _api;

  /// [language] goes in the query: that is where FastAPI reads it.
  Future<MeetingTranscription> transcribe({
    required List<int> bytes,
    required String filename,
    String? language,
  }) =>
      _guard(() async {
        final lang = language?.trim() ?? '';
        final raw = await _api.postFile(
          ApiEndpoints.meetRecording,
          field: 'file',
          bytes: bytes,
          filename: filename,
          query: lang.isEmpty ? null : {'language': lang},
          timeout: _transcriptionTimeout,
        );
        return MeetingTranscription.fromJson(_map(raw));
      });

  Future<MeetingReport> generateReport({
    required String text,
    String? meetingTitle,
    String? language,
    String? transcriptionId,
  }) =>
      _guard(() async {
        final raw = await _api.post(
          ApiEndpoints.meetReport,
          body: {
            'meeting_title': _orNull(meetingTitle),
            'language': _orNull(language),
            'transcribed_text': text.trim(),
            'transcription_id': transcriptionId,
          },
        );
        return MeetingReport.fromJson(_map(raw));
      });

  Future<List<MeetingReport>> getReports() => _guard(() async {
        final raw = await _api.get(ApiEndpoints.meetReports);
        return _maps(raw).map(MeetingReport.fromJson).toList();
      });

  Future<List<MeetingTranscription>> getTranscriptions() => _guard(() async {
        final raw = await _api.get(ApiEndpoints.meetTranscriptions);
        return _maps(raw).map(MeetingTranscription.fromJson).toList();
      });

  /// A 404 means the route has no implementation behind the gateway: the Java
  /// image of the service has no controller, only the Python one serves it.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      throw const ApiException('Le service de rapports n’est pas disponible sur le serveur.', statusCode: 404);
    }
  }

  static String? _orNull(String? value) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  static Iterable<Map<String, dynamic>> _maps(dynamic raw) =>
      raw is List ? raw.whereType<Map<String, dynamic>>() : const [];

  static Map<String, dynamic> _map(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    throw const ApiException('Réponse serveur invalide.');
  }
}
