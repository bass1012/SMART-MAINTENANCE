# 🧪 Test de Synchronisation Immédiat

## ⚡ **Actions Immédiates**

### **1. Redémarrer l'Application Flutter**

```bash
# Arrêter l'app si elle tourne
# Appuyez sur 'q' dans le terminal où flutter run est actif

# OU tuez le processus
pkill -f flutter

# Redémarrer proprement
cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
flutter run
```

---

### **2. Test Simple en 3 Étapes**

#### **Étape 1 : Côté Client**
1. Ouvrir l'app mobile (client)
2. Se connecter avec le compte client
3. Ouvrir l'intervention #43
4. **REGARDER LA CONSOLE** - Vous devriez voir :
   ```
   🔄 Rafraîchissement initial de l'intervention #43
   📡 Appel API getInterventionById(43)...
   ✅ Réponse API reçue:
      - Ancien statut: pending
      - Nouveau statut: on_the_way
   🔄 CHANGEMENT DE STATUT DÉTECTÉ: pending → on_the_way
   ```

#### **Étape 2 : Vérification**
- ✅ Le statut doit **immédiatement** se mettre à jour à l'ouverture
- ✅ Le stepper doit montrer "En route" (🚗)

#### **Étape 3 : Test du Timer Auto**
1. Laisser l'écran ouvert
2. Attendre 30 secondes
3. Regarder la console - vous devriez voir :
   ```
   ⏰ Timer déclenché - Rafraîchissement auto de l'intervention #43
   📡 Appel API getInterventionById(43)...
   ```

---

## 🔍 **Diagnostic Rapide**

### **Si le statut ne change toujours pas :**

#### **A. Vérifier la console Flutter**

Cherchez ces messages dans la console :

**✅ BONS SIGNES :**
```
🔄 Rafraîchissement initial...
✅ Réponse API reçue
📊 Statut actuel: on_the_way
⏰ Timer déclenché
```

**❌ MAUVAIS SIGNES :**
```
❌ Erreur lors du rafraîchissement
Access denied. No token provided
```

---

#### **B. Vérifier le Statut en Base de Données**

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
sqlite3 database.sqlite "SELECT id, title, status, technician_id FROM interventions WHERE id = 43;"
```

**Résultat attendu :**
```
43|dassadsa|on_the_way|15
```

Si le statut est différent, c'est **ça** le vrai statut.

---

#### **C. Tester l'API Directement**

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
node test-intervention-status.js
```

---

## 🎯 **Actions Correctives**

### **Problème 1 : "Access denied"**

**Cause :** Le token d'authentification a expiré

**Solution :**
```dart
1. Se déconnecter de l'app mobile
2. Se reconnecter
3. Rouvrir l'intervention
```

---

### **Problème 2 : "Ancien statut = Nouveau statut"**

**Cause :** Le statut n'a pas vraiment changé en base

**Solution :**
```bash
# Vérifier le vrai statut en DB
sqlite3 database.sqlite "SELECT status FROM interventions WHERE id = 43;"

# Si c'est "pending", changer le statut côté technicien d'abord
```

---

### **Problème 3 : Pas de logs dans la console**

**Cause :** L'app n'a pas été redémarrée avec les nouveaux changements

**Solution :**
```bash
# Hot restart (plus rapide)
# Appuyez sur 'R' dans la console flutter

# OU redémarrage complet
flutter run
```

---

## 📱 **Voir les Logs en Temps Réel**

### **Sur Android :**
```bash
flutter logs
```

### **Sur iOS :**
```bash
flutter logs
```

### **Filtrer uniquement les logs de synchronisation :**
```bash
flutter logs | grep -E "🔄|📡|✅|⏰|🔄"
```

---

## 🧪 **Scénario de Test Complet**

### **Test 1 : Rafraîchissement Initial**

```
ACTION : Ouvrir l'écran de détail
ATTENDU : Statut se met à jour immédiatement
CONSOLE : "🔄 Rafraîchissement initial..."
RÉSULTAT : Statut affiché = "on_the_way"
```

---

### **Test 2 : Timer Auto (30s)**

```
ÉTAPE 1 : Ouvrir l'écran de détail
ÉTAPE 2 : Attendre 30 secondes
CONSOLE : "⏰ Timer déclenché..."
RÉSULTAT : Les données se rafraîchissent automatiquement
```

---

### **Test 3 : Changement en Temps Réel**

```
PRÉPARATION :
- Téléphone A (client) : Écran de détail ouvert
- Téléphone B (technicien) : Se connecter

ACTION (Téléphone B) :
- Changer le statut (ex: cliquer "Je suis arrivé")

RÉSULTAT (Téléphone A) :
- Sous 30 secondes, le statut change automatiquement
- Console affiche : "🔄 CHANGEMENT DE STATUT DÉTECTÉ: on_the_way → arrived"
```

---

## 🐛 **Debug Avancé**

### **Activer les Logs API**

Éditer `/lib/services/api_service.dart` :

```dart
class ApiConfig {
  static const bool debugLogs = true; // ← Mettre à true
}
```

Cela affichera **toutes** les requêtes API dans la console.

---

### **Vérifier le Token**

Dans la console Flutter, cherchez :

```
🔐 Auth headers: {Authorization: Bearer eyJhbGc...}
```

Si vous voyez `Authorization: null`, le problème vient du token.

---

## ✅ **Checklist de Vérification**

Avant de dire que "ça ne marche pas", vérifiez :

- [ ] L'app Flutter a été **redémarrée** (pas juste hot reload)
- [ ] Le backend est **démarré** (`lsof -i :3000`)
- [ ] L'intervention existe en DB (`SELECT * FROM interventions WHERE id = 43`)
- [ ] Le statut en DB est bien `on_the_way`
- [ ] L'API retourne bien le bon statut (test-intervention-status.js)
- [ ] Le token d'authentification est valide (se reconnecter si doute)
- [ ] Les logs s'affichent dans la console Flutter

---

## 🎯 **Si Tout Est OK mais Ça Ne Marche Toujours Pas**

### **Test Manuel de l'API**

1. **Récupérer le token** dans les logs Flutter :
   ```
   🔐 Auth headers: {Authorization: Bearer TOKEN_ICI}
   ```

2. **Tester l'API avec curl :**
   ```bash
   curl -X GET "http://localhost:3000/api/interventions/43" \
     -H "Authorization: Bearer VOTRE_TOKEN" \
     -H "Content-Type: application/json" | jq
   ```

3. **Vérifier la réponse :**
   ```json
   {
     "success": true,
     "data": {
       "id": 43,
       "status": "on_the_way",  ← Vérifier ça
       "title": "dassadsa"
     }
   }
   ```

---

## 📞 **Informations Utiles**

**Intervention de test :**
- ID: 43
- Client ID: 9
- Technicien ID: 15
- Statut actuel: `on_the_way`

**Commandes rapides :**
```bash
# Statut actuel
sqlite3 database.sqlite "SELECT status FROM interventions WHERE id = 43;"

# Changer manuellement (pour test)
sqlite3 database.sqlite "UPDATE interventions SET status = 'arrived' WHERE id = 43;"

# Vérifier
node test-intervention-status.js
```

---

## 🚀 **Prochaine Étape**

Une fois que le rafraîchissement automatique fonctionne :

1. Tester avec plusieurs interventions
2. Vérifier que le timer s'arrête pour les interventions terminées
3. Tester le pull-to-refresh manuel
4. Vérifier les filtres dans la liste

---

**Date :** 30 octobre 2025  
**Objectif :** Synchronisation automatique fonctionnelle en < 30 secondes
