import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/common/support_fab_wrapper.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  int? _expandedIndex;

  final List<Map<String, String>> _faqs = [
    // Interventions
    {
      'question': 'Comment créer une demande d\'intervention ?',
      'answer':
          'Depuis l\'onglet "Interventions", appuyez sur le bouton "+" en bas à droite. Sélectionnez le type d\'intervention (Entretien, Dépannage, Installation ou Diagnostic), décrivez votre problème et soumettez votre demande. Un technicien vous sera assigné rapidement.',
    },
    {
      'question': 'Quels sont les types d\'interventions disponibles ?',
      'answer':
          '• Entretien : maintenance préventive de vos équipements\n• Dépannage : en cas de panne ou dysfonctionnement\n• Installation : pour installer de nouveaux équipements\n• Diagnostic : pour identifier un problème technique (frais de diagnostic payable en ligne)',
    },
    {
      'question': 'Comment suivre l\'état de mes interventions ?',
      'answer':
          'L\'onglet "Interventions" affiche toutes vos demandes avec leur statut en temps réel : En attente, Assignée, En cours, Terminée. Appuyez sur une intervention pour voir les détails, le technicien assigné et les images.',
    },
    {
      'question': 'Comment payer les frais de diagnostic ?',
      'answer':
          'Après un diagnostic, vous recevrez une notification pour payer les frais. Accédez aux détails de l\'intervention et appuyez sur "Payer le diagnostic". Le paiement se fait directement dans l\'application via FineoPay.',
    },
    {
      'question': 'Comment noter un technicien après une intervention ?',
      'answer':
          'Après la clôture d\'une intervention, une popup vous invite à noter le technicien (1 à 5 étoiles) et laisser un commentaire. Vous pouvez aussi noter plus tard depuis les détails de l\'intervention.',
    },
    // Boutique
    {
      'question': 'Comment acheter des équipements dans la boutique ?',
      'answer':
          'Allez dans "Boutique", parcourez les produits par catégorie, ajoutez au panier les articles souhaités, puis validez votre commande. Le paiement s\'effectue directement dans l\'application via FineoPay sécurisé.',
    },
    {
      'question': 'Comment payer mes commandes ?',
      'answer':
          'Lors du paiement, vous êtes redirigé vers une page FineoPay intégrée dans l\'application. Choisissez votre mode de paiement (Mobile Money, carte, etc.), effectuez le paiement, puis appuyez sur "J\'ai effectué le paiement". La vérification est automatique.',
    },
    // Devis & Contrats
    {
      'question': 'Où trouver mes devis et contrats ?',
      'answer':
          'L\'onglet "Devis & Contrats" regroupe tous vos devis d\'intervention et contrats de maintenance. Vous pouvez voir le détail, accepter ou refuser un devis, et suivre l\'état de vos contrats.',
    },
    {
      'question': 'Comment accepter ou refuser un devis ?',
      'answer':
          'Dans l\'onglet "Devis & Contrats", appuyez sur un devis en attente pour voir les détails. Utilisez les boutons "Accepter" ou "Refuser" pour donner votre réponse. Un devis accepté lancera automatiquement l\'intervention.',
    },
    // Offres de maintenance
    {
      'question': 'Qu\'est-ce qu\'une offre de maintenance ?',
      'answer':
          'Les offres de maintenance sont des forfaits mensuels ou annuels qui incluent des visites d\'entretien régulières, des réductions sur les dépannages et un support prioritaire. Consultez-les dans "Offres Maintenance".',
    },
    {
      'question': 'Comment souscrire à une offre de maintenance ?',
      'answer':
          'Dans "Offres Maintenance", consultez les différentes formules disponibles. Sélectionnez celle qui vous convient, vérifiez les détails et procédez au paiement. Votre souscription sera active immédiatement.',
    },
    // Équipements
    {
      'question': 'Comment gérer mes équipements ?',
      'answer':
          'L\'onglet "Équipements" liste tous vos appareils enregistrés. Vous pouvez ajouter un nouvel équipement avec le bouton "+", voir l\'historique de maintenance de chaque appareil, et suivre les garanties.',
    },
    // Réclamations
    {
      'question': 'Comment faire une réclamation ?',
      'answer':
          'Allez dans "Réclamation" et appuyez sur le bouton "+" en bas à gauche. Décrivez votre problème en détail, joignez des photos si nécessaire, et soumettez. Notre équipe vous répondra dans les 24-48h.',
    },
    {
      'question': 'Comment suivre ma réclamation ?',
      'answer':
          'Vos réclamations apparaissent dans l\'onglet "Réclamation" avec leur statut (En cours, Répondue, Résolue). Appuyez sur une réclamation pour voir les réponses de notre équipe et répondre si besoin.',
    },
    // Factures & Historique
    {
      'question': 'Comment consulter mes factures ?',
      'answer':
          'Le menu "Factures" affiche toutes vos factures avec leur statut (Payée, En attente, En retard). Vous pouvez télécharger chaque facture en PDF et voir les détails du paiement.',
    },
    {
      'question': 'Où voir l\'historique de mes activités ?',
      'answer':
          '"Historique" dans le menu regroupe toutes vos interventions passées, commandes et paiements. Utilisez les filtres pour retrouver facilement une activité spécifique.',
    },
    // Profil & Paramètres
    {
      'question': 'Comment modifier mon profil ?',
      'answer':
          'Appuyez sur l\'icône de profil en haut à droite, puis "Mon Profil". Activez le mode édition, modifiez vos informations (nom, téléphone, email optionnel, photo, localisation) et enregistrez.',
    },
    {
      'question': 'Comment gérer les notifications ?',
      'answer':
          'Dans "Paramètres", accédez aux préférences de notifications. Vous pouvez activer/désactiver les notifications par type (interventions, paiements, promotions) et choisir le mode de réception.',
    },
    // Support
    {
      'question': 'Comment contacter le support ?',
      'answer':
          'Un bouton de chat flottant est disponible sur tous les écrans en bas à droite. Appuyez dessus pour démarrer une conversation avec notre équipe support. Vous pouvez aussi accéder à "Aide & Support" dans le menu.',
    },
    {
      'question': 'Que faire en cas d\'urgence ?',
      'answer':
          'Pour les urgences, créez une intervention de type "Dépannage" avec une description claire du problème. Notre équipe est notifiée immédiatement et vous contactera dans les plus brefs délais.',
    },
    // Rapports
    {
      'question': 'Où trouver les rapports de maintenance ?',
      'answer':
          '"Rapport maintenance" dans le menu affiche tous les comptes-rendus d\'intervention réalisés par les techniciens. Vous y trouverez les détails des travaux effectués, les pièces remplacées et les recommandations.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SupportFabWrapper(
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background_tech_2.png'),
              fit: BoxFit.cover,
              opacity: 0.4,
            ),
          ),
          child: CustomScrollView(
            slivers: [
              // SliverAppBar qui se réduit lors du scroll
              SliverAppBar(
                expandedHeight: 170,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF0a543d),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                title: Text(
                  'FAQ',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0a543d),
                          Color(0xFF0d6b4d),
                          Color(0xFF0f7d59),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.help_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Questions Fréquentes',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Trouvez rapidement des réponses à vos questions',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Liste des questions en SliverList
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final faq = _faqs[index];
                      final isExpanded = _expandedIndex == index;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() {
                              _expandedIndex = isExpanded ? null : index;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0a543d)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isExpanded ? Icons.remove : Icons.add,
                                        color: const Color(0xFF0a543d),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        faq['question']!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (isExpanded) ...[
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 44),
                                    child: Text(
                                      faq['answer']!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _faqs.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
