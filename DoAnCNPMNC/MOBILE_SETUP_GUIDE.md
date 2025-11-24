# 📱 Mobile Development Setup Guide

## 🎯 Quick Setup

### 1. Configure Your Environment

Edit `lib/utils/constants.dart` in both apps:

```dart
class AppConfig {
  // 🔧 Change these settings:
  static const Environment currentEnv = Environment.development;  // or staging, production
  static const String laptopIp = '192.168.1.173';  // ⚠️ YOUR laptop IP
  static const bool usePhysicalDevice = true;       // ⚠️ false for Emulator
}
```

### 2. Get Your Laptop IP

**Windows:**
```powershell
ipconfig
# Look for "IPv4 Address" under your WiFi adapter
```

**Mac/Linux:**
```bash
ifconfig | grep "inet "
# or
ip addr show
```

---

## 🌐 Environment Options

### Development (default)
- **Web Browser:** `http://localhost:3000/api`
- **Android Emulator:** `http://10.0.2.2:3000/api`
- **Physical Device:** `http://YOUR_LAPTOP_IP:3000/api`

### Staging
```dart
static const Environment currentEnv = Environment.staging;
```
- URL: `https://staging-api.lalamove.com/api`

### Production
```dart
static const Environment currentEnv = Environment.production;
```
- URL: `https://api.lalamove.com/api`

---

## 💻 Platform Detection

The app **automatically detects** your platform:

| Platform | Detection | API URL |
|----------|-----------|---------|
| 🌐 **Web** | `kIsWeb` | `localhost:3000` |
| 📱 **Emulator** | `usePhysicalDevice = false` | `10.0.2.2:3000` |
| 📲 **Physical Device** | `usePhysicalDevice = true` | `YOUR_IP:3000` |

---

## 🚀 Running the Apps

### Web (Chrome)
```bash
flutter run -d chrome
```

### Android Emulator
1. Set in `constants.dart`:
   ```dart
   static const bool usePhysicalDevice = false;
   ```
2. Run:
   ```bash
   flutter run
   ```

### Physical Device (WiFi Required)
1. Get your laptop IP: `ipconfig`
2. Update `constants.dart`:
   ```dart
   static const String laptopIp = '192.168.1.XXX';  // Your IP
   static const bool usePhysicalDevice = true;
   ```
3. Connect device to **same WiFi**
4. Run:
   ```bash
   flutter run
   ```

---

## 🔍 Debug Console

When you run the app, you'll see:

```
🔧 ========== APP CONFIG ==========
📱 App: Lalamove v1.0.0
🌍 Environment: DEVELOPMENT
💻 Device Type: physicalDevice
🔌 API URL: http://192.168.1.173:3000/api
🔌 Socket URL: http://192.168.1.173:3000
🔧 ================================
```

This confirms your configuration is correct!

---

## ⚠️ Common Issues

### Issue: API Not Connecting on Physical Device

**Solution:**
1. ✅ Ensure device and laptop are on **same WiFi**
2. ✅ Check laptop IP is correct: `ipconfig`
3. ✅ Disable Windows Firewall temporarily
4. ✅ Verify backend is running: `http://YOUR_IP:3000/api/health`

### Issue: Android Emulator Can't Connect

**Solution:**
1. Use `10.0.2.2` instead of `localhost`
2. Set `usePhysicalDevice = false`

### Issue: iOS Physical Device Not Working

**Solution:**
1. Enable "Local Network" permission in iOS Settings
2. Use `http://` not `https://` for development
3. Add to `Info.plist`:
   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
     <key>NSAllowsLocalNetworking</key>
     <true/>
   </dict>
   ```

---

## 🎨 App Structure

```
lalamove_app/          # Customer + Intake Staff App
├── lib/
│   ├── screens/
│   │   ├── customer/  # Customer features
│   │   └── intake/    # Intake staff features
│   └── utils/
│       └── constants.dart  # 🔧 Configure here

app_giaohang/          # Driver + Deliverer App
├── lib/
│   ├── screens/       # Driver/Deliverer features
│   └── utils/
│       └── constants.dart  # 🔧 Configure here
```

---

## 📝 Development Checklist

- [ ] Backend running on `localhost:3000`
- [ ] Got laptop IP from `ipconfig`
- [ ] Updated `laptopIp` in `constants.dart`
- [ ] Set correct `usePhysicalDevice` value
- [ ] Device on same WiFi as laptop
- [ ] Firewall allows connection
- [ ] See debug output in console

---

## 🎯 Tips

1. **Use Web for fast development** - Hot reload is faster
2. **Test on Emulator before Physical Device**
3. **Check debug console** for API URL confirmation
4. **Staging/Production** - Switch environment easily without code changes

---

**Need Help?** Check console output or contact the dev team! 🚀
