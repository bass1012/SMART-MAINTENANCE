import 'package:mct_maintenance_mobile/config/environment.dart';

/// Helper pour construire l'URL complète d'un avatar
class AvatarHelper {
  /// Construit l'URL complète de l'avatar à partir du nom de fichier
  /// 
  /// Exemples:
  /// - "avatar-15-123456.jpg" -> "http://192.168.1.139:3000/uploads/avatars/avatar-15-123456.jpg"
  /// - "/uploads/avatars/avatar-15-123456.jpg" -> "http://192.168.1.139:3000/uploads/avatars/avatar-15-123456.jpg"
  /// - "http://..." -> "http://..." (URL complète inchangée)
  static String buildAvatarUrl(String? profileImage) {
    if (profileImage == null || profileImage.isEmpty) {
      return '';
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
}
