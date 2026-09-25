# Configuration production restante

Les fonctionnalités applicatives sont présentes dans `lib/`. Les éléments suivants nécessitent une configuration Firebase ou un service externe avant publication.

## Notifications push

Le plugin `firebase_messaging` est intégré et le token est enregistré dans `users/{uid}/fcmTokens`. Android déclare la permission `POST_NOTIFICATIONS`. Il reste à activer Cloud Messaging dans Firebase, configurer la clé APNs côté iOS et les paramètres Web Push côté navigateur. Les rappels doivent être envoyés depuis Cloud Functions avec le fuseau horaire du joueur ; le client ne doit pas envoyer lui-même les notifications.

## Modération

Le service `ModerationService` écrit dans `reports`. Les règles Firestore doivent limiter la création de rapports par utilisateur et interdire la modification/suppression par le client. Une Cloud Function doit agréger les signalements et appliquer les décisions de modération.

## Replays et spectateurs

Les traits sont déjà stockés dans RTDB sous `strokes/{roomCode}` et accessibles en lecture par le replay. Ajouter une politique d’expiration pour supprimer les dessins anciens et éviter une croissance illimitée.

## Reconnaissance de dessin

Le mode solo nécessite un modèle embarqué (TensorFlow Lite/ML Kit) ou une API dédiée. Le contrat recommandé est une entrée `List<DrawingStroke>` et une sortie `{label, confidence}` ; aucune donnée de dessin ne doit être envoyée à un service tiers sans consentement.

## Cosmétiques

`CosmeticCatalog` et `CosmeticService` couvrent la sélection locale. Pour une boutique réelle, déplacer l’inventaire et les achats dans un backend sécurisé ou dans les achats intégrés des plateformes. Les cosmétiques ne doivent jamais modifier le score, la taille de collision ou les règles de partie.

## Classement saisonnier

Le client utilise `seasonScores.{YYYY-Sn}` et affiche la saison courante par trimestre. Une tâche planifiée doit archiver les résultats, empêcher les écritures client sur les scores et publier les récompenses de fin de saison via une Cloud Function.

Les règles versionnées sont `firestore.rules` et `database.rules.json`. Elles doivent être déployées avec `firebase deploy --only firestore,database` après revue des écritures serveur nécessaires au moteur de partie.

Le dossier `functions/` contient `notifyTurnEnding` et `rotateSeason`. Installer ses dépendances avec `npm install` depuis ce dossier, puis déployer avec `firebase deploy --only functions`. Cloud Scheduler doit être activé pour la rotation trimestrielle.

## Modes de jeu

Les salons stockent `gameMode` avec les valeurs `classic`, `blitz` et `cooperative`. `blitz` utilise des manches de 30 secondes ; `cooperative` permet à tous les joueurs de dessiner. Les règles Firestore/RTDB doivent valider ces valeurs côté serveur.

Les mots communautaires sont soumis dans `community_words` avec le statut `pending`. Une modération serveur doit approuver les mots avant qu’ils soient utilisés dans une partie.

## Layouts adaptatifs

La page de jeu bascule en deux colonnes à partir de 900 px : toile et outils à gauche, chat à droite. En dessous, elle conserve le flux vertical mobile. Les appareils pliables doivent être testés avec leurs dimensions et leurs changements de posture réels.
