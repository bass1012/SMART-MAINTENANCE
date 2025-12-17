# ✅ Écran Devis et Contrats - Affichage en Sections

## 🎯 Modifications Apportées

L'écran "Devis et Contrats" a été complètement revu pour afficher **les devis ET les contrats** dans des **sections séparées** avec un système d'onglets.

---

## 📱 Nouvelle Interface

### **TabBar avec 2 Onglets :**

```
┌─────────────────────────────────────────┐
│ Mes Devis et Contrats                   │
├─────────────────────────────────────────┤
│  📄 Devis (2)  │  📋 Contrats (1)      │ ← Onglets cliquables
├─────────────────────────────────────────┤
│                                         │
│  [Contenu de l'onglet actif]          │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📄 Onglet Devis

**Affichage :**
- Liste de tous les devis du client
- Référence + Titre + Description
- Statut (Brouillon, Envoyé, Accepté, Refusé, Expiré)
- Montant en FCFA
- Date de validité
- Boutons "Accepter" / "Refuser" si statut = "pending"

**Carte de Devis :**
```
┌─────────────────────────────────────┐
│ DEV-2025-001        [Accepté ✓]    │
│ Installation climatisation          │
│ Description du devis...             │
│ ─────────────────────────────────   │
│ 150 000 FCFA    Valable jusqu'au... │
└─────────────────────────────────────┘
```

**États :**
- ✅ **Chargement** : Spinner
- ✅ **Erreur** : Message + bouton "Réessayer"
- ✅ **Vide** : Icône + "Aucun devis trouvé"
- ✅ **Pull-to-refresh** : Glisser vers le bas pour actualiser

---

## 📋 Onglet Contrats (NOUVEAU)

**Affichage :**
- Liste de tous les contrats du client
- Référence + Titre + Description
- Type (Maintenance, Support, Garantie, Service)
- Statut (Brouillon, En attente, Actif, Expiré, Terminé)
- Dates de début et fin
- Montant + Fréquence de paiement
- Icône selon le type de contrat

**Carte de Contrat :**
```
┌─────────────────────────────────────┐
│ 🔧 CONT-2025-001      [Actif ✓]    │
│    Contrat maintenance annuel       │
│    Maintenance préventive...        │
│ ─────────────────────────────────   │
│ 📅 Début: 01/01/2025               │
│ 📅 Fin: 31/12/2025                 │
│ ─────────────────────────────────   │
│ Montant              [Annuel]       │
│ 50 000 FCFA                         │
└─────────────────────────────────────┘
```

**Détails Affichés :**
- **Icône du type** : 🔧 Maintenance, 🎧 Support, ✅ Garantie, 🛎️ Service
- **Statut coloré** : Vert (Actif), Orange (En attente), Rouge (Expiré), Gris (Terminé)
- **Dates** : Début et fin du contrat
- **Alerte** : Date de fin en orange si < 30 jours (pour contrats actifs)
- **Fréquence** : Mensuel, Trimestriel, Annuel, Unique

**États :**
- ✅ **Chargement** : Spinner
- ✅ **Erreur** : Message + bouton "Réessayer"
- ✅ **Vide** : Icône + "Aucun contrat trouvé"
- ✅ **Pull-to-refresh** : Glisser vers le bas pour actualiser

---

## 🎨 Design et UX

### **Couleurs des Statuts :**

**Devis :**
- 🔵 **Bleu** : Envoyé
- 🟢 **Vert** : Accepté
- 🔴 **Rouge** : Refusé
- 🟠 **Orange** : Expiré
- ⚪ **Gris** : Brouillon

**Contrats :**
- 🟢 **Vert** : Actif
- 🟠 **Orange** : En attente
- 🔴 **Rouge** : Expiré
- ⚪ **Gris** : Terminé / Brouillon

### **Icônes des Types de Contrats :**
- 🔧 **Maintenance** : `Icons.build_circle`
- 🎧 **Support** : `Icons.support_agent`
- ✅ **Garantie** : `Icons.verified_user`
- 🛎️ **Service** : `Icons.room_service`

### **Interactions :**
- **Tap sur un devis** → Ouvre les détails (écran existant)
- **Tap sur un contrat** → Message "Détails du contrat à venir" (TODO)
- **Swipe down** → Rafraîchit la liste
- **Boutons Accepter/Refuser** → Actions sur les devis en attente

---

## 🔧 Fichiers Créés/Modifiés

### **1. Nouveau Modèle : `contract_model.dart`**
```dart
class Contract {
  final int id;
  final String reference;
  final String title;
  final String description;
  final String type;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String paymentFrequency;
  // ... autres champs
}
```

### **2. Mise à jour : `api_service.dart`**
```dart
// Nouvelle méthode
Future<List<Contract>> getCustomerContracts() async {
  final response = await _handleRequest('GET', '/api/customer/contracts');
  return (response['data'] as List)
      .map((item) => Contract.fromJson(item))
      .toList();
}
```

### **3. Refonte : `quotes_contracts_screen.dart`**
- Ajout de `TabController` pour gérer les onglets
- Séparation en 2 onglets : Devis et Contrats
- Chargement indépendant des devis et contrats
- Gestion d'erreurs séparée
- Pull-to-refresh sur chaque onglet
- Nouvelle carte de contrat avec design riche

---

## 📊 API Backend Utilisée

### **Devis :**
```
GET /api/customer/quotes
```
**Retourne :** Liste des devis du client

### **Contrats :**
```
GET /api/customer/contracts
```
**Retourne :** Liste des contrats du client

---

## ✅ Fonctionnalités Implémentées

### **Devis :**
- [x] Affichage de la liste
- [x] Détails du devis (écran existant)
- [x] Accepter un devis
- [x] Refuser un devis (TODO)
- [x] Pull-to-refresh
- [x] Gestion des erreurs
- [x] État vide

### **Contrats :**
- [x] Affichage de la liste
- [x] Carte avec toutes les infos
- [x] Icône selon le type
- [x] Statut coloré
- [x] Dates de début/fin
- [x] Alerte si expiration proche
- [x] Fréquence de paiement
- [x] Pull-to-refresh
- [x] Gestion des erreurs
- [x] État vide
- [ ] Détails du contrat (TODO)

---

## 🎯 Prochaines Étapes (TODO)

1. **Créer l'écran de détails du contrat** (`contract_detail_screen.dart`)
   - Afficher toutes les informations
   - Termes et conditions
   - Historique des paiements
   - Actions (renouveler, résilier, etc.)

2. **Implémenter le refus de devis**
   - Ajouter la méthode `rejectQuote()` dans `api_service.dart`
   - Connecter le bouton "Refuser"

3. **Notifications**
   - Alerter si un contrat expire bientôt
   - Notifier lors de la réception d'un nouveau devis

4. **Filtres et tri**
   - Filtrer par statut
   - Trier par date, montant, etc.

---

## 📱 Pour Tester

### **1. Hot restart Flutter :**
```
R
```

### **2. Navigation :**
```
Dashboard → Services → "Devis et Contrat"
```

### **3. Vérifier :**
- ✅ 2 onglets visibles : "Devis" et "Contrats"
- ✅ Compteur dans chaque onglet
- ✅ Devis affichés dans le 1er onglet
- ✅ Contrats affichés dans le 2ème onglet
- ✅ Pull-to-refresh fonctionne
- ✅ Tap sur un devis ouvre les détails
- ✅ Tap sur un contrat affiche un message

---

## 🎨 Aperçu Visuel

### **Onglet Devis :**
```
┌─────────────────────────────────────┐
│ DEV-2025-001        [Accepté ✓]    │
│ Installation climatisation          │
│ Pose d'un système de clim...        │
│ ─────────────────────────────────   │
│ 150 000 FCFA    Valable jusqu'au... │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ DEV-2025-002        [En attente]    │
│ Réparation chaudière                │
│ Remplacement du thermostat...       │
│ ─────────────────────────────────   │
│ 75 000 FCFA     Valable jusqu'au... │
│ [Refuser]           [Accepter]      │
└─────────────────────────────────────┘
```

### **Onglet Contrats :**
```
┌─────────────────────────────────────┐
│ 🔧 CONT-2025-001      [Actif ✓]    │
│    Contrat maintenance annuel       │
│    Maintenance préventive...        │
│ ─────────────────────────────────   │
│ 📅 Début: 01/01/2025               │
│ 📅 Fin: 31/12/2025                 │
│ ─────────────────────────────────   │
│ Montant              [Annuel]       │
│ 50 000 FCFA                         │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 🎧 CONT-2024-015      [Expiré]     │
│    Support technique                │
│    Assistance téléphonique...       │
│ ─────────────────────────────────   │
│ 📅 Début: 01/01/2024               │
│ 📅 Fin: 31/12/2024                 │
│ ─────────────────────────────────   │
│ Montant              [Mensuel]      │
│ 5 000 FCFA                          │
└─────────────────────────────────────┘
```

---

## 🎉 Résultat

**Avant :**
- ❌ Seulement les devis affichés
- ❌ Pas de contrats visibles
- ❌ Interface simple

**Après :**
- ✅ Devis ET contrats affichés
- ✅ Séparation claire en onglets
- ✅ Compteurs visibles
- ✅ Design riche pour les contrats
- ✅ Pull-to-refresh sur chaque section
- ✅ Gestion d'erreurs robuste
- ✅ États vides informatifs

---

**Fais un hot restart (`R`) pour voir les changements !** 🎨📋✨
