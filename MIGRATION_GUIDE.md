# Migration Guide: From Local Backend to Firebase

This guide helps developers understand and adapt to the Firebase migration.

## What Changed?

### Before: Local Backend with HTTP
```dart
// OLD: HTTP-based authentication
const String baseUrl = 'http://localhost:5000/api/auth';

// Manual token management
final response = await http.post(
  Uri.parse('$baseUrl/login'),
  body: jsonEncode({'email': email, 'password': password}),
);

// Manual session storage
final prefs = await SharedPreferences.getInstance();
await prefs.setString('token', token);
```

### After: Firebase Authentication
```dart
// NEW: Firebase authentication
final result = await FirebaseService.login(
  email: email,
  password: password,
);

// Automatic session management
// No need for manual token storage!
```

## Migration Steps

### Step 1: Update Dependencies

**Old `pubspec.yaml`**:
```yaml
dependencies:
  http: ^1.2.1
  shared_preferences: ^2.2.3
  provider: ^6.1.2
```

**New `pubspec.yaml`**:
```yaml
dependencies:
  provider: ^6.1.2
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.14.0
```

### Step 2: Initialize Firebase

Add to your `main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CodeAnalyzerApp());
}
```

### Step 3: Replace Auth Service

**Old implementation**:
```dart
// auth_service.dart
class AuthService {
  static const String baseUrl = 'http://localhost:5000/api/auth';
  
  static Future<Map<String, dynamic>> login(email, password) async {
    // HTTP POST request
  }
}
```

**New implementation**:
```dart
// auth_service.dart
import 'firebase_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) {
    return FirebaseService.login(email: email, password: password);
  }
}
```

### Step 4: Update Auth Provider

**Old state management**:
```dart
class AuthProvider with ChangeNotifier {
  String? _token;
  bool get isAuthenticated => _token != null;
  
  Future<bool> login(...) async {
    _token = result['token'];
    // Manual state update
  }
}
```

**New state management**:
```dart
class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  bool get isAuthenticated => 
    FirebaseService.currentUser != null;
  
  Future<bool> login(...) async {
    _user = result['user'];
    // Firebase handles session
  }
}
```

### Step 5: Update Navigation

**Old navigation**:
```dart
// main.dart
home: Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    if (authProvider.isAuthenticated) {
      return DashboardScreen();
    }
    return LoginScreen();
  },
)
```

**New navigation**:
```dart
// main.dart
home: StreamBuilder(
  stream: FirebaseService.authStateChanges,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return DashboardScreen();
    }
    return LoginScreen();
  },
)
```

### Step 6: Database Operations

**Old approach** (No database, only HTTP):
```dart
// Data was handled by backend only
// No local database operations
```

**New approach** (Firestore):
```dart
import 'services/firestore_database.dart';

// Create project
String projectId = await FirestoreDatabase.createProject(
  name: 'My Project',
  description: 'My description',
);

// Get projects realtime
FirestoreDatabase.getUserProjects().listen((projects) {
  print('Projects updated: ${projects.length}');
});

// Update project
await FirestoreDatabase.updateProject(projectId, {
  'name': 'Updated name',
});
```

## Feature Comparison

| Feature | Old System | New System |
|---------|-----------|-----------|
| Authentication | HTTP + LocalHost | Firebase Auth |
| Token Storage | SharedPreferences | Firebase Sessions |
| Real-time Updates | Not supported | Native support |
| Database | Server only | Cloud Firestore |
| Scalability | Limited | Enterprise-grade |
| Cost | Server costs | Pay-as-you-go |
| Maintenance | Manual | Managed |
| Security | Basic | Industry-standard |

## Code Examples

### Authentication

**Old way**:
```dart
// Manual HTTP request
final response = await http.post(
  Uri.parse('http://localhost:5000/api/auth/login'),
  body: jsonEncode({'email': email, 'password': password}),
);

if (response.statusCode == 200) {
  final token = jsonDecode(response.body)['token'];
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
}
```

**New way**:
```dart
// Simple Firebase call
final result = await FirebaseService.login(
  email: email,
  password: password,
);

if (result['success']) {
  // Automatically logged in and persisted
}
```

### Getting User Data

**Old way**:
```dart
// Manual HTTP request with token
final token = await SharedPreferences.getInstance()
  .then((p) => p.getString('token'));

final response = await http.get(
  Uri.parse('http://localhost:5000/api/auth/profile'),
  headers: {'Authorization': 'Bearer $token'},
);

final user = jsonDecode(response.body)['user'];
```

**New way**:
```dart
// Simple Firebase call
final user = await FirebaseService.getUserProfile();
// Auto-fetches from Firestore
```

### Creating Database Records

**Old way**:
```dart
// Store in backend only
final response = await http.post(
  Uri.parse('http://localhost:5000/api/projects'),
  headers: {'Authorization': 'Bearer $token'},
  body: jsonEncode(projectData),
);
```

**New way**:
```dart
// Store in Firestore
String projectId = await FirestoreDatabase.createProject(
  name: projectData['name'],
  description: projectData['description'],
);
```

### Real-time Updates

**Old way**:
```dart
// Manual polling required
Timer.periodic(Duration(seconds: 5), (_) {
  // Fetch data again
  fetchProjects();
});
```

**New way**:
```dart
// Automatic real-time sync
FirestoreDatabase.getUserProjects().listen((projects) {
  // Called automatically when data changes
});
```

## Breaking Changes

### Removed
- `http` package usage
- `shared_preferences` for auth tokens
- Manual token management
- LocalHost backend reference
- `String? get token` from AuthProvider

### Added
- Firebase initialization
- `firebase_options.dart` configuration
- `FirebaseService` for auth
- `FirestoreDatabase` for data
- Stream-based auth state
- Data models with serialization

## Troubleshooting Migration

### Issue: "Could not find http"
**Solution**: Run `flutter pub get` to install Firebase packages

### Issue: "Firebase not initialized"
**Solution**: Ensure `Firebase.initializeApp()` is called before `runApp()`

### Issue: "Permission denied" in Firestore
**Solution**: Check Firestore security rules in Firebase Console

### Issue: "User not found" in login
**Solution**: Verify user exists in Firebase Authentication console

## Testing the Migration

### 1. Authentication Test
```dart
// Register new user
final registerResult = await FirebaseService.register(
  email: 'test@example.com',
  password: 'Test123!',
  name: 'Test User',
);
assert(registerResult['success']);

// Login
final loginResult = await FirebaseService.login(
  email: 'test@example.com',
  password: 'Test123!',
);
assert(loginResult['success']);

// Verify in Firebase Console
```

### 2. Database Test
```dart
// Create project
String projectId = await FirestoreDatabase.createProject(
  name: 'Test Project',
  description: 'Test description',
);
assert(projectId.isNotEmpty);

// Check in Firestore Console
// projects/{projectId} should exist
```

### 3. Real-time Test
```dart
// Listen to changes
FirestoreDatabase.getUserProjects().listen((projects) {
  print('Current projects: ${projects.length}');
});

// Add project in console
// Listen should automatically fire with updated list
```

## Performance Tips

1. **Use Streams for Real-time Data**
   - Prefer `Stream<List>` over repeated `Future` calls
   - Reduces database reads

2. **Batch Operations**
   - Combine multiple writes
   - Use `batch.commit()` for atomic updates

3. **Indexed Queries**
   - Create indexes for frequently queried fields
   - Check Firestore console for suggestions

4. **Lazy Loading**
   - Use `limit()` to fetch only needed documents
   - Implement pagination

## Next Steps

1. **Update all screens** to use new services
2. **Test authentication flow** thoroughly
3. **Populate Firestore** with test data
4. **Implement remaining features** with new architecture
5. **Monitor Firebase Console** for errors

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Firebase Auth Error Codes](https://firebase.google.com/docs/auth/troubleshoot)
- [Flutter Firebase Setup](https://firebase.flutter.dev/)

## Support

If you encounter issues during migration:
1. Check [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
2. Review [FIRESTORE_USAGE.md](FIRESTORE_USAGE.md)
3. Check [CLEANUP_SUMMARY.md](CLEANUP_SUMMARY.md)
4. Review Firebase Console logs

---

**Migration completed successfully!** ✅

Your app is now using Firebase for authentication and Cloud Firestore for data storage.
