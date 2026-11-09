import 'package:fakarniapp/models/user.dart';

/// Signed-in session for widget tests. The access token is an unsigned JWT
/// `{"sub":"u1","exp":4102444800}` (year 2100): it is never renewed.
const testSession = AuthSession(
  accessToken: 'eyJhbGciOiJub25lIn0.eyJzdWIiOiJ1MSIsImV4cCI6NDEwMjQ0NDgwMH0.sig',
  refreshToken: 'test-refresh',
  user: AppUser(
    id: 'u1',
    nom: 'Ben Ali',
    prenom: 'Sami',
    email: 'sami@fakarni.tn',
    role: UserRole.careOwner,
    numTel: '12345678',
    adresse: 'Tunis',
  ),
);
