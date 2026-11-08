# Guide d'intégration — Communication, Posts, Navigation et Suivi médical

Ce guide s'adresse à l'agent IA (et au développeur) qui intègre, sur la machine
où se trouvent l'**authentification**, les **activités éducatives** et les
**événements**, le travail réalisé en parallèle sur une autre machine.

Il décrit tout ce qui a changé, où, pourquoi, et la procédure de fusion. Lis-le
en entier avant de toucher au code.

---

## 1. Vue d'ensemble

| Dépôt | Branche | État |
|---|---|---|
| Mobile `YasserWahada25/FaakarniApp_Mobile` | **`feature/communication-posts-medical`** | Communication, Posts, navigation, suivi médical branchés sur l'API |
| Backend `YasserWahada25/Esprit_PI_4SAE5_2026_FakarniApp` | `main` | 11 commits de corrections (déjà déployés sur le Codespace via la CI) |

Le mobile parle **uniquement à la Spring Cloud Gateway (port 8090)**, comme le web.

Travail réalisé **sur cette branche** :
- couche réseau commune (`ApiConfig`, `ApiClient`, `AuthSession`) ;
- **Communication** : groupes (CRUD, membres, rôles, image de couverture) et messagerie (vrais utilisateurs, temps réel STOMP + repli en polling) ;
- **Posts** : fil, création/modification avec image, suppression, réactions, commentaires/réponses, « My Posts » ;
- **Navigation** : *Posts* remplace *Geofencing* dans la barre du bas ;
- **Suivi médical** : dossier de l'utilisateur, liste des patients, dossier patient (IRM, édition, suppression), assistant NeuroScan en 3 étapes avec analyse IA réelle.

Travail **non présent** sur cette branche (il est sur l'autre machine) :
authentification (écrans sign-in/sign-up/mot de passe), activités éducatives, événements.

---

## 2. Procédure de fusion (à suivre dans l'ordre)

```bash
# 1. Mettre à l'abri le travail local (auth, éducatif, events) sur sa propre branche
git checkout -b feature/auth-education-events
git add -A
git commit -m "feat: auth, educational activities and events API integration"
git push -u origin feature/auth-education-events

# 2. Récupérer et fusionner cette branche
git fetch origin
git merge origin/feature/communication-posts-medical

# 3. Après résolution des conflits
flutter pub get
dart analyze          # doit afficher "No issues found!"
flutter test          # 25 tests sur cette branche, tous verts
```

Ensuite, ouvrir une pull request de `feature/auth-education-events` vers `main`.

### Zones de conflit attendues

| Fichier | Ce que cette branche y a changé | Résolution |
|---|---|---|
| `pubspec.yaml` / `pubspec.lock` | Ajout de `http`, `http_parser`, `stomp_dart_client`, `image_picker` | Garder **l'union** des dépendances, puis `flutter pub get` (régénère le lock) |
| `lib/core/router/app_router.dart` | Posts devient la 3ᵉ branche du `StatefulShellRoute` (sous-routes `create`, `edit/:id`, `my-posts` sur `_rootKey`) ; Geofencing devient une route plein écran de premier niveau | Garder ces deux déplacements **et** les ajouts auth (redirect, garde, routes) |
| `lib/core/router/app_routes.dart` | `posts` rangé avec les branches, `geofencing` avec les modules plein écran (commentaires uniquement, mêmes chemins) | Trivial |
| `lib/screens/shell/main_shell.dart` | 3ᵉ destination : **Posts** (icône `dynamic_feed`) au lieu de Geofencing | Garder |
| `lib/widgets/navigation/app_drawer.dart`, `lib/screens/home/home_screen.dart` | Geofencing en `push: true`, Community Posts en `go` | Garder |
| `README.md` | Réécrit (connexion au backend, organisation de la couche API) | Fusionner les deux contenus |
| `test/widget_test.dart` | Le parcours de la barre du bas passe par Posts ; Geofencing testé via le drawer | Garder et ajouter les tests auth |
| `test/screens_render_test.dart` | Test NeuroScan : l'âge est maintenant le seul champ texte de l'étape 1 (index 0) | Garder |
| `ios/Runner/Info.plist` | `NSPhotoLibraryUsageDescription` (image_picker) | Garder |

Fichiers **non modifiés** ici (aucun conflit possible de notre côté) :
`lib/main.dart`, `lib/models/user.dart`, `lib/core/constants/app_constants.dart`,
les écrans `screens/auth/*`, `screens/educational/*`, `screens/alzheimer/*`,
`screens/profile/*`, le thème (`lib/core/theme/*`).

---

## 3. Couche réseau ajoutée — à unifier avec celle de l'autre machine

| Fichier | Rôle |
|---|---|
| `lib/core/network/api_config.dart` | `ApiConfig.baseUrl` (dart-define `API_BASE_URL`), `mediaUrl()`, `chatSocketUrl`, compte de dev (`DEV_EMAIL`/`DEV_PASSWORD`), timeout 20 s |
| `lib/core/network/api_client.dart` | `ApiClient.instance` : `get/post/put/patch/delete/upload`, ajoute `Authorization: Bearer`, décode l'UTF-8, lève `ApiException` (message en français). `ApiException.describe(e)` pour l'affichage |
| `lib/core/network/json_parsing.dart` | `parseApiDate` (les `LocalDateTime` Spring sont **UTC sans fuseau** → lus en UTC puis convertis en local), `stringOrNull`, `fullNameOf` |
| `lib/core/session/auth_session.dart` | `AuthSession.instance` : jeton + utilisateur connecté (**point d'intégration avec l'auth**) |

Configuration : `env/dev.example.json` → copier en `env/dev.json` (ignoré par git),
puis `flutter run --dart-define-from-file=env/dev.json`. `.vscode/launch.json`
contient une configuration qui le fait automatiquement. Un hot reload ne suffit
pas après un changement de ce fichier (valeurs compilées) : relancer l'app.

### 3.1 Brancher l'authentification sur `AuthSession` (obligatoire)

Toutes les fonctionnalités de cette branche lisent l'utilisateur via
`AuthSession.instance.userId` / `.user` et le jeton via `ApiClient`. En
attendant l'auth, `AuthSession` connecte automatiquement le compte de `env/dev.json`.

À faire dans le code d'authentification de l'autre machine :

1. **Après chaque connexion réussie** (`POST /auth/login`, `/auth/google`, `/auth/facebook`
   → `AuthResponse { accessToken, refreshToken, user }`) :
   ```dart
   AuthSession.instance.signIn(accessToken: res.accessToken, user: appUser);
   ```
   `user` est un `AppUser` (`lib/models/user.dart`). Si `user` est omis, l'id est lu dans le `sub` du JWT.
2. **À la déconnexion** (`POST /auth/logout` avec `{refreshToken}`) : `AuthSession.instance.signOut();`
3. **Au démarrage**, si la session est persistée (shared_preferences / secure storage),
   rappeler `signIn(...)` avec le jeton restauré.
4. **Renouvellement du jeton (15 min)** : `AuthSession` ne gère aujourd'hui que la
   reconnexion du compte de dev. Ajouter le `refreshToken` à `AuthSession` et, dans
   `ensureSignedIn()`, appeler `POST /auth/refresh` (`{ "refreshToken": "…" }` → nouvel
   `AuthResponse`) quand le jeton expire dans moins de 30 s.
   **Important** : group-service et post-service ne renvoient **pas** 401 avec un jeton
   expiré, ils traitent l'appel comme anonyme (un groupe créé aurait le créateur
   `anonymousUser`, un post l'auteur `anonymousUser`). Le renouvellement doit donc être
   **proactif**, avant l'expiration.
5. Une fois l'auth branchée, le compte de dev peut rester (il n'agit que si `DEV_EMAIL`
   est défini) ; ne jamais définir `DEV_*` dans un build de production.
6. Si `AppConstants.skipAuth` est passé à `false` de l'autre côté, garder ce choix.

### 3.2 Un seul client HTTP et une seule URL de base

Si les services éducatif / events de l'autre machine utilisent leur propre client
(`dio`, `http` direct) ou une URL codée en dur :
- **URL** : la remplacer par `ApiConfig.baseUrl` (ou `ApiConfig.uri(path)`).
- **Client** : de préférence migrer ces services sur `ApiClient.instance` (jeton,
  UTF-8, erreurs déjà gérés). À défaut, s'assurer qu'ils prennent le jeton de
  `AuthSession.instance.accessToken()` pour ne pas avoir deux sessions différentes.

### 3.3 Conventions utilisées par les écrans

- État local en `StatefulWidget` + services singletons (pas de provider/riverpod ;
  `lib/providers/` est vide). Chaque service d'écriture expose un
  `ValueNotifier<int> revision` incrémenté après chaque écriture ; les écrans
  concernés l'écoutent pour se recharger (ex. un groupe créé depuis le formulaire
  rafraîchit la liste).
- Erreurs : `catch (e)` → `ApiException.describe(e)` dans un `ErrorStateView` /
  `showAppSnackBar`.
- En mode debug, les erreurs réseau affichent l'URL visée, et la console imprime au
  premier appel `AuthSession: API_BASE_URL=…, dev account …`.

---

## 4. Fonctionnalités et contrats API par module

Tous les chemins passent par la Gateway (`{API_BASE_URL}` = port 8090).

### 4.1 Communication — `lib/services/group_service.dart`, `chat_service.dart`, `chat_socket.dart`, `user_directory_service.dart`

| Fonction | Appel |
|---|---|
| Groupes (avec membres) | `GET /api/groups?includeMembers=true` ; `GET /api/groups/{id}?includeMembers=true` |
| Créer / modifier / supprimer | `POST /api/groups` (**JWT obligatoire**, le créateur devient ADMIN) ; `PUT /api/groups/{id}` ; `DELETE /api/groups/{id}` |
| Rejoindre / quitter / retirer | `POST /api/groups/{id}/members {userId, role:"MEMBER"}` ; `DELETE /api/groups/{id}/members/{userId}` |
| Rôle d'un membre | `PATCH /api/groups/{id}/members/{userId}/role {role}` |
| Image de couverture | `POST /api/upload/image` (multipart `file`, `image/*`, ≤ 5 Mo) → `{url:"/uploads/groups/…"}` |
| Contacts du chat | `GET /api/users/by-role/{PATIENT_PROFILE|DOCTOR_PROFILE|CARE_OWNER}` (public ; `GET /api/users` est réservé à ADMIN) |
| Conversation / envoi / suppression | `GET /api/messages/conversation?user1=&user2=` ; `POST /api/messages/send {senderId, receiverId, content}` ; `DELETE /api/messages/{id}` |
| Temps réel | WebSocket STOMP brut `wss://…/chat-ws/websocket` ; abonnements `/queue/messages/{userId}` et `/queue/typing/{userId}` ; envoi `/app/chat.typing {senderId, receiverId, typing}`. Si le socket n'est pas connecté, la conversation est relue toutes les 4 s |

Le *Feed* de la messagerie reste vide (le web n'a pas de backend pour lui).

### 4.2 Posts — `lib/services/post_service.dart`

| Fonction | Appel |
|---|---|
| Fil / posts d'un utilisateur | `GET /api/posts` (trié côté mobile) ; `GET /api/posts/user/{userId}` |
| Créer / modifier / supprimer | `POST /api/posts {content, imageUrl}` (**auteur pris dans le JWT**) ; `PUT /api/posts/{id}` ; `DELETE /api/posts/{id}` |
| Réactions | `GET /api/posts/{id}/reactions?userId=` ; `POST /api/posts/{id}/reactions/toggle {userId, type: LIKE|HEART|SUPPORT}` |
| Commentaires | `GET /api/posts/{id}/comments?page=0&size=50` (page Spring, réponses incluses) ; `POST … {userId, content, parentCommentId?}` (un seul niveau de réponse) ; `DELETE …/comments/{cid}?userId=` (refusé si non-auteur) |

- Les images de post sont stockées **en ligne** (`data:image/…;base64,…`, ≤ 5 Mo de
  texte), comme le fait le web ; `PostImage` les décode.
- Modifier/Supprimer ne s'affichent que sur les posts de l'utilisateur connecté.

### 4.3 Suivi médical — `lib/services/medical_service.dart`

| Fonction | Appel |
|---|---|
| Patients | `GET /api/users/by-role/PATIENT_PROFILE` |
| Dossier d'un patient | `GET /api/dossiers/patient/{patientId}` → **404 = pas encore de dossier** (aucune analyse) |
| Analyse IRM (étape 3) | `POST /api/detection/analyser?patientId=` multipart champ **`image`** (nom de fichier en `.png/.jpg/.jpeg`) — timeout 90 s ; le résultat est aussi ajouté au dossier |
| Image IRM stockée | `GET /api/detection/image/{nomFichier}` |
| Modifier / supprimer une analyse | `PUT /api/dossiers/analyse/update-description {analyseId, descriptionRisque, conseilMedecin, notesCliniques}` ; `DELETE /api/dossiers/analyse/{analyseId}` — **`analyseId` = `id` de l'analyse dans le dossier** (pas `analyseIrmId`) |

L'assistant NeuroScan garde les 3 étapes du web : 1) patient (choisi dans la
liste, présélectionné si l'utilisateur est patient), genre, âge → indice de risque ;
2) questionnaire clinique ; 3) image IRM → modèle IA (Flask EfficientNetB3 via
Detection-Service) → rapport, puis « Voir le dossier ».
Score indicatif /30 par stade : 28 / 22 / 16 / 9 (identique au web).

Écrans : `records_tab.dart` (dossier de l'utilisateur connecté), `follow_up_tab.dart`
(patients), `patient_dossier_screen.dart` (vue d'ensemble, dossier avec IRM
zoomable + édition/suppression, comparaison, statistiques), `detection_tab.dart`.

### 4.4 Navigation

Barre du bas : **Home · Alzheimer · Posts · Education · Messages**.
Geofencing s'ouvre en plein écran (bouton retour) depuis le drawer et l'accès
rapide de l'accueil ; ses formulaires de zone restent fonctionnels.

---

## 5. Backend : ce qui a changé sur `main` (déjà déployé)

| Commit | Effet |
|---|---|
| `4144abf` fix(chat) | Spring Boot 4 : propriété Mongo `spring.mongodb.uri` (le chat tombait sur `localhost` → 500 après 30 s) |
| `abf96dd` fix(gateway) | `/chat-ws/**` réécrit vers `/ws/**` du chat (temps réel) |
| `6d7e3aa` feat(frontend) | Messagerie web sur vrais utilisateurs, plus de mock ; nginx proxifie `/chat-ws/` |
| `04d7dfc` fix(post-service) | `userId` des commentaires/réactions en `String` (ids Mongo) ; auteur inclus dans les commentaires |
| `749eee5` fix(frontend) | Posts web : utilisateur connecté au lieu de `userId = 1` |
| `fb77676` fix(gateway) | Routes `lb://DETECTION-MALADIE-SERVICE` / `lb://DOSSIER-MEDICAL-SERVICE` (tirets) |
| `5cb6105` fix(dossier) | 404 au lieu de 500 quand le patient n'a pas de dossier |
| `526c291` fix(detection) | Dossier `uploads` accessible en écriture + volume `fakarni_detection_uploads` |
| `71c064b` fix(frontend) | Web médical sur données réelles (Records, liste patients, sélection du patient) |
| `29b2cec` fix(frontend) | Rafraîchissement des pages médicales (application Angular *zoneless*) |
| `59e673c` fix(detection) | Ajout au dossier via `RestClient` (le client Feign n'avait pas de convertisseur JSON) |

Points d'exploitation :
- **Base existante du post-service** : une seule fois,
  `ALTER TABLE comments MODIFY user_id VARCHAR(255) NOT NULL; ALTER TABLE reactions MODIFY user_id VARCHAR(255) NOT NULL;`
  (`ddl-auto=update` ne change pas le type d'une colonne). Déjà fait sur le Codespace actuel.
- Démarrage de la stack sur le Codespace : `docker compose -f docker-compose.yml -f docker-compose.hub.yml up -d --no-build`
  (les MySQL n'ont pas de `restart:` ; ne pas utiliser `restart`). Port **8090 en Public** pour le mobile.
- Les tests du Detection-Service sont désactivés dans son `pom.xml` (`skipTests=true`).

---

## 6. Vérification après fusion

Comptes de test du Codespace : un **patient** (`wahadayasser25@gmail.com`) et un
**médecin** (`balkis@gmail.com`) ; demander les mots de passe à l'équipe.

- [ ] Connexion par l'écran d'auth (et non plus par `DEV_EMAIL`) → la console
      n'affiche plus de connexion du compte de dev ; groupes/posts créés ont le bon auteur.
- [ ] Déconnexion → les écrans Communication/Posts/Médical demandent de se connecter.
- [ ] Jeton expiré (> 15 min) → création de groupe/post toujours attribuée au bon utilisateur.
- [ ] Communication : créer/rejoindre/quitter un groupe ; chat avec le médecin, message
      reçu en direct, « en train d'écrire ».
- [ ] Posts : post avec image, réactions, commentaire + réponse, My Posts.
- [ ] Médical : analyse IRM en 3 étapes → « Voir le dossier » ; Follow-up → IRM, Modifier.
- [ ] Éducatif / Events (autre machine) toujours fonctionnels avec le client unifié.
- [ ] `dart analyze` propre, `flutter test` vert.

---

## 7. Limites connues (non traitées)

- Le backend ne vérifie pas les droits : n'importe quel client peut supprimer un
  groupe ou un post via l'API ; le chat n'exige pas de jeton. Le mobile masque
  seulement les actions selon le rôle / l'auteur.
- « Support en ligne » (Groups) écrit à un utilisateur `support` inexistant.
- Le mobile n'applique pas le contrôle « l'image ressemble-t-elle à une IRM ? » du web.
- Pas d'export PDF sur mobile (le bouton du rapport ouvre le dossier du patient).
- Pas de gestion de présence en ligne (le backend n'en fournit pas).
