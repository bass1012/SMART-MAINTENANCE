import 'package:flutter/material.dart';
import '../../models/notification_preference.dart';
import '../../services/notification_preferences_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _service = NotificationPreferencesService();

  NotificationPreference? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await _service.getPreferences();
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePreference(Map<String, dynamic> updates) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final updated = await _service.updatePreferences(updates);
      if (updated != null) {
        setState(() {
          _preferences = updated;
          _isSaving = false;
        });
        _showSnackBar('Préférences mises à jour', isError: false);
      } else {
        setState(() => _isSaving = false);
        _showSnackBar('Erreur lors de la mise à jour');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnackBar(e.toString());
    }
  }

  Future<void> _toggleEmail(bool value) async {
    final success = await _service.toggleEmail(value);
    if (success) {
      setState(() {
        _preferences = _preferences?.copyWith(emailEnabled: value);
      });
      _showSnackBar(
        value ? 'Emails activés' : 'Emails désactivés',
        isError: false,
      );
    }
  }

  Future<void> _togglePush(bool value) async {
    final success = await _service.togglePush(value);
    if (success) {
      setState(() {
        _preferences = _preferences?.copyWith(pushEnabled: value);
      });
      _showSnackBar(
        value
            ? 'Notifications push activées'
            : 'Notifications push désactivées',
        isError: false,
      );
    }
  }

  Future<void> _resetPreferences() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les préférences'),
        content: const Text(
          'Êtes-vous sûr de vouloir réinitialiser toutes vos préférences de notifications aux valeurs par défaut ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      try {
        final reset = await _service.resetPreferences();
        if (reset != null) {
          setState(() {
            _preferences = reset;
            _isSaving = false;
          });
          _showSnackBar('Préférences réinitialisées', isError: false);
        }
      } catch (e) {
        setState(() => _isSaving = false);
        _showSnackBar(e.toString());
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préférences Notifications'),
        actions: [
          if (!_isLoading && _preferences != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPreferences,
              tooltip: 'Actualiser',
            ),
          if (!_isLoading && _preferences != null)
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: _resetPreferences,
              tooltip: 'Réinitialiser',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _preferences == null
                  ? const Center(child: Text('Aucune préférence trouvée'))
                  : _buildContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPreferences,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Préférences générales
            _buildSectionHeader('Préférences Générales', Icons.settings),
            _buildGeneralSection(),
            const SizedBox(height: 24),

            // Interventions
            _buildSectionHeader('Interventions', Icons.build),
            _buildInterventionSection(),
            const SizedBox(height: 24),

            // Commandes
            _buildSectionHeader('Commandes', Icons.shopping_cart),
            _buildOrderSection(),
            const SizedBox(height: 24),

            // Devis
            _buildSectionHeader('Devis', Icons.description),
            _buildQuoteSection(),
            const SizedBox(height: 24),

            // Réclamations
            _buildSectionHeader('Réclamations', Icons.report_problem),
            _buildComplaintSection(),
            const SizedBox(height: 24),

            // Contrats
            _buildSectionHeader('Contrats', Icons.assignment),
            _buildContractSection(),
            const SizedBox(height: 24),

            // Marketing
            _buildSectionHeader('Marketing & Promotions', Icons.campaign),
            _buildMarketingSection(),
            const SizedBox(height: 80),
          ],
        ),
        if (_isSaving)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Enregistrement...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSection() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Notifications Email'),
            subtitle: const Text('Activer toutes les notifications par email'),
            secondary: const Icon(Icons.email),
            value: _preferences!.emailEnabled,
            onChanged: _toggleEmail,
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Notifications Push'),
            subtitle: const Text('Activer toutes les notifications push'),
            secondary: const Icon(Icons.notifications_active),
            value: _preferences!.pushEnabled,
            onChanged: _togglePush,
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Notifications SMS'),
            subtitle: const Text('Activer les notifications par SMS'),
            secondary: const Icon(Icons.sms),
            value: _preferences!.smsEnabled,
            onChanged: (value) {
              _updatePreference({'sms_enabled': value});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionSection() {
    return Card(
      child: Column(
        children: [
          _buildNotificationTile(
            title: 'Nouvelle demande',
            subtitle: 'Quand vous créez une intervention',
            emailValue: _preferences!.interventionRequestEmail,
            pushValue: _preferences!.interventionRequestPush,
            onEmailChanged: (v) =>
                _updatePreference({'intervention_request_email': v}),
            onPushChanged: (v) =>
                _updatePreference({'intervention_request_push': v}),
          ),
          const Divider(height: 1),
          _buildNotificationTile(
            title: 'Technicien assigné',
            subtitle: 'Quand un technicien est assigné',
            emailValue: _preferences!.interventionAssignedEmail,
            pushValue: _preferences!.interventionAssignedPush,
            onEmailChanged: (v) =>
                _updatePreference({'intervention_assigned_email': v}),
            onPushChanged: (v) =>
                _updatePreference({'intervention_assigned_push': v}),
          ),
          const Divider(height: 1),
          _buildNotificationTile(
            title: 'Intervention terminée',
            subtitle: 'Quand l\'intervention est complétée',
            emailValue: _preferences!.interventionCompletedEmail,
            pushValue: _preferences!.interventionCompletedPush,
            onEmailChanged: (v) =>
                _updatePreference({'intervention_completed_email': v}),
            onPushChanged: (v) =>
                _updatePreference({'intervention_completed_push': v}),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSection() {
    return Card(
      child: Column(
        children: [
          _buildNotificationTile(
            title: 'Commande créée',
            subtitle: 'Confirmation de commande',
            emailValue: _preferences!.orderCreatedEmail,
            pushValue: _preferences!.orderCreatedPush,
            onEmailChanged: (v) =>
                _updatePreference({'order_created_email': v}),
            onPushChanged: (v) => _updatePreference({'order_created_push': v}),
          ),
          const Divider(height: 1),
          _buildNotificationTile(
            title: 'Statut commande',
            subtitle: 'Changement de statut',
            emailValue: _preferences!.orderStatusUpdateEmail,
            pushValue: _preferences!.orderStatusUpdatePush,
            onEmailChanged: (v) =>
                _updatePreference({'order_status_update_email': v}),
            onPushChanged: (v) =>
                _updatePreference({'order_status_update_push': v}),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteSection() {
    return Card(
      child: Column(
        children: [
          _buildNotificationTile(
            title: 'Nouveau devis',
            subtitle: 'Réception d\'un devis',
            emailValue: _preferences!.quoteCreatedEmail,
            pushValue: _preferences!.quoteCreatedPush,
            onEmailChanged: (v) =>
                _updatePreference({'quote_created_email': v}),
            onPushChanged: (v) => _updatePreference({'quote_created_push': v}),
          ),
          const Divider(height: 1),
          _buildNotificationTile(
            title: 'Devis modifié',
            subtitle: 'Mise à jour d\'un devis',
            emailValue: _preferences!.quoteUpdatedEmail,
            pushValue: _preferences!.quoteUpdatedPush,
            onEmailChanged: (v) =>
                _updatePreference({'quote_updated_email': v}),
            onPushChanged: (v) => _updatePreference({'quote_updated_push': v}),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintSection() {
    return Card(
      child: Column(
        children: [
          _buildNotificationTile(
            title: 'Réclamation créée',
            subtitle: 'Confirmation de réception',
            emailValue: _preferences!.complaintCreatedEmail,
            pushValue: _preferences!.complaintCreatedPush,
            onEmailChanged: (v) =>
                _updatePreference({'complaint_created_email': v}),
            onPushChanged: (v) =>
                _updatePreference({'complaint_created_push': v}),
          ),
          const Divider(height: 1),
          _buildNotificationTile(
            title: 'Réponse reçue',
            subtitle: 'Réponse à votre réclamation',
            emailValue: _preferences!.complaintResponseEmail,
            pushValue: _preferences!.complaintResponsePush,
            onEmailChanged: (v) =>
                _updatePreference({'complaint_response_email': v}),
            onPushChanged: (v) =>
                _updatePreference({'complaint_response_push': v}),
          ),
        ],
      ),
    );
  }

  Widget _buildContractSection() {
    return Card(
      child: Column(
        children: [
          _buildNotificationTile(
            title: 'Expiration proche',
            subtitle: 'Contrat arrivant à expiration',
            emailValue: _preferences!.contractExpiringEmail,
            pushValue: _preferences!.contractExpiringPush,
            onEmailChanged: (v) =>
                _updatePreference({'contract_expiring_email': v}),
            onPushChanged: (v) =>
                _updatePreference({'contract_expiring_push': v}),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketingSection() {
    return Card(
      child: Column(
        children: [
          _buildNotificationTile(
            title: 'Promotions',
            subtitle: 'Offres et promotions spéciales',
            emailValue: _preferences!.promotionEmail,
            pushValue: _preferences!.promotionPush,
            onEmailChanged: (v) => _updatePreference({'promotion_email': v}),
            onPushChanged: (v) => _updatePreference({'promotion_push': v}),
          ),
          const Divider(height: 1),
          _buildNotificationTile(
            title: 'Conseils maintenance',
            subtitle: 'Astuces et conseils d\'entretien',
            emailValue: _preferences!.maintenanceTipEmail,
            pushValue: _preferences!.maintenanceTipPush,
            onEmailChanged: (v) =>
                _updatePreference({'maintenance_tip_email': v}),
            onPushChanged: (v) =>
                _updatePreference({'maintenance_tip_push': v}),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required bool emailValue,
    required bool pushValue,
    required Function(bool) onEmailChanged,
    required Function(bool) onPushChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.email, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    const Text('Email'),
                    const Spacer(),
                    Switch(
                      value: emailValue && _preferences!.emailEnabled,
                      onChanged:
                          _preferences!.emailEnabled ? onEmailChanged : null,
                      activeColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.notifications,
                        size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    const Text('Push'),
                    const Spacer(),
                    Switch(
                      value: pushValue && _preferences!.pushEnabled,
                      onChanged:
                          _preferences!.pushEnabled ? onPushChanged : null,
                      activeColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
