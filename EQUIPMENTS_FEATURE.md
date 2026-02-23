# Equipment Management Feature

## Overview
This feature allows customers to track and manage their equipment (climatiseurs, chauffe-eaux, pompes, etc.) with serial numbers and maintenance history.

## Components

### Backend (API)
**Location**: `mct-maintenance-api/src/`

1. **Model**: `models/equipment.model.js`
   - Fields: id, customer_id, name, type, brand, model, serial_number, location, dates, status, notes
   - Serial numbers are unique across the system
   - Status enum: active, inactive, maintenance, retired

2. **Controller**: `controllers/equipment/equipmentController.js`
   - `getMyEquipments()` - Get all equipments for authenticated customer
   - `getEquipment()` - Get single equipment by ID
   - `createEquipment()` - Create new equipment
   - `updateEquipment()` - Update existing equipment
   - `deleteEquipment()` - Soft delete equipment

3. **Routes**: `routes/equipmentRoutes.js`
   - `GET /api/equipments/my-equipments` - List user's equipments
   - `GET /api/equipments/:id` - Get specific equipment
   - `POST /api/equipments` - Create equipment
   - `PUT /api/equipments/:id` - Update equipment
   - `DELETE /api/equipments/:id` - Delete equipment

4. **Migration**: `migrations/20251015_create_equipments.js`
   - Creates the equipments table with all necessary fields
   - Foreign key to users table (customer_id)

### Mobile App (Flutter)
**Location**: `mct_maintenance_mobile/lib/screens/customer/`

1. **Screen**: `equipments_screen.dart`
   - Full CRUD interface for equipment management
   - Features:
     - List view with equipment cards
     - Add equipment dialog with form
     - Edit equipment functionality
     - Delete confirmation dialog
     - Detail view in bottom sheet
     - Empty state with helpful message
     - Pull-to-refresh

2. **Navigation**: `customer_main_screen.dart`
   - Added "Mes équipements" card in services section
   - Icon: devices_other
   - Routes to EquipmentsScreen

## API Endpoints

### Authentication Required
All endpoints require Bearer token authentication:
```
Authorization: Bearer {token}
```

### Get My Equipments
```http
GET /api/equipments/my-equipments
```

**Response**:
```json
{
  "success": true,
  "equipments": [
    {
      "id": 1,
      "name": "Climatiseur Samsung",
      "type": "climatiseur",
      "brand": "Samsung",
      "model": "AR12TXHQASINEU",
      "serial_number": "SN123456789",
      "location": "Salon",
      "status": "active",
      "installation_date": "2024-01-15",
      "notes": "Entretien annuel requis"
    }
  ]
}
```

### Create Equipment
```http
POST /api/equipments
Content-Type: application/json

{
  "name": "Climatiseur Samsung",
  "type": "climatiseur",
  "brand": "Samsung",
  "model": "AR12TXHQASINEU",
  "serial_number": "SN123456789",
  "location": "Salon",
  "installation_date": "2024-01-15",
  "status": "active",
  "notes": "Équipement neuf"
}
```

### Update Equipment
```http
PUT /api/equipments/:id
Content-Type: application/json

{
  "location": "Chambre 1",
  "status": "maintenance",
  "notes": "Maintenance prévue le 15/02"
}
```

### Delete Equipment
```http
DELETE /api/equipments/:id
```

## Database Schema

```sql
CREATE TABLE equipments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER NOT NULL,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(100) NOT NULL,
  brand VARCHAR(100),
  model VARCHAR(100),
  serial_number VARCHAR(100) UNIQUE,
  installation_date DATE,
  purchase_date DATE,
  warranty_expiry DATE,
  location VARCHAR(255),
  status ENUM('active', 'inactive', 'maintenance', 'retired') DEFAULT 'active',
  last_maintenance_date DATETIME,
  next_maintenance_date DATETIME,
  notes TEXT,
  createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deletedAt DATETIME,
  FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE RESTRICT
);
```

## Testing

### Backend API Testing
A comprehensive test script is available: `test-equipments.js`

**Run tests**:
```bash
node test-equipments.js
```

**Tests include**:
1. Customer login
2. Get equipments list
3. Create new equipment
4. Get single equipment
5. Update equipment
6. Delete equipment
7. Verify deletion

**Before running**:
Update the test credentials in the script:
```javascript
const TEST_CREDENTIALS = {
  email: 'client@test.com',  // Your test customer email
  password: 'password123'
};
```

### Mobile App Testing
1. Start the backend server
2. Run the Flutter app
3. Login as a customer
4. Navigate to "Mes équipements" from the dashboard
5. Test CRUD operations:
   - Add equipment using the + button
   - Edit equipment by tapping the edit icon
   - View details by tapping the equipment card
   - Delete equipment using the delete icon

## Setup Instructions

### Backend
1. Ensure database is synced:
   ```bash
   cd mct-maintenance-api
   node -e "const db = require('./src/models'); db.sequelize.sync().then(() => process.exit(0));"
   ```

2. The equipments table will be created automatically by Sequelize

### Mobile
No additional setup required. The equipment screen is already integrated.

## Features

✅ Complete CRUD operations
✅ Serial number uniqueness validation
✅ Customer ownership validation
✅ Soft delete with paranoid mode
✅ Beautiful Material Design UI
✅ Pull-to-refresh
✅ Empty state handling
✅ Error handling with user-friendly messages
✅ Form validation
✅ Equipment status tracking
✅ Maintenance date tracking

## Future Enhancements

- [ ] Equipment photos
- [ ] Maintenance history timeline
- [ ] Link equipment to interventions
- [ ] QR code scanning for serial numbers
- [ ] Warranty expiration notifications
- [ ] Maintenance reminders
- [ ] Equipment performance analytics

## Notes

- Serial numbers are optional but must be unique if provided
- Equipment is soft-deleted (deletedAt timestamp) for history tracking
- Only equipment owners can view/edit their own equipment
- All dates are stored in ISO format (YYYY-MM-DD)
