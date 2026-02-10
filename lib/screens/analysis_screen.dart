import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/firestore_database.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _codeController = TextEditingController();
  String _analysisResult = '';
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _analyzeCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some code to analyze.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = '';
    });

    // Simulate analysis delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        // Simple mock analysis logic
        if (code.contains('select *') || code.contains('SELECT *')) {
          _analysisResult = '⚠️ Warning: Avoid using "SELECT *" in production queries for better performance and security.';
        } else if (code.contains('print(') || code.contains('System.out.println')) {
          _analysisResult = 'ℹ️ Note: Consider using a proper logging framework instead of print statements.';
        } else if (code.length < 50) {
          _analysisResult = '✅ Code looks clean and concise!';
        } else {
          _analysisResult = '✅ Analysis complete. No critical issues found.';
        }
      });

      // Save to history
      try {
        await FirestoreDatabase.saveAnalysisResult(
          codeSnippet: code,
          result: _analysisResult,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Analysis saved to history'), duration: Duration(seconds: 1)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving to history: $e')),
          );
        }
      }
    }
  }

  void _clear() {
    setState(() {
      _codeController.clear();
      _analysisResult = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Code Analysis'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paste your code snippet below:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _codeController,
              labelText: 'Code Snippet',
              hintText: 'Enter or paste code here...',
              maxLines: 8,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Analyze',
                    onPressed: _isAnalyzing ? () {} : _analyzeCode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isAnalyzing ? null : _clear,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Clear', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isAnalyzing)
              const Center(child: CircularProgressIndicator())
            else if (_analysisResult.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _analysisResult.startsWith('✅') ? Colors.green[50] : Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _analysisResult.startsWith('✅') ? Colors.green : Colors.amber,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Analysis Result:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_analysisResult),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
