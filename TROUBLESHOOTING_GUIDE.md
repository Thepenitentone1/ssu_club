# Troubleshooting Guide - SSU Club Hub

## 🔧 Current Issues & Solutions

### Issue 1: Cloudinary Upload Not Working
**Error**: `❌ Cloudinary connection test failed: No URL returned`
**Web Error**: `MissingPluginException(No implementation found for method getTemporaryDirectory)`

#### Quick Fixes:
1. **Web Platform Limitation**
   - **Web uploads are not fully supported** due to browser limitations
   - **Use mobile app** for uploading images and files
   - **Error message**: "Web upload not supported. Please use mobile app for uploading images."

2. **Check Cloudinary Configuration**
   ```dart
   // In lib/core/config/cloudinary_config.dart
   static const String cloudName = 'your_cloud_name';        // ← Must match dashboard
   static const String uploadPreset = 'your_preset_name';    // ← Must be "Unsigned"
   ```

3. **Verify Upload Preset Settings**
   - Go to [Cloudinary Dashboard](https://cloudinary.com/console)
   - Settings → Upload → Upload presets
   - Ensure preset is set to **"Unsigned"**
   - Make sure preset is **active**

4. **Test on Mobile Device**
   - Web uploads have limitations
   - Use mobile app for best experience
   - Check console for detailed error messages

#### Debug Steps:
1. **Run the app** and check console output
2. **Click "Test Upload" button** in Profile page
3. **Look for these debug messages**:
   ```
   ✅ Cloudinary initialized successfully
   Cloud Name: your_cloud_name
   Upload Preset: your_preset_name
   📸 Picking image from gallery...
   ✅ Image selected: filename.jpg
   📤 Uploading file: filename_timestamp.jpg to folder: profiles
   ✅ Upload successful: https://res.cloudinary.com/...
   ```

### Issue 2: Clubs Page Not Loading

#### Quick Fixes:
1. **Check Navigation**
   - Ensure you're clicking the "Clubs" tab in bottom navigation
   - Verify the page is included in the pages list

2. **Check Console for Errors**
   - Look for any error messages in the debug console
   - Check if there are any import issues

3. **Verify File Structure**
   - Ensure `lib/features/clubs/presentation/pages/clubs_page.dart` exists
   - Check that the import in `main.dart` is correct

#### Debug Steps:
1. **Check if other pages load** (Events, Announcements, etc.)
2. **Try refreshing the app**
3. **Check console for any error messages**

## 🛠️ Manual Testing Steps

### Test 1: Cloudinary Upload
1. **Open the app**
2. **Go to Profile page**
3. **Click "Test Upload" button**
4. **Check console output**
5. **Try uploading a profile image**

**⚠️ Important**: Web uploads are limited. Use mobile app for full functionality.

### Test 2: Clubs Page
1. **Open the app**
2. **Click "Clubs" in bottom navigation**
3. **Verify clubs list appears**
4. **Try clicking on a club**

### Test 3: Notifications
1. **Open the app on mobile device**
2. **Check if notification permissions are requested**
3. **Look for FCM token in console**

## 🔍 Common Error Messages & Solutions

### Cloudinary Errors:
- **"Invalid upload preset"**: Check preset name and settings
- **"Cloud name not found"**: Verify cloud name in dashboard
- **"No URL returned"**: Usually web platform limitation or network issue
- **"MissingPluginException"**: Web platform limitation - use mobile app

### Navigation Errors:
- **"Clubs page not found"**: Check import statements
- **"Page not loading"**: Check if widget is properly exported

### Notification Errors:
- **"Permission denied"**: Check app permissions
- **"FCM token not generated"**: Check Firebase configuration

## 📱 Platform-Specific Issues

### Web Platform:
- **Upload limitations**: Use mobile for best upload experience
- **File picker issues**: Some browsers have restrictions
- **Network issues**: Check CORS settings
- **path_provider issues**: Not fully supported on web

### Mobile Platform:
- **Permission issues**: Grant camera and storage permissions
- **File access**: Ensure app can access device storage
- **Network issues**: Check mobile data/WiFi connection

## 🚀 Quick Debug Commands

### Check Dependencies:
```bash
flutter pub get
flutter clean
flutter pub get
```

### Run with Debug Info:
```bash
flutter run --debug
```

### Check for Issues:
```bash
flutter doctor
flutter analyze
```

## 📞 Getting Help

### If Issues Persist:

1. **Check Console Output**
   - Copy all error messages
   - Note the exact error text

2. **Verify Configuration**
   - Double-check Cloudinary credentials
   - Ensure Firebase is properly configured

3. **Test on Different Device**
   - Try on mobile vs web
   - Test on different browsers

4. **Contact Support**
   - Share console output
   - Describe exact steps to reproduce

## ✅ Success Indicators

### Upload Working (Mobile):
- ✅ Console shows "Upload successful"
- ✅ URL is returned and saved
- ✅ Image appears in profile

### Upload Working (Web):
- ⚠️ Limited functionality
- ✅ No crashes or errors
- ✅ Clear message about mobile recommendation

### Clubs Loading:
- ✅ Clubs list appears
- ✅ Can click on clubs
- ✅ Club details show

### Notifications Working:
- ✅ Permission requested
- ✅ FCM token generated
- ✅ Local notifications work

## 🌐 Web-Specific Notes

### What Works on Web:
- ✅ Viewing clubs, events, announcements
- ✅ Chat functionality
- ✅ Profile viewing
- ✅ Theme switching

### What's Limited on Web:
- ⚠️ File uploads (use mobile)
- ⚠️ Camera access (use mobile)
- ⚠️ Push notifications (use mobile)

---

**💡 Tip**: For the best experience, use the mobile app for uploading files and receiving notifications! 