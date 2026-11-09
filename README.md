# Fakarni (فكرني) — application mobile

Version mobile (Flutter) de la plateforme FakarniApp. Elle consomme les mêmes
microservices que l'application web, via la Spring Cloud Gateway (port 8090).

## Connexion au backend

1. Dans le Codespace, démarrer la stack puis passer le port **8090** en
   **Public** (onglet *Ports* → clic droit → *Port Visibility*).
2. Copier `config/dev.example.json` en `config/dev.json` (ignoré par git) et y
   mettre `API_BASE_URL` : l'URL du port 8090, par ex. `https://xxxx-8090.app.github.dev`.
3. Lancer : `flutter run` (le fichier est lu au démarrage) ou
   `flutter run --dart-define-from-file=config/dev.json`.

Sans `config/dev.json`, l'application vise `http://10.0.2.2:8090` (gateway lancée
sur la machine hôte, vue depuis l'émulateur Android).

### Session

On se connecte par l'écran *Sign In* (`POST /auth/login`). `AuthProvider`
(`lib/providers/auth_provider.dart`) garde la session (« Remember me » dans le
stockage sécurisé), renouvelle le jeton (15 min) avec le refresh token avant son
expiration et protège les pages. `AuthSession.instance`
(`lib/core/session/auth_session.dart`) en est une vue pour les modules
Communication, Posts et Médical.

Historique de l'intégration des deux machines : **[docs/GUIDE_INTEGRATION.md](docs/GUIDE_INTEGRATION.md)**.

## Organisation de la couche API

| Fichier | Rôle |
|---|---|
| `lib/core/config/api_config.dart` | URL de la gateway (`config/dev.json` / `--dart-define`), URL du WebSocket du chat |
| `lib/core/config/api_endpoints.dart` | Chemins des routes de la gateway |
| `lib/services/api_client.dart` | Client JSON unique (jeton Bearer renouvelé, erreurs en français, envoi de fichiers) |
| `lib/providers/auth_provider.dart` | Session : connexion, « Remember me », renouvellement du jeton, déconnexion |
| `lib/core/session/auth_session.dart` | Vue de la session pour Communication, Posts et Médical |
| `lib/core/network/*` | Réexportent `ApiConfig` / `ApiClient` (chemins historiques) |
| `lib/services/auth_service.dart` | User-Service (`/auth/**`, `/api/users/{id}`) |
| `lib/services/educational_service.dart` | Activités, jeux (`/api/activities/**`), événements (`/api/events`), progression (`/api/engagement/**`) |
| `lib/services/session_service.dart` | Séances Alzheimer, favoris, réservations, salles vidéo (`/session/**`) |
| `lib/services/meeting_signaling.dart`, `meeting_media.dart` | Visio : signalisation SockJS/STOMP (`/ws`) et WebRTC |
| `lib/services/meeting_insights_service.dart` | Transcription et rapports de réunion (`/api/meet/**`) |
| `lib/services/group_service.dart` | group-service (`/api/groups`, `/api/upload`) |
| `lib/services/chat_service.dart` | Chat_Service REST (`/api/messages`) |
| `lib/services/chat_socket.dart` | Chat_Service temps réel (STOMP sur `/chat-ws/websocket`) |
| `lib/services/user_directory_service.dart` | user-service (`/api/users/by-role/{role}`) |
| `lib/services/post_service.dart` | Post-Service : posts, réactions, commentaires (`/api/posts/**`) |
| `lib/services/medical_service.dart` | Suivi médical : analyse IRM par l'IA (`/api/detection/**`), dossiers (`/api/dossiers/**`), patients |

Le chat reçoit les nouveaux messages par WebSocket. Si le socket ne se connecte
pas, l'écran de conversation interroge l'API toutes les 4 secondes.

## Tests

`flutter test` — rendu de tous les écrans et lecture des JSON des services.
