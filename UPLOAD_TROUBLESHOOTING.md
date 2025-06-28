# Upload Troubleshooting Guide

## 🔧 Common Upload Issues and Solutions

### Issue 1: "Cloudinary connection failed"
**Symptoms:**
- Upload button doesn't work
- Error message: "Cloudinary connection failed. Please check your configuration."

**Solutions:**
1. **Check Cloudinary Configuration**
   - Open `lib/core/config/cloudinary_config.dart`
   - Verify your cloud name and upload preset are correct
   - Make sure your Cloudinary account is active

2. **Verify Upload Preset**
   - Log into your Cloudinary dashboard
   - Go to Settings → Upload
   - Check that your upload preset is set to "Unsigned"
   - Ensure the preset is active

3. **Test Configuration**
   - Run the app and check the debug console
   - Look for the "Cloudinary Configuration Debug" output
   - Verify all values are correct

### Issue 2: "No image selected" or "No image captured"
**Symptoms:**
- Image picker opens but no image is uploaded
- No error message appears

**Solutions:**
1. **Check Permissions**
   - Ensure the app has permission to access camera and gallery
   - On Android: Check Settings → Apps → Your App → Permissions
   - On iOS: Check Settings → Privacy & Security → Photos/Camera

2. **Test Image Picker**
   - Try selecting different image formats (JPG, PNG)
   - Try different image sizes
   - Check if the issue occurs on both camera and gallery

### Issue 3: "Error uploading file"
**Symptoms:**
- Image is selected but upload fails
- Error message appears in console

**Solutions:**
1. **Check Internet Connection**
   - Ensure you have a stable internet connection
   - Try uploading on different networks

2. **Check File Size**
   - Try uploading smaller images (under 1MB)
   - Check if the issue occurs with specific file types

3. **Check Cloudinary Limits**
   - Verify you haven't exceeded your free tier limits
   - Check your Cloudinary dashboard for usage statistics

### Issue 4: Web Upload Not Working
**Symptoms:**
- Upload works on mobile but not on web
- Error message: "Web upload not fully supported"

**Solutions:**
1. **Use Mobile App**
   - Web uploads have limitations
   - Use the mobile app for best experience

2. **Check Browser Console**
   - Open browser developer tools
   - Look for JavaScript errors
   - Check network requests

## 🛠️ Debug Steps

### Step 1: Check Configuration
```dart
// Add this to your main.dart temporarily
CloudinaryStorageService.debugConfiguration();
```

### Step 2: Test Connection
```dart
// Add this to test Cloudinary connection
final isConnected = await CloudinaryStorageService.testConnection();
print('Connection test result: $isConnected');
```

### Step 3: Check Console Output
Look for these debug messages:
- `=== Cloudinary Configuration Debug ===`
- `=== Testing Cloudinary Connection ===`
- `Uploading file: [filename] to folder: [folder]`
- `Upload successful: [url]`

## 📱 Platform-Specific Issues

### Android
- **Permission Issues**: Add camera and storage permissions to `android/app/src/main/AndroidManifest.xml`
- **File Access**: Ensure the app can access external storage

### iOS
- **Permission Issues**: Add camera and photo library usage descriptions to `ios/Runner/Info.plist`
- **Simulator Issues**: Some features may not work in iOS Simulator

### Web
- **Browser Compatibility**: Test in different browsers (Chrome, Firefox, Safari)
- **File API**: Some browsers may have limitations with file uploads

## 🔍 Advanced Debugging

### Enable Verbose Logging
```dart
// Add this to see detailed upload logs
print('Debug: Starting upload process');
print('Debug: File selected: ${image.name}');
print('Debug: File size: ${image.length()} bytes');
```

### Test with Different Files
- Try uploading different image formats
- Test with various file sizes
- Try uploading from different sources (camera vs gallery)

### Check Network Requests
- Use browser developer tools (F12)
- Go to Network tab
- Look for requests to Cloudinary
- Check for any failed requests

## 📞 Getting Help

If you're still having issues:

1. **Check the Console Output**
   - Look for error messages
   - Note the exact error text

2. **Verify Your Setup**
   - Follow the Cloudinary setup guide again
   - Double-check all configuration values

3. **Test with Sample Code**
   - Try the basic upload example from Cloudinary docs
   - Compare with your implementation

4. **Contact Support**
   - Cloudinary Support: https://support.cloudinary.com/
   - Flutter Community: https://stackoverflow.com/questions/tagged/flutter

## ✅ Quick Fix Checklist

- [ ] Cloudinary account is active
- [ ] Upload preset is set to "Unsigned"
- [ ] Cloud name and preset name are correct
- [ ] App has proper permissions
- [ ] Internet connection is stable
- [ ] File size is reasonable (< 10MB)
- [ ] Testing on mobile device (not just web)

---

**💡 Tip**: Most upload issues are related to configuration or permissions. Start by checking your Cloudinary setup and app permissions. 