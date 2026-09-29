/// Form validators ported from the web app (`auth/validators/form.validators.ts`
/// and the Angular reactive-form rules of each page). Each returns `null` when
/// the value is valid, otherwise the message shown under the field.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final RegExp _name = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ\s'-]+$");
  static final RegExp _phone = RegExp(r'^[0-9]{8}$');
  static final RegExp _strongPassword = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{6,}$');
  static final RegExp _code = RegExp(r'^[0-9]{6}$');

  static String? required(String? value, [String message = 'This field is required.']) =>
      (value == null || value.trim().isEmpty) ? message : null;

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    if (!_email.hasMatch(value.trim())) return 'Please enter a valid email address.';
    return null;
  }

  static String? name(String? value, {String label = 'Name'}) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    if (!_name.hasMatch(value.trim())) return '$label must contain only letters (no numbers).';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    return null;
  }

  /// Sign-up rule: 6+ chars, 1 uppercase, 1 digit, 1 special character.
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 6) return 'Password must be at least 6 characters.';
    if (!_strongPassword.hasMatch(value)) {
      return 'Password must contain 1 uppercase, 1 number and 1 special character.';
    }
    return null;
  }

  static String? phone(String? value) =>
      (value == null || !_phone.hasMatch(value.trim())) ? 'Phone number must contain exactly 8 digits.' : null;

  static String? resetCode(String? value) =>
      (value == null || !_code.hasMatch(value.trim())) ? 'Le code doit contenir exactement 6 chiffres.' : null;

  static String? minLength(String? value, int min, String message) =>
      (value == null || value.trim().length < min) ? message : null;

  static String? latitude(String? value) {
    final v = double.tryParse(value ?? '');
    if (v == null || v < -90 || v > 90) return 'Latitude invalide (-90 à 90).';
    return null;
  }

  static String? longitude(String? value) {
    final v = double.tryParse(value ?? '');
    if (v == null || v < -180 || v > 180) return 'Longitude invalide (-180 à 180).';
    return null;
  }
}
