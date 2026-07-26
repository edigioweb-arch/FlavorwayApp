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

Chaque ligne de cette table représente une personne physique ou morale inscrite sur la plateforme.

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
