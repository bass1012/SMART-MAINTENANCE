# 📱 Accès aux Commandes - Application Mobile

## ✅ Comment Voir la Liste des Commandes

Il existe **3 façons** d'accéder à la liste des commandes dans l'application mobile :

---

## 🎯 Méthode 1 : Depuis le Dashboard (Nouveau)

### **Carte "Commandes" dans la grille des services**

1. Ouvrir l'application mobile
2. Vous êtes sur le **Tableau de Bord Client**
3. Scroller vers le bas jusqu'à la section **"Services"**
4. Cliquer sur la carte **"Commandes"** (icône 🛍️, couleur orange)
5. ✅ L'écran d'historique s'ouvre avec l'onglet "Commandes"

**Interface :**
```
┌─────────────────────────────────┐
│  Tableau de Bord Client         │
├─────────────────────────────────┤
│  Services                       │
│                                 │
│  ┌──────────┐  ┌──────────┐   │
│  │🔧 Inter- │  │📋 Devis  │   │
│  │ventions  │  │et Contrat│   │
│  └──────────┘  └──────────┘   │
│                                 │
│  ┌──────────┐  ┌──────────┐   │
│  │📊 Rapport│  │⚠️  Récla-│   │
│  │mainten.  │  │mation    │   │
│  └──────────┘  └──────────┘   │
│                                 │
│  ┌──────────┐  ┌──────────┐   │
│  │🔧 Offre  │  │🛒 Boutique│  │
│  │entretien │  │          │   │
│  └──────────┘  └──────────┘   │
│                                 │
│  ┌──────────┐  ┌──────────┐   │
│  │🛍️ Comman-│  │🧾 Factures│  │
│  │des       │  │          │   │ ← NOUVEAU
│  └──────────┘  └──────────┘   │
└─────────────────────────────────┘
```

---

## 🎯 Méthode 2 : Depuis le Menu Latéral

### **Option "Historique" dans le drawer**

1. Ouvrir l'application mobile
2. Cliquer sur l'icône **☰** (menu hamburger) en haut à gauche
3. Le menu latéral s'ouvre
4. Cliquer sur **"Historique"** (icône 🕒)
5. ✅ L'écran d'historique s'ouvre avec 3 onglets

**Menu Latéral :**
```
┌─────────────────────────────────┐
│  Bakary Madou CISSE             │
│  cisse.bakary@gmail.com         │
├─────────────────────────────────┤
│  🏠 Accueil                      │
│  👤 Mon Profil                   │
│  🕒 Historique                   │ ← CLIQUER ICI
│  🧾 Factures                     │
│  ❓ Aide & Support               │
│  ─────────────────              │
│  ⚙️  Paramètres                  │
│                                 │
│  [Déconnexion]                  │
└─────────────────────────────────┘
```

---

## 🎯 Méthode 3 : Depuis la Carte Statistique

### **Cliquer sur la carte "Commandes" dans les statistiques**

1. Ouvrir l'application mobile
2. Sur le **Tableau de Bord**, en haut vous voyez les statistiques
3. Cliquer sur la carte **"Commandes"** (affiche le nombre total)
4. ✅ Navigation vers l'historique (si implémenté)

**Statistiques :**
```
┌─────────────────────────────────┐
│  Statistiques                   │
│                                 │
│  ┌──────────┐  ┌──────────┐   │
│  │🔧 Inter- │  │📋 Devis  │   │
│  │ventions  │  │          │   │
│  │    5     │  │    3     │   │
│  └──────────┘  └──────────┘   │
│                                 │
│  ┌──────────┐  ┌──────────┐   │
│  │🛍️ Comman-│  │💰 Dépenses│  │
│  │des       │  │          │   │
│  │    6     │  │ 7550000  │   │ ← Cliquer ici
│  └──────────┘  └──────────┘   │
└─────────────────────────────────┘
```

---

## 📋 Écran d'Historique

### **3 Onglets Disponibles**

Une fois dans l'écran d'historique, vous avez accès à 3 onglets :

```
┌─────────────────────────────────┐
│  ← Historique                   │
├─────────────────────────────────┤
│  [Interventions] [Commandes] [Devis]
│       ↓            ↓          ↓
│    Onglet 1     Onglet 2   Onglet 3
└─────────────────────────────────┘
```

#### **Onglet 1 : Interventions**
- Liste des interventions passées
- Statut : Terminé, En cours, Annulé
- Date et description

#### **Onglet 2 : Commandes** ← VOTRE OBJECTIF
- Liste de toutes vos commandes
- Référence de la commande
- Date de création
- Montant total en FCFA
- Statut : En attente, Livré, Annulé
- **Clic sur une commande** → Écran de détail

#### **Onglet 3 : Devis**
- Liste des devis reçus
- Référence du devis
- Date d'émission
- Montant
- Statut : En attente, Accepté, Refusé

---

## 🛍️ Détails d'une Commande

### **Cliquer sur une commande pour voir les détails**

**Informations affichées :**
- ✅ Référence de la commande
- ✅ Date de création
- ✅ Statut (En attente, Livré, Annulé)
- ✅ Adresse de livraison
- ✅ Méthode de paiement
- ✅ Liste des articles commandés
  - Nom du produit
  - Quantité
  - Prix unitaire
  - Total par article
- ✅ Montant total en FCFA
- ✅ Bouton "Télécharger la facture PDF"

**Interface Détail :**
```
┌─────────────────────────────────┐
│  ← Détails de la Commande       │
├─────────────────────────────────┤
│  CMD-1761052570922              │
│  [En attente]                   │
│                                 │
│  📅 Date: 22/10/2025            │
│  📍 Livraison: Cocody, Abidjan  │
│  💳 Paiement: Mobile Money      │
│                                 │
│  Articles commandés:            │
│  ┌─────────────────────────┐   │
│  │ Pompe à chaleur         │   │
│  │ Qté: 2 × 1500000 FCFA   │   │
│  │ Total: 3000000 FCFA     │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Montant Total           │   │
│  │     3020000 FCFA        │   │
│  └─────────────────────────┘   │
│                                 │
│  [📄 Télécharger la facture]   │
└─────────────────────────────────┘
```

---

## 🔄 Flux Complet

### **Parcours Utilisateur**

```
Tableau de Bord
    ↓
Cliquer sur "Commandes" (carte orange)
    ↓
Écran Historique
    ↓
Onglet "Commandes" (automatiquement sélectionné)
    ↓
Liste des commandes affichée
    ↓
Cliquer sur une commande
    ↓
Écran de détail de la commande
    ↓
Voir tous les détails + articles
    ↓
[Optionnel] Télécharger la facture PDF
```

---

## 📊 Données Affichées

### **Liste des Commandes**

Chaque commande dans la liste affiche :

| Élément | Description |
|---------|-------------|
| **Titre** | "Commande #[ID]" |
| **Date** | Date de création (format: JJ/MM/AAAA) |
| **Montant** | Montant total en FCFA |
| **Statut** | Badge coloré (Vert=Livré, Orange=En attente, Rouge=Annulé) |
| **Description** | Notes ou adresse de livraison |

**Exemple :**
```
┌─────────────────────────────────┐
│  Commande #4                    │
│  📅 22/10/2025                  │
│  💰 3020000 FCFA                │
│  [En attente]                   │
│  📍 Cocody, Abidjan             │
└─────────────────────────────────┘
```

---

## 🎨 Design

### **Couleurs et Icônes**

**Carte "Commandes" :**
- Icône : `shopping_bag_outlined` 🛍️
- Couleur : Orange (`Colors.orange`)
- Position : Grille des services, 4ème ligne

**Statuts des Commandes :**
- ✅ **Livré** : Vert (`Colors.green`)
- ⏳ **En attente** : Orange (`Colors.orange`)
- ❌ **Annulé** : Rouge (`Colors.red`)

**Couleur Principale :**
- Vert MCT : `#0a543d`

---

## 🧪 Test

### **Vérifier que tout fonctionne**

1. **Lancer l'application**
   ```bash
   cd mct_maintenance_mobile
   flutter run
   ```

2. **Se connecter**
   - Email : `cisse.bakary@gmail.com`
   - Mot de passe : [votre mot de passe]

3. **Accéder aux commandes**
   - Méthode 1 : Cliquer sur la carte "Commandes" dans le dashboard
   - Méthode 2 : Menu ☰ → "Historique"

4. **Vérifier l'affichage**
   - ✅ Liste des commandes visible
   - ✅ Onglet "Commandes" actif
   - ✅ Données chargées depuis l'API

5. **Tester le détail**
   - Cliquer sur une commande
   - ✅ Écran de détail s'affiche
   - ✅ Toutes les informations visibles
   - ✅ Bouton de téléchargement PDF présent

---

## 📝 Fichiers Modifiés

### **Application Mobile**

1. ✅ `/lib/screens/customer/customer_main_screen.dart`
   - Import de `HistoryScreen`
   - Ajout de la carte "Commandes" dans la grille
   - Ajout de la carte "Factures" dans la grille
   - Navigation vers `HistoryScreen`

2. ✅ `/lib/screens/customer/history_screen.dart` (existant)
   - Affiche les 3 onglets (Interventions, Commandes, Devis)
   - Charge les commandes depuis l'API
   - Navigation vers `OrderDetailScreen`

3. ✅ `/lib/screens/customer/order_detail_screen.dart` (existant)
   - Affiche les détails complets d'une commande
   - Bouton de téléchargement PDF

4. ✅ `/lib/widgets/common/custom_drawer.dart` (existant)
   - Option "Historique" dans le menu latéral

---

## 🔌 API Backend

### **Endpoint Utilisé**

**GET `/api/customer/orders`**
- Récupère la liste des commandes du client connecté
- Authentification JWT requise
- Retourne : `{ success: true, data: [...] }`

**Données Retournées :**
```json
{
  "success": true,
  "data": [
    {
      "id": 4,
      "reference": "CMD-1761052570922",
      "customer_id": 9,
      "total_amount": 3020000,
      "status": "pending",
      "notes": "Livraison à Cocody",
      "shipping_address": "Cocody, Abidjan",
      "payment_method": "mobile_money",
      "created_at": "2025-10-22T10:30:00.000Z",
      "customer": {
        "id": 9,
        "first_name": "Bakary Madou",
        "last_name": "CISSE",
        "email": "cisse.bakary@gmail.com"
      },
      "items": [
        {
          "id": 1,
          "product_id": 5,
          "quantity": 2,
          "unit_price": 1500000,
          "total": 3000000,
          "product": {
            "id": 5,
            "name": "Pompe à chaleur",
            "description": "...",
            "price": 1500000
          }
        }
      ]
    }
  ]
}
```

---

## ✅ Résultat Final

### **Avant**

```
❓ Comment voir les commandes ?
   → Pas de carte visible dans le dashboard
   → Seulement accessible via le menu latéral
```

### **Après**

```
✅ 3 façons d'accéder aux commandes :
   1. Carte "Commandes" dans le dashboard
   2. Menu latéral → "Historique"
   3. Carte statistique "Commandes"

✅ Écran d'historique avec 3 onglets
✅ Liste des commandes avec détails
✅ Clic sur commande → Écran de détail
✅ Téléchargement de facture PDF
```

---

## 🎯 Fonctionnalités Complètes

- ✅ **Accès facile** - Carte visible dans le dashboard
- ✅ **Navigation intuitive** - 3 façons d'accéder
- ✅ **Affichage clair** - Liste avec statuts colorés
- ✅ **Détails complets** - Toutes les informations
- ✅ **Articles** - Liste des produits commandés
- ✅ **Montants** - Prix en FCFA
- ✅ **PDF** - Téléchargement de facture
- ✅ **Design** - Interface professionnelle MCT

**L'accès aux commandes est maintenant simple et intuitif !** 🛍️✨
