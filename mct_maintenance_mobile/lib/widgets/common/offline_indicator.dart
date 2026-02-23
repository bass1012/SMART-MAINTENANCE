import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sync_provider.dart';

/// Widget d'indicateur de mode offline
///
/// Affiche une bannière en haut de l'écran quand:
/// - L'appareil est hors ligne
/// - Des éléments sont en attente de synchronisation
/// - Une synchronisation est en cours
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        // Ne rien afficher si en ligne et rien en attente
        if (syncProvider.isOnline && syncProvider.pendingItems == 0) {
          return const SizedBox.shrink();
        }

        // Déterminer couleur et message selon l'état
        Color backgroundColor;
        IconData icon;
        String message;

        if (!syncProvider.isOnline) {
          // Mode offline
          backgroundColor = Colors.orange[700]!;
          icon = Icons.cloud_off;
          message = syncProvider.pendingItems > 0
              ? 'Mode hors ligne - ${syncProvider.pendingItems} élément(s) en attente'
              : 'Mode hors ligne';
        } else if (syncProvider.isSyncing) {
          // Synchronisation en cours
          backgroundColor = Colors.blue[700]!;
          icon = Icons.sync;
          message =
              'Synchronisation en cours... (${syncProvider.syncedItemsCount}/${syncProvider.pendingItems})';
        } else if (syncProvider.pendingItems > 0) {
          // En ligne mais éléments en attente
          backgroundColor = Colors.amber[700]!;
          icon = Icons.cloud_queue;
          message =
              '${syncProvider.pendingItems} élément(s) en attente de synchronisation';
        } else {
          return const SizedBox.shrink();
        }

        return Material(
          color: backgroundColor,
          elevation: 4,
          child: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                children: [
                  // Icône
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),

                  // Message
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Indicateur de chargement si sync en cours
                  if (syncProvider.isSyncing)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),

                  // Bouton sync manuel si en ligne et pas en cours
                  if (syncProvider.isOnline &&
                      !syncProvider.isSyncing &&
                      syncProvider.pendingItems > 0)
                    _buildSyncButton(context, syncProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Bouton de synchronisation manuelle
  Widget _buildSyncButton(BuildContext context, SyncProvider syncProvider) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () async {
          await syncProvider.forceSyncNow();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  syncProvider.lastSyncError != null
                      ? 'Erreur de synchronisation'
                      : 'Synchronisation réussie',
                ),
                backgroundColor: syncProvider.lastSyncError != null
                    ? Colors.red
                    : Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.sync, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text(
                'Sync',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Version compacte pour intégration dans AppBar
class OfflineIndicatorCompact extends StatelessWidget {
  const OfflineIndicatorCompact({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        if (syncProvider.isOnline && syncProvider.pendingItems == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: syncProvider.isOnline ? Colors.amber : Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                syncProvider.isOnline ? Icons.cloud_queue : Icons.cloud_off,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${syncProvider.pendingItems}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
