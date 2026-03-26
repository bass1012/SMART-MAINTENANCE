import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';

/// Widget pour afficher l'image de fond du maintenancier de manière responsive
///
/// Sur téléphone: image en cover avec opacité
/// Sur tablette: image positionnée de manière à remplir l'écran correctement
class ResponsiveBackground extends StatelessWidget {
  final Widget child;
  final String? imagePath;
  final bool showGradient;
  final double imageOpacity;
  final List<Color>? gradientColors;
  final List<double>? gradientStops;

  const ResponsiveBackground({
    super.key,
    required this.child,
    this.imagePath = 'assets/images/Maintenancier_SMART_Maintenance_two.png',
    this.showGradient = true,
    this.imageOpacity = 0.4,
    this.gradientColors,
    this.gradientStops,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    // Sur les grands écrans, on utilise cover pour remplir l'écran
    if (isLargeScreen || (isTablet && isLandscape)) {
      return Stack(
        children: [
          // Image de fond en cover pour remplir tout l'écran
          Positioned.fill(
            child: Opacity(
              opacity: imageOpacity,
              child: imagePath != null
                  ? Image.asset(
                      imagePath!,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    )
                  : Container(color: const Color(0xFFe6ffe6)),
            ),
          ),

          // Overlay de couleur pour uniformiser
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFe6ffe6).withOpacity(0.3),
          ),

          // Gradient overlay si activé
          if (showGradient)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors ??
                      [
                        const Color(0xFF0a543d).withOpacity(0.15),
                        const Color(0xFF0d6b4d).withOpacity(0.10),
                        const Color(0xFF0f7d59).withOpacity(0.10),
                        Colors.white.withOpacity(0.3),
                      ],
                  stops: gradientStops ?? const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),

          // Contenu
          child,
        ],
      );
    }

    // Sur tablette portrait, image en cover également
    if (isTablet) {
      return Stack(
        children: [
          // Image de fond en cover
          Positioned.fill(
            child: Opacity(
              opacity: imageOpacity,
              child: imagePath != null
                  ? Image.asset(
                      imagePath!,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    )
                  : Container(color: const Color(0xFFe6ffe6)),
            ),
          ),

          // Overlay de couleur
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFe6ffe6).withOpacity(0.4),
          ),

          // Gradient overlay
          if (showGradient)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors ??
                      [
                        const Color(0xFF0a543d).withOpacity(0.20),
                        const Color(0xFF0d6b4d).withOpacity(0.15),
                        Colors.white.withOpacity(0.4),
                      ],
                  stops: gradientStops ?? const [0.0, 0.4, 1.0],
                ),
              ),
            ),

          // Contenu
          child,
        ],
      );
    }

    // Sur téléphone: comportement classique avec BoxFit.cover
    return Container(
      decoration: BoxDecoration(
        image: imagePath != null
            ? DecorationImage(
                image: AssetImage(imagePath!),
                fit: BoxFit.cover,
                opacity: imageOpacity,
              )
            : null,
      ),
      child: showGradient
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors ??
                      [
                        const Color(0xFF0a543d).withOpacity(0.25),
                        const Color(0xFF0d6b4d).withOpacity(0.20),
                        Colors.white.withOpacity(0.5),
                      ],
                  stops: gradientStops ?? const [0.0, 0.5, 1.0],
                ),
              ),
              child: child,
            )
          : child,
    );
  }
}

/// Version simplifiée pour les écrans avec fond simple (opacity uniquement)
class SimpleResponsiveBackground extends StatelessWidget {
  final Widget child;
  final String imagePath;
  final double opacity;

  const SimpleResponsiveBackground({
    super.key,
    required this.child,
    this.imagePath = 'assets/images/Maintenancier_SMART_Maintenance_two.png',
    this.opacity = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = ResponsiveHelper.isLargeScreen(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    // Sur grands écrans ou tablette (portrait ou landscape): utiliser cover
    if (isLargeScreen || isTablet) {
      return Stack(
        children: [
          // Image de fond en cover pour remplir tout l'écran
          Positioned.fill(
            child: Opacity(
              opacity: opacity,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          // Overlay de couleur pour uniformiser
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFe6ffe6).withOpacity(0.35),
          ),
          child,
        ],
      );
    }

    // Téléphone: comportement classique
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          opacity: opacity,
        ),
      ),
      child: child,
    );
  }
}
