# 📄 Layout de la Facture PDF - MCT Maintenance

## 🎨 Nouveau Design

### En-tête avec logo à gauche et informations à droite

```
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│  [LOGO MCT]                              FACTURE             │
│  (120px)                                 MCT Maintenance     │
│                                          Service pro - CI    │
│                                                               │
├───────────────────────────────────────────────────────────────┤
```

## 📐 Structure CSS

### Layout Flexbox

```css
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 3px solid #0a543d;
}
```

### Section Logo (Gauche)

```css
.logo-section {
  flex: 0 0 auto;  /* Ne grandit pas, ne rétrécit pas */
}

.logo {
  max-width: 120px;
  height: auto;
}
```

### Section Info (Droite)

```css
.info-section {
  flex: 1;              /* Prend l'espace restant */
  text-align: right;    /* Aligné à droite */
  padding-left: 20px;
}

h1 {
  font-size: 36px;
  color: #0a543d;
}

.company-name {
  font-size: 20px;
  color: #666;
  font-weight: 600;
}

.tagline {
  font-size: 14px;
  color: #888;
}
```

## 🏗️ Structure HTML

```html
<div class="header">
  <!-- Logo à gauche -->
  <div class="logo-section">
    <img src="[base64]" alt="MCT Maintenance" class="logo" />
  </div>
  
  <!-- Informations à droite -->
  <div class="info-section">
    <h1>FACTURE</h1>
    <div class="company-name">MCT Maintenance</div>
    <div class="tagline">Service de maintenance professionnel - Côte d'Ivoire</div>
  </div>
</div>
```

## 📊 Comparaison Avant/Après

### Avant (Centré)
```
        [LOGO]
       FACTURE
   MCT Maintenance
Service professionnel
```

### Après (Logo gauche, Info droite)
```
[LOGO]              FACTURE
                MCT Maintenance
         Service professionnel - CI
```

## ✅ Avantages du nouveau layout

1. **Plus professionnel** - Layout moderne avec logo à gauche
2. **Meilleure utilisation de l'espace** - Optimisation horizontale
3. **Hiérarchie visuelle claire** - Logo = identité, Droite = document
4. **Conforme aux standards** - Format classique des factures professionnelles

## 🎯 Éléments clés

- **Logo**: 120px max, aligné à gauche
- **Titre "FACTURE"**: 36px, vert MCT (#0a543d), aligné à droite
- **Nom entreprise**: 20px, gris foncé, aligné à droite
- **Tagline**: 14px, gris clair, aligné à droite
- **Bordure**: 3px solid #0a543d sous l'en-tête

## 📱 Responsive

Le layout utilise Flexbox pour s'adapter automatiquement :
- Logo garde sa taille fixe
- Section info prend l'espace restant
- Alignement vertical centré avec `align-items: center`

## 🖨️ Impression

Le design est optimisé pour l'impression A4 :
- Marges: 40px (20px en mode print)
- Format: A4 (210mm x 297mm)
- Couleurs: Optimisées pour impression couleur ou N&B

## 📝 Fichier modifié

`/src/services/pdfService.js`
- CSS: Flexbox layout pour l'en-tête
- HTML: Structure avec logo-section et info-section
