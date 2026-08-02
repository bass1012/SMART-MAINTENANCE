import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Rôles supportés pour la personnalisation de l'état vide guidé.
enum UserRoleContext { customer, technician, manager }

/// Composant d'état vide guidé adapté au rôle de l'utilisateur.
///
/// Propose un visuel soigné avec icône contextualisée, titre explicatif,
/// conseils d'onboarding (étape suivante conseillée) et bouton d'action principal.
class GuidedEmptyState extends StatelessWidget {
  final UserRoleContext roleContext;
  final String title;
  final String description;
  final String? onboardingTip;
  final IconData? customIcon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const GuidedEmptyState({
    super.key,
    required this.roleContext,
    required this.title,
    required this.description,
    this.onboardingTip,
    this.customIcon,
    this.actionLabel,
    this.onActionPressed,
  });

  Color get _primaryColor {
    switch (roleContext) {
      case UserRoleContext.customer:
        return const Color(0xFF0a543d);
      case UserRoleContext.technician:
        return const Color(0xFF0d6b4d);
      case UserRoleContext.manager:
        return const Color(0xFF1565C0);
    }
  }

  IconData get _defaultIcon {
    switch (roleContext) {
      case UserRoleContext.customer:
        return Icons.cleaning_services_outlined;
      case UserRoleContext.technician:
        return Icons.handyman_outlined;
      case UserRoleContext.manager:
        return Icons.insights_outlined;
    }
  }

  String get _defaultTip {
    switch (roleContext) {
      case UserRoleContext.customer:
        return 'Astuce Client : Enregistrez vos équipements pour bénéficier automatiquement du suivi de garantie et d\'interventions prioritaires.';
      case UserRoleContext.technician:
        return 'Astuce Technicien : Passez votre statut en "En ligne" pour recevoir des affectations d\'interventions à proximité.';
      case UserRoleContext.manager:
        return 'Astuce Manager : Le cockpit d\'exceptions regroupe automatiquement les blocages réseau, retards et paiements échoués.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _primaryColor;
    final icon = customIcon ?? _defaultIcon;
    final tip = onboardingTip ?? _defaultTip;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Conteneur d'icône avec dégradé et ombre douce
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 44,
                color: color,
              ),
            ),
            const SizedBox(height: 20),

            // Titre
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Encadré de conseil / Onboarding
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
