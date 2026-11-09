# Fakarni (فكرني) — application mobile

Application mobile Flutter de la plateforme **FakarniApp**, dédiée à
l'accompagnement des personnes atteintes de la maladie d'Alzheimer, de leurs
aidants et de leurs médecins.

C'est la version mobile de l'application web
([Esprit_PI_4SAE5_2026_FakarniApp](https://github.com/YasserWahada25/Esprit_PI_4SAE5_2026_FakarniApp)).
Elle utilise **les mêmes microservices Spring Boot**, toujours à travers la
**Spring Cloud Gateway (port 8090)**, exactement comme le web.

---

## Sommaire

1. [Fonctionnalités](#1-fonctionnalités)
2. [Navigation](#2-navigation)
3. [Démarrage rapide](#3-démarrage-rapide)
4. [Connexion au backend](#4-connexion-au-backend)
5. [Architecture](#5-architecture)
6. [Structure du projet](#6-structure-du-projet)
7. [Tests](#7-tests)
8. [Conventions de développement](#8-conventions-de-développement)
9. [Dépannage](#9-dépannage)
10. [Limites connues](#10-limites-connues)

---

## 1. Fonctionnalités

| Module | Ce que fait l'utilisateur | État |
|---|---|---|
| **Authentification** | Inscription, connexion, « Remember me », mot de passe oublié (code par e-mail), déconnexion | Branché sur l'API |
| **Profil** | Consulter et modifier ses informations | Branché sur l'API |
| **Community Posts** (accueil) | Fil de publications, recherche, post avec image, réactions, commentaires et réponses, « My Posts » | Branché sur l'API |
| **Alzheimer Meeting** | Calendrier des séances, réservations, favoris, visio, rapports | Branché sur l'API (voir détails) |
| **Suivi médical** | Dossier médical, détection par IRM (assistant NeuroScan + IA), suivi des patients | Branché sur l'API |
| **Éducatif** | Activités et jeux cognitifs (quiz, memory, puzzle, images), événements, progression | Branché sur l'API |
| **Communication** | Groupes (création, membres, rôles), messagerie en temps réel | Branché sur l'API |
| **Geofencing** | Suivi en direct, zones de sécurité, alertes, supervision | Interface prête, **pas encore branchée** sur l'API |

### Authentification et session
- Les pages d'authentification sont publiques. Toutes les autres demandent d'être connecté : un utilisateur non connecté est renvoyé vers *Sign In*.
- Le jeton d'accès dure 15 minutes. L'application le renouvelle avec le *refresh token* **avant** son expiration, puis rejoue une fois une requête refusée en 401.
- « Remember me » garde la session dans le stockage sécurisé du téléphone (Keystore / Keychain). Sans cette option, elle reste en mémoire.
- Rôles : `PATIENT_PROFILE`, `DOCTOR_PROFILE`, `CARE_OWNER` (aidant) et `ADMIN`. Le back-office d'administration reste sur le web.

### Alzheimer Meeting
- **Réservations :** le patient demande une séance individuelle ou de groupe, en ligne ou en présentiel (lieu choisi sur la carte ou par sa position GPS). La demande reste « En attente » jusqu'à ce que l'**admin** l'accepte ou la refuse depuis le web. Un chevauchement avec une séance existante est refusé.
- **Confidentialité :** une réservation, et la séance qu'elle devient une fois acceptée, n'est visible que par le patient qui l'a faite, les participants ajoutés (le médecin, par exemple) et l'admin. Les séances publiques créées par l'admin sont visibles par tous.
- **Consultation :** calendrier des séances acceptées, filtre en ligne / présentiel, détail d'une séance.
- **Favoris :** marquer des séances et les retrouver dans un onglet dédié.
- **Visio :** vidéo et audio en WebRTC, couper le micro ou la caméra, changer de caméra, chat en direct avec historique, liste des participants, ajout d'un participant par son identifiant. La salle s'ouvre au premier participant autorisé et les autres la rejoignent.
- **Rapports :** transcription d'un enregistrement audio et rapport de synthèse (voir [limites](#10-limites-connues)).
- **Notifications :** préférences de rappel enregistrées sur l'appareil.

### Suivi médical
- **Medical Records :** dossier médical de l'utilisateur connecté.
- **Disease Detection :** assistant NeuroScan en 3 étapes : profil et indice de risque, questionnaire clinique, puis analyse d'une IRM par le modèle d'IA du backend, qui produit un rapport.
- **Follow-up :** liste des patients et dossier de chacun (IRM zoomable, modification et suppression d'une analyse, comparaison, statistiques).

### Éducatif
- **Activités :** quiz, quiz d'images, memory par paires, puzzle, vidéos et contenus ; le score est envoyé au serveur.
- **Événements :** liste et localisation sur une carte.
- **Progression :** suivi de l'engagement du patient.

### Communication
- **Groupes :** créer, modifier, rejoindre, quitter, image de couverture, rôles des membres.
- **Messagerie :** conversations avec de vrais utilisateurs et indicateur « en train d'écrire ». Les nouveaux messages arrivent par WebSocket ; sans WebSocket, la conversation est relue toutes les 4 secondes.

---

## 2. Navigation

**Barre du bas :** Home (Community Posts) · Alzheimer · Medical · Education · Messages.

- Chaque onglet garde sa propre pile de navigation.
- Le **menu latéral** (bouton ☰) donne accès à tous les modules et à leurs sous-pages, au profil et à la déconnexion.
- **Geofencing**, les formulaires, le détail d'un dossier patient, la visio et les pages des posts (création, modification, « My Posts ») s'ouvrent en plein écran, avec un bouton retour.
- Après la connexion, l'utilisateur arrive sur le fil **Community Posts**.

---

## 3. Démarrage rapide

### Prérequis
- **Flutter 3.44** (Dart 3.12) ou plus récent.
- Android Studio ou les outils Android en ligne de commande, et un téléphone Android avec le *débogage USB* activé (ou un émulateur).
- Sous Windows : le **mode développeur** doit être activé, car les plugins Flutter utilisent des liens symboliques (`start ms-settings:developers`).

### Installation et lancement
```bash
git clone https://github.com/YasserWahada25/FaakarniApp_Mobile.git
cd FaakarniApp_Mobile
flutter pub get
cp config/dev.example.json config/dev.json   # puis renseigner API_BASE_URL (voir §4)
flutter run
```

Dans VS Code, la configuration de lancement **« Fakarni (config/dev.json) »** (`.vscode/launch.json`) fait la même chose.

### Permissions demandées sur le téléphone
| Permission | Utilisation |
|---|---|
| Caméra, micro | Visio des séances |
| Localisation | « Utiliser ma position » dans le formulaire de réservation |
| Photos, fichiers | Images des posts et des groupes, IRM, fichiers audio pour les rapports |

---

## 4. Connexion au backend

Le backend complet (gateway, Eureka, microservices, bases de données) tourne
dans un **GitHub Codespace** du dépôt web, avec Docker Compose.

1. Dans le Codespace, démarrer la stack :
   ```bash
   bash scripts/codespace-start.sh
   # ou : docker compose -f docker-compose.yml -f docker-compose.hub.yml up -d --no-build
   ```
2. Passer les ports **8090** (gateway) et **4300** (web) en **Public** : onglet *Ports* → clic droit → *Port Visibility*. Le script le fait automatiquement.
3. Copier `config/dev.example.json` en `config/dev.json` (ce fichier est ignoré par git) :
   ```json
   { "API_BASE_URL": "https://<nom-du-codespace>-8090.app.github.dev" }
   ```
4. Lancer `flutter run`. Le fichier est lu au démarrage ; il faut relancer l'application (pas un *hot reload*) après l'avoir modifié.

**Ordre de priorité de l'URL :** `--dart-define=API_BASE_URL=…`, puis `config/dev.json`, puis `http://10.0.2.2:8090` (une gateway lancée sur le PC, vue depuis l'émulateur Android).

**Si le port 8090 est privé**, l'application affiche « Le port 8090 du Codespace est privé ».

---

## 5. Architecture

```
Écrans (screens/)  ──►  Providers / état (providers/)  ──►  Services (services/)
                                                              │
                                    ApiClient (jeton, JSON, erreurs) ──► Gateway :8090 ──► microservices
                                    STOMP / SockJS (temps réel)      ──► /ws (visio), /chat-ws (chat)
                                    WebRTC (pair à pair)             ──► autres participants de la visio
```

### Couche réseau
| Élément | Rôle |
|---|---|
| `lib/core/config/api_config.dart` | URL de la gateway, URL des médias et du WebSocket du chat |
| `lib/core/config/api_endpoints.dart` | **Tous** les chemins d'API, centralisés |
| `lib/services/api_client.dart` | Client HTTP unique : jeton Bearer, JSON UTF-8, envoi de fichiers, messages d'erreur en français |
| `lib/providers/auth_provider.dart` | Session : connexion, « Remember me », renouvellement du jeton, déconnexion ; protège les routes |
| `lib/core/session/auth_session.dart` | Vue en lecture de la session pour les modules Communication, Posts et Médical |

### Services par microservice
| Service mobile | Microservice (route de la gateway) |
|---|---|
| `auth_service.dart` | User-Service (`/auth/**`, `/api/users/**`) |
| `user_directory_service.dart` | User-Service (`/api/users/by-role/{role}`) |
| `post_service.dart` | Post-Service (`/api/posts/**`) |
| `session_service.dart` | session-service : séances, favoris, réservations, salles vidéo (`/session/**`) |
| `meeting_signaling.dart` | session-service : signalisation de la visio (SockJS + STOMP sur `/ws`) |
| `meeting_media.dart` | WebRTC : caméra, micro et connexions entre participants |
| `meeting_insights_service.dart` | meeting-insights-service : transcription et rapports (`/api/meet/**`) |
| `medical_service.dart` | Detection-Service (`/api/detection/**`), Dossier-Medical-Service (`/api/dossiers/**`) |
| `educational_service.dart` | activite-educative-service (`/api/activities/**`), Event-Service (`/api/events`), suivi-engagement-service (`/api/engagement/**`) |
| `group_service.dart` | group-service (`/api/groups/**`, `/api/upload/image`) |
| `chat_service.dart`, `chat_socket.dart` | Chat_Service (`/api/messages/**`, STOMP sur `/chat-ws/websocket`) |

### État de l'application
- `AuthProvider` et `SessionsProvider` (séances Alzheimer partagées entre les onglets) sont des `ChangeNotifier` singletons.
- `MeetingController` pilote une salle de visio (connexion, négociation WebRTC, chat, participants).
- Les autres écrans gardent leur état dans un `StatefulWidget`. Les services d'écriture exposent un `ValueNotifier<int> revision` que les écrans écoutent pour se recharger.

### Principales dépendances
`go_router` (navigation), `http` (API), `flutter_secure_storage` (session),
`stomp_dart_client` (temps réel), `flutter_webrtc` (visio), `flutter_map` +
`latlong2` (cartes), `geolocator` (position), `image_picker` / `file_picker`
(images, IRM, audio), `google_fonts`, `intl`.

---

## 6. Structure du projet

```
lib/
├── main.dart                 # Point d'entrée : configuration, session, thème, routeur
├── core/
│   ├── config/               # ApiConfig (URL), ApiEndpoints (chemins d'API)
│   ├── constants/            # Constantes de l'application
│   ├── network/              # Réexports de ApiConfig / ApiClient, lecture des dates JSON
│   ├── router/               # go_router : routes, garde d'authentification, onglets
│   ├── session/              # AuthSession (vue de la session)
│   ├── theme/                # Couleurs, typographie, dimensions, thème Material
│   └── utils/                # Formatage, validateurs, scores cliniques
├── models/                   # Modèles et lecture du JSON des API
├── providers/                # AuthProvider, SessionsProvider, MeetingController
├── services/                 # Accès aux microservices (un fichier par domaine)
├── screens/                  # Un dossier par module (auth, alzheimer, medical, posts…)
└── widgets/                  # Composants réutilisables, communs et par module
test/                         # Tests unitaires et tests d'écrans
config/dev.example.json       # Modèle de configuration du backend
docs/GUIDE_INTEGRATION.md     # Historique de l'intégration entre les deux postes
```

---

## 7. Tests

```bash
flutter analyze   # analyse statique : doit afficher « No issues found! »
flutter test      # tous les tests
```

Les tests couvrent :
- **les écrans :** chaque route s'affiche sans erreur sur un petit téléphone, avec le parcours de navigation et la déconnexion ;
- **les modèles :** lecture du JSON de chaque service (auth, éducatif, Alzheimer, posts, communication, médical) ;
- **les services :** requêtes envoyées (chemins, corps, multipart), gestion des erreurs et du renouvellement du jeton ;
- **la visio :** signalisation, négociation entre participants, chat et participants, testés sans caméra ni réseau grâce à des faux.

Les tests n'appellent jamais le vrai backend. Les lignes `API … → HTTP 400` affichées pendant `flutter test` sont normales.

---

## 8. Conventions de développement

- **Chemins d'API :** à ajouter dans `lib/core/config/api_endpoints.dart`, jamais écrits en dur dans un service.
- **Appels HTTP :** toujours via `ApiClient.instance`, qui gère le jeton, le JSON et les erreurs. Pour afficher une erreur : `ApiException.describe(e)`.
- **Utilisateur connecté :** `AuthProvider.instance.user`, ou `AuthSession.instance.userId`.
- **Nouveau module :** reprendre le service web correspondant (`frontend/src/app/**/services`) et les DTO du contrôleur backend, pour rester aligné avec le web.
- **Dates :** les `LocalDateTime` de Spring arrivent sans fuseau ; les lire avec `parseApiDate` (`lib/core/network/json_parsing.dart`).
- **Avant chaque commit :** `flutter analyze` et `flutter test` doivent passer.

---

## 9. Dépannage

| Problème | Solution |
|---|---|
| « Le port 8090 du Codespace est privé » | Passer le port 8090 en **Public** dans l'onglet *Ports* du Codespace |
| « Serveur injoignable » / délai dépassé | Vérifier `API_BASE_URL` dans `config/dev.json`, que le Codespace tourne, puis relancer l'application |
| Toutes les URL du Codespace répondent 404 | Dans l'onglet *Ports* : *Stop Forwarding Port* sur 8090 / 4300, réajouter le port, le repasser en Public |
| `Building with plugins requires symlink support` | Activer le mode développeur de Windows (`start ms-settings:developers`) |
| Erreur Kotlin « this and base files have different roots » | Déjà corrigée par `kotlin.incremental=false` (`android/gradle.properties`) ; sinon `flutter clean` puis relancer |
| La visio ne connecte pas les participants hors Wi-Fi | Seuls des serveurs STUN sont configurés, sans TURN : certains réseaux mobiles bloquent la connexion directe |

---

## 10. Limites connues

- **Geofencing :** les écrans existent, mais ne sont pas encore reliés au tracking-service et au geofencing-service.
- **Rapports de réunion :** l'image Docker par défaut du meeting-insights-service ne contient pas d'API (`/api/meet/*` répond 404) ; le service FastAPI réel (`Dockerfile.python`) doit être déployé et routé par la gateway.
- **Visio :** pas de partage d'écran sur mobile, et pas de serveur TURN.
- **Rappels de séance :** les préférences sont enregistrées sur l'appareil, mais aucune notification n'est envoyée (le web ne le fait pas non plus).
- **Sécurité côté backend :** le WebSocket de la visio et le chat n'exigent pas de jeton, et les transcriptions de réunion ne sont pas filtrées par utilisateur.
- **Connexion Google / Facebook :** non disponible sur mobile (elle demande les SDK natifs et des identifiants OAuth).
