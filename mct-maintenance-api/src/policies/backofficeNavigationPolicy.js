/**
 * Structure de la navigation Back-Office par domaine métier et politique d'accès par rôle.
 *
 * Domaines :
 *  1. Opérations (Interventions, Plannings, Techniciens)
 *  2. Commercial (Devis, Contrats, Offres)
 *  3. Parc (Équipements, Stock, Garanties)
 *  4. Support (Réclamations SLA, Remboursements)
 *  5. Pilotage (Cockpit d'exceptions, Analytics)
 *  6. Configuration (Paramètres système, Utilisateurs)
 */

const BACKOFFICE_MENU = [
  {
    id: 'operations',
    label: 'Opérations',
    icon: 'engineering',
    allowed_roles: ['admin', 'manager', 'dispatcher'],
    items: [
      { id: 'interventions_list', label: 'Toutes les interventions', path: '/admin/interventions' },
      { id: 'dispatch_board', label: 'Planning & Affectations', path: '/admin/dispatch' },
      { id: 'technicians', label: 'Gestion des techniciens', path: '/admin/technicians' }
    ]
  },
  {
    id: 'commercial',
    label: 'Commercial',
    icon: 'monetization_on',
    allowed_roles: ['admin', 'manager', 'sales'],
    items: [
      { id: 'quotes', label: 'Devis & Propositions', path: '/admin/quotes' },
      { id: 'contracts', label: 'Contrats de maintenance', path: '/admin/contracts' },
      { id: 'offers', label: 'Offres & Forfaits', path: '/admin/offers' }
    ]
  },
  {
    id: 'fleet',
    label: 'Parc & Matériel',
    icon: 'inventory_2',
    allowed_roles: ['admin', 'manager', 'inventory_manager'],
    items: [
      { id: 'equipments', label: 'Parc équipements clients', path: '/admin/equipments' },
      { id: 'stock_parts', label: 'Stock & Pièces détachées', path: '/admin/stock' },
      { id: 'warranties', label: 'Suivi des garanties', path: '/admin/warranties' }
    ]
  },
  {
    id: 'support',
    label: 'Support & SAV',
    icon: 'support_agent',
    allowed_roles: ['admin', 'manager', 'support'],
    items: [
      { id: 'complaints', label: 'Réclamations SLA', path: '/admin/complaints' },
      { id: 'refunds', label: 'Litiges & Remboursements', path: '/admin/refunds' }
    ]
  },
  {
    id: 'steering',
    label: 'Pilotage & Analytics',
    icon: 'dashboard',
    allowed_roles: ['admin', 'manager'],
    items: [
      { id: 'cockpit_alerts', label: 'Cockpit des exceptions', path: '/admin/cockpit' },
      { id: 'revenue_stats', label: 'Analytics & Revenus', path: '/admin/analytics' }
    ]
  },
  {
    id: 'configuration',
    label: 'Configuration',
    icon: 'settings',
    allowed_roles: ['admin'],
    items: [
      { id: 'system_config', label: 'Tarifs & Contrats serveur', path: '/admin/config' },
      { id: 'user_management', label: 'Utilisateurs & Permissions', path: '/admin/users' }
    ]
  }
];

/**
 * Filtre le menu du back-office selon le rôle du compte.
 */
function getNavigationForRole(role = 'admin') {
  const userRole = (role || '').toLowerCase();
  
  // Admin a accès à tout
  if (userRole === 'admin') {
    return BACKOFFICE_MENU;
  }

  return BACKOFFICE_MENU
    .filter(domain => domain.allowed_roles.includes(userRole))
    .map(domain => ({ ...domain }));
}

module.exports = {
  BACKOFFICE_MENU,
  getNavigationForRole
};
