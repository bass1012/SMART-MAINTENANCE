# 💡 Titre Subtil pour les Onglets

## ✅ Amélioration Ajoutée

### **Indication Visuelle**

Un titre subtil a été ajouté au-dessus des onglets pour indiquer aux utilisateurs qu'ils peuvent **glisser entre les sections**.

---

## 🎨 Interface

### **Avant**

```
┌─────────────────────────────────┐
│  ← Historique            🔄     │
├─────────────────────────────────┤
│  Interventions  Commandes  Devis│
│       ↓            ↓         ↓  │
│    Onglets (pas d'indication)   │
└─────────────────────────────────┘
```

### **Après**

```
┌─────────────────────────────────┐
│  ← Historique            🔄     │
├─────────────────────────────────┤
│  👆 Glissez pour naviguer       │ ← NOUVEAU
│     entre les sections          │
├─────────────────────────────────┤
│  Interventions  Commandes  Devis│
│       ↓            ↓         ↓  │
│              Onglets             │
└─────────────────────────────────┘
```

---

## 📝 Modification

**Fichier :** `/lib/screens/customer/history_screen.dart`

### **Code Ajouté**

```dart
appBar: AppBar(
  title: const Text('Historique'),
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(80), // ← Hauteur augmentée
    child: Column(
      children: [
        // Titre subtil au-dessus des onglets
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.swipe_outlined, // ← Icône de glissement
                size: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Glissez pour naviguer entre les sections',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7), // ← Couleur subtile
                  fontStyle: FontStyle.italic, // ← Style italique
                ),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Interventions'),
            Tab(text: 'Commandes'),
            Tab(text: 'Devis'),
          ],
        ),
      ],
    ),
  ),
),
```

---

## 🎯 Caractéristiques

### **Design Subtil**

1. **Icône** : `swipe_outlined` (👆)
   - Indique le geste de glissement
   - Taille : 16px (petite, discrète)

2. **Texte** : "Glissez pour naviguer entre les sections"
   - Police : 12px (petite)
   - Style : Italique
   - Couleur : Blanc avec opacité 0.7 (subtil)

3. **Position** : Au-dessus des onglets
   - Padding horizontal : 16px
   - Padding vertical : 8px

4. **Hauteur** : `PreferredSize` de 80px
   - 32px pour le titre subtil
   - 48px pour les onglets

---

## 💡 Avantages

### **Expérience Utilisateur**

1. **Découvrabilité**
   - Les utilisateurs savent qu'il y a plusieurs sections
   - Indication claire du geste de navigation

2. **Guidage Subtil**
   - Ne surcharge pas l'interface
   - Discret mais informatif

3. **Accessibilité**
   - Icône + Texte pour une meilleure compréhension
   - Visible mais pas intrusif

4. **Cohérence**
   - S'intègre naturellement dans l'AppBar
   - Couleur harmonieuse avec le thème

---

## 🎨 Variantes Possibles

### **1. Version Plus Courte**

```dart
Text(
  'Glissez entre les sections',
  style: TextStyle(
    fontSize: 11,
    color: Colors.white.withOpacity(0.6),
  ),
),
```

### **2. Version avec Compteur**

```dart
Text(
  '3 sections disponibles',
  style: TextStyle(
    fontSize: 12,
    color: Colors.white.withOpacity(0.7),
  ),
),
```

### **3. Version Animée (Optionnel)**

```dart
AnimatedOpacity(
  opacity: _showHint ? 1.0 : 0.0,
  duration: Duration(milliseconds: 500),
  child: Text('Glissez pour naviguer'),
)
```

---

## 📱 Rendu Visuel

### **AppBar Complet**

```
┌─────────────────────────────────┐
│  ← Historique            🔄     │
│                                 │
│  👆 Glissez pour naviguer       │
│     entre les sections          │
│  ─────────────────────────────  │
│  [Interventions] Commandes Devis│
│        ↑                        │
│     Onglet actif                │
└─────────────────────────────────┘
```

### **Couleurs**

- **Fond AppBar** : Vert MCT (#0a543d)
- **Texte titre** : Blanc (100%)
- **Texte subtil** : Blanc (70% opacité)
- **Icône** : Blanc (70% opacité)
- **Onglet actif** : Blanc avec indicateur
- **Onglet inactif** : Blanc (70% opacité)

---

## 🧪 Test

### **Vérifier l'Affichage**

1. **Relancer l'app**
   ```bash
   cd mct_maintenance_mobile
   flutter run
   ```

2. **Naviguer vers Historique**
   - Menu ☰ → "Historique"
   - OU Carte "Commandes"

3. **Vérifier**
   - ✅ Titre subtil visible au-dessus des onglets
   - ✅ Icône de glissement présente
   - ✅ Texte lisible mais discret
   - ✅ Onglets toujours fonctionnels

4. **Tester le Glissement**
   - Glisser de droite à gauche
   - ✅ Navigation entre les onglets
   - Glisser de gauche à droite
   - ✅ Retour à l'onglet précédent

---

## ✅ Résultat

**Avant :**
- ❓ Utilisateurs ne savent pas qu'il y a plusieurs sections
- Onglets visibles mais pas évidents

**Après :**
- ✅ Indication claire : "Glissez pour naviguer"
- ✅ Icône visuelle du geste
- ✅ Design subtil et professionnel
- ✅ Meilleure découvrabilité des fonctionnalités

**L'interface est plus intuitive !** 💡 Les utilisateurs comprennent immédiatement qu'ils peuvent naviguer entre plusieurs sections.
