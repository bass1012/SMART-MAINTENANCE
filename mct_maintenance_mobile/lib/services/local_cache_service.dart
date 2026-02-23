import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

/// Service de cache local pour le mode offline
///
/// Gère le cache SQLite pour:
/// - Interventions (lecture/écriture offline)
/// - Queue de synchronisation (upload en attente)
/// - Photos (stockage avant upload)
/// - Métadonnées de sync
class LocalCacheService {
  static final LocalCacheService _instance = LocalCacheService._internal();
  factory LocalCacheService() => _instance;
  LocalCacheService._internal();

  Database? _database;

  /// Accès à la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialiser la base de données SQLite
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mct_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Créer les tables lors de la première ouverture
  Future<void> _onCreate(Database db, int version) async {
    // Table cache interventions
    await db.execute('''
      CREATE TABLE cached_interventions (
        id INTEGER PRIMARY KEY,
        data TEXT NOT NULL,
        last_synced_at TEXT,
        is_modified INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Table queue synchronisation
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        entity_id INTEGER,
        data TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        max_retries INTEGER DEFAULT 3,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        last_attempt_at TEXT,
        error_message TEXT
      )
    ''');

    // Table cache photos
    await db.execute('''
      CREATE TABLE cached_photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        intervention_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        uploaded INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Table métadonnées sync
    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    print('✅ Tables SQLite créées pour mode offline');
  }

  /// Migrations futures
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migrations à implémenter si nécessaire
  }

  // ==================== CRUD INTERVENTIONS ====================

  /// Mettre en cache une intervention
  Future<void> cacheIntervention(Map<String, dynamic> intervention) async {
    final db = await database;
    await db.insert(
      'cached_interventions',
      {
        'id': intervention['id'],
        'data': jsonEncode(intervention),
        'last_synced_at': DateTime.now().toIso8601String(),
        'is_modified': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('💾 Intervention ${intervention['id']} mise en cache');
  }

  /// Récupérer toutes les interventions en cache
  Future<List<Map<String, dynamic>>> getCachedInterventions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('cached_interventions');

    return maps
        .map((map) {
          try {
            final dataString = map['data'] as String?;
            if (dataString == null || dataString.isEmpty) {
              print('⚠️ Intervention avec data null/vide, id: ${map['id']}');
              return null;
            }
            return jsonDecode(dataString) as Map<String, dynamic>;
          } catch (e) {
            print('❌ Erreur décodage intervention ${map['id']}: $e');
            return null;
          }
        })
        .where((item) => item != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  /// Récupérer une intervention spécifique
  Future<Map<String, dynamic>?> getCachedIntervention(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_interventions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return jsonDecode(maps.first['data'] as String) as Map<String, dynamic>;
  }

  /// Mettre à jour une intervention en cache (marquer comme modifiée)
  Future<void> updateCachedIntervention(
      int id, Map<String, dynamic> updates) async {
    final db = await database;

    // Récupérer intervention actuelle
    final cached = await getCachedIntervention(id);
    if (cached == null) return;

    // Fusionner modifications
    final merged = {...cached, ...updates};

    await db.update(
      'cached_interventions',
      {
        'data': jsonEncode(merged),
        'is_modified': 1,
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    print('✏️ Intervention $id modifiée en cache');
  }

  /// Supprimer intervention du cache
  Future<void> removeCachedIntervention(int id) async {
    final db = await database;
    await db.delete('cached_interventions', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== QUEUE SYNCHRONISATION ====================

  /// Ajouter élément à la queue de synchronisation
  Future<int> addToSyncQueue(
    String type,
    int? entityId,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    final id = await db.insert('sync_queue', {
      'type': type,
      'entity_id': entityId,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
    });

    print('📤 Ajouté à la queue sync: $type (id: $id)');
    return id;
  }

  /// Récupérer éléments en attente de synchronisation
  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'retry_count < max_retries',
      orderBy: 'created_at ASC',
    );
  }

  /// Marquer élément comme synchronisé (supprimer de la queue)
  Future<void> markSyncItemComplete(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
    print('✅ Élément sync $id complété');
  }

  /// Incrémenter compteur tentatives (en cas d'échec)
  Future<void> incrementRetryCount(int id, String errorMessage) async {
    final db = await database;

    // Récupérer retry_count actuel
    final item = await db.query('sync_queue', where: 'id = ?', whereArgs: [id]);
    if (item.isEmpty) return;

    final retryCount = (item.first['retry_count'] as int) + 1;

    await db.update(
      'sync_queue',
      {
        'retry_count': retryCount,
        'last_attempt_at': DateTime.now().toIso8601String(),
        'error_message': errorMessage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    print('⚠️ Échec sync $id (tentative $retryCount)');
  }

  /// Nombre d'éléments en attente
  Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sync_queue WHERE retry_count < max_retries');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== CACHE PHOTOS ====================

  /// Ajouter photo au cache (avant upload)
  Future<void> cachePhoto(
    int interventionId,
    String filePath,
    String fileName,
  ) async {
    final db = await database;
    await db.insert('cached_photos', {
      'intervention_id': interventionId,
      'file_path': filePath,
      'file_name': fileName,
      'created_at': DateTime.now().toIso8601String(),
    });

    print('📷 Photo mise en cache: $fileName');
  }

  /// Récupérer photos non uploadées pour une intervention
  Future<List<Map<String, dynamic>>> getUnuploadedPhotos(
      int interventionId) async {
    final db = await database;
    return await db.query(
      'cached_photos',
      where: 'intervention_id = ? AND uploaded = 0',
      whereArgs: [interventionId],
    );
  }

  /// Marquer photo comme uploadée
  Future<void> markPhotoUploaded(int id) async {
    final db = await database;
    await db.update(
      'cached_photos',
      {'uploaded': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    print('✅ Photo $id uploadée');
  }

  // ==================== MÉTADONNÉES ====================

  /// Sauvegarder métadonnée
  Future<void> setMetadata(String key, String value) async {
    final db = await database;
    await db.insert(
      'sync_metadata',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lire métadonnée
  Future<String?> getMetadata(String key) async {
    final db = await database;
    final result = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  // ==================== NETTOYAGE ====================

  /// Nettoyer cache ancien (> 7 jours)
  Future<void> clearOldCache() async {
    final db = await database;
    final cutoffDate =
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

    await db.delete(
      'cached_interventions',
      where: 'last_synced_at < ? AND is_modified = 0',
      whereArgs: [cutoffDate],
    );

    print('🧹 Cache ancien nettoyé');
  }

  /// Réinitialiser toute la base (pour tests)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('cached_interventions');
    await db.delete('sync_queue');
    await db.delete('cached_photos');
    await db.delete('sync_metadata');
    print('🗑️ Cache complètement vidé');
  }

  /// Fermer la base de données
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
