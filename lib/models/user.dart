/// User roles available in the mobile app. The web `Role.ADMIN` is omitted:
/// the admin back-office is out of scope for the mobile app.
enum UserRole {
  patient('PATIENT_PROFILE', 'Patient'),
  doctor('DOCTOR_PROFILE', 'Médecin'),
  careOwner('CARE_OWNER', 'Aidant / Proche');

  const UserRole(this.backendValue, this.label);

  final String backendValue;
  final String label;

  bool get isCaregiver => this == UserRole.careOwner || this == UserRole.doctor;
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

/// Payload of the sign-up form (web `SignUpRequest`).
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
}
