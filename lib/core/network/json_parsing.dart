// Helpers to read the JSON produced by the Spring Boot services.

/// Spring serialises `LocalDateTime` without a time zone (e.g.
/// `2026-11-08T09:02:53.123456`). The containers run in UTC, so such values
/// are read as UTC and converted to the device's local time. Also accepts the
/// array form (`[2026, 11, 8, 9, 2, 53]`) in case a service enables it.
DateTime parseApiDate(Object? value, {DateTime? fallback}) {
  if (value is String && value.isNotEmpty) {
    final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(value);
    final parsed = DateTime.tryParse(hasZone ? value : '${value}Z');
    if (parsed != null) return parsed.toLocal();
  }
  if (value is List && value.length >= 3) {
    final p = value.map((e) => (e as num).toInt()).toList();
    int at(int i) => i < p.length ? p[i] : 0;
    return DateTime.utc(p[0], p[1], p[2], at(3), at(4), at(5), at(6) ~/ 1000000).toLocal();
  }
  return fallback ?? DateTime.now();
}

String? stringOrNull(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

/// "Prénom Nom" from a user-service `UserDTO`/`UserResponse` map.
String? fullNameOf(Object? user) {
  if (user is! Map) return null;
  final name = [stringOrNull(user['prenom']), stringOrNull(user['nom'])].whereType<String>().join(' ');
  return name.isNotEmpty ? name : stringOrNull(user['email']);
}
