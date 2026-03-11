import 'package:flutter/foundation.dart';
import '../services/local_cache_service.dart';
import '../services/connectivity_service.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'dart:convert';

/// Provider de synchronisation pour le mode offline
///
/// Gère:
/// - État de synchronisation (en cours/terminée/erreur)
/// - Compteur d'éléments en attente
/// - Synchronisation automatique au retour du réseau
/// - Retry logic pour échecs temporaires
class SyncProvider extends ChangeNotifier {
  final LocalCacheService _cacheService = LocalCacheService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final ApiService _apiService = ApiService();

  // État synchronisation
  bool _isSyncing = false;
  int _pendingItems = 0;
  String? _lastSyncError;
  DateTime? _lastSyncTime;
  int _syncedItemsCount = 0;

  // Getters
  bool get isSyncing => _isSyncing;
  int get pendingItems => _pendingItems;
  String? get lastSyncError => _lastSyncError;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get syncedItemsCount => _syncedItemsCount;
  bool get isOnline => _connectivityService.isConnected;

  StreamSubscription? _connectivitySubscription;
  Timer? _periodicSyncTimer;

  SyncProvider() {
    _init();
  }

  /// Initialiser le provider
  void _init() {
    print('🔄 Initialisation SyncProvider...');

    _connectivityService.initialize();

    // Nettoyer les éléments bloqués au démarrage
    _cleanupOldItems();

    _updatePendingCount();

    // Écouter changements connectivité
    _connectivitySubscription = _connectivityService.connectionStream.listen(
      (isConnected) {
        notifyListeners();

        if (isConnected) {
          print('🟢 Retour en ligne - Démarrage synchronisation auto...');
          // Petit délai pour stabiliser la connexion
          Future.delayed(const Duration(seconds: 2), () {
            syncAll();
          });
        } else {
          print('🔴 Passage hors ligne - Mode cache activé');
        }
      },
    );

    // Synchronisation périodique (toutes les 5 minutes si en ligne)
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) {
        if (_connectivityService.isConnected && !_isSyncing) {
          print('⏰ Synchronisation périodique...');
          syncAll();
        }
      },
    );
  }

  /// Nettoyer les éléments de sync obsolètes/bloqués au démarrage
  Future<void> _cleanupOldItems() async {
    try {
      final cleaned = await _cacheService.clearOldSyncItems();
      if (cleaned > 0) {
        print(
            '🧹 Nettoyage au démarrage: $cleaned éléments obsolètes supprimés');
      }
    } catch (e) {
      print('❌ Erreur nettoyage éléments obsolètes: $e');
    }
  }

  /// Forcer le nettoyage complet de la queue de synchronisation
  Future<void> clearSyncQueue() async {
    try {
      await _cacheService.clearSyncQueue();
      await _updatePendingCount();
      notifyListeners();
    } catch (e) {
      print('❌ Erreur vidage queue sync: $e');
    }
  }

  /// Mettre à jour le compteur d'éléments en attente
  Future<void> _updatePendingCount() async {
    try {
      _pendingItems = await _cacheService.getPendingSyncCount();
      notifyListeners();
    } catch (e) {
      print('❌ Erreur mise à jour compteur: $e');
    }
  }

  /// Nettoyer les duplicatas dans la queue
  Future<void> _cleanupDuplicates() async {
    try {
      final items = await _cacheService.getPendingSyncItems();

      // Grouper par intervention_id, type ET action (pour ne supprimer que les vrais duplicatas)
      final Map<String, List<Map<String, dynamic>>> grouped = {};

      for (var item in items) {
        final entityId = item['entity_id'];
        final type = item['type'] as String;

        // Pour les statuts, inclure l'action dans la clé pour ne supprimer que les duplicatas de la même action
        String key;
        if (type == 'intervention_status') {
          final dataString = item['data'] as String;
          final data = jsonDecode(dataString) as Map<String, dynamic>;
          final action = data['action'] ?? 'unknown';
          key = '${type}_${entityId}_$action';
        } else {
          key = '${type}_$entityId';
        }

        if (!grouped.containsKey(key)) {
          grouped[key] = [];
        }
        grouped[key]!.add(item);
      }

      // Pour chaque groupe, garder seulement le plus récent
      int cleaned = 0;
      for (var entry in grouped.entries) {
        final group = entry.value;
        if (group.length > 1) {
          // Trier par ID (le plus récent a l'ID le plus élevé)
          group.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));

          // Supprimer tous sauf le premier (plus récent)
          for (int i = 1; i < group.length; i++) {
            await _cacheService.markSyncItemComplete(group[i]['id'] as int);
            cleaned++;
            print(
                '🗑️ Duplicata supprimé: ${entry.key} (id: ${group[i]['id']})');
          }
        }
      }

      if (cleaned > 0) {
        print('🧹 $cleaned duplicata(s) nettoyé(s)');
      }
    } catch (e) {
      print('❌ Erreur nettoyage duplicatas: $e');
    }
  }

  /// Synchroniser tous les éléments en attente
  Future<void> syncAll() async {
    if (_isSyncing) {
      print('⚠️ Synchronisation déjà en cours, ignorée');
      return;
    }

    if (!_connectivityService.isConnected) {
      print('⚠️ Pas de connexion, synchronisation impossible');
      return;
    }

    _isSyncing = true;
    _lastSyncError = null;
    _syncedItemsCount = 0;
    notifyListeners();

    print('🔄 Début synchronisation...');

    try {
      // Nettoyer les duplicatas avant de synchroniser
      await _cleanupDuplicates();

      final items = await _cacheService.getPendingSyncItems();
      print('📋 ${items.length} éléments à synchroniser');

      // Trier les items pour synchroniser dans l'ordre du workflow
      final sortedItems = List<Map<String, dynamic>>.from(items);
      sortedItems.sort((a, b) {
        final typeA = a['type'] as String;
        final typeB = b['type'] as String;

        // Ordre de priorité: intervention_status > intervention_update > report_upload > diagnostic_report_upload > photo_upload
        final priorityMap = {
          'intervention_status': 0,
          'intervention_update': 1,
          'report_upload': 2,
          'diagnostic_report_upload': 3,
          'photo_upload': 4,
        };

        final priorityA = priorityMap[typeA] ?? 99;
        final priorityB = priorityMap[typeB] ?? 99;

        // Si même type, trier par ordre de workflow
        if (priorityA == priorityB && typeA == 'intervention_status') {
          final dataA = jsonDecode(a['data'] as String);
          final dataB = jsonDecode(b['data'] as String);
          final actionA = dataA['action'] as String?;
          final actionB = dataB['action'] as String?;

          // Ordre des actions: accept < on-the-way < arrived < start < complete
          final actionOrder = {
            'accept': 0,
            'on-the-way': 1,
            'arrived': 2,
            'start': 3,
            'complete': 4,
          };

          final orderA = actionOrder[actionA] ?? 99;
          final orderB = actionOrder[actionB] ?? 99;

          return orderA.compareTo(orderB);
        }

        return priorityA.compareTo(priorityB);
      });

      for (var item in sortedItems) {
        try {
          await _syncItem(item);
          await _cacheService.markSyncItemComplete(item['id'] as int);
          _syncedItemsCount++;
          print(
              '✅ Élément ${item['id']} synchronisé (${_syncedItemsCount}/${sortedItems.length})');
        } catch (e) {
          final errorMessage = e.toString();

          // Détecter UNIQUEMENT les vraies actions obsolètes (déjà effectuées avec succès)
          final isReallyObsolete = errorMessage.contains('déjà acceptée') ||
              errorMessage.contains('déjà terminée') ||
              errorMessage.contains('déjà été confirmée') ||
              errorMessage.contains('déjà confirmée') ||
              errorMessage.contains('already confirmed') ||
              errorMessage.contains('Intervention non trouvée');

          // Erreurs d'ordre = pas obsolète, juste dans le mauvais ordre (retry sans incrémenter le compteur)
          final isOrderError = errorMessage.contains('doit être en cours') ||
              errorMessage.contains('signaler votre arrivée') ||
              errorMessage.contains('doit être terminée pour soumettre');

          if (isReallyObsolete) {
            // Action vraiment obsolète = on la supprime
            print('⚠️ Élément ${item['id']} obsolète: $errorMessage');
            await _cacheService.markSyncItemComplete(item['id'] as int);
            print('🗑️ Élément ${item['id']} supprimé de la queue');
          } else if (isOrderError) {
            // Erreur d'ordre = on garde et réessayera au prochain cycle
            print('⏭️ Élément ${item['id']} reporté (ordre): $errorMessage');
            // Ne pas incrémenter retry_count - il sera réessayé automatiquement
          } else {
            // Autre erreur (réseau, serveur, etc.) = on incrémente retry
            print('❌ Échec sync élément ${item['id']}: $errorMessage');
            await _cacheService.incrementRetryCount(
              item['id'] as int,
              errorMessage,
            );
          }
        }
      }

      _lastSyncTime = DateTime.now();
      final totalItems = sortedItems.length;
      final pendingItems = totalItems - _syncedItemsCount;
      print(
          '✅ Synchronisation terminée: $_syncedItemsCount/$totalItems réussis');

      // Si des items sont reportés (erreur d'ordre), réessayer après 10 secondes
      if (pendingItems > 0 && _syncedItemsCount > 0) {
        print(
            '🔄 $pendingItems items reportés, nouvelle tentative dans 10s...');
        Future.delayed(const Duration(seconds: 10), () {
          if (_connectivityService.isConnected && !_isSyncing) {
            syncAll();
          }
        });
      }
    } catch (e) {
      _lastSyncError = e.toString();
      print('❌ Erreur synchronisation globale: $e');
    } finally {
      _isSyncing = false;
      await _updatePendingCount();
      notifyListeners();
    }
  }

  /// Synchroniser un élément spécifique
  Future<void> _syncItem(Map<String, dynamic> item) async {
    final type = item['type'] as String;
    final entityId = item['entity_id'] as int?;
    final dataString = item['data'] as String;
    final data = jsonDecode(dataString) as Map<String, dynamic>;

    print('🔄 Sync $type (entity: $entityId)');

    switch (type) {
      case 'intervention_update':
        await _syncInterventionUpdate(entityId!, data);
        break;

      case 'intervention_status':
        await _syncInterventionStatus(entityId!, data);
        break;

      case 'report_upload':
        await _syncReportUpload(entityId!, data);
        break;

      case 'diagnostic_report_upload':
        await _syncDiagnosticReportUpload(entityId!, data);
        break;

      case 'photo_upload':
        await _syncPhotoUpload(entityId!, data);
        break;

      default:
        print('⚠️ Type de sync inconnu: $type');
    }
  }

  /// Synchroniser mise à jour intervention
  Future<void> _syncInterventionUpdate(
      int interventionId, Map<String, dynamic> data) async {
    // TODO: Implémenter avec la bonne méthode API quand disponible
    print('🔄 Sync intervention update: $interventionId');
    // Simulation réussite pour le moment
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Synchroniser changement statut intervention
  Future<void> _syncInterventionStatus(
      int interventionId, Map<String, dynamic> data) async {
    final action = data['action'] as String?;

    if (action == null) {
      throw Exception('Action manquante dans les données de sync');
    }

    print('🔄 Sync intervention status: $interventionId -> $action');

    // Appeler le bon endpoint selon l'action
    switch (action) {
      case 'accept':
        await _apiService.acceptIntervention(interventionId);
        break;
      case 'on-the-way':
        await _apiService.markInterventionOnTheWay(interventionId);
        break;
      case 'arrived':
        await _apiService.markInterventionArrived(interventionId);
        break;
      case 'start':
        await _apiService.startIntervention(interventionId);
        break;
      case 'complete':
        await _apiService.completeIntervention(interventionId);
        break;
      default:
        throw Exception('Action inconnue: $action');
    }

    print('✅ Statut synchronisé: $action');
  }

  /// Synchroniser upload rapport
  Future<void> _syncReportUpload(
      int interventionId, Map<String, dynamic> reportData) async {
    print('📝 Début upload rapport intervention $interventionId');

    try {
      // IMPORTANT: S'assurer que l'intervention est marquée comme completed côté serveur
      // avant de soumettre le rapport
      try {
        print('🔄 Vérification/Marquage intervention comme terminée...');
        await _apiService.completeIntervention(interventionId);
        print('✅ Intervention marquée comme terminée');
      } catch (e) {
        final errorMessage = e.toString();
        // Si déjà terminée ou déjà en cours, c'est OK
        if (errorMessage.contains('déjà terminée') ||
            errorMessage.contains('doit être en cours')) {
          print('ℹ️ Intervention déjà dans le bon état: $errorMessage');
        } else {
          // Autre erreur, on continue quand même car le rapport peut être valide
          print('⚠️ Erreur marquage terminée (on continue): $errorMessage');
        }
      }

      // Récupérer les photos non uploadées depuis le cache
      final photos = await _cacheService.getUnuploadedPhotos(interventionId);

      if (photos.isNotEmpty) {
        print('📷 ${photos.length} photo(s) à uploader depuis le cache');

        // Les photos sont déjà dans reportData['photos'] avec leurs chemins locaux
        // L'API va les uploader via multipart
        final photoPaths = photos.map((p) => p['file_path'] as String).toList();
        reportData['photos'] = photoPaths;
      } else {
        print('ℹ️ Aucune photo à uploader');
        reportData['photos'] = [];
      }

      // Soumettre le rapport (upload multipart inclus)
      await _apiService.submitInterventionReport(
        interventionId,
        reportData,
      );

      print('✅ Rapport uploadé avec succès');

      // Marquer les photos comme uploadées
      if (photos.isNotEmpty) {
        for (final photo in photos) {
          await _cacheService.markPhotoUploaded(photo['id'] as int);
        }
        print('✅ ${photos.length} photo(s) marquées comme uploadées');
      }
    } catch (e) {
      print('❌ Erreur upload rapport: $e');
      rethrow;
    }
  }

  /// Synchroniser upload rapport de diagnostic
  Future<void> _syncDiagnosticReportUpload(
      int interventionId, Map<String, dynamic> diagnosticData) async {
    print('🔬 Début upload rapport diagnostic intervention $interventionId');

    try {
      // Soumettre le rapport de diagnostic
      await _apiService.post(
        '/diagnostic-reports',
        {
          'intervention_id': interventionId,
          'problem_description': diagnosticData['problem_description'],
          'recommended_solution': diagnosticData['recommended_solution'],
          'parts_needed': diagnosticData['parts_needed'] ?? [],
          'labor_cost': diagnosticData['labor_cost'] ?? 0,
          'estimated_total': diagnosticData['estimated_total'] ?? 0,
          'urgency_level': diagnosticData['urgency_level'] ?? 'medium',
          'estimated_duration': diagnosticData['estimated_duration'] ?? '',
          'photos': [], // TODO: Support photos diagnostic
          'notes': diagnosticData['notes'] ?? '',
        },
      );

      print('✅ Rapport diagnostic uploadé avec succès');
    } catch (e) {
      print('❌ Erreur upload rapport diagnostic: $e');
      rethrow;
    }
  }

  /// Synchroniser upload photo
  Future<void> _syncPhotoUpload(
      int interventionId, Map<String, dynamic> photoData) async {
    final filePath = photoData['file_path'] as String;
    // TODO: Implémenter upload photo depuis cache
    print('📷 Upload photo: $filePath');
  }

  /// Ajouter élément à la queue de synchronisation
  Future<void> addToQueue(
    String type,
    int? entityId,
    Map<String, dynamic> data,
  ) async {
    await _cacheService.addToSyncQueue(type, entityId, data);
    await _updatePendingCount();
  }

  /// Forcer une synchronisation manuelle
  Future<void> forceSyncNow() async {
    print('🔄 Synchronisation forcée par l\'utilisateur');
    await syncAll();
  }

  /// Nettoyer cache ancien
  Future<void> cleanOldCache() async {
    try {
      await _cacheService.clearOldCache();
      print('🧹 Nettoyage cache ancien effectué');
    } catch (e) {
      print('❌ Erreur nettoyage cache: $e');
    }
  }

  /// Statistiques de synchronisation
  Map<String, dynamic> getStats() {
    return {
      'isOnline': isOnline,
      'isSyncing': isSyncing,
      'pendingItems': pendingItems,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'lastSyncError': lastSyncError,
      'syncedItemsCount': syncedItemsCount,
    };
  }

  @override
  void dispose() {
    print('🔄 Fermeture SyncProvider');
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    super.dispose();
  }
}
