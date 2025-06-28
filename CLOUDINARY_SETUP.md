# Cloudinary Setup Guide

## 🆓 Free Alternative to Firebase Storage

Cloudinary offers a generous **free tier** with:
- **25GB storage**
- **25GB bandwidth per month**
- **No credit card required**
- **Perfect for student projects**

## 📋 Setup Steps

### 1. Create Cloudinary Account
1. Go to [cloudinary.com](https://cloudinary.com)
2. Click "Sign Up For Free"
3. Fill in your details (no credit card required)
4. Verify your email

### 2. Get Your Credentials
1. After signing in, go to your **Dashboard**
2. Note down your **Cloud Name** (shown in the dashboard)
3. Go to **Settings** → **Upload** tab
4. Scroll down to **Upload presets**
5. Click **"Add upload preset"**
6. Set **Signing Mode** to **"Unsigned"**
7. Set **Folder** to **"ssu_club_hub"** (or your preferred folder)
8. Click **"Save"**
9. Note down the **Preset name**

### 3. Update Configuration
Open `lib/core/config/cloudinary_config.dart` and replace:

```dart
class CloudinaryConfig {
  // Replace these with your actual Cloudinary credentials
  static const String cloudName = 'da4gqys2t';        // ← Your cloud name
  static const String uploadPreset = 'ssu_club_hub';  // ← Your preset name
  
  // Optional: API Key and Secret (for advanced features)
  static const String apiKey = '431371291439882';
  static const String apiSecret = 'sh5pp_AxQTsCdetqWR5igHqfDoo';
}
```

### 4. Initialize Cloudinary
In your `main.dart`, add this after Firebase initialization:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await dotenv.load(fileName: ".env");
  }
  await FirebaseInit.initialize();
  
  // Initialize Cloudinary
  CloudinaryStorageService.initialize();
  
  runApp(
    provider.ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ProviderScope(child: MyApp()),
    ),
  );
}
```

## 🚀 Features Available

### ✅ What Works
- **Image uploads** from gallery and camera
- **File uploads** (documents, PDFs, etc.)
- **Automatic image optimization**
- **CDN delivery** for fast loading
- **Secure HTTPS URLs**
- **Folder organization**

### ⚠️ Limitations (Free Tier)
- **No file deletion** (requires paid plan)
- **No file size info** (requires paid plan)
- **Web uploads** limited (use mobile for best experience)

## 📱 Usage Examples

### Upload Profile Image
```dart
final downloadUrl = await CloudinaryStorageService.uploadImageFromGallery('profiles');
```

### Upload Event Image
```dart
final downloadUrl = await CloudinaryStorageService.uploadImageFromGallery('events');
```

### Upload Chat File
```dart
final downloadUrl = await CloudinaryStorageService.pickAndUploadFile('chat');
```

## 🔒 Security Notes

- **Upload presets** are public (safe to expose)
- **Cloud name** is public (safe to expose)
- **API keys** are private (keep secret if using advanced features)

## 💰 Cost Comparison

| Service | Free Tier | Paid Plans |
|---------|-----------|------------|
| **Cloudinary** | 25GB storage, 25GB bandwidth | $89/month for 225GB |
| **Firebase Storage** | 5GB storage, 1GB/day download | $0.026/GB storage |
| **AWS S3** | 5GB storage, 20,000 requests | $0.023/GB storage |

**Cloudinary is the most generous free option!**

## 🛠️ Troubleshooting

### "Invalid upload preset" error
- Check your preset name is correct
- Ensure preset is set to "Unsigned"
- Verify preset is active

### "Cloud name not found" error
- Check your cloud name is correct
- Ensure your account is active

### Upload fails on web
- Web uploads have limitations
- Use mobile app for best experience
- Check browser console for errors

## 📞 Support

- **Cloudinary Docs**: [cloudinary.com/documentation](https://cloudinary.com/documentation)
- **Flutter Package**: [pub.dev/packages/cloudinary_public](https://pub.dev/packages/cloudinary_public)
- **Community**: [Stack Overflow](https://stackoverflow.com/questions/tagged/cloudinary)

---

**🎉 You're all set! Your app now uses free, reliable file storage with Cloudinary!** 