import 'package:flutter/material.dart';
import '../services/firestore_database.dart';
import '../models/firestore_models.dart';
import 'add_edit_snippet_screen.dart';

class SnippetListScreen extends StatelessWidget {
  const SnippetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Code Snippets'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<SnippetModel>>(
        stream: FirestoreDatabase.getUserSnippets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.code, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No code snippets found.\nAdd your first one!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final snippets = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snippets.length,
            itemBuilder: (context, index) {
              final snippet = snippets[index];
              return _SnippetCard(snippet: snippet);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditSnippetScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SnippetCard extends StatelessWidget {
  final SnippetModel snippet;

  const _SnippetCard({required this.snippet});

  void _deleteSnippet(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this snippet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreDatabase.deleteSnippet(snippet.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Snippet deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting snippet: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          snippet.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${snippet.language} • ${snippet.status}',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        leading: CircleAvatar(
          child: Text(snippet.language.isNotEmpty ? snippet.language[0].toUpperCase() : '?'),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    snippet.content,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Analysis: ${snippet.analysis}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditSnippetScreen(snippet: snippet),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteSnippet(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
