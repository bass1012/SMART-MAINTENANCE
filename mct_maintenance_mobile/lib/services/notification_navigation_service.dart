import 'package:flutter/material.dart';
import '../screens/customer/intervention_detail_screen.dart' as customer;
import '../screens/technician/intervention_detail_screen.dart' as technician;
import '../screens/customer/quote_detail_screen.dart';
import '../screens/customer/order_detail_screen.dart';
import '../screens/customer/support_screen.dart';
import '../screens/customer/maintenance_offers_screen.dart';
import '../screens/customer/quotes_contracts_screen.dart';
import '../screens/customer/notifications_screen.dart';
import '../services/api_service.dart';
import '../models/quote_contract_model.dart';
import '../widgets/common/loading_indicator.dart';

/// Service pour gérer la navigation depuis les notifications
class NotificationNavigationService {
  static final NotificationNavigationService _instance =
      NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  final ApiService _apiService = ApiService();

  /// Naviguer selon les données de la notification
  void navigateFromNotification(
      BuildContext context, Map<String, dynamic> notificationData) {
    final String? type = notificationData['type'];
    final String? role = notificationData['role'];

    print('🧭 Navigation depuis notification - Type: $type, Role: $role');
    print('   Données: $notificationData');

    if (type == null) {
      print('⚠️  Type de notification manquant');
      return;
    }

    // Déterminer la route selon le type de notification
    switch (type) {
      // Interventions
      case 'intervention_request':
      case 'intervention_assigned':
      case 'technician_assigned':
      case 'intervention_status':
      case 'intervention_started':
      case 'intervention_completed':
      case 'intervention_cancelled':
      case 'intervention_updated':
      case 'technician_on_the_way':
      case 'technician_arrived':
      case 'quote_execution_confirmed': // Exécution confirmée → vers l'intervention
        _navigateToInterventionDetails(context, notificationData);
        break;

      // Devis
      case 'quote_created':
      case 'quote_received':
      case 'quote_sent':
      case 'quote_accepted':
      case 'quote_rejected':
        _navigateToQuoteDetails(context, notificationData);
        break;

      // Commandes
      case 'order_created':
      case 'order_status':
      case 'payment_confirmed':
      case 'payment_success':
      case 'payment_failed':
      case 'payment_refunded':
      case 'payment_pending':
        _navigateToOrderDetails(context, notificationData);
        break;

      // Réclamations
      case 'complaint_response':
      case 'complaint_status':
        _navigateToComplaintDetails(context, notificationData);
        break;

      // Chat/Support
      case 'chat':
      case 'support_message':
        _navigateToChat(context, notificationData);
        break;

      // Offres d'entretien et souscriptions
      case 'maintenance_offer_created':
      case 'maintenance_offer_activated':
      case 'subscription_created':
      case 'subscription_activated':
      case 'subscription_payment_confirmed':
        _navigateToMaintenanceOffers(context);
        break;

      // Paiement offre d'entretien - rediriger vers les interventions
      case 'maintenance_offer_payment':
        _showPaymentPendingMessage(context);
        break;

      // Contrats
      case 'contract_created':
      case 'contract_expiring':
      case 'contract_renewal_request':
      case 'maintenance_reminder':
        _navigateToContracts(context);
        break;

      // Notifications générales
      case 'general':
      case 'announcement':
      case 'alert':
      case 'promotion':
        // Rester sur la page de notifications
        _navigateToNotifications(context);
        break;

      default:
        print('⚠️  Type de notification non géré: $type');
        _navigateToNotifications(context);
    }
  }

  /// Navigation vers les details d'une intervention
  Future<void> _navigateToInterventionDetails(
      BuildContext context, Map<String, dynamic> data) async {
    // Support both interventionId and intervention_id keys
    final int? interventionId =
        _parseId(data['interventionId']) ?? _parseId(data['intervention_id']);
    final String? role = data['role'];

    if (interventionId == null) {
      print('⚠️  ID intervention manquant - data: $data');
      _showError(context, 'ID intervention manquant');
      return;
    }

    print('→ Navigation vers intervention #$interventionId (role: $role)');

    // Variable pour suivre si le dialog est ouvert
    bool dialogOpen = false;

    try {
      // Afficher un loader pendant le chargement
      if (context.mounted) {
        dialogOpen = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: LoadingIndicator()),
        );
      }

      // Charger les details de l'intervention
      final response = await _apiService.getInterventionById(interventionId);

      // Fermer le loader
      if (context.mounted && dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }

      if (!context.mounted) return;

      if (response['success'] == true && response['data'] != null) {
        final intervention = response['data'];

        // Choisir le bon ecran selon le role
        final Widget detailScreen;
        if (role == 'technician') {
          detailScreen =
              technician.InterventionDetailScreen(intervention: intervention);
        } else {
          detailScreen =
              customer.InterventionDetailScreen(intervention: intervention);
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => detailScreen),
        );
      } else {
        _showError(context, 'Cette intervention n\'existe plus ou a été supprimée');
      }
    } catch (e) {
      print('❌ Erreur navigation intervention: $e');
      // Fermer le loader en cas d'erreur
      if (context.mounted && dialogOpen) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }
      if (context.mounted) {
        _showError(context, 'Erreur lors du chargement de l\'intervention');
      }
    }
  }

  /// Navigation vers les détails d'un devis
  Future<void> _navigateToQuoteDetails(
      BuildContext context, Map<String, dynamic> data) async {
    // Support both quoteId and quote_id keys
    final int? quoteId =
        _parseId(data['quoteId']) ?? _parseId(data['quote_id']);

    if (quoteId == null) {
      print('⚠️  ID devis manquant - data: $data');
      return;
    }

    print('→ Navigation vers devis #$quoteId');

    // Variable pour suivre si le dialog est ouvert
    bool dialogOpen = false;

    try {
      // Afficher un loader pendant le chargement
      if (context.mounted) {
        dialogOpen = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: LoadingIndicator()),
        );
      }

      // Charger les details du devis
      final response = await _apiService.getQuotes();

      // Fermer le loader
      if (context.mounted && dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }

      if (!context.mounted) return;

      if (response['success'] == true) {
        final quotes =
            List<Map<String, dynamic>>.from(response['data'] ?? []);

        // Chercher le devis en comparant les IDs (gerer String et int)
        final quoteData = quotes.firstWhere(
          (q) => _parseId(q['id']) == quoteId,
          orElse: () => {},
        );

        print('🔍 Recherche devis #$quoteId dans ${quotes.length} devis');
        print('   IDs disponibles: ${quotes.map((q) => q['id']).toList()}');
        print('   Devis trouvé: ${quoteData.isNotEmpty}');

        if (quoteData.isNotEmpty) {
          final quote = QuoteContract.fromJson(quoteData);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuoteDetailScreen(quote: quote),
            ),
          );
        } else {
          _showError(context, 'Ce devis n\'existe plus ou a été supprimé');
        }
      } else {
        _showError(context, 'Impossible de charger les devis');
      }
    } catch (e) {
      print('❌ Erreur navigation devis: $e');
      // Fermer le loader en cas d'erreur
      if (context.mounted && dialogOpen) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }
      if (context.mounted) {
        _showError(context, 'Erreur lors du chargement du devis');
      }
    }
  }

  /// Navigation vers les details d'une commande
  void _navigateToOrderDetails(
      BuildContext context, Map<String, dynamic> data) async {
    // Support both orderId and order_id keys
    final int? orderId =
        _parseId(data['orderId']) ?? _parseId(data['order_id']);

    if (orderId == null) {
      print('⚠️  ID commande manquant - data: $data');
      _showError(context, 'ID commande manquant');
      return;
    }

    print('→ Navigation vers commande #$orderId');

    // Variable pour suivre si le dialog est ouvert
    bool dialogOpen = false;

    try {
      // Afficher un loader pendant le chargement
      if (context.mounted) {
        dialogOpen = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Charger les details de la commande depuis l'API
      final response = await _apiService.getOrderDetails(orderId);

      // Fermer le loader
      if (context.mounted && dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }

      if (!context.mounted) return;

      if (response != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: response),
          ),
        );
      } else {
        _showError(context, 'Cette commande n\'existe plus ou a été supprimée');
      }
    } catch (e) {
      print('❌ Erreur navigation commande: $e');
      // Fermer le loader en cas d'erreur
      if (context.mounted && dialogOpen) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }
      if (context.mounted) {
        _showError(context, 'Erreur lors du chargement de la commande');
      }
    }
  }

  /// Navigation vers les détails d'une réclamation
  void _navigateToComplaintDetails(
      BuildContext context, Map<String, dynamic> data) {
    // Support both complaintId and complaint_id keys
    final int? complaintId =
        _parseId(data['complaintId']) ?? _parseId(data['complaint_id']);

    if (complaintId == null) {
      print('⚠️  ID réclamation manquant - data: $data');
      return;
    }

    print('→ Navigation vers réclamation #$complaintId (via support)');
    // Les réclamations sont gérées dans l'écran de support
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SupportScreen(),
      ),
    );
  }

  /// Navigation vers le chat/support
  void _navigateToChat(BuildContext context, Map<String, dynamic> data) {
    print('→ Navigation vers chat/support');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SupportScreen(),
      ),
    );
  }

  /// Navigation vers les offres d'entretien
  void _navigateToMaintenanceOffers(BuildContext context) {
    print('→ Navigation vers offres d\'entretien');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MaintenanceOffersScreen(),
      ),
    );
  }

  /// Navigation vers les contrats
  void _navigateToContracts(BuildContext context) {
    print('→ Navigation vers contrats');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuotesContractsScreen(),
      ),
    );
  }

  /// Navigation vers la liste des notifications
  void _navigateToNotifications(BuildContext context) {
    print('→ Navigation vers notifications');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  /// Afficher un message pour les paiements en attente
  void _showPaymentPendingMessage(BuildContext context) {
    print('→ Affichage message paiement en attente');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.card_membership, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rendez-vous dans "Mes Interventions" pour effectuer le paiement',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0a543d),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Parser un ID depuis différents formats
  int? _parseId(dynamic id) {
    if (id == null) return null;

    if (id is int) return id;
    if (id is String) {
      try {
        return int.parse(id);
      } catch (e) {
        print('⚠️  Erreur parsing ID: $id');
        return null;
      }
    }

    return null;
  }

  /// Afficher un message d'erreur
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
