# Firebase & Firestore Implementation Guide

This document explains the Firebase and Firestore integration in the Code Analyzer app.

## Setup Instructions

### 1. Configure Firebase Credentials

Update the `firebase_options.dart` file with your Firebase project credentials:

```dart
// Get these from Firebase Console
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: 'YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  databaseURL: 'YOUR_DATABASE_URL',
  storageBucket: 'YOUR_STORAGE_BUCKET',
);
```

### 2. Set Up Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Copy your credentials to `firebase_options.dart`

### 3. Enable Authentication & Firestore

In Firebase Console:
- Enable **Email/Password Authentication**
- Enable **Cloud Firestore** database
- Set up Firestore security rules

### Example Firestore Security Rules

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

## Key Features

### Authentication (Firebase Auth)
- **Sign Up**: Create new user accounts with email/password
- **Login**: Authenticate with Firebase
- **Auto-Login**: Persistent sessions via Firebase
- **Logout**: Clear authentication and local data

### Database (Cloud Firestore)
- **User Profiles**: Stored automatically on registration
- **Real-time Updates**: Stream data changes
- **Collections**: Organize data by type

## Firebase Service Methods

### Authentication Methods

```dart
// Register new user
await FirebaseService.register(
  email: 'user@example.com',
  password: 'password123',
  name: 'John Doe',
);

// Login user
await FirebaseService.login(
  email: 'user@example.com',
  password: 'password123',
);

// Logout
await FirebaseService.logout();

// Get current user profile
await FirebaseService.getUserProfile();

// Get auth state stream
FirebaseService.authStateChanges;
```

### Database Methods

```dart
// Add document
await FirebaseService.addDocument(
  collection: 'projects',
  data: {
    'name': 'My Project',
    'description': 'Project description',
  },
);

// Update document
await FirebaseService.updateDocument(
  collection: 'projects',
  docId: 'project123',
  data: {'status': 'completed'},
);

// Delete document
await FirebaseService.deleteDocument(
  collection: 'projects',
  docId: 'project123',
);

// Get documents stream
FirebaseService.getDocuments(
  'projects',
  orderBy: 'name',
  descending: false,
);
```

## Database Structure

### Users Collection
```
users/
  {uid}/
    - uid: string
    - email: string
    - name: string
    - createdAt: timestamp
    - updatedAt: timestamp
```

## Architecture

### Services Layer
- **FirebaseService**: Core Firebase operations
- **AuthService**: Authentication wrapper

### Provider Layer
- **AuthProvider**: State management for auth

### Screens
- **LoginScreen**: User authentication
- **DashboardScreen**: Main app interface
- **RegisterScreen**: New user registration

## Migration from Old Backend

Old implementation used:
- ❌ HTTP requests to `localhost:5000`
- ❌ SharedPreferences for token storage
- ❌ Manual session management

New implementation uses:
- ✅ Firebase Authentication (secure & scalable)
- ✅ Cloud Firestore (real-time database)
- ✅ Firebase Session Management (built-in)
- ✅ Server-side data validation

## Error Handling

Firebase Auth errors are handled with user-friendly messages:
- `user-not-found`: No user with this email
- `wrong-password`: Incorrect password
- `email-already-in-use`: Email already registered
- `weak-password`: Password too weak
- `invalid-email`: Invalid email format

## Testing

### Test Credentials (First Time)
1. Register a new account via the app
2. Login with that account
3. View profile in Dashboard

### Firebase Console Testing
1. Go to Firebase Console
2. Navigate to Firestore
3. Check `users` collection for new user documents

## Troubleshooting

### Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub upgrade
```

### Firebase Not Initializing
- Check `firebase_options.dart` configuration
- Verify Google Services credentials
- Ensure Firebase project is active

### Firestore Permission Denied
- Check security rules in Firebase Console
- Verify user is authenticated
- Check document ownership in rules

## Next Steps

1. **Implement User Profiles Screen**
   - Display user information
   - Allow profile updates
   - Avatar upload to Storage

2. **Add Projects Collection**
   - Create/read/update/delete projects
   - Store project metadata

3. **Real-time Features**
   - Use StreamBuilder for live updates
   - Implement Collections queries

4. **Offline Support**
   - Enable Firestore offline persistence
   - Sync when connection restored

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Guide](https://firebase.google.com/docs/firestore)
- [Flutter Firebase Plugin](https://firebase.flutter.dev/)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/start)

---

**Last Updated**: February 2026
