import 'firebase_service.dart';

class AuthService {
  // Register user with Firebase
  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    return await FirebaseService.register(
      email: email,
      password: password,
      name: name,
    );
  }

  // Login user with Firebase
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    return await FirebaseService.login(
      email: email,
      password: password,
    );
  }

  // Logout user
  static Future<void> logout() async {
    await FirebaseService.logout();
  }

  // Get current user profile
  static Future<Map<String, dynamic>?> getUser() async {
    return await FirebaseService.getUserProfile();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    return FirebaseService.currentUser != null;
  }
}