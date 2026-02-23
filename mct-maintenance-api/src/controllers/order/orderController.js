const { Order, User, Product, OrderItem, CustomerProfile, Payment } = require('../../models');
const Promotion = require('../../models/Promotion');
const Subscription = require('../../models/Subscription');
const MaintenanceOffer = require('../../models/MaintenanceOffer');
const { Op } = require('sequelize');
const { validationResult } = require('express-validator');
const { notifyNewOrder, notifyOrderStatusUpdate } = require('../../services/notificationHelpers');
const { sendEmail } = require('../../services/emailService');
const {
  sendOrderCreatedEmail,
  sendOrderConfirmedEmail,
  sendOrderShippedEmail,
  sendOrderDeliveredEmail
} = require('../../services/emailHelper');

// Récupérer toutes les commandes (Admin/Manager)
const getAllOrders = async (req, res, next) => {
  try {
  const { status, startDate, endDate, limit = 10, page = 1, mine } = req.query;
    const offset = (page - 1) * limit;
    
    const where = {};
    // Si l'utilisateur n'est pas admin/manager, il ne voit que ses propres commandes
    const role = req.user ? req.user.role : null;
    const userId = req.user ? req.user.id : null;
    if (userId && (mine === 'true' || (role !== 'admin' && role !== 'manager'))) {
      // Trouver le CustomerProfile de l'utilisateur
      const customerProfile = await CustomerProfile.findOne({ where: { user_id: userId } });
      if (customerProfile) {
        where.customerId = customerProfile.id; // Utiliser l'ID du CustomerProfile, pas du User
      }
    }
    if (status) where.status = status;
    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) where.createdAt[Op.gte] = new Date(startDate);
      if (endDate) where.createdAt[Op.lte] = new Date(endDate);
    }

    // Filtrer les commandes archivées (soft deleted)
    const { count, rows: orders } = await Order.findAndCountAll({
      where: { ...where, deletedAt: null },
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          attributes: ['id', 'user_id', 'first_name', 'last_name', 'commune', 'city'],
          include: [{
            model: User,
            as: 'user',
            attributes: ['id', 'email', 'phone']
          }]
        },
        {
          model: OrderItem,
          as: 'items',
          include: [{ model: Product, as: 'product' }]
        }
      ],
      order: [['createdAt', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    // Adapter les données pour le frontend : ajouter reference, customerName, customerEmail
    const mappedOrders = orders.map(order => {
      // Générer une référence simple si absente (ex: ORD-0001)
      let reference = order.reference;
      if (!reference) {
        reference = `ORD-${String(order.id).padStart(4, '0')}`;
      }
      let customerName = '';
      let customerEmail = '';
      let customerPhone = '';
      if (order.customer) {
        customerName = [order.customer.first_name, order.customer.last_name].filter(Boolean).join(' ');
        if (order.customer.user) {
          customerEmail = order.customer.user.email || '';
          customerPhone = order.customer.user.phone || '';
        }
      }
      return {
        ...order.toJSON(),
        reference,
        customerName,
        customerEmail,
        customerPhone
      };
    });
    res.status(200).json({
      success: true,
      count,
      totalPages: Math.ceil(count / limit),
      currentPage: parseInt(page),
      data: mappedOrders
    });
  } catch (error) {
    console.error('Error fetching orders:', error);
    next(error);
  }
};

// Récupérer une commande par ID (Admin/Manager)
const getOrderById = async (req, res, next) => {
  try {
    console.log('Recherche de la commande ID:', req.params.id);
    
    const order = await Order.findByPk(req.params.id, {
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          attributes: ['id', 'user_id', 'first_name', 'last_name', 'commune', 'city'],
          include: [{
            model: User,
            as: 'user',
            attributes: ['id', 'email', 'phone']
          }]
        },
        {
          model: OrderItem,
          as: 'items',
          include: [{ model: Product, as: 'product' }]
        }
      ]
    });

    console.log('Commande trouvée:', order ? order.id : 'null');

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée'
      });
    }

    res.status(200).json({
      success: true,
      data: order
    });
  } catch (error) {
    console.error('Error fetching order:', error);
    next(error);
  }
};

// Créer une commande (Client)
const createOrder = async (req, res, next) => {
  const transaction = await Order.sequelize.transaction();
  let committed = false;
  
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    const { items, shippingAddress, shipping_address, paymentMethod, payment_method, notes, customer_id, promo_code, promo_discount, promo_id } = req.body;
    
    console.log('📦 Création commande - Items reçus:', JSON.stringify(items, null, 2));
    
    // Déterminer le customer_id à utiliser
    let customerId;
    
    if (customer_id && req.user.role === 'admin') {
      // Admin peut créer une commande pour un autre client
      // customer_id fourni est déjà l'ID du customer_profile
      customerId = customer_id;
    } else {
      // Pour un client, trouver son customer_profile
      const customerProfile = await CustomerProfile.findOne({
        where: { user_id: req.user.id },
        transaction
      });
      
      if (!customerProfile) {
        await transaction.rollback();
        return res.status(404).json({
          success: false,
          message: 'Profil client non trouvé'
        });
      }
      
      customerId = customerProfile.id;
      console.log(`👤 Client user_id=${req.user.id} → customer_profile_id=${customerId}`);
    }
    
    // Calculer le total
    let totalAmount = 0;
    const orderItems = [];
    
    // Vérifier les produits et calculer le total
    for (const item of items) {
      const productId = item.productId || item.product_id || item.id;
      console.log('🔍 Item reçu:', item, '→ productId extrait:', productId);
      
      if (!productId) {
        await transaction.rollback();
        return res.status(400).json({
          success: false,
          message: 'ID de produit manquant dans un des items'
        });
      }
      
      const product = await Product.findByPk(productId, { transaction });
      console.log('🔍 Produit trouvé:', product ? `${product.id} - ${product.nom}` : 'NULL');
      
      if (!product) {
        await transaction.rollback();
        console.log('❌ Produit non trouvé avec ID:', productId);
        return res.status(404).json({
          success: false,
          message: `Produit non trouvé avec l'ID: ${productId}`
        });
      }
      
      if (product.quantite_stock < item.quantity) {
        await transaction.rollback();
        return res.status(400).json({
          success: false,
          message: `Stock insuffisant pour le produit: ${product.nom}`
        });
      }
      
      console.log('Product from DB:', product.toJSON());
      // Utiliser le prix du produit de manière cohérente (prix ou price)
      const productPrice = product.prix || product.price;
      const itemTotal = productPrice * item.quantity;
      totalAmount += itemTotal;
      
      orderItems.push({
        product_id: product.id,
        quantity: item.quantity,
        unit_price: productPrice,
        total: itemTotal
      });
      
      // Mettre à jour le stock
      await product.decrement('quantite_stock', { by: item.quantity, transaction });
    }
    
    // Appliquer la réduction promo si présente
    const finalAmount = promo_discount ? totalAmount - promo_discount : totalAmount;
    
    // Créer la commande
    const order = await Order.create({
      customerId,
      totalAmount: finalAmount,
      status: 'pending',
      shippingAddress: shippingAddress || shipping_address,
      paymentMethod: paymentMethod || payment_method,
      notes,
      reference: `CMD-${Date.now()}`,
      promoCode: promo_code || null,
      promoDiscount: promo_discount || 0,
      promoId: promo_id || null
    }, { transaction });
    
    // Ajouter les articles de la commande avec l'ID de la commande
    console.log('Order created:', order.toJSON());
    
    // Mettre à jour chaque item avec l'ID de la commande
    const itemsWithOrderId = orderItems.map(item => ({
      ...item,
      order_id: order.id
    }));
    
    // Créer les items de commande
    await Promise.all(itemsWithOrderId.map(async item => {
      console.log('Creating order item:', item);
      const orderItem = await OrderItem.create(item, { transaction });
      console.log('Order item created:', orderItem.toJSON());
      return orderItem;
    }));
    
    // Créer un enregistrement Payment pour la commande
    const { Payment } = require('../../models');
    const paymentProvider = paymentMethod === 'cash' ? 'cash' : 
                           paymentMethod === 'Carte bancaire' ? 'stripe' :
                           paymentMethod === 'Orange Money' ? 'orange_money' :
                           paymentMethod === 'MTN Money' ? 'mtn_money' :
                           paymentMethod === 'Moov Money' ? 'moov_money' :
                           paymentMethod === 'Wave' ? 'wave' : 'cash';
    
    await Payment.create({
      orderId: order.id,
      amount: finalAmount,
      currency: 'XOF',
      provider: paymentProvider,
      status: 'pending',
      paymentMethod: paymentMethod || payment_method || 'cash'
    }, { transaction });
    
    console.log('✅ Payment record created for order');
    
  await transaction.commit();
  committed = true;
    
    // Si un code promo a été utilisé, incrémenter son compteur
    if (promo_id) {
      try {
        const promotion = await Promotion.findByPk(promo_id);
        if (promotion) {
          await promotion.increment('usageCount');
          console.log(`✅ Compteur promo ${promo_code} incrémenté (${promotion.usageCount + 1})`);
        }
      } catch (promoError) {
        console.error('❌ Erreur incrémentation promo:', promoError);
        // Ne pas bloquer la commande si erreur promo
      }
    }
    
    // Récupérer la commande complète avec les détails
    const orderWithDetails = await Order.findByPk(order.id, {
      include: [
        { 
          model: CustomerProfile,
          as: 'customer',
          include: [{
            model: User,
            as: 'user'
          }]
        },
        { 
          model: OrderItem,
          as: 'items',
          include: [{ model: Product, as: 'product' }]
        }
      ]
    });

    // 🎁 Activer automatiquement l'offre d'entretien si la commande contient un climatiseur (categorie_id = 1)
    try {
      const hasClimatiseur = orderWithDetails.items.some(item => 
        item.product && item.product.categorie_id === 1
      );
      
      if (hasClimatiseur) {
        // IMPORTANT: Utiliser req.user.id (ID User) et non customerId (ID CustomerProfile)
        // car les endpoints de souscription client utilisent req.user.id
        const userId = req.user.id;
        console.log('🎁 Commande contient un climatiseur - Activation offre d\'entretien automatique');
        console.log(`   👤 User ID: ${userId}, CustomerProfile ID: ${customerId}`);
        
        // Chercher l'offre d'entretien active la plus appropriée (Premium > Gold > la plus chère)
        let maintenanceOffer = await MaintenanceOffer.findOne({
          where: { 
            isActive: true,
            title: { [Op.like]: '%premium%' }
          }
        });
        
        if (!maintenanceOffer) {
          maintenanceOffer = await MaintenanceOffer.findOne({
            where: { 
              isActive: true,
              title: { [Op.like]: '%gold%' }
            }
          });
        }
        
        if (!maintenanceOffer) {
          // Prendre l'offre active la plus chère
          maintenanceOffer = await MaintenanceOffer.findOne({
            where: { isActive: true },
            order: [['price', 'DESC']]
          });
        }
        
        if (maintenanceOffer) {
          // Vérifier si le client n'a pas déjà une souscription active à cette offre
          const existingSubscription = await Subscription.findOne({
            where: {
              customer_id: userId, // Utiliser userId (User.id) et non customerId (CustomerProfile.id)
              maintenance_offer_id: maintenanceOffer.id,
              status: 'active'
            }
          });
          
          if (!existingSubscription) {
            // Calculer les dates de début et fin
            const startDate = new Date();
            const endDate = new Date();
            endDate.setMonth(endDate.getMonth() + maintenanceOffer.duration);
            
            // Créer la souscription automatique (gratuite car incluse avec l'achat)
            const newSubscription = await Subscription.create({
              customer_id: userId, // IMPORTANT: Utiliser userId (User.id) et non customerId (CustomerProfile.id)
              maintenance_offer_id: maintenanceOffer.id,
              status: 'active',
              start_date: startDate,
              end_date: endDate,
              price: 0, // Gratuit car inclus avec l'achat du climatiseur
              payment_status: 'paid' // Considéré comme payé car inclus
            });
            
            console.log(`✅ Souscription créée automatiquement: Offre "${maintenanceOffer.title}" pour le client (User ID: ${userId})`);
            console.log(`   📅 Période: ${startDate.toLocaleDateString()} - ${endDate.toLocaleDateString()}`);
          } else {
            console.log(`ℹ️ Le client (User ID: ${userId}) a déjà une souscription active à l'offre "${maintenanceOffer.title}"`);
          }
        } else {
          console.log('⚠️ Aucune offre d\'entretien active trouvée');
        }
      }
    } catch (subscriptionError) {
      console.error('❌ Erreur création souscription automatique:', subscriptionError);
      // Ne pas bloquer la commande si erreur souscription
    }

    // 🔔 Notifier les admins de la nouvelle commande
    try {
      const customerProfile = orderWithDetails.customer;
      if (customerProfile && customerProfile.user) {
        // Créer un objet customer pour les anciennes fonctions
        const customer = {
          id: customerProfile.user.id,  // User ID pour les notifications
          email: customerProfile.user.email,
          phone: customerProfile.user.phone,
          first_name: customerProfile.first_name,
          firstName: customerProfile.first_name,
          last_name: customerProfile.last_name,
          lastName: customerProfile.last_name
        };
        
        await notifyNewOrder(orderWithDetails, customer);
        console.log('✅ Notification commande envoyée aux admins');
        
        // 📧 Email au client (confirmation de commande - template professionnel)
        await sendOrderCreatedEmail(orderWithDetails.get({ plain: true }), customer);
        console.log('✅ Email professionnel confirmation commande envoyé au client');
      }
    } catch (notifError) {
      console.error('❌ Erreur notification commande:', notifError);
    }
    
    res.status(201).json({
      success: true,
      message: 'Commande créée avec succès',
      data: orderWithDetails
    });
    
  } catch (error) {
    try {
      // Ne rollback que si la transaction n'est pas déjà terminée
      if (!committed && transaction && transaction.finished !== 'commit' && transaction.finished !== 'rollback') {
        await transaction.rollback();
      }
    } catch (rbErr) {
      console.error('Error during transaction rollback:', rbErr);
    }
    console.error('Error creating order:', error);
    next(error);
  }
};

// Mettre à jour une commande (Admin)
const updateOrder = async (req, res, next) => {
  const transaction = await Order.sequelize.transaction();
  let committed = false;
  
  try {
    const { status, notes, shipping_address, payment_method, items, tracking_url } = req.body;
    
    const order = await Order.findByPk(req.params.id, {
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          include: [{
            model: User,
            as: 'user',
            attributes: ['id', 'email', 'first_name', 'last_name', 'phone']
          }]
        },
        {
          model: OrderItem,
          as: 'items',
          include: [{ model: Product, as: 'product' }]
        }
      ],
      transaction
    });
    
    if (!order) {
      await transaction.rollback();
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée'
      });
    }
    
    // ⭐ Sauvegarder l'ancien statut AVANT modification
    const oldStatus = order.status;
    const oldTrackingUrl = order.trackingUrl;
    
    // Mettre à jour les champs fournis
    if (status) order.status = status;
    if (notes !== undefined) order.notes = notes;
    if (shipping_address !== undefined) order.shippingAddress = shipping_address;
    if (payment_method !== undefined) order.paymentMethod = payment_method;
    if (tracking_url !== undefined) order.trackingUrl = tracking_url;
    
    // Si des items sont fournis, gérer les modifications
    if (items && Array.isArray(items)) {
      // Restaurer le stock des anciens items
      for (const oldItem of order.items) {
        const product = await Product.findByPk(oldItem.productId, { transaction });
        if (product) {
          await product.increment('quantite_stock', { by: oldItem.quantity, transaction });
        }
      }
      
      // Supprimer tous les anciens items
      await OrderItem.destroy({
        where: { orderId: order.id },
        transaction
      });
      
      // Créer les nouveaux items et décrémenter le stock
      let newTotalAmount = 0;
      for (const item of items) {
        const product = await Product.findByPk(item.product_id, { transaction });
        if (!product) {
          await transaction.rollback();
          return res.status(404).json({
            success: false,
            message: `Produit non trouvé avec l'ID: ${item.product_id}`
          });
        }
        
        if (product.quantite_stock < item.quantity) {
          await transaction.rollback();
          return res.status(400).json({
            success: false,
            message: `Stock insuffisant pour le produit: ${product.nom}`
          });
        }
        
        const itemTotal = item.unit_price * item.quantity;
        newTotalAmount += itemTotal;
        
        await OrderItem.create({
          order_id: order.id,
          product_id: item.product_id,
          quantity: item.quantity,
          unit_price: item.unit_price,
          total: itemTotal
        }, { transaction });
        
        await product.decrement('quantite_stock', { by: item.quantity, transaction });
      }
      
      // Mettre à jour le montant total
      order.totalAmount = newTotalAmount;
    }
    
    await order.save({ transaction });
    await transaction.commit();
    committed = true;
    
    // Recharger la commande avec les relations
    const updatedOrder = await Order.findByPk(order.id, {
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          include: [{
            model: User,
            as: 'user',
            attributes: ['id', 'email', 'first_name', 'last_name', 'phone']
          }]
        },
        {
          model: OrderItem,
          as: 'items',
          include: [{ model: Product, as: 'product' }]
        }
      ]
    });

    // 🔔 Notifier le client si le statut a changé
    if (status && status !== oldStatus) {
      try {
        const customer = updatedOrder.customer?.user;
        if (customer) {
          await notifyOrderStatusUpdate(updatedOrder, customer, status);
          console.log(`✅ Notification changement statut commande envoyée: ${oldStatus} → ${status}`);
          
          // 📧 Email selon le nouveau statut (templates professionnels)
          if (status === 'processing' || status === 'confirmed') {
            // Commande en préparation
            await sendOrderConfirmedEmail(updatedOrder.get({ plain: true }), customer.get({ plain: true }));
            console.log('✅ Email professionnel préparation envoyé');
          } else if (status === 'shipped') {
            // Commande expédiée
            await sendOrderShippedEmail(updatedOrder.get({ plain: true }), customer.get({ plain: true }));
            console.log('✅ Email professionnel expédition envoyé');
          } else if (status === 'delivered') {
            // Commande livrée
            await sendOrderDeliveredEmail(updatedOrder.get({ plain: true }), customer.get({ plain: true }));
            console.log('✅ Email professionnel livraison envoyé');
          }
        }
      } catch (notifError) {
        console.error('❌ Erreur notification statut:', notifError);
      }
    }

    // 🔔 Notifier le client si un lien de livraison a été ajouté
    if (tracking_url && tracking_url !== oldTrackingUrl) {
      try {
        const customer = updatedOrder.customer?.user;
        if (customer) {
          const notificationService = require('../../services/notificationService');
          await notificationService.create({
            userId: customer.id,
            type: 'order_tracking',
            title: 'Lien de suivi disponible',
            message: `Le lien de suivi de votre commande #${updatedOrder.reference} est maintenant disponible`,
            priority: 'high',
            data: {
              orderId: updatedOrder.id,
              orderReference: updatedOrder.reference,
              trackingUrl: tracking_url
            },
            actionUrl: `/commandes/${updatedOrder.id}`
          });
          console.log(`✅ Notification lien de suivi envoyée pour commande #${updatedOrder.reference}`);
        }
      } catch (notifError) {
        console.error('❌ Erreur notification tracking:', notifError);
      }
    }
    
    res.status(200).json({
      success: true,
      message: 'Commande mise à jour avec succès',
      data: updatedOrder
    });
  } catch (error) {
    try {
      // Ne rollback que si la transaction n'est pas déjà terminée
      if (!committed && transaction && transaction.finished !== 'commit' && transaction.finished !== 'rollback') {
        await transaction.rollback();
      }
    } catch (rbErr) {
      console.error('Error during transaction rollback:', rbErr);
    }
    console.error('Error updating order:', error);
    next(error);
  }
};

// Supprimer une commande (Admin)
const deleteOrder = async (req, res, next) => {
  const transaction = await Order.sequelize.transaction();
  let committed = false;
  
  try {
    const order = await Order.findByPk(req.params.id, {
      include: [{ model: OrderItem, as: 'items' }],
      transaction
    });
    
    if (!order) {
      await transaction.rollback();
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée'
      });
    }
    
    // Si la commande est en cours de traitement (pending ou processing), 
    // on restaure le stock avant de supprimer
    if (order.status === 'pending' || order.status === 'processing') {
      // Restaurer le stock des produits
      for (const item of order.items) {
        const product = await Product.findByPk(item.productId, { transaction });
        if (product) {
          await product.increment('quantite_stock', { by: item.quantity, transaction });
        }
      }
    }
    
    // Supprimer les articles de la commande
    await OrderItem.destroy({
      where: { orderId: order.id },
      transaction
    });
    
    // Supprimer la commande (soft delete si paranoid: true)
    await order.destroy({ transaction });
    
    await transaction.commit();
    committed = true;
    
    res.status(200).json({
      success: true,
      message: 'Commande supprimée avec succès'
    });
    
  } catch (error) {
    try {
      // Ne rollback que si la transaction n'est pas déjà terminée
      if (!committed && transaction && transaction.finished !== 'commit' && transaction.finished !== 'rollback') {
        await transaction.rollback();
      }
    } catch (rbErr) {
      console.error('Error during transaction rollback:', rbErr);
    }
    console.error('Error deleting order:', error);
    next(error);
  }
};

// Récupérer les commandes de l'utilisateur connecté (Client)
const getMyOrders = async (req, res, next) => {
  try {
    const { status, limit = 10, page = 1 } = req.query;
    const offset = (page - 1) * limit;
    
    const where = { customerId: req.user.id };
    if (status) where.status = status;
    
    const { count, rows: orders } = await Order.findAndCountAll({
      where,
      include: [
        {
          model: OrderItem,
          include: [{ model: Product, as: 'product' }]
        }
      ],
      order: [['createdAt', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
    
    res.status(200).json({
      success: true,
      count,
      totalPages: Math.ceil(count / limit),
      currentPage: parseInt(page),
      data: orders
    });
  } catch (error) {
    console.error('Error fetching user orders:', error);
    next(error);
  }
};

// Annuler une commande (Client)
const cancelOrder = async (req, res, next) => {
  const transaction = await Order.sequelize.transaction();
  let committed = false;
  
  try {
    const order = await Order.findOne({
      where: {
        id: req.params.id,
        customerId: req.user.id
      },
      include: [OrderItem],
      transaction
    });
    
    if (!order) {
      await transaction.rollback();
      return res.status(404).json({
        success: false,
        message: 'Commande non trouvée ou accès refusé'
      });
    }
    
    // Vérifier si la commande peut être annulée
    if (!['pending', 'processing'].includes(order.status)) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        message: `Impossible d'annuler une commande avec le statut: ${order.status}`
      });
    }
    
    // Mettre à jour le statut de la commande
    order.status = 'cancelled';
    await order.save({ transaction });
    
    // Restaurer le stock des produits
    await Promise.all(order.OrderItems.map(async (item) => {
      await Product.increment('stock', {
        by: item.quantity,
        where: { id: item.productId },
        transaction
      });
    }));
    
    await transaction.commit();
    committed = true;
    
    res.status(200).json({
      success: true,
      message: 'Commande annulée avec succès',
      data: order
    });
    
  } catch (error) {
    try {
      // Ne rollback que si la transaction n'est pas déjà terminée
      if (!committed && transaction && transaction.finished !== 'commit' && transaction.finished !== 'rollback') {
        await transaction.rollback();
      }
    } catch (rbErr) {
      console.error('Error during transaction rollback:', rbErr);
    }
    console.error('Error cancelling order:', error);
    next(error);
  }
};

const getCustomerOrders = async (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Get customer orders - To be implemented',
    data: []
  });
};

module.exports = {
  getAllOrders,
  getOrderById,
  createOrder,
  updateOrder,
  deleteOrder,
  getCustomerOrders
};
