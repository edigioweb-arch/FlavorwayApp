# FlavorWay – Cycle de vie d'une commande

## Présentation

Ce document décrit toutes les étapes du parcours d'une commande sur la plateforme FlavorWay.

Il définit les actions des différents acteurs (client, restaurateur, livreur et administrateur), les changements de statut ainsi que les événements importants qui seront utilisés par les applications Flutter et le backend Laravel.

---

# 1. Création de la commande

### Acteur

Client

### Actions

- Recherche un restaurant.
- Consulte le menu.
- Ajoute des produits au panier.
- Vérifie son panier.
- Choisit une adresse de livraison.
- Sélectionne un moyen de paiement.
- Confirme la commande.

### Statut

```
created
```

---

# 2. Paiement

Le paiement est traité.

Selon le moyen de paiement choisi, la commande peut être :

- Payée immédiatement.
- Payée à la livraison.

### Statut

```
payment_pending
```

ou

```
payment_completed
```

---

# 3. Réception par le restaurant

Le restaurant reçoit immédiatement la commande.

Le restaurateur peut :

- accepter la commande ;
- refuser la commande.

### Statuts

```
restaurant_accepted
```

ou

```
restaurant_rejected
```

---

# 4. Préparation

Le restaurant prépare la commande.

### Statut

```
preparing
```

---

# 5. Commande prête

La commande est terminée.

Elle attend un livreur.

### Statut

```
ready_for_pickup
```

---

# 5b. Recherche d'un livreur

Une fois la commande prête, le système recherche automatiquement un livreur disponible à proximité du restaurant.

Pendant cette recherche, la commande reste en attente jusqu'à ce qu'un livreur soit trouvé.

Si aucun livreur n'est disponible, la commande reste dans cet état et une nouvelle tentative est effectuée périodiquement.

### Statut

```
waiting_for_driver
```

---

# 6. Attribution d'un livreur

Le système recherche automatiquement un livreur disponible.

Lorsqu'un livreur accepte :

### Statut

```
driver_assigned
```

---

# 7. Le livreur se rend au restaurant

Le livreur est en route.

### Statut

```
driver_heading_to_restaurant
```

---

# 8. Le livreur récupère la commande

Le restaurateur remet la commande.

### Statut

```
picked_up
```

---

# 9. Livraison

Le livreur se dirige vers le client.

### Statut

```
on_the_way_to_customer
```

---

# 10. Arrivée

Le livreur arrive à destination.

### Statut

```
driver_arrived_customer
```

---

# 11. Confirmation de livraison

Le client reçoit sa commande.

### Statut

```
delivered
```

---

# 12. Évaluation

Après la livraison, le client peut :

- noter le restaurant ;
- noter le livreur ;
- laisser un commentaire.

---

# Cas particuliers

## Annulation par le client

Possible uniquement avant l'acceptation du restaurant.

Statut :

```
cancelled_by_customer
```

---

## Refus du restaurant

Statut :

```
restaurant_rejected
```

---

## Annulation par l'administrateur

Statut :

```
cancelled_by_admin
```

---

## Remboursement

Lorsqu'une commande déjà payée est annulée, un remboursement peut être effectué selon les règles de la plateforme.

Le remboursement peut concerner :

- une annulation par le client avant la préparation ;
- une annulation par le restaurant ;
- une annulation par l'administrateur ;
- un échec de livraison.

### Statut

```
refunded
```

---

## Échec de livraison

Exemples :

- client absent ;
- adresse incorrecte ;
- problème technique.

Statut :

```
delivery_failed
```

---

# Notifications

À chaque changement de statut, une notification est envoyée aux personnes concernées.

Exemples :

- Client
- Restaurateur
- Livreur
- Administrateur

---

# Conclusion

Chaque changement de statut sera enregistré dans la base de données afin de permettre un suivi complet de la commande.

Ce document servira de référence pour le développement du backend Laravel, des API et des applications Flutter.

---

# 13. Clôture de la commande

Une fois la commande terminée :

- les revenus du livreur sont enregistrés ;
- la commission FlavorWay est calculée ;
- le paiement du restaurant est mis à jour ;
- la commande est archivée ;
- les statistiques sont mises à jour.

### Statut

```
completed
```

---

## Évolutions futures

Le cycle de vie pourra évoluer afin d'intégrer :

- les commandes planifiées ;
- les commandes groupées ;
- les livraisons multiples ;
- les abonnements ;
- les commandes professionnelles.

---

## Remarque

Les statuts définis dans ce document seront utilisés comme référence unique dans :

- l'application Client ;
- l'application Livreur ;
- l'espace Restaurateur ;
- le Back-office Administrateur ;
- les API Laravel ;
- la base de données.

---

## Source de vérité

Les statuts définis dans ce document constituent la référence officielle de FlavorWay.

Aucun développeur ne devra créer de nouveaux statuts sans mettre à jour cette documentation.

Toutes les applications (Client, Livreur, Restaurateur et Administrateur) devront utiliser exactement les mêmes valeurs.

