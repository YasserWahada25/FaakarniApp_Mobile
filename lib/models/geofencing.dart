/// Geofencing models (web `geofencing.service.ts`).
enum ZoneType {
  safe('SAFE', 'SAFE — patient must stay inside', 'Alert triggered if the patient leaves this zone.'),
  danger('DANGER', 'DANGER — patient must stay outside', 'Alert triggered if the patient enters this zone.');

  const ZoneType(this.code, this.optionLabel, this.explanation);

  final String code;
  final String optionLabel;
  final String explanation;
}

class SafeZone {
  const SafeZone({
    required this.id,
    required this.nomZone,
    required this.patientId,
    required this.patientName,
    required this.centreLat,
    required this.centreLon,
    required this.rayon,
    required this.type,
    this.soignantId,
  });

  final int id;
  final String nomZone;
  final String patientId;
  final String patientName;
  final double centreLat;
  final double centreLon;
  final int rayon;
  final ZoneType type;
  final String? soignantId;

  SafeZone copyWith({
    String? nomZone,
    String? patientId,
    String? patientName,
    double? centreLat,
    double? centreLon,
    int? rayon,
    ZoneType? type,
  }) =>
      SafeZone(
        id: id,
        nomZone: nomZone ?? this.nomZone,
        patientId: patientId ?? this.patientId,
        patientName: patientName ?? this.patientName,
        centreLat: centreLat ?? this.centreLat,
        centreLon: centreLon ?? this.centreLon,
        rayon: rayon ?? this.rayon,
        type: type ?? this.type,
        soignantId: soignantId,
      );
}

enum AlertStatus {
  active('Active'),
  resolved('Resolved');

  const AlertStatus(this.label);
  final String label;
}

enum AlertSeverity {
  high('High'),
  medium('Medium'),
  low('Low');

  const AlertSeverity(this.label);
  final String label;
}

enum AlertKind {
  zoneExit('SORTIE_ZONE', 'Sortie de zone'),
  dangerEntry('ENTREE_ZONE_DANGER', 'Entrée zone danger'),
  sos('SOS', 'SOS patient'),
  gpsLost('GPS_PERDU', 'Signal GPS perdu');

  const AlertKind(this.code, this.label);
  final String code;
  final String label;
}

class GeoAlert {
  const GeoAlert({
    required this.id,
    required this.patientName,
    required this.kind,
    required this.severity,
    required this.status,
    required this.timestamp,
    required this.distanceHorsZone,
  });

  final int id;
  final String patientName;
  final AlertKind kind;
  final AlertSeverity severity;
  final AlertStatus status;
  final DateTime timestamp;
  final double distanceHorsZone;

  bool get isActive => status == AlertStatus.active;

  GeoAlert resolve() => GeoAlert(
        id: id,
        patientName: patientName,
        kind: kind,
        severity: severity,
        status: AlertStatus.resolved,
        timestamp: timestamp,
        distanceHorsZone: distanceHorsZone,
      );
}

/// Patient linked to the caregiver (supervision tables and zone form).
class MonitoredPatient {
  const MonitoredPatient({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.email,
    required this.latitude,
    required this.longitude,
    required this.lastSeen,
    required this.isOnline,
  });

  final String id;
  final String prenom;
  final String nom;
  final String email;
  final double latitude;
  final double longitude;
  final DateTime lastSeen;
  final bool isOnline;

  String get fullName => '$prenom $nom';
  String get initials => '${prenom[0]}${nom[0]}';
}

enum PatientSafetyStatus {
  safe('SAFE'),
  alert('ALERT'),
  offline('OFFLINE');

  const PatientSafetyStatus(this.label);
  final String label;
}

class PatientStat {
  const PatientStat({
    required this.patient,
    required this.zone,
    required this.totalAlerts,
    required this.activeAlerts,
    required this.safetyScore,
    required this.status,
  });

  final MonitoredPatient patient;
  final SafeZone? zone;
  final int totalAlerts;
  final int activeAlerts;
  final int safetyScore;
  final PatientSafetyStatus status;
}

class DailyCount {
  const DailyCount(this.label, this.count);

  final String label;
  final int count;
}

class AlertChannelPreferences {
  const AlertChannelPreferences({required this.emailEnabled, required this.voiceEnabled});

  final bool emailEnabled;
  final bool voiceEnabled;

  AlertChannelPreferences copyWith({bool? emailEnabled, bool? voiceEnabled}) => AlertChannelPreferences(
        emailEnabled: emailEnabled ?? this.emailEnabled,
        voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      );
}

enum GpsStatus { requesting, active, denied }
