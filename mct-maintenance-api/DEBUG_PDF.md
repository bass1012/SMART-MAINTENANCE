# 🐛 Dépannage - PDF vide ou sans contenu

## ✅ Test réussi

Le test de génération de PDF fonctionne correctement :
```bash
node test-pdf.js
```

**Résultat :** PDF de 223 KB généré avec succès ✅

---

## 🔍 Diagnostic du problème

Si le PDF téléchargé depuis le dashboard est vide, voici les étapes de débogage :

### 1. Vérifier les logs du serveur

Lorsque vous cliquez sur "Télécharger" dans le dashboard, vous devriez voir ces logs :

```
📄 Téléchargement facture pour commande: 4
✅ Commande trouvée: { id: 4, reference: 'CMD-XXX', ... }
📦 Données de la commande: { ... }
🔄 Génération du PDF...
🚀 Démarrage génération PDF...
🎨 Génération HTML pour commande: 4
📋 Items: 2
👤 Customer: Présent
✅ PDF généré, taille: 223960 bytes
```

### 2. Problèmes possibles

#### A. Commande sans articles (items)
**Symptôme :** `📋 Items: 0`

**Solution :**
```sql
-- Vérifier les items de la commande
SELECT * FROM order_items WHERE order_id = 4;
```

#### B. Client (customer) manquant
**Symptôme :** `👤 Customer: Absent`

**Solution :**
```sql
-- Vérifier le client
SELECT * FROM orders WHERE id = 4;
SELECT * FROM users WHERE id = (SELECT customer_id FROM orders WHERE id = 4);
```

#### C. Données Sequelize non converties
**Symptôme :** Erreur dans les logs

**Solution :** Le contrôleur convertit maintenant automatiquement avec `.toJSON()`

---

## 🔧 Solutions

### Solution 1 : Redémarrer le serveur backend

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start
```

### Solution 2 : Vérifier les données de la commande

```bash
# Tester avec curl
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/api/payments/invoice/4/download \
  --output test-download.pdf
```

### Solution 3 : Vérifier que Puppeteer fonctionne

```bash
# Test rapide
node test-pdf.js
```

Si ce test fonctionne mais pas le téléchargement depuis le dashboard, le problème vient des données de la commande.

---

## 📊 Vérifier les données d'une commande

```javascript
// Dans la console Node.js
const { Order, User } = require('./src/models');

async function checkOrder(orderId) {
  const order = await Order.findByPk(orderId, {
    include: [
      {
        model: User,
        as: 'customer',
        attributes: ['id', 'email', 'first_name', 'last_name', 'phone']
      },
      {
        model: require('./src/models').OrderItem,
        as: 'items',
        include: [
          {
            model: require('./src/models').Product,
            as: 'product'
          }
        ]
      }
    ]
  });
  
  console.log('Commande:', order.toJSON());
}

checkOrder(4);
```

---

## 🎯 Checklist de vérification

- [ ] Le serveur backend est démarré
- [ ] Puppeteer est installé (`npm list puppeteer`)
- [ ] Le test `node test-pdf.js` fonctionne
- [ ] La commande a des articles (items)
- [ ] La commande a un client (customer)
- [ ] Les logs s'affichent dans le terminal
- [ ] Le token JWT est valide
- [ ] Le PDF téléchargé n'est pas vide (> 200 KB)

---

## 📝 Logs attendus (succès)

```
📄 Téléchargement facture pour commande: 4
✅ Commande trouvée: {
  id: 4,
  reference: 'CMD-XXX',
  customer: 'Jean Kouassi',
  itemsCount: 2,
  totalAmount: 150000
}
📦 Données de la commande: { ... }
🔄 Génération du PDF...
🚀 Démarrage génération PDF...
🎨 Génération HTML pour commande: 4
📋 Items: 2
👤 Customer: Présent
📝 HTML généré, longueur: 7654 caractères
🌐 Lancement de Puppeteer...
✅ Puppeteer lancé
📄 Nouvelle page créée
⏳ Chargement du contenu HTML...
✅ HTML chargé
🖨️ Génération du PDF...
✅ PDF généré, taille: 223960 bytes
🔒 Navigateur fermé
✅ PDF généré, taille: 223960 bytes
```

---

## 🆘 Si rien ne fonctionne

1. **Supprimer et réinstaller Puppeteer :**
   ```bash
   npm uninstall puppeteer
   npm install puppeteer
   ```

2. **Vérifier les permissions :**
   ```bash
   # macOS
   xcode-select --install
   ```

3. **Tester avec une commande simple :**
   ```bash
   node test-pdf.js
   ```

4. **Vérifier les logs du navigateur :**
   Les logs détaillés vous indiqueront exactement où le problème se situe.

---

## 📞 Contact

Si le problème persiste après toutes ces vérifications, partagez :
- Les logs complets du serveur
- Le résultat de `node test-pdf.js`
- La taille du PDF téléchargé
- Les données de la commande (sans informations sensibles)
