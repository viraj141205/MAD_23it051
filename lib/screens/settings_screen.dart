import 'package:flutter/material.dart';
import '../services/firestore_database.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _geminiKeyController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await FirestoreDatabase.getUserSettings();
      if (settings != null) {
        _geminiKeyController.text = settings['geminiKey'] ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await FirestoreDatabase.saveUserSettings({
        'geminiKey': _geminiKeyController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _geminiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Judge0 Info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.rocket_launch_outlined, color: Colors.blue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Code execution is powered by Judge0 CE (ce.judge0.com). '
                            'No API key needed — it works out of the box!',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Gemini AI
                  const Text(
                    'Gemini AI Configuration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Provide your Google Gemini API key to enable AI-driven code reviews and conversions.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _geminiKeyController,
                    labelText: 'Gemini API Key',
                    hintText: 'Enter your Gemini API key',
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: _isSaving ? 'Saving...' : 'Save Settings',
                    onPressed: _isSaving ? () {} : _saveSettings,
                  ),
                ],
              ),
            ),
    );
  }
}
