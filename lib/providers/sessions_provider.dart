import 'package:flutter/foundation.dart';

import '../models/session.dart';
import '../services/api_client.dart';
import '../services/session_service.dart';
import '../widgets/common/async_state_view.dart';

/// Sessions shared by the Alzheimer tabs (web `AlzheimerService` subject): a
/// favorite toggled or a reservation sent in one tab shows up in the others.
class SessionsProvider extends ChangeNotifier {
  SessionsProvider({SessionService? service}) : _service = service ?? SessionService.instance;

  static final SessionsProvider instance = SessionsProvider();

  final SessionService _service;

  List<Session> _sessions = const [];
  List<Session> _favorites = const [];
  ViewStatus _status = ViewStatus.loading;
  String? _error;
  String? _loadedFor;
  Future<void>? _loading;
  Session? _lastCreated;

  List<Session> get sessions => _sessions;
  List<Session> get favorites => _favorites;
  ViewStatus get status => _status;
  String? get error => _error;

  /// Last reservation sent: the reservations tab opens its day.
  Session? get lastCreated => _lastCreated;

  /// Concurrent calls (tabs opening together) share the same requests. Data
  /// already shown stays on screen while it is refreshed, except after a change
  /// of account.
  Future<void> load() => _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    final userId = _service.currentUserId;
    if (_loadedFor != userId || _status == ViewStatus.error) {
      _sessions = const [];
      _favorites = const [];
      _status = ViewStatus.loading;
      _error = null;
      notifyListeners();
    }
    try {
      final results = await Future.wait([_service.getSessions(), _service.getFavorites()]);
      _sessions = results[0];
      _favorites = results[1];
      _status = ViewStatus.ready;
      _error = null;
      _loadedFor = userId;
    } on ApiException catch (e) {
      _status = ViewStatus.error;
      _error = e.message;
      _loadedFor = userId;
    }
    notifyListeners();
  }

  /// Throws [ApiException] and leaves the data untouched when the server refuses.
  Future<void> toggleFavorite(Session session) async {
    final favorite = !session.isFavorite;
    await _service.setFavorite(session.id, favorite);
    _sessions = [for (final s in _sessions) s.id == session.id ? s.copyWith(isFavorite: favorite) : s];
    _favorites = favorite
        ? ([..._favorites.where((s) => s.id != session.id), session.copyWith(isFavorite: true)]
          ..sort((a, b) => a.start.compareTo(b.start)))
        : _favorites.where((s) => s.id != session.id).toList();
    notifyListeners();
  }

  Future<Session> createReservation(ReservationRequest request) async {
    final created = await _service.createReservation(request);
    _lastCreated = created;
    _sessions = [..._sessions, created]..sort((a, b) => a.start.compareTo(b.start));
    notifyListeners();
    return created;
  }
}
