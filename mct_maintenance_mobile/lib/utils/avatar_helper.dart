import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:mct_maintenance_mobile/config/environment.dart';

/// Helper pour construire l'URL complète d'un avatar
class AvatarHelper {
  /// Retourne true si la valeur est un data URL base64
  static bool isBase64Url(String? value) {
    return value != null && value.startsWith('data:image/');
  }

  /// Construit l'URL complète de l'avatar à partir du nom de fichier ou data URL
  static String buildAvatarUrl(String? profileImage) {
    if (profileImage == null || profileImage.isEmpty) {
      return '';
    }

    // Data URL base64 → retourner tel quel
    if (isBase64Url(profileImage)) {
      return profileImage;
    }

    // Si c'est déjà une URL complète, la retourner telle quelle
    if (profileImage.startsWith('http://') || profileImage.startsWith('https://')) {
      return profileImage;
    }

    // Si ça commence par /, c'est un chemin relatif
    if (profileImage.startsWith('/')) {
      return '${AppConfig.baseUrl}$profileImage';
    }

    // Sinon, c'est juste le nom du fichier, construire le chemin complet
    return '${AppConfig.baseUrl}/uploads/avatars/$profileImage';
  }

  /// Vérifie si un avatar est disponible
  static bool hasAvatar(String? profileImage) {
    return profileImage != null && profileImage.isNotEmpty;
  }

  /// Retourne l'ImageProvider adapté : MemoryImage si base64, NetworkImage sinon
  static ImageProvider? buildImageProvider(String? profileImage) {
    if (profileImage == null || profileImage.isEmpty) return null;

    if (isBase64Url(profileImage)) {
      // Extraire la partie base64 après la virgule
      final commaIndex = profileImage.indexOf(',');
      if (commaIndex == -1) return null;
      try {
        final bytes = base64Decode(profileImage.substring(commaIndex + 1));
        return MemoryImage(Uint8List.fromList(bytes));
      } catch (_) {
        return null;
      }
    }

    final url = buildAvatarUrl(profileImage);
    if (url.isEmpty) return null;
    return NetworkImage(url);
  }
}
