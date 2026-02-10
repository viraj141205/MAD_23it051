# Firestore Database Usage Examples

This guide shows how to use Firebase and Firestore in your Flutter app.

## Quick Start

### 1. Basic Authentication

```dart
import 'package:flutter/material.dart';
import 'services/firebase_service.dart';

// Register new user
final result = await FirebaseService.register(
  email: 'user@example.com',
  password: 'password123',
  name: 'John Doe',
);

if (result['success']) {
  print('User registered: ${result['user']}');
}

// Login user
final loginResult = await FirebaseService.login(
  email: 'user@example.com',
  password: 'password123',
);

// Logout
await FirebaseService.logout();
```

### 2. Working with Projects

```dart
import 'services/firestore_database.dart';

// Create a project
String projectId = await FirestoreDatabase.createProject(
  name: 'My Code Project',
  description: 'Analyzing my code quality',
  category: 'flutter',
);

// Get user's projects (real-time stream)
FirestoreDatabase.getUserProjects().listen((projects) {
  for (var project in projects) {
    print('Project: ${project.name} - ${project.description}');
  }
});

// Update a project
await FirestoreDatabase.updateProject(
  projectId,
  {
    'name': 'Updated Project Name',
    'category': 'dart',
  },
);

// Delete a project
await FirestoreDatabase.deleteProject(projectId);
```

### 3. Analysis Reports

```dart
// Create analysis report
String reportId = await FirestoreDatabase.createAnalysisReport(
  projectId: 'project123',
  status: 'completed',
  issuesFound: 5,
  warningsFound: 3,
  codeQualityScore: 8.5,
  details: {
    'language': 'dart',
    'filesAnalyzed': 15,
    'timeToAnalyze': '2.5 seconds',
  },
);

// Get project's reports
FirestoreDatabase.getProjectReports(projectId).listen((reports) {
  for (var report in reports) {
    print('Report: ${report.status} - Issues: ${report.issuesFound}');
  }
});

// Get latest report
final latestReport = await FirestoreDatabase.getLatestReport(projectId);
print('Latest score: ${latestReport?.codeQualityScore}');
```

### 4. User Settings

```dart
// Save user preferences
await FirestoreDatabase.saveUserSettings({
  'theme': 'dark',
  'notifications': true,
  'language': 'en',
  'autoAnalysis': false,
});

// Get user settings
final settings = await FirestoreDatabase.getUserSettings();
print('Theme: ${settings?['theme']}');
```

### 5. Activity Logging

```dart
// Log user activity
await FirestoreDatabase.logActivity(
  action: 'project_created',
  description: 'User created a new project',
  metadata: {
    'projectId': 'proj123',
    'projectName': 'My Project',
  },
);

// Get user activity logs
FirestoreDatabase.getUserActivityLogs(limit: 20).listen((logs) {
  for (var log in logs) {
    print('${log['action']}: ${log['description']}');
  }
});
```

### 6. Search

```dart
// Search projects by name
FirestoreDatabase.searchProjects('flutter').listen((results) {
  print('Found ${results.length} projects');
  for (var project in results) {
    print('- ${project.name}');
  }
});
```

### 7. Statistics

```dart
// Get user statistics
final stats = await FirestoreDatabase.getUserStatistics();
print('Total Projects: ${stats['totalProjects']}');
print('Total Reports: ${stats['totalReports']}');
```

## Usage in Screens

### Example: Projects List Screen

```dart
import 'package:flutter/material.dart';
import '../services/firestore_database.dart';
import '../models/firestore_models.dart';

class ProjectsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Projects')),
      body: StreamBuilder<List<ProjectModel>>(
        stream: FirestoreDatabase.getUserProjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No projects yet'));
          }

          final projects = snapshot.data!;
          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return ListTile(
                title: Text(project.name),
                subtitle: Text(project.description),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text('Edit'),
                      value: 'edit',
                    ),
                    PopupMenuItem(
                      child: Text('Delete'),
                      value: 'delete',
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteProject(context, project.id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProjectDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context) {
    // Show dialog to create new project
  }

  void _deleteProject(BuildContext context, String projectId) async {
    await FirestoreDatabase.deleteProject(projectId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Project deleted')),
    );
  }
}
```

### Example: Project Details Screen

```dart
class ProjectDetailsScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailsScreen({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Project Details')),
      body: FutureBuilder<ProjectModel?>(
        future: FirestoreDatabase.getProject(projectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(child: Text('Project not found'));
          }

          final project = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(project.description),
                    SizedBox(height: 16),
                    Text('Category: ${project.category ?? 'N/A'}'),
                    Text('Status: ${project.isActive ? 'Active' : 'Inactive'}'),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Text('Analysis Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: _buildReportsList(projectId),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportsList(String projectId) {
    return StreamBuilder<List<AnalysisReportModel>>(
      stream: FirestoreDatabase.getProjectReports(projectId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: Text('No reports'));
        }

        final reports = snapshot.data!;
        if (reports.isEmpty) {
          return Center(child: Text('No analysis reports yet'));
        }

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return Card(
              child: ListTile(
                title: Text('Report - ${report.status}'),
                subtitle: Text('Issues: ${report.issuesFound}, '
                    'Warnings: ${report.warningsFound}, '
                    'Score: ${report.codeQualityScore}'),
              ),
            );
          },
        );
      },
    );
  }
}
```

## Error Handling

```dart
try {
  await FirestoreDatabase.createProject(
    name: 'My Project',
    description: 'Description',
  );
} on FirebaseAuthException catch (e) {
  print('Auth Error: ${e.code} - ${e.message}');
} on FirebaseException catch (e) {
  print('Firebase Error: ${e.code} - ${e.message}');
} catch (e) {
  print('Error: $e');
}
```

## Best Practices

### 1. Always Check Authentication
```dart
final user = FirebaseService.currentUser;
if (user == null) {
  // Redirect to login
}
```

### 2. Use Streams for Real-time Data
```dart
// Good: Real-time updates
FirestoreDatabase.getUserProjects().listen((projects) {
  // Updates automatically when data changes
});

// Avoid: Single snapshot doesn't update
final projects = await FirestoreDatabase.getProject(id);
```

### 3. Handle Errors Gracefully
```dart
try {
  final result = await FirebaseService.login(email, password);
  if (!result['success']) {
    // Show user-friendly error message
    print(result['message']);
  }
} catch (e) {
  // Handle unexpected errors
}
```

### 4. Batch Operations for Multiple Changes
Use batch writes for atomic updates when modifying multiple documents.

### 5. Optimize Queries
```dart
// Good: Only fetches needed data
FirestoreDatabase.getUserProjects()

// Less efficient: Fetches all projects then filters
FirestoreDatabase.searchProjects(query)
```

## Security Considerations

1. **User Isolation**: Each user can only access their own data
2. **Server Validation**: Always validate on backend
3. **Sensitive Data**: Never store passwords in Firestore
4. **Rate Limiting**: Implement rate limiting for API calls
5. **Input Validation**: Validate all user inputs

---

For more examples and advanced usage, see `FIREBASE_SETUP.md`
