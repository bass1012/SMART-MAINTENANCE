mct-maintenance-mobile/
├── android/                    # Configuration Android
├── ios/                        # Configuration iOS
├── lib/
│   ├── config/
│   │   ├── routes.dart         # Configuration routes
│   │   ├── themes.dart         # Configuration thèmes
│   │   ├── constants.dart      # Constantes
│   │   └── environment.dart    # Variables d'environnement
│   │
│   ├── core/
│   │   ├── app.dart            # Widget principal
│   │   ├── di.dart             # Configuration injection dépendances
│   │   └── observer.dart       # Navigation observer
│   │
│   ├── models/
│   │   ├── user.dart
│   │   ├── customer.dart
│   │   ├── technician.dart
│   │   ├── product.dart
│   │   ├── category.dart
│   │   ├── brand.dart
│   │   ├── contract.dart
│   │   ├── intervention.dart
│   │   ├── assignment.dart
│   │   ├── report.dart
│   │   ├── order.dart
│   │   ├── quote.dart
│   │   ├── promotion.dart
│   │   ├── complaint.dart
│   │   └── notification.dart
│   │
│   ├── services/
│   │   ├── api_service.dart    # Service API
│   │   ├── auth_service.dart   # Service authentification
│   │   ├── storage_service.dart # Service stockage local
│   │   ├── location_service.dart # Service localisation
│   │   ├── notification_service.dart # Service notifications
│   │   ├── payment_service.dart # Service paiements
│   │   └── camera_service.dart # Service caméra
│   │
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── user_repository.dart
│   │   ├── product_repository.dart
│   │   ├── intervention_repository.dart
│   │   ├── contract_repository.dart
│   │   ├── order_repository.dart
│   │   └── notification_repository.dart
│   │
│   ├── widgets/
│   │   ├── common/
│   │   │   ├── custom_button.dart
│   │   │   ├── custom_input.dart
│   │   │   ├── custom_card.dart
│   │   │   ├── loading_widget.dart
│   │   │   ├── error_widget.dart
│   │   │   └── empty_state.dart
│   │   │
│   │   ├── auth/
│   │   │   ├── login_form.dart
│   │   │   ├── register_form.dart
│   │   │   └── forgot_password_form.dart
│   │   │
│   │   ├── customer/
│   │   │   ├── profile_card.dart
│   │   │   ├── contract_card.dart
│   │   │   ├── intervention_card.dart
│   │   │   ├── product_card.dart
│   │   │   └── order_card.dart
│   │   │
│   │   ├── technician/
│   │   │   ├── assignment_card.dart
│   │   │   ├── status_badge.dart
│   │   │   ├── location_map.dart
│   │   │   └── report_form.dart
│   │   │
│   │   └── shared/
│   │       ├── app_bar.dart
│   │       ├── bottom_nav.dart
│   │       ├── drawer.dart
│   │       └── search_bar.dart
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   └── otp_verification_screen.dart
│   │   │
│   │   ├── customer/
│   │   │   ├── customer_main_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   ├── contracts_screen.dart
│   │   │   ├── contract_detail_screen.dart
│   │   │   ├── interventions_screen.dart
│   │   │   ├── intervention_request_screen.dart
│   │   │   ├── intervention_tracking_screen.dart
│   │   │   ├── reports_screen.dart
│   │   │   ├── report_detail_screen.dart
│   │   │   ├── complaints_screen.dart
│   │   │   ├── complaint_form_screen.dart
│   │   │   ├── products_screen.dart
│   │   │   ├── product_detail_screen.dart
│   │   │   ├── cart_screen.dart
│   │   │   ├── checkout_screen.dart
│   │   │   ├── orders_screen.dart
│   │   │   └── order_detail_screen.dart
│   │   │
│   │   ├── technician/
│   │   │   ├── technician_main_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   ├── assignments_screen.dart
│   │   │   ├── assignment_detail_screen.dart
│   │   │   ├── map_screen.dart
│   │   │   ├── report_form_screen.dart
│   │   │   ├── contracts_screen.dart
│   │   │   └── schedule_screen.dart
│   │   │
│   │   ├── common/
│   │   │   ├── splash_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── notifications_screen.dart
│   │   │   ├── settings_screen.dart
│   │   │   └── about_screen.dart
│   │   │
│   │   └── admin/
│   │       ├── admin_main_screen.dart
│   │       ├── dashboard_screen.dart
│   │       ├── users_screen.dart
│   │       ├── technicians_screen.dart
│   │       ├── products_screen.dart
│   │       ├── interventions_screen.dart
│   │       └── settings_screen.dart
│   │
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   ├── helpers.dart
│   │   ├── extensions.dart
│   │   └── logger.dart
│   │
│   └── features/
│       ├── auth/
│       │   ├── bloc/
│       │   │   ├── auth_bloc.dart
│       │   │   ├── auth_event.dart
│       │   │   └── auth_state.dart
│       │   └── cubit/
│       │       ├── login_cubit.dart
│       │       └── register_cubit.dart
│       │
│       ├── customer/
│       │   ├── bloc/
│       │   │   ├── customer_bloc.dart
│       │   │   ├── customer_event.dart
│       │   │   └── customer_state.dart
│       │   └── cubit/
│       │       ├── profile_cubit.dart
│       │       ├── contract_cubit.dart
│       │       └── intervention_cubit.dart
│       │
│       ├── technician/
│       │   ├── bloc/
│       │   │   ├── technician_bloc.dart
│       │   │   ├── technician_event.dart
│       │   │   └── technician_state.dart
│       │   └── cubit/
│       │       ├── assignment_cubit.dart
│       │       └── location_cubit.dart
│       │
│       └── shared/
│           ├── bloc/
│           │   ├── theme_bloc.dart
│           │   ├── theme_event.dart
│           │   └── theme_state.dart
│           └── cubit/
│               ├── notification_cubit.dart
│               └── connectivity_cubit.dart
│
├── assets/
│   ├── images/
│   ├── icons/
│   ├── fonts/
│   └── translations/
│       ├── en.json
│       └── fr.json
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── pubspec.yaml
├── README.md
└── analysis_options.yaml