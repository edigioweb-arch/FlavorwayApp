# FlavorWay

FlavorWay est une plateforme complète de livraison de repas développée avec Flutter, Firebase, Laravel et MySQL.

## Présentation

La plateforme FlavorWay est composée de plusieurs applications qui partagent les mêmes données et les mêmes règles métier :

- Application Client en Flutter
- Application Livreur en Flutter
- Back-office Administrateur en Laravel
- Plateforme Restaurateur en Laravel

## Technologies utilisées

### Applications mobiles

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Firebase Storage

### Plateformes web et API

- Laravel
- PHP
- MySQL
- API REST
- Blade
- Bootstrap ou Tailwind CSS

## Fonctionnalités principales

### Application Client

- Création de compte et connexion
- Recherche de restaurants
- Consultation des menus
- Gestion du panier
- Création de commandes
- Suivi des commandes
- Notifications
- Messagerie
- Gestion des adresses
- Paiement
- Avis et évaluations

### Application Livreur

- Connexion et gestion du profil
- Mode en ligne ou hors ligne
- Réception des missions
- Acceptation ou refus des livraisons
- Navigation
- Mise à jour du statut des commandes
- Messagerie
- Confirmation de livraison par OTP
- Consultation des gains
- Historique des livraisons

### Back-office Administrateur

- Gestion des utilisateurs
- Gestion des restaurants
- Gestion des livreurs
- Gestion des commandes
- Gestion des paiements
- Gestion des abonnements
- Gestion des commissions
- Gestion des promotions
- Gestion du support
- Gestion des notifications
- Gestion des paramètres de la plateforme
- Consultation des statistiques

### Plateforme Restaurateur

- Gestion du restaurant
- Gestion des menus
- Gestion des produits
- Gestion des disponibilités
- Réception des commandes
- Acceptation ou refus des commandes
- Mise à jour de la préparation
- Consultation des ventes
- Gestion de l’abonnement
- Accès au support

## Architecture

Les applications Flutter, le Back-office Administrateur et la plateforme Restaurateur utilisent une architecture commune.

Les données sont gérées à travers :

- Laravel REST API
- MySQL
- Cloud Firestore
- Firebase Authentication
- Firebase Cloud Messaging

## Règles importantes du projet

- Aucune donnée métier ne doit être codée en dur.
- Toutes les données doivent provenir de Firestore, de MySQL ou des API Laravel.
- Le design validé ne doit pas être modifié.
- Les couleurs, la typographie, les composants, les boutons et les écrans existants doivent être conservés.
- Les futures modifications doivent concerner uniquement les fonctionnalités, la sécurité, la synchronisation et les performances.

## Identifiants de l’application

- Nom de l’application : FlavorWay
- Package Android : `ma.edigioweb.flavorway`
- Bundle Identifier iOS : `ma.edigioweb.flavorway`

## Dépôt GitHub

```text
https://github.com/edigioweb-arch/FlavorwayApp
