# LOT 5 — Cycle financier appliqué

Laravel reste la source de vérité des montants, droits et statuts. Les transitions
utilisent les services existants ; Flutter affiche la réponse du serveur.

## Cash

`confirmed → preparing → ready → picked_up → on_the_way → delivered`.
Le paiement est `pending` dès la création. La livraison seule ne l'encaisse pas.
Après `delivered`, une confirmation explicite le passe à `paid` :

- livraison FlavorWay : uniquement le livreur FlavorWay actif assigné ;
- livraison restaurant : uniquement le propriétaire actif du restaurant concerné.

Les actions API sont `POST /api/v1/courier/orders/{order}/cash-collected` et
`POST /api/v1/restaurant/orders/{order}/cash-collected`. Les panneaux web utilisent
le même service métier. Le client ne peut pas confirmer. Le verrou de commande
sérialise les confirmations ; une répétition restitue le paiement déjà encaissé.
L'historique conserve l'acteur et le mode de livraison.

Promo : `reserved → consumed` à l'encaissement, une seule fois. Une annulation
ou un rejet avant encaissement libère la réservation. Un usage consommé n'est
pas libéré par une annulation tardive ; les fonds nécessitent une réconciliation.

## Retry et callbacks

Un échec confirmé permet un nouvel intent ; une réponse réseau incertaine
conserve l'intent existant. Un intent actif bloque la création d'un second.
Le serveur impose le moyen de paiement et le total enregistrés sur la commande.
Changer de moyen après validation est refusé.

Un succès validé confirme une commande `pending_payment` ou `payment_failed`.
Sur commande annulée, il conserve `cancelled` et marque le paiement
`reconciliation_required`. Deux encaissements externes tardifs sont signalés
pour réconciliation, sans les masquer. Les callbacks dupliqués sont idempotents.
La recherche exige le provider et une référence non ambiguë ; les références
mal formées ou contradictoires sont rejetées.

## Remboursement

`paid`, `reconciliation_required`, `refund_pending` et `refunded` sont distincts.
`refunded` exige une référence justificative. Aucun remboursement opérateur ou
Cash n'est simulé. L'interface provider impose l'authentification du callback
avant normalisation ; les providers MTN/Airtel non configurés refusent les appels.
Aucune signature opérateur réelle n'est implémentée dans ce lot.
