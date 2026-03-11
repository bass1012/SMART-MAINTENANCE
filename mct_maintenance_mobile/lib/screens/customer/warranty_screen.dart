import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class WarrantyScreen extends StatelessWidget {
  const WarrantyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Garantie et Responsabilités',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Image de fond
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/images/Maintenancier_SMART_Maintenance_two.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Contenu
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec icône
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0a543d),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nos engagements envers vous',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 1: Installation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildWarrantySection(
                    icon: Icons.build_outlined,
                    title: 'Installation d\'équipements',
                    color: Colors.blue,
                    content:
                        '''Tous les travaux d'installation d'équipement de notre maison (LK et Carrier) par nos techniciens ont une garantie de 3 mois (délais plus ou moins impartis pour le premier entretien).

Garantie portant sur la qualité des travaux et le matériel utilisé pour l'installation, non sur les éventuels soucis électriques ou la qualité du courant (puissance reçue d'électricité) que reçoit l'équipement, ce qui est du ressort de l'Opérateur fournisseur d'électricité que le client/partenaire doit consulter pour plus de détails.

Tous les travaux d'installation de nouveaux splits (reçu d'achat corroborant à présenter par le client/partenaire Vs la date de notre installation) autre que les nôtres bénéficie de la même garantie tout comme de la même exemption.''',
                    duration: '3 mois',
                  ),
                ),

                const SizedBox(height: 16),

                // Section 2: Entretien
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildWarrantySection(
                    icon: Icons.cleaning_services,
                    title: 'Travaux d\'entretien',
                    color: Colors.green,
                    content:
                        '''Tous les travaux d'entretien de vos équipements effectués par nos équipes bénéficient de 3 jours de garantie pour leur bonne marche et le confort de résultat escompté à la suite des travaux.

Durant ces 3 jours nous restons à votre entière disposition pour nous signaler tout éventuel défaut de rendement de votre/vos équipements qui résulteraient de notre passage.

Attention : la garantie ne prend pas en compte les défauts de marche liés à l'électricité ou tout problème qui y serait lié.''',
                    duration: '3 jours',
                  ),
                ),

                const SizedBox(height: 16),

                // Section 3: Dépannage
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildWarrantySection(
                    icon: Icons.handyman,
                    title: 'Travaux de dépannage',
                    color: Colors.orange,
                    content:
                        '''Tous les travaux de dépannage de vos nouveaux équipements moins d'1 mois d'ancienneté (reçu d'achat corroborant à présenter par le client/partenaire Vs la date de notre dépannage) bénéficient d'une garantie de 7 jours à la suite de notre intervention.

Garantie portant sur la qualité des travaux et le matériel utilisé pour l'installation, non sur les éventuels soucis électriques ou la qualité du courant (puissance reçue d'électricité) que reçoit l'équipement, ce qui est du ressort de l'Opérateur fournisseur d'électricité que le client/partenaire doit consulter pour plus de détails.

Les dépannages sur vos équipements avec une ancienneté supérieur à celle mentionnée plus bénéficient de 3 jours de garantie tout comme de la même exemption.''',
                    duration: '3 à 7 jours',
                  ),
                ),

                const SizedBox(height: 16),

                // Section 4: Diagnostic
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildWarrantySection(
                    icon: Icons.search,
                    title: 'Diagnostic préalable',
                    color: Colors.purple,
                    content:
                        '''Les dépannages et les installations sont tous soumis à un diagnostic (4 000 FCFA) préalable avant tous travaux.

Le diagnostic établi nous permet de vous partager un devis et c'est uniquement après la validation dudit devis que nous intervenons.''',
                    price: '4 000 FCFA',
                  ),
                ),

                const SizedBox(height: 24),

                // Section Contact
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0a543d),
                          const Color(0xFF0d6b4d),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0a543d).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.support_agent,
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Besoin d\'aide ?',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pour toutes préoccupations ou autres sujets portant sur la qualité de nos travaux (installation, dépannage, entretien), veuillez nous contacter par WhatsApp.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _launchWhatsApp(),
                          icon:
                              const Icon(Icons.chat, color: Color(0xFF25D366)),
                          label: Text(
                            'WhatsApp: 07 59 50 50 50',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0a543d),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantySection({
    required IconData icon,
    required String title,
    required Color color,
    required String content,
    String? duration,
    String? price,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (duration != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Garantie: $duration',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          if (price != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                price,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse(
        'https://wa.me/22507595050505?text=Bonjour, j\'ai une question concernant la garantie de vos services.');

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }
}
