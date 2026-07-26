# FlavorWay – Base de données

## Présentation

Ce document décrit la structure de la base de données principale de FlavorWay.

Il définit les tables MySQL, leurs relations ainsi que leur rôle dans la plateforme.

Cette documentation servira de référence pour :

- les migrations Laravel ;
- les modèles Eloquent ;
- les API ;
- les applications Flutter ;
- le Back-office Administrateur ;
- l'Espace Restaurateur.

---

# Principes

La base de données est centralisée.

Laravel est la seule application autorisée à écrire directement dans la base de données.

Flutter communique uniquement avec les API Laravel.

Firebase est utilisé uniquement pour :

- l'authentification ;
- les notifications ;
- les fonctionnalités temps réel.

MySQL reste la source principale des données métier.

---

# Table : users

## Présentation

La table `users` est la table centrale de FlavorWay. Elle contient tous les utilisateurs de la plateforme, quel que soit leur rôle ou leur type de compte.

Chaque ligne de cette table représente un compte utilisateur enregistré sur la plateforme, qu'il s'agisse d'un client, d'un restaurateur, d'un employé de restaurant, d'un livreur, d'un membre du support ou d'un administrateur.

Les informations propres aux restaurants, aux commandes, aux paiements ou aux livraisons sont stockées dans leurs tables respectives et reliées à cette table par des relations.

## Rôles pris en charge

| Rôle | Description |
|---|---|
| Client | Utilisateur final qui commande des plats et réserve des tables |
| Restaurateur | Propriétaire ou gérant d'un restaurant inscrit sur la plateforme |
| Employé de restaurant | Personnel autorisé à gérer les commandes et le menu d'un restaurant |
| Livreur | Coursier qui assure la livraison des commandes |
| Support | Membre de l'équipe FlavorWay chargé de l'assistance aux utilisateurs |
| Administrateur | Super-utilisateur ayant accès à l'ensemble des fonctionnalités du Back-office |

## Convention technique

Les intitulés des rôles sont présentés en français dans cette documentation afin de faciliter la lecture.

En revanche, les valeurs réellement enregistrées dans la base de données resteront en anglais pour conserver une nomenclature technique uniforme.

Exemple :

- client
- restaurant_owner
- restaurant_employee
- driver
- support
- admin

## Structure de la table

| Champ | Type | Description |
|---|---|---|
| id | bigint, auto-incrément | Identifiant unique de l'utilisateur |
| firebase_uid | string, nullable | Identifiant Firebase Authentication (null si compte non lié) |
| first_name | string | Prénom de l'utilisateur |
| last_name | string | Nom de famille de l'utilisateur |
| email | string, unique | Adresse e-mail de connexion |
| phone | string, nullable | Numéro de téléphone |
| password | string, nullable | Mot de passe local hashé. Ce champ peut rester null lorsque l'authentification est entièrement gérée par Firebase Authentication. |
| avatar | string, nullable | URL ou chemin de la photo de profil |
| role | enum | Rôle de l'utilisateur (client, restaurant_owner, restaurant_employee, driver, support, admin) |
| status | enum | Statut du compte (active, pending, suspended, disabled) |
| language | string, défaut 'fr' | Langue préférée de l'utilisateur |
| country | string, nullable | Pays de résidence |
| city | string, nullable | Ville de résidence |
| currency | string, nullable | Devise préférée de l'utilisateur (MAD, XAF, XOF, EUR, USD, etc.) |
| email_verified_at | timestamp, nullable | Date de vérification de l'adresse e-mail |
| phone_verified_at | timestamp, nullable | Date de vérification du numéro de téléphone |
| last_login_at | timestamp, nullable | Date de la dernière connexion |
| is_online | boolean | Indique si l'utilisateur est actuellement connecté |
| deleted_at | timestamp, nullable | Date de suppression logique (Soft Delete Laravel) |
| created_at | timestamp | Date de création du compte |
| updated_at | timestamp | Date de la dernière modification |

## Index

Les index suivants devront être créés afin d'optimiser les performances :

- Index unique sur `email`
- Index unique sur `firebase_uid`
- Index sur `role`
- Index sur `status`
- Index sur `phone`
- Index sur `created_at`


## Statuts possibles

| Statut | Description |
|---|---|
| active | Le compte est actif et l'utilisateur peut utiliser la plateforme |
| pending | Le compte est en attente de validation (utilisé pour les restaurateurs et livreurs) |
| suspended | Le compte est temporairement suspendu par un administrateur |
| disabled | Le compte est définitivement désactivé |

## Contraintes

Les règles suivantes devront être respectées :

- L'adresse e-mail doit être unique.
- Le numéro de téléphone ne peut appartenir qu'à un seul compte.
- Un utilisateur doit toujours posséder un rôle valide.
- Un utilisateur suspendu ne peut pas se connecter.
- Un administrateur ne peut pas être supprimé sans autorisation spécifique.


## Relations avec les autres tables

La table `users` est reliée aux tables suivantes :

| Table | Type de relation | Description |
|---|---|---|
| user_addresses | Un utilisateur peut avoir plusieurs adresses | Adresses de livraison et de facturation |
| restaurants | Un restaurateur peut posséder un ou plusieurs restaurants | Restaurants dont l'utilisateur est propriétaire ou gestionnaire. |
| orders | Un client peut passer plusieurs commandes | Commandes passées par l'utilisateur |
| reviews | Un client peut laisser plusieurs avis | Évaluations laissées par l'utilisateur |
| notifications | Un utilisateur peut recevoir plusieurs notifications | Notifications push et in-app |
| wallets | Un utilisateur peut avoir un porte-monnaie électronique | Solde, historique des transactions et revenus |
| conversations | Un utilisateur peut participer à plusieurs conversations | Conversations avec les clients, restaurateurs, livreurs et le support |

## Conclusion

La table `users` est la base de toute la plateforme FlavorWay.

Elle centralise les informations essentielles de chaque personne inscrite et permet de relier l'ensemble des fonctionnalités : commandes, livraisons, restaurants, paiements, avis et notifications.

Sa conception doit être rigoureuse afin de garantir la cohérence des données à travers tous les modules de l'application.

---

# Table : user_addresses

## Présentation

La table `user_addresses` permet à chaque utilisateur d'enregistrer plusieurs adresses de livraison.

Les informations relatives aux adresses sont stockées dans une table séparée de la table `users` afin de rendre la plateforme plus flexible et évolutive. Cette séparation permet à un utilisateur de gérer librement ses adresses sans impacter la structure centrale des comptes, et d'associer plusieurs points de livraison à un même client.

## Structure de la table

| Champ | Type | Description |
|---|---|---|
| id | bigint, auto-incrément | Identifiant unique de l'adresse |
| user_id | bigint, foreign key | Identifiant de l'utilisateur propriétaire de l'adresse (clé étrangère vers `users.id`) |
| label | string, nullable | Libellé personnel de l'adresse (ex : Maison, Bureau, Chez un proche) |
| recipient_name | string | Nom du destinataire pour la livraison |
| recipient_phone | string | Numéro de téléphone du destinataire |
| address_line_1 | string | Adresse principale (numéro, rue, quartier) |
| address_line_2 | string, nullable | Complément d'adresse (étage, appartement, point de repère) |
| postal_code | string, nullable | Code postal de la localité |
| city | string | Ville de livraison |
| region | string, nullable | Région ou département |
| country | string | Pays de l'adresse |
| latitude | decimal(10,7), nullable | Latitude pour le géocodage et l'affichage sur la carte |
| longitude | decimal(10,7), nullable | Longitude pour le géocodage et l'affichage sur la carte |
| delivery_instructions | text, nullable | Instructions particulières pour le livreur (code d'accès, sonnette, étage) |
| is_default | boolean, défaut false | Indique si cette adresse est l'adresse par défaut de l'utilisateur |
| is_active | boolean, défaut true | Indique si l'adresse est toujours active et utilisable |
| created_at | timestamp | Date de création de l'adresse |
| updated_at |
