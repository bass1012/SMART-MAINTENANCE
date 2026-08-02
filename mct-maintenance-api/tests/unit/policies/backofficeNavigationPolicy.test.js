const { BACKOFFICE_MENU, getNavigationForRole } = require('../../../src/policies/backofficeNavigationPolicy');

describe('backofficeNavigationPolicy', () => {
  it('doit retourner tous les 6 domaines pour le rôle admin', () => {
    const menu = getNavigationForRole('admin');
    expect(menu.length).toBe(6);
    expect(menu.map(m => m.id)).toEqual(['operations', 'commercial', 'fleet', 'support', 'steering', 'configuration']);
  });

  it('doit restreindre la navigation pour le rôle manager', () => {
    const menu = getNavigationForRole('manager');
    const domainIds = menu.map(m => m.id);
    expect(domainIds).toContain('operations');
    expect(domainIds).toContain('commercial');
    expect(domainIds).toContain('fleet');
    expect(domainIds).toContain('support');
    expect(domainIds).toContain('steering');
    expect(domainIds).not.toContain('configuration'); // Configuration réservée à admin
  });

  it('doit restreindre la navigation pour un rôle spécialisé (ex: support)', () => {
    const menu = getNavigationForRole('support');
    expect(menu.length).toBe(1);
    expect(menu[0].id).toBe('support');
  });
});
