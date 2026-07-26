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

Chaque ligne de cette table représente un compte utilisateur enregistré sur la plateforme, qu'il s'agisse d'un client, d'un restaurateur, d'un employé de restaurant, d'un livreur, d'un membre du support ou d'un administrateur.

Les informations propres aux restaurants, aux commandes, aux paiements ou aux livraisons sont stockées dans leurs tables respectives et reliées à cette table par des relations.

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

---

# Table : user_addresses

## Présentation

La table `user_addresses` permet à chaque utilisateur d'enregistrer plusieurs adresses de livraison.

Les informations relatives aux adresses sont stockées dans une table séparée de la table `users` afin de rendre la plateforme plus flexible et évolutive. Cette séparation permet à un utilisateur de gérer librement ses adresses sans impacter la structure centrale des comptes, et d'associer plusieurs points de livraison à un même client.

## Structure de la table

| Champ | Type | Description |
|---|---|---|
| id | bigint, auto-incrément | Identifiant unique de l'adresse |
| user_id | bigint, foreign key | Identifiant de l'utilisateur propriétaire de l'adresse (clé étrangère vers `users.id`) |
| label | string, nullable | Libellé personnel de l'adresse (ex : Maison, Bureau, Chez un proche) |
| recipient_name | string | Nom du destinataire pour la livraison |
| recipient_phone | string | Numéro de téléphone du destinataire |
| address_line_1 | string | Adresse principale (numéro, rue, quartier) |
| address_line_2 | string, nullable | Complément d'adresse (étage, appartement, point de repère) |
| postal_code | string, nullable | Code postal de la localité |
| city | string | Ville de livraison |
| region | string, nullable | Région ou département |
| country | string | Pays de l'adresse |
| latitude | decimal(10,7), nullable | Latitude pour le géocodage et l'affichage sur la carte |
| longitude | decimal(10,7), nullable | Longitude pour le géocodage et l'affichage sur la carte |
| delivery_instructions | text, nullable | Instructions particulières pour le livreur (code d'accès, sonnette, étage) |
| is_default | boolean, défaut false | Indique si cette adresse est l'adresse par défaut de l'utilisateur |
| is_active | boolean, défaut true | Indique si l'adresse est toujours active et utilisable |
| created_at | timestamp | Date de création de l'adresse |
| updated_at | timestamp | Date de dernière modification |
| deleted_at | timestamp, nullable | Date de suppression logique (Soft Delete Laravel) |

## Index

Les index suivants devront être créés afin d'optimiser les performances :

- Index sur `user_id` pour accélérer la récupération des adresses d'un utilisateur
- Index composé sur `(user_id, is_default)` pour vérifier rapidement l'existence d'une adresse par défaut
- Index sur `is_active` pour filtrer les adresses actives
- Index sur `city` pour les recherches géographiques

Un index spatial ou une stratégie géographique adaptée (comme le calcul de distance basé sur les coordonnées) pourra être ajouté ultérieurement selon le moteur MySQL utilisé et les besoins réels de l'application en matière de recherches de proximité.

## Contraintes

Les règles suivantes devront être respectées :

- Une adresse appartient obligatoirement à un utilisateur (clé étrangère `user_id` non nullable).
- Un utilisateur peut enregistrer plusieurs adresses.
- Un utilisateur ne peut avoir qu'une seule adresse active définie comme adresse par défaut. Lorsqu'une nouvelle adresse devient l'adresse par défaut, toutes les autres adresses du même utilisateur doivent automatiquement passer à `is_default = false`. Cette opération devra être gérée par Laravel dans une transaction afin d'éviter plusieurs adresses par défaut en cas de demandes simultanées.
- Une adresse inactive (`is_active = false`) ou supprimée logiquement (`deleted_at` renseigné) ne peut pas rester définie comme adresse par défaut.
- Une adresse supprimée logiquement ne doit plus être proposée ni utilisée pour les livraisons.
- Le champ `recipient_name` est obligatoire afin de garantir une livraison nominative.
- Le champ `address_line_1` est obligatoire pour assurer une localisation minimale.
- `latitude` et `longitude` doivent être soit toutes les deux renseignées, soit toutes les deux nulles.
- La latitude doit être comprise entre -90 et 90.
- La longitude doit être comprise entre -180 et 180.

## Relations

La table `user_addresses` est reliée aux tables suivantes :

| Table | Type de relation | Description |
|---|---|---|
| users | Une adresse appartient à un seul utilisateur | Chaque adresse est liée à un compte utilisateur via la clé étrangère `user_id` |
| orders | Une adresse peut être sélectionnée lors de la création d'une commande | La table `orders` devra conserver une copie figée des informations de livraison utilisées au moment de la commande. La modification ou la suppression ultérieure de l'adresse dans `user_addresses` ne doit jamais modifier l'historique d'une commande déjà passée. |

## Conclusion

La table `user_addresses` est indispensable au bon fonctionnement des livraisons sur FlavorWay.

Elle permet aux clients d'enregistrer et de gérer facilement leurs lieux de livraison, d'associer des instructions précises pour les livreurs, et de faciliter l'intégration future de fonctionnalités avancées telles que la géolocalisation en temps réel, la suggestion d'adresses récentes ou la validation automatique des zones de livraison.

---

# Table : restaurants

## Présentation

La table `restaurants` contient les informations propres aux établissements présents sur FlavorWay.

Les informations personnelles du propriétaire (nom, email, mot de passe, etc.) restent dans la table `users`. La table `restaurants` contient uniquement les informations commerciales et opérationnelles de l'établissement.

Un utilisateur ayant le rôle `restaurant_owner` peut posséder ou gérer un ou plusieurs restaurants.

Les employés autorisés à gérer l'établissement seront gérés ultérieurement dans une table séparée nommée `restaurant_employees`.

## Structure de la table

| Champ | Type | Description |
|---|---|---|
| id | bigint, auto-incrément | Identifiant unique du restaurant |
| owner_id | bigint, foreign key | Identifiant de l'utilisateur propriétaire du restaurant (clé étrangère vers `users.id`) |
| name | string | Nom commercial de l'établissement |
| slug | string, unique | Identifiant URL unique généré à partir du nom |
| description | text, nullable | Description de l'établissement, de sa cuisine et de son ambiance |
| email | string, nullable | Adresse e-mail de contact du restaurant |
| phone | string | Numéro de téléphone du restaurant |
| logo | string, nullable | URL ou chemin du logo du restaurant |
| cover_image | string, nullable | URL ou chemin de l'image de couverture du restaurant |
| address_line_1 | string | Adresse principale du restaurant |
| address_line_2 | string, nullable | Complément d'adresse |
| postal_code | string, nullable | Code postal |
| city | string | Ville du restaurant |
| region | string, nullable | Région ou département |
| country | string | Pays du restaurant |
| latitude | decimal(10,7), nullable | Latitude pour la localisation sur la carte |
| longitude | decimal(10,7), nullable | Longitude pour la localisation sur la carte |
| currency | string | Devise utilisée par le restaurant. Cette devise est propre au restaurant et permet la gestion d'une plateforme multi-pays. |
| minimum_order_amount | decimal(10,2) | Montant minimum de commande dans la devise du restaurant |
| average_preparation_time | integer | Estimation exprimée en minutes utilisée pour informer les clients et les livreurs du temps de préparation moyen |
| delivery_radius | decimal(10,2), nullable | Rayon de livraison maximal en kilomètres |
| delivery_fee | decimal(10,2) | Frais de livraison de base du restaurant. Le coût réel de livraison pourra ensuite être ajusté selon les règles métier (distance, promotions, zone de livraison, etc.). |
| rating_average | decimal(2,1), défaut 0.0 | Note moyenne calculée automatiquement à partir des avis enregistrés dans la table `reviews`. Cette valeur ne doit jamais être modifiée manuellement. |
| reviews_count | integer, défaut 0 | Nombre total d'avis. Ce compteur est synchronisé automatiquement avec la table `reviews`. Il ne doit jamais être modifié manuellement. |
| status | enum | Statut administratif du restaurant (pending, approved, rejected, suspended, closed) |
| is_open | boolean, défaut true | État opérationnel actuel du restaurant (ouvert ou temporairement fermé) |
| is_featured | boolean, défaut false | Indique si le restaurant est mis en avant dans l'application |
| is_delivery_enabled | boolean, défaut true | Indique si le restaurant accepte les commandes en livraison |
| is_pickup_enabled | boolean, défaut true | Indique si le restaurant accepte les commandes à emporter |
| approved_at | timestamp, nullable | Date à laquelle le restaurant a été approuvé |
| suspended_at | timestamp, nullable | Date à laquelle le restaurant a été suspendu |
| created_at | timestamp | Date de création de l'enregistrement |
| updated_at | timestamp | Date de dernière modification |
| deleted_at | timestamp, nullable | Date de suppression logique (Soft Delete Laravel) |

Pour les champs monétaires (`minimum_order_amount`, `delivery_fee`), les montants utilisent la devise définie dans le champ `currency` du restaurant.

L'utilisation d'un type décimal (`decimal(10,2)`) est recommandée pour les montants afin d'éviter les imprécisions liées aux nombres flottants.

## Statuts possibles

| Statut | Description |
|---|---|
| pending | Le restaurant est en attente de validation par un administrateur. Il ne peut pas encore recevoir de commandes. |
| approved | Le restaurant est approuvé et peut recevoir des commandes et être affiché dans l'application. |
| rejected | La demande d'inscription du restaurant a été refusée par un administrateur. |
| suspended | Le restaurant est temporairement suspendu par un administrateur, par exemple pour non-respect des conditions générales. |
| closed | Le restaurant est définitivement fermé et ne peut plus recevoir de commandes. |

Le champ `status` représente le statut administratif du restaurant. Le champ `is_open` représente uniquement son état opérationnel actuel, par exemple ouvert ou temporairement fermé pour la pause de midi. Ces deux champs ne doivent pas être confondus.

## Index

Les index suivants devront être créés afin d'optimiser les performances :

- Index unique sur `slug`
- Index sur `owner_id` pour accélérer la récupération des restaurants d'un propriétaire
- Index sur `status` pour filtrer par statut administratif
- Index sur `is_open` pour filtrer les restaurants actuellement ouverts
- Index sur `is_featured` pour les restaurants mis en avant
- Index sur `city` pour les recherches par ville
- Index composé sur `(status, is_open)` pour les recherches courantes de restaurants approuvés et ouverts

Pour les coordonnées géographiques, un index spatial ou une stratégie adaptée pourra être ajouté selon les besoins réels de recherche par distance.

## Contraintes

Les règles suivantes devront être respectées :

- Un restaurant appartient obligatoirement à un utilisateur propriétaire (clé étrangère `owner_id` non nullable).
- Le propriétaire doit posséder le rôle `restaurant_owner`.
- Le slug doit être unique.
- `latitude` et `longitude` doivent être soit toutes les deux renseignées, soit toutes les deux nulles.
- La latitude doit être comprise entre -90 et 90.
- La longitude doit être comprise entre -180 et 180.
- Les montants (`minimum_order_amount`, `delivery_fee`) ne peuvent pas être négatifs.
- Le rayon de livraison (`delivery_radius`) ne peut pas être négatif.
- La note moyenne (`rating_average`) doit être comprise entre 0 et 5.
- Le nombre d'avis (`reviews_count`) ne peut pas être négatif.
- Un restaurant non approuvé (`pending`, `rejected`), suspendu (`suspended`) ou fermé administrativement (`closed`) ne doit pas accepter de commande.
- Un restaurant supprimé logiquement ne doit plus être affiché dans l'application.
- `approved_at` doit être renseigné lorsque le restaurant est approuvé (`status = approved`).
- `suspended_at` doit être renseigné lorsque le restaurant est suspendu (`status = suspended`).

## Relations

La table `restaurants` est reliée aux tables suivantes :

| Table | Type de relation | Description |
|---|---|---|
| users | Un restaurant appartient à un seul propriétaire | Le propriétaire du restaurant est un utilisateur ayant le rôle `restaurant_owner` |
| restaurant_employees | Un restaurant peut avoir plusieurs employés | Les employés autorisés à gérer l'établissement (table documentée ultérieurement) |
| product_categories | Un restaurant peut avoir plusieurs catégories de menu | Les catégories organisent les produits du restaurant (table documentée ultérieurement) |
| products | Un restaurant peut proposer plusieurs produits | Les plats, boissons et articles disponibles à la commande (table documentée ultérieurement) |
| orders | Un restaurant reçoit plusieurs commandes | Un restaurant reçoit plusieurs commandes mais les informations importantes utilisées lors de la commande seront conservées dans la table `orders` afin de préserver l'historique, même si les informations du restaurant sont modifiées par la suite. |
| reviews | Un restaurant peut recevoir plusieurs avis | Les avis laissés par les clients permettent de calculer `rating_average` et `reviews_count` |
| promotions | Un restaurant peut proposer plusieurs promotions | Les offres spéciales et réductions proposées par le restaurant (table documentée ultérieurement) |

## Horaires d'ouverture

Les horaires détaillés du restaurant ne doivent pas être stockés directement dans la table `restaurants`.

Ils seront gérés ultérieurement dans une table séparée nommée :

`restaurant_opening_hours`

Cette séparation permettra de gérer :

- plusieurs plages horaires par jour (ex : service midi et service soir) ;
- les jours de fermeture (ex : fermé le lundi) ;
- les horaires exceptionnels (ex : jours fériés) ;
- les changements temporaires (ex : fermeture pour travaux).

## Conclusion

La table `restaurants` est centrale pour la gestion des restaurants, des menus, des commandes et des livraisons sur FlavorWay.

Elle structure l'ensemble des informations opérationnelles et commerciales propres à chaque établissement et constitue la clé de voûte de tout le système de commande, de réservation et de livraison de la plateforme.

---

# Table : restaurant_employees

## Présentation

La table `restaurant_employees` représente les collaborateurs autorisés à accéder à l'espace de gestion d'un restaurant.

Le propriétaire reste enregistré dans la table `users` avec le rôle `restaurant_owner`. Cette table permet d'associer d'autres utilisateurs à un restaurant pour leur donner accès au back-office.

Chaque collaborateur possède un rôle et des permissions spécifiques, ce qui permet une gestion collaborative et évolutive des établissements.

## Structure de la table

| Champ | Type | Description |
|---|---|---|
| id | bigint, auto-incrément | Identifiant unique de l'enregistrement |
| restaurant_id | bigint, foreign key | Identifiant du restaurant (clé étrangère vers `restaurants.id`). Associe le collaborateur à un établissement. |
| user_id | bigint, foreign key | Identifiant de l'utilisateur collaborateur (clé étrangère vers `users.id`). Un employé doit être un utilisateur existant. |
| role | enum | Rôle du collaborateur dans le restaurant (manager, cashier, kitchen, delivery_manager, staff). Définit ses responsabilités principales. |
| permissions | json, nullable | Permissions spécifiques supplémentaires accordées au collaborateur en complément de son rôle. Stocké au format JSON pour gérer des autorisations fines. |
| invited_by | bigint, foreign key | Identifiant de l'utilisateur ayant invité le collaborateur (clé étrangère vers `users.id`). Permet de tracer qui a ajouté chaque employé. |
| invited_at | timestamp | Date d'envoi de l'invitation au collaborateur |
| accepted_at | timestamp, nullable | Date à laquelle le collaborateur a accepté l'invitation. L'accès n'est possible qu'après acceptation. |
| status | enum | Statut de la collaboration (pending, active, suspended, revoked) |
| last_login_at | timestamp, nullable | Date de la dernière connexion du collaborateur au back-office du restaurant |
| created_at | timestamp | Date de création de l'enregistrement |
| updated_at | timestamp | Date de dernière modification |
| deleted_at | timestamp, nullable | Date de suppression logique (Soft Delete Laravel) |

## Rôles possibles

| Rôle | Responsabilités |
|---|---|
| manager | Gestion complète du restaurant : modification des informations, gestion du menu, des employés, des commandes et des promotions |
| cashier | Gestion des commandes en cours, encaissement des paiements sur place et impression des tickets |
| kitchen | Consultation des commandes reçues, mise à jour du statut de préparation des plats |
| delivery_manager | Gestion des livraisons, assignment des livreurs, suivi des courses |
| staff | Accès limité à la consultation des commandes et des horaires |

## Statuts possibles

| Statut | Description |
|---|---|
| pending | L'invitation a été envoyée mais le collaborateur ne l'a pas encore acceptée |
| active | Le collaborateur a accepté l'invitation et peut accéder au back-office du restaurant |
| suspended | L'accès du collaborateur est temporairement suspendu par le propriétaire |
| revoked | L'invitation a été révoquée et le collaborateur ne peut plus accéder au back-office |

## Index

Les index suivants devront être créés afin d'optimiser les performances :

- Index sur `restaurant_id` pour accélérer la récupération des employés d'un restaurant
- Index sur `user_id` pour retrouver les restaurants auxquels un utilisateur est associé
- Index sur `status` pour filtrer les employés actifs ou en attente
- Index sur `role` pour filtrer par rôle
- Index composé sur `(restaurant_id, status)` pour les recherches courantes d'employés actifs par restaurant
- Contrainte d'unicité sur `(restaurant_id, user_id)` pour garantir qu'un même utilisateur ne peut apparaître qu'une seule fois pour un même restaurant

## Contraintes

Les règles suivantes devront être respectées :

- Un collaborateur appartient obligatoirement à un restaurant (clé étrangère `restaurant_id` non nullable).
- Un collaborateur correspond obligatoirement à un utilisateur existant (clé étrangère `user_id` non nullable).
- Un propriétaire (`restaurant_owner`) ne doit jamais apparaître comme employé de son propre restaurant dans cette table.
- Un même utilisateur ne peut apparaître qu'une seule fois pour un même restaurant (contrainte d'unicité sur la paire `restaurant_id`, `user_id`).
- Une invitation doit être acceptée (`accepted_at` renseigné) avant que le collaborateur puisse accéder au back-office.
- Un collaborateur révoqué (`status = revoked`) ou supprimé logiquement ne peut plus accéder au back-office.
- Un collaborateur suspendu (`status = suspended`) ne peut pas accéder au back-office tant que la suspension n'est pas levée par le propriétaire.
- Les permissions attribuées doivent toujours être compatibles avec le rôle défini. Par exemple, un employé avec le rôle `kitchen` ne peut pas recevoir la permission de gérer les paiements.

## Relations

La table `restaurant_employees` est reliée aux tables suivantes :

| Table | Type de relation | Description |
|---|---|---|
| users | Un collaborateur est un utilisateur existant | Chaque employé doit correspondre à un compte utilisateur valide dans la table `users` |
| restaurants | Un collaborateur appartient à un restaurant | Chaque employé est associé à un restaurant spécifique via la clé étrangère `restaurant_id` |

Cette table matérialise une relation de type plusieurs-à-plusieurs entre `users` et `restaurants`, avec des informations supplémentaires sur le rôle, les permissions et le statut de chaque collaboration.

## Sécurité

La gestion des collaborateurs implique des règles de sécurité strictes :

- Toutes les actions des collaborateurs devront être contrôlées par leurs permissions respectives.
- Certaines actions sensibles devront rester exclusivement réservées au `restaurant_owner` : suppression du restaurant, gestion des moyens de paiement, modification du propriétaire, suppression définitive des employés.
- Les permissions seront vérifiées côté Laravel via un système de policies ou de gates, garantissant que chaque collaborateur ne peut effectuer que les actions autorisées par son rôle et ses permissions.

## Conclusion

La table `restaurant_employees` est indispensable pour permettre à plusieurs personnes de gérer un même restaurant tout en conservant une architecture sécurisée et évolutive.

Elle permet au propriétaire d'inviter et de gérer les accès de son équipe sans partager son mot de passe, garantit que chaque collaborateur ne dispose que des droits nécessaires à ses responsabilités, et facilite la délégation des tâches quotidiennes au sein de l'établissement.
