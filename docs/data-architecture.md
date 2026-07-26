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