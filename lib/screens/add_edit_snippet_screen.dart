import 'package:flutter/material.dart';
import '../models/firestore_models.dart';
import '../services/firestore_database.dart';
import '../services/code_analyzer_service.dart';
import '../services/code_execution_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddEditSnippetScreen extends StatefulWidget {
  final SnippetModel? snippet;

  const AddEditSnippetScreen({super.key, this.snippet});

  @override
  State<AddEditSnippetScreen> createState() => _AddEditSnippetScreenState();
}

class _AddEditSnippetScreenState extends State<AddEditSnippetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String _language = 'Java';
  String _status = 'Draft';
  bool _isLoading = false;

  final List<String> _languages = [
    'Java',
    'C++',
    'Python',
    'JavaScript',
    'Dart',
    'Go',
    'Rust',
    'Swift',
    'Kotlin',
    'PHP',
    'C#',
    'Ruby',
    'C',
    'HTML/CSS',
    'SQL',
    'TypeScript',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.snippet?.title ?? '');
    _contentController = TextEditingController(text: widget.snippet?.content ?? '');
    _status = widget.snippet?.status ?? 'Draft';

    // Initialize language
    final initialLanguage = widget.snippet?.language ?? 'Java';
    if (initialLanguage.isNotEmpty) {
      if (!_languages.contains(initialLanguage)) {
        _languages.insert(0, initialLanguage);
      }
      _language = initialLanguage;
    } else {
      _language = 'Java';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveSnippet() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        if (widget.snippet == null) {
          // CREATE
          final analysis = CodeAnalyzerService.analyzeCode(
            _contentController.text.trim(),
            _language,
          );
          await FirestoreDatabase.createSnippet(
            title: _titleController.text.trim(),
            language: _language,
            content: _contentController.text.trim(),
            status: _status,
            analysis: analysis,
          );
        } else {
          // UPDATE
          final content = _contentController.text.trim();
          final staticAnalysis = CodeAnalyzerService.analyzeCode(content, _language);

          String executionFeedback = '';
          final pistonLang = CodeExecutionService.getPistonLanguage(_language);

          if (pistonLang != null) {
            final execResult = await CodeExecutionService.executeCode(content, _language);
            if (execResult != null) {
              if (execResult.compileOutput != null && execResult.compileOutput!.isNotEmpty) {
                executionFeedback = '\n\n❌ Compiler Errors:\n${execResult.compileOutput}';
              } else if (execResult.stderr.isNotEmpty) {
                executionFeedback = '\n\n❌ Runtime Errors:\n${execResult.stderr}';
              } else {
                executionFeedback = '\n\n✅ Execution Successful!\nOutput:\n${execResult.stdout}';
              }
            }
          }

          final report = staticAnalysis + executionFeedback;

          await FirestoreDatabase.updateSnippet(
            widget.snippet!.id,
            {
              'title': _titleController.text.trim(),
              'language': _language,
              'content': content,
              'status': _status,
              'analysis': report, // Use the combined report
            },
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Snippet ${widget.snippet == null ? 'created' : 'updated'} successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.snippet != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Snippet' : 'New Snippet'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _titleController,
                        labelText: 'Title',
                        hintText: 'Enter snippet title',
                        validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _language,
                        decoration: const InputDecoration(
                          labelText: 'Language',
                          border: OutlineInputBorder(),
                        ),
                        items: _languages
                            .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _language = value;
                              _contentController.clear();
                            });
                          }
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Language is required' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _contentController, // Changed from _contentController
                        labelText: 'Code Content',
                        hintText: 'Paste your code here...',
                        maxLines: 15,
                        isCode: true,
                        validator: (value) => value == null || value.isEmpty ? 'Code is required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Draft', 'Active', 'Archived']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _status = value);
                        },
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: isEditing ? 'Update Snippet' : 'Save Snippet',
                        onPressed: _saveSnippet,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
