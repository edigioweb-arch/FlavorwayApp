# FlavorWay – Vision du projet

## Présentation

FlavorWay est une plateforme de livraison de repas inspirée d'Uber Eats, Glovo et Deliveroo.

La plateforme est composée de plusieurs applications qui utilisent le même backend.

## Applications

### Application Client (Flutter)

Permet aux clients de :

- créer un compte
- rechercher des restaurants
- commander des repas
- suivre leur livraison
- discuter avec le livreur
- recevoir des notifications

---

### Application Livreur (Flutter)

Permet aux livreurs de :

- accepter des livraisons
- suivre leur itinéraire
- mettre à jour le statut des commandes
- consulter leurs revenus

---

### Espace Restaurateur (Laravel)

Permet aux restaurants de :

- gérer leur établissement
- gérer leurs produits
- gérer les commandes
- consulter leurs statistiques

---

### Back-office Administrateur (Laravel)

Permet à FlavorWay de gérer :

- les utilisateurs
- les restaurants
- les livreurs
- les commandes
- les paiements
- les commissions
- les promotions
- les paramètres de la plateforme
- les statistiques globales

---

## Technologies

### Frontend

- Flutter

### Backend

- Laravel 12

### Base de données

- MySQL

### Temps réel

- Firebase Firestore

### Authentification

- Firebase Authentication

### Notifications

- Firebase Cloud Messaging

### Stockage

- Firebase Storage

---

## Principe d'architecture

Flutter ne contient aucune logique métier.

Toutes les règles métier sont gérées par Laravel.

Laravel communique avec MySQL et Firebase.

Flutter communique uniquement avec les API Laravel.

## Objectifs du projet

FlavorWay a pour objectif de proposer une plateforme complète de livraison de repas permettant de connecter :

- les clients
- les restaurants
- les livreurs
- les administrateurs

Le système doit être rapide, sécurisé, évolutif et disponible sur Android, iOS et le Web.