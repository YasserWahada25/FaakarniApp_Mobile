import 'dart:convert';

/// User roles (web `Role`, User-Service `Role`). [admin] accounts can sign in,
/// but the role is not offered in the mobile forms (back-office is web only).
enum UserRole {
  patient('PATIENT_PROFILE', 'Patient'),
  doctor('DOCTOR_PROFILE', 'Médecin'),
  careOwner('CARE_OWNER', 'Aidant / Proche'),
  admin('ADMIN', 'Administrateur');

  const UserRole(this.backendValue, this.label);

  final String backendValue;
  final String label;

  /// Roles a user can pick in the sign-up and profile forms.
  static const List<UserRole> selectable = [patient, doctor, careOwner];

  bool get isCaregiver => this == UserRole.careOwner || this == UserRole.doctor;

  static UserRole fromBackend(String? value) => UserRole.values.firstWhere(
        (r) => r.backendValue == (value ?? '').trim().toUpperCase(),
        orElse: () => UserRole.patient,
      );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    required this.numTel,
    required this.adresse,
  });

  /// User-Service `UserResponse`.
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: '${json['id'] ?? ''}',
        nom: (json['nom'] as String?) ?? '',
        prenom: (json['prenom'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
        role: UserRole.fromBackend(json['role'] as String?),
        numTel: (json['numTel'] as String?) ?? '',
        adresse: (json['adresse'] as String?) ?? '',
      );

  final String id;
  final String nom;
  final String prenom;
  final String email;
  final UserRole role;
  final String numTel;
  final String adresse;

  String get fullName => '$prenom $nom';
  String get initials =>
      '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'role': role.backendValue,
        'numTel': numTel,
        'adresse': adresse,
      };

  AppUser copyWith({
    String? nom,
    String? prenom,
    String? email,
    UserRole? role,
    String? numTel,
    String? adresse,
  }) =>
      AppUser(
        id: id,
        nom: nom ?? this.nom,
        prenom: prenom ?? this.prenom,
        email: email ?? this.email,
        role: role ?? this.role,
        numTel: numTel ?? this.numTel,
        adresse: adresse ?? this.adresse,
      );
}

/// Payload of the sign-up form (web `SignUpRequest`, `POST /api/users`).
class SignUpRequest {
  const SignUpRequest({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.password,
    required this.role,
    required this.numTel,
    required this.adresse,
  });

  final String nom;
  final String prenom;
  final String email;
  final String password;
  final UserRole role;
  final String numTel;
  final String adresse;

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'password': password,
        'role': role.backendValue,
        // The API pattern (8 digits) rejects an empty string: omit it instead.
        if (numTel.isNotEmpty) 'numTel': numTel,
        'adresse': adresse,
      };
}

/// Payload of the profile form (web `UserUpdateRequest`, `PUT /api/users/{id}`).
/// Empty fields are omitted: the API keeps their current value.
class UpdateUserRequest {
  const UpdateUserRequest({this.nom, this.prenom, this.email, this.role, this.numTel, this.adresse});

  final String? nom;
  final String? prenom;
  final String? email;
  final UserRole? role;
  final String? numTel;
  final String? adresse;

  Map<String, dynamic> toJson() => {
        if (_filled(nom)) 'nom': nom,
        if (_filled(prenom)) 'prenom': prenom,
        if (_filled(email)) 'email': email,
        if (role != null) 'role': role!.backendValue,
        if (_filled(numTel)) 'numTel': numTel,
        if (_filled(adresse)) 'adresse': adresse,
      };

  static bool _filled(String? v) => v != null && v.trim().isNotEmpty;
}

/// Signed-in session (User-Service `AuthResponse`).
class AuthSession {
  const AuthSession({required this.accessToken, required this.refreshToken, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: (json['accessToken'] as String?) ?? '',
        refreshToken: (json['refreshToken'] as String?) ?? '',
        user: AppUser.fromJson((json['user'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );

  final String accessToken;
  final String refreshToken;
  final AppUser user;

  Map<String, dynamic> toJson() => {'accessToken': accessToken, 'refreshToken': refreshToken, 'user': user.toJson()};

  AuthSession copyWith({AppUser? user}) =>
      AuthSession(accessToken: accessToken, refreshToken: refreshToken, user: user ?? this.user);

  /// Expiry of the access token (JWT `exp` claim, 15 min on the User-Service).
  DateTime? get accessTokenExpiry => _jwtExpiry(accessToken);

  /// True when the access token is missing or expires within [margin].
  bool accessTokenExpired({Duration margin = const Duration(seconds: 30)}) {
    final exp = accessTokenExpiry;
    return exp == null || DateTime.now().add(margin).isAfter(exp);
  }

  static DateTime? _jwtExpiry(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload is Map ? payload['exp'] : null;
      return exp is num ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000) : null;
    } on FormatException {
      return null;
    }
  }
}
