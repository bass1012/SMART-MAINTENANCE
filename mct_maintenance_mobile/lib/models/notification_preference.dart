class NotificationPreference {
  final int id;
  final int userId;

  // Préférences générales
  final bool emailEnabled;
  final bool pushEnabled;
  final bool smsEnabled;

  // Interventions
  final bool interventionRequestEmail;
  final bool interventionRequestPush;
  final bool interventionAssignedEmail;
  final bool interventionAssignedPush;
  final bool interventionCompletedEmail;
  final bool interventionCompletedPush;

  // Commandes
  final bool orderCreatedEmail;
  final bool orderCreatedPush;
  final bool orderStatusUpdateEmail;
  final bool orderStatusUpdatePush;

  // Devis
  final bool quoteCreatedEmail;
  final bool quoteCreatedPush;
  final bool quoteUpdatedEmail;
  final bool quoteUpdatedPush;

  // Réclamations
  final bool complaintCreatedEmail;
  final bool complaintCreatedPush;
  final bool complaintResponseEmail;
  final bool complaintResponsePush;

  // Contrats
  final bool contractExpiringEmail;
  final bool contractExpiringPush;

  // Marketing et promotions
  final bool promotionEmail;
  final bool promotionPush;
  final bool maintenanceTipEmail;
  final bool maintenanceTipPush;

  // Heures de silence
  final bool quietHoursEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;

  NotificationPreference({
    required this.id,
    required this.userId,
    this.emailEnabled = true,
    this.pushEnabled = true,
    this.smsEnabled = false,
    this.interventionRequestEmail = true,
    this.interventionRequestPush = true,
    this.interventionAssignedEmail = true,
    this.interventionAssignedPush = true,
    this.interventionCompletedEmail = true,
    this.interventionCompletedPush = true,
    this.orderCreatedEmail = true,
    this.orderCreatedPush = true,
    this.orderStatusUpdateEmail = true,
    this.orderStatusUpdatePush = true,
    this.quoteCreatedEmail = true,
    this.quoteCreatedPush = true,
    this.quoteUpdatedEmail = true,
    this.quoteUpdatedPush = true,
    this.complaintCreatedEmail = true,
    this.complaintCreatedPush = true,
    this.complaintResponseEmail = true,
    this.complaintResponsePush = true,
    this.contractExpiringEmail = true,
    this.contractExpiringPush = true,
    this.promotionEmail = false,
    this.promotionPush = false,
    this.maintenanceTipEmail = false,
    this.maintenanceTipPush = false,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      emailEnabled: json['email_enabled'] ?? true,
      pushEnabled: json['push_enabled'] ?? true,
      smsEnabled: json['sms_enabled'] ?? false,
      interventionRequestEmail: json['intervention_request_email'] ?? true,
      interventionRequestPush: json['intervention_request_push'] ?? true,
      interventionAssignedEmail: json['intervention_assigned_email'] ?? true,
      interventionAssignedPush: json['intervention_assigned_push'] ?? true,
      interventionCompletedEmail: json['intervention_completed_email'] ?? true,
      interventionCompletedPush: json['intervention_completed_push'] ?? true,
      orderCreatedEmail: json['order_created_email'] ?? true,
      orderCreatedPush: json['order_created_push'] ?? true,
      orderStatusUpdateEmail: json['order_status_update_email'] ?? true,
      orderStatusUpdatePush: json['order_status_update_push'] ?? true,
      quoteCreatedEmail: json['quote_created_email'] ?? true,
      quoteCreatedPush: json['quote_created_push'] ?? true,
      quoteUpdatedEmail: json['quote_updated_email'] ?? true,
      quoteUpdatedPush: json['quote_updated_push'] ?? true,
      complaintCreatedEmail: json['complaint_created_email'] ?? true,
      complaintCreatedPush: json['complaint_created_push'] ?? true,
      complaintResponseEmail: json['complaint_response_email'] ?? true,
      complaintResponsePush: json['complaint_response_push'] ?? true,
      contractExpiringEmail: json['contract_expiring_email'] ?? true,
      contractExpiringPush: json['contract_expiring_push'] ?? true,
      promotionEmail: json['promotion_email'] ?? false,
      promotionPush: json['promotion_push'] ?? false,
      maintenanceTipEmail: json['maintenance_tip_email'] ?? false,
      maintenanceTipPush: json['maintenance_tip_push'] ?? false,
      quietHoursEnabled: json['quiet_hours_enabled'] ?? false,
      quietHoursStart: json['quiet_hours_start'],
      quietHoursEnd: json['quiet_hours_end'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'email_enabled': emailEnabled,
      'push_enabled': pushEnabled,
      'sms_enabled': smsEnabled,
      'intervention_request_email': interventionRequestEmail,
      'intervention_request_push': interventionRequestPush,
      'intervention_assigned_email': interventionAssignedEmail,
      'intervention_assigned_push': interventionAssignedPush,
      'intervention_completed_email': interventionCompletedEmail,
      'intervention_completed_push': interventionCompletedPush,
      'order_created_email': orderCreatedEmail,
      'order_created_push': orderCreatedPush,
      'order_status_update_email': orderStatusUpdateEmail,
      'order_status_update_push': orderStatusUpdatePush,
      'quote_created_email': quoteCreatedEmail,
      'quote_created_push': quoteCreatedPush,
      'quote_updated_email': quoteUpdatedEmail,
      'quote_updated_push': quoteUpdatedPush,
      'complaint_created_email': complaintCreatedEmail,
      'complaint_created_push': complaintCreatedPush,
      'complaint_response_email': complaintResponseEmail,
      'complaint_response_push': complaintResponsePush,
      'contract_expiring_email': contractExpiringEmail,
      'contract_expiring_push': contractExpiringPush,
      'promotion_email': promotionEmail,
      'promotion_push': promotionPush,
      'maintenance_tip_email': maintenanceTipEmail,
      'maintenance_tip_push': maintenanceTipPush,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
    };
  }

  NotificationPreference copyWith({
    int? id,
    int? userId,
    bool? emailEnabled,
    bool? pushEnabled,
    bool? smsEnabled,
    bool? interventionRequestEmail,
    bool? interventionRequestPush,
    bool? interventionAssignedEmail,
    bool? interventionAssignedPush,
    bool? interventionCompletedEmail,
    bool? interventionCompletedPush,
    bool? orderCreatedEmail,
    bool? orderCreatedPush,
    bool? orderStatusUpdateEmail,
    bool? orderStatusUpdatePush,
    bool? quoteCreatedEmail,
    bool? quoteCreatedPush,
    bool? quoteUpdatedEmail,
    bool? quoteUpdatedPush,
    bool? complaintCreatedEmail,
    bool? complaintCreatedPush,
    bool? complaintResponseEmail,
    bool? complaintResponsePush,
    bool? contractExpiringEmail,
    bool? contractExpiringPush,
    bool? promotionEmail,
    bool? promotionPush,
    bool? maintenanceTipEmail,
    bool? maintenanceTipPush,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationPreference(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      interventionRequestEmail:
          interventionRequestEmail ?? this.interventionRequestEmail,
      interventionRequestPush:
          interventionRequestPush ?? this.interventionRequestPush,
      interventionAssignedEmail:
          interventionAssignedEmail ?? this.interventionAssignedEmail,
      interventionAssignedPush:
          interventionAssignedPush ?? this.interventionAssignedPush,
      interventionCompletedEmail:
          interventionCompletedEmail ?? this.interventionCompletedEmail,
      interventionCompletedPush:
          interventionCompletedPush ?? this.interventionCompletedPush,
      orderCreatedEmail: orderCreatedEmail ?? this.orderCreatedEmail,
      orderCreatedPush: orderCreatedPush ?? this.orderCreatedPush,
      orderStatusUpdateEmail:
          orderStatusUpdateEmail ?? this.orderStatusUpdateEmail,
      orderStatusUpdatePush:
          orderStatusUpdatePush ?? this.orderStatusUpdatePush,
      quoteCreatedEmail: quoteCreatedEmail ?? this.quoteCreatedEmail,
      quoteCreatedPush: quoteCreatedPush ?? this.quoteCreatedPush,
      quoteUpdatedEmail: quoteUpdatedEmail ?? this.quoteUpdatedEmail,
      quoteUpdatedPush: quoteUpdatedPush ?? this.quoteUpdatedPush,
      complaintCreatedEmail:
          complaintCreatedEmail ?? this.complaintCreatedEmail,
      complaintCreatedPush: complaintCreatedPush ?? this.complaintCreatedPush,
      complaintResponseEmail:
          complaintResponseEmail ?? this.complaintResponseEmail,
      complaintResponsePush:
          complaintResponsePush ?? this.complaintResponsePush,
      contractExpiringEmail:
          contractExpiringEmail ?? this.contractExpiringEmail,
      contractExpiringPush: contractExpiringPush ?? this.contractExpiringPush,
      promotionEmail: promotionEmail ?? this.promotionEmail,
      promotionPush: promotionPush ?? this.promotionPush,
      maintenanceTipEmail: maintenanceTipEmail ?? this.maintenanceTipEmail,
      maintenanceTipPush: maintenanceTipPush ?? this.maintenanceTipPush,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}
