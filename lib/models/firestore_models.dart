import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for Firestore
class UserModel {
  final String uid;
  final String email;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert UserModel to JSON for Firestore
  Map<String, dynamic> toJSON() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create UserModel from Firestore document
  factory UserModel.fromJSON(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Copy with method for updating user data
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Project model for Firestore
class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? category;
  final bool isActive;

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.isActive = true,
  });

  /// Convert ProjectModel to JSON for Firestore
  Map<String, dynamic> toJSON() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'category': category,
      'isActive': isActive,
    };
  }

  /// Create ProjectModel from Firestore document
  factory ProjectModel.fromJSON(String id, Map<String, dynamic> json) {
    return ProjectModel(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ownerId: json['ownerId'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      category: json['category'],
      isActive: json['isActive'] ?? true,
    );
  }

  /// Copy with method
  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    bool? isActive,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Analysis report model for Firestore
class AnalysisReportModel {
  final String id;
  final String projectId;
  final String userId;
  final String status;
  final int issuesFound;
  final int warningsFound;
  final double codeQualityScore;
  final DateTime createdAt;
  final Map<String, dynamic>? details;

  AnalysisReportModel({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.status,
    required this.issuesFound,
    required this.warningsFound,
    required this.codeQualityScore,
    required this.createdAt,
    this.details,
  });

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJSON() {
    return {
      'projectId': projectId,
      'userId': userId,
      'status': status,
      'issuesFound': issuesFound,
      'warningsFound': warningsFound,
      'codeQualityScore': codeQualityScore,
      'createdAt': Timestamp.fromDate(createdAt),
      'details': details,
    };
  }

  /// Create from Firestore document
  factory AnalysisReportModel.fromJSON(String id, Map<String, dynamic> json) {
    return AnalysisReportModel(
      id: id,
      projectId: json['projectId'] ?? '',
      userId: json['userId'] ?? '',
      status: json['status'] ?? 'pending',
      issuesFound: json['issuesFound'] ?? 0,
      warningsFound: json['warningsFound'] ?? 0,
      codeQualityScore: (json['codeQualityScore'] ?? 0).toDouble(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      details: json['details'],
    );
  }
}

/// Snippet model for Firestore
class SnippetModel {
  final String id;
  final String userId;
  final String title;
  final String language;
  final String content;
  final String analysis;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  SnippetModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.language,
    required this.content,
    required this.analysis,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert SnippetModel to JSON for Firestore
  Map<String, dynamic> toJSON() {
    return {
      'userId': userId,
      'title': title,
      'language': language,
      'content': content,
      'analysis': analysis,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create SnippetModel from Firestore document
  factory SnippetModel.fromJSON(String id, Map<String, dynamic> json) {
    return SnippetModel(
      id: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      language: json['language'] ?? '',
      content: json['content'] ?? '',
      analysis: json['analysis'] ?? 'Pending',
      status: json['status'] ?? 'Draft',
      createdAt: (json['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  /// Copy with method
  SnippetModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? language,
    String? content,
    String? analysis,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SnippetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      language: language ?? this.language,
      content: content ?? this.content,
      analysis: analysis ?? this.analysis,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model for independent code analysis history
class AnalysisResultModel {
  final String id;
  final String userId;
  final String codeSnippet;
  final String language;
  final String result;
  final DateTime createdAt;

  AnalysisResultModel({
    required this.id,
    required this.userId,
    required this.codeSnippet,
    required this.language,
    required this.result,
    required this.createdAt,
  });

  Map<String, dynamic> toJSON() {
    return {
      'userId': userId,
      'codeSnippet': codeSnippet,
      'language': language,
      'result': result,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AnalysisResultModel.fromJSON(String id, Map<String, dynamic> json) {
    return AnalysisResultModel(
      id: id,
      userId: json['userId'] ?? '',
      codeSnippet: json['codeSnippet'] ?? '',
      language: json['language'] ?? 'Unknown',
      result: json['result'] ?? '',
      createdAt: (json['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}
