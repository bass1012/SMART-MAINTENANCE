import 'package:flutter/material.dart';

/// Helper pour afficher des SnackBar avec un style cohérent et moderne dans toute l'application
class SnackBarHelper {
  /// Affiche un SnackBar de succès (vert avec icône check_circle)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? emoji,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar(
        message: emoji != null ? '$emoji $message' : '✅ $message',
        icon: Icons.check_circle,
        backgroundColor: Colors.green,
        duration: duration,
        action: action,
      ),
    );
  }

  /// Affiche un SnackBar d'erreur (rouge avec icône error_outline)
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar(
        message: '❌ $message',
        icon: Icons.error_outline,
        backgroundColor: Colors.red,
        duration: duration,
        action: action,
      ),
    );
  }

  /// Affiche un SnackBar d'information (bleu avec icône info)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? emoji,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar(
        message: emoji != null ? '$emoji $message' : 'ℹ️ $message',
        icon: Icons.info_outline,
        backgroundColor: Colors.blue,
        duration: duration,
      ),
    );
  }

  /// Affiche un SnackBar d'avertissement (orange avec icône warning)
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar(
        message: '⚠️ $message',
        icon: Icons.warning_amber_rounded,
        backgroundColor: Colors.orange,
        duration: duration,
      ),
    );
  }

  /// Affiche un SnackBar de chargement (bleu avec CircularProgressIndicator)
  static void showLoading(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 10),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '🔄 $message',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: duration,
      ),
    );
  }

  /// Affiche un SnackBar personnalisé
  static void showCustom(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar(
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
      ),
    );
  }

  /// Cache le SnackBar actuellement affiché
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Construit un SnackBar avec le style moderne et cohérent
  static SnackBar _buildSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
    SnackBarAction? action,
  }) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: duration,
      action: action,
    );
  }
}
