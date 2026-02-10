# Quick Reference Guide

A quick reference for working with the Firebase-integrated Code Analyzer app.

## 📋 Quick Links

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Project overview and features |
| [FIREBASE_SETUP.md](FIREBASE_SETUP.md) | Firebase configuration |
| [FIRESTORE_USAGE.md](FIRESTORE_USAGE.md) | Code examples and API |
| [CLEANUP_SUMMARY.md](CLEANUP_SUMMARY.md) | What changed and why |
| [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) | Migration from old system |
| [IMPLEMENTATION_REPORT.md](IMPLEMENTATION_REPORT.md) | Detailed report |

## 🚀 Getting Started in 5 Minutes

### 1. Setup Firebase
```bash
# Create Firebase project
# Enable Email/Password auth
# Enable Cloud Firestore
# Get credentials
```

### 2. Update Configuration
```dart
// lib/firebase_options.dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  databaseURL: 'YOUR_DATABASE_URL',
  storageBucket: 'YOUR_STORAGE_BUCKET',
);
```

### 3. Get Dependencies
```bash
flutter pub get
```

### 4. Run App
```bash
flutter run
```

## 📚 Common Tasks

### Authentication

**Register User**
```dart
final result = await FirebaseService.register(
  email: email,
  password: password,
  name: name,
);
```

**Login User**
```dart
final result = await FirebaseService.login(
  email: email,
  password: password,
);
```

**Logout**
```dart
await FirebaseService.logout();
```

**Get Current User**
```dart
final user = FirebaseService.currentUser;
final userProfile = await FirebaseService.getUserProfile();
```

### Database Operations

**Create Project**
```dart
String projectId = await FirestoreDatabase.createProject(
  name: 'Project Name',
  description: 'Description',
);
```

**Get Projects (Real-time)**
```dart
FirestoreDatabase.getUserProjects().listen((projects) {
  // projects.length, projects[0].name, etc.
});
```

**Update Project**
```dart
await FirestoreDatabase.updateProject(projectId, {
  'name': 'New Name',
});
```

**Delete Project**
```dart
await FirestoreDatabase.deleteProject(projectId);
```

**Create Report**
```dart
String reportId = await FirestoreDatabase.createAnalysisReport(
  projectId: projectId,
  status: 'completed',
  issuesFound: 5,
  warningsFound: 2,
  codeQualityScore: 8.5,
);
```

**Get Reports**
```dart
FirestoreDatabase.getProjectReports(projectId).listen((reports) {
  // reports.length, reports[0].status, etc.
});
```

## 🎨 UI Patterns

### Login Screen
```dart
// Uses CustomTextField and CustomButton
// Validates email and password
// Shows error messages
```

### Dashboard Screen
```dart
// Displays user welcome message
// Shows quick action cards
// Has logout button
```

### List with StreamBuilder
```dart
StreamBuilder<List<ProjectModel>>(
  stream: FirestoreDatabase.getUserProjects(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    if (!snapshot.hasData) return Text('No data');
    return ListView(
      children: snapshot.data!.map(...).toList(),
    );
  },
)
```

## 🔒 Security Rules

Firestore security rules (copy to Firebase Console):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    match /projects/{projectId} {
      allow read, write: if request.auth.uid == resource.data.ownerId;
    }
  }
}
```

## 🐛 Debugging

### Check Authentication Status
```dart
print('Current user: ${FirebaseService.currentUser}');
print('Is authenticated: ${FirebaseService.currentUser != null}');
```

### Check Firestore Data
```dart
// Use Firebase Console
// Browse Firestore collections
// Check for errors in logs
```

### Enable Logging
```dart
// Add to main.dart
if (kDebugMode) {
  // Enable verbose logging
}
```

## ⚡ Performance Tips

1. **Use Streams** for real-time data
   ```dart
   // Good: Real-time updates
   FirestoreDatabase.getUserProjects().listen(...)
   ```

2. **Limit Results**
   ```dart
   // Get only top 10
   query.limit(10)
   ```

3. **Order Results**
   ```dart
   // Sort by creation date
   query.orderBy('createdAt', descending: true)
   ```

4. **Cache Locally**
   ```dart
   // StreamBuilder caches automatically
   ```

## 📱 Testing

### Test Registration
1. Open app
2. Click "Register"
3. Fill form
4. Submit
5. Check Firebase Console → Auth

### Test Login
1. Enter credentials
2. Click Login
3. Verify dashboard appears
4. Check Firebase Console → Firestore

### Test Database
1. Create project
2. Check Firestore Console → projects collection
3. Document should exist with ownerId

## 🚨 Common Issues

| Issue | Solution |
|-------|----------|
| "Firebase not initialized" | Call Firebase.initializeApp() |
| "Permission denied" | Check Firestore security rules |
| "User not found" | Register account first |
| "App crashes on login" | Check firebase_options.dart |
| "Data not syncing" | Verify Firestore rules allow read |

## 📖 File Structure

```
lib/
├── main.dart                  # Firebase init + routing
├── firebase_options.dart      # Firebase config (EDIT THIS)
├── config/
│   ├── constants.dart
│   └── theme.dart
├── models/
│   └── firestore_models.dart  # Data models
├── providers/
│   └── auth_provider.dart     # State management
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── dashboard_screen.dart
├── services/
│   ├── firebase_service.dart      # Auth
│   ├── firestore_database.dart    # Database
│   └── auth_service.dart          # Wrapper
└── widgets/
    ├── custom_button.dart
    └── custom_text_field.dart
```

## 🔗 Dependencies

```yaml
firebase_core: ^2.24.0
firebase_auth: ^4.15.0
cloud_firestore: ^4.14.0
provider: ^6.1.2
flutter: sdk
cupertino_icons: ^1.0.8
```

## 💡 Usage Examples

See [FIRESTORE_USAGE.md](FIRESTORE_USAGE.md) for:
- Complete code examples
- Screen implementations
- Error handling patterns
- Best practices

## 🎓 Next Steps

1. ✅ Configure Firebase credentials
2. ✅ Run `flutter pub get`
3. ✅ Test authentication flow
4. ✅ Implement your features
5. ✅ Deploy to Firebase

## 📞 Support

- Check [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for setup issues
- Check [FIRESTORE_USAGE.md](FIRESTORE_USAGE.md) for usage questions
- Check [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) for migration help
- Check [CLEANUP_SUMMARY.md](CLEANUP_SUMMARY.md) for what changed

---

**Happy coding!** 🎉

For detailed documentation, see:
- [Complete Setup Guide](FIREBASE_SETUP.md)
- [API Reference](FIRESTORE_USAGE.md)
- [Migration Guide](MIGRATION_GUIDE.md)
