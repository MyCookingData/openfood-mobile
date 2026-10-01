import 'package:flutter/material.dart';
import '../../core/theme.dart';

class LegalViewerScreen extends StatelessWidget {
  final int initialTabIndex;

  const LegalViewerScreen({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: initialTabIndex.clamp(0, 3),
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.cream, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Informations Légales & CGU",
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppTheme.cream,
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.greenXl,
            indicatorWeight: 3,
            labelColor: AppTheme.greenXl,
            unselectedLabelColor: AppTheme.muted2,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(text: "CGU / CGV"),
              Tab(text: "Remboursements"),
              Tab(text: "Abonnements Win"),
              Tab(text: "Mentions & RGPD"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CguTab(),
            _RemboursementTab(),
            _AbonnementsTab(),
            _MentionsTab(),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1 : CGU / CGV
// -------------------------------------------------------------
class _CguTab extends StatelessWidget {
  const _CguTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBadge("Conditions Générales d'Utilisation et de Vente", Icons.gavel_rounded),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: "1. Préambule & Société Éditrice",
            content:
                "Les présentes CGU régissent l'utilisation de l'Application et du Site OpenFood, édités et exploités par la société N2D NEW DELIVERY DRIVER, SAS au capital enregistrée au RCS de Fort-de-France sous le n° 992 130 476, dont le siège social est situé au 24, rue de l'enclos, 97222 Case-Pilote, Martinique.\n\nL'utilisation de la plateforme emporte acceptation pleine et entière des présentes conditions.",
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            title: "2. Services Fournis",
            content:
                "• Service d'intermédiation : mise en relation avec les Restaurants partenaires et Livreurs indépendants.\n• Service de commande & Click and Collect.\n• Service de paiement sécurisé pour le compte des restaurants tiers.\n• Frais de service : 5% du montant de la commande.\n• Taux de TVA : 2,1% (nourriture/boissons sans alcool) et 8,5% (alcool).",
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            title: "3. Commandes & Vente d'Alcool",
            content:
                "• L'achat d'alcool est formellement interdit aux mineurs de moins de 18 ans (art. L. 3342-1 du Code de la santé publique).\n• Le livreur est en droit d'exiger un justificatif d'identité avec photo.\n• En cas de refus ou de minorité, aucun produit alcoolisé ne sera remis et aucun remboursement ne sera dû.",
            isWarning: true,
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            title: "4. Livraison & Réception",
            content:
                "• L'adresse de livraison saisie doit être exacte et complète.\n• Si le Client ne se présente pas lors de l'arrivée notifiée du livreur ou avant la fermeture du restaurant (Click & Collect), la commande reste intégralement due et non remboursée.",
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 2 : REMBOURSEMENTS & ANNULATION
// -------------------------------------------------------------
class _RemboursementTab extends StatelessWidget {
  const _RemboursementTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBadge("Politique de Remboursement & Réclamations", Icons.assignment_return_rounded),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: "Indisponibilité d'un Produit",
            content:
                "Si un article commandé est en rupture en cuisine, le Restaurant vous contactera pour proposer une alternative équivalente. En cas de refus, N2D NEW DELIVERY DRIVER procédera au remboursement du produit manquant dans les meilleurs délais (ou sous forme d'avoir avec votre accord).",
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            title: "Produit Non-Conforme & Délai de 24h",
            content:
                "Toute réclamation relative à une non-conformité (produit endommagé, plat erroné) doit impérativement être transmise dans un délai maximal de 24 heures après la livraison.\n\n⚠️ OBLIGATION : La réclamation doit obligatoirement être accompagnée d'une photographie nette du produit et de la commande (via WhatsApp ou openfoodfwi@gmail.com). Sans photo, aucune réclamation ne pourra être instruite.",
            isWarning: true,
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            title: "Exclusions Fermes de Remboursement",
            content:
                "Aucun remboursement ne sera accordé dans les situations suivantes :\n1. Absence du client au point de livraison à l'arrivée notifiée du livreur.\n2. Non-retrait d'une commande Click & Collect avant la fermeture du restaurant.\n3. Présentation d'un mineur pour la récupération d'une commande d'alcool.",
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            title: "Annulation & Droit de Rétractation",
            content:
                "Une fois la commande acceptée par le restaurant, aucune annulation n'est possible. Conformément à l'art. L.221-18 du Code de la consommation, le droit de rétractation de 14 jours est exclu pour les denrées périssables et repas préparés.",
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 3 : ABONNEMENTS OPEN WIN
// -------------------------------------------------------------
class _AbonnementsTab extends StatelessWidget {
  const _AbonnementsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBadge("Offres & Formules Abonnés", Icons.workspace_premium_rounded),
          const SizedBox(height: 16),
          _buildPlanCard(
            title: "OpenFood WIN",
            price: "2,99 €",
            color: AppTheme.gold,
            features: [
              "Participation offerte aux jeux concours",
              "Accès aux réductions & offres privées flash",
              "1 code promo spécial anniversaire (-10%)",
              "1 € de cashback offert dès l'abonnement",
            ],
          ),
          const SizedBox(height: 14),
          _buildPlanCard(
            title: "OpenFood SMART",
            price: "5,99 €",
            color: AppTheme.greenXl,
            isPopular: true,
            features: [
              "Tous les avantages OpenFood WIN",
              "1% de cashback offert sur chaque commande",
              "5% de réduction directe sur vos commandes",
            ],
          ),
          const SizedBox(height: 14),
          _buildPlanCard(
            title: "OpenFood MAX",
            price: "9,99 €",
            color: AppTheme.gold,
            features: [
              "Tous les avantages OpenFood WIN",
              "3% de cashback offert sur chaque commande",
              "10% de réduction directe sur les plats",
              "1 livraison gratuite par mois (rayon ≤ 5 km)",
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 4 : MENTIONS LÉGALES & RGPD
// -------------------------------------------------------------
class _MentionsTab extends StatelessWidget {
  const _MentionsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBadge("Mentions Légales & Protection des Données", Icons.security_rounded),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: "Identité de la Société",
            content:
                "• Dénomination : N2D NEW DELIVERY DRIVER SAS\n• RCS : Fort-de-France 992 130 476\n• Siège social : 24, rue de l'enclos, 97222 Case-Pilote, Martinique\n• Contact SAV / DPO : openfoodfwi@gmail.com & WhatsApp\n• Site web : https://www.openfood.fr",
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            title: "Protection des Données (RGPD)",
            content:
                "Vos données personnelles (nom, email, téléphone, coordonnées GPS de livraison) sont collectées uniquement pour la finalité de préparation, livraison et facturation de vos commandes.\n\nVous disposez d'un droit d'accès, de rectification et d'effacement auprès de notre délégué à la protection des données par email à openfoodfwi@gmail.com.",
          ),
          const SizedBox(height: 14),
          _buildCookingDataCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  static Widget _buildCookingDataCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: AppTheme.gold, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Conception & Ingénierie Logicielle",
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Application et plateformes conçues et développées par :",
            style: TextStyle(color: AppTheme.muted2, fontSize: 12),
          ),
          const SizedBox(height: 6),
          const Text(
            "Cooking Data (EIRL)",
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: AppTheme.cream,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const Text(
            "« Créateur de solutions informatiques sur-mesure à votre écoute »",
            style: TextStyle(
              color: AppTheme.gold,
              fontStyle: FontStyle.italic,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "📍 Le Lamentin (97232) • Martinique 🇲🇶\n✉️ contact@cookingdata.fr\n🌐 cookingdata.fr",
            style: TextStyle(
              color: AppTheme.cream,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// HELPERS & WIDGETS DE DESIGN
// -------------------------------------------------------------
Widget _buildHeaderBadge(String title, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border2),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppTheme.greenXl, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: AppTheme.cream,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildSectionCard({
  required String title,
  required String content,
  bool isWarning = false,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isWarning ? AppTheme.red.withValues(alpha: 0.10) : AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isWarning ? AppTheme.redL.withValues(alpha: 0.40) : AppTheme.border,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isWarning ? AppTheme.redL : AppTheme.greenXl,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: AppTheme.cream,
            fontSize: 12.5,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

Widget _buildPlanCard({
  required String title,
  required String price,
  required Color color,
  required List<String> features,
  bool isPopular = false,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isPopular ? color.withValues(alpha: 0.6) : AppTheme.border,
        width: isPopular ? 1.5 : 1.0,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: color,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppTheme.cream,
                  ),
                ),
                const Text(
                  " /mois",
                  style: TextStyle(color: AppTheme.muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        const Divider(color: AppTheme.surface3, height: 20),
        ...features.map((feat) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.greenXl, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feat,
                      style: const TextStyle(color: AppTheme.cream, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            )),
      ],
    ),
  );
}
