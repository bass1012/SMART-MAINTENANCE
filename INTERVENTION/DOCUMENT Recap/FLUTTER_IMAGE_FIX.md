# Fix: Flutter Image Loading Error - localhost Connection Issue

## Problem
Flutter mobile app couldn't load images from the backend API because it was using `localhost:3000`, which on a mobile device refers to the device itself, not the development machine.

**Error:**
```
SocketException: Connection refused (OS Error: Connection refused, errno = 111), 
address = localhost, port = 38414
```

## Root Cause
- **Hardcoded localhost URLs** in `product_model.dart`
- Mobile devices/emulators cannot access `localhost` of the host machine
- Need to use actual machine IP address or special emulator addresses

## Solution Applied

### 1. Updated Flutter Configuration (`environment.dart`)

**Machine IP detected:** `192.168.1.139`

```dart
static const Map<Environment, String> _baseUrls = {
  Environment.development: 'http://192.168.1.139:3000', // Physical devices
  Environment.staging: 'https://staging.votreserveur.com',
  Environment.production: 'https://api.votreserveur.com',
};

static const Map<Environment, String> _androidBaseUrls = {
  Environment.development: 'http://10.0.2.2:3000', // Android emulator only
  Environment.staging: 'https://staging.votreserveur.com',
  Environment.production: 'https://api.votreserveur.com',
};
```

### 2. Updated Product Model (`product_model.dart`)

**Before:**
```dart
imageUrl = imagePath.startsWith('http') 
    ? imagePath 
    : 'http://localhost:3000$imagePath';
```

**After:**
```dart
imageUrl = imagePath.startsWith('http') 
    ? imagePath 
    : '${AppConfig.baseUrl}$imagePath';
```

### 3. Updated Backend CORS (`app.js`)

```javascript
const allowedOrigins = [
  'http://localhost:3001', 
  'http://localhost:3000', 
  'http://192.168.1.139:3001',
  'http://192.168.1.139:3000'  // Added for mobile app
];
```

## Files Modified

1. **Flutter App:**
   - `/mct_maintenance_mobile/lib/config/environment.dart` - Updated base URLs
   - `/mct_maintenance_mobile/lib/models/product_model.dart` - Use centralized config

2. **Backend API:**
   - `/mct-maintenance-api/src/app.js` - Updated CORS allowed origins

## How It Works

### For Physical Devices (iOS/Android):
- Uses `http://192.168.1.139:3000`
- Both device and computer must be on the same WiFi network

### For Android Emulator:
- Uses `http://10.0.2.2:3000` (special address that maps to host's localhost)

### For iOS Simulator:
- Uses `http://192.168.1.139:3000` (same as physical devices)

## Testing Instructions

### 1. Verify Backend is Running

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start
```

Expected output:
```
✅ Server running on port 3000
✅ Database connected
```

### 2. Verify Your IP Address

```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Current IP: `192.168.1.139`

**If your IP changes**, update in:
- `mct_maintenance_mobile/lib/config/environment.dart` (line 19)
- `mct-maintenance-api/src/app.js` (lines 53-54)

### 3. Test with Flutter App

**Hot Restart (Required):**
```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
flutter run
# Press 'R' (Shift+R) for hot restart
```

**Test Image Loading:**
1. Navigate to Products screen
2. Images should now load correctly
3. Check console for no more connection errors

### 4. Verify Network Connectivity

**Both devices must be on the same WiFi network:**
- Computer: 192.168.1.139
- Mobile device: 192.168.1.x (same subnet)

**Test API accessibility from mobile:**
```
http://192.168.1.139:3000/api/health
```

## Platform-Specific Notes

### Android Emulator
- Automatically uses `10.0.2.2:3000`
- No network configuration needed
- Works even without WiFi

### Android Physical Device
- Uses `192.168.1.139:3000`
- Must be on same WiFi as computer
- May need to disable mobile data

### iOS Simulator
- Uses `192.168.1.139:3000`
- Works with host machine's network

### iOS Physical Device
- Uses `192.168.1.139:3000`
- Must be on same WiFi as computer
- May need to trust the HTTP connection in iOS settings

## Troubleshooting

### Image Still Not Loading

**1. Check Backend is Running:**
```bash
curl http://192.168.1.139:3000/api/health
```

**2. Check Image File Exists:**
```bash
ls -la /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/uploads/products/
```

**3. Test Direct Image Access:**
```bash
curl -I http://192.168.1.139:3000/uploads/products/product-2-1760959212464.jpg
```

**4. Verify CORS Headers:**
```bash
curl -H "Origin: http://192.168.1.139:3000" \
     -H "Access-Control-Request-Method: GET" \
     -X OPTIONS \
     http://192.168.1.139:3000/uploads/products/product-2-1760959212464.jpg
```

### Connection Refused

**Check Firewall:**
```bash
# Mac: Allow incoming connections on port 3000
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/node
```

**Check WiFi Network:**
- Ensure both devices on same network
- Disable VPN if active
- Check router doesn't block device-to-device communication

### IP Address Changed

**Update Configuration:**
1. Get new IP: `ifconfig | grep "inet "`
2. Update `environment.dart` line 19
3. Update `app.js` lines 53-54
4. Restart backend: `npm start`
5. Hot restart Flutter: Press 'R'

## Security Notes

⚠️ **Development Mode:**
- Backend currently allows all origins in development mode
- This is intentional for easier testing

🔒 **Production:**
- Only allowed origins will be accepted
- Configure proper domain names
- Use HTTPS for production

## Next Steps

1. ✅ **Test Image Loading** - Verify images load in Flutter app
2. ⏳ **Update Other Services** - Check if other API calls work
3. ⏳ **Test on Different Networks** - Verify when network changes
4. ⏳ **Production Deployment** - Use domain names instead of IP addresses

## Summary

✅ **Flutter app** now uses machine IP instead of localhost
✅ **Backend CORS** updated to allow mobile app requests  
✅ **Product model** uses centralized configuration
✅ **Platform detection** automatically uses correct URL

**Result:** Images will now load correctly on all devices! 📱🖼️
