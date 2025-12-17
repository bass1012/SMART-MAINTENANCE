/// 📝 EXEMPLE D'UTILISATION DES TEST KEYS
///
/// Ce fichier montre comment ajouter des keys aux widgets
/// pour les rendre testables avec Patrol

import 'package:flutter/material.dart';
import '../utils/test_keys.dart';

// ═══════════════════════════════════════════════════════════════
// EXEMPLE 1: Écran de Connexion Simple
// ═══════════════════════════════════════════════════════════════

class LoginScreenExample extends StatelessWidget {
  const LoginScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ✅ BON - Avec Key pour test
          TextField(
            key: const ValueKey(TestKeys.emailField),
            decoration: const InputDecoration(labelText: 'Email'),
          ),

          // ✅ BON - Avec Key pour test
          TextField(
            key: const ValueKey(TestKeys.passwordField),
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
          ),

          // ✅ BON - Avec Key pour test
          ElevatedButton(
            key: const ValueKey(TestKeys.loginButton),
            onPressed: () {},
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}

// ❌ MAUVAIS - Sans keys
class LoginScreenBad extends StatelessWidget {
  const LoginScreenBad({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXEMPLE 2: Liste avec Keys Dynamiques
// ═══════════════════════════════════════════════════════════════

class InterventionsListExample extends StatelessWidget {
  final List<Map<String, dynamic>> interventions;

  const InterventionsListExample({
    super.key,
    required this.interventions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ BON - Key sur la liste principale
      body: ListView.builder(
        key: const ValueKey(TestKeys.interventionsList),
        itemCount: interventions.length,
        itemBuilder: (context, index) {
          final intervention = interventions[index];

          // ✅ BON - Key dynamique avec index
          return ListTile(
            key: ValueKey(TestKeys.withIndex(TestKeys.intervention, index)),
            title: Text(intervention['title']),
            subtitle: Text(intervention['status']),
            onTap: () {
              // Navigation vers détails
            },
          );
        },
      ),

      // ✅ BON - FAB avec key
      floatingActionButton: FloatingActionButton(
        key: const ValueKey(TestKeys.newInterventionFab),
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXEMPLE 3: Formulaire Complexe
// ═══════════════════════════════════════════════════════════════

class NewInterventionFormExample extends StatefulWidget {
  const NewInterventionFormExample({super.key});

  @override
  State<NewInterventionFormExample> createState() =>
      _NewInterventionFormExampleState();
}

class _NewInterventionFormExampleState
    extends State<NewInterventionFormExample> {
  String? selectedType;
  String? selectedPriority;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Intervention')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Titre
            TextField(
              key: const ValueKey(TestKeys.interventionTitleField),
              decoration: const InputDecoration(labelText: 'Titre'),
            ),

            // Description
            TextField(
              key: const ValueKey(TestKeys.interventionDescriptionField),
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),

            // ✅ BON - Dropdown avec key
            DropdownButton<String>(
              key: const ValueKey(TestKeys.interventionTypeDropdown),
              value: selectedType,
              hint: const Text('Type d\'intervention'),
              items: [
                // ✅ BON - Chaque option avec key
                DropdownMenuItem(
                  key: const ValueKey(TestKeys.typeMaintenance),
                  value: 'maintenance',
                  child: const Text('Maintenance'),
                ),
                DropdownMenuItem(
                  key: const ValueKey(TestKeys.typeRepair),
                  value: 'repair',
                  child: const Text('Réparation'),
                ),
                DropdownMenuItem(
                  key: const ValueKey(TestKeys.typeInstallation),
                  value: 'installation',
                  child: const Text('Installation'),
                ),
              ],
              onChanged: (value) => setState(() => selectedType = value),
            ),

            // Priorité
            DropdownButton<String>(
              key: const ValueKey(TestKeys.priorityDropdown),
              value: selectedPriority,
              hint: const Text('Priorité'),
              items: [
                DropdownMenuItem(
                  key: const ValueKey(TestKeys.priorityLow),
                  value: 'low',
                  child: const Text('Basse'),
                ),
                DropdownMenuItem(
                  key: const ValueKey(TestKeys.priorityNormal),
                  value: 'normal',
                  child: const Text('Normale'),
                ),
                DropdownMenuItem(
                  key: const ValueKey(TestKeys.priorityHigh),
                  value: 'high',
                  child: const Text('Haute'),
                ),
                DropdownMenuItem(
                  key: const ValueKey(TestKeys.priorityUrgent),
                  value: 'urgent',
                  child: const Text('Urgente'),
                ),
              ],
              onChanged: (value) => setState(() => selectedPriority = value),
            ),

            // Adresse
            TextField(
              key: const ValueKey(TestKeys.addressField),
              decoration: const InputDecoration(labelText: 'Adresse'),
            ),

            // Bouton localisation
            ElevatedButton.icon(
              key: const ValueKey(TestKeys.getCurrentLocationButton),
              icon: const Icon(Icons.my_location),
              label: const Text('Utiliser ma position'),
              onPressed: () {},
            ),

            const SizedBox(height: 20),

            // Bouton soumettre
            ElevatedButton(
              key: const ValueKey(TestKeys.submitInterventionButton),
              onPressed: () {},
              child: const Text('Créer Intervention'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXEMPLE 4: Panier avec Actions
// ═══════════════════════════════════════════════════════════════

class CartExample extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const CartExample({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panier'),
        actions: [
          // ✅ BON - Icône panier avec badge
          Stack(
            children: [
              IconButton(
                key: const ValueKey(TestKeys.cartIcon),
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {},
              ),
              Positioned(
                right: 0,
                child: Container(
                  key: const ValueKey(TestKeys.cartBadge),
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${items.length}'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Liste des items
          Expanded(
            child: ListView.builder(
              key: const ValueKey(TestKeys.cartItemsList),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Card(
                  key: ValueKey(TestKeys.withIndex(TestKeys.cartItem, index)),
                  child: Row(
                    children: [
                      // Info produit
                      Expanded(
                        child: Text(items[index]['name']),
                      ),

                      // Contrôles quantité
                      IconButton(
                        key: ValueKey(TestKeys.withIndex(
                            TestKeys.quantityDecrement, index)),
                        icon: const Icon(Icons.remove),
                        onPressed: () {},
                      ),
                      Text('${items[index]['quantity']}'),
                      IconButton(
                        key: ValueKey(TestKeys.withIndex(
                            TestKeys.quantityIncrement, index)),
                        icon: const Icon(Icons.add),
                        onPressed: () {},
                      ),

                      // Supprimer
                      IconButton(
                        key: ValueKey(TestKeys.withIndex(
                            TestKeys.removeFromCartButton, index)),
                        icon: const Icon(Icons.delete),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Total et checkout
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:'),
                    Text(
                      '25,000 FCFA',
                      key: const ValueKey(TestKeys.cartTotal),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const ValueKey(TestKeys.checkoutButton),
                  onPressed: () {},
                  child: const Text('Passer la commande'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXEMPLE 5: Navigation Bottom Bar
// ═══════════════════════════════════════════════════════════════

class MainNavigationExample extends StatefulWidget {
  const MainNavigationExample({super.key});

  @override
  State<MainNavigationExample> createState() => _MainNavigationExampleState();
}

class _MainNavigationExampleState extends State<MainNavigationExample> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          Center(child: Text('Home')),
          Center(child: Text('Interventions')),
          Center(child: Text('Boutique')),
          Center(child: Text('Notifications')),
          Center(child: Text('Profil')),
        ],
      ),

      // ✅ BON - BottomNavigationBar avec keys
      bottomNavigationBar: BottomNavigationBar(
        key: const ValueKey(TestKeys.bottomNav),
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            key: const ValueKey(TestKeys.homeTab),
            icon: const Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            key: const ValueKey(TestKeys.interventionsTab),
            icon: const Icon(Icons.build),
            label: 'Interventions',
          ),
          BottomNavigationBarItem(
            key: const ValueKey(TestKeys.shopTab),
            icon: const Icon(Icons.shopping_bag),
            label: 'Boutique',
          ),
          BottomNavigationBarItem(
            key: const ValueKey(TestKeys.notificationsTab),
            icon: const Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            key: const ValueKey(TestKeys.profileTab),
            icon: const Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CHECKLIST POUR AJOUTER DES KEYS
// ═══════════════════════════════════════════════════════════════

/// CHECKLIST: Widgets à Keyer
/// 
/// ✅ Tous les TextField/TextFormField
/// ✅ Tous les boutons (ElevatedButton, TextButton, IconButton, FAB)
/// ✅ Tous les Dropdown/Select
/// ✅ Toutes les listes (ListView, GridView)
/// ✅ Tous les items de liste (avec index)
/// ✅ Tous les écrans/pages principales
/// ✅ Tous les éléments de navigation
/// ✅ Tous les éléments cliquables critiques
/// 
/// ❌ Ne PAS keyer:
/// - Widgets purement décoratifs (Container, Padding)
/// - Textes statiques non-interactifs
/// - Icons dans des boutons déjà keyés

// ═══════════════════════════════════════════════════════════════
// COMMENT UTILISER DANS VOS WIDGETS EXISTANTS
// ═══════════════════════════════════════════════════════════════

/// 1. Importer TestKeys
///    import 'package:mct_maintenance_mobile/utils/test_keys.dart';
/// 
/// 2. Ajouter les keys aux widgets
///    TextField(
///      key: const ValueKey(TestKeys.emailField),
///      // ... reste du code
///    )
/// 
/// 3. Pour les listes, utiliser l'index
///    ListView.builder(
///      itemBuilder: (context, index) {
///        return ListTile(
///          key: ValueKey(TestKeys.withIndex(TestKeys.intervention, index)),
///          // ... reste du code
///        );
///      },
///    )
