#!/usr/bin/env node
'use strict';

require('dotenv').config();

const { sequelize } = require('../src/config/database');
const { User } = require('../src/models');

const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'supportuser@mct.ci';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'Keep0ut@2023!';

(async () => {
  try {
    console.log('Connecting to database...');
    await sequelize.authenticate();
    // Ensure base tables exist if using sync in dev
    await sequelize.sync({ alter: false });

    console.log('Upserting admin user...');
    let user = await User.findOne({ where: { email: ADMIN_EMAIL } });
    if (!user) {
      user = await User.create({
        email: ADMIN_EMAIL,
        password_hash: ADMIN_PASSWORD, // Will be hashed by model hook
        role: 'admin',
        status: 'active',
        email_verified: true,
        phone_verified: false
      });
      console.log('✅ Admin created:', { id: user.id, email: user.email, role: user.role });
    } else {
      // Update role and password
      user.role = 'admin';
      user.status = 'active';
      user.email_verified = true;
      user.password_hash = ADMIN_PASSWORD; // Will be re-hashed by beforeUpdate hook
      await user.save();
      console.log('✅ Admin updated:', { id: user.id, email: user.email, role: user.role });
    }

    console.log('\nYou can now login with:');
    console.log(`Email: ${ADMIN_EMAIL}`);
    console.log(`Password: ${ADMIN_PASSWORD}`);
    process.exit(0);
  } catch (err) {
    console.error('❌ Failed to create admin:', err);
    process.exit(1);
  }
})();
