import 'package:flutter/material.dart';
import '../screens/customer/intervention_detail_screen.dart' as customer;
import '../screens/technician/intervention_detail_screen.dart' as technician;
import '../screens/technician/view_report_screen.dart';
import '../screens/customer/quote_detail_screen.dart';
import '../screens/customer/order_detail_screen.dart';
import '../screens/customer/support_screen.dart';
import '../screens/customer/maintenance_offers_screen.dart';
import '../screens/customer/quotes_contracts_screen.dart';
import '../screens/customer/contract_detail_screen.dart';
import '../screens/customer/notifications_screen.dart';
import '../screens/customer/subscription_payment_screen.dart';
import '../screens/customer/contract_payment_screen.dart';
import '../services/api_service.dart';
import '../models/quote_contract_model.dart';
import '../models/contract_model.dart';
import '../widgets/common/loading_indicator.dart';

/// Service pour gérer la navigation depuis les notifications
class NotificationNavigationService {
  static final NotificationNavigationService _instance =
      NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  final ApiService _apiService = ApiService();

  /// Naviguer avec remplacement (évite les problèmes de context invalide)
  void navigateFromNotificationWithReplace(
      NavigatorState navigator, Map<String, dynamic> notificationData) {
    final String? type = notificationData['type'];
    final String? role = notificationData['role'];

    print(
        '🧭 Navigation depuis notification (replace) - Type: $type, Role: $role');
    print('   Données: $notificationData');

    if (type == null) {
      print('⚠️  Type de notification manquant');
      navigator.pop();
      return;
    }

    // Déterminer la navigation selon le type
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
      case 'quote_execution_confirmed':
      case 'intervention_confirmed': // Client a confirmé l'intervention
      case 'intervention_rejected': // Client a contesté l'intervention
      case 'intervention_dispute': // Litige signalé aux admins
        _navigateToInterventionWithReplace(navigator, notificationData);
        break;

      case 'report_submitted': // Rapport soumis → vers écran rapport
        _navigateToReportWithReplace(navigator, notificationData);
        break;

      case 'report_confirmation_required': // Demande de confirmation du rapport
        _navigateToInterventionWithReplace(navigator, notificationData);
        break;

      // Devis
      case 'quote_created':
      case 'quote_received':
      case 'quote_sent':
      case 'quote_accepted':
      case 'quote_rejected':
        _navigateToQuoteWithReplace(navigator, notificationData);
        break;

      // Commandes
      case 'order_created':
      case 'order_status':
      case 'order_status_update':
      case 'payment_confirmed':
      case 'payment_success':
      case 'payment_failed':
      case 'payment_refunded':
      case 'payment_pending':
        _navigateToOrderWithReplace(navigator, notificationData);
        break;

      // Paiement diagnostic (naviguer vers intervention)
      case 'diagnostic_payment_confirmed':
      case 'diagnostic_payment_failed':
        _navigateToInterventionWithReplace(navigator, notificationData);
        break;

      // Souscription créée - vérifier si paiement en attente
      case 'subscription_created':
        _navigateToSubscriptionPaymentWithReplace(navigator, notificationData);
        break;

      // Contrats de maintenance
      case 'contract_created':
        _navigateToContractWithReplace(navigator, notificationData);
        break;

      // Second paiement requis (50% à la dernière visite)
      case 'second_payment_required':
        _navigateToSecondPaymentWithReplace(navigator, notificationData);
        break;

      case 'contract_expiring':
      case 'contract_renewal_request':
      case 'maintenance_reminder':
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => const QuotesContractsScreen(),
          ),
        );
        break;

      default:
        // Pour les autres types, simplement fermer l'écran de notifications
        navigator.pop();
    }
  }

  /// Navigation vers intervention avec remplacement
  Future<void> _navigateToInterventionWithReplace(
      NavigatorState navigator, Map<String, dynamic> data) async {
    print('🔍 _navigateToInterventionWithReplace - Données reçues: $data');
    print('   interventionId brut: ${data['interventionId']}');
    print('   intervention_id brut: ${data['intervention_id']}');

    final int? interventionId =
        _parseId(data['interventionId']) ?? _parseId(data['intervention_id']);
    final String? role = data['role'];

    print('   interventionId parsé: $interventionId');

    if (interventionId == null) {
      print('⚠️  ID intervention manquant');
      _showSnackBarAndPop(navigator, 'ID intervention manquant');
      return;
    }

    print('→ Navigation vers intervention #$interventionId (replace)');

    try {
      final response = await _apiService.getInterventionById(interventionId);

      if (response['success'] == true && response['data'] != null) {
        final intervention = response['data'];
        final Widget detailScreen;

        if (role == 'technician') {
          detailScreen =
              technician.InterventionDetailScreen(intervention: intervention);
        } else {
          detailScreen =
              customer.InterventionDetailScreen(intervention: intervention);
        }

        // Remplacer l'écran de notifications par l'écran de détail
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => detailScreen),
        );
      } else {
        _showSnackBarAndPop(
            navigator, 'Cette intervention n\'existe plus ou a été supprimée');
      }
    } catch (e) {
      print('❌ Erreur navigation intervention: $e');
      // Vérifier si c'est une erreur "non trouvé"
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('non trouvée') ||
          errorMessage.contains('not found') ||
          errorMessage.contains('404')) {
        _showSnackBarAndPop(
            navigator, 'Cette intervention n\'existe plus ou a été supprimée');
      } else {
        _showSnackBarAndPop(
            navigator, 'Erreur lors du chargement de l\'intervention');
      }
    }
  }

  /// Navigation vers rapport avec remplacement
  Future<void> _navigateToReportWithReplace(
      NavigatorState navigator, Map<String, dynamic> data) async {
    final int? interventionId =
        _parseId(data['interventionId']) ?? _parseId(data['intervention_id']);

    if (interventionId == null) {
      print('⚠️  ID intervention manquant pour le rapport');
      _showSnackBarAndPop(navigator, 'ID intervention manquant');
      return;
    }

    print(
        '→ Navigation vers rapport de l\'intervention #$interventionId (replace)');

    try {
      final response = await _apiService.getInterventionById(interventionId);

      if (response['success'] == true && response['data'] != null) {
        final intervention = response['data'];

        // Vérifier si un rapport existe
        if (intervention['report_data'] != null) {
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  ViewReportScreen(intervention: intervention),
            ),
          );
        } else {
          _showSnackBarAndPop(
              navigator, 'Rapport non disponible pour cette intervention');
        }
      } else {
        _showSnackBarAndPop(
            navigator, 'Cette intervention n\'existe plus ou a été supprimée');
      }
    } catch (e) {
      print('❌ Erreur navigation rapport: $e');
      _showSnackBarAndPop(navigator, 'Erreur lors du chargement du rapport');
    }
  }

  /// Afficher un SnackBar puis fermer l'écran
  void _showSnackBarAndPop(NavigatorState navigator, String message) {
    navigator.pop();
    // Utiliser le context du navigator pour afficher le SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.context.mounted) {
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  /// Navigation vers devis avec remplacement
  Future<void> _navigateToQuoteWithReplace(
      NavigatorState navigator, Map<String, dynamic> data) async {
    final int? quoteId =
        _parseId(data['quoteId']) ?? _parseId(data['quote_id']);

    if (quoteId == null) {
      _showSnackBarAndPop(navigator, 'ID devis manquant');
      return;
    }

    try {
      // Charger tous les devis puis chercher le bon
      final response = await _apiService.getQuotes();

      if (response['success'] == true) {
        final quotes = List<Map<String, dynamic>>.from(response['data'] ?? []);
        final quoteData = quotes.firstWhere(
          (q) => _parseId(q['id']) == quoteId,
          orElse: () => {},
        );

        if (quoteData.isNotEmpty) {
          final quote = QuoteContract.fromJson(quoteData);
          navigator.pushReplacement(
            MaterialPageRoute(
                builder: (context) => QuoteDetailScreen(quote: quote)),
          );
        } else {
          _showSnackBarAndPop(
              navigator, 'Ce devis n\'existe plus ou a été supprimé');
        }
      } else {
        _showSnackBarAndPop(navigator, 'Erreur lors du chargement des devis');
      }
    } catch (e) {
      print('❌ Erreur navigation devis: $e');
      _showSnackBarAndPop(navigator, 'Erreur lors du chargement du devis');
    }
  }

  /// Navigation vers commande avec remplacement
  Future<void> _navigateToOrderWithReplace(
      NavigatorState navigator, Map<String, dynamic> data) async {
    final int? orderId =
        _parseId(data['orderId']) ?? _parseId(data['order_id']);

    if (orderId == null) {
      _showSnackBarAndPop(navigator, 'ID commande manquant');
      return;
    }

    try {
      // Charger toutes les commandes puis chercher la bonne
      final response = await _apiService.getOrders();

      if (response['success'] == true) {
        final orders = List<Map<String, dynamic>>.from(response['data'] ?? []);
        final orderData = orders.firstWhere(
          (o) => _parseId(o['id']) == orderId,
          orElse: () => {},
        );

        if (orderData.isNotEmpty) {
          navigator.pushReplacement(
            MaterialPageRoute(
                builder: (context) => OrderDetailScreen(order: orderData)),
          );
        } else {
          _showSnackBarAndPop(
              navigator, 'Cette commande n\'existe plus ou a été supprimée');
        }
      } else {
        _showSnackBarAndPop(
            navigator, 'Erreur lors du chargement des commandes');
      }
    } catch (e) {
      print('❌ Erreur navigation commande: $e');
      _showSnackBarAndPop(
          navigator, 'Erreur lors du chargement de la commande');
    }
  }

  /// Navigation vers le paiement de souscription avec remplacement
  void _navigateToSubscriptionPaymentWithReplace(
      NavigatorState navigator, Map<String, dynamic> data) {
    final String? paymentStatus = data['paymentStatus']?.toString();
    final int? subscriptionId = _parseId(data['subscriptionId']);
    final String? serviceName = data['serviceName']?.toString();
    final double? amount = _parseDouble(data['amount']);

    print(
        '→ Vérification souscription #$subscriptionId - payment: $paymentStatus');

    // Si paiement en attente et données disponibles, naviguer vers paiement
    if (paymentStatus == 'pending' &&
        subscriptionId != null &&
        serviceName != null &&
        amount != null) {
      print('  → Navigation vers écran de paiement (replace)');
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => SubscriptionPaymentScreen(
            subscriptionId: subscriptionId,
            subscriptionName: serviceName,
            amount: amount,
          ),
        ),
      );
    } else {
      // Sinon, naviguer vers les offres d'entretien
      print('  → Navigation vers offres d\'entretien (replace)');
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MaintenanceOffersScreen(),
        ),
      );
    }
  }

  /// Navigation vers un contrat spécifique avec remplacement
  Future<void> _navigateToContractWithReplace(
      NavigatorState navigator, Map<String, dynamic> data) async {
    final int? contractId =
        _parseId(data['subscriptionId']) ?? _parseId(data['subscription_id']);

    print('→ Navigation vers contrat #$contractId (replace)');

    if (contractId == null) {
      print('⚠️  ID contrat manquant - data: $data');
      // Fallback vers la liste des contrats
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => const QuotesContractsScreen(),
        ),
      );
      return;
    }

    try {
      // Charger le contrat
      final Contract? contract = await _apiService.getContractById(contractId);

      if (contract != null) {
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => ContractDetailScreen(contract: contract),
          ),
        );
      } else {
        // Fallback vers la liste des contrats si le contrat spécifique n'est pas trouvé
        print('⚠️  Contrat #$contractId non trouvé, redirection vers la liste');
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => const QuotesContractsScreen(),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur navigation contrat: $e');
      // Fallback vers la liste des contrats
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => const QuotesContractsScreen(),
        ),
      );
    }
  }

  /// Navigation vers le second paiement (50% à la dernière visite)
  Future<void> _navigateToSecondPaymentWithReplace(
      NavigatorState navigator, Map<String, dynamic> data) async {
    final int? subscriptionId =
        _parseId(data['subscriptionId']) ?? _parseId(data['subscription_id']);
    final double? amount = _parseDouble(data['amount']);

    print(
        '→ Navigation vers second paiement contrat #$subscriptionId - montant: $amount');

    if (subscriptionId == null) {
      print('⚠️  ID contrat manquant pour second paiement');
      _showSnackBarAndPop(navigator, 'ID contrat manquant');
      return;
    }

    try {
      // Charger le contrat pour obtenir toutes les informations
      final Contract? contract =
          await _apiService.getContractById(subscriptionId);

      if (contract != null) {
        // Naviguer directement vers l'écran de paiement avec paymentPhase=2
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => ContractPaymentScreen(
              subscriptionId: contract.id,
              reference: contract.reference,
              amount: contract.amount,
              contractType: contract.title,
              equipment: contract.equipmentDescription ?? 'Climatiseur',
              model: contract.equipmentModel,
              firstPaymentStatus: contract.firstPaymentStatus,
              secondPaymentStatus: contract.secondPaymentStatus,
              paymentPhase: 2, // Second paiement
            ),
          ),
        );
      } else {
        print('⚠️  Contrat #$subscriptionId non trouvé');
        _showSnackBarAndPop(navigator, 'Contrat non trouvé');
      }
    } catch (e) {
      print('❌ Erreur navigation second paiement: $e');
      _showSnackBarAndPop(navigator, 'Erreur lors du chargement du contrat');
    }
  }

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
      case 'intervention_confirmed': // Client a confirmé l'intervention
      case 'intervention_rejected': // Client a contesté l'intervention
      case 'intervention_dispute': // Litige signalé aux admins
        _navigateToInterventionDetails(context, notificationData);
        break;

      case 'report_submitted': // Rapport soumis → vers écran rapport
        _navigateToReportDetails(context, notificationData);
        break;

      case 'report_confirmation_required': // Demande de confirmation du rapport
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
      case 'order_status_update':
      case 'payment_confirmed':
      case 'payment_success':
      case 'payment_failed':
      case 'payment_refunded':
      case 'payment_pending':
        _navigateToOrderDetails(context, notificationData);
        break;

      // Paiement diagnostic (naviguer vers intervention)
      case 'diagnostic_payment_confirmed':
      case 'diagnostic_payment_failed':
        _navigateToInterventionDetails(context, notificationData);
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
      case 'subscription_activated':
      case 'subscription_payment_confirmed':
        _navigateToMaintenanceOffers(context);
        break;

      // Souscription créée - vérifier si paiement en attente
      case 'subscription_created':
        _navigateToSubscriptionPaymentOrOffers(context, notificationData);
        break;

      // Paiement offre d'entretien - rediriger vers les interventions
      case 'maintenance_offer_payment':
        _showPaymentPendingMessage(context);
        break;

      // Contrats
      case 'contract_created':
        _navigateToContractDetails(context, notificationData);
        break;

      // Second paiement requis (50% à la dernière visite)
      case 'second_payment_required':
        _navigateToSecondPayment(context, notificationData);
        break;

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
        _showError(
            context, 'Cette intervention n\'existe plus ou a été supprimée');
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

  /// Navigation vers les détails d'un rapport d'intervention
  Future<void> _navigateToReportDetails(
      BuildContext context, Map<String, dynamic> data) async {
    final int? interventionId =
        _parseId(data['interventionId']) ?? _parseId(data['intervention_id']);

    if (interventionId == null) {
      print('⚠️  ID intervention manquant pour le rapport - data: $data');
      _showError(context, 'ID intervention manquant');
      return;
    }

    print('→ Navigation vers rapport de l\'intervention #$interventionId');

    bool dialogOpen = false;

    try {
      if (context.mounted) {
        dialogOpen = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: LoadingIndicator()),
        );
      }

      final response = await _apiService.getInterventionById(interventionId);

      if (context.mounted && dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }

      if (!context.mounted) return;

      if (response['success'] == true && response['data'] != null) {
        final intervention = response['data'];

        if (intervention['report_data'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ViewReportScreen(intervention: intervention),
            ),
          );
        } else {
          _showError(context, 'Rapport non disponible pour cette intervention');
        }
      } else {
        _showError(
            context, 'Cette intervention n\'existe plus ou a été supprimée');
      }
    } catch (e) {
      print('❌ Erreur navigation rapport: $e');
      if (context.mounted && dialogOpen) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }
      if (context.mounted) {
        _showError(context, 'Erreur lors du chargement du rapport');
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
        final quotes = List<Map<String, dynamic>>.from(response['data'] ?? []);

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
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
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

  /// Navigation vers le paiement de souscription ou les offres
  void _navigateToSubscriptionPaymentOrOffers(
      BuildContext context, Map<String, dynamic> data) {
    final String? paymentStatus = data['paymentStatus']?.toString();
    final int? subscriptionId = _parseId(data['subscriptionId']);
    final String? serviceName = data['serviceName']?.toString();
    final double? amount = _parseDouble(data['amount']);

    print(
        '→ Vérification souscription #$subscriptionId - payment: $paymentStatus');

    // Si paiement en attente et données disponibles, naviguer vers paiement
    if (paymentStatus == 'pending' &&
        subscriptionId != null &&
        serviceName != null &&
        amount != null) {
      print('  → Navigation vers écran de paiement');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionPaymentScreen(
            subscriptionId: subscriptionId,
            subscriptionName: serviceName,
            amount: amount,
          ),
        ),
      );
    } else {
      // Sinon, naviguer vers les offres d'entretien
      print('  → Navigation vers offres d\'entretien');
      _navigateToMaintenanceOffers(context);
    }
  }

  /// Parser un double depuis diverses sources
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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

  /// Navigation vers les détails d'un contrat
  Future<void> _navigateToContractDetails(
      BuildContext context, Map<String, dynamic> data) async {
    // Supporter subscriptionId et subscription_id
    final int? contractId =
        _parseId(data['subscriptionId']) ?? _parseId(data['subscription_id']);

    if (contractId == null) {
      print('⚠️  ID contrat manquant - data: $data');
      // Fallback vers la liste des contrats
      _navigateToContracts(context);
      return;
    }

    print('→ Navigation vers contrat #$contractId');

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

      // Charger le contrat
      final Contract? contract = await _apiService.getContractById(contractId);

      // Fermer le loader
      if (context.mounted && dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }

      if (!context.mounted) return;

      if (contract != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContractDetailScreen(contract: contract),
          ),
        );
      } else {
        // Fallback vers la liste des contrats si le contrat spécifique n'est pas trouvé
        print('⚠️  Contrat #$contractId non trouvé, redirection vers la liste');
        _navigateToContracts(context);
      }
    } catch (e) {
      // Fermer le loader en cas d'erreur
      if (context.mounted && dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      print('❌ Erreur navigation contrat: $e');
      // Fallback vers la liste des contrats
      if (context.mounted) {
        _navigateToContracts(context);
      }
    }
  }

  /// Navigation vers le second paiement (50% à la dernière visite)
  Future<void> _navigateToSecondPayment(
      BuildContext context, Map<String, dynamic> data) async {
    final int? subscriptionId =
        _parseId(data['subscriptionId']) ?? _parseId(data['subscription_id']);
    final double? amount = _parseDouble(data['amount']);

    print(
        '→ Navigation vers second paiement contrat #$subscriptionId - montant: $amount');

    if (subscriptionId == null) {
      print('⚠️  ID contrat manquant pour second paiement');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID contrat manquant')),
        );
        _navigateToContracts(context);
      }
      return;
    }

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

      // Charger le contrat
      final Contract? contract =
          await _apiService.getContractById(subscriptionId);

      // Fermer le loader
      if (context.mounted && dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }

      if (!context.mounted) return;

      if (contract != null) {
        // Naviguer vers l'écran de paiement avec paymentPhase=2
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContractPaymentScreen(
              subscriptionId: contract.id,
              reference: contract.reference,
              amount: contract.amount,
              contractType: contract.title,
              equipment: contract.equipmentDescription ?? 'Climatiseur',
              model: contract.equipmentModel,
              firstPaymentStatus: contract.firstPaymentStatus,
              secondPaymentStatus: contract.secondPaymentStatus,
              paymentPhase: 2, // Second paiement
            ),
          ),
        );
      } else {
        print('⚠️  Contrat #$subscriptionId non trouvé');
        _navigateToContracts(context);
      }
    } catch (e) {
      // Fermer le loader en cas d'erreur
      if (context.mounted && dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      print('❌ Erreur navigation second paiement: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement du contrat')),
        );
        _navigateToContracts(context);
      }
    }
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
