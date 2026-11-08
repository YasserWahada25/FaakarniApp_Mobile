# Fakarni (فكرني) — application mobile

Version mobile (Flutter) de la plateforme FakarniApp. Elle consomme les mêmes
microservices que l'application web, via la Spring Cloud Gateway (port 8090).

## Connexion au backend

1. Dans le Codespace, démarrer la stack puis passer le port **8090** en
   **Public** (onglet *Ports* → clic droit → *Port Visibility*).
2. Copier `env/dev.example.json` en `env/dev.json` (ignoré par git) et le remplir :
   - `API_BASE_URL` : l'URL du port 8090, par ex. `https://xxxx-8090.app.github.dev` ;
   - `DEV_EMAIL` / `DEV_PASSWORD` : un compte existant de la plateforme.
3. Lancer : `flutter run --dart-define-from-file=env/dev.json`

Sans `env/dev.json`, l'application vise `http://10.0.2.2:8090` (gateway lancée
sur la machine hôte, vue depuis l'émulateur Android).

### Compte de développement (temporaire)

Tant que l'écran de connexion n'est pas branché sur `POST /auth/login`,
`AuthSession` (`lib/core/session/auth_session.dart`) connecte automatiquement le
compte `DEV_EMAIL` et le reconnecte quand son jeton (15 min) expire. Une fois
l'authentification intégrée, l'écran de connexion appelle
`AuthSession.instance.signIn(accessToken: …, user: …)` et `signOut()` à la
déconnexion ; le compte de développement n'est alors plus utilisé.

Intégration avec l'authentification et les modules éducatif / événements
développés sur une autre machine : voir **[docs/GUIDE_INTEGRATION.md](docs/GUIDE_INTEGRATION.md)**.

## Organisation de la couche API

| Fichier | Rôle |
|---|---|
| `lib/core/network/api_config.dart` | URL de la gateway, URL du WebSocket du chat |
| `lib/core/network/api_client.dart` | Client JSON (jeton Bearer, erreurs en français) |
| `lib/core/session/auth_session.dart` | Utilisateur connecté (jeton + id) |
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
