# 🏆 RAPPORT D'AUDIT MULTI-EXPERTS COMPLET — OPENFOOD
### *Réalisé par le Collège des 15 Agents Experts de l'Usine Logicielle Cooking Data*
*Date : 14 Septembre 2026 — Statut : Rapport d'Audit Pré-Production*

---

## 🏛️ 1. Pôle Ingénierie & Modularité (Avis Architect-Agent & Dev-Agent)

### ✅ Ce qui est très bien conçu :
1. **Séparation Découplée en 3 Frontends Métiers :**
   - L'isolation en 3 applications distinctes (`openfood-mobile`, `openfood-admin`, `openfood-restaurateur`) est un excellent choix architectural. Cela évite d'embarquer les privilèges et la logique d'administration dans l'APK/IPA client grand public.
2. **Package de Modèles Partagés (`openfood-models`) :**
   - Les objets `OrderModel`, `ProductModel`, `RestaurantModel`, `Promotion`, etc., sont centralisés et typés, ce qui élimine les désynchronisations de schémas entre le mobile et le web.
3. **Architecture Temps Réel Firestore :**
   - Utilisation judicieuse des `StreamBuilder` pour les commandes en direct côté restaurateur (`live_orders_tab.dart`) avec déclenchement audio (`audioplayers`).
4. **Fallback & Résilience Plateformes :**
   - Présence de contournements conditionnels propres pour le Web et Desktop (`kIsWeb || defaultTargetPlatform == TargetPlatform.windows`), permettant de développer et tester sans crash du SDK natif Stripe.

### ⚠️ Ce qu'il manque & Dette Technique à corriger :
1. **Nettoyage des Fichiers Résiduels dans le Mobile :**
   - Présence de reliquats d'une ancienne tentative web Next.js (`apps/mobile/package.json`, `next.config.ts`, `src/components/ui/`, `tailwind.config.ts`). À supprimer ou isoler pour alléger le dépôt mobile de plus de 15 000 lignes de JSON et TS inutiles.
   - Présence de scripts de test/patch (`fix_db.dart`, `fix_db2.dart`, `test_firebase.dart`) dans `lib/`.
2. **Gestion d'État Hybride (Provider + StatefulWidgets) :**
   - La plupart des écrans utilisent des `setState` locaux volumineux couplés à `CartProvider` et `LocationProvider`. Pour scaler à plus de 50 restaurants et 1 000 commandes/jour, migrer progressivement vers un pattern plus robuste (Riverpod ou Bloc).
3. **Pagination & Requêtes Lourdes :**
   - Actuellement, les collections `restaurants` et `orders` sont parfois lues sans `limit(20)`. Risque de surcoût Firestore si la base grossit.

---

## 🛡️ 2. Pôle Sécurité & Cloud (Avis CyberSec-Agent & Cloud-Agent)

### ✅ Ce qui est bien sécurisé :
1. **Paiement Stripe Connect avec Capture Manuelle :**
   - Le secret Stripe (`sk_live_...` / `sk_test_...`) n'est **JAMAIS** exposé dans l'application mobile. Il est confiné dans les Cloud Functions Firebase.
   - Le flux en deux temps (`PaymentIntent` en capture manuelle ➔ `capture` uniquement après validation du restaurant) empêche les fraudes et élimine les frais de rétro-facturation en cas de refus d'un plat.
2. **Contrôle d'accès aux Analytics :**
   - Les événements analytics ne peuvent être que créés par les clients et ne sont lisibles/modifiables que par les administrateurs.

### 🚨 Vulnérabilités Critiques à combler avant la Production :
1. **Faille Majeure dans `firestore.rules` :**
   ```javascript
   function isAdmin() {
     return isAuthenticated(); // ⚠️ DANGER CRITIQUE : Tout utilisateur connecté est considéré comme Admin !
   }
   ```
   - **Impact :** Un client authentifié peut actuellement modifier les prix des produits (`/products`), modifier les stocks (`/inventory`) ou altérer les métadonnées des restaurants.
   - **Correction Immédiate requise :**
     ```javascript
     function isAdmin() {
       return isAuthenticated() && (request.auth.token.admin == true || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
     }
     ```
2. **Règles d'écriture sur les Commandes (`/orders`) :**
   - `allow read, write: if isAuthenticated();` permet à n'importe quel client de lire ou de modifier le statut de la commande d'un autre client.
   - **Correction :** Restreindre la lecture à `resource.data.userId == request.auth.uid || isAdmin() || isRestoOwner(resource.data.restaurantId)`.

---

## ⚖️ 3. Pôle Juridique & Réglementaire (Avis Legal-Agent)

### 📋 Obligations Légales Spécifiques FoodTech & Marketplace (France & DOM) :

1. **Qualification Juridique de la Plateforme (Statut Marketplace / Courtier) :**
   - OpenFood agit en qualité d'**intermédiaire transparent** mettant en relation des clients, des restaurateurs indépendants et des livreurs.
   - **Indispensable :** Rédaction de **3 jeux de CGU/CGV distincts** :
     - *CGV Clients :* Droit de rétractation (exclu pour les denrées périssables selon l'Art. L. 221-28 du Code de la Consommation), délais de livraison, réclamations.
     - *CGU Restaurateurs :* Taux de commission, engagement sur les normes d'hygiène (HACCP), délais d'acceptation.
     - *Contrat de Prestation Livreurs :* Indépendance juridique (auto-entrepreneurs), conformité URSSAF, assurance responsabilité civile professionnelle circulation.
2. **Affichage Obligatoire des Allergènes (Règlement INCO N° 1169/2011) :**
   - Obligation légale d'indiquer la présence des **14 allergènes majeurs** (gluten, crustacés, arachides, lait, etc.) sur chaque fiche produit.
3. **Conformité RGPD & Données Géographiques :**
   - La géolocalisation en temps réel du livreur et du client constitue une donnée hautement sensible : obligation de recueillir le consentement explicite et d'interrompre le tracking dès la commande livrée.
   - Mentions obligatoires : Responsable de traitement, durée de conservation (3 ans max pour les comptes inactifs), droit de suppression.

---

## 💰 4. Pôle Comptabilité, Fiscalité & Modèle Financier (Avis FinOps & DBA)

### 📊 Ventilation de la TVA et Facturation Marketplace :

1. **Régime de TVA Mixte sur la Restauration en Martinique :**
   - Attention aux taux de TVA applicables dans les DOM (Martinique : taux réduit à **2,1%** ou **8,5%** selon les produits, contre 5.5% et 10% en métropole) :
     - *Alimentation immédiate / plats chauds :* TVA réduite.
     - *Boissons alcoolisées :* TVA au taux normal (8,5% en Martinique / 20% métropole).
     - *Prestation de livraison OpenFood :* Facturation de la commission avec TVA sur services.
2. **Schéma de Facturation Triple :**
   - **Facture 1 (Restaurant ➔ Client) :** Porte sur les plats et boissons (émise au nom du restaurant).
   - **Facture 2 (Livreur / OpenFood ➔ Client) :** Porte sur les frais de livraison.
   - **Facture 3 (OpenFood ➔ Restaurant) :** Facture de commission de service (ex: 15% ou 20% HT) prélevée automatiquement via Stripe Connect Application Fee.
3. **Recommandation Stripe Connect :**
   - Utiliser le paramètre `application_fee_amount` dans `createOrderPaymentIntent` pour encaisser automatiquement la commission OpenFood sur chaque transaction sans manipulation bancaire manuelle.

---

## 📈 5. Synthèse & Feuille de Route de Mise en Production

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 🎯 SCORE GLOBAL DE MATURITÉ : 7.8 / 10 (TRÈS BONNE BASE MVP PRÊTE POUR LE DURCISSEMENT)        │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ • Architecture & Concept Métier : 9/10  (Parcours complet, Stripe Connect, multi-rôles)         │
│ • Sécurité Firestore & Tokens   : 5/10  (Règles à verrouiller impérativement)                   │
│ • Propreté du Code              : 7/10  (Supprimer reliquats Next.js, uniformiser les imports)  │
│ • Conformité Juridique / Fiscale : 6/10  (Ajouter CGV, TVA DOM et affichage allergènes)          │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```
