# 📱 Jeel ERP - Installation Guide

## System Requirements
- **OS:** Android 8.0 (API level 26) or higher
- **Storage:** Minimum 100 MB free space
- **RAM:** Minimum 2 GB
- **Features:** Biometric sensor (optional for fingerprint login)

## Installation Steps

### Step 1: Download APK
- Download `jeel-erp-v1.0.0-release.apk` from the releases folder

### Step 2: Enable Unknown Sources
1. Go to **Settings** on your Android device
2. Navigate to **Security** or **Apps**
3. Enable **"Unknown sources"** or **"Install unknown apps"**
   - For Android 10+: Go to **Settings > Apps & notifications > Advanced > Install unknown apps > File Manager** (enable)

### Step 3: Install APK
1. Open **File Manager** on your device
2. Navigate to the folder where you downloaded `jeel-erp-v1.0.0-release.apk`
3. Tap on the APK file
4. Tap **"Install"** when prompted
5. Wait for installation to complete

### Step 4: Launch Application
1. Go to **App Drawer** or **Home Screen**
2. Find and tap **"Jeel ERP"** icon
3. App will launch with splash screen
4. You will be redirected to the login screen

## First Time Login

### Option 1: Biometric Login (Fingerprint/Face ID)
1. Ensure your device has registered biometric data
2. Tap the **fingerprint icon** on the login screen
3. Follow the on-screen prompts
4. Successful authentication will auto-fill credentials and log you in

### Option 2: Manual Login
1. Tap **"Login without Fingerprint"** button
2. Enter your **email address**
3. Enter your **password**
4. Tap **"Log in"** button
5. You will be authenticated and redirected to the WebView

### Option 3: Quick Entry
1. If you've previously logged in with **"Remember Me"** enabled:
   - Credentials will auto-fill on subsequent app launches
   - Tap "Log in" or use biometric verification

## Features Guide

### 🔐 Biometric Authentication
- **Availability:** Only if device has enrolled biometric data
- **Methods:** Fingerprint, Face ID, or Iris (device dependent)
- **Error Handling:** Clear error messages for:
  - No biometric enrolled
  - Device doesn't support biometric
  - Biometric locked (too many failed attempts)

### 💾 Remember Me
- Checkbox available on login screen
- Saves your email address for future logins
- Password is securely stored locally

### ⏱️ Session Timeout
- Session automatically expires after **7 days**
- You will be returned to login screen after timeout
- Remember Me setting persists

### 🔒 Security Features
- **Failed Login Lockout:** After 5 failed attempts, account is locked for 15 minutes
- **Secure Storage:** All sensitive data encrypted locally
- **No Server Storage:** Credentials stored only on device

## Troubleshooting

### App Won't Install
- **Issue:** "Parse error" or "Package corrupt"
- **Solution:** 
  - Re-download APK file
  - Ensure file is not corrupted (check file size: 46.37 MB)

### Biometric Not Working
- **Issue:** Fingerprint icon inactive or error
- **Solutions:**
  1. Ensure at least one biometric is enrolled (Settings > Security > Biometric)
  2. Check if device supports biometric
  3. Try using "Login without Fingerprint" instead
  4. Restart the device

### Login Fails After Multiple Attempts
- **Issue:** Account locked after failed login attempts
- **Solution:** Wait 15 minutes before trying again

### WebView Not Loading
- **Issue:** WebView content not displayed
- **Solutions:**
  1. Check internet connection
  2. Clear app cache (Settings > Apps > Jeel ERP > Storage > Clear Cache)
  3. Uninstall and reinstall the app

### Session Expires Too Quickly
- **Issue:** Logged out unexpectedly
- **Solution:**
  - Check if your session timeout is 7 days
  - If you need to stay logged in longer, enable "Remember Me" and use biometric login

## Uninstallation
1. Go to **Settings > Apps > Jeel ERP**
2. Tap **"Uninstall"**
3. Confirm uninstallation

## Contact & Support
For issues or feature requests, contact the development team.

## Version Information
- **Current Version:** 1.0.0
- **Release Date:** December 9, 2025
- **APK Name:** jeel-erp-v1.0.0-release.apk
- **Size:** 46.37 MB
- **API Level:** 26+ (Android 8.0+)

---

**Happy using Jeel ERP! 🎉**
