# Fix: Images ne s'affichant pas dans le panier

## Problème
Les images des produits dans le panier n'étaient pas affichées car elles utilisaient encore les anciennes URLs avec `localhost:3000` qui avaient été sauvegardées dans SharedPreferences avant la correction du système.

## Cause
- Le panier sauvegarde les produits dans SharedPreferences (stockage local)
- Les produits ajoutés au panier AVANT la correction des URLs contenaient `localhost:3000`
- Lors du rechargement du panier, ces anciennes URLs étaient réutilisées
- `localhost:3000` ne fonctionne pas sur mobile (connexion refusée)

## Solution Appliquée

### 1. Correction automatique des URLs dans le CartService

**Fichier:** `/mct_maintenance_mobile/lib/services/cart_service.dart`

**Ajout d'une fonction de correction:**
```dart
// Corriger l'URL de l'image si elle contient localhost
String _fixImageUrl(String? imageUrl) {
  if (imageUrl == null) return '';
  
  // Si l'URL contient localhost, la remplacer par la vraie base URL
  if (imageUrl.contains('localhost:3000')) {
    // Extraire le chemin (ex: /uploads/products/...)
    final uri = Uri.parse(imageUrl);
    final path = uri.path;
    return '${AppConfig.baseUrl}$path';
  }
  
  return imageUrl;
}
```

**Modification de loadCart():**
- Chargement des items depuis SharedPreferences
- Détection des URLs avec `localhost:3000`
- Remplacement automatique par `http://192.168.1.139:3000` (ou `10.0.2.2` pour émulateur Android)
- Création de nouveaux ProductModel avec URLs corrigées
- Sauvegarde automatique du panier avec URLs mises à jour

**Résultat:** Les anciennes URLs sont automatiquement corrigées au prochain lancement de l'app, sans intervention de l'utilisateur.

### 2. Amélioration de l'affichage dans CartScreen

**Fichier:** `/mct_maintenance_mobile/lib/screens/customer/cart_screen.dart`

**Améliorations:**

1. **Indicateur de chargement:**
   ```dart
   loadingBuilder: (context, child, loadingProgress) {
     if (loadingProgress == null) return child;
     return CircularProgressIndicator(...);
   }
   ```
   - Affiche un spinner pendant le chargement de l'image
   - Indicateur de progression si la taille est connue

2. **Meilleure gestion des erreurs:**
   ```dart
   errorBuilder: (context, error, stackTrace) {
     debugPrint('Erreur de chargement image panier: $error');
     debugPrint('URL: ${item.product.imageUrl}');
     return Container(
       child: Column(
         children: [
           Icon(Icons.image_not_supported),
           Text('Image\nindisponible'),
         ],
       ),
     );
   }
   ```
   - Logs détaillés pour debug
   - Message utilisateur clair
   - Icône de remplacement

3. **Vérification de l'URL:**
   ```dart
   item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
   ```
   - Vérifie que l'URL existe et n'est pas vide
   - Évite les erreurs de parsing

## Comment tester

### 1. Hot Restart de l'application

**IMPORTANT:** Un simple Hot Reload ne suffit pas !

```bash
# Dans votre terminal Flutter
flutter run

# Puis appuyez sur:
Shift + R  (ou tapez 'R')
```

Le Hot Restart va :
- Redémarrer complètement l'application
- Recharger le panier depuis SharedPreferences
- Appliquer la correction automatique des URLs
- Sauvegarder les URLs corrigées

### 2. Vérifier les logs

Dans la console Flutter, vous devriez voir :
```
✅ Chargement du panier...
✅ Correction de l'URL: localhost:3000 → 192.168.1.139:3000
✅ Panier sauvegardé avec URLs corrigées
```

Si une image ne charge toujours pas :
```
❌ Erreur de chargement image panier: ...
   URL: http://192.168.1.139:3000/uploads/products/xxx.jpg
```

### 3. Vérifier l'affichage

**Dans le panier, vous devriez voir:**
- ✅ Spinner de chargement pendant le téléchargement
- ✅ Image du produit une fois chargée
- ✅ Ou message "Image indisponible" si l'image n'existe pas

**Si l'image ne charge toujours pas:**
1. Vérifiez que le backend est lancé (`npm start` dans mct-maintenance-api)
2. Vérifiez votre connexion WiFi (même réseau)
3. Testez l'URL directement dans un navigateur:
   ```
   http://192.168.1.139:3000/uploads/products/product-2-1760959212464.jpg
   ```

## Fonctionnement technique

### Avant (ancien système)
```
1. Produit ajouté au panier → URL: http://localhost:3000/uploads/...
2. Sauvegarde dans SharedPreferences → URL: http://localhost:3000/uploads/...
3. Rechargement du panier → URL: http://localhost:3000/uploads/...
4. Tentative de chargement → ❌ Connection refused
```

### Après (nouveau système)
```
1. Produit ajouté au panier → URL: http://192.168.1.139:3000/uploads/...
2. Sauvegarde dans SharedPreferences → URL: http://192.168.1.139:3000/uploads/...
3. Rechargement du panier → Détection de localhost → Correction automatique
4. Tentative de chargement → ✅ Image chargée
```

### Migration automatique
```
Panier existant avec localhost:3000
         ↓
   Rechargement du panier
         ↓
   Détection de "localhost:3000"
         ↓
Extraction du chemin: /uploads/products/xxx.jpg
         ↓
Construction nouvelle URL: http://192.168.1.139:3000/uploads/products/xxx.jpg
         ↓
Création nouveau ProductModel avec URL corrigée
         ↓
Sauvegarde automatique dans SharedPreferences
         ↓
   Panier mis à jour ! ✅
```

## Avantages de cette solution

✅ **Automatique:** Aucune intervention utilisateur requise
✅ **Rétrocompatible:** Corrige automatiquement les anciennes données
✅ **Transparent:** L'utilisateur ne remarque rien
✅ **Permanent:** Une fois corrigé, le panier reste à jour
✅ **Robuste:** Gère les cas d'erreur avec feedback visuel
✅ **Debug:** Logs détaillés pour diagnostic

## Cas d'usage couverts

### Cas 1: Panier vide
- Pas de correction nécessaire
- Les nouveaux produits utilisent directement les bonnes URLs

### Cas 2: Panier avec anciennes URLs
- Détection automatique de `localhost:3000`
- Remplacement par l'IP actuelle
- Sauvegarde des URLs corrigées

### Cas 3: Panier avec URLs déjà corrigées
- Aucune modification
- Chargement normal

### Cas 4: Image manquante sur le serveur
- Affichage d'un placeholder
- Message "Image indisponible"
- Logs pour debug

### Cas 5: Problème de connexion réseau
- Spinner de chargement
- Message d'erreur si timeout
- Logs de diagnostic

## Fichiers modifiés

1. ✅ `/mct_maintenance_mobile/lib/services/cart_service.dart`
   - Import de `AppConfig`
   - Fonction `_fixImageUrl()`
   - Modification de `loadCart()`

2. ✅ `/mct_maintenance_mobile/lib/screens/customer/cart_screen.dart`
   - Ajout `loadingBuilder` pour spinner
   - Amélioration `errorBuilder` avec logs
   - Vérification URL non vide

## Prochaines étapes

1. ✅ **Test immédiat:**
   - Hot Restart de l'app
   - Vérifier les images dans le panier
   - Consulter les logs

2. ⏳ **Test complet:**
   - Ajouter de nouveaux produits au panier
   - Vérifier qu'ils utilisent les bonnes URLs
   - Fermer et rouvrir l'app

3. ⏳ **Déploiement:**
   - Une fois validé, cette correction s'appliquera à tous les utilisateurs
   - Pas de migration de données nécessaire
   - Correction automatique au premier lancement

## Résumé

🎯 **Problème:** Images du panier avec `localhost:3000` → ❌ Connection refused

🔧 **Solution:** Correction automatique des URLs au chargement du panier

✅ **Résultat:** Images affichées correctement avec indicateur de chargement

📱 **Action requise:** Hot Restart (Shift + R) de l'application Flutter

🚀 **Statut:** Prêt à tester ! Les images du panier devraient maintenant s'afficher correctement.
