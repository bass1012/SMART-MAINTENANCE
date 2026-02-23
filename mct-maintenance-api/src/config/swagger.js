const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'MCT Maintenance API',
      version: '2.0.8',
      description: 'API complète pour la gestion de maintenance - Interventions, Commandes, Devis, Réclamations, Contrats',
      contact: {
        name: 'MCT Maintenance Team',
        email: 'mctsacarrier@gmail.com'
      },
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT'
      }
    },
    servers: [
      {
        url: 'http://localhost:3000/api',
        description: 'Serveur de développement'
      },
      {
        url: 'http://192.168.1.139:3000/api',
        description: 'Serveur réseau local'
      },
      {
        url: 'https://api.mct-maintenance.com/api',
        description: 'Serveur de production'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Entrez votre token JWT au format : Bearer {token}'
        }
      },
      schemas: {
        Error: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: false
            },
            message: {
              type: 'string',
              example: 'Message d\'erreur'
            },
            error: {
              type: 'string',
              example: 'Détails de l\'erreur'
            }
          }
        },
        Success: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: true
            },
            message: {
              type: 'string',
              example: 'Opération réussie'
            },
            data: {
              type: 'object'
            }
          }
        },
        User: {
          type: 'object',
          properties: {
            id: {
              type: 'integer',
              example: 1
            },
            email: {
              type: 'string',
              format: 'email',
              example: 'client@example.com'
            },
            first_name: {
              type: 'string',
              example: 'John'
            },
            last_name: {
              type: 'string',
              example: 'Doe'
            },
            role: {
              type: 'string',
              enum: ['admin', 'customer', 'technician'],
              example: 'customer'
            },
            status: {
              type: 'string',
              enum: ['active', 'inactive', 'suspended'],
              example: 'active'
            },
            phone: {
              type: 'string',
              example: '+221771234567'
            },
            avatar_url: {
              type: 'string',
              format: 'uri',
              example: '/uploads/avatars/user_1.jpg'
            },
            created_at: {
              type: 'string',
              format: 'date-time'
            },
            updated_at: {
              type: 'string',
              format: 'date-time'
            }
          }
        },
        CustomerProfile: {
          type: 'object',
          properties: {
            id: {
              type: 'integer',
              example: 1
            },
            user_id: {
              type: 'integer',
              example: 5
            },
            address: {
              type: 'string',
              example: '123 Rue de la Paix, Dakar'
            },
            city: {
              type: 'string',
              example: 'Dakar'
            },
            latitude: {
              type: 'number',
              format: 'double',
              example: 14.6937
            },
            longitude: {
              type: 'number',
              format: 'double',
              example: -17.4441
            },
            created_at: {
              type: 'string',
              format: 'date-time'
            },
            updated_at: {
              type: 'string',
              format: 'date-time'
            }
          }
        },
        Intervention: {
          type: 'object',
          properties: {
            id: {
              type: 'integer',
              example: 1
            },
            customer_id: {
              type: 'integer',
              example: 5
            },
            technician_id: {
              type: 'integer',
              example: 3,
              nullable: true
            },
            description: {
              type: 'string',
              example: 'Réparation climatiseur'
            },
            status: {
              type: 'string',
              enum: ['pending', 'assigned', 'in_progress', 'completed', 'cancelled'],
              example: 'assigned'
            },
            priority: {
              type: 'string',
              enum: ['low', 'normal', 'high', 'urgent'],
              example: 'normal'
            },
            scheduled_date: {
              type: 'string',
              format: 'date-time'
            },
            completed_date: {
              type: 'string',
              format: 'date-time',
              nullable: true
            },
            created_at: {
              type: 'string',
              format: 'date-time'
            },
            updated_at: {
              type: 'string',
              format: 'date-time'
            }
          }
        },
        Order: {
          type: 'object',
          properties: {
            id: {
              type: 'integer',
              example: 1
            },
            customer_id: {
              type: 'integer',
              example: 5
            },
            status: {
              type: 'string',
              enum: ['pending', 'confirmed', 'preparing', 'shipped', 'delivered', 'cancelled'],
              example: 'confirmed'
            },
            total_amount: {
              type: 'number',
              format: 'decimal',
              example: 150000
            },
            payment_method: {
              type: 'string',
              enum: ['cash', 'card', 'mobile_money', 'bank_transfer'],
              example: 'mobile_money'
            },
            payment_status: {
              type: 'string',
              enum: ['pending', 'paid', 'failed', 'refunded'],
              example: 'paid'
            },
            tracking_url: {
              type: 'string',
              format: 'uri',
              nullable: true
            },
            created_at: {
              type: 'string',
              format: 'date-time'
            },
            updated_at: {
              type: 'string',
              format: 'date-time'
            }
          }
        },
        DeleteCustomerResponse: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: true
            },
            message: {
              type: 'string',
              example: 'Client supprimé avec succès avec toutes ses données associées'
            },
            deletedItems: {
              type: 'object',
              properties: {
                interventions: {
                  type: 'integer',
                  example: 5
                },
                interventionImages: {
                  type: 'integer',
                  example: 12
                },
                orders: {
                  type: 'integer',
                  example: 3
                },
                orderItems: {
                  type: 'integer',
                  example: 8
                },
                quotes: {
                  type: 'integer',
                  example: 2
                },
                quoteItems: {
                  type: 'integer',
                  example: 6
                },
                complaints: {
                  type: 'integer',
                  example: 1
                },
                contracts: {
                  type: 'integer',
                  example: 1
                },
                notifications: {
                  type: 'integer',
                  example: 45
                },
                customerProfile: {
                  type: 'integer',
                  example: 1
                },
                user: {
                  type: 'integer',
                  example: 1
                },
                total: {
                  type: 'integer',
                  example: 84
                }
              }
            }
          }
        },
        Quote: {
          type: 'object',
          properties: {
            id: {
              type: 'integer',
              example: 1
            },
            customer_id: {
              type: 'integer',
              example: 5
            },
            title: {
              type: 'string',
              example: 'Devis installation climatiseur'
            },
            description: {
              type: 'string',
              example: 'Installation complète d\'un système de climatisation'
            },
            total_amount: {
              type: 'number',
              format: 'decimal',
              example: 250000
            },
            status: {
              type: 'string',
              enum: ['pending', 'accepted', 'rejected', 'expired'],
              example: 'pending'
            },
            valid_until: {
              type: 'string',
              format: 'date',
              example: '2025-12-31'
            },
            created_at: {
              type: 'string',
              format: 'date-time'
            },
            updated_at: {
              type: 'string',
              format: 'date-time'
            }
          }
        },
        Complaint: {
          type: 'object',
          properties: {
            id: {
              type: 'integer',
              example: 1
            },
            customer_id: {
              type: 'integer',
              example: 5
            },
            subject: {
              type: 'string',
              example: 'Problème de livraison'
            },
            description: {
              type: 'string',
              example: 'Commande non reçue après 2 semaines'
            },
            status: {
              type: 'string',
              enum: ['open', 'in_progress', 'resolved', 'closed', 'cancelled'],
              example: 'open'
            },
            priority: {
              type: 'string',
              enum: ['low', 'medium', 'high', 'urgent', 'critical'],
              example: 'high'
            },
            category: {
              type: 'string',
              example: 'Livraison'
            },
            resolution: {
              type: 'string',
              nullable: true
            },
            created_at: {
              type: 'string',
              format: 'date-time'
            },
            updated_at: {
              type: 'string',
              format: 'date-time'
            }
          }
        },
        Contract: {
          type: 'object',
          properties: {
            id: {
              type: 'integer',
              example: 1
            },
            customer_id: {
              type: 'integer',
              example: 5
            },
            type: {
              type: 'string',
              example: 'Contrat de maintenance annuel'
            },
            start_date: {
              type: 'string',
              format: 'date',
              example: '2025-01-01'
            },
            end_date: {
              type: 'string',
              format: 'date',
              example: '2025-12-31'
            },
            amount: {
              type: 'number',
              format: 'decimal',
              example: 500000
            },
            status: {
              type: 'string',
              enum: ['active', 'expired', 'cancelled', 'pending'],
              example: 'active'
            },
            auto_renew: {
              type: 'boolean',
              example: true
            },
            created_at: {
              type: 'string',
              format: 'date-time'
            },
            updated_at: {
              type: 'string',
              format: 'date-time'
            }
          }
        }
      }
    },
    responses: {
      Unauthorized: {
        description: 'Non authentifié - Token manquant ou invalide',
        content: {
          'application/json': {
            schema: {
              type: 'object',
              properties: {
                success: {
                  type: 'boolean',
                  example: false
                },
                message: {
                  type: 'string',
                  example: 'Token non fourni ou invalide'
                }
              }
            }
          }
        }
      },
      Forbidden: {
        description: 'Accès refusé - Permissions insuffisantes',
        content: {
          'application/json': {
            schema: {
              type: 'object',
              properties: {
                success: {
                  type: 'boolean',
                  example: false
                },
                message: {
                  type: 'string',
                  example: 'Accès non autorisé'
                }
              }
            }
          }
        }
      },
      NotFound: {
        description: 'Ressource non trouvée',
        content: {
          'application/json': {
            schema: {
              type: 'object',
              properties: {
                success: {
                  type: 'boolean',
                  example: false
                },
                message: {
                  type: 'string',
                  example: 'Ressource non trouvée'
                }
              }
            }
          }
        }
      },
      BadRequest: {
        description: 'Requête invalide - Erreur de validation',
        content: {
          'application/json': {
            schema: {
              type: 'object',
              properties: {
                success: {
                  type: 'boolean',
                  example: false
                },
                message: {
                  type: 'string',
                  example: 'Données invalides'
                },
                errors: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      field: {
                        type: 'string'
                      },
                      message: {
                        type: 'string'
                      }
                    }
                  }
                }
              }
            }
          }
        }
      },
      InternalServerError: {
        description: 'Erreur serveur interne',
        content: {
          'application/json': {
            schema: {
              type: 'object',
              properties: {
                success: {
                  type: 'boolean',
                  example: false
                },
                message: {
                  type: 'string',
                  example: 'Erreur serveur interne'
                },
                error: {
                  type: 'string'
                }
              }
            }
          }
        }
      }
    },
    security: [
      {
        bearerAuth: []
      }
    ],
    tags: [
      {
        name: 'Authentification',
        description: 'Endpoints d\'authentification et gestion des tokens'
      },
      {
        name: 'Clients',
        description: 'Gestion des clients (CRUD, suppression cascade)'
      },
      {
        name: 'Techniciens',
        description: 'Gestion des techniciens et leurs interventions'
      },
      {
        name: 'Interventions',
        description: 'Gestion des interventions de maintenance'
      },
      {
        name: 'Commandes',
        description: 'Gestion des commandes de produits'
      },
      {
        name: 'Devis',
        description: 'Gestion des devis clients'
      },
      {
        name: 'Réclamations',
        description: 'Gestion des réclamations clients'
      },
      {
        name: 'Contrats',
        description: 'Gestion des contrats de maintenance'
      },
      {
        name: 'Notifications',
        description: 'Système de notifications temps réel'
      },
      {
        name: 'Produits',
        description: 'Catalogue de produits'
      },
      {
        name: 'Analytics',
        description: 'Statistiques et rapports'
      },
      {
        name: 'Administration',
        description: 'Endpoints administrateurs'
      }
    ]
  },
  apis: [
    './src/routes/*.js',
    './src/controllers/**/*.js'
  ]
};

const swaggerSpec = swaggerJsdoc(options);

const setupSwagger = (app) => {
  // Route pour la documentation JSON
  app.get('/api-docs.json', (req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.send(swaggerSpec);
  });

  // Route pour l'interface Swagger UI
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
    customCss: '.swagger-ui .topbar { display: none }',
    customSiteTitle: 'MCT Maintenance API',
    customfavIcon: '/favicon.ico',
    swaggerOptions: {
      persistAuthorization: true,
      displayRequestDuration: true,
      filter: true,
      tryItOutEnabled: true,
      syntaxHighlight: {
        activate: true,
        theme: 'monokai'
      }
    }
  }));

  console.log('📚 Swagger UI disponible sur: http://localhost:3000/api-docs');
  console.log('📄 Swagger JSON disponible sur: http://localhost:3000/api-docs.json');
};

module.exports = { setupSwagger, swaggerSpec };
