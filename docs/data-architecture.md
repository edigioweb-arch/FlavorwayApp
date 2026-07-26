# FlavorWay — Architecture des données

---

# 1. Utilisateurs (Users)

La plateforme FlavorWay repose sur une collection principale appelée **Users**.

Tous les utilisateurs de la plateforme sont enregistrés au même endroit.

Les rôles disponibles sont :

- Client
- Livreur
- Restaurateur
- Employé de restaurant
- Support
- Administrateur

Chaque utilisateur possède un identifiant unique généré par Firebase Authentication.

Les informations complémentaires sont ensuite synchronisées avec la base de données.

---

## Champs principaux

- id
- firebase_uid
- prénom
- nom
- email
- téléphone
- photo
- rôle
- statut
- langue
- pays
- ville
- devise
- date de création
- dernière connexion

---

## Statuts possibles

- Actif
- En attente de validation
- Suspendu
- Désactivé

---

## Relations

Un utilisateur peut :

- posséder plusieurs adresses ;
- passer plusieurs commandes ;
- laisser plusieurs avis ;
- recevoir plusieurs notifications ;
- participer à plusieurs conversations.

Selon son rôle, il pourra également être lié à :

- un restaurant ;
- un véhicule de livraison ;
- un portefeuille (Wallet).

---

# 2. Restaurants

Chaque restaurant inscrit sur FlavorWay possède sa propre fiche.

Un restaurant peut être géré par un ou plusieurs employés autorisés.

Chaque restaurant dispose :

- d'un profil public ;
- d'un menu ;
- de catégories de produits ;
- d'horaires d'ouverture ;
- de documents administratifs ;
- d'un portefeuille financier ;
- de statistiques.

---

## Champs principaux

- id
- nom
- description
- logo
- bannière
- téléphone
- email
- adresse
- pays
- ville
- coordonnées GPS
- statut
- horaires
- note moyenne
- nombre d'avis
- frais de livraison
- délai moyen
- commission FlavorWay
- date de création

---

## Statuts possibles

- En attente de validation
- Actif
- Suspendu
- Fermé temporairement
- Désactivé

---

## Relations

Un restaurant possède :

- plusieurs catégories ;
- plusieurs produits ;
- plusieurs employés ;
- plusieurs commandes ;
- plusieurs avis ;
- plusieurs promotions ;
- un portefeuille ;
- plusieurs notifications.