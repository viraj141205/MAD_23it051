# Code Analyzer

A modern Flutter application for analyzing code quality with Firebase authentication and Firestore database integration.

## Overview

Code Analyzer is a comprehensive code analysis tool built with Flutter. It provides users with detailed insights into their code quality, issues, and recommendations using a secure Firebase backend.

### Key Features

- 🔐 **Secure Authentication**: Firebase Email/Password authentication
- ☁️ **Cloud Database**: Cloud Firestore for data persistence
- 📊 **Real-time Updates**: Stream-based data updates
- 🎯 **Code Analysis**: Analyze and track code quality metrics
- 📈 **Reports**: Detailed analysis reports with history
- ⚙️ **User Settings**: Customizable user preferences
- 📝 **Activity Logging**: Track user actions and changes

## Technology Stack

### Frontend
- **Flutter 3.10.8+**: UI framework
- **Provider 6.1.2**: State management
- **Material Design**: UI components

### Backend
- **Firebase Core**: Platform integration
- **Firebase Auth**: User authentication
- **Cloud Firestore**: Database & real-time sync

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── firebase_options.dart          # Firebase configuration
├── config/
│   ├── constants.dart            # App constants
│   └── theme.dart                # Theme definitions
├── models/
│   └── firestore_models.dart     # Data models
├── providers/
│   └── auth_provider.dart        # Auth state management
├── screens/
│   ├── login_screen.dart         # Login UI
│   ├── register_screen.dart      # Registration UI
│   └── dashboard_screen.dart     # Main dashboard
├── services/
│   ├── firebase_service.dart     # Firebase operations
│   ├── firestore_database.dart   # Database methods
│   └── auth_service.dart         # Auth wrapper
└── widgets/
    ├── custom_button.dart        # Reusable button
    └── custom_text_field.dart    # Reusable text field
```

## Getting Started

### Prerequisites
- Flutter SDK 3.10.8 or higher
- Dart 3.0+
- Firebase project

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd code_analyzer
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Copy your credentials
   - Update `lib/firebase_options.dart` with your credentials
   - Enable Email/Password authentication
   - Enable Cloud Firestore

4. **Run the app**
   ```bash
   flutter run
   ```

## Configuration

### Firebase Setup

See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed Firebase configuration instructions.

### Required Steps

1. **Enable Authentication**
   - Go to Firebase Console → Authentication
   - Enable Email/Password provider

2. **Set Up Firestore**
   - Go to Firebase Console → Firestore Database
   - Create database in your region
   - Apply security rules from FIREBASE_SETUP.md

3. **Configure App**
   - Edit `lib/firebase_options.dart`
   - Add your Firebase project credentials

## Usage

### Authentication Flow

1. **Register**: Create new account with email/password
2. **Login**: Authenticate with credentials
3. **Dashboard**: Access main app features
4. **Logout**: Sign out securely

### Database Operations

See [FIRESTORE_USAGE.md](FIRESTORE_USAGE.md) for detailed usage examples:
- Creating projects
- Managing analysis reports
- User settings
- Activity logging
- Searching and filtering

## Code Cleanup

This project has been optimized with the following changes:

### Removed
- ❌ HTTP requests to local server
- ❌ SharedPreferences token storage
- ❌ Manual session management
- ❌ Placeholder UI elements
- ❌ Unnecessary dependencies

### Added
- ✅ Firebase Authentication
- ✅ Cloud Firestore database
- ✅ Real-time data sync
- ✅ Comprehensive error handling
- ✅ Database service layer
- ✅ Data models with serialization

See [CLEANUP_SUMMARY.md](CLEANUP_SUMMARY.md) for detailed changes.

## API Reference

### Firebase Service
- `register()` - Register new user
- `login()` - Authenticate user
- `logout()` - Sign out user
- `getUserProfile()` - Get user data
- `authStateChanges` - Auth state stream

### Firestore Database
- `createProject()` - Create project
- `getUserProjects()` - Get user's projects
- `updateProject()` - Update project data
- `deleteProject()` - Delete project
- `createAnalysisReport()` - Create report
- `getProjectReports()` - Get project reports
- `saveUserSettings()` - Save preferences
- `logActivity()` - Log user action

See [FIRESTORE_USAGE.md](FIRESTORE_USAGE.md) for complete API documentation.

## Security

- **Authentication**: Handled by Firebase Auth
- **Data Encryption**: In-transit and at-rest encryption
- **User Isolation**: Each user can only access their data
- **Input Validation**: Server-side validation
- **Security Rules**: Firestore rules enforce access control

For security best practices, see [FIREBASE_SETUP.md](FIREBASE_SETUP.md#security-considerations).

## Testing

### Manual Testing
1. Register new account
2. Verify account in Firebase Console
3. Login with credentials
4. Create projects
5. View analysis reports
6. Test logout

### Console Testing
- Monitor Firestore in Firebase Console
- Check Auth users in Authentication tab
- View activity logs in Firestore

## Troubleshooting

### Build Issues
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### Firebase Connection Issues
- Verify credentials in `firebase_options.dart`
- Check Firebase Console configuration
- Ensure Firestore is enabled

### Authentication Issues
- Check security rules in Firestore
- Verify Email/Password authentication is enabled
- Clear app cache and rebuild

## Performance Optimization

- Indexed queries for fast searches
- Stream-based real-time updates
- Lazy loading for large datasets
- Efficient state management with Provider
- Optimized widget rebuilds

## Future Enhancements

- [ ] Google/GitHub authentication
- [ ] Two-factor authentication
- [ ] Profile picture uploads to Storage
- [ ] Collaborative projects
- [ ] Advanced analytics
- [ ] Export reports as PDF
- [ ] Email notifications
- [ ] Dark mode improvements

## Contributing

Contributions are welcome! Please follow the code style and conventions used in the project.

## License

This project is licensed under the MIT License - see LICENSE file for details.

## Support

For issues, questions, or feedback:
1. Check [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
2. Check [FIRESTORE_USAGE.md](FIRESTORE_USAGE.md)
3. Review [CLEANUP_SUMMARY.md](CLEANUP_SUMMARY.md)
4. Open an issue on GitHub

## Resources

- [Flutter Documentation](https://flutter.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Guide](https://firebase.google.com/docs/firestore)
- [Provider Package](https://pub.dev/packages/provider)

---

**Last Updated**: February 2026
**Version**: 1.0.0
