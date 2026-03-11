import 'package:flutter/material.dart';

// Couleur principale MCT
const Color _primaryColor = Color(0xFF0a543d);

class CGUCGVScreen extends StatefulWidget {
  const CGUCGVScreen({super.key});

  @override
  State<CGUCGVScreen> createState() => _CGUCGVScreenState();
}

class _CGUCGVScreenState extends State<CGUCGVScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryColor,
              _primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CGU & CGV',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Conditions Générales',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tabs style pill
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: _primaryColor,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  splashBorderRadius: BorderRadius.circular(25),
                  overlayColor:
                      WidgetStateProperty.all(Colors.white.withOpacity(0.1)),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline, size: 18),
                          SizedBox(width: 8),
                          Text('CGU'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('CGV'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCGUContent(),
                      _buildCGVContent(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCGUContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Conditions Générales d\'Utilisation'),
          const SizedBox(height: 8),
          _buildLastUpdate('Dernière mise à jour : Février 2026'),
          const SizedBox(height: 24),
          _buildArticle(
            '1. Objet',
            'Les présentes Conditions Générales d\'Utilisation (CGU) régissent l\'utilisation '
                'de l\'application mobile Smart Maintenance, éditée par MCT.\n\n'
                'L\'application permet aux utilisateurs de :\n'
                '• Demander des interventions de maintenance et dépannage\n'
                '• Commander des pièces et équipements\n'
                '• Souscrire à des offres d\'entretien\n'
                '• Suivre l\'état de leurs demandes en temps réel',
          ),
          _buildArticle(
            '2. Acceptation des CGU',
            'L\'utilisation de l\'application implique l\'acceptation pleine et entière '
                'des présentes CGU. En créant un compte ou en utilisant nos services, '
                'vous reconnaissez avoir lu, compris et accepté ces conditions.',
          ),
          _buildArticle(
            '3. Inscription et Compte Utilisateur',
            '• L\'inscription est gratuite et nécessite un numéro de téléphone valide\n'
                '• Vous êtes responsable de la confidentialité de vos identifiants\n'
                '• Les informations fournies doivent être exactes et à jour\n'
                '• Un compte est strictement personnel et ne peut être cédé',
          ),
          _buildArticle(
            '4. Utilisation des Services',
            'L\'utilisateur s\'engage à :\n'
                '• Utiliser l\'application conformément à sa destination\n'
                '• Ne pas perturber le fonctionnement de l\'application\n'
                '• Respecter les droits des autres utilisateurs\n'
                '• Ne pas transmettre de contenu illicite ou offensant',
          ),
          _buildArticle(
            '5. Propriété Intellectuelle',
            'L\'ensemble des éléments de l\'application (logos, textes, images, etc.) '
                'sont la propriété exclusive de MCT. Toute reproduction, '
                'représentation ou exploitation sans autorisation est interdite.',
          ),
          _buildArticle(
            '6. Protection des Données Personnelles',
            'Conformément à la réglementation en vigueur, MCT s\'engage à :\n'
                '• Collecter uniquement les données nécessaires au service\n'
                '• Ne jamais vendre vos données à des tiers\n'
                '• Sécuriser vos informations personnelles\n'
                '• Vous permettre d\'exercer vos droits (accès, rectification, suppression)',
          ),
          _buildArticle(
            '7. Responsabilité',
            'MCT ne saurait être tenue responsable :\n'
                '• Des interruptions temporaires de service\n'
                '• Des dommages indirects liés à l\'utilisation de l\'application\n'
                '• Des actions des prestataires tiers\n\n'
                'L\'utilisateur est seul responsable de l\'utilisation qu\'il fait de l\'application.',
          ),
          _buildArticle(
            '8. Modification des CGU',
            'MCT se réserve le droit de modifier les présentes CGU à tout moment. '
                'Les utilisateurs seront informés des modifications significatives. '
                'La poursuite de l\'utilisation vaut acceptation des nouvelles conditions.',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCGVContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Conditions Générales de Vente'),
          const SizedBox(height: 8),
          _buildLastUpdate('Dernière mise à jour : Février 2026'),
          const SizedBox(height: 24),
          _buildArticle(
            '1. Objet',
            'Les présentes Conditions Générales de Vente (CGV) régissent les relations '
                'commerciales entre Smart Maintenance (MCT) et ses clients pour :\n'
                '• Les prestations de maintenance et dépannage\n'
                '• La vente de pièces et équipements\n'
                '• Les abonnements aux offres d\'entretien',
          ),
          _buildArticle(
            '2. Prix et Tarification',
            '• Les prix sont indiqués en Francs CFA (FCFA), toutes taxes comprises\n'
                '• Les frais de diagnostic sont facturés selon les tarifs en vigueur\n'
                '• Les prix peuvent être modifiés à tout moment, sans préavis\n'
                '• Le prix applicable est celui en vigueur au moment de la commande',
          ),
          _buildArticle(
            '3. Commandes et Devis',
            '• Toute intervention fait l\'objet d\'un devis préalable\n'
                '• Le client dispose de 7 jours pour accepter ou refuser un devis\n'
                '• L\'acceptation du devis vaut engagement ferme\n'
                '• Les modifications après acceptation peuvent entraîner des frais supplémentaires',
          ),
          _buildArticle(
            '4. Modalités de Paiement',
            'Les paiements peuvent être effectués par :\n'
                '• Mobile Money (Orange Money, MTN Money, Wave, Moov Money)\n'
                '• Carte bancaire (Visa, MasterCard)\n'
                '• Virement bancaire (sur demande)\n\n'
                'Le paiement est exigible à la confirmation de la commande ou à la '
                'réception du service selon les conditions du devis.',
          ),
          _buildArticle(
            '5. Délais d\'Intervention',
            '• Les délais sont donnés à titre indicatif\n'
                '• En cas d\'urgence, une intervention sous 24h peut être demandée (frais majorés)\n'
                '• Les retards dus à des causes externes ne sauraient engager notre responsabilité\n'
                '• Le client sera informé en cas de retard prévisible',
          ),
          _buildArticle(
            '6. Garanties',
            '• Les pièces neuves sont garanties 12 mois\n'
                '• Les pièces reconditionnées sont garanties 6 mois\n'
                '• La main d\'œuvre est garantie 3 mois\n'
                '• La garantie ne couvre pas les dommages causés par une mauvaise utilisation',
          ),
          _buildArticle(
            '7. Réclamations et SAV',
            '• Toute réclamation doit être formulée dans les 48h suivant l\'intervention\n'
                '• Les réclamations peuvent être soumises via l\'application\n'
                '• MCT s\'engage à traiter les réclamations sous 72h ouvrées\n'
                '• En cas de litige, une solution amiable sera privilégiée',
          ),
          _buildArticle(
            '8. Annulation et Remboursement',
            '• L\'annulation est gratuite jusqu\'à 24h avant l\'intervention prévue\n'
                '• Au-delà, des frais d\'annulation de 20% peuvent s\'appliquer\n'
                '• Les remboursements sont effectués sous 7 à 14 jours ouvrés\n'
                '• Le mode de remboursement dépend du mode de paiement initial',
          ),
          _buildArticle(
            '9. Offres d\'Entretien',
            '• Les abonnements sont souscrits pour une durée déterminée\n'
                '• Le renouvellement est automatique sauf résiliation\n'
                '• La résiliation doit être faite au moins 30 jours avant l\'échéance\n'
                '• Les avantages sont valables uniquement pendant la période d\'abonnement',
          ),
          _buildArticle(
            '10. Litiges et Droit Applicable',
            'Les présentes CGV sont soumises au droit ivoirien. En cas de litige, '
                'les parties s\'engagent à rechercher une solution amiable avant toute '
                'action judiciaire. À défaut, les tribunaux d\'Abidjan seront seuls compétents.',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: _primaryColor,
      ),
    );
  }

  Widget _buildLastUpdate(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: _primaryColor.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildArticle(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
