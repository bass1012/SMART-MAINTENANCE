import 'package:flutter/material.dart';

/// 🔑 Test Keys - Clés pour les Tests E2E
///
/// Ce fichier centralise toutes les clés (Keys) utilisées dans les tests E2E.
/// IMPORTANT: Ajouter ces keys dans vos widgets pour les rendre testables !

class TestKeys {
  // ═══════════════════════════════════════════════════════════════
  // AUTHENTIFICATION
  // ═══════════════════════════════════════════════════════════════

  /// Écran de connexion
  static const String emailField = 'emailField';
  static const String passwordField = 'passwordField';
  static const String loginButton = 'loginButton';
  static const String registerLink = 'registerLink';
  static const String forgotPasswordLink = 'forgotPasswordLink';

  /// Écran d'inscription
  static const String firstNameField = 'firstNameField';
  static const String lastNameField = 'lastNameField';
  static const String phoneField = 'phoneField';
  static const String registerButton = 'registerButton';

  // ═══════════════════════════════════════════════════════════════
  // DASHBOARDS
  // ═══════════════════════════════════════════════════════════════

  /// Dashboard Client
  static const String customerDashboard = 'customerDashboard';
  static const String statsCard = 'statsCard';
  static const String interventionsCard = 'interventionsCard';
  static const String ordersCard = 'ordersCard';

  /// Dashboard Technicien
  static const String technicianDashboard = 'technicianDashboard';
  static const String todayInterventions = 'todayInterventions';
  static const String calendar = 'calendar';

  // ═══════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════

  static const String bottomNav = 'bottomNav';
  static const String homeTab = 'homeTab';
  static const String interventionsTab = 'interventionsTab';
  static const String shopTab = 'shopTab';
  static const String notificationsTab = 'notificationsTab';
  static const String profileTab = 'profileTab';

  // ═══════════════════════════════════════════════════════════════
  // INTERVENTIONS - CLIENT
  // ═══════════════════════════════════════════════════════════════

  /// Liste interventions
  static const String interventionsList = 'interventionsList';
  static const String newInterventionFAB = 'newInterventionFAB';
  static const String newInterventionFab = 'newInterventionFAB'; // Alias
  static const String intervention = 'intervention_'; // + index

  /// Création intervention
  static const String interventionTitleField = 'interventionTitleField';
  static const String interventionDescriptionField =
      'interventionDescriptionField';
  static const String interventionAddressField = 'interventionAddressField';
  static const String interventionEquipmentCountField =
      'interventionEquipmentCountField';
  static const String interventionTypeDropdown = 'interventionTypeDropdown';
  static const String interventionPriorityDropdown =
      'interventionPriorityDropdown';
  static const String interventionSubmitButton = 'interventionSubmitButton';
  static const String priorityDropdown = 'priorityDropdown';
  static const String addressField = 'addressField';
  static const String getCurrentLocationButton = 'getCurrentLocationButton';
  static const String selectDateButton = 'selectDateButton';
  static const String selectTimeButton = 'selectTimeButton';
  static const String addPhotoButton = 'addPhotoButton';
  static const String cameraOption = 'cameraOption';
  static const String galleryOption = 'galleryOption';
  static const String submitInterventionButton = 'submitInterventionButton';

  /// Types d'intervention
  static const String typeMaintenance = 'typeMaintenance';
  static const String typeRepair = 'typeRepair';
  static const String typeInstallation = 'typeInstallation';
  static const String typeDiagnostic = 'typeDiagnostic';

  /// Priorités
  static const String priorityLow = 'priorityLow';
  static const String priorityNormal = 'priorityNormal';
  static const String priorityHigh = 'priorityHigh';
  static const String priorityUrgent = 'priorityUrgent';

  /// Détails intervention
  static const String interventionDetails = 'interventionDetails';
  static const String interventionStatus = 'interventionStatus';
  static const String cancelInterventionButton = 'cancelInterventionButton';
  static const String rateInterventionButton = 'rateInterventionButton';

  // ═══════════════════════════════════════════════════════════════
  // INTERVENTIONS - TECHNICIEN
  // ═══════════════════════════════════════════════════════════════

  static const String acceptInterventionButton = 'acceptInterventionButton';
  static const String declineInterventionButton = 'declineInterventionButton';
  static const String enRouteButton = 'enRouteButton';
  static const String arrivedButton = 'arrivedButton';
  static const String startInterventionButton = 'startInterventionButton';
  static const String completeInterventionButton = 'completeInterventionButton';

  /// Rapport
  static const String reportForm = 'reportForm';
  static const String createReportButton = 'createReportButton';
  static const String reportDescriptionField = 'reportDescriptionField';
  static const String reportPartsUsedField = 'reportPartsUsedField';
  static const String reportTimeSpentField = 'reportTimeSpentField';
  static const String addReportPhotoButton = 'addReportPhotoButton';
  static const String submitReportButton = 'submitReportButton';

  // ═══════════════════════════════════════════════════════════════
  // BOUTIQUE
  // ═══════════════════════════════════════════════════════════════

  /// Catalogue
  static const String productsList = 'productsList';
  static const String product = 'product_'; // + index
  static const String searchField = 'searchField';
  static const String categoryFilter = 'categoryFilter';
  static const String priceFilter = 'priceFilter';

  /// Détails produit
  static const String productDetails = 'productDetails';
  static const String addToCartButton = 'addToCartButton';
  static const String quantitySelector = 'quantitySelector';

  /// Panier
  static const String cartIcon = 'cartIcon';
  static const String cartBadge = 'cartBadge';
  static const String cartItemsList = 'cartItemsList';
  static const String cartItem = 'cartItem_'; // + index
  static const String quantityIncrement = 'quantityIncrement_'; // + index
  static const String quantityDecrement = 'quantityDecrement_'; // + index
  static const String removeFromCartButton = 'removeFromCartButton_'; // + index
  static const String cartTotal = 'cartTotal';
  static const String checkoutButton = 'checkoutButton';

  /// Checkout
  static const String shippingAddressField = 'shippingAddressField';
  static const String paymentMethodDropdown = 'paymentMethodDropdown';
  static const String paymentWave = 'paymentWave';
  static const String paymentOrangeMoney = 'paymentOrangeMoney';
  static const String paymentMoovMoney = 'paymentMoovMoney';
  static const String paymentMTN = 'paymentMTN';
  static const String paymentCard = 'paymentCard';
  static const String paymentCash = 'paymentCash';
  static const String confirmOrderButton = 'confirmOrderButton';

  /// Commandes
  static const String ordersList = 'ordersList';
  static const String order = 'order_'; // + index
  static const String orderDetails = 'orderDetails';
  static const String orderSuccess = 'orderSuccess';

  // ═══════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════

  static const String notificationsList = 'notificationsList';
  static const String notification = 'notification_'; // + index
  static const String notificationBadge = 'notificationBadge';
  static const String markAllReadButton = 'markAllReadButton';

  // ═══════════════════════════════════════════════════════════════
  // PROFIL & PARAMÈTRES
  // ═══════════════════════════════════════════════════════════════

  /// Profil
  static const String profileScreen = 'profileScreen';
  static const String avatarImage = 'avatarImage';
  static const String changeAvatarButton = 'changeAvatarButton';
  static const String profileFirstNameField = 'profileFirstNameField';
  static const String profileLastNameField = 'profileLastNameField';
  static const String profilePhoneField = 'profilePhoneField';
  static const String saveProfileButton = 'saveProfileButton';

  /// Paramètres
  static const String settingsScreen = 'settingsScreen';
  static const String themeSwitch = 'themeSwitch';
  static const String notificationsSwitch = 'notificationsSwitch';
  static const String languageSelector = 'languageSelector';
  static const String changePasswordButton = 'changePasswordButton';
  static const String logoutButton = 'logoutButton';

  // ═══════════════════════════════════════════════════════════════
  // RÉCLAMATIONS
  // ═══════════════════════════════════════════════════════════════

  static const String complaintsList = 'complaintsList';
  static const String newComplaintButton = 'newComplaintButton';
  static const String complaintTitleField = 'complaintTitleField';
  static const String complaintDescriptionField = 'complaintDescriptionField';
  static const String complaintPriorityDropdown = 'complaintPriorityDropdown';
  static const String submitComplaintButton = 'submitComplaintButton';

  // ═══════════════════════════════════════════════════════════════
  // DEVIS & CONTRATS
  // ═══════════════════════════════════════════════════════════════

  static const String quotesList = 'quotesList';
  static const String quote = 'quote_'; // + index
  static const String acceptQuoteButton = 'acceptQuoteButton';
  static const String rejectQuoteButton = 'rejectQuoteButton';

  static const String contractsList = 'contractsList';
  static const String contract = 'contract_'; // + index
  static const String subscribeButton = 'subscribeButton';

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Génère une key avec index
  static String withIndex(String baseKey, int index) {
    return '$baseKey$index';
  }

  /// Génère une key pour un item de liste
  static String listItem(String listName, int index) {
    return '${listName}_item_$index';
  }
}

/// Extension pour faciliter l'utilisation des keys
extension TestKeysExtension on String {
  /// Convertit une string en ValueKey<String>
  ValueKey<String> get key => ValueKey<String>(this);
}
