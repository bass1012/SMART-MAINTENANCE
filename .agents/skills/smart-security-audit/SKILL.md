---
name: smart-security-audit
description: Audit de cybersécurité complet et hardening pour SMART MAINTENANCE (API Express Node.js & App Flutter Mobile), basé sur les frameworks MITRE ATT&CK, NIST CSF 2.0, MITRE F3 et OWASP Top 10. À utiliser pour vérifier la sécurité de l'authentification, le stockage sécurisé, la protection des devis/paiements, la validation des uploads et la configuration serveur VPS.
---

# Smart Security Audit - Guide & Checklists pour SMART MAINTENANCE

Ce skill guide l'agent IA et le développeur dans l'audit et la sécurisation du projet **SMART MAINTENANCE** (`mct-maintenance-api` et `mct_maintenance_mobile`).

---

## 1. Checklists de Sécurité API Node.js / Express (`mct-maintenance-api`)

### A. Authentification & Contrôle d'Accès (RBAC & BOLA/IDOR)
- [ ] **JWT Security** : Vérifier que le secret JWT est robuste, transmis via en-tête `Authorization: Bearer <token>`, et expiré de façon appropriée.
- [ ] **Protection BOLA/IDOR** : S'assurer que chaque route avec un identifiant en paramètre (ex: `/api/quotes/:id`, `/api/payments/:id`) vérifie explicitement si la ressource appartient au `req.user.id` ou si l'utilisateur est un Admin (`req.user.role === 'admin'`).
- [ ] **Rôles & Permissions** : Valider l'étanchéité entre les rôles `customer`, `technician` et `admin`.

### B. Injections & Validation de Données
- [ ] **Sanitisation SQL / ORM** : S'assurer qu'aucune concaténation de chaîne brute n'est utilisée dans les requêtes Sequelize (`sequelize.query`). Utiliser uniquement les replacements/binds.
- [ ] **Validation des Fichiers Téléchargés** : Vérifier le type MIME réel (Magic Bytes) et l'extension des images/PDFs uploadez. Prévenir le *Path Traversal* sur les chemins de destination.

### C. Sécurité Financière & Devis (MITRE F3)
- [ ] **Intégrité des Montants** : Vérifier que le montant des transactions/paiements est calculé et validé côté serveur à partir du devis en base de données, et **jamais** accepté aveuglément depuis le corps de la requête client (`req.body.amount`).
- [ ] **Signature & Webhooks Paiement** : Sécuriser les callbacks des passerelles de paiement (Orange Money, Wave) avec vérification de signature HMAC/Secret.

### D. Hardening Serveur & En-têtes HTTP
- [ ] **Helmet / CORS / CSP** : Valider les en-têtes HTTP de sécurité via `helmet`.
- [ ] **Rate Limiting** : Protéger les routes sensibles (`/login`, `/register`, `/verify-otp`, `/payments`) contre le brute-force.

---

## 2. Checklists de Sécurité App Mobile Flutter (`mct_maintenance_mobile`)

### A. Stockage Sécurisé & Fuites de Données
- [ ] **Protection des Jetons** : Stocker les tokens JWT et clés d'accès exclusivement dans `flutter_secure_storage` (iOS Keychain / Android Keystore).
- [ ] **Assainissement des Logs** : S'assurer qu'aucun token, mot de passe ou payload sensible n'est affiché dans les logs via `print()` en mode Production.

### B. Communications Réseau
- [ ] **Transport Sécurisé** : Toutes les communications HTTP/REST et WebSockets (Socket.IO) doivent utiliser impérativement `https://` et `wss://`.

---

## 3. Workflow de Vérification DevSecOps

1. Inspecter le code cible avec `grep_search` et `view_file`.
2. Répertorier les vulnérabilités identifiées par ordre de gravité (CRITIQUE, ÉLEVÉE, MOYENNE).
3. Appliquer la correction directement sans impacter les fonctionnalités existantes.
4. Lancer `npm test` pour le backend et `flutter analyze` pour le mobile.
5. Mettre à jour `tasks/lessons.md`.
