# FlavorWay — Cycle officiel d’une commande

## 1. Objectif

Ce document définit le cycle unique d’une commande FlavorWay.

Ce cycle doit être utilisé par :

- l’application Client Flutter ;
- l’application Livreur Flutter ;
- l’espace Restaurateur Laravel ;
- le Back-office Administrateur Laravel ;
- les API ;
- MySQL ;
- Firestore ;
- les notifications ;
- la messagerie.

Aucune application ne doit utiliser des statuts différents de ceux définis dans ce document.

---

## 2. Statuts principaux

### `created`

La commande vient d’être créée par le client.

Acteur autorisé :

- Client
- Administrateur

Statuts suivants autorisés :

- `restaurant_accepted`
- `restaurant_rejected`
- `cancelled`

---

### `restaurant_accepted`

Le restaurant accepte la commande.

Acteur autorisé :

- Restaurateur
- Employé autorisé du restaurant
- Administrateur

Statuts suivants autorisés :

- `preparing`
- `cancelled`

---

### `restaurant_rejected`

Le restaurant refuse la commande.

Acteur autorisé :

- Restaurateur
- Employé autorisé du restaurant
- Administrateur

Conséquences :

- arrêt du traitement de la commande ;
- notification du client ;
- annulation ou remboursement du paiement ;
- enregistrement du motif du refus.

---

### `preparing`

Le restaurant prépare la commande.

Acteur autorisé :

- Restaurateur
- Employé autorisé du restaurant

Statuts suivants autorisés :

- `ready_for_pickup`
- `cancelled`

---

### `ready_for_pickup`

La commande est prête à être récupérée.

Acteur autorisé :

- Restaurateur
- Employé autorisé du restaurant

Conséquences :

- création ou activation de la mission de livraison ;
- notification des livreurs disponibles ;
- notification du client ;
- attente de l’affectation d’un livreur.

Statuts suivants autorisés :

- `driver_assigned`
- `cancelled`

---

### `driver_assigned`

Un livreur a accepté la mission ou a été affecté.

Acteurs autorisés :

- Livreur
- Administrateur
- Système d’affectation automatique

Statuts suivants autorisés :

- `driver_heading_to_restaurant`
- `cancelled`

---

### `driver_heading_to_restaurant`

Le livreur se dirige vers le restaurant.

Acteur autorisé :

- Livreur affecté à la commande

Statuts suivants autorisés :

- `driver_arrived_restaurant`
- `failed`

---

### `driver_arrived_restaurant`

Le livreur confirme son arrivée au restaurant.

Acteur autorisé :

- Livreur affecté à la commande

Statuts suivants autorisés :

- `picked_up`
- `failed`

---

### `picked_up`

Le livreur a récupéré la commande.

Acteurs impliqués :

- Livreur affecté
- Restaurant

La récupération doit être sécurisée avec au moins une preuve :

- code de retrait ;
- QR code ;
- validation du restaurant.

Statuts suivants autorisés :

- `on_the_way_to_customer`
- `failed`

---

### `on_the_way_to_customer`

Le livreur se dirige vers l’adresse du client.

Acteur autorisé :

- Livreur affecté à la commande

Statuts suivants autorisés :

- `driver_arrived_customer`
- `failed`

---

### `driver_arrived_customer`

Le livreur confirme son arrivée à l’adresse de livraison.

Acteur autorisé :

- Livreur affecté à la commande

Statuts suivants autorisés :

- `delivery_confirmation_pending`
- `failed`

---

### `delivery_confirmation_pending`

La commande attend une preuve de remise au client.

Preuves possibles :

- code OTP ;
- QR code ;
- signature ;
- photo ;
- validation directe du client.

Statuts suivants autorisés :

- `delivered`
- `failed`

---

### `delivered`

La commande a été remise au client.

Conséquences :

- clôture de la commande ;
- confirmation de la transaction ;
- calcul de la commission FlavorWay ;
- ajout de la rémunération du livreur ;
- mise à jour des statistiques du restaurant ;
- activation des avis et des notes ;
- envoi d’une notification au client, au restaurant et au livreur.

Ce statut est final.

---

## 3. Statuts exceptionnels

### `cancelled`

La commande a été annulée.

Les informations suivantes doivent obligatoirement être enregistrées :

- `cancelled_by`
- `cancel_reason`
- `cancelled_at`
- `refund_required`
- `refund_amount`

Valeurs possibles pour `cancelled_by` :

- `customer`
- `restaurant`
- `driver`
- `support`
- `admin`
- `system`

---

### `failed`

La commande ou la livraison n’a pas pu être terminée.

Exemples :

- client injoignable ;
- adresse introuvable ;
- incident du livreur ;
- commande endommagée ;
- problème de paiement ;
- restaurant fermé ;
- problème technique.

Un ticket support doit être créé lorsque l’incident nécessite une intervention humaine.

---

## 4. Statuts du paiement

Le statut du paiement doit être séparé du statut de la commande.

Valeurs officielles :

- `pending`
- `authorized`
- `paid`
- `failed`
- `cancelled`
- `partially_refunded`
- `refunded`

Exemple :

```json
{
  "order_status": "preparing",
  "payment_status": "paid"
}