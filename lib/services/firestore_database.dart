import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/firestore_models.dart';
import 'firebase_service.dart';

class FirestoreDatabase {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== Projects Collection ====================

  /// Create a new project
  static Future<String> createProject({
    required String name,
    required String description,
    String? category,
  }) async {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final projectRef = await _firestore.collection('projects').add({
        'name': name,
        'description': description,
        'ownerId': userId,
        'category': category,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return projectRef.id;
    } catch (e) {
      debugPrint('Error creating project: $e');
      rethrow;
    }
  }

  /// Get user's projects
  /// Note: This query requires a composite index: projects (ownerId: ASC, createdAt: DESC)
  static Stream<List<ProjectModel>> getUserProjects() {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) return Stream.value([]);

      return _firestore
          .collection('projects')
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ProjectModel.fromJSON(doc.id, doc.data()))
            .toList();
      });
    } catch (e) {
      debugPrint('Error getting projects: $e');
      return Stream.value([]);
    }
  }

  /// Get single project
  static Future<ProjectModel?> getProject(String projectId) async {
    try {
      final doc = await _firestore.collection('projects').doc(projectId).get();
      if (!doc.exists) return null;
      return ProjectModel.fromJSON(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('Error getting project: $e');
      return null;
    }
  }

  /// Update project
  static Future<void> updateProject(
    String projectId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('projects').doc(projectId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating project: $e');
      rethrow;
    }
  }

  /// Delete project
  static Future<void> deleteProject(String projectId) async {
    try {
      await _firestore.collection('projects').doc(projectId).delete();
    } catch (e) {
      debugPrint('Error deleting project: $e');
      rethrow;
    }
  }

  // ==================== Analysis Reports Collection ====================

  /// Create analysis report
  static Future<String> createAnalysisReport({
    required String projectId,
    required String status,
    required int issuesFound,
    required int warningsFound,
    required double codeQualityScore,
    Map<String, dynamic>? details,
  }) async {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final reportRef = await _firestore.collection('analysis_reports').add({
        'projectId': projectId,
        'userId': userId,
        'status': status,
        'issuesFound': issuesFound,
        'warningsFound': warningsFound,
        'codeQualityScore': codeQualityScore,
        'details': details ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      });

      return reportRef.id;
    } catch (e) {
      debugPrint('Error creating analysis report: $e');
      rethrow;
    }
  }

  /// Get project's analysis reports
  /// Note: This query requires a composite index: analysis_reports (projectId: ASC, createdAt: DESC)
  static Stream<List<AnalysisReportModel>> getProjectReports(
    String projectId,
  ) {
    try {
      return _firestore
          .collection('analysis_reports')
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => AnalysisReportModel.fromJSON(doc.id, doc.data()))
            .toList();
      });
    } catch (e) {
      debugPrint('Error getting analysis reports: $e');
      return Stream.value([]);
    }
  }

  /// Get latest report for project
  static Future<AnalysisReportModel?> getLatestReport(
    String projectId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('analysis_reports')
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return AnalysisReportModel.fromJSON(doc.id, doc.data());
    } catch (e) {
      debugPrint('Error getting latest report: $e');
      return null;
    }
  }

  // ==================== User Settings Collection ====================

  /// Save user settings
  static Future<void> saveUserSettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore.collection('user_settings').doc(userId).set({
        ...settings,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user settings: $e');
      rethrow;
    }
  }

  /// Get user settings
  static Future<Map<String, dynamic>?> getUserSettings() async {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore.collection('user_settings').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting user settings: $e');
      return null;
    }
  }

  // ==================== Activity Log Collection ====================

  /// Log user activity
  static Future<void> logActivity({
    required String action,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('activity_logs').add({
        'userId': userId,
        'action': action,
        'description': description,
        'metadata': metadata ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error logging activity: $e');
    }
  }

  /// Get user activity logs
  /// Note: This query requires a composite index: activity_logs (userId: ASC, createdAt: DESC)
  static Stream<List<Map<String, dynamic>>> getUserActivityLogs({
    int limit = 50,
  }) {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) return Stream.value([]);

      return _firestore
          .collection('activity_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      debugPrint('Error getting activity logs: $e');
      return Stream.value([]);
    }
  }

  // ==================== Batch Operations ====================

  /// Delete all user data (for account deletion)
  static Future<void> deleteAllUserData() async {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();

      // Delete projects
      final projects = await _firestore
          .collection('projects')
          .where('ownerId', isEqualTo: userId)
          .get();

      for (var doc in projects.docs) {
        batch.delete(doc.reference);
      }

      // Delete analysis reports
      final reports = await _firestore
          .collection('analysis_reports')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in reports.docs) {
        batch.delete(doc.reference);
      }

      // Delete activity logs
      final logs = await _firestore
          .collection('activity_logs')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in logs.docs) {
        batch.delete(doc.reference);
      }

      // Delete user settings
      batch.delete(_firestore.collection('user_settings').doc(userId));

      // Commit batch
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      rethrow;
    }
  }

  // ==================== Search & Query ====================

  /// Search projects by name
  static Stream<List<ProjectModel>> searchProjects(String query) {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) return Stream.value([]);

      final normalizedQuery = query.toLowerCase();

      return _firestore
          .collection('projects')
          .where('ownerId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ProjectModel.fromJSON(doc.id, doc.data()))
            .where((project) =>
                project.name.toLowerCase().contains(normalizedQuery) ||
                project.description.toLowerCase().contains(normalizedQuery))
            .toList();
      });
    } catch (e) {
      debugPrint('Error searching projects: $e');
      return Stream.value([]);
    }
  }

  /// Get statistics for user
  static Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) return {};

      final projects = await _firestore
          .collection('projects')
          .where('ownerId', isEqualTo: userId)
          .count()
          .get();

      final reports = await _firestore
          .collection('analysis_reports')
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return {
        'totalProjects': projects.count,
        'totalReports': reports.count,
        'lastAccess': DateTime.now(),
      };
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {};
    }
  }
}
