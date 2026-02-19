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
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
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
        _urlController.text = settings['pistonUrl'] ?? 'https://emkc.org/api/v2/piston/execute';
        _keyController.text = settings['pistonKey'] ?? '';
      } else {
        _urlController.text = 'https://emkc.org/api/v2/piston/execute';
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
    if (_urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API URL cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirestoreDatabase.saveUserSettings({
        'pistonUrl': _urlController.text.trim(),
        'pistonKey': _keyController.text.trim(),
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
    _urlController.dispose();
    _keyController.dispose();
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
                  const Text(
                    'Piston API Configuration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Customize the Piston API endpoint or provide an authorization key for whitelisted access.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _urlController,
                    labelText: 'API Execution URL',
                    hintText: 'https://emkc.org/api/v2/piston/execute',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _keyController,
                    labelText: 'Authorization Key (Optional)',
                    hintText: 'Your API key or token',
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
