# 🧪 Guide de test - Système de notifications

## ✅ Prérequis

- [x] Backend démarré sur port 3000
- [x] Dashboard démarré sur port 3001
- [x] Dashboard rafraîchi (CTRL+SHIFT+R)
- [x] Connecté avec admin@mct-maintenance.com
- [x] Console ouverte (F12)
- [x] Socket.IO connecté (voir logs dans la console)

---

## 🎯 TEST 1 : Intervention

### **Méthode A : App Mobile Flutter (RECOMMANDÉ)**

**Avantages** : Test complet et réaliste du flux utilisateur

**Procédure :**

1. **Lancer l'app mobile** :
   ```bash
   cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
   flutter run
   ```

2. **Se connecter avec un compte client**

3. **Créer une intervention** :
   - Onglet "Interventions"
   - Bouton "+" en bas à droite
   - Remplir le formulaire :
     * Titre : "Test notification - Climatiseur"
     * Description : "Test du système"
     * Date : Aujourd'hui
     * Priorité : Haute
   - Soumettre

4. **Vérifier le dashboard** :
   - [ ] Badge "1" sur la cloche 🔔
   - [ ] Toast "Nouvelle demande d'intervention"
   - [ ] Console : `🔔 Nouvelle notification reçue`

5. **Cliquer sur la cloche** :
   - [ ] Dropdown s'ouvre
   - [ ] Notification visible avec bordure bleue
   - [ ] Icône ⚠️ (priorité haute)
   - [ ] Message : "X a créé une demande d'intervention"

6. **Cliquer sur la notification** :
   - [ ] Navigation vers `/interventions`
   - [ ] Notification devient grise
   - [ ] Badge se décrémente

---

### **Méthode B : Script de test**

**Avantages** : Plus rapide, pas besoin de l'app mobile

**Procédure :**

1. **Obtenir un token** :
   - Dashboard → F12 → Console
   - Taper : `localStorage.getItem('token')`
   - Copier le token (sans les guillemets)

2. **Lancer le script** :
   ```bash
   cd /Users/bassoued/Documents/MAINTENANCE
   ./test-intervention-notification.sh VOTRE_TOKEN
   ```

3. **Vérifier le dashboard** :
   - [ ] Badge apparaît
   - [ ] Toast visible
   - [ ] Notification dans le dropdown

---

## 🎯 TEST 2 : Réclamation

### **Méthode : Script de test**

```bash
./test-complaint-notification.sh VOTRE_TOKEN
```

**Vérifications :**
- [ ] Badge s'incrémente
- [ ] Toast "Nouvelle réclamation"
- [ ] Clic sur notification → `/reclamations/:id`
- [ ] Page de détails de la réclamation

---

## 🎯 TEST 3 : Commande

### **Méthode : Script de test**

```bash
./test-order-notification.sh VOTRE_TOKEN
```

**Vérifications :**
- [ ] Badge s'incrémente
- [ ] Toast "Nouvelle commande"
- [ ] Clic sur notification → `/commandes/:id`
- [ ] Page de détails de la commande

---

## 🎯 TEST 4 : Fonctionnalités du composant

### **Badge**
- [ ] Badge apparaît avec le bon nombre
- [ ] Badge disparaît quand tout est lu
- [ ] Animation pulse du badge

### **Toast**
- [ ] Toast apparaît pour chaque nouvelle notification
- [ ] Icône correspond à la priorité
- [ ] Toast disparaît après 4 secondes
- [ ] Plusieurs toasts s'empilent correctement

### **Dropdown**
- [ ] S'ouvre au clic sur la cloche
- [ ] Affiche toutes les notifications
- [ ] Scroll si plus de 5 notifications
- [ ] Bouton "Tout marquer comme lu" visible

### **Notification individuelle**
- [ ] Bordure bleue si non lue
- [ ] Titre en gras si non lue
- [ ] Icône selon priorité :
  * 🔴 Urgent
  * ⚠️ High
  * 🔵 Medium
  * ✅ Low
- [ ] Date relative ("Il y a X min")
- [ ] Fond coloré selon priorité

### **Actions**
- [ ] Clic sur notification → Navigation
- [ ] Clic sur ✓ → Marquer comme lue
- [ ] Clic sur 🗑️ → Supprimer
- [ ] "Tout marquer comme lu" fonctionne

---

## 🎯 TEST 5 : Temps réel

### **Test de latence**

1. **Préparer** :
   - Dashboard ouvert
   - Console visible
   - Chronomètre prêt

2. **Créer une intervention depuis le mobile**

3. **Mesurer le temps** :
   - Entre la soumission mobile et l'apparition du badge
   - **Résultat attendu** : < 1 seconde

4. **Vérifier les logs** :
   - Console backend : `📬 Notification créée`
   - Console dashboard : `🔔 Nouvelle notification reçue`

---

## 🎯 TEST 6 : Persistance

### **Test de rechargement**

1. **Créer 3 notifications** (intervention, réclamation, commande)

2. **Rafraîchir le dashboard** (F5)

3. **Vérifier** :
   - [ ] Badge affiche "3"
   - [ ] Dropdown affiche les 3 notifications
   - [ ] Notifications dans le bon ordre (plus récent en premier)

---

## 🎯 TEST 7 : Notifications multiples

### **Test de flood**

1. **Créer rapidement plusieurs interventions** (5+)

2. **Vérifier** :
   - [ ] Tous les toasts apparaissent
   - [ ] Badge se met à jour correctement
   - [ ] Pas de doublons dans le dropdown
   - [ ] Pas d'erreurs dans la console

---

## 📊 Checklist finale

### **Fonctionnalités de base**
- [ ] Socket.IO connecté
- [ ] Notifications en temps réel
- [ ] Badge avec compteur
- [ ] Toast pour nouvelles notifications

### **Navigation**
- [ ] Interventions → `/interventions`
- [ ] Réclamations → `/reclamations/:id`
- [ ] Commandes → `/commandes/:id`
- [ ] Pas d'erreur 404

### **Actions utilisateur**
- [ ] Marquer comme lu
- [ ] Supprimer
- [ ] Marquer tout comme lu
- [ ] Clic pour naviguer

### **UI/UX**
- [ ] Animations fluides
- [ ] Couleurs correctes
- [ ] Icônes appropriées
- [ ] Responsive

---

## 🐛 Dépannage

### **Problème : Pas de badge**

**Vérifications :**
1. Console du dashboard → Chercher "Socket.IO connecté"
2. Si absent → Rafraîchir (CTRL+SHIFT+R)
3. Vérifier le backend → `curl http://localhost:3000/health`

### **Problème : Toast ne s'affiche pas**

**Vérifications :**
1. Console → Chercher "Nouvelle notification reçue"
2. Si absent → Socket.IO non connecté
3. Vérifier les logs backend

### **Problème : 404 au clic**

**Solution :**
```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
sqlite3 database.sqlite "UPDATE notifications SET action_url = '/interventions' WHERE type = 'intervention_request';"
```

---

## 📈 Résultats attendus

### **Performance**
- Latence : < 1 seconde
- Pas de lag dans l'interface
- Pas d'erreurs dans la console

### **Fiabilité**
- 100% des notifications reçues
- Pas de doublons
- Synchronisation DB ↔ UI

### **UX**
- Interface intuitive
- Feedback visuel clair
- Navigation fluide

---

**Tous les tests passent ? Le système est prêt pour la production ! 🎉**
