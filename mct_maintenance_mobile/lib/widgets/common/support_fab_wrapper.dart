import 'package:flutter/material.dart';
import '../../screens/customer/support_screen.dart';

/// Widget wrapper qui ajoute le bouton flottant de support à n'importe quel écran
class SupportFabWrapper extends StatelessWidget {
  final Widget child;
  final bool showFab;
  final bool alignLeft;

  const SupportFabWrapper({
    super.key,
    required this.child,
    this.showFab = true,
    this.alignLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showFab)
          Positioned(
            left: alignLeft ? 16 : null,
            right: alignLeft ? null : 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'support_fab_${DateTime.now().millisecondsSinceEpoch}',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF0a543d),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
