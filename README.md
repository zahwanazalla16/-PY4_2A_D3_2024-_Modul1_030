# logbook_app_001

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



## Menjalankan Vision App
### **Langkah 1: Buka Terminal PowerShell**

```powershell
# Navigate ke project folder
cd c:\Projects\Flutter\logbook_app_001
```

### **Langkah 2: Cek Flutter & Dependencies**

```powershell
# Cek versi Flutter
flutter --version

# Cek available devices (emulator atau physical device)
flutter devices
```

Output yang diharapkan:
```
# FLUTTER INFO
Flutter 3.x.x • channel stable
Dart 3.x.x

# AVAILABLE DEVICES
chrome           • Chrome           • web           • chrome
emulator-5554    • Android Emulator • android       • sdk gphone64_arm64
```

### **Langkah 3: Install Dependencies**

```powershell
# Download & install semua packages
flutter pub get

# Output:
# Running "flutter pub get" in logbook_app_001...
# packages have been installed...
```

### **Langkah 4: Clean Build (Opsional tapi Recommended)**

```powershell
# Hapus build artifacts lama
flutter clean

# Download packages lagi (optional)
flutter pub get
```

### **Langkah 5: Run Application**

```powershell
# Run ke device default (emulator atau physical device)
flutter run

# ATAU run ke specific device
flutter run -d emulator-5554

# ATAU run dengan verbose logging (untuk debugging)
flutter run -v
```

**Apa yang terjadi saat `flutter run`:**
```
✓ Compiling lib/main.dart for the Android ARM64 platform...
✓ Built build/app/outputs/app-release.apk
✓ Installing build/app/outputs/app-release.apk...
✓ Forwarding device port 34625 to host port 34625...
✓ 1 application installed. 11.2s

Launching lib/main.dart on Android Emulator in release mode...
Application finished.
The app is ready on device.

# Jika ada prompt di terminal, app sedang berjalan
# Tekan 'h' untuk help, 'r' untuk reload, 'R' untuk restart, 'q' untuk quit
```

### **Langkah 6: Grant Camera Permission (Android)**

Saat app pertama kali buka Vision:

```
1. App menampilkan prompt: "logbook_app_001 needs access to camera"
2. Click "Allow" untuk grant permission
3. Camera preview akan tampil
```

Jika ditolak:
```powershell
# Manual grant via adb (Android Debug Bridge)
adb shell pm grant com.example.logbook_app_001 android.permission.CAMERA
adb shell pm grant com.example.logbook_app_001 android.permission.WRITE_EXTERNAL_STORAGE
```

### **Langkah 7: Test Vision Features**

Setelah app berjalan:

1. **Camera Preview**
   - Tap tombol PCD Tools (gear icon)
   - Lihat modal dengan 8 filter buttons

2. **Test Filter**
   - Tap "Grayscale" → camera feed jadi grayscale
   - Tap lagi → normal color kembali
   - Tap "Blur" slider → geser untuk ubah blur amount

3. **Take Photo**
   - Tap tombol hijau (camera icon) → ambil foto
   - Navigate ke Image Editor
   - Lihat histogram otomatis muncul
   - Edit dengan filter & slider
   - Tap "Save" → simpan ke gallery

4. **Upload Photo**
   - Tap tombol biru (image icon)
   - Pilih foto dari gallery
   - Edit dengan Vision tools
   - Save

---

## Terminal Commands Reference

| Command | Kegunaan |
|---------|----------|
| `flutter devices` | List available devices |
| `flutter pub get` | Install dependencies |
| `flutter clean` | Delete build artifacts |
| `flutter run` | Run app ke default device |
| `flutter run -d <device_id>` | Run ke specific device |
| `flutter run -v` | Run dengan verbose logging |
| `r` (saat app berjalan) | Hot reload (code changes) |
| `R` (saat app berjalan) | Hot restart (full restart) |
| `q` (saat app berjalan) | Quit / stop app |

---

## Common Issues & Solutions
### **Issue 1: "No devices found"**
```powershell
# Solution: Start Android Emulator
# Buka Android Studio → Tools → AVD Manager → Click Play

# Atau via terminal:
emulator -avd Pixel_4_API_30 &

# Tunggu emulator boot, lalu
flutter devices
```

### **Issue 2: "Unable to find a target with hash string ..."**
```powershell
Solution: Build cache corrupted
flutter clean
flutter pub get
flutter run
```

### **Issue 3: "Camera Permission Denied"**
```powershell
# Emulator Settings → Apps & notifications → Permissions → Camera → Allow
# ATAU
adb shell pm grant com.example.logbook_app_001 android.permission.CAMERA
```

### **Issue 4: "Black Screen saat Camera Preview"**
```powershell
# Solution 1: Emulator camera tidak enabled
# Emulator settings → Camera → Webcam (enable)

# Solution 2: Force refresh
# Tekan 'R' di terminal (hot restart)

# Solution 3: Full rebuild
flutter clean && flutter pub get && flutter run
```

### **Issue 5: "App jalan lambat / jank"**
```powershell
# Run dalam release mode (faster)
flutter run --release

# Hindari blur filter besar-besaran saat development
```

---
