mct-maintenance-dashboard/
├── public/
│   ├── index.html
│   ├── favicon.ico
│   └── manifest.json
│
├── src/
│   ├── assets/
│   │   ├── images/
│   │   ├── icons/
│   │   └── styles/
│   │       ├── global.css
│   │       ├── variables.css
│   │       └── components.css
│   │
│   ├── components/
│   │   ├── common/
│   │   │   ├── Layout/
│   │   │   │   ├── Sidebar.js
│   │   │   │   ├── Header.js
│   │   │   │   └── Layout.js
│   │   │   ├── UI/
│   │   │   │   ├── Button.js
│   │   │   │   ├── Input.js
│   │   │   │   ├── Modal.js
│   │   │   │   ├── Table.js
│   │   │   │   ├── Card.js
│   │   │   │   └── Chart.js
│   │   │   └── Forms/
│   │   │       ├── Form.js
│   │   │       ├── FormField.js
│   │   │       └── FormSelect.js
│   │   │
│   │   ├── auth/
│   │   │   ├── Login.js
│   │   │   ├── Register.js
│   │   │   └── ForgotPassword.js
│   │   │
│   │   ├── dashboard/
│   │   │   ├── Dashboard.js
│   │   │   ├── StatsCard.js
│   │   │   ├── ChartCard.js
│   │   │   └── ActivityFeed.js
│   │   │
│   │   ├── users/
│   │   │   ├── UserList.js
│   │   │   ├── UserForm.js
│   │   │   ├── UserDetail.js
│   │   │   └── CustomerProfile.js
│   │   │
│   │   ├── technicians/
│   │   │   ├── TechnicianList.js
│   │   │   ├── TechnicianForm.js
│   │   │   ├── TechnicianDetail.js
│   │   │   ├── AssignmentMap.js
│   │   │   └── Schedule.js
│   │   │
│   │   ├── products/
│   │   │   ├── ProductList.js
│   │   │   ├── ProductForm.js
│   │   │   ├── ProductDetail.js
│   │   │   ├── CategoryList.js
│   │   │   └── BrandList.js
│   │   │
│   │   ├── interventions/
│   │   │   ├── InterventionList.js
│   │   │   ├── InterventionForm.js
│   │   │   ├── InterventionDetail.js
│   │   │   ├── AssignmentForm.js
│   │   │   └── ReportForm.js
│   │   │
│   │   ├── contracts/
│   │   │   ├── ContractList.js
│   │   │   ├── ContractForm.js
│   │   │   ├── ContractDetail.js
│   │   │   └── OfferList.js
│   │   │
│   │   ├── orders/
│   │   │   ├── OrderList.js
│   │   │   ├── OrderForm.js
│   │   │   ├── OrderDetail.js
│   │   │   ├── QuoteList.js
│   │   │   └── QuoteForm.js
│   │   │
│   │   ├── complaints/
│   │   │   ├── ComplaintList.js
│   │   │   ├── ComplaintForm.js
│   │   │   └── ComplaintDetail.js
│   │   │
│   │   ├── promotions/
│   │   │   ├── PromotionList.js
│   │   │   ├── PromotionForm.js
│   │   │   └── CodeGenerator.js
│   │   │
│   │   ├── notifications/
│   │   │   ├── NotificationList.js
│   │   │   ├── NotificationForm.js
│   │   │   └── PushNotification.js
│   │   │
│   │   └── settings/
│   │       ├── Settings.js
│   │       ├── SystemSettings.js
│   │       ├── UserSettings.js
│   │       └── BackupSettings.js
│   │
│   ├── services/
│   │   ├── api.js              # Configuration Axios
│   │   ├── authService.js      # Service authentification
│   │   ├── userService.js      # Service utilisateurs
│   │   ├── technicianService.js # Service techniciens
│   │   ├── productService.js   # Service produits
│   │   ├── interventionService.js # Service interventions
│   │   ├── contractService.js  # Service contrats
│   │   ├── orderService.js     # Service commandes
│   │   ├── complaintService.js # Service réclamations
│   │   ├── promotionService.js # Service promotions
│   │   ├── notificationService.js # Service notifications
│   │   └── uploadService.js    # Service upload fichiers
│   │
│   ├── utils/
│   │   ├── constants.js        # Constantes
│   │   ├── helpers.js          # Fonctions utilitaires
│   │   ├── validators.js       # Validateurs
│   │   ├── formatters.js       # Formateurs
│   │   └── charts.js           # Configuration charts
│   │
│   ├── hooks/
│   │   ├── useAuth.js          # Hook authentification
│   │   ├── useApi.js           # Hook appels API
│   │   ├── useForm.js          # Hook gestion formulaires
│   │   ├── useDebounce.js      # Hook debounce
│   │   └── useLocalStorage.js  # Hook localStorage
│   │
│   ├── context/
│   │   ├── AuthContext.js      # Contexte authentification
│   │   ├── AppContext.js       # Contexte application
│   │   └── ThemeContext.js     # Contexte thème
│   │
│   ├── routes/
│   │   ├── PrivateRoute.js     # Route protégée
│   │   ├── AdminRoute.js       # Route admin
│   │   └── index.js            # Configuration routes
│   │
│   ├── pages/
│   │   ├── LoginPage.js
│   │   ├── DashboardPage.js
│   │   ├── UsersPage.js
│   │   ├── TechniciansPage.js
│   │   ├── ProductsPage.js
│   │   ├── InterventionsPage.js
│   │   ├── ContractsPage.js
│   │   ├── OrdersPage.js
│   │   ├── ComplaintsPage.js
│   │   ├── PromotionsPage.js
│   │   ├── NotificationsPage.js
│   │   └── SettingsPage.js
│   │
│   ├── App.js                  # Composant principal
│   ├── index.js                # Point d'entrée
│   └── serviceWorker.js        # Service Worker
│
├── .env.example                # Variables d'environnement
├── package.json
├── Dockerfile
└── nginx.conf                  # Configuration Nginx pour déploiement