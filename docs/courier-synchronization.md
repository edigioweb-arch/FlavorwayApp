# LOT 6 — Livreur et synchronisation

Laravel/MySQL conserve la commande et `order_status_histories`. Il n'y a aucune
nouvelle machine à états ni copie de commande côté notification.

## Comptes et droits

L'admin crée les comptes courier FlavorWay ou restaurant, choisit la ville et
le restaurant pour le second type. Un mot de passe aléatoire non affiché protège
le compte avant invitation. Le lien de définition de mot de passe est à usage
unique. L'envoi réel de l'invitation requiert la configuration mail existante.
Le formulaire restaurateur indique seulement une capacité de livreurs prévue.

Le livreur peut modifier son téléphone uniquement. La modification admin de son
type ou rattachement est refusée tant que des livraisons ou un Cash livré restent
à clôturer. Un compte inactif ne peut pas lire le panneau ni effectuer d'action.

## Assignation et livraison

Assignation : `confirmed`, `preparing`, `ready`. Une répétition à l'identique
n'ajoute pas d'historique. Réassignation : admin uniquement, avant pickup, avec
ID du livreur actuel et motif. La transaction verrouille la commande puis le
livreur. Chaque affectation conserve l'acteur, l'ancien et le nouveau livreur,
la date et le motif dans la timeline ; `assigned_at` donne la dernière affectation.

Le livreur assigné peut uniquement déclencher :
`ready → picked_up → on_the_way → delivered`.
Les lectures vérifient à la fois l'assignation, le type et le restaurant.
`/courier/history` exclut les commandes actives et possède une pagination.
Le dashboard compte toutes les commandes actives, même créées un jour précédent.

Le Cash reste en attente après livraison. Les règles du lot 5 s'appliquent :
encaissement par le livreur FlavorWay assigné ou par le propriétaire du restaurant
pour une livraison restaurant. Aucun revenu livreur n'est déduit des frais client.

## Notifications et affichage

Les changements de timeline créent les notifications stockées existantes ; les
jobs FCM ne sont envoyés qu'après commit. Une transaction annulée annule aussi
la notification. Les listeners de création/annulation utilisent la découverte
Laravel sans seconde inscription manuelle.

Payload : `type`, `order_id`, `order_number`, `status`, `destination`.
Le clic client utilise `order_number`, car c'est la clé de route Laravel. Un
payload incomplet ou destiné à un autre rôle ouvre les notifications, sans créer
ni inventer une commande. Une commande introuvable reste une erreur serveur.
Le clic au démarrage est conservé jusqu'à disponibilité du navigateur.

Polling : suivi client existant ; restaurant mobile et web toutes les 15 secondes ;
livreur web toutes les 20 secondes hors saisie. Les actions relisent la réponse
serveur. Les écrans présentent la même timeline, sans websocket.

## Validation externe

Tester sur appareil Android les notifications foreground/background/terminated,
les permissions et le renouvellement du token, avec FCM configuré et worker de
queue actif. Vérifier aussi la délivrabilité email de l'invitation. APNs réel,
GPS, carte live, MTN/Airtel réels et chat restent hors de ce lot.
