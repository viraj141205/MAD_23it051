import 'package:flutter/material.dart';
import '../models/firestore_models.dart';
import '../services/firestore_database.dart';
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
  late TextEditingController _languageController;
  late TextEditingController _contentController;
  String _status = 'Draft';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.snippet?.title ?? '');
    _languageController = TextEditingController(text: widget.snippet?.language ?? '');
    _contentController = TextEditingController(text: widget.snippet?.content ?? '');
    _status = widget.snippet?.status ?? 'Draft';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _languageController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveSnippet() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        if (widget.snippet == null) {
          // CREATE
          await FirestoreDatabase.createSnippet(
            title: _titleController.text.trim(),
            language: _languageController.text.trim(),
            content: _contentController.text.trim(),
            status: _status,
          );
        } else {
          // UPDATE
          await FirestoreDatabase.updateSnippet(
            widget.snippet!.id,
            {
              'title': _titleController.text.trim(),
              'language': _languageController.text.trim(),
              'content': _contentController.text.trim(),
              'status': _status,
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
                      CustomTextField(
                        controller: _languageController,
                        labelText: 'Language',
                        hintText: 'e.g. Python, Dart, JavaScript',
                        validator: (value) => value == null || value.isEmpty ? 'Language is required' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _contentController,
                        labelText: 'Code Content',
                        hintText: 'Paste your code here',
                        maxLines: 10,
                        validator: (value) => value == null || value.isEmpty ? 'Content is required' : null,
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
