# Livreur mobile — LOT 8 phase B

Flutter possède une entrée Laravel distincte `/courier/login`. Aucun appel Firebase Auth n’est utilisé par `CourierSessionService`. Firebase Messaging reste le transport push partagé avec le client.

## Session et permissions

L’Admin crée le compte et génère son mot de passe temporaire. `POST /api/v1/courier/login` n’accepte que les comptes livreur actifs de type `restaurant` ou `flavorway`; le restaurant associé doit être actif. Les jetons aléatoires 256 bits sont stockés sous forme SHA-256 côté serveur et dans le stockage chiffré du système côté mobile. Ils expirent après 30 jours. Chaque requête contrôle `courier_session_version`, le rôle et le statut actuels. La réinitialisation Admin invalide donc les anciennes sessions.

Si `must_change_password=true`, seuls `me`, `password` et `logout` restent disponibles. Le nouveau mot de passe exige 12 caractères, lettres et chiffres. Le changement invalide les autres sessions et renouvelle le jeton actuel. Logout révoque le jeton et désactive son enregistrement FCM. En cas d’échec réseau, l’application ne prétend pas que la révocation serveur a réussi.

Seul le téléphone peut être édité dans le profil. Les autres propriétés sont administrées sur le Web.

## Assignation manuelle : une règle serveur

`CourierEligibilityService` est utilisé par le formulaire Admin et `OrderPlacementService`.

- Disponible signifie compte actif et aucune **autre** commande `confirmed`, `preparing`, `ready`, `picked_up`, `on_the_way` assignée. Il ne s’agit pas d’une présence GPS ou d’un statut connecté.
- Un compte restaurant disponible et rattaché à ce restaurant est prioritaire. Aucun nombre déclaré de livreurs n’intervient.
- En l’absence de tel compte, les comptes FlavorWay actifs sans rattachement restaurant et sans autre livraison sont candidats.
- Une commande finale, en transit, en attente de paiement, ou de mode inconnu n’est pas assignable.
- La règle s’applique aux deux snapshots. `delivery_mode_snapshot` reste le snapshot **tarifaire** inchangé; `courier_routing_type` enregistre l’acteur choisi lors de l’assignation. Les frais et le total ne changent pas.
- Les anciennes assignations sans ce nouveau champ conservent leur contrôle strict de mode; une ancienne combinaison incohérente n’est pas transformée implicitement en fallback.
- Les règles de priorité ne sont pas recalculées pendant la livraison ou l’historique : la disparition ou le retour d’un autre livreur ne retire pas une commande déjà attribuée.
- Les lignes des comptes candidats sont verrouillées lors de l’assignation. Une réassignation conserve l’exigence du livreur attendu et d’un motif.

Les opérations utilisent `Order::forCourier`, `OrderPlacementService::advanceForCourier`, `OrderStatusTransitionService` et `CashCollectionService`. Les actions affichées sont calculées par Laravel. Aucun montant ou statut financier n’est envoyé par Flutter. L’encaissement demande une confirmation explicite et n’est possible qu’après livraison; il est idempotent. Le livreur restaurant assigné peut maintenant encaisser sa commande; l’action propriétaire restaurant préexistante est conservée.

## Notifications et historique

Les événements d’assignation et `ready` alimentent les notifications Laravel, puis FCM. Le token device est rattaché à la session Laravel. Le worker refuse l’envoi si la session est expirée/révoquée, le compte est désactivé ou la commande a été réassignée. Un clic courier ouvre `/courier/order` derrière le contrôle de session et de mot de passe obligatoire. Les timelines affichées proviennent de `status_history` du même `OrderResource`.

L’historique est paginé côté serveur (20 entrées) et comprend `delivered`, `cancelled`, `payment_failed`. Le dashboard compte les assignations du jour selon `assigned_at` et affiche le Cash restant des commandes non annulées. Le détail distingue sous-total, frais de livraison et total; il n’invente aucune rémunération livreur.

## Compatibilité conservée

Le portail Web `/courier/*` est **LEGACY / SECOURS TECHNIQUE**. Il reste présent et utilise les services métier communs. Aucune refonte de son interface dans ce lot.

Écrans restaurateur Flutter conservés, à retirer ou rediriger dans un lot ultérieur :

- `lib/screens/restaurant_owner/restaurant_owner_login_screen.dart`
- `lib/screens/restaurant_owner/restaurant_dashboard_screen.dart`
- `lib/screens/restaurant_owner/edit_menu_screen.dart`
- `lib/screens/restaurant_owner/edit_restaurant_screen.dart`
- `lib/screens/restaurant_owner/edit_gallery_screen.dart`
- `lib/screens/restaurateur/restaurant_dashboard_screen.dart`
- `lib/screens/restaurateur/restaurant_orders_screen.dart`
- `lib/screens/restaurateur/restaurant_reservations_screen.dart`

Les routes et imports legacy sont conservés; ce lot ne prétend pas les avoir supprimés.

## Recette

La commande `FW-20260916-000001` doit être assignée par le formulaire Admin puis traitée depuis Flutter. Aucune commande réelle n’est créée par l’implémentation ou les tests (fixtures SQLite isolées seulement). Ne jamais ajuster directement son statut en base. La réception FCM sur appareil et le parcours réel restent des validations distinctes des tests automatisés.

Validation du lot : migrations MySQL locales appliquées; Laravel 340 tests / 1 784 assertions PASS; Flutter 153 tests PASS; analyse 0 erreur, 0 warning, 173 infos; APK debug généré avec succès. ADB ne détecte aucun appareil lors de cette validation. Lecture locale : Test COURIER (id 12) actif, FlavorWay, éligible; commande de recette toujours ready, Cash unpaid, total 11 000, sans assignation. La recette réelle et la réception FCM sur appareil restent en attente; aucun statut de cette commande n’a été modifié.
